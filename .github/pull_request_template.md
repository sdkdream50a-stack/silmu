# PR 요약

(변경 내용 1~2줄 요약)

## silmu 5단계 법령 검증 게이트

법령·조문·금액·요율 변경이 있는 경우 모두 체크 후 머지:

- [ ] 1. **조문번호** — 법제처 mcp 또는 PDF 원문 확인 완료
- [ ] 2. **수치** — 표준값표(지체상금 10% / 낙찰하한율 89.745% / G2B §30 / 분할계약 §77) 대조 완료
- [ ] 3. **위계** — law(법률) / decree(시행령) / rule(시행규칙) / 예규 정확 배치
- [ ] 4. **한시 특례** — 만료일 명시 + retroactive 부채 등록
- [ ] 5. **양법** — 국가/지방 차이 명시 또는 단일법 한정 표기 (silmu는 지방계약법 우선)

**법령 변경 없음** 시 위 체크박스 무시 가능.

## 운영 mcp 프록시 검증 (권장)

```bash
kamal app exec -i 'sh -c "
xml=\$(curl -s \"http://www.law.go.kr/DRF/lawService.do?OC=sdkdream50a&target=law&MST=<MST>&type=XML\")
echo \"\$xml\" | grep -oE \"제[0-9]+조[(][^)]{0,40}[)]\" | sort -u
"'
```

자주 사용하는 MST: 지방계약법 시행령 281055 / 국가계약법 시행령 280803 / 공무원수당규정 282475 / 공무원연금법 277137

## 참조

- 5단계 게이트 사양: `memory/project_legal_validation_gate.md`
- 도구 권위자 검증 누적: `memory/project_tools_authority_audit.md` (13건 부정확 정정 완료)
- 폐지 조문 블랙리스트: 지방계약법 시행령 §42의2 (2022년 삭제)
