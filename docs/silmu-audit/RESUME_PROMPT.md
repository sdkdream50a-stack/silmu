# RESUME_PROMPT — 다음 세션 시작 프롬프트

> 이 파일 하나만 붙여넣으면 다음 세션이 바로 이어진다.

---

## 붙여넣기용 프롬프트

```
silmu.kr P1 작업을 이어서 한다.

프로젝트: /Users/seong/project/silmu  (Rails 8.1 + PostgreSQL, Kamal → 141.164.53.97)
선행 감사: docs/silmu-audit/  (2026-09-05 완료, 운영 564 URL 전수 크롤 기반)

시작 전 반드시 읽을 것:
  1. docs/silmu-audit/AUTHORITY_AUDIT_REPORT.md   ← 무엇이 문제인가 (실측)
  2. docs/silmu-audit/TRUST_RISK_REGISTER.md      ← TR-01~TR-12
  3. docs/silmu-audit/P1_IMPLEMENTATION_PLAN.md   ← 무엇을 이 순서로 할 것인가
  4. docs/silmu-audit/AUTHORITY_METADATA_SCHEMA.md
  5. docs/silmu-audit/AUDIT_CASE_PROVENANCE_SPEC.md

이번 세션 목표: Phase 1 (P0 신뢰 수술) 중 P1-1과 P1-2.

  P1-1  검증 배지와 출처 분리
        - verification_note 컬럼 추가(관리자 전용) + 기존 verification_source 무손실 복사
        - verification_method 5개 enum 표준화
        - 공개 렌더에서 내부 메타데이터(커밋 해시·batch·lawId·dashboard 키) 제거
        - 배지 문구 "5단계 정합성 검증 완료" → "법령 근거 검증 완료"

  P1-2  감사사례 provenance 부여 (257건)
        - provenance / original_document_url / source_page / disposition / audit_year / audit_name 추가
        - AUDIT_CASE_PROVENANCE_SPEC §5 STEP 1~5 backfill
        - 재구성 사례에 제목 라벨 강제

제약 (P0 감사와 동일):
  - 스키마 변경은 additive·nullable만. destructive migration 금지.
  - 콘텐츠 본문 재작성 금지. 삭제 금지. URL 이동 금지.
  - 운영 DB 파괴적 변경 금지.
  - backfill은 db/content_migrations/ 기존 멱등 패턴 사용 (새 기계 만들지 말 것).
  - Hermes / Revenue OS / 다른 lane 무수정.

완료 판정 (기계 검사):
  운영 재크롤 후 공개 HTML에서
    commit / batch / lawId / backlog  문자열 = 0건
    provenance 미분류 감사사례        = 0건
    배지 표시 + 원문 URL 결손          = 0건
  그리고 bin/rails test 가 baseline(242 runs / 0 failures / 14 skips) 대비 비퇴화.

재크롤·재측정 방법:
  docs/silmu-audit/tools/extract_pages.py  (sitemap 전수 크롤 → extracted.json)
  docs/silmu-audit/tools/build_audit.py    (분류 → CONTENT_AUDIT.csv)
```

---

## 현재 상태 스냅샷 (2026-09-05)

| 항목 | 값 |
|---|---|
| 브랜치 | `fix/tool-accuracy-p1-0804` (미커밋 변경 다수 — 감사 착수 전부터 존재) |
| 최신 커밋 | `7405624` |
| 테스트 baseline | **242 runs · 2,173 assertions · 0 failures · 0 errors · 14 skips** |
| 이번 세션 앱 코드 변경 | **0** (감사 전용. `docs/silmu-audit/` 신규 추가만) |
| 운영 콘텐츠 | audit-cases 257 · topics 114 · guides 107 · tools 37 · templates 26 · series 8 |
| 로컬 dev DB | topics 92 · guides 103 · audit_cases 191 (**stale — 정본 아님**) |

## 첫 3개 게이트 (Phase 1 완료 조건)

| # | 게이트 | 현재 | 목표 |
|---|---|---:|---:|
| G1 | 공개 HTML 내부 메타데이터 문자열 | 136 | 0 |
| G2 | provenance 미분류 감사사례 | 257 | 0 |
| G3 | 배지 표시 + 원문 URL 결손 | 246 | 0 |

## 함정 (반복하지 말 것)

1. **로컬 dev DB를 정본으로 삼지 말 것.** 운영보다 최대 66건 뒤처져 있다(TR-11).
2. **부분문자열 매칭으로 출처를 분류하지 말 것.** 이번 감사 초기에 `silmu 자체 시드 — 공개 감사패턴(GOE 2021·SEN 2024 등) 일반화`가 `GOE 2021`에 걸려 16건을 오귀속으로 잘못 판정했다. 라이브 재확인으로 기각했다. **정확 매칭 + 실물 확인**이 원칙이다.
3. **사이드바·관련콘텐츠를 본문으로 세지 말 것.** `<main>` 안에도 추천·목차 블록이 있어 절단 마커가 필요하다(`tools/build_audit.py`의 `CUT` 정규식).
4. `LegalComplianceJob`을 사유 확인 없이 되살리지 말 것 — 같은 파일에 `GoogleSitemapPingJob` 무한루프 사건 전례가 있다.
5. **"0건"을 보고하기 전에 양성 대조를 하라.** 이번 감사에서 3개의 0을 대조했더니 2개가 바뀌었다.
   · "감사사례 공식 원문 링크 0" → 링크는 0이지만 조문 표기 219건·텍스트 도메인 94건이 이미 있었다(수정 비용이 훨씬 낮음).
   · "AI 근거 주입 없음" → 주입 코드는 있고 **UI 배선만 없었다**(`ai_assistant_channel.rb:31-44`).
   검출기가 `<main>`으로 좁혀져 있거나 표현형이 여럿이면 나머지는 조용히 0이 된다.
