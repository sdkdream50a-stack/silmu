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

# ── P4 (2026-09-20) — 학교회계 source 정규화 ──────────────────────────────────
# P3 가 수집한 법률 1 + 시·도 교육규칙 17 을 **기존 freshness engine 에 결속**한다.
# 새 테이블·새 잡·새 daemon 0 — 이미 있는 AuthoritySource/Document/Version 을 쓴다.
#
# 선언(층·관할·제목·일련번호)은 `config/school_accounting_rules.yml` 이 소유하고
# 여기서는 그것을 읽어 등록만 한다. 두 곳에 같은 목록을 적지 않는다.
# key 규약도 `SchoolAccountingSources.ordin_key` **하나**를 쓴다.

# 법률 — 기존 법제처 소스(moleg)에 문서 1건 추가. 조회는 이름으로(법령 API 규약).
SchoolAccountingSources.national_core.each do |rec|
  doc = AuthorityDocument.find_or_initialize_by(key: rec.key)
  doc.assign_attributes(authority_source: moleg, title: rec.title, short_title: nil,
                        document_type: "LAW", agency: "교육부",
                        jurisdiction: "NATIONAL", region: "ALL", status: "ACTIVE")
  doc.save!
end

# 자치법규 — 별도 소스. 법령 API 와 응답 스키마가 다르고(ordin_api) 개정 주기도 훨씬 길다.
# 24시간마다 17건을 더 치면 한 번 실행 상한(20건)을 법령 문서가 못 쓰게 된다 → 30일 주기.
ordin = AuthoritySource.find_or_initialize_by(key: "moleg_ordin_api")
ordin.assign_attributes(
  name: "법제처 국가법령정보센터 — 자치법규 (공동활용 API)",
  agency: "법제처",
  source_type: "STRUCTURED_API",
  authority_tier: 1,
  jurisdiction: "EDU_OFFICE",
  region: "ALL",
  official_url: "https://www.law.go.kr",
  fetch_strategy: "ordin_api",
  enabled: true,
  check_interval_hours: 24 * 30,
  config: { "api" => "DRF/lawService.do?target=ordin" }
)
ordin.save!

SchoolAccountingSources.regional_rules.each do |rec|
  doc = AuthorityDocument.find_or_initialize_by(key: rec.key)
  doc.assign_attributes(
    authority_source: ordin,
    title: rec.title,
    short_title: "#{rec.region} 학교회계 규칙",
    # 「규칙」 = 자치법규 종류 C0002. 기존 어휘를 그대로 쓴다 — 새 document_type 을 만들지 않는다.
    document_type: "LOCAL_RULE",
    agency: "#{rec.region}교육청",
    jurisdiction: "EDU_OFFICE",
    region: rec.region,
    # 이름이 통일돼 있지 않아 **일련번호로 조회**한다(AuthorityDocument#fetch_key).
    official_identifier: rec.official_identifier,
    status: rec.status
  )
  doc.save!
end

puts "AuthoritySource #{AuthoritySource.count}개 · AuthorityDocument #{AuthorityDocument.count}개 등록"
