# frozen_string_literal: true

require "test_helper"

# 견적서 검증기 V1 — 산술은 코드가, 결론의 강도는 값의 출처가 정한다.
class ReviewLab::QuoteReviewerTest < ActiveSupport::TestCase
  B = ReviewLab::FixtureBuilder
  TODAY = Date.new(2026, 9, 28)

  HEAD = [ "순번", "품명", "규격", "단위", "수량", "단가", "금액" ].freeze

  def quote(rows:, supply:, vat:, total:, extra: [])
    [
      [ "견적일자", "2026-09-10" ], [ "유효기간", "견적일로부터 30일" ], [ "상호", "(가상) 업체" ],
      [ "사업자등록번호", "000-00-00000" ], [ "납품기한", "계약일로부터 20일" ], [ "납품조건", "설치 포함" ],
      *extra, HEAD, *rows,
      [ "공급가액", "", "", "", "", "", supply ], [ "부가세", "", "", "", "", "", vat ], [ "합계", "", "", "", "", "", total ]
    ]
  end

  def review(rows_bytes, **opts)
    docs = Array(rows_bytes).each_with_index.map do |b, i|
      ReviewLab::TextExtractor.call(bytes: b, role: i.zero? ? "quote" : "comparison_quote", label: i.zero? ? "견적서" : "비교견적 #{i}")
    end
    ReviewLab::QuoteReviewer.call(documents: docs, today: TODAY, **opts)
  end

  def codes(r, severity = nil) = r.findings.select { |f| severity.nil? || f.severity == severity }.map(&:code)

  CLEAN_ROWS = [ [ 1, "의자", "표준형", "개", 10, 1_000, 10_000 ], [ 2, "책상", "1200mm", "개", 5, 2_000, 10_000 ] ].freeze

  test "양성 대조 — 오류 없는 견적서는 산술 PASS 만 나오고 BLOCK/WARN 이 없다" do
    r = review(B.xlsx(quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000)))
    assert_empty codes(r, "BLOCK")
    assert_empty codes(r, "WARN")
    %w[Q-ROW Q-SUPPLY Q-VAT Q-TOTAL Q-VALID].each { |c| assert_includes codes(r, "PASS"), c }
    refute r.inconclusive?
  end

  test "수량×단가 오류는 BLOCK — 계산값과 차이를 함께 준다" do
    rows = [ [ 1, "의자", "표준형", "개", 10, 1_000, 11_000 ] ]
    r = review(B.xlsx(quote(rows: rows, supply: 11_000, vat: 1_100, total: 12_100)))
    f = r.findings.find { |x| x.code == "Q-ROW" }
    assert_equal "BLOCK", f.severity
    assert_match(/10,000원/, f.problem)
    assert_match(/1,000원/, f.problem)
  end

  test "부가세 불일치는 WARN(과세·면세 혼합 가능) · 0원은 CHECK · 절사 10원 이내는 PASS" do
    assert_equal "WARN", review(B.xlsx(quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_500, total: 22_500))).findings.find { |f| f.code == "Q-VAT" }.severity
    assert_equal "CHECK", review(B.xlsx(quote(rows: CLEAN_ROWS, supply: 20_000, vat: 0, total: 20_000))).findings.find { |f| f.code == "Q-VAT" }.severity
    rows = [ [ 1, "의자", "표준형", "개", 1, 12_345, 12_345 ] ]
    assert_equal "PASS", review(B.xlsx(quote(rows: rows, supply: 12_345, vat: 1_234, total: 13_579))).findings.find { |f| f.code == "Q-VAT" }.severity
  end

  test "합계 ≠ 공급가액+부가세 는 BLOCK · 공급가액 ≠ 품목합 은 BLOCK(공사는 간접비 때문에 CHECK)" do
    r = review(B.xlsx(quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 23_000)))
    assert_equal "BLOCK", r.findings.find { |f| f.code == "Q-TOTAL" }.severity
    r = review(B.xlsx(quote(rows: CLEAN_ROWS, supply: 25_000, vat: 2_500, total: 27_500)))
    assert_equal "BLOCK", r.findings.find { |f| f.code == "Q-SUPPLY" }.severity
    r = review(B.xlsx(quote(rows: CLEAN_ROWS, supply: 25_000, vat: 2_500, total: 27_500)), contract_type: "construction_etc")
    assert_equal "CHECK", r.findings.find { |f| f.code == "Q-SUPPLY" }.severity
  end

  test "중복 품목·규격 누락·단위 누락" do
    rows = [ [ 1, "의자", "", "개", 1, 1_000, 1_000 ], [ 2, "의자", "", "", 1, 1_000, 1_000 ] ]
    r = review(B.xlsx(quote(rows: rows, supply: 2_000, vat: 200, total: 2_200)))
    assert_includes codes(r, "WARN"), "Q-DUP"
    assert_equal 2, codes(r, "WARN").count("Q-SPEC")
    assert_equal 1, codes(r, "WARN").count("Q-UNIT")
  end

  test "필수 정보 누락은 WARN, 유효기간 경과는 WARN" do
    rows = [ HEAD, *CLEAN_ROWS, [ "공급가액", "", "", "", "", "", 20_000 ] ]
    r = review(B.xlsx(rows))
    %w[Q-VENDOR Q-DATE Q-VALID Q-DELIVERY].each { |c| assert_includes codes(r, "WARN"), c }
    expired = quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000).map { |row| row.first == "견적일자" ? [ "견적일자", "2026-01-02" ] : row }
    assert(review(B.xlsx(expired)).findings.any? { |f| f.code == "Q-VALID" && f.severity == "WARN" && f.problem.include?("지났") })
  end

  test "UNKNOWN 보존 — 품목표를 못 읽으면 PASS 가 아니라 «읽지 못함» 과 건너뛴 규칙이 남는다" do
    r = review(B.docx([ "견적서", "금액은 별도 협의" ]))
    assert_includes codes(r, "CHECK"), "Q-ITEMS-READ"
    assert(r.skipped_rules.any? { |s| s[:code] == "Q-ROW" })
    refute_includes codes(r, "PASS"), "Q-ROW"
  end

  test "읽을 수 없는 파일은 검사 불가(inconclusive) — 아무것도 못 잡았다고 통과가 아니다" do
    r = review("\xD0\xCF\x11\xE0".b + ("\x00".b * 100))
    assert r.inconclusive?
    assert_empty r.findings
    assert_match(/문제 없음/, r.headline)
  end

  test "AI 가 읽은 값은 산술이 틀려도 BLOCK 이 아니라 CHECK — FACT 로 승격하지 않는다" do
    image = ReviewLab::TextExtractor.call(bytes: "\x89PNG\r\n\x1A\n".b, role: "quote", label: "견적서")
    ai = { "company_name" => "업체", "supply_amount" => 20_000, "vat_amount" => 2_000, "total_amount" => 99_999,
           "items" => [ { "name" => "의자", "spec" => "표준", "unit" => "개", "qty" => 10, "unit_price" => 1_000 } ] }
    r = ReviewLab::QuoteReviewer.call(documents: [ image ], ai_fields: ai, today: TODAY)
    total = r.findings.find { |f| f.code == "Q-TOTAL" }
    assert_equal "CHECK", total.severity
    assert_match(/AI가 읽은 값 기준/, total.problem)
    assert(r.findings.none? { |f| %w[BLOCK WARN PASS].include?(f.severity) }, "AI 판독값에서 나온 결론은 전부 CHECK 여야 한다")
    assert(r.skipped_rules.any? { |s| s[:code] == "Q-ROW" }, "AI 는 행 금액을 주지 않으므로 행 산술은 건너뛴다(곱을 지어내지 않는다)")
  end

  test "계약방식 판정은 기존 판정기를 그대로 호출한다 — 같은 입력이면 같은 결론" do
    r = review(B.xlsx(quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000)),
               contract_type: "goods", agency_scope: "PUBLIC_SCHOOL", counterparty_type: "GENERAL")
    direct = ContractMethodService.determine(contract_type: "goods", estimated_price: 20_000, agency_scope: "PUBLIC_SCHOOL", counterparty_type: "GENERAL")
    assert_equal direct[:decision][:state], r.extras[:contract][:result][:decision][:state]
    assert_equal 20_000, r.extras[:contract][:assumed_estimated_price]
  end

  test "계약 유형을 고르지 않으면 판정을 지어내지 않고 건너뛴다" do
    r = review(B.xlsx(quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000)))
    assert_nil r.extras[:contract]
    assert(r.skipped_rules.any? { |s| s[:code] == "CONTRACT-LINK" })
  end

  test "가격 근거 — 비교견적 없음/같은 규격 전부/일부/규격 불일치" do
    main = B.xlsx(quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000))
    level = ->(*others) { review([ main, *others ]).extras[:price_evidence][:level] }
    same = B.xlsx([ HEAD, [ 1, "의자", "표준형", "개", 10, 900, 9_000 ], [ 2, "책상", "1200 mm", "개", 5, 2_100, 10_500 ] ])
    half = B.xlsx([ HEAD, [ 1, "의자", "표준형", "개", 10, 900, 9_000 ], [ 2, "책상", "1400mm", "개", 5, 2_100, 10_500 ] ])
    none = B.xlsx([ HEAD, [ 1, "의자", "고급형", "개", 10, 900, 9_000 ] ])
    assert_equal "PRICE_EVIDENCE_INSUFFICIENT", level.call
    assert_equal "PRICE_EVIDENCE_STRONG", level.call(same)
    assert_equal "PRICE_EVIDENCE_PARTIAL", level.call(half)
    assert_equal "NOT_COMPARABLE", level.call(none)
  end

  test "가격 적정성 판정 문구를 내지 않는다" do
    main = B.xlsx(quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000))
    r = review(main)
    text = r.findings.map { |f| [ f.problem, f.why_it_matters, f.suggested_action ].join(" ") }.join(" ")
    refute_match(/비쌉니다|저렴합니다|적정합니다|고가|과다/, text)
  end

  test "개인정보 패턴은 위치만 알리고 값은 되풀이하지 않는다" do
    rows = quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000, extra: [ [ "담당자 연락처", "010-1234-5678" ] ])
    f = review(B.xlsx(rows)).findings.find { |x| x.code == "PII" }
    assert_equal "CHECK", f.severity
    refute_includes f.to_h.values.join(" "), "1234-5678"
  end

  # ── 독립 리뷰(정확성) 회귀 ──────────────────────────────────────────
  test "R#4 유효기간이 날짜(«2026년 8월 31일까지»)면 그 날짜로 만료를 판정한다" do
    rows = quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000).map do |row|
      case row.first
      when "견적일자" then [ "견적일자", "2026-08-20" ]
      when "유효기간" then [ "유효기간", "2026년 8월 31일까지" ]
      else row
      end
    end
    f = review(B.xlsx(rows)).findings.find { |x| x.code == "Q-VALID" }
    assert_equal "WARN", f.severity
  end

  test "R#7 «2천만원»·«1.5억원» 을 틀리게 읽지 않는다" do
    assert_equal 20_000_000, ReviewLab::FieldExtractor.parse_amount("2천만원")
    assert_equal 120_000_000, ReviewLab::FieldExtractor.parse_amount("1억2천만원")
    assert_equal 150_000_000, ReviewLab::FieldExtractor.parse_amount("1.5억원")
    assert_nil ReviewLab::FieldExtractor.parse_amount("1.5")
  end

  test "R#8 품목표 «합계»(소계)가 공급가액과 같으면 확정 오류가 아니라 CHECK" do
    rows = [ [ "견적일자", "2026-09-10" ], HEAD, *CLEAN_ROWS, [ "합계", "", "", "", "", "", 20_000 ],
             [ "공급가액", 20_000 ], [ "부가세", 2_000 ] ]
    f = review(B.xlsx(rows)).findings.find { |x| x.code == "Q-TOTAL" }
    assert_equal "CHECK", f.severity
  end

  test "R#8 «합계금액» 라벨이 품목표 «합계» 보다 우선한다" do
    rows = [ [ "합계금액", 22_000 ], HEAD, *CLEAN_ROWS, [ "합계", "", "", "", "", "", 20_000 ], [ "공급가액", 20_000 ], [ "부가세", 2_000 ] ]
    assert_equal "PASS", review(B.xlsx(rows)).findings.find { |x| x.code == "Q-TOTAL" }.severity
  end

  test "R#9 «계» 로 시작하는 품명(계량컵)에서 품목표 읽기가 멈추지 않는다" do
    rows = [ [ "품명", "규격", "단위", "수량", "단가", "금액" ], [ "전자저울", "1kg", "개", 1, 100_000, 100_000 ],
             [ "계량컵", "500ml", "개", 1, 150_000, 150_000 ], [ "공급가액", "", "", "", "", 250_000 ] ]
    r = review(B.xlsx(rows))
    assert_equal "PASS", r.findings.find { |x| x.code == "Q-SUPPLY" }.severity
  end

  test "R#13 XLSX 날짜 셀(일련번호)을 견적일로 읽는다" do
    rows = quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000).map { |row| row.first == "견적일자" ? [ "견적일자", 46_275 ] : row }
    r = review(B.xlsx(rows))
    refute(r.findings.any? { |f| f.code == "Q-DATE" && f.severity == "WARN" })
  end

  test "R#15 주 견적서 품목표를 못 읽으면 가격 근거를 «규격이 달라» 로 오표기하지 않는다" do
    r = review([ B.docx([ "견적서" ]), B.xlsx([ HEAD, [ 1, "의자", "표준형", "개", 1, 1_000, 1_000 ] ]) ])
    assert_nil r.extras[:price_evidence]
    assert(r.skipped_rules.any? { |s| s[:code] == "Q-PRICE-EVIDENCE" })
  end

  test "R#17 기산일이 견적일이 아니면 만료일을 지어내지 않는다" do
    rows = quote(rows: CLEAN_ROWS, supply: 20_000, vat: 2_000, total: 22_000).map { |row| row.first == "유효기간" ? [ "유효기간", "발주일로부터 30일" ] : row }
    assert_equal "CHECK", review(B.xlsx(rows)).findings.find { |x| x.code == "Q-VALID" }.severity
  end
end
