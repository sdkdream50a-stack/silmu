# SOURCE_GRAPH_DESIGN — 근거 그래프 설계

> 목표: "이 법이 바뀌면 무엇이 틀리게 되는가"에 **즉시** 답할 수 있는 구조.
> 현재는 답할 수 없다 — 법령 본문이 `topics`의 텍스트 컬럼(`law_content`·`decree_content`·`rule_content`·`interpretation_content`)에 **문자열로 중복 저장**되고, 정규 `laws` 테이블은 로컬 기준 **0행**이다.

---

## 1. 노드

```
QUESTION ──canonicalizes──► TASK ──belongs_to──► TOPIC(도메인)
                             │
                             ├──governed_by──► LAW ──delegates──► DECREE ──delegates──► ENF_RULE
                             │                                   └──delegates──► ADMIN_RULE(훈령·예규·고시)
                             │                                                    └──► OFFICIAL_GUIDELINE(편람·집행기준)
                             ├──interpreted_by──► INTERPRETATION (유권해석·질의회신)
                             ├──evidenced_by────► AUDIT_CASE
                             ├──evidenced_by────► CASE_LAW (판결·행정심판·소청)
                             ├──uses───────────► FORM (서식)
                             └──solved_by──────► TOOL (계산기·판단기)
```

`AGENCY`는 노드가 아니라 **엣지의 속성**이다. 같은 TASK가 기관에 따라 다른 LAW로 연결된다.

```
TASK --governed_by{agency_type: LOCAL_GOVERNMENT}--> 지방계약법 §9
TASK --governed_by{agency_type: CENTRAL_GOVERNMENT}--> 국가계약법 §11
```

---

## 2. 엣지 속성 (공통)

```
{ applicable_from, applicable_to, agency_type[], region[], fiscal_system,
  source_tier, official_source_url, confidence, verified_at }
```

`confidence ∈ { CONFIRMED, PROBABLE, UNVERIFIED }` — 확신 없는 연결도 **끊지 않고 표시**한다. 침묵보다 낫다.

---

## 3. 기존 DB와의 호환 — incremental migration

**그래프 DB를 도입하지 않는다.** PostgreSQL 인접 리스트 1테이블로 충분하다(현재 규모: 노드 후보 ~1,500).

```ruby
# STEP 1 — laws 테이블 정규화 (이미 존재, 0행)
#   law_id(법제처 ID) · law_type(법률/시행령/시행규칙/행정규칙) · ministry
#   name · effective_date · content · article_index(jsonb) 추가
add_column :laws, :article_index, :jsonb, default: {}
add_column :laws, :official_source_url, :string
add_column :laws, :parent_law_id, :string     # 위임 체계 (법 → 령 → 규칙)
add_index  :laws, [:law_type, :effective_date]

# STEP 2 — 관계 테이블 1개
create_table :content_evidence_links do |t|
  t.string  :source_type, null: false   # Topic | Guide | AuditCase | Tool | Template
  t.bigint  :source_id,   null: false
  t.string  :relation,    null: false   # governed_by | interpreted_by | evidenced_by | uses | solved_by
  t.string  :target_type, null: false   # Law | Interpretation | AuditCase | CaseLaw | Form | Tool
  t.bigint  :target_id
  t.string  :article_ref                # "제25조제1항제5호나목"
  t.string  :agency_type, array: true, default: []
  t.string  :region,      array: true, default: []
  t.string  :source_tier
  t.string  :official_source_url
  t.string  :confidence, null: false, default: "UNVERIFIED"
  t.date    :applicable_from
  t.date    :applicable_to
  t.datetime :verified_at
  t.timestamps
  t.index [:source_type, :source_id]
  t.index [:target_type, :target_id]
  t.index [:relation, :confidence]
end
```

### 파괴적 변경 없음
- `topics.law_content` 등 **기존 텍스트 컬럼을 삭제하지 않는다.** 렌더는 그대로 동작한다.
- 링크 테이블은 **부가 정보**로 시작한다. 충분히 채워진 뒤에 렌더 소스를 전환한다.
- 채우는 방법: 기존 자산 3개를 그대로 쓴다.
  1. 토픽 본문의 법제처 딥링크 **813개** (이미 존재 — `law.go.kr` 656 · `mois` 115 · `g2b` 113)
  2. `audit_cases.legal_basis` 문자열 파싱
  3. `config/contract_thresholds.yml`의 `basis:` 필드 (조문이 이미 구조화되어 있음)

---

## 4. 이 그래프가 열어주는 질문

| 질문 | 쿼리 |
|---|---|
| 지방계약법 §25가 개정되면 무엇이 영향받는가 | `content_evidence_links WHERE target=Law(지방계약법) AND article_ref LIKE '제25조%'` |
| 이 토픽의 근거 중 6개월 이상 미검증은 | `verified_at < now() - 6.months` |
| 교육청에만 적용되는 규칙은 | `agency_type @> '{EDUCATION_OFFICE}'` |
| 근거 없는 결론을 가진 콘텐츠는 | `source`에 링크가 0개인 콘텐츠 |
| 감사원 원문이 없는 실제 감사사례는 | `relation=evidenced_by AND official_source_url IS NULL` (현재 **257건 전부**) |

마지막 쿼리가 오늘 시점의 답을 바로 준다 — 그것이 이 그래프를 만드는 이유다.

---

## 5. 구축 순서

| 단계 | 작업 | 산출 |
|---|---|---|
| G1 | `laws` 정규화 + 법제처 API로 현행 조문 적재 | 법령 노드 |
| G2 | 토픽 813 딥링크 → `content_evidence_links` 자동 생성 (`confidence: PROBABLE`) | 엣지 초기 집합 |
| G3 | `contract_thresholds.yml`의 `basis:` → 엣지 (`CONFIRMED`) | 고신뢰 엣지 |
| G4 | 감사사례 `legal_basis` 파싱 → 엣지 | 사례 연결 |
| G5 | 영향 그래프 뷰 = `CHANGE_DETECTION_DESIGN`의 입력 | 변경 감지 가동 |
