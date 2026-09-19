# frozen_string_literal: true

# 실무 검증실 Beta — 실제 업무문서(견적서·입찰공고 패키지)를 올려 규칙 검사 + (선택) AI 의미검사.
#
# 공개 범위 (요구서 §9)
#   · 안내 화면(index·quote·package GET)은 누구나 본다 — 기능 설명까지만.
#   · 업로드·분석·demo 실행은 로그인 전용이다. 목적은 마케팅이 아니라 민감 문서 기능 분리·남용 방지다.
#     회원 이메일을 쓰는 기능(뉴스레터·CRM)은 만들지 않는다.
#
# 저장하지 않는다 (요구서 §10)
#   · 원본·추출문·결과를 DB·디스크·캐시에 쓰지 않는다. 요청 안에서 검사하고 응답으로 렌더한 뒤 사라진다.
#   · 응답은 `Cache-Control: no-store` — 공유 PC 뒤로가기·CDN 캐시에 남지 않게 한다.
#   · 업로드 파라미터(파일명 포함)는 로그에서 가린다(config/initializers/filter_parameter_logging.rb).
#
# 도구 레지스트리(ToolsHelper#tools_registry)에 넣지 않는다 — «도구 39개» 는 강의자료·화면에 박힌 수다.
class ReviewLabController < ApplicationController
  before_action :require_login_for_ai, only: %i[quote_review package_review demo]
  before_action :no_store
  before_action :enforce_rate_limit, only: %i[quote_review package_review demo]
  around_action :one_review_at_a_time, only: %i[quote_review package_review demo]
  before_action :remember_return_path, only: %i[index quote package]

  # 문서 파싱은 CPU 를 오래 쓸 수 있다. 운영은 Puma 단일 프로세스 · 스레드 3개라 검토가 동시에 여러 건 돌면
  # 사이트 전체가 느려진다 — 프로세스 안에서 동시에 1건만 돌리고 나머지는 곧바로 «잠시 후» 로 돌려보낸다.
  REVIEW_SLOT = Concurrent::Semaphore.new(1)

  MAX_COMPARISON_QUOTES = 3
  MAX_TOTAL_BYTES = 40.megabytes
  RULE_LIMIT_PER_HOUR = 30
  AI_LIMIT_PER_DAY = 10

  PACKAGE_ROLES = %w[notice task_order spec special_terms rfp cost_sheet].freeze
  MAX_OTHER_FILES = 2

  CONTRACT_TYPE_OPTIONS = ContractDecision::RuleSet.current.contract_types
                                                  .select { |k, _| ReviewLab::QuoteReviewer::CONTRACT_TYPES.include?(k) }
                                                  .map { |k, v| [ v["label"], k ] }.freeze
  AGENCY_SCOPE_OPTIONS = ContractDecision::RuleSet.current.agency_scopes.map { |k, v| [ v["label"], k ] }.freeze
  COUNTERPARTY_OPTIONS = ContractDecision::RuleSet.current.counterparty_types.map { |k, v| [ v["label"], k ] }.freeze

  helper_method :contract_type_options, :agency_scope_options, :counterparty_options

  def index
    set_lab_meta("실무 검증실 Beta", "견적서·입찰공고 패키지를 올리면 금액 산술·문서 간 불일치·공고기간을 규칙으로 먼저 검사하고, 근거 조문과 확인할 점을 함께 보여주는 사전검토 도구입니다.")
  end

  def quote
    set_lab_meta("견적서 검토 — 실무 검증실 Beta", "견적서의 수량×단가·공급가액·부가세·합계를 규칙으로 검산하고 규격·단위·유효기간 누락과 가격 근거 수준을 표시합니다.")
  end

  def package
    set_lab_meta("입찰공고 패키지 검토 — 실무 검증실 Beta", "공고문·과업지시서·규격서를 함께 올리면 금액·수량·기한·일정의 문서 간 불일치와 공고기간을 검사합니다.")
  end

  def quote_review
    main = params[:main_file]
    return reject(:quote, "검토할 견적서 파일을 올려 주세요.") unless uploaded?(main)

    comparisons = Array(params[:comparison_files]).select { |f| uploaded?(f) }.first(MAX_COMPARISON_QUOTES)
    return reject(:quote, "파일 합계가 40MB 를 넘습니다.") if total_bytes([ main, *comparisons ]) > MAX_TOTAL_BYTES

    docs = [ extract(main, "quote", "견적서") ]
    comparisons.each_with_index { |f, i| docs << extract(f, "comparison_quote", "비교견적 #{i + 1}") }

    ai_fields = nil
    if ai_requested? && docs.first.format == :image
      # 규칙으로 읽을 수 없는 **사진·스캔 이미지** 견적서만 기존 AI 추출 경로로 읽는다 — 사용자가 선택했을 때만.
      # 이미지는 가릴 수 없으므로 원본이 그대로 전송된다(화면에 명시). PDF 는 보내지 않는다 —
      # 규칙 추출이 실패한 PDF 에도 가리지 않은 본문이 들어 있을 수 있다.
      ai_fields = ai_quota_available? ? ai_extract_quote(main) : nil
    end

    @review = ReviewLab::QuoteReviewer.call(documents: docs, ai_fields: ai_fields, **decision_params)
    @ai_note = ai_note_for_quote(docs.first, ai_fields)
    render :report
  end

  def package_review
    raw_files = params[:files].is_a?(ActionController::Parameters) ? params[:files] : {}
    files = PACKAGE_ROLES.filter_map do |role|
      f = raw_files[role]
      [ f, role ] if uploaded?(f)
    end
    Array(raw_files[:other]).select { |f| uploaded?(f) }.first(MAX_OTHER_FILES).each { |f| files << [ f, "other" ] }
    return reject(:package, "문서를 2개 이상 올려 주세요(상호대조는 문서가 둘 이상일 때 의미가 있습니다).") if files.size < 2
    return reject(:package, "파일 합계가 40MB 를 넘습니다.") if total_bytes(files.map(&:first)) > MAX_TOTAL_BYTES

    others = 0
    docs = files.map do |f, role|
      label = role == "other" ? "기타 첨부 #{others += 1}" : ReviewLab::DocumentArtifact::ROLES.fetch(role)
      extract(f, role, label)
    end
    @review = ReviewLab::PackageReviewer.call(documents: docs, contract_type: params[:contract_type], agency_scope: params[:agency_scope])
    run_ai_semantic(docs) if ai_requested?
    render :report
  end

  # 연수 시연 — 완전 가상 문서로 실제 파일 경로(생성 → 파싱 → 검사)를 그대로 돈다.
  def demo
    case params[:kind]
    when "quote"
      @review = ReviewLab::Demo.run_quote
      @demo = ReviewLab::Demo.compare(@review, ReviewLab::Demo::QUOTE_EXPECTED)
    when "package"
      @review = ReviewLab::Demo.run_package
      @demo = ReviewLab::Demo.compare(@review, ReviewLab::Demo::PACKAGE_EXPECTED)
      run_ai_semantic(@review.documents) if ai_requested?
    else
      return head :not_found
    end
    render :report
  end

  private

  def contract_type_options = CONTRACT_TYPE_OPTIONS
  def agency_scope_options = AGENCY_SCOPE_OPTIONS
  def counterparty_options = COUNTERPARTY_OPTIONS

  # 로그인 후 이 화면으로 돌아오게 한다(Users::SessionsController#after_sign_in_path_for 가 읽는다).
  def remember_return_path
    store_location_for(:user, request.fullpath) unless user_signed_in?
  end

  def no_store
    response.headers["Cache-Control"] = "no-store"
  end

  def set_lab_meta(title, description)
    set_meta_tags(title: title, description: description, noindex: true,
                  og: { title: "#{title} — 실무.kr", description: description, url: canonical_url })
  end

  def uploaded?(f) = f.respond_to?(:read) && f.respond_to?(:size) && f.size.positive?

  def total_bytes(files) = files.sum(&:size)

  # 원본 파일명은 쓰지 않는다 — 표시명은 역할에서 만든다.
  def extract(file, role, label)
    ReviewLab::TextExtractor.call(bytes: file.read, role: role, label: label)
  ensure
    file.rewind if file.respond_to?(:rewind)
  end

  def decision_params
    { contract_type: params[:contract_type], agency_scope: params[:agency_scope], counterparty_type: params[:counterparty_type] }
  end

  def ai_requested? = params[:use_ai] == "1"

  def reject(page, message)
    flash.now[:alert] = message
    public_send(page)
    render page, status: :unprocessable_entity
  end

  # 사용자 단위 한도(로그인 전용이라 IP 가 아니라 user.id 로 센다 — 엣지 IP 공유(G-60)와 무관하다).
  def enforce_rate_limit
    key = "review_lab:rule:#{current_user.id}:#{Time.current.strftime('%Y%m%d%H')}"
    count = Rails.cache.increment(key, 1, expires_in: 1.hour) || 1
    return if count <= RULE_LIMIT_PER_HOUR

    flash.now[:alert] = "검토 요청이 너무 많습니다. 한 시간 뒤에 다시 시도해 주세요."
    kind = action_name == "package_review" ? :package : :quote
    public_send(kind)
    render kind, status: :too_many_requests
  end

  def one_review_at_a_time
    unless REVIEW_SLOT.try_acquire
      flash.now[:alert] = "다른 검토가 진행 중입니다. 몇 초 뒤에 다시 시도해 주세요."
      kind = action_name == "package_review" ? :package : :quote
      public_send(kind)
      return render(kind, status: :service_unavailable)
    end
    begin
      yield
    ensure
      REVIEW_SLOT.release
    end
  end

  def ai_quota_available?
    key = "review_lab:ai:#{current_user.id}:#{Date.current}"
    count = Rails.cache.increment(key, 1, expires_in: 1.day) || 1
    count <= AI_LIMIT_PER_DAY
  end

  def ai_extract_quote(file)
    result = DocumentAnalyzerService.new.analyze(file: file, document_type: "quote_extraction")
    result[:success] ? result[:fields] : nil
  end

  def ai_note_for_quote(main, ai_fields)
    return nil unless ai_requested?
    return "원본에서 값을 규칙으로 읽었으므로 AI 로 보내지 않았습니다." if main.ok?
    return "AI 로 값을 읽었습니다. 아래 모든 결과는 원본과 대조하기 전까지 확인 필요(CHECK)입니다." if ai_fields
    return "AI 로 값 읽기는 사진·스캔 이미지 견적서에만 씁니다. 이 파일은 AI 로 보내지 않았습니다." unless main.format == :image

    "AI 로 값을 읽지 못했습니다(한도 초과 또는 오류). 원본 파일(XLSX·HWPX·DOCX)로 다시 올려 주세요."
  end

  def run_ai_semantic(docs)
    unless ai_quota_available?
      @ai_note = "오늘 AI 검토 한도(#{AI_LIMIT_PER_DAY}회)를 다 썼습니다. 규칙 검사 결과는 그대로 유효합니다."
      return
    end
    result = ReviewLab::AiSemanticReviewer.call(documents: docs)
    result.findings.each { |f| @review.add(f) }
    @ai_note = result.error || ("AI 가 낸 인용문 중 원문에서 찾지 못한 #{result.dropped}건은 버렸습니다." if result.dropped.positive?) ||
               "AI 검토 #{result.findings.size}건 — 모두 «추가 확인 필요» 입니다."
  end
end
