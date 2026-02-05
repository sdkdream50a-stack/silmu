# 법규정 자동 검증 시스템

토픽 콘텐츠가 현행 법규정과 일치하는지 자동으로 검증하고 수정하는 시스템입니다.

## 기능

- **자동 검증**: Anthropic Claude API를 사용하여 콘텐츠의 금액, 기간, 비율 등이 최신 규정과 일치하는지 확인
- **자동 수정**: 오류 발견 시 자동으로 수정
- **자동 커밋**: 수정사항을 Git에 자동 커밋 및 푸시
- **리포트 생성**: 검증 결과를 JSON 파일로 저장

## 설정

### 1. 환경변수 설정

```bash
# .env 또는 시스템 환경변수
export ANTHROPIC_API_KEY='your-anthropic-api-key'
```

### 2. GitHub Secrets 설정 (자동 실행용)

GitHub 저장소 설정 > Secrets and variables > Actions에서 추가:

| Secret 이름 | 설명 |
|------------|------|
| `ANTHROPIC_API_KEY` | Anthropic API 키 |
| `SLACK_WEBHOOK_URL` | (선택) 슬랙 알림용 Webhook URL |

## 사용 방법

### 수동 실행

```bash
# 전체 토픽 검증
rails verify:regulations

# 특정 토픽만 검증
rails verify:topic[travel-expense]
rails verify:topic[year-end-settlement]

# 검증 리포트 조회
rails verify:reports
```

### GitHub Actions (수동 트리거)

- **스케줄 자동 실행**: 비활성화 (비용 절감)
- **수동 트리거**: GitHub Actions 탭 → "Run workflow" 버튼 클릭
- **설정 파일**: `.github/workflows/verify_regulations.yml`

> 💡 자동 실행을 원하면 workflow 파일에서 `schedule` 주석을 해제하세요.

## 검증 대상

| 토픽 | 검증 키워드 |
|------|------------|
| 여비 | 공무원 여비 규정, 일비, 숙박비, 식비 |
| 연말정산 | 소득세법, 세액공제, 소득공제 |
| 예산이월 | 지방재정법, 사고이월, 명시이월 |
| 수의계약 | 지방계약법, 추정가격, 수의계약 한도 |
| 1인견적 | 수의계약, 견적 |
| 2인견적 | 나라장터, 지정정보처리장치 |

## 검증 항목

- **금액**: 원, 만원, 억원 단위 금액
- **비율**: 퍼센트(%) 값
- **기간**: ~일 이내, ~주일 이내
- **날짜**: 법 개정일, 시행일 등

## 리포트

검증 결과는 `log/regulation_reports/` 디렉토리에 JSON 파일로 저장됩니다.

```json
{
  "timestamp": "2026-02-05T14:30:00+09:00",
  "changes": [
    {
      "topic": "travel-expense",
      "field": "rule_content",
      "wrong_value": "80,000원",
      "correct_value": "100,000원",
      "reason": "2023년 개정 반영",
      "source": "공무원 여비 규정 별표"
    }
  ],
  "errors": [],
  "summary": {
    "total_changes": 1,
    "total_errors": 0
  }
}
```

## 주의사항

1. **API 비용**: Anthropic API 사용료가 발생합니다.
2. **검증 정확도**: AI 기반 검증이므로 100% 정확하지 않을 수 있습니다.
3. **수동 확인 권장**: 중요한 변경사항은 수동으로 확인하는 것이 좋습니다.

## 문제 해결

### API 키 오류

```
⚠️ ANTHROPIC_API_KEY 환경변수가 설정되지 않았습니다.
```

→ 환경변수에 API 키를 설정하세요.

### 검증 실패

로그 파일 확인:
```bash
cat log/regulation_reports/report_*.json | jq '.errors'
```
