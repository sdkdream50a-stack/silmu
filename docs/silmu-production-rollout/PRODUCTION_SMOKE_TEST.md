# PRODUCTION_SMOKE_TEST — 배포 후 스모크

> §11 — 5xx / layout regression / missing component 가 없어야 한다.

## 1. 대표 URL 18종 (Stage 1 직후)

| HTTP | 응답시간 | 크기 | URL | 신규 컴포넌트 |
|---:|---:|---:|---|---|
| 200 | 0.86s | 100KB | `/` | 푸터정정 |
| 200 | 0.76s | 242KB | `/topics` | 푸터정정 |
| 200 | 1.30s | 238KB | `/topics/private-contract` | 푸터정정 |
| 200 | 2.42s | 305KB | `/guides` | 푸터정정 |
| 200 | 0.48s | 96KB | `/guides/purchase-and-inspection` | 푸터정정 |
| 200 | 0.76s | 121KB | `/audit-cases` | 푸터정정 |
| 200 | 1.05s | 104KB | `/audit-cases/private-contract-over-limit` | provenance·푸터정정 |
| 200 | 0.25s | 190KB | `/tools` | — |
| 200 | 0.62s | 122KB | `/tools/contract-method` | 도구신뢰·푸터정정 |
| 200 | 0.40s | 102KB | `/tools/pdf` | 도구신뢰·푸터정정 |
| 200 | 0.71s | 123KB | `/templates` | — |
| 200 | 0.62s | 93KB | `/silmu-search` | 푸터정정 |
| 200 | 0.28s | 134KB | `/faq` | — |
| 200 | 0.23s | 91KB | `/about` | — |
| 200 | 0.61s | 104KB | `/sitemap.xml` | — |
| 200 | 0.50s | 22KB | `/llms.txt` | — |
| 200 | 0.34s | 15KB | `/feed.rss` | — |
| 200 | 0.45s | 1KB | `/up` | — |

**5xx 0건 · 비정상 응답 0건.**

## 2. backfill 후 렌더 검증 (캐시 우회)

⚠️ Cloudflare 엣지 캐시 TTL 4시간(`cache-control: public, max-age=14400`).
backfill 직후 첫 조회는 `cf-cache-status: HIT` 로 **이전 렌더가 나왔다.**
`?cb=<timestamp>` + `Cache-Control: no-cache` 로 우회해 재검증했다.

### 실제 감사결과 사례 `/audit-cases/goe-2021-management-allowance-mispayment`
```
[provenance] 🟢 실제 감사결과 — 공공기관이 공개한 감사결과 문서에 근거한 사례입니다.
[verify]     공식 원문 확인 · 2026-05-21
             "공식 발행 문서 원문까지 확인했습니다."
[trustblock] 법령 근거: 공무원보수규정 / 지방공무원 보수규정 / 공무원수당 등에 관한 규정 …(링크)
             적용 대상: 공립학교
             출처: 경기도교육청 감사관실 · 감사사례집 · 2021
누출: 없음
```

### 재구성 사례 `/audit-cases/private-contract-over-limit`
```
[provenance] 📘 실무.kr 재구성 사례 — 특정 기관의 실제 감사결과 원문을 그대로 재현한 것이 아니라 …
             ⚠️ 본문의 기관명·인물·금액은 실무 이해를 돕기 위한 예시입니다.
[verify]     법령 근거 검증 · 2026-06-09
             "인용한 법령·조문을 국가법령정보센터 원문과 대조했습니다. 사례의 사실관계 검증과는 다릅니다."
[trustblock] 법령 근거: 지방계약법 시행령 제25조(링크) / 적용 대상: 지방자치단체
누출: 없음
```

### 토픽 `/topics/private-contract`
```
[verify] 내용 정합성 검토 2026-06-09 · 실무.kr 검토일
         "실무.kr 내부 기준으로 내용 일관성을 검토했습니다. 공식 원문 대조는 포함되지 않습니다."
         [검증 절차] 링크
구 배지 문구("5단계 정합성 검증 완료") 잔존: False
누출: 없음
```

## 3. 누출 검사

전 페이지에서 `Phase A` · `batch 0` · `commits ` · `eed3ceb` · `lawId` · `backlog` · `운영 정합` · `차후 정밀화` 검색.

| 대상 | 결과 |
|---|---|
| 감사사례·토픽 상세 (렌더 경계) | **0건** |
| 운영 `leak_scan` (474건 검사) | 경계가 막아낸 at_risk **287건** · 실제 누출 **0건** · positive control OK |

### 다만 — 콘텐츠 본문 자체에 남은 내부 표현 (P1 경계 밖)
`/topics` 인덱스의 JSON-LD `description` 에서 `Phase A` 문자열이 검출되었다.
추적 결과 **렌더 누출이 아니라 원고 본문에 쓰인 내부 작업 표현**이다.

```
"… 1,008,200원 과다 지급으로 5년 시효 환수 대상이 됩니다.
  Phase A #1 (호봉 누락·과소)의 대칭 사례입니다."
```

운영 실측 범위:
| 대상 | 건수 |
|---|---:|
| audit_cases | **3** (`goe-2021-tenure-allowance-mispayment`, `goe-2021-overtime-allowance-mispayment`, `goe-2021-suspension-pay-deduction`) |
| topics | **1** |
| guides | 0 |

- 이번 배포로 생긴 회귀가 **아니다** (기존 원고에 이미 존재)
- `InternalMetadataFilter` 는 출처·검증 렌더 경계를 지키는 장치이며 **본문 원고는 대상이 아니다**
- §27 에 따라 **자동 수정하지 않았다.** 사람이 4건을 편집해야 한다 → `P2_GATE_DECISION.md` 잔여 위험에 등재

## 4. 인프라 영향

같은 서버의 다른 앱 5종 컨테이너 상태 변화 없음. `kamal-proxy` 재기동 없음.
