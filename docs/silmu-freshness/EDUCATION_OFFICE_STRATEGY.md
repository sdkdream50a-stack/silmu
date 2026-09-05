# EDUCATION_OFFICE_STRATEGY — 교육청 확장 전략 (설계만)

> §36·§37·§54 — 이번 단계에서 17개 교육청 adapter 를 구현하지 않는다. **구조만 지원한다.**

## 1. 왜 복사본으로 관리하면 안 되는가

17개 교육청 × 학교회계·예산편성·재무회계 지침을 각각 독립 문서로 관리하면
- 교육부 공통 기준이 바뀔 때 17곳을 따로 고쳐야 하고
- 어느 것이 공통이고 어느 것이 지역 특례인지 알 수 없어지며
- 사용자는 자기 지역 기준을 찾지 못한다

## 2. 상속 모델 (§36)

```
        교육부 공통 기준 (COMMON)
                 │
        시도교육청 Override (REGIONAL_OVERRIDE)
                 │
     교육지원청 / 학교 적용 (INHERITED)
```

기존 스키마가 이미 이를 표현할 수 있다.

```
authority_documents.jurisdiction = "EDUCATION"
authority_documents.region       = "ALL" | "서울특별시" | "경기도" | …
```

- `region = "ALL"` → 교육부 공통
- `region = "경기도"` → 경기도교육청 override

조회 규칙(설계):
```ruby
# 사용자 지역이 "경기도" 일 때
docs = AuthorityDocument.where(jurisdiction: "EDUCATION")
                        .where(region: [ "경기도", "ALL" ])
                        .order(Arel.sql("CASE region WHEN 'ALL' THEN 1 ELSE 0 END"))
# → 지역 문서가 있으면 그것이, 없으면 공통이 적용된다
```

**콘텐츠를 복제하지 않고 근거만 분기한다.** P1 `AGENCY_RULE_MODEL.md` 의 `COMMON_RULE + OVERRIDE` 와 같은 원리다.

## 3. Canary 우선순위 (§17 후단)

처음부터 17개를 하지 않는다.

| 순서 | 대상 | 이유 |
|:--:|---|---|
| 1 | 교육부 공통 (교육비특별회계 세출예산 집행기준) | 모든 교육청의 상위 기준 |
| 2 | 경기도교육청 | 기존 감사사례 62건의 출처 (`GOE 2021`) |
| 3 | 서울특별시교육청 | 기존 감사사례 24건의 출처 (`SEN 2024/2025`) |
| 4 | 나머지 15개 | 2·3 에서 parser 패턴이 안정된 뒤 |

2·3을 먼저 하는 이유: **이미 그 기관 자료를 근거로 쓰는 콘텐츠가 있어서** 영향 그래프가 즉시 의미를 갖는다.

## 4. 기술적 난점

교육청 지침은 대부분 **UNSTRUCTURED** 다.

| 구분 | 법제처 | 교육청 |
|---|---|---|
| 접근 | 공식 API | 게시판 HTML + 첨부 PDF/HWP |
| 버전 식별 | 법령일련번호 | 없음 (게시글 제목·날짜로 추정) |
| 시행일 | 명시 필드 | 본문에 산문으로 |
| 변경 감지 | 메타데이터 비교 | 첨부파일 해시 |

→ `source_type = UNSTRUCTURED_PDF`, `fetch_strategy = http_pdf` 로 별도 fetcher 가 필요하다(§18).
→ **시행일을 자동 추출할 수 없으면 `effective_at = nil` 로 두고 `"시행일 미상"` 으로 표시한다.** 추정하지 않는다.

## 5. 지역 선택 UI (§37)

P1 이 이미 기반을 갖고 있다.
```
audit_cases/topics/guides.target_agency = [EDUCATION_OFFICE, PUBLIC_SCHOOL, …]
                             .jurisdiction = EDUCATION
                             .agency_scope_confidence = HIGH
```
여기에 `region` 차원을 더하면 "내 지역 기준 보기"가 가능해진다.

**이번 단계에서 17개 교육청 콘텐츠를 만들지 않는다.** 근거 계층이 먼저다.

## 6. 착수 조건

교육청 확장은 다음이 끝난 뒤 시작한다.
1. 법제처 structured 소스가 운영에서 1주기 이상 안정 동작
2. UNSTRUCTURED fetcher 설계 (해시 기반 변경 감지 + 시행일 미상 허용)
3. 교육부 공통 기준 1건으로 canary
