# frozen_string_literal: true

require "test_helper"

# 입찰공고 패키지 검증기 V1 — 문서 간 일관성과 §35 공고기간.
class ReviewLab::PackageReviewerTest < ActiveSupport::TestCase
  B = ReviewLab::FixtureBuilder

  def d(role, label, blocks) = ReviewLab::TextExtractor.call(bytes: B.docx(blocks), role: role, label: label)

  def notice(ann: "2026. 10. 1.", deadline: "2026. 10. 10. 18:00", price: "45,000,000원", extra: [])
    d("notice", "공고문", [
      [ "사업명", "가상 사업" ], [ "추정가격", price ], [ "공고일", ann ],
      [ "입찰서 제출기간", "#{ann} 10:00 ~ #{deadline}" ], [ "개찰일시", "2026. 10. 12. 11:00" ],
      [ "입찰참가자격", "물품 제조업 등록 업체" ], [ "계약방법", "제한경쟁입찰" ], [ "낙찰자 결정방법", "적격심사" ],
      [ "문의처", "행정실 (02-000-0000)" ], *extra
    ])
  end

  def review_of(*docs, **opts) = ReviewLab::PackageReviewer.call(documents: docs, **opts)
  def found(r, code) = r.findings.select { |f| f.code == code }

  test "양성 대조 — 같은 값이면 충돌 0 · 일치 항목 PASS" do
    r = review_of(notice, d("task_order", "과업지시서", [ "1. 사업명: 가상 사업", "2. 추정가격: 45,000,000원" ]))
    assert_empty found(r, "X-CONFLICT")
    assert_match(/추정가격/, found(r, "X-CONSISTENT").first.problem)
  end

  test "음성 대조 — 금액이 다르면 BLOCK 충돌로 잡고 두 문서의 위치를 모두 준다" do
    r = review_of(notice, d("task_order", "과업지시서", [ "2. 추정가격: 40,000,000원" ]))
    f = found(r, "X-CONFLICT").first
    assert_equal "BLOCK", f.severity
    assert_match(/공고문/, f.location)
    assert_match(/과업지시서/, f.location)
  end

  test "기한은 «일수» 끼리만 비교 — 일수와 날짜 범위가 섞이면 충돌이 아니라 형식 다름(CHECK)" do
    a = d("notice", "공고문", [ "납품기한: 계약일로부터 30일" ])
    b = d("spec", "규격서", [ "납품기한: 2026. 11. 1. ~ 2026. 11. 30." ])
    r = review_of(a, b)
    assert_empty found(r, "X-CONFLICT")
    assert_equal "CHECK", found(r, "X-FORMAT").first.severity
  end

  test "한 문서 안의 모순도 잡는다 — 단, 다품목 수량은 모순이 아니다(원문 대조)" do
    r = review_of(d("notice", "공고문", [ "추정가격: 45,000,000원", "추정가격: 40,000,000원" ]), d("spec", "규격서", [ "사업명: 가상 사업" ]))
    assert_equal "BLOCK", found(r, "X-INTERNAL").first.severity
    multi = review_of(d("spec", "규격서", [ "가. 전자칠판", "수량: 10대", "나. 거치대", "수량: 2대" ]), d("notice", "공고문", [ "수량: 12대" ]))
    assert_empty found(multi, "X-INTERNAL")
    assert_empty found(multi, "X-CONFLICT")
    assert_equal "원문 대조", multi.comparisons.find { |c| c[:key] == :quantity }[:verdict]
    assert_equal "CHECK", found(multi, "X-QTY-MULTI").first.severity, "N9 — 침묵하지 않고 확인을 요청한다"
  end

  test "§35 공고기간 — 간격 8일↑ PASS · 정확히 7일 CHECK(경계) · 6일↓ WARN, 근거 조문 인용" do
    g = { contract_type: "goods" }
    pass = review_of(notice(ann: "2026. 10. 1.", deadline: "2026. 10. 9. 18:00"), notice, **g)
    edge = review_of(notice(ann: "2026. 10. 1.", deadline: "2026. 10. 8. 18:00"), notice(ann: "2026. 10. 1.", deadline: "2026. 10. 8. 18:00"), **g)
    short = review_of(notice(ann: "2026. 10. 5.", deadline: "2026. 10. 10. 18:00"), notice(ann: "2026. 10. 5.", deadline: "2026. 10. 10. 18:00"), **g)
    assert_equal "PASS", found(pass, "P-35").first.severity
    assert_equal "CHECK", found(edge, "P-35").first.severity
    w = found(short, "P-35").first
    assert_equal "WARN", w.severity
    cite = w.evidence.first
    assert_equal "제35조제1항", cite[:locator]
    assert_match(/law\.go\.kr/, cite[:url])
  end

  test "§35⑤ 협상에 의한 계약은 추정가격 구간별 기간(1억 이상 10억 미만 = 20일)" do
    n = notice(ann: "2026. 10. 1.", deadline: "2026. 10. 16. 18:00", price: "300,000,000원",
               extra: [])
    n2 = d("notice", "공고문", n.segments.map { |s| s[:cells] || s[:text] }.map { |c| c == [ "계약방법", "제한경쟁입찰" ] ? [ "계약방법", "협상에 의한 계약" ] : c })
    r = review_of(n2, d("spec", "규격서", [ "사업명: 가상 사업" ]))
    f = found(r, "P-35").first
    assert_equal "WARN", f.severity, "15일 < 20일"
    assert_match(/기준 20일/, f.extracted_value)
  end

  test "§35③ 공사(현장설명 없음) 10억 이상은 15일" do
    n = notice(ann: "2026. 10. 1.", deadline: "2026. 10. 11. 18:00", price: "1,200,000,000원")
    r = review_of(n, d("spec", "규격서", [ "사업명: 가상 사업" ]), contract_type: "construction_general")
    assert_match(/기준 15일/, found(r, "P-35").first.extracted_value)
  end

  test "지방계약법 밖의 기관(사립학교)은 공고기간을 판정하지 않고 CHECK" do
    r = review_of(notice(ann: "2026. 10. 5.", deadline: "2026. 10. 10. 18:00"), notice, agency_scope: "PRIVATE_SCHOOL")
    f = found(r, "P-35").first
    assert_equal "CHECK", f.severity
    assert_match(/지방계약법/, f.problem)
  end

  test "일정 순서 역전은 BLOCK" do
    n = notice(ann: "2026. 10. 5.", deadline: "2026. 10. 3. 18:00")
    r = review_of(n, d("spec", "규격서", [ "사업명: 가상 사업" ]))
    assert(found(r, "P-ORDER").any? { |f| f.severity == "BLOCK" })
  end

  test "공고문 필수 항목 누락은 WARN · 공고문이 없으면 건너뛴 이유를 남긴다" do
    r = review_of(d("notice", "공고문", [ "사업명: 가상 사업" ]), d("spec", "규격서", [ "사업명: 가상 사업" ]))
    assert_operator found(r, "X-MISSING").size, :>=, 5
    r2 = review_of(d("spec", "규격서", [ "사업명: 가상 사업" ]), d("task_order", "과업지시서", [ "사업명: 가상 사업" ]))
    assert(r2.skipped_rules.any? { |s| s[:code] == "X-MISSING" })
  end

  test "업종·면허는 후보(CHECK)로만 — 참가자격에 업종이 있으면 PASS, 없으면 CHECK · 과업에 없으면 아무 말도 안 한다" do
    task = d("task_order", "과업지시서", [ "나. 교실 전원 콘센트 증설 및 배선 공사" ])
    r = review_of(notice, task)
    assert_equal "CHECK", found(r, "L-LICENSE").first.severity
    assert_equal "CHECK", found(r, "L-SPLIT").first.severity
    with = notice(extra: [ [ "업종", "전기공사업 등록 업체" ] ])
    assert_equal "PASS", found(review_of(with, task), "L-LICENSE").first.severity
    plain = review_of(notice, d("task_order", "과업지시서", [ "가. 전자칠판 12대 납품" ]))
    assert_empty found(plain, "L-LICENSE")
    assert_empty found(plain, "L-SPLIT")
  end

  test "기초금액÷추정가격 1.1 은 PASS, 같으면 CHECK(부가세 포함 여부 확인)" do
    ok = review_of(notice(extra: [ [ "기초금액", "49,500,000원" ] ]), d("spec", "규격서", [ "사업명: 가상 사업" ]))
    assert_equal "PASS", found(ok, "P-PRICE").first.severity
    same = review_of(notice(extra: [ [ "기초금액", "45,000,000원" ] ]), d("spec", "규격서", [ "사업명: 가상 사업" ]))
    assert_equal "CHECK", found(same, "P-PRICE").first.severity
  end

  # ── 독립 리뷰(정확성) 회귀 ──────────────────────────────────────────
  test "R#1 기준을 정할 값(계약유형·추정가격)을 모르면 최소 7일 초과만으로 PASS 하지 않는다" do
    unknown_type = review_of(notice(ann: "2026. 10. 1.", deadline: "2026. 10. 10. 18:00"), d("spec", "규격서", [ "사업명: 가상 사업" ]))
    assert_equal "CHECK", found(unknown_type, "P-35").first.severity
    no_price = d("notice", "공고문", [ [ "기초금액", "3,300,000,000원" ], [ "공고일", "2026. 10. 1." ], [ "입찰마감", "2026. 10. 10. 18:00" ] ])
    r = review_of(no_price, d("spec", "규격서", [ "사업명: 가상 사업" ]), contract_type: "construction_general")
    assert_equal "CHECK", found(r, "P-35").first.severity
  end

  test "R#2 «입찰방법: 전자입찰» 은 계약방법이 아니다 — 뒤의 «협상에 의한 계약» 이 §35⑤ 를 켠다" do
    n = d("notice", "공고문", [ [ "추정가격", "500,000,000원" ], [ "공고일", "2026. 10. 1." ], [ "입찰마감", "2026. 10. 10. 18:00" ],
                              [ "입찰방법", "전자입찰" ], [ "계약방법", "협상에 의한 계약" ] ])
    f = found(review_of(n, d("spec", "규격서", [ "사업명: 가상 사업" ]), contract_type: "service"), "P-35").first
    assert_equal "WARN", f.severity
    assert_match(/기준 20일/, f.extracted_value)
  end

  test "R#3 날짜의 «30일» 을 기간으로 읽지 않는다 — 다른 마감일은 충돌" do
    r = review_of(d("notice", "공고문", [ "납품기한: 2026년 11월 30일까지" ]), d("spec", "규격서", [ "납품기한: 2026년 10월 30일까지" ]))
    assert_equal "BLOCK", found(r, "X-CONFLICT").first.severity
  end

  test "R#5 «계약기간 만료 후 14일 이내» 같은 문장을 계약기간 값으로 읽지 않는다" do
    r = review_of(d("task_order", "과업지시서", [ "계약기간: 계약일로부터 60일", "계약기간 만료 후 14일 이내에 대금을 지급한다." ]),
                  d("spec", "규격서", [ "사업명: 가상 사업" ]))
    assert_empty found(r, "X-INTERNAL")
  end

  test "R#10·R#11 오후 시각을 읽고, 같은 날 개찰이 마감보다 이르면 순서 오류" do
    n = d("notice", "공고문", [ [ "공고일", "2026. 10. 1." ], [ "입찰마감", "2026. 10. 12. 오후 2시" ], [ "개찰일시", "2026. 10. 12. 13:00" ] ])
    r = review_of(n, d("spec", "규격서", [ "사업명: 가상 사업" ]))
    assert(found(r, "P-ORDER").any? { |f| f.severity == "BLOCK" })
  end

  test "R#14 라벨을 하나도 못 읽은 묶음은 «문제 없음» 이 아니라 검사 불가" do
    r = review_of(d("task_order", "과업지시서", [ "그냥 설명 문장입니다." ]), d("spec", "규격서", [ "규격은 별도 협의." ]))
    assert r.inconclusive?
    assert_match(/문제 없음/, r.headline)
  end

  test "열린 질문 — 다품목 문서가 있어도 수량이 하나뿐인 문서끼리는 계속 대조한다" do
    multi = d("spec", "규격서", [ "수량: 10대", "수량: 2대" ])
    r = review_of(d("notice", "공고문", [ "수량: 12대" ]), d("task_order", "과업지시서", [ "수량: 15대" ]), multi)
    assert_equal "BLOCK", found(r, "X-CONFLICT").first.severity
    assert_equal "CHECK", found(r, "X-QTY-MULTI").first.severity
  end
end
