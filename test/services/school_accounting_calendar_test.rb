# frozen_string_literal: true

require "test_helper"

# P3 — 학교회계 일정 엔진.
#
# 이 엔진이 틀리면 «법정 기한» 이라고 적힌 날짜가 틀린다. 그래서 검사는 두 가지를 본다.
#   ① 조문 텍스트가 **법제처 원문과 글자 그대로 같은가** (우리가 요약·의역하지 않았는가)
#   ② 날짜 산식이 **교육청이 같은 조문을 환산해 공표한 값과 같은가** (우리 해석이 아닌가)
#
# ②의 대조군은 두 교육청의 2026학년도 예산편성 기본지침이 **직접 적은 날짜**다 —
#   전라남도교육청: 50일 전 = 2026.1.9. · 30일 전 = 2026.1.29. · 5일 전 = 2026.2.23.
#   부산광역시교육청: 50일 전 = 2026.1.9. · 30일 전 = 2026.1.29.
# 서로 독립된 두 교육청이 같은 값을 적었고, 우리 산식이 그 값을 재현한다.
class SchoolAccountingCalendarTest < ActiveSupport::TestCase
  C = SchoolAccountingCalendar

  # ── 회계연도 ───────────────────────────────────────────────────────────
  test "회계연도는 3월 1일에 시작해 다음 해 2월 말일에 끝난다" do
    assert_equal Date.new(2026, 3, 1), C.fiscal_start(2026)
    assert_equal Date.new(2027, 2, 28), C.fiscal_end(2026)
  end

  test "윤년이면 2월 29일에 끝난다" do
    # 2027학년도는 2028년 2월에 끝나고 2028년은 윤년이다.
    assert_equal Date.new(2028, 2, 29), C.fiscal_end(2027)
    assert_equal 29, C.fiscal_end(2027).day
  end

  test "2월 말일을 28일로 못 박지 않았다" do  # 음성 대조 — 하드코딩이면 이 검사가 걸린다
    leap_ends = (2020..2040).map { |y| C.fiscal_end(y).day }.tally
    assert leap_ends.key?(29), "21년치 중 2월 29일에 끝나는 회계연도가 하나도 없다 — 말일 계산이 굳어 있다"
    assert leap_ends.key?(28), "28일에 끝나는 회계연도가 없다 — 계산이 반대로 굳어 있다"
  end

  test "1·2월은 직전 학년도에 속한다 — 회계연도 전환 경계" do
    assert_equal 2025, C.fiscal_year(Date.new(2026, 2, 28))
    assert_equal 2026, C.fiscal_year(Date.new(2026, 3, 1))
    assert_equal 2026, C.fiscal_year(Date.new(2027, 2, 28))
    assert_equal 2027, C.fiscal_year(Date.new(2027, 3, 1))
  end

  test "회계연도는 빈틈도 겹침도 없이 이어진다" do
    (2024..2035).each do |y|
      assert_equal C.fiscal_end(y) + 1, C.fiscal_start(y + 1),
                   "#{y}학년도 종료 다음 날이 #{y + 1}학년도 개시일이 아니다"
    end
  end

  # ── 「N일 전까지」 환산 : 교육청 공표값과 대조 ───────────────────────────
  test "30일 전 = 2026.1.29 — 전남·부산 2026학년도 지침이 적은 날짜" do
    assert_equal Date.new(2026, 1, 29), C.days_before_start(2026, 30)
  end

  test "5일 전 = 2026.2.23 — 전남 2026학년도 지침이 적은 날짜" do
    assert_equal Date.new(2026, 2, 23), C.days_before_start(2026, 5)
  end

  test "50일 전 = 2026.1.9 — 전남·부산이 모두 적은 날짜(산식 교차검증)" do
    # 이 축은 화면에 쓰지 않는다. 같은 산식이 **다른 N** 에서도 공표값을 맞히는지 보는 대조다.
    assert_equal Date.new(2026, 1, 9), C.days_before_start(2026, 50)
  end

  test "역산은 윤년에서 하루 밀린다" do
    # 2028학년도 개시 2028-03-01, 직전 2월은 29일 → 30일 전은 1월 30일이다(1월 29일이 아니다).
    assert_equal Date.new(2028, 1, 30), C.days_before_start(2028, 30)
    assert_equal Date.new(2028, 2, 24), C.days_before_start(2028, 5)
  end

  test "역산 산식이 틀린 값을 실제로 걸러낸다" do  # 양성 대조
    naive = C.fiscal_start(2026) - 30   # 「그냥 30일 빼기」 = 1월 30일
    assert_not_equal naive, C.days_before_start(2026, 30),
                     "단순 30일 빼기와 결과가 같다 — 대조가 무의미하다"
    assert_equal Date.new(2026, 1, 30), naive
  end

  # ── 「끝난 후 N개월 이내」 ──────────────────────────────────────────────
  test "결산서 제출 = 회계연도 종료 후 2개월 — 민법 제157조·제160조" do
    # 2026학년도 종료 2027-02-28 → 기산 2027-03-01 → 만료 2027-04-30
    assert_equal Date.new(2027, 4, 30), C.months_after_end(2026, 2)
  end

  test "결산 심의결과 통보 = 종료 후 3개월" do
    assert_equal Date.new(2027, 5, 31), C.months_after_end(2026, 3)
  end

  test "윤년 종료에서도 개월 계산이 4월 30일로 떨어진다" do
    assert_equal Date.new(2028, 4, 30), C.months_after_end(2027, 2)   # 종료 2028-02-29
  end

  # ── 조문 원문 ──────────────────────────────────────────────────────────
  # 법제처 국가법령정보 「초·중등교육법」(법령일련번호 283903 · 시행 2026-09-11) 원문 대조.
  test "준예산은 법률이 닫아 둔 다섯 가지 그대로다" do
    assert_equal 5, C::PROVISIONAL_BUDGET_ITEMS.size
    assert_equal [ "교직원 등의 인건비",
                   "학교교육에 직접 사용되는 교육비",
                   "학교시설의 유지관리비",
                   "법령상 지급 의무가 있는 경비",
                   "이미 예산으로 확정된 경비" ],
                 C::PROVISIONAL_BUDGET_ITEMS.map { |i| i[:text] }
    assert_equal (1..5).to_a, C::PROVISIONAL_BUDGET_ITEMS.map { |i| i[:no] }
  end

  test "준예산 조문 본문을 요약하지 않고 그대로 싣는다" do
    text = C::PROVISIONAL_BUDGET_CLAUSE
    assert_includes text, "새로운 회계연도가 시작될 때까지 확정되지 아니하면"
    assert_includes text, "전년도 예산에 준하여 집행할 수 있다"
    assert_includes text, "확정된 예산에 따라 집행된 것으로 본다"
  end

  test "마일스톤 조문 텍스트가 법률 원문 문구를 담는다" do
    by_key = C.milestones(2026).index_by(&:key)
    assert_includes by_key[:budget_submission].statute_text, "회계연도가 시작되기 30일 전까지"
    assert_includes by_key[:committee_review].statute_text, "회계연도가 시작되기 5일 전까지"
    assert_includes by_key[:settlement_submission].statute_text, "회계연도가 끝난 후 2개월 이내에"
    assert_includes by_key[:fiscal_start].statute_text, "매년 3월 1일에 시작하여 다음 해 2월 말일에 끝난다"
  end

  # ── 근거 층 분리 ───────────────────────────────────────────────────────
  test "법률 기한과 교육규칙 기한을 같은 층으로 적지 않는다" do
    ms = C.milestones(2026)
    law = ms.select { |m| m.basis == :law }.map(&:key)
    rule = ms.select { |m| m.basis == :edu_rule }.map(&:key)

    assert_includes law, :budget_submission
    assert_includes law, :committee_review
    assert_includes law, :settlement_submission
    assert_includes rule, :guideline
    assert_includes rule, :settlement_review
    assert_empty(law & rule)
    assert ms.all? { |m| m.citation.present? }, "근거가 없는 마일스톤이 있다"
  end

  test "법률 근거 마일스톤은 초·중등교육법 제30조의3 을 인용한다" do
    C.milestones(2026).select { |m| m.basis == :law }.each do |m|
      assert_match(/초·중등교육법 제30조의3제\d항/, m.citation, "#{m.key} 의 인용이 조항까지 가지 않는다")
    end
  end

  test "교육규칙 근거 마일스톤은 적용 교육청 수를 함께 적는다" do  # 전국 공통처럼 보이면 안 된다
    C.milestones(2026).select { |m| m.basis == :edu_rule }.each do |m|
      assert_match(%r{\d+/17}, m.uniformity, "#{m.key} 가 몇 개 교육청에 해당하는지 적지 않는다")
    end
  end

  # ── 17개 교육규칙 레지스트리 ───────────────────────────────────────────
  # 2026-09-20 변형시험 M22 생존 — «17개 있다」만 재면 한 교육청 이름이 바뀌어도(=그 교육청이
  # 사라져도) 통과한다. 어느 17개인지 이름으로 고정한다.
  ALL_OFFICES = %w[서울 부산 대구 인천 광주 대전 울산 세종 경기 강원 충북 충남 전북 전남 경북 경남 제주].freeze

  test "17개 시·도교육청 규칙이 전부 있다 — 어느 17개인지까지" do
    assert_equal ALL_OFFICES.sort, C.regional_rules.map { |r| r[:code] }.sort,
                 "교육청 목록이 바뀌었다 — 빠진 곳이 있으면 그 지역 사용자에게 화면이 거짓이 된다"
    assert_equal 17, C.regional_rules.size
    assert_equal 17, C.regional_rules.map { |r| r[:ordin_seq] }.uniq.size, "자치법규 번호가 중복됐다"
    assert C.regional_rules.all? { |r| r[:ordin_seq].is_a?(Integer) }, "자치법규 일련번호가 없는 항목이 있다"
    assert C.regional_rules.all? { |r| r[:rule_name].present? }
  end

  test "출납폐쇄는 전국 공통이 아니라는 사실이 데이터에 남아 있다" do
    assert_nil C.uniform_rule_value(:closing_type), "출납폐쇄가 균일한 것으로 기록돼 있다"
    split = C.rule_value_split(:closing_type)
    assert_equal 2, split.size
    assert_equal 17, split.values.sum(&:size)
    assert_equal 11, split["after_end_20_days"].size
    assert_equal 6, split["year_end_with_exception"].size
  end

  test "균일한 축은 균일하다고 판정한다" do  # 음성 대조 — 전부 «갈린다» 로 답하면 무의미하다
    assert_equal 3, C.uniform_rule_value(:guideline_months_before),
                 "17개가 모두 3개월인데 균일 판정이 나오지 않는다"
  end

  test "조항이 없는 교육청은 다수값으로 메우지 않는다" do
    jeonnam = C.regional_rule("전남")
    assert_nil jeonnam[:meeting_notice_days], "전남 규칙에 없는 조항이 값으로 채워져 있다"
    assert_nil jeonnam[:settlement_review_months]
    value, count = C.majority_rule_value(:settlement_review_months)
    assert_equal 3, value
    assert_equal 16, count, "조항 없는 교육청까지 세고 있다"
  end

  # 2026-09-20 변형시험 M09 생존 — 현재 데이터에서는 nil 을 세든 말든 다수값이 같아서
  # 차이가 드러나지 않는다. **차이가 드러나는 입력**을 직접 먹여 본다.
  test "다수값은 조항 없는 교육청을 세지 않는다" do
    # 현재 17개 데이터에서는 nil 을 세든 말든 결과가 같아 차이가 드러나지 않는다(M09).
    # nil 이 **다수인** 입력을 직접 먹인다.
    assert_equal [ 7, 2 ], C.majority_of([ nil, nil, nil, 7, 7 ]),
                 "조항이 없는 쪽이 다수라고 해서 «없음» 을 기한으로 삼았다"
  end

  test "값이 하나도 없으면 다수값도 없다" do
    assert_equal [ nil, 0 ], C.majority_of([ nil, nil ])
  end

  # 2026-09-20 독립 리뷰(Medium) — 8자리 날짜를 `scan(/\d{4}|\d{2}/)` 로 자르면 남은 4자리가
  # 다시 `\d{4}` 에 걸려 «2016.1114» 가 나왔다. 화면에 **틀린 시행일**이 찍히던 결함이다.
  test "시행일자 8자리를 사람이 읽는 날짜로 바꾼다" do
    {
      "20161114" => "2016.11.14",
      "20160229" => "2016.2.29",
      "20250901" => "2025.9.1",
      "623860"   => "623860",      # 8자리가 아니면 손대지 않는다
      nil        => ""
    }.each do |raw, expected|
      assert_equal expected, C.format_effective_date(raw), "입력 #{raw.inspect}"
    end
  end

  test "17개 규칙의 시행일자가 전부 변환된다" do  # 한 건이라도 8자리가 아니면 화면이 원문을 그대로 뱉는다
    C.regional_rules.each do |rule|
      formatted = C.format_effective_date(rule[:effective])
      assert_match(/\A\d{4}\.\d{1,2}\.\d{1,2}\z/, formatted,
                   "#{rule[:code]} 의 시행일자 #{rule[:effective].inspect} 가 날짜로 안 보인다")
    end
  end

  test "자치법규 링크가 법제처 원문을 가리킨다" do
    url = C.ordinance_url(C.regional_rule("서울"))
    assert_equal "https://www.law.go.kr/LSW/ordinInfoP.do?ordinSeq=1263963", url
  end

  # ── 국면 ───────────────────────────────────────────────────────────────
  test "국면 경계는 기한에서 나온다" do
    {
      Date.new(2026, 3, 1)  => :settlement,     # 전년도 결산서 제출 기한(4/30) 전
      Date.new(2026, 4, 30) => :settlement,     # 기한 당일은 아직 결산기
      Date.new(2026, 5, 1)  => :execution,
      Date.new(2026, 11, 30) => :execution,
      Date.new(2026, 12, 1) => :compilation,    # 지침 시달(개시 3개월 전)
      Date.new(2027, 1, 28) => :compilation,
      Date.new(2027, 1, 29) => :review,         # 예산안 제출 기한
      Date.new(2027, 2, 23) => :review,         # 심의 기한 당일
      Date.new(2027, 2, 24) => :confirmation,
      Date.new(2027, 2, 28) => :confirmation,
      Date.new(2027, 3, 1)  => :settlement      # 새 회계연도 개시 + 전년도 결산기
    }.each do |date, expected|
      assert_equal expected, C.phase(date), "#{date} 의 국면"
    end
  end

  test "1년 어느 날에도 국면이 정해진다" do  # 구멍이 있으면 화면이 «집행기» 로 조용히 떨어진다
    (Date.new(2026, 3, 1)..Date.new(2027, 2, 28)).each do |d|
      assert_includes C::PHASES.keys, C.phase(d), "#{d} 의 국면이 정의되지 않았다"
    end
  end

  test "모든 국면에 설명이 있다" do
    C::PHASES.each_key { |k| assert C::PHASE_NOTES[k].present?, "#{k} 국면 설명이 없다" }
  end

  # ── status ─────────────────────────────────────────────────────────────
  test "status 는 인접 회계연도를 함께 본다 — 집행과 편성은 동시에 돈다" do
    s = C.status(on: Date.new(2026, 9, 20))
    assert_equal 2026, s[:fiscal_year]
    assert_equal "2026학년도", s[:fiscal_year_label]
    assert_equal :execution, s[:phase]
    assert_equal 204, s[:days_elapsed]
    assert_equal 161, s[:days_remaining]

    years = s[:upcoming].map(&:fiscal_year).uniq
    assert_includes years, 2027, "다음 회계연도 편성 기한이 보이지 않는다"
    assert_includes years, 2026, "올해 기한이 보이지 않는다"
  end

  test "다가오는 기한은 오늘 이후만이고 날짜 순이다" do
    on = Date.new(2026, 9, 20)
    s = C.status(on: on)
    assert s[:upcoming].none? { |m| m.date < on }, "지난 기한이 남아 있다"
    assert_equal s[:upcoming].map(&:date).sort, s[:upcoming].map(&:date), "정렬이 깨졌다"
    assert_equal s[:upcoming].first, s[:next_milestone]
  end

  test "D-day 는 오늘을 0 으로 센다" do
    on = Date.new(2027, 1, 29)
    m = C.milestones(2027).find { |x| x.key == :budget_submission }
    assert_equal on, m.date
    assert_equal 0, m.days_from(on)
    assert_equal 1, m.days_from(on - 1)
    assert_not m.past?(on), "기한 당일을 «지남» 으로 센다"
    assert m.past?(on + 1)
  end

  # ── 지방자치단체 기준과 섞이지 않는다 ───────────────────────────────────
  test "이 엔진은 1~12월 회계연도를 쓰지 않는다" do  # LOCAL_GOV / SCHOOL 분리
    C.milestones(2026).each do |m|
      assert_not_equal [ 12, 31 ], [ m.date.month, m.date.day ], "#{m.key} 이 12월 31일이다 — 지자체 회계연도 가정"
      assert_not_equal [ 1, 1 ], [ m.date.month, m.date.day ], "#{m.key} 이 1월 1일이다 — 지자체 회계연도 가정"
    end
    assert_equal 3, C.fiscal_start(2026).month
  end

  test "지자체 업무달력 엔진은 그대로다" do  # 기존 자산 비회귀
    summaries = GovernmentCalendarIcsService::EVENTS.map { |e| e[:summary] }
    assert_includes summaries, "연말 예산 집행 마감 / 불용 처리", "지자체 달력에서 기존 이벤트가 사라졌다"
    assert_includes summaries, "전년도 결산보고서 제출"
    assert_equal 8, GovernmentCalendarIcsService::EVENTS.size, "지자체 달력 이벤트 수가 바뀌었다"
    assert GovernmentCalendarIcsService.generate.include?("BEGIN:VCALENDAR")
  end
end
