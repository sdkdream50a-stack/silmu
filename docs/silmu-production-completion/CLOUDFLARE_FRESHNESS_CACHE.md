# CLOUDFLARE_FRESHNESS_CACHE — 캐시 지연 (미착수)

> §18~§21. **이번 세션에서 조사·구현하지 않았다.** 사실만 유지한다.

## 1. 알려진 사실 (P1.55 실측)

```
cache-control: public, max-age=14400, stale-while-revalidate=3600
cf-cache-status: HIT / MISS
age: <초>
```
Cloudflare 엣지 캐시 TTL **4시간**.

P1.55 에서 실제로 겪은 것:
- provenance backfill 직후 공개 페이지가 **이전 상태로 보였다**
- DB 값은 처음부터 정확했다
- `?cb=<ts>` + `Cache-Control: no-cache` 로 우회하니 정상 렌더

## 2. Authority 관점 위험

```
CHANGE_DETECTED   상태 → 사용자에게 최대 4시간 늦게 경고가 보인다
REVIEW_REQUIRED   상태 → 검토가 끝나 해제돼도 최대 4시간 더 경고가 보인다
```

일반 콘텐츠에는 문제가 아니지만, **"지금 이 기준이 맞는가"** 를 답하는 사이트에서는
경고 지연이 신뢰 문제로 이어질 수 있다.

## 3. 상태

```
DECISION = DESIGN_ONLY (미착수)
```

§21 이 허용한 대로 설계만 남기고 구현하지 않았다.
다만 §21 후단 요구대로 **"최대 4시간 늦게 경고가 보일 수 있다"는 사실은 운영 문서에 유지**한다.

## 4. 다음 세션 검토안 (§19~§20)

먼저 확인할 것 — 추측하지 말 것:
```
현재 Rails 가 보내는 Cache-Control (컨트롤러별 차이)
CDN-Cache-Control 사용 여부
Cloudflare 캐시 규칙(Page Rules / Cache Rules)
purge API 사용 가능 여부 (API 토큰 존재?)
```

검토 방향(우선순위 순):
1. **freshness 상태 변경 시 해당 URL 만 purge** — 전체 성능 희생 없음. Cloudflare purge API 필요
2. **freshness 민감 페이지만 TTL 단축** — 예: `freshness_attention?` 인 콘텐츠에 짧은 `max-age`
3. 전 사이트 `no-cache` — **하지 않는다**(성능 희생이 크다)

⚠️ 1번은 외부 API 호출을 콘텐츠 상태 변경에 결합시킨다. Freshness Engine 의 READ-ONLY 원칙과
충돌하지 않는지(=purge 실패가 상태 전이를 막지 않는지) 설계 단계에서 확인해야 한다.
