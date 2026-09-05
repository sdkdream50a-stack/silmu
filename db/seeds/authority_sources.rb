# frozen_string_literal: true

# P1.5 §17·§52 — Canary Source Registry.
#
# 처음부터 17개 교육청·전국 조례를 감시하지 않는다.
# 실무.kr 에서 콘텐츠 연결 수가 가장 많고 도구·감사사례 영향이 큰 **지방계약 structured source** 부터 증명한다.
#
# 멱등: key 기준 find_or_initialize.

moleg = AuthoritySource.find_or_initialize_by(key: "moleg_law_api")
moleg.assign_attributes(
  name: "법제처 국가법령정보센터 (공동활용 API)",
  agency: "법제처",
  source_type: "STRUCTURED_API",
  authority_tier: 1,
  jurisdiction: "NATIONAL",
  region: "ALL",
  official_url: "https://www.law.go.kr",
  fetch_strategy: "law_api",
  enabled: true,
  check_interval_hours: 24,     # §23 high impact = daily
  config: { "api" => "DRF/lawSearch.do" }
)
moleg.save!

# Canary 문서군 — 지방계약 (§52)
# title 은 법제처 정식 법령명과 정확히 일치해야 한다(검색 키로 쓰인다).
CANARY_DOCUMENTS = [
  { key: "local_contract_act",        title: "지방자치단체를 당사자로 하는 계약에 관한 법률",
    short_title: "지방계약법",         document_type: "LAW" },
  { key: "local_contract_decree",     title: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령",
    short_title: "지방계약법 시행령",   document_type: "PRESIDENTIAL_DECREE" },
  { key: "local_contract_rule",       title: "지방자치단체를 당사자로 하는 계약에 관한 법률 시행규칙",
    short_title: "지방계약법 시행규칙", document_type: "MINISTERIAL_ORDINANCE" },
  # 확장 1단계 — 지방회계
  { key: "local_accounting_act",      title: "지방회계법",        short_title: nil, document_type: "LAW" },
  { key: "local_accounting_decree",   title: "지방회계법 시행령",  short_title: nil, document_type: "PRESIDENTIAL_DECREE" },
  # 확장 2단계 — 복무·보수
  { key: "local_public_official_act", title: "지방공무원법",      short_title: nil, document_type: "LAW" },
  { key: "local_public_official_duty", title: "지방공무원 복무규정", short_title: nil, document_type: "PRESIDENTIAL_DECREE" },
  { key: "local_public_official_pay",  title: "지방공무원 보수규정", short_title: nil, document_type: "PRESIDENTIAL_DECREE" }
].freeze

CANARY_DOCUMENTS.each do |attrs|
  doc = AuthorityDocument.find_or_initialize_by(key: attrs[:key])
  doc.assign_attributes(
    authority_source: moleg,
    title: attrs[:title],
    short_title: attrs[:short_title],
    document_type: attrs[:document_type],
    agency: "행정안전부",
    jurisdiction: "LOCAL",
    region: "ALL",
    status: "ACTIVE"
  )
  doc.save!
end

puts "AuthoritySource #{AuthoritySource.count}개 · AuthorityDocument #{AuthorityDocument.count}개 등록"
