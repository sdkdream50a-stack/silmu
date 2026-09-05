# P2_HANDOFF — P1.6 이후

> `P2_GATE = CONDITIONAL` **유지**. 콘텐츠 개수가 아니라 신뢰 시스템과 도달 경로가 먼저다(§86).

## 1. P1.6 이 남긴 것

| 자산 | 상태 |
|---|---|
| 자연어 검색 recall | 복구 (stopword·조사분리·과반 완화) |
| Answer-First | FAQ 331건을 "바로 답"으로 노출. 생성 없음 |
| 업무 taxonomy | `TaskEntryHelper` — **런타임 count 게이트**. 콘텐츠가 생기면 카드가 자동 등장 |
| Solution Page | 대표 페이지(topics#show)에 first viewport 적용 |
| Freshness UI | presenter 경유. 거짓 CURRENT 구조적 불가 |
| Zero-result signal | 기존 `SearchLog.zero_result` 재사용 (§42 Radar 기반) |

## 2. P2 콘텐츠 확대 1순위 — 실측 기반

`SearchLog.content_gap_candidates` 와 이번 실측이 같은 곳을 가리킨다.

| 후보 | 근거 | 현재 자산 |
|---|---|---:|
| **정보공개** | §17·§18 이 예시로 든 대표 업무인데 **전 자산 0건** | 0 |
| 재산·물품 | `topic.category=property` 발행 0 → 업무 카드가 자동 제외됨 | 0 |
| 민원 | guide 1건뿐 | 1 |
| 시설·안전 | 매핑 자체 없음 | 0 |

**확대하면 UI 는 손대지 않아도 된다** — count 게이트가 카드를 자동으로 켠다.
이 성질은 회귀 테스트(`콘텐츠가 생기면 업무가 자동으로 나타난다`)로 고정돼 있다.

## 3. P2 착수 전 선행 조건

```
1. AuthorityFreshnessCheckJob 스케줄러 활성화 판단 (별도 승인)
   → 알림 인프라는 P1.55B 에서 준비됨. 다만 운영 SMTP 실도달은 여전히 LIVE_UNPROVEN
2. laws.effective_date — 2026-09-08 07:00 weekly_law_sync 결과 관측 후 판단
3. P1.6 운영 배포 + 자연 트래픽에서 검색 성공률·zero_result 율 관측
```

## 4. P2 가 이어받을 미해결

| 항목 | 성격 |
|---|---|
| `bid-notice-requirements` 의 `category="입찰"` | 라우트 제약 밖 → 카테고리 내비에서 고아. **데이터 정정**(콘텐츠 무변경 원칙 때문에 P1.6 에서 안 고침) |
| HowTo JSON-LD 가 malformed step 을 그대로 내보냄 | 선재 결함. 구조화 데이터 품질 |
| `closeDocPopup()` 버튼 접근 이름 없음 | 선재 a11y |
| 공개 콘텐츠 internal 표현 4건 (AuditCase 3 · Topic 1) | 기존 편집 backlog. AI bulk rewrite 금지 |
| Guide/AuditCase 에 Solution Page 미적용 | §41 충돌 위험 높음 파일. P1.6 은 대표 페이지로 증명만 |
| Docker 배포 우회 A/B/C 미결정 | BUILDER_RECOVERY §6 |

## 5. P2 에서 하지 말 것

```
검색을 LLM/RAG 로 갈아엎기        — 먼저 keyword·synonym·intent 로 얼마나 가는지 측정된 상태다
동의어 대량 자동 생성              — 연상어를 넣으면 "바로 답"이 다른 질문에 답한다(P1.6 실측)
없는 업무 카드를 먼저 만들기        — 카드는 콘텐츠의 결과지 원인이 아니다
콘텐츠 개수를 성과 지표로 쓰기      — §83
```
