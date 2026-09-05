# SOURCE_REGISTRY — 감시 대상 등록부

> 처음부터 인터넷 전체를 감시하지 않는다(§16). 등록된 것만 본다.

## 1. 현재 등록 (2026-09-06)

### Source
| key | 이름 | tier | 유형 | 전략 | 주기 |
|---|---|:--:|---|---|---:|
| `moleg_law_api` | 법제처 국가법령정보센터 (공동활용 API) | 1 | STRUCTURED_API | `law_api` | 24h |

### Documents — Canary (§52 지방계약 우선)
| key | 문서 | 유형 | 수집된 시행일 | 연결 콘텐츠 |
|---|---|---|---|---:|
| `local_contract_act` | 지방자치단체를 당사자로 하는 계약에 관한 법률 | LAW | 2024.02.17 | 32 |
| `local_contract_decree` | 〃 시행령 | PRESIDENTIAL_DECREE | 2026.06.03 | 77 |
| `local_contract_rule` | 〃 시행규칙 | MINISTERIAL_ORDINANCE | 2026.07.01 | 4 |
| `local_accounting_act` | 지방회계법 | LAW | 2026.01.02 | 11 |
| `local_accounting_decree` | 지방회계법 시행령 | PRESIDENTIAL_DECREE | 2026.06.02 | 0 |
| `local_public_official_act` | 지방공무원법 | LAW | 2026.06.02 | 16 |
| `local_public_official_duty` | 지방공무원 복무규정 | PRESIDENTIAL_DECREE | 2026.06.23 | 2 |
| `local_public_official_pay` | 지방공무원 보수규정 | PRESIDENTIAL_DECREE | 2026.08.01 | 12 |

**왜 지방계약부터인가 (§52)** — 연결 콘텐츠가 가장 많고(113/154), 도구 영향이 있으며, 감사사례 근거의 다수를 차지한다. 여기서 실패하면 다른 영역도 실패한다.

## 2. Tier 정책 (§7)

| Tier | 대상 | 현행성 근거 |
|:--:|---|:--:|
| 1 | 국가법령정보센터 · 중앙행정기관 · 법원/헌재 · 감사원 · 조달청 · 인사혁신처 · 행안부 · 교육부 | ✅ |
| 2 | 시·도 · 시군구 · 17개 교육청 · 공공기관 규정 · 지방재정365 · 알리미 · ALIO | ✅ (적용범위 명시 필수) |
| 3 | 공신력 있는 전문기관 공식 해설 | ✅ (단독 근거 금지) |
| 4 | 카페 · 블로그 · 커뮤니티 · 개인자료 | ❌ **질문 발굴 전용** |

코드 강제: `AuthoritySource#usable_for_currency_judgement?` → `tier <= 3`.
회귀 테스트가 tier 4 를 거부하는지 확인한다.

## 3. 주기 (§23)

| 등급 | 주기 | 대상 |
|---|---:|---|
| High impact | 24h | 지방계약 3종 등 핵심 법령 |
| 일반 공식 지침 | 168h (주간) | 예규·훈령 |
| 연간 편람 | 720h (월간) | 업무편람·기본지침 |

`AuthoritySource#check_interval_hours` 로 소스별 조절. `due?` 가 주기를 넘겼는지 판단한다.
회귀 테스트: 25시간 경과 시 일간 소스는 due, 주간 소스는 due 아님.

## 4. Structured vs Unstructured (§18)

| 구분 | 예 | fetcher | 상태 |
|---|---|---|---|
| Structured | 법률·시행령·시행규칙·행정규칙 | `Authority::LawApiFetcher` | ✅ 구현 |
| Unstructured | PDF 지침 · 업무편람 · 교육청 매뉴얼 · FAQ | (미구현) | 설계만 |

**같은 parser 로 처리하지 않는다.** `AuthoritySource#source_type` + `fetch_strategy` 로 분기하며,
지원하지 않는 전략은 조용히 성공하지 않고 `PARSE_FAILED` 로 실패한다(회귀 테스트 있음).

## 5. 확장 순서

```
1) 지방계약  ✅ 완료
2) 지방회계  ✅ 등록 (연결 11)
3) 복무·보수 ✅ 등록 (연결 30)
4) 국가공무원 (국가공무원법·복무규정·보수규정)      — 등록만 하면 됨
5) 행정규칙 (지방자치단체 입찰 및 계약집행기준 등)   — 법제처 target=admrul 필요
6) 교육행정 지침 (교육부·교육청)                  — UNSTRUCTURED fetcher 필요
7) 17개 교육청                                  — EDUCATION_OFFICE_STRATEGY.md
```

4번까지는 `db/seeds/authority_sources.rb` 에 항목만 추가하면 된다(코드 변경 없음).
5번부터 새 fetcher 가 필요하다.

## 6. 등록 방법

```ruby
# db/seeds/authority_sources.rb 에 추가 후
bin/rails silmu:freshness:seed_sources   # 멱등
```
`title` 은 **법제처 정식 법령명과 정확히 일치**해야 한다(검색 키로 쓰인다).
불일치 시 `PARSE_FAILED — 검색 결과 없음` 으로 즉시 드러난다.
