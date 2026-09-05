# LEGACY_JOB_RISK — 구 LegalComplianceJob 위험 기록

> §49 — **삭제하지 않는다.** `LEGACY_UNSAFE` 로 취급하고 명확히 문서화한다.
> 새 시스템이 충분히 안정화된 후 제거/대체를 판단한다.

---

## 1. 현재 상태

| 항목 | 값 |
|---|---|
| 파일 | `app/jobs/legal_compliance_job.rb` (171줄) — **존치** |
| 스케줄 | `config/recurring.yml` 에서 주석 처리 — **이번 세션 무변경** |
| 중단일 | 2026-04-13 (주석에 명시) |
| 판정 | **DO_NOT_ENABLE** |

## 2. 왜 켜면 안 되는가 — 호출 경로

```
LegalComplianceJob#run_basic_check
  └─ Open3.capture3("bundle exec rake legal:ci_check")   ← job 안에서 Rails 재부팅
       │
       ├─ 중대 오류 발견        ─┐
       └─ JSON 파싱 실패        ─┴─► run_ai_verification
                                      └─ RegulationVerifier#verify_all
                                           └─ Topic.published.find_each
                                                └─ verify_field  (필드마다 Anthropic API 호출)
                                                     └─ apply_corrections
                                                          └─ topic.update!(field => AI가_만든_문자열)
```

`app/services/regulation_verifier.rb:382`
```ruby
if updated_content != content
  topic.update!(field => updated_content)   # ← 발행 중인 법령 해설 본문을 AI 출력으로 덮어쓴다
  log "  💾 #{field} 저장 완료"
end
```

**dry-run 플래그·사람 승인 게이트·diff 검토·롤백 기록이 하나도 없다.**
`grep -nE 'dry|DRY|guard|approve|confirm'` 결과는 `ENV["ANTHROPIC_API_KEY"]` 단 1건.

## 3. §22 6조건 판정

| 조건 | 판정 | 근거 |
|---|:--:|---|
| idempotent | ⚠️ | 리포트는 반복 가능하나 실행마다 메일 발송 |
| **non-destructive** | ❌ | 위 2번 — 게시 콘텐츠 직접 수정 |
| reasonable external load | ❌ | 발행 토픽 전체 × 필드마다 API 호출 + job 내 Rails 재부팅 |
| **failure-safe** | ❌ | JSON 파싱 실패가 **더 큰 AI 검증으로 에스컬레이션**. rake 출력 형식이 바뀌면 매 실행마다 유료 호출 + 자동 수정 |
| observable | ⚠️ | 로그·메일뿐. `ADMIN_EMAIL` 미설정이면 흔적 없음 |
| tested | ❌ | 관련 테스트 0건 |

## 4. 새 엔진과의 비교

| | 구 LegalComplianceJob | AuthorityFreshnessCheckJob |
|---|---|---|
| 콘텐츠 본문 수정 | **가능** | **불가** (화이트리스트 3컬럼) |
| 실패 시 동작 | AI 검증으로 확대 | 실패 기록 후 종료 |
| 외부 호출 상한 | 없음 | `MAX_DOCUMENTS_PER_RUN=20` · 요청 간격 1s |
| 연속 실패 처리 | 없음 | 5회 초과 시 소스 건너뜀 |
| 버전 이력 | 없음 | immutable snapshot |
| 사람 승인 | 없음 | `AuthorityReviewTask#decide!` 필수 |
| 테스트 | 0 | 51 |
| AI 사용 | 콘텐츠 자동 수정 | **사용 안 함** |

## 5. 활성화 조건 (그때가 오면)

구 잡을 되살리려면 순서대로:

1. `RegulationVerifier` 에 `dry_run:` 옵션 — 기본값 `true`. `apply_corrections` 는 `dry_run == false` 일 때만 `update!`
2. 제안 수정을 검토 큐(`AuthorityReviewTask` 재사용 가능)에 적재, **사람 승인 후** 적용
3. JSON 파싱 실패 시 AI 로 에스컬레이션하지 않고 실패로 종료
4. `Open3` 로 rake 재부팅하지 않고 lint 로직 직접 호출
5. 실행당 API 호출·비용 상한
6. 실행 결과 원장 기록
7. 테스트 추가
8. 그 다음에야 `recurring.yml` 주석 해제

**1·3번만 해도 위험의 대부분이 사라진다.**

## 6. 대체 판단

새 엔진이 구 잡의 "법령 정합성 검증" 목적을 **부분적으로** 대체한다.

| 구 잡 기능 | 새 엔진 | 비고 |
|---|---|---|
| 법령 개정 감지 | ✅ 대체 | 더 정확 (버전·시행일 구분) |
| 영향 콘텐츠 탐색 | ✅ 대체 | Impact Graph |
| 조문 번호·폐지 조문 lint | ❌ 미대체 | `silmu:legal_lint` rake 가 별도로 존재 |
| 콘텐츠 수치 대조 | ❌ 미대체 | 구 잡의 AI 검증 영역 |
| 자동 수정 | ❌ **의도적 미대체** | 하면 안 되는 기능 |

따라서 **지금 삭제하지 않는다.** 조문 lint·수치 대조를 안전한 형태로 옮긴 뒤 판단한다.
