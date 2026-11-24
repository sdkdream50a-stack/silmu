# 공개 콘텐츠 법령 정정 — MAS 2단계경쟁(mas-contract) · 결산(budget-settlement)
#
# 무엇을 고치나 (기준일 2026-11-24, 국가법령정보센터 원문 대조)
#   mas-contract
#     · 2단계경쟁 대상: "2천만원 초과·3개 업체 비교견적·최저가" → 1회 납품요구 구매예산
#       중소기업자간 경쟁제품 1억원·그 외 물품 5천만원 이상, 5인 이상 제안요청, 합산점수 최고 업체
#     · 예외(제49조⑤·제50조), 분할 회피 금지(제51조), 제안공고(제52조의3)를
#       현행(5억원)과 2027.1.1. 시행분(그 외 물품 5천만원)으로 나눠 표기
#     · 법 제13조 인용문을 원문으로 교체, 법 제14조를 근거로 쓴 오류 제거
#     · 출처 없는 "행정안전부 유권해석" 2건(2천만원·3개 업체 주장) 삭제, 나머지 2건은 출처 미확인 표시
#   budget-settlement
#     · "2월 10일 출납 폐쇄", "6~7월 의회 제출", "8월 31일 승인 법정 기한" 등 오류 →
#       12/31 출납 폐쇄(예외 1/20)·2/10 출납사무 완결·80일 내 작성·5/31까지 제출·다음 해 승인
#     · 결산검사위원 선임 근거·인원·자격(지방자치법 제150조, 시행령 제83조·제84조)
#     · 교육비특별회계(교육감·교육부장관·시도의회)와 학교회계(학교운영위원회, 2개월) 구분 추가
#     · 출처 없는 "유권해석" 3건 → 조문 근거 질의응답으로 교체
#   감사사례 settlement-report-delayed (budget-settlement 페이지에 노출)
#     · "8월 31일 의회 제출 법정 기한"·"2월 10일 출납 폐쇄" → 5/31 제출(시행령 제10조①)·12/31 폐쇄
#     · 근거 없는 행안부 제재(재정관리위기단체 사전경보 등) 서술 삭제, 재구성 사례임을 표시
#
# 근거 조문
#   조달사업에 관한 법률 제12조·제13조, 같은 법 시행령 제13조 [시행 2026.9.11.]
#   물품 다수공급자계약 업무처리규정 제49조~제54조 [조달청훈령 제2400호, 2026.7.21. 시행]
#     · 제49조③·제52조의3 개정분은 훈령 제2393호 부칙 제1조제2호로 2027.1.1. 시행
#   지방회계법 제7조·제9조·제14조~제16조 [시행 2026.10.20.] / 같은 법 시행령 제3조·제10조 [시행 2026.6.2.]
#   지방자치법 제150조 [시행 2026.10.15.] / 같은 법 시행령 제83조·제84조 [시행 2026.7.1.]
#   지방교육자치에 관한 법률 제3조·제20조 / 초·중등교육법 제30조의3 [시행 2026.11.20.]
#
# 안전장치
#   · 바꿀 필드마다 2026-11-24 운영값의 SHA256 앞 16자리를 고정해 둔다.
#     운영값이 그 사이 바뀌었으면 아무것도 쓰지 않고 실패한다(다른 사람의 수정 덮어쓰기 방지).
#   · 이미 새 값이면 건너뛴다(멱등). 토픽 2건·감사사례 1건을 한 트랜잭션으로 쓴다.
#   · DRY_RUN=1 이면 바뀔 필드만 출력하고 쓰지 않는다.
#   · 새 본문은 data/20261124_mas_settlement/<slug>/<field>.(md|json) — 시드도 같은 파일을 읽는다.
require "digest"

module MasSettlementCorrection20261124
  DATA_DIR = Rails.root.join("db/content_migrations/data/20261124_mas_settlement")

  GUARDS = {
    "mas-contract" => {
      "decree_content" => "684ee0c2ba9b46e2",
      "faqs" => "f42b1ffb5eff3536",
      "flowchart_mermaid" => "8a57ec533ec7f154",
      "interpretation_content" => "111c99917f6de3cc",
      "law_content" => "2687d3999b436f94",
      "practical_tips" => "525bc2319ff9905a",
      "qa_content" => "5824c3b05da7f5d1",
      "regulation_content" => "22c0b65a75f6c33a",
      "rule_content" => "cc0b31d31abe4622",
      "summary" => "1e3ff27b83373ba6"
    },
    "budget-settlement" => {
      "decree_content" => "99385ba722ee4787",
      "faqs" => "0fb08b6a8788728a",
      "interpretation_content" => "81bf5da3ea377760",
      "law_content" => "3153351d11dd7871",
      "practical_tips" => "e7bafface80e13a5",
      "qa_content" => "e657ed1db186109a",
      "quick_stats" => "6d5a5261f4244904",
      "regulation_content" => "44418b5bbc9a2eae",
      "rule_content" => "a0184f019414b8a2",
      "summary" => "80b5535ef66173c2"
    }
  }.freeze

  # 감사사례 — 데이터 폴더 이름은 "audit-<slug>"
  AUDIT_GUARDS = {
    "settlement-report-delayed" => {
      "detail" => "540ac5b83bb1b149",
      "issue" => "6aacc79ef067c23b",
      "legal_basis" => "149932bf7cc33693",
      "lesson" => "c18c4736ab41dd4f"
    }
  }.freeze

  module_function

  # 새 값 { field => value } — 시드 파일에서도 호출한다.
  def values(slug)
    Dir[DATA_DIR.join(slug, "*")].sort.to_h do |path|
      field = File.basename(path).sub(/\.(md|json)\z/, "")
      raw = File.read(path, encoding: "UTF-8")
      [ field, path.end_with?(".json") ? JSON.parse(raw) : raw ]
    end
  end

  def canonical(value)
    return value.to_s unless value.is_a?(Array) || value.is_a?(Hash)

    JSON.generate(value.is_a?(Array) ? value.map { |h| h.is_a?(Hash) ? h.sort.to_h : h } : value.sort.to_h)
  end

  def fingerprint(value)
    Digest::SHA256.hexdigest(canonical(value))[0, 16]
  end

  # => [{ record:, label:, changes: {field => new} }], mismatches
  def plan
    mismatches = []
    targets = GUARDS.map { |slug, g| [ Topic.find_by!(slug: slug), slug, g ] } +
              AUDIT_GUARDS.map { |slug, g| [ AuditCase.find_by!(slug: slug), "audit-#{slug}", g ] }
    plans = targets.map do |record, dir, guards|
      new_values = values(dir)
      raise "#{dir}: 데이터 파일과 가드 필드가 다름" unless new_values.keys.sort == guards.keys.sort

      changes = {}
      guards.each do |field, guard|
        current = record.public_send(field)
        next if canonical(current) == canonical(new_values[field])

        if fingerprint(current) == guard
          changes[field] = new_values[field]
        else
          mismatches << "#{dir}.#{field} (운영값 #{fingerprint(current)} ≠ 기대 #{guard})"
        end
      end
      { record: record, label: dir, changes: changes }
    end
    [ plans, mismatches ]
  end

  def run!(dry_run: ENV["DRY_RUN"].present?)
    plans, mismatches = plan
    if mismatches.any?
      raise "운영값이 검증 시점과 달라 중단 — 아무것도 쓰지 않음: #{mismatches.join(', ')}"
    end

    plans.each do |p|
      puts "[#{dry_run ? 'dry-run' : 'apply'}] #{p[:label]}: #{p[:changes].keys.join(', ').presence || '변경 없음(이미 반영)'}"
    end
    return plans if dry_run

    Topic.transaction do
      plans.each { |p| p[:record].update!(p[:changes]) if p[:changes].any? }
    end
    plans
  end
end

MasSettlementCorrection20261124.run! unless defined?(MAS_SETTLEMENT_CORRECTION_LIBRARY_ONLY)
