# CHANGE_DETECTION_DESIGN — 법령·지침 변경 감지 설계

> **이번 세션 구현 없음. 설계만.**
> 그러나 이 문서는 가장 시급한 사실 하나에서 출발한다: **자동 검증이 이미 있었고, 2026-04-13에 꺼졌다.**

---

## 1. 현재 상태 (실측)

`config/recurring.yml`
```yaml
# 법령 정합성 자동 검증 (잠정 중단 2026-04-13)
# weekly_legal_check:
#   class: LegalComplianceJob
#   args: ["check"]
#   schedule: "0 10 * * 1"
```
- `LegalComplianceJob` **주석 처리됨**
- `GoogleSitemapPingJob`도 주석 처리 (2026-05-18 무한루프 사건 · Google Ping API 폐지)
- 살아 있는 잡: `SeoReportJob`(주/월/링크), `SitemapPingJob`(매일 06시)

**결과:** 전 콘텐츠의 마지막 검증이 **2026-06**에서 멈췄다 (2026-07 이후 0건). 오늘 2026-09-05 기준 3개월.
기준값 파일도 함께 낡았다 — `legal_standards.yml` 2026-02-04, `contract_thresholds.yml` 2026-03-28.

> **먼저 할 일은 새 감지 시스템을 만드는 것이 아니라, 왜 껐는지 확인하고 되살리는 것이다.**
> (`GoogleSitemapPingJob` 무한루프 전례가 있으므로 재가동 전 원인 규명이 선행 조건이다.)

---

## 2. 목표 파이프라인

```
        Official Source Watcher
        (법제처 API · 부처 RSS · 예규 고시)
                    │
                    ▼
            Version Detection
        (law_id + 시행일 + 본문 해시)
                    │
                    ▼
              OLD / NEW DIFF
        (조문 단위 · 삭제/신설/개정 분류)
                    │
                    ▼
          Affected Content Graph          ← SOURCE_GRAPH_DESIGN
        content_evidence_links 역방향 조회
                    │
        ┌───────┬───────┬───────┬───────┐
        ▼       ▼       ▼       ▼       ▼
      GUIDE   CASE    TOOL   TEMPLATE  AI KNOWLEDGE
        └───────┴───────┴───────┴───────┘
                    │
                    ▼
             REVIEW_REQUIRED
        (needs_review=true · review_reason 기록)
```

기존 자산 재사용:
- Watcher: `LawApiService` · `LawContentFetcher` · `LawSyncJob` · `MpmRssMonitorJob`(인사혁신처 RSS) — **이미 존재**
- 상태 필드: `topics.needs_review` · `review_flagged_at` · `review_reason` — **이미 존재**
- 검토 화면: `Admin::TopicReviewsController` (`/admin/topic_reviews`, `member { patch :resolve }`) — **이미 존재**
- 구독 알림: `law_change_subscriptions` + `LawChangeNotificationJob` — **이미 존재**

> **감지 시스템의 부품 대부분이 이미 코드에 있다. 없는 것은 ① 조문 단위 diff ② 영향 그래프 ③ 가동 중인 스케줄이다.**

---

## 3. 버전 감지

```
LawVersion { law_id, law_type, effective_date, promulgation_no, body_hash, article_hashes(jsonb), fetched_at }
```
- `body_hash`가 바뀌면 `article_hashes`를 대조해 **변경된 조문만** 추출한다.
- 조문 변경 유형: `NEW` / `AMENDED` / `DELETED` / `RENUMBERED`.
- `RENUMBERED`가 가장 위험하다 — 실제로 이 사이트에는 조문 번호 오류를 정정한 이력이 있다
  (`db/content_migrations/20260518000000_phase_1_legal_basis_corrections.rb`, 커밋 `94ef99f` "계약보증금 귀속 조문 번호 안전 표기 (소스 충돌로 번호 미확정)", `6035512` "계약보증금 면제 5천만원=상시(§53) 재정정").

---

## 4. 영향 판정

```sql
-- 변경된 조문을 근거로 삼은 모든 콘텐츠
SELECT source_type, source_id, article_ref, confidence
FROM content_evidence_links
WHERE target_type='Law' AND target_id=:law_id
  AND article_ref ~ :changed_article_pattern
  AND (applicable_to IS NULL OR applicable_to > CURRENT_DATE);
```

영향 심각도:
| 등급 | 조건 | 조치 |
|---|---|---|
| `CRITICAL` | 금액·기한·자격요건이 변경 + 도구가 참조 | 도구 즉시 `AMBIGUOUS` 반환 + 배너 |
| `HIGH` | 토픽의 핵심 기준 조문 변경 | `needs_review=true` + 배지 강등 |
| `MEDIUM` | 인용 조문 번호 변경 | 표기 정정 |
| `LOW` | 자구 정비 | 로그만 |

**핵심 규칙: 영향 판정 전까지 도구는 답을 계속 내면 안 된다.** 낡은 상수로 계산한 금액이 기안으로 들어가는 것이 가장 큰 위험이다(TR-03).

---

## 5. 사용자 표시

```
✅ 2026.07.21 개정사항 반영          ← 검증 완료 + 최신
⚠️ 2026.07.21 개정 확인 중 — 일부 기준이 달라질 수 있습니다   ← REVIEW_REQUIRED
🔴 이 도구는 개정 반영 전입니다. 결과를 기안에 사용하지 마세요.  ← CRITICAL
```

배지는 **자기고발이 가능해야 한다.** 지금처럼 검증이 3개월 멈춰도 화면이 계속 "검증 완료"라고 말하는 구조를 반복하지 않는다.
→ `review_due_at`을 두고, 경과 시 자동으로 `STALE_SUSPECTED`로 강등한다.

---

## 6. 착수 순서

| 단계 | 작업 | 선행 조건 |
|---|---|---|
| C1 | `LegalComplianceJob` 중단 사유 규명 | — |
| C2 | `review_due_at` 도입 + 경과 시 배지 자동 강등 | 메타 스키마 |
| C3 | `LawVersion` 스냅샷 적재 (법제처 API) | `laws` 정규화(G1) |
| C4 | 조문 단위 diff | C3 |
| C5 | 영향 그래프 조회 | `content_evidence_links`(G2~G4) |
| C6 | 스케줄 재가동 + 관리자 검토 큐 연결 | C1·C5 |

**C2만으로도 TR-05의 절반이 닫힌다** — 검증이 멈추면 화면이 스스로 말하게 되기 때문이다.
