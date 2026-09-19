# frozen_string_literal: true

require "net/http"

module ReviewLab
  # AI 의미검사 (요구서 §8) — 사용자가 **명시적으로 선택**했을 때만 돈다.
  #
  # 경계
  #   · 보내기 전에 개인정보 패턴을 가린다(PiiScanner.mask) · 문서당 길이 상한.
  #   · AI 가 낸 것은 전부 origin=:ai → Finding 이 CHECK 로 고정한다(BLOCK·WARN·PASS 불가).
  #   · AI 가 «원문 인용» 이라고 낸 문장이 실제 원문에 없으면 버린다 — 지어낸 근거를 화면에 올리지 않는다.
  #   · 금액·날짜 계산, 법령 판정, 가격 적정성은 AI 에게 묻지 않는다(규칙 검사의 몫).
  #
  # provider = 기존 사이트가 이미 쓰는 Anthropic Messages API · 같은 키 · 같은 모델(새 provider 아님).
  class AiSemanticReviewer
    API_URL = "https://api.anthropic.com/v1/messages"
    MODEL = "claude-sonnet-4-20250514" # DocumentAnalyzerService 가 복잡 분석에 쓰는 모델과 동일
    MAX_CHARS_PER_DOC = 6_000
    MAX_ISSUES = 8
    TYPES = { "conflict" => "문서 간 의미 충돌", "ambiguous" => "모호한 표현", "missing" => "누락 의심",
              "scope" => "과업범위 불완전", "mismatch" => "목적 불일치" }.freeze

    Result = Struct.new(:findings, :dropped, :error, keyword_init: true)

    def self.call(documents:, http: nil) = new(documents: documents, http: http).call

    def initialize(documents:, http: nil)
      @documents = documents.select(&:ok?)
      @http = http
      @api_key = ENV["ANTHROPIC_API_KEY"]
    end

    def call
      return Result.new(findings: [], dropped: 0, error: "AI 키가 설정되지 않아 AI 검토를 건너뛰었습니다.") if @api_key.blank? && @http.nil?
      return Result.new(findings: [], dropped: 0, error: nil) if @documents.empty?

      raw = request(prompt)
      issues = parse(raw)
      return Result.new(findings: [], dropped: 0, error: "AI 응답을 해석하지 못해 AI 검토 결과를 표시하지 않습니다.") if issues.nil?

      grounded, dropped = issues.first(MAX_ISSUES).partition { |i| grounded?(i) }
      Result.new(findings: grounded.map { |i| to_finding(i) }, dropped: dropped.size, error: nil)
    rescue Net::ReadTimeout, Net::OpenTimeout
      Result.new(findings: [], dropped: 0, error: "AI 응답 시간이 초과되어 AI 검토를 건너뛰었습니다.")
    rescue StandardError => e
      # 문서 내용이 예외 메시지에 섞일 수 있어 클래스명만 남긴다.
      Rails.logger.warn("[review-lab] ai semantic failed: #{e.class}")
      Result.new(findings: [], dropped: 0, error: "AI 검토 중 오류가 나 AI 결과를 표시하지 않습니다. 규칙 검사 결과는 그대로 유효합니다.")
    end

    private

    def masked_text(doc) = PiiScanner.mask(doc.full_text)[0, MAX_CHARS_PER_DOC]

    def prompt
      docs = @documents.map { |d| "### 문서: #{d.label} (#{d.role_label})\n#{masked_text(d)}" }.join("\n\n")
      <<~PROMPT
        당신은 한국 공공기관(학교 행정실) 입찰·계약 문서를 읽는 검토 보조자입니다.
        아래 문서들을 읽고, 담당자가 **다시 확인해야 할 문장**만 찾으세요.

        찾을 것(type):
        - conflict: 서로 다른 문서가 같은 사항을 다른 뜻으로 적은 곳
        - ambiguous: 해석이 둘 이상 가능한 표현(예: «등», «협의하여 결정», 기준 없는 «적정한»)
        - missing: 과업·납품·검수에 필요한데 빠진 것으로 보이는 사항
        - scope: 과업 범위가 불완전하거나 경계가 불분명한 곳
        - mismatch: 사양서와 공고문의 목적·대상이 어긋나는 곳

        하지 말 것:
        - 금액·날짜·기간을 계산하거나 비교하지 마세요(별도 규칙 검사가 합니다).
        - 법령 위반 여부나 가격이 적정한지 판정하지 마세요.
        - 문서에 없는 문장을 만들지 마세요. quote 는 문서에 있는 문장을 **글자 그대로** 복사해야 합니다.

        최대 #{MAX_ISSUES}건. 반드시 아래 JSON 만 출력하세요.
        {"issues":[{"document":"문서 이름","quote":"원문 그대로","type":"conflict|ambiguous|missing|scope|mismatch","explanation":"왜 확인이 필요한지 한 문장","check":"담당자가 확인할 것 한 문장"}]}

        #{docs}
      PROMPT
    end

    def request(text)
      return @http.call(text) if @http

      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 60
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["x-api-key"] = @api_key
      req["anthropic-version"] = "2023-06-01"
      req.body = { model: MODEL, max_tokens: 2000, messages: [ { role: "user", content: text } ] }.to_json
      res = http.request(req)
      raise "anthropic status #{res.code}" unless res.code == "200"

      JSON.parse(res.body).dig("content", 0, "text")
    end

    def parse(raw)
      json = raw.to_s[/\{[\s\S]*\}/] or return nil
      Array(JSON.parse(json)["issues"]).select { |i| i.is_a?(Hash) }
    rescue JSON::ParserError
      nil
    end

    def squash(s) = s.to_s.gsub(/\s+/, "")

    # 인용문이 해당 문서(또는 어느 문서든) 원문에 실제로 있어야 한다. 가림 처리된 원문 기준.
    def grounded?(issue)
      quote = squash(issue["quote"])
      return false if quote.length < 4

      targets = @documents.select { |d| d.label == issue["document"] }.presence || @documents
      targets.any? { |d| squash(PiiScanner.mask(d.full_text)).include?(quote) }
    end

    def to_finding(issue)
      doc = @documents.find { |d| d.label == issue["document"] } ||
            @documents.find { |d| squash(PiiScanner.mask(d.full_text)).include?(squash(issue["quote"])) }
      seg = doc&.segments&.find { |s| squash(PiiScanner.mask(s[:text])).include?(squash(issue["quote"])[0, 20]) }
      # type 은 닫힌 목록만 — 문서 속 문구가 AI 를 흔들어 «AI-확정위반» 같은 코드를 띄우지 못하게 한다.
      type = TYPES.key?(issue["type"].to_s) ? issue["type"].to_s : "note"
      Finding.new(
        severity: "CHECK", origin: :ai, code: "AI-#{type.upcase}",
        source_document: doc&.label, location: seg&.dig(:locator),
        extracted_value: issue["quote"].to_s.truncate(160),
        problem: "#{TYPES.fetch(type, 'AI 검토')}: #{issue['explanation'].to_s.truncate(200)}",
        why_it_matters: "AI 해석입니다. 법령 사실이나 확정 오류가 아닙니다.",
        suggested_action: issue["check"].to_s.truncate(200).presence,
        confidence: "AI 해석 — 원문 대조 필요"
      )
    end
  end
end
