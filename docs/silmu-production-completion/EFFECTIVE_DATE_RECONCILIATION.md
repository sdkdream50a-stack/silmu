# EFFECTIVE_DATE_RECONCILIATION — 시행일 정본 판정

> §12~§17. **분석·판정 완료 · 실제 write 하지 않음.**

---

## 1. 현재 상태 재실측 (§12 — 자동으로 채워졌다고 가정하지 않는다)

파서 수정(`1bb1c4e`)이 운영에 반영된 **이후** 다시 측정했다.

```
laws  total=15 · effective_date NOT NULL=0 · law_type=0 · ministry=0 · last_update 2026-06-15
```

15행 전부 `law_id` 컬럼에 **법령명이 들어가 있다**(MST 가 아니라 폴백 산출물).
→ **파서 수정은 과거 데이터를 소급해 채우지 않았다.** §12 의 경고가 맞았다.

## 2. 소비처 전수 추적 (§13 판단의 근거)

```
laws 테이블에 쓰는 곳     : LawSyncJob (Law.upsert_from_api!)  — 유일
laws 테이블을 읽는 곳     : Admin::TopicReviewsController (Law.count, Law.maximum(:updated_at)) — 통계 표시용
Law.current 스코프        : 사용처 0
Law#law_go_kr_url        : 사용처 0
```

### 공개 UI 의 시행일은 어디서 오는가
```
topics#show
  └ Rails.cache "topic_law_refs/v1/<slug>" (7일)
       └ miss → LawReferenceWarmJob → LawContentFetcher#fetch_for_topic
            └ LawApiService (법제처 실시간)
                 └ effective_display → topics/_law_reference_links → "(2026.06.03 시행)"
```

**`laws` 테이블은 공개 UI 경로에 없다.** 즉 `laws.effective_date` 의 공개 소비처는 **0** 이다.

## 3. §13 정본 결정

| 후보 | 판정 |
|---|---|
| A. legacy `laws.effective_date` | ❌ 공개 소비처 0 · 이력 없음 · 폴백 오염(law_id 에 법령명) |
| **B. `AuthorityVersion.effective_at`** | ✅ **채택** — immutable · 버전 이력 · 출처 URL · 공포일/시행일 분리 |
| C. Presenter 통합 | 불필요 — 통합할 두 소비처가 애초에 없다 |

```
SOURCE_OF_TRUTH = AuthorityVersion.effective_at
```

`laws` 는 **LawSyncJob 내부의 변경 감지용 스냅샷**으로 역할을 한정한다.
그 감지 기능은 Freshness Engine 이 더 정확하게 대체하므로 **DEPRECATED 후보**다(제거는 별도 판단).

## 4. §14~§16 — backfill 하지 않는다

§14 는 "채운다면 dry-run · official identifier match · HIGH confidence" 를 요구한다.
그러나 **채우지 않는 것이 옳다**고 판단했다. 근거:

1. **소비처가 0** — 채워도 사용자에게 보이는 것이 없다. 부채만 는다.
2. **자동으로 해결된다** — `LawSyncJob` 은 `recurring.yml` 에 **활성**이다.
   ```yaml
   weekly_law_sync:
     class: LawSyncJob
     schedule: "0 7 * * 2"   # 매주 화요일 07:00
   ```
   파서가 고쳐졌으므로 **다음 화요일 실행 시 15행이 공식 API 값으로 채워진다.**
   수동 backfill 은 같은 일을 덜 안전하게 앞당기는 것뿐이다.
3. **거짓 개정 알림이 발생하지 않는다** — 변경 감지는
   `prev_effective_date.present? && new_effective_date.present?` 조건이다.
   현재 prev 가 전부 NULL 이므로 첫 채움에서는 감지가 **발화하지 않는다**. 구조적으로 안전하다.

```
DECISION = NO_MANUAL_BACKFILL (scheduled job 이 공식 출처로 자동 해결)
```

## 5. §15 참고 자료 — 공식 시행일 (이미 확보된 값)

Freshness Engine 이 수집한 공식 값이다. 다음 `LawSyncJob` 결과 검증에 쓸 수 있다.

| laws.name | AuthorityVersion.effective_at | MST | 출처 |
|---|---|---|---|
| 지방자치단체를 당사자로 하는 계약에 관한 법률 | 2024-02-17 | 253973 | 법제처 API |
| 〃 시행령 | 2026-06-03 | 286149 | 법제처 API |
| 〃 시행규칙 | 2026-07-01 | 287365 | 법제처 API |
| 지방재정법 | (미추적) | — | — |
| 국가를 당사자로 하는 계약에 관한 법률 | (미추적) | — | — |
| 공무원 여비 규정 | (미추적) | — | — |
| 소득세법 · 공무원연금법 등 | (미추적) | — | — |

15행 중 **3행만** 현재 Freshness Engine 감시 대상과 겹친다. 나머지 12행은 아직 추적하지 않는다.
→ 그래서도 수동 backfill 은 부적절하다. 근거가 있는 것은 3건뿐이다.

## 6. §17 공개 UI 일치 확인

파서 수정 후 dev 에서 확인한 값:
```
fetch_law_meta("지방자치단체를 당사자로 하는 계약에 관한 법률 시행령")
  effective_display = "2026.06.03 시행"
```
Freshness Engine 이 독립적으로 수집한 값과 **일치한다** (`AuthorityVersion.effective_at = 2026-06-03`).
두 경로가 같은 공식 API 를 보므로 모순이 없다.

⚠️ **운영 공개 페이지에서 "(2026.06.03 시행)" 표기가 실제로 뜨는지는 아직 확인하지 못했다.**
`topic_law_refs` 캐시가 7일이라 기존 캐시(시행일 없음)가 남아 있을 수 있다.
→ 미완료 항목. 다음 세션에서 캐시 만료 후 또는 `LawReferenceWarmJob` 재실행 후 확인한다.

## 7. 후속 조치

- [ ] 화요일 `LawSyncJob` 실행 후 `laws.effective_date` 15행 채워짐 확인
- [ ] 그 결과가 공식 값과 일치하는지 위 표로 대조 (3건)
- [ ] 운영 토픽 페이지에 시행일 표기 실제 노출 확인 (캐시 만료 후)
- [ ] `laws` + `LawSyncJob` 을 Freshness Engine 으로 통합/폐기할지 판단
