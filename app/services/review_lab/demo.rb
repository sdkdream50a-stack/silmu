# frozen_string_literal: true

module ReviewLab
  # 연수 시연용 **완전 가상** 문서와 기대 결과(요구서 §11).
  #
  # 실제 학교·업체·사람을 쓰지 않는다. 기관명은 «가상초등학교», 업체는 «(가상)»,
  # 사업자등록번호는 실재할 수 없는 000-00-00000, 전화는 02-000-0000 이다.
  #
  # EXPECTED 는 «심어 둔 오류» 의 정답표다. 검사기가 이것과 **정확히** 같아야 한다 —
  # 빠진 것(못 잡음)도, 더 나온 것(거짓 경보)도 테스트 실패다.
  module Demo
    module_function

    QUOTE_TODAY = Date.new(2026, 9, 28)   # 연수 첫날 — 테스트가 날짜에 흔들리지 않도록 고정
    PACKAGE_TODAY = Date.new(2026, 9, 28)

    QUOTE_OPTIONS = { contract_type: "goods", agency_scope: "PUBLIC_SCHOOL", counterparty_type: "GENERAL" }.freeze
    PACKAGE_OPTIONS = { contract_type: "goods", agency_scope: "PUBLIC_SCHOOL" }.freeze

    # [code, severity, 무엇을 심었나]
    QUOTE_EXPECTED = [
      [ "Q-ROW", "BLOCK", "학생용 책상: 30 × 82,000 = 2,460,000 인데 2,640,000 으로 적음" ],
      [ "Q-SUPPLY", "PASS", "공급가액은 적힌 품목 금액의 합과 일치(행 오류는 Q-ROW 가 잡음)" ],
      [ "Q-VAT", "WARN", "부가세 794,000 — 공급가액 10%는 749,000" ],
      [ "Q-TOTAL", "PASS", "합계 = 적힌 공급가액 + 적힌 부가세" ],
      [ "Q-SPEC", "WARN", "학생용 의자 규격 누락" ],
      [ "Q-UNIT", "WARN", "전자칠판 단위 누락" ],
      [ "Q-DELIVERY", "WARN", "납품기한 누락" ],
      [ "Q-VALID", "PASS", "견적일 2026-09-10 + 90일 = 12-09 까지 유효" ],
      [ "Q-PRICE-EVIDENCE", "CHECK", "비교견적 1부 — 같은 규격은 책상·전자칠판 2품목뿐(PARTIAL)" ]
    ].freeze

    PACKAGE_EXPECTED = [
      [ "X-CONFLICT", "BLOCK", "추정가격: 공고문 45,000,000 ↔ 과업지시서 40,000,000" ],
      [ "X-CONFLICT", "BLOCK", "수량: 공고문·과업지시서 12대 ↔ 규격서 10대" ],
      [ "X-CONFLICT", "BLOCK", "납품기한: 공고문·규격서 30일 ↔ 과업지시서 45일" ],
      [ "X-CONSISTENT", "PASS", "사업명 등 일치 항목" ],
      [ "P-35", "WARN", "공고 10-05 → 마감 10-10 (5일) < 7일" ],
      [ "P-ORDER", "PASS", "공고 → 제출 개시 → 마감 → 개찰 순서 정상" ],
      [ "P-PRICE", "PASS", "기초금액 49,500,000 = 추정가격 45,000,000 × 1.1" ],
      [ "L-LICENSE", "CHECK", "과업에 «전원 콘센트 증설 및 배선 공사» — 참가자격에 전기공사업 없음" ],
      [ "L-SPLIT", "CHECK", "전기공사 분리발주 원칙 확인" ]
    ].freeze

    def quote_documents
      [
        TextExtractor.call(bytes: FixtureBuilder.xlsx(quote_rows), role: "quote", label: "견적서(가상 가나교육기자재)"),
        TextExtractor.call(bytes: FixtureBuilder.pdf(comparison_rows, columns: [ 0, 30, 110, 230, 270, 310, 380 ]),
                           role: "comparison_quote", label: "비교견적서(가상 다라교구)")
      ]
    end

    def package_documents
      [
        TextExtractor.call(bytes: FixtureBuilder.hwpx(notice_blocks), role: "notice", label: "입찰공고문"),
        TextExtractor.call(bytes: FixtureBuilder.docx(task_order_blocks), role: "task_order", label: "과업지시서"),
        TextExtractor.call(bytes: FixtureBuilder.pdf(spec_lines), role: "spec", label: "규격서")
      ]
    end

    def run_quote = QuoteReviewer.call(documents: quote_documents, today: QUOTE_TODAY, **QUOTE_OPTIONS)
    def run_package = PackageReviewer.call(documents: package_documents, today: PACKAGE_TODAY, **PACKAGE_OPTIONS)

    # 기대표 대조: 규칙 finding 의 (code, severity) 다중집합 비교. AI finding 은 대조에서 뺀다(선택 기능).
    def compare(review, expected)
      actual = review.rule_findings.map { |f| [ f.code, f.severity ] }
      want = expected.map { |c, s, _| [ c, s ] }
      missing = multiset_minus(want, actual)
      extra = multiset_minus(actual, want)
      { expected: expected, missing: missing, extra: extra, matched: want.size - missing.size, ok: missing.empty? && extra.empty? }
    end

    def multiset_minus(a, b)
      rest = b.dup
      a.reject { |x| (i = rest.index(x)) && rest.delete_at(i) }
    end

    # ── 가상 문서 내용 ───────────────────────────────────────────────
    def quote_rows
      [
        [ "견 적 서" ],
        [ "견적일자", "2026-09-10" ],
        [ "유효기간", "견적일로부터 90일" ],
        [ "상호", "(가상) 가나교육기자재" ],
        [ "사업자등록번호", "000-00-00000" ],
        [ "대표자", "가상대표" ],
        [ "납품조건", "설치 포함, 가상초등학교 납품" ],
        [],
        [ "순번", "품명", "규격", "단위", "수량", "단가", "금액", "비고" ],
        [ 1, "학생용 의자", "", "개", 30, 45_000, 1_350_000 ],
        [ 2, "학생용 책상", "1200×600×760mm", "개", 30, 82_000, 2_640_000 ],
        [ 3, "전자칠판", "75인치 4K 터치", "", 1, 3_200_000, 3_200_000 ],
        [ 4, "설치비", "전자칠판 벽걸이 설치", "식", 1, 300_000, 300_000 ],
        [ "공급가액", "", "", "", "", "", 7_490_000 ],
        [ "부가세", "", "", "", "", "", 794_000 ],
        [ "합계", "", "", "", "", "", 8_284_000 ]
      ]
    end

    def comparison_rows
      [
        "견 적 서 (가상 다라교구)",
        "견적일자: 2026-09-12",
        [ "순번", "품명", "규격", "단위", "수량", "단가", "금액" ],
        [ "1", "학생용 책상", "1200×600×760mm", "개", "30", "79,000", "2,370,000" ],
        [ "2", "전자칠판", "75인치 4K 터치", "대", "1", "3,350,000", "3,350,000" ],
        [ "3", "학생용 의자", "표준형", "개", "30", "43,000", "1,290,000" ],
        [ "4", "설치비", "현장 여건 별도", "식", "1", "250,000", "250,000" ],
        "공급가액: 7,260,000원"
      ]
    end

    def notice_blocks
      [
        "가상초등학교 공고 제2026-0917호",
        "(가상) 교실 전자칠판 구매·설치 제한경쟁입찰 공고",
        [ "공고번호", "가상초 제2026-0917호" ],
        [ "사업명", "가상초등학교 교실 전자칠판 구매·설치" ],
        [ "추정가격", "45,000,000원 (부가가치세 별도)" ],
        [ "기초금액", "49,500,000원 (부가가치세 포함)" ],
        [ "수량", "12대 (전자칠판 75인치)" ],
        [ "납품기한", "계약일로부터 30일" ],
        [ "공고일", "2026. 10. 5." ],
        [ "입찰서 제출기간", "2026. 10. 6. 10:00 ~ 2026. 10. 10. 18:00" ],
        [ "개찰일시", "2026. 10. 12. 11:00" ],
        [ "입찰참가자격", "「중소기업제품 구매촉진 및 판로지원에 관한 법률」에 따른 직접생산확인증명서(전자칠판) 소지 업체" ],
        [ "지역제한", "가상시 소재 업체" ],
        [ "계약방법", "제한경쟁입찰(총액)" ],
        [ "낙찰자 결정방법", "적격심사" ],
        [ "공동수급", "불허" ],
        [ "입찰보증금", "입찰금액의 5%(지급각서로 갈음)" ],
        [ "제출서류", "입찰참가신청서, 직접생산확인증명서 사본" ],
        [ "문의처", "가상초등학교 행정실 계약담당 (02-000-0000)" ]
      ]
    end

    def task_order_blocks
      [
        "과업지시서",
        "1. 사업명: 가상초등학교 교실 전자칠판 구매·설치",
        "2. 추정가격: 40,000,000원(부가가치세 별도)",
        "3. 수량: 12대",
        "4. 납품기한: 계약일로부터 45일",
        "5. 과업 내용",
        "가. 교실 12실에 75인치 전자칠판 설치",
        "나. 교실 내 전자칠판 전용 전원 콘센트 증설 및 배선 공사",
        "다. 기존 칠판 철거 및 폐기물 처리",
        "6. 검수: 설치 완료 후 학교 검수 및 사용자 교육 1회"
      ]
    end

    def spec_lines
      [
        "물품 규격서",
        "사업명: 가상초등학교 교실 전자칠판 구매·설치",
        "수량: 10대",
        "납품기한: 계약일로부터 30일",
        "화면 크기: 75인치 이상",
        "해상도: 4K UHD (3840×2160)",
        "터치: 20점 이상 멀티터치",
        "전원: AC 220V, 60Hz"
      ]
    end
  end
end
