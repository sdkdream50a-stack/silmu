# frozen_string_literal: true

require "test_helper"

# P4 §17 — 예산문서 검증기.
#
# 이 파일의 규율: **기대값을 피검 대상에서 읽지 않는다.** 금액은 테스트가 직접 적고,
# «검사가 실제로 돌았는가»(rules_run)와 «안 돌았을 때 그 사실을 말하는가»(skipped)를 함께 본다.
# 각 규칙마다 양성(결함 주입 → 잡는다)과 음성(정상 → 안 잡는다) 대조를 쌍으로 둔다.
class ReviewLab::BudgetReviewerTest < ActiveSupport::TestCase
  B = ReviewLab::FixtureBuilder
  D = ReviewLab::Demo

  def doc(bytes, role, label) = ReviewLab::TextExtractor.call(bytes: bytes, role: role, label: label)
  def plan(blocks) = doc(B.hwpx(blocks), "project_plan", "사업계획서")
  def basis(rows) = doc(B.xlsx(rows), "cost_basis", "산출기초")
  def review(*docs) = ReviewLab::BudgetReviewer.call(documents: docs)

  def find(r, code) = r.findings.select { |f| f.code == code }
  def sev(r, code) = find(r, code).map(&:severity)
  def skipped?(r, code) = r.skipped_rules.any? { |s| s[:code] == code }

  HEADER = [ "순번", "품명", "규격", "단위", "수량", "단가", "금액" ].freeze

  def basis_rows(rows, supply:, vat: nil, total: nil, name: "테스트 사업")
    out = [ [ "사업명", name ], [], HEADER ] + rows
    out << [ "공급가액", "", "", "", "", "", supply ] if supply
    out << [ "부가세", "", "", "", "", "", vat ] if vat
    out << [ "합계", "", "", "", "", "", total ] if total
    out
  end

  # ── B-ROW 수량 × 단가 = 금액 ─────────────────────────────────────
  test "B-ROW 양성 — 행 금액이 수량×단가와 다르면 BLOCK" do
    r = review(basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 9_000 ] ], supply: 9_000)))
    assert_equal [ "BLOCK" ], sev(r, "B-ROW")
    assert_includes find(r, "B-ROW").first.problem, "10,000원"
  end

  test "B-ROW 음성 — 정상 행만 있으면 PASS 이고 BLOCK 이 없다" do
    r = review(basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000)))
    assert_equal [ "PASS" ], sev(r, "B-ROW")
  end

  test "B-ROW 를 못 돌리면 PASS 가 아니라 skipped 로 남는다" do
    r = review(plan([ [ "사업명", "표만 없는 계획서" ], [ "총사업비", "1,000,000원" ] ]))
    assert_empty find(r, "B-ROW")
    assert skipped?(r, "B-ROW")
  end

  # ── B-SUM Σ행 = 공급가액 ─────────────────────────────────────────
  test "B-SUM 양성 — 적힌 공급가액이 품목 합과 다르면 BLOCK" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ], [ 2, "의자", "표준", "개", 5, 2_000, 10_000 ] ]
    r = review(basis(basis_rows(rows, supply: 19_000)))
    assert_equal [ "BLOCK" ], sev(r, "B-SUM")
  end

  test "B-SUM 음성 — 합이 맞으면 PASS" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ], [ 2, "의자", "표준", "개", 5, 2_000, 10_000 ] ]
    assert_equal [ "PASS" ], sev(review(basis(basis_rows(rows, supply: 20_000))), "B-SUM")
  end

  # 부가세가 있는데 공급가액이 없으면 «합계» 와 품목 합을 견주면 안 된다(부가세만큼 거짓 BLOCK).
  test "B-SUM — 부가세만 있고 공급가액이 없으면 검사하지 않고 그 이유를 적는다" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ]
    r = review(basis(basis_rows(rows, supply: nil, vat: 1_000, total: 11_000)))
    assert_empty find(r, "B-SUM")
    assert_includes r.skipped_rules.find { |s| s[:code] == "B-SUM" }[:reason], "공급가액은 없어"
  end

  # ── B-VAT / B-TOTAL ─────────────────────────────────────────────
  test "B-VAT 양성/음성" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ]
    assert_equal [ "WARN" ], sev(review(basis(basis_rows(rows, supply: 10_000, vat: 900, total: 10_900))), "B-VAT")
    assert_equal [ "PASS" ], sev(review(basis(basis_rows(rows, supply: 10_000, vat: 1_000, total: 11_000))), "B-VAT")
  end

  test "B-TOTAL 양성 — 합계가 공급가액+부가세와 다르면 BLOCK" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ]
    assert_equal [ "BLOCK" ], sev(review(basis(basis_rows(rows, supply: 10_000, vat: 1_000, total: 12_000))), "B-TOTAL")
  end

  # ── R1 수리 회귀 — 문서를 섞지 않는다 / 비교 불가를 PASS 로 만들지 않는다 ──
  test "B-TOTAL — 합계 항목이 없으면 조기 종료하지 않고 이유를 남긴다" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ]
    r = review(basis(basis_rows(rows, supply: 10_000, vat: 1_000)))
    assert_empty find(r, "B-TOTAL")
    assert_includes r.skipped_rules.find { |x| x[:code] == "B-TOTAL" }[:reason], "합계 항목을 찾지 못해"
  end

  test "B-VAT/B-TOTAL 은 한 문서 안에서만 값을 모은다 — 사업계획서의 «총액» 을 끌어오지 않는다" do
    # 사업계획서에 총액(부가세 포함)이, 산출기초에 공급가액·부가세가 있다.
    # 문서를 섞으면 «공급가액 + 부가세 ≠ 계획서 총액» 으로 거짓 BLOCK 이 난다.
    p = plan([ [ "사업명", "테스트" ], [ "총액", "99,999,999원" ], [ "총사업비", "11,000원" ] ])
    b = basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000, vat: 1_000, name: "테스트"))
    r = review(p, b)
    refute(r.findings.any? { |f| f.code == "B-TOTAL" && f.severity == "BLOCK" },
           "문서를 섞어 거짓 BLOCK 이 났다: #{find(r, 'B-TOTAL').map(&:extracted_value)}")
  end

  test "B-CROSS-TOTAL — 산출기초에 부가세가 있고 합계가 없으면 비교하지 않는다(거짓 BLOCK·거짓 PASS 둘 다 막는다)" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ]
    b = basis(basis_rows(rows, supply: 10_000, vat: 1_000, name: "테스트"))
    # ① 계획서가 부가세 포함액을 적은 정상 문서 — 종전에는 공급가액과 견줘 거짓 BLOCK 이었다
    p1 = plan([ [ "사업명", "테스트" ], [ "총사업비", "11,000원" ] ])
    r1 = review(p1, b)
    assert_empty find(r1, "B-CROSS-TOTAL")
    assert_includes r1.skipped_rules.find { |x| x[:code] == "B-CROSS-TOTAL" }[:reason], "어느 값과 견줄지"
    # ② 계획서가 부가세를 빠뜨린 문서 — 종전에는 공급가액과 같아 거짓 PASS 였다
    p2 = plan([ [ "사업명", "테스트" ], [ "총사업비", "10,000원" ] ])
    refute(review(p2, b).findings.any? { |f| f.code == "B-CROSS-TOTAL" && f.severity == "PASS" })
  end

  test "B-CROSS-TOTAL — 합계가 있으면 종전대로 부가세 포함액끼리 비교한다" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ]
    b = basis(basis_rows(rows, supply: 10_000, vat: 1_000, total: 11_000, name: "테스트"))
    p = plan([ [ "사업명", "테스트" ], [ "총사업비", "11,000원" ] ])
    assert_equal [ "PASS" ], sev(review(p, b), "B-CROSS-TOTAL")
  end

  test "예산과목 라벨은 «과목» 단독을 읽지 않는다 — 교과목명을 예산과목으로 표시하지 않는다" do
    p = plan([ [ "사업명", "테스트" ], [ "총사업비", "10,000원" ], [ "과목", "방과후 논술" ] ])
    assert_empty find(review(p), "B-ACCOUNT")
    p2 = plan([ [ "사업명", "테스트" ], [ "총사업비", "10,000원" ], [ "예산과목", "학교운영비" ] ])
    assert_equal [ "CHECK" ], sev(review(p2), "B-ACCOUNT")
  end

  # ── B-CROSS-TOTAL 문서 간 금액 ───────────────────────────────────
  test "B-CROSS-TOTAL 양성 — 사업계획서 총사업비 ≠ 산출기초 합계면 BLOCK" do
    p = plan([ [ "사업명", "테스트 사업" ], [ "사업기간", "2026. 3. 2. ~ 2026. 4. 30." ], [ "총사업비", "9,000,000원" ] ])
    b = basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000, vat: 1_000, total: 11_000))
    assert_equal [ "BLOCK" ], sev(review(p, b), "B-CROSS-TOTAL")
  end

  test "B-CROSS-TOTAL 음성 — 같으면 PASS" do
    p = plan([ [ "사업명", "테스트 사업" ], [ "사업기간", "2026. 3. 2. ~ 2026. 4. 30." ], [ "총사업비", "11,000원" ] ])
    b = basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000, vat: 1_000, total: 11_000))
    assert_equal [ "PASS" ], sev(review(p, b), "B-CROSS-TOTAL")
  end

  test "B-CROSS-TOTAL — 문서가 하나뿐이면 대조하지 않고 그 사실을 적는다" do
    r = review(basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000)))
    assert_empty find(r, "B-CROSS-TOTAL")
    assert skipped?(r, "B-CROSS-TOTAL")
  end

  # ── B-ENVELOPE 예산액 ────────────────────────────────────────────
  test "B-ENVELOPE — 예산액 초과는 BLOCK 이 아니라 WARN 이다(전용·추경 절차가 있을 수 있다)" do
    p = plan([ [ "사업명", "테스트 사업" ], [ "예산현액", "5,000,000원" ], [ "총사업비", "6,000,000원" ] ])
    f = find(review(p), "B-ENVELOPE").first
    assert_equal "WARN", f.severity
    assert_includes f.why_it_matters, "판정하지 않습니다"
  end

  test "B-ENVELOPE 음성 — 예산액 안이면 PASS" do
    p = plan([ [ "사업명", "테스트 사업" ], [ "예산현액", "8,000,000원" ], [ "총사업비", "6,000,000원" ] ])
    assert_equal [ "PASS" ], sev(review(p), "B-ENVELOPE")
  end

  # ── B-NAME / B-PERIOD ───────────────────────────────────────────
  test "B-NAME 양성 — 문서마다 사업명이 다르면 WARN" do
    p = plan([ [ "사업명", "도서관 가구 교체" ], [ "총사업비", "10,000원" ] ])
    b = basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000, name: "급식실 보수"))
    assert_equal [ "WARN" ], sev(review(p, b), "B-NAME")
  end

  test "B-NAME 음성 — 괄호·공백만 다른 같은 사업명은 WARN 이 아니다" do
    p = plan([ [ "사업명", "도서관 가구 교체" ], [ "총사업비", "10,000원" ] ])
    b = basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000, name: "도서관가구교체"))
    assert_equal [ "PASS" ], sev(review(p, b), "B-NAME")
  end

  test "B-PERIOD 양성 — 종료일이 시작일보다 빠르면 BLOCK" do
    p = plan([ [ "사업명", "테스트" ], [ "사업기간", "2026. 5. 1. ~ 2026. 3. 1." ], [ "총사업비", "10,000원" ] ])
    assert_equal [ "BLOCK" ], sev(review(p), "B-PERIOD")
  end

  test "B-PERIOD — 범위 형태가 아니면 검사하지 않고 이유를 적는다" do
    p = plan([ [ "사업명", "테스트" ], [ "사업기간", "계약일로부터 30일" ], [ "총사업비", "10,000원" ] ])
    assert_empty find(p_r = review(p), "B-PERIOD")
    assert skipped?(p_r, "B-PERIOD")
  end

  # ── B-REQUIRED / B-ACCOUNT / PII ────────────────────────────────
  test "B-REQUIRED 양성 — 필수 항목이 없으면 WARN 이고 «못 읽었을 수도 있다» 를 적는다" do
    f = find(review(basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000, name: "테스트"))), "B-REQUIRED").first
    assert_equal "WARN", f.severity
    assert_includes f.why_it_matters, "구별하지 못합니다"
  end

  test "B-ACCOUNT — 과목은 CHECK 로 «표시만» 하고 어떤 경로로도 PASS/BLOCK 이 되지 않는다" do
    p = plan([ [ "사업명", "테스트" ], [ "총사업비", "10,000원" ], [ "예산과목", "학교운영비" ] ])
    r = review(p)
    assert_equal [ "CHECK" ], sev(r, "B-ACCOUNT")
    assert skipped?(r, "B-ACCOUNT")
    assert_includes r.skipped_rules.find { |s| s[:code] == "B-ACCOUNT" }[:reason], "판정하지 않습니다"
  end

  test "PII — 값은 표시하지 않고 위치만 알린다" do
    p = plan([ [ "사업명", "테스트" ], [ "총사업비", "10,000원" ], [ "담당자", "010-1234-5678" ] ])
    f = find(review(p), "PII").first
    assert_equal "CHECK", f.severity
    refute_includes f.to_h.values.map(&:to_s).join(" "), "1234-5678"
  end

  # ── R2 수리 회귀 ──────────────────────────────────────────────────
  test "구역 소계가 여러 개인 산출기초에서 품목이 잘리지 않는다" do
    rows = [ [ "사업명", "테스트" ], [], HEADER,
             [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ],
             [ 2, "의자", "표준", "개", 5, 2_000, 10_000 ],
             [ "소계", "", "", "", "", "", 20_000 ],
             [ 3, "서가", "5단", "개", 2, 5_000, 10_000 ],
             [ 4, "설치비", "운반", "식", 1, 5_000, 5_000 ],
             [ "소계", "", "", "", "", "", 15_000 ],
             [ "공급가액", "", "", "", "", "", 35_000 ] ]
    b = basis(rows)
    items = ReviewLab::ItemTable.parse(b)
    assert_equal 4, items.size, "소계에서 표 읽기가 멈췄다: #{items.map(&:name)}"
    refute_includes items.map(&:name), "소계", "소계 행이 품목으로 들어가 금액이 이중 계상된다"
    # 잘렸다면 품목 합(20,000)과 공급가액(35,000)이 어긋나 **거짓 BLOCK** 이 났을 것이다.
    assert_equal [ "PASS" ], sev(review(b), "B-SUM")
  end

  test "최종 합계·부가세에서는 여전히 표 읽기를 멈춘다 — 소계 예외가 과탐이 아니다" do
    rows = [ [ "사업명", "테스트" ], [], HEADER,
             [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ],
             [ "공급가액", "", "", "", "", "", 10_000 ],
             [ "부가세", "", "", "", "", "", 1_000 ],
             [ "합계", "", "", "", "", "", 11_000 ] ]
    items = ReviewLab::ItemTable.parse(basis(rows))
    assert_equal [ "책상" ], items.map(&:name)
  end

  test "부가세 검산은 공급가액·부가세를 **둘 다** 가진 문서를 고른다" do
    # 사업계획서가 공급가액만 적은 경우, 그 문서를 집으면 산출기초의 부가세 검산이 사라진다.
    p = plan([ [ "사업명", "테스트" ], [ "공급가액", "999,999원" ], [ "총사업비", "11,000원" ] ])
    b = basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ],
                         supply: 10_000, vat: 1_000, total: 11_000, name: "테스트"))
    r = review(p, b)
    assert_equal [ "PASS" ], sev(r, "B-VAT")
    assert_equal [ "PASS" ], sev(r, "B-TOTAL")
  end

  test "B-ROW-COVERAGE — 검산하지 못한 행이 있으면 «몇 개를 못 쟀는지» 를 적는다" do
    rows = [ [ "사업명", "테스트" ], [], HEADER,
             [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ],
             [ 2, "잡비", "일식", "식", "", "", 5_000 ],
             [ "공급가액", "", "", "", "", "", 15_000 ] ]
    r = review(basis(rows))
    f = find(r, "B-ROW-COVERAGE").first
    assert_equal "CHECK", f.severity
    assert_includes f.problem, "1개는"
    assert_equal [ "PASS" ], sev(r, "B-ROW")   # 읽힌 행은 맞다 — 둘은 다른 말이다
  end

  test "모든 행이 검산되면 coverage 경고를 내지 않는다" do  # 음성 대조
    r = review(basis(basis_rows([ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ] ], supply: 10_000)))
    assert_empty find(r, "B-ROW-COVERAGE")
  end

  test "예산과목 라벨은 띄어쓰기 변형도 읽는다" do
    p = plan([ [ "사업명", "테스트" ], [ "총사업비", "10,000원" ], [ "예산 과목", "학교운영비" ] ])
    assert_equal [ "CHECK" ], sev(review(p), "B-ACCOUNT")
  end

  # ── 판정 권위 불변식 — AI 는 어떤 경로로도 확정·통과를 만들 수 없다 ──
  # P4 가 예산 축에 AI 의미검사를 열었으므로 이 축에서도 계약과 **같은 보장**이 성립해야 한다.
  test "AI 가 낸 판정은 무엇을 넣든 CHECK 로 고정된다" do
    ReviewLab::Finding::SEVERITIES.each do |asked|
      f = ReviewLab::Finding.new(severity: asked, code: "AI-X", problem: "p", origin: :ai)
      assert_equal "CHECK", f.severity, "origin=:ai 인데 #{asked} 가 그대로 나갔다"
      assert f.ai?
    end
  end

  test "규칙 판정은 요청한 severity 를 그대로 쓴다 — 위 고정이 과탐이 아님을 보인다" do
    ReviewLab::Finding::SEVERITIES.each do |asked|
      assert_equal asked, ReviewLab::Finding.new(severity: asked, code: "R", problem: "p").severity
    end
  end

  test "AI finding 은 검사 통과 수(rule_findings)에 섞이지 않는다" do
    r = ReviewLab::Demo.run_budget
    r.add(ReviewLab::Finding.new(severity: "PASS", code: "AI-OVERBROAD", problem: "p", origin: :ai))
    refute_includes r.rule_findings.map(&:code), "AI-OVERBROAD"
    assert_includes r.ai_findings.map(&:code), "AI-OVERBROAD"
    assert_equal "CHECK", r.ai_findings.first.severity
  end

  # ── 구조 불변식 ─────────────────────────────────────────────────
  test "읽을 수 없는 문서만 올리면 «문제 없음» 이 아니라 «검사 불가» 다" do
    r = review(doc("not a document".b, "project_plan", "깨진 파일"))
    assert r.inconclusive?
    assert_includes r.headline, "«문제 없음» 으로 보면 안"
    # 검사를 한 건도 못 돌렸으므로 finding 도 0 이어야 한다.
    # 「항목을 찾지 못했습니다」 같은 WARN 이 나오면 읽지도 못한 문서를 **검사한 척** 하는 것이다.
    assert_equal 0, r.rules_run
    assert_empty r.findings.map(&:code)
  end

  test "이 검증기는 어떤 입력에서도 «적정·부적정·위법» 을 말하지 않는다" do
    r = ReviewLab::Demo.run_budget
    text = r.findings.flat_map { |f| [ f.problem, f.why_it_matters, f.suggested_action ] }.compact.join(" ")
    %w[적정합니다 부적정 위법 집행 가능합니다].each { |w| refute_includes text, w }
  end

  test "산출기초는 학교/지자체 기준을 가르지 않는다 — 결과 문구에 지자체 기준 주장이 없다" do
    text = ReviewLab::Demo.run_budget.findings.map(&:problem).join(" ")
    refute_includes text, "지방재정법"
    refute_includes text, "지방자치단체 기준"
  end

  # ── R3 독립 검토 수리 회귀 ───────────────────────────────────────
  # 이 4개는 «변이를 죽이려고» 쓴 것이 아니라 R3 가 **실제 입력으로 재현**한 결함이다.

  test "R3 «총계» 로 끝나는 산출기초 — 합계 행을 품목으로 이중 계상하지 않는다" do
    rows = [ [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ], [ 2, "의자", "표준", "개", 5, 2_000, 10_000 ] ]
    doc = basis([ [ "사업명", "총계 서식" ], [], HEADER ] + rows + [ [ "총계", "", "", "", "", "", 20_000 ] ])
    assert_equal 2, ReviewLab::ItemTable.parse(doc).size, "«총계» 행이 품목으로 읽히면 안 된다"
    r = review(doc)
    assert_equal [ "PASS" ], sev(r, "B-SUM"), "정상 문서에 거짓 BLOCK 이 나면 안 된다"
  end

  test "R3 «총계» 는 FieldExtractor 가 합계로 인정하는 라벨과 같은 어휘다" do
    # 한쪽만 알면 같은 행을 «합계» 이자 «품목» 으로 읽는다 — 그 어긋남 자체를 고정한다.
    assert_includes ReviewLab::FieldExtractor::BUDGET_FIELDS[:grand_total][2], "총계"
    assert "총계".match?(ReviewLab::ItemTable::STOP_ROW)
  end

  test "R3 check_vat — 세 값을 다 가진 문서를 고른다(합계 있는 문서의 산술 모순을 놓치지 않는다)" do
    p_doc = plan([ [ "사업명", "가상초" ], [ "공급가액", "10,000원" ], [ "부가세", "1,000원" ] ])
    b_doc = basis([ [ "사업명", "가상초" ], [], HEADER, [ 1, "책상", "표준", "개", 1, 10_000, 10_000 ],
                    [ "공급가액", "", "", "", "", "", 10_000 ], [ "부가세", "", "", "", "", "", 1_000 ],
                    [ "합계", "", "", "", "", "", 12_000 ] ])
    r = review(p_doc, b_doc)
    assert_equal [ "BLOCK" ], sev(r, "B-TOTAL"), "합계 12,000 != 공급가액+부가세 11,000 은 BLOCK 이어야 한다"
    refute skipped?(r, "B-TOTAL")
  end

  test "R3 B-SUM 은 총사업비로 폴백하지 않는다 — 부가세 포함 관행값에 거짓 BLOCK 금지" do
    doc = plan([ [ "사업명", "가상초" ], [ "총사업비", "11,000,000원" ], [], HEADER,
                 [ 1, "책상", "표준", "개", 100, 100_000, 10_000_000 ] ])
    r = review(doc)
    assert_empty find(r, "B-SUM"), "총사업비(부가세 포함)와 품목 합(부가세 별도)을 견주면 안 된다"
    assert skipped?(r, "B-SUM"), "검사를 못 돌렸으면 그 사실을 말해야 한다"
  end

  test "R3 B-ROW PASS 는 검산한 행만 «맞다» 고 말한다 — coverage CHECK 와 모순되지 않는다" do
    doc = basis([ [ "사업명", "가상초" ], [], HEADER, [ 1, "책상", "표준", "개", 10, 1_000, 10_000 ],
                  [ 2, "설치비", "운반", "식", "", "", 200_000 ], [ "공급가액", "", "", "", "", "", 210_000 ] ])
    r = review(doc)
    assert_equal [ "CHECK" ], sev(r, "B-ROW-COVERAGE")
    assert_equal [ "PASS" ], sev(r, "B-ROW")
    refute_includes find(r, "B-ROW").first.problem, "모든 행",
                    "검산하지 못한 행이 있는데 «모든 행» 이라고 말하면 화면이 거짓을 말한다"
    assert_includes find(r, "B-ROW").first.problem, "검산한 1개 행"
  end

  test "R3 라벨 공백 변형은 추출 전 정규화로 흡수된다(«예산  과목» 2칸)" do
    # R3 리뷰어는 field_extractor 만 보고 «미인식» 이라 했으나, TextExtractor 가 앞서 공백을 압축한다.
    r = review(plan([ [ "사업명", "가상초" ], [ "예산  과목", "학교운영비" ] ]))
    assert_equal [ "CHECK" ], sev(r, "B-ACCOUNT")
    assert_equal "학교운영비", find(r, "B-ACCOUNT").first.extracted_value
  end
end
