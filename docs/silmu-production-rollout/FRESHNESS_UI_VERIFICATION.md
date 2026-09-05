# FRESHNESS_UI_VERIFICATION — 공개 신선도 UI 검증

> §28·§29 — 운영에서 실제 engine 상태와 UI 가 일치해야 한다.

## 1. 현재 운영 상태와 UI 의 일치

엔진 상태:
```
변경 이벤트 8건 (전부 NEW_DOCUMENT = 기준선)
검토 태스크 0건
콘텐츠 freshness_state: Topic 0 · Guide 0 · AuditCase 0
```

UI 상태:
```
⚠ 최신 개정사항 검토 중  →  0 페이지
```

**일치한다.** 기준선은 개정이 아니므로 경고를 띄우지 않는다(§18·§19).

## 2. §28 세 가지 표시 규칙

### ① Engine operational + content current
```
✅ 공식 원문 확인 · 2026-05-21
   공식 발행 문서 원문까지 확인했습니다.  [검증 절차]
   📚 출처: 경기도교육청 감사관실 · 감사사례집 · 2021 p.122  [공식 원문 보기]
```
운영 `/audit-cases/goe-2021-management-allowance-mispayment` 실측.

### ② Change detected but not reviewed
```
⚠ 최신 개정사항 검토 중
   근거 법령의 개정이 감지되어 이 콘텐츠에 미치는 영향을 검토하고 있습니다.
   검토가 끝나기 전까지는 공식 원문을 함께 확인해 주세요.
   감지된 개정 시행일: YYYY.MM.DD (시행 예정)
```
구현: `app/views/shared/_freshness_notice.html.erb`
노출 조건 `freshness_attention?` = `CHANGE_DETECTED | REVIEW_REQUIRED | SOURCE_UNAVAILABLE`
**현재 운영에서 해당 콘텐츠 0건** — 실제 개정이 아직 없기 때문이다.

### ③ Source unavailable — 과도한 오류 경고 금지
```
⚠ 공식 출처 확인 불가
   공식 출처를 일시적으로 확인할 수 없습니다.
   중요한 업무 판단 전에는 공식 원문을 직접 확인해 주세요.
```
회색 톤(`bg-slate-50`)으로 낮춘다. 사용자에게 시스템 장애를 크게 알리지 않는다.
게시 취소·삭제는 하지 않는다.

## 3. §29 — 약한 연결에 배지 강제 금지

`show_agency_scope?` = `target_agency` 존재 **AND** `agency_scope_confidence == "HIGH"`
→ MEDIUM/LOW 는 화면에 나가지 않는다.

운영 실측:
```
audit_cases  agency HIGH 210 / 257   (47건은 표시 안 함)
topics       agency HIGH  15 / 114   (99건은 표시 안 함)
guides       agency HIGH   0 / 103   (전부 표시 안 함)
```
**Guide 103건 전부 "적용 대상"을 표시하지 않는다.** 판정 신호가 없기 때문이고, 이것이 의도된 동작이다.
빈 메타데이터보다 거짓 신뢰가 위험하다.

마찬가지로 `provenance` 가 `UNVERIFIED` 인 61건은 `출처 추가 검증 필요` 로 정직하게 표시된다 —
"현재 기준 확인" 배지를 강제로 붙이지 않는다.

## 4. §30 도구

운영 도구 10종이 Authority Graph 에 연결되어 있다(간선 기준).
현재 **자동 경고를 생성하지 않았다** — 실제 변경이 없기 때문이다.
도구 계산식은 어떤 경우에도 자동 변경되지 않는다.

`/tools/contract-method` 실측:
```
적용 기준  지방계약법령 계약방법 결정 기준
계약 기준값 기준일  2026-03-28
계산 근거  [지방계약법 제9조] [지방계약법 시행령 제25조, 제30조]   ← 링크
ⓘ 계산 결과는 실무 참고용입니다 …
```

## 5. §31 Template

```
TEMPLATES_TRACKED = 0
```
서식에는 `config/tool_trust.yml` 같은 근거 등록부가 아직 없다.
이번 rollout 성공 조건에 포함하지 않았다(§31). P2 별도 확장 과제.

## 6. §4·§37·§39 — 과장 금지

전 페이지 실측 결과 다음 문구 **0건**:
```
자동 현행화 중 · 실시간 법령 반영 · 항상 최신 · 100% 최신 · 모든 개정 자동 반영
자동 검증 및 5단계 게이트를 운영하고 있으나
```

현재 푸터(유지):
> 실무.kr은 법령·지침의 현행성을 지속적으로 점검하고 있습니다. 중요한 업무 판단 전에는 각 페이지의 기준일과 공식 근거를 함께 확인해 주세요. …

**"법령·지침 변경을 자동 감지하고 있습니다" 는 아직 쓰지 않는다** — 스케줄러가 꺼져 있고 자연 주기 실행을 관측하지 않았다.

## 7. 캐시 주의

Cloudflare 엣지 캐시 TTL 4시간(`cache-control: public, max-age=14400, stale-while-revalidate=3600`).
**backfill·freshness 상태 변경은 최대 4시간 뒤에 사용자에게 보인다.**

검토가 끝나 `VERIFIED_AFTER_CHANGE` 로 바뀌어도 경고가 최대 4시간 더 보일 수 있다.
반대로 개정 감지 직후 경고도 최대 4시간 늦게 뜬다.
→ 실제 개정 대응 시에는 Cloudflare 캐시 purge 를 함께 고려해야 한다(P2 운영 절차).
