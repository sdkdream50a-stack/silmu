# frozen_string_literal: true

require "test_helper"

# 구기준 법령 수치가 코드·시드에 다시 들어오지 않게 막는다 (2026-09-17 전수감사 15_STALE_VALUE_SWEEP).
# 원문: 지방계약법 시행령 제30조 제1항 제2호(1인 견적 2천만원 이하) · 시행규칙 제75조(공사 0.5/1,000, 임대차 요율 없음) ·
#   공무원 여비 규정 별표 2(일비 25,000원) · 공무원수당 등에 관한 규정 제18조(월 16만원) · 지방계약법 시행령 제42조의2 삭제<2016. 1. 15.>, 제43조의2 없음.
# 시험(exam) 콘텐츠는 별도 PR 이 다룬다.
class StaleLegalLiteralsTest < ActiveSupport::TestCase
  EXCLUDED = %r{\Aapp/(views/exam|controllers/exam|models/exam_)}
  # 옛 문자열을 «찾는» 코드(검출기 패턴·과거 치환 스크립트의 old 값)는 게시 문구가 아니다.
  MATCHERS = %w[
    app/services/blog_legal_verifier.rb
    db/seeds/topic_content_fix_2026_08_04_penaltyrates.rb
  ].freeze

  COMMENT = /\A\s*(#|<%#)/ # 과거 정정 이력을 적은 주석

  PATTERNS = {
    "1인 견적 500만원" => /(5백만|500만) ?원[^\n]{0,12}(이하|초과|미만|이상)[^\n]{0,30}(1인|1개 ?(업체|사)|2인|2개)|(1인|단독) 견적[^\n]{0,15}(5백만|500만) ?원/,
    "공사 지체상금 1/1,000·0.1%/일" => %r{0\.1%/일|x 0\.1% x|(?<![\d.])1/1,?000 \(공사|공사[^\n"]{0,25}(?<![\d.])(1/1,?000|1,000분의 1(?![.\d]))},
    "임대차 지체상금률" => %r{임대차[^\n"]{0,15}(?<![\d.])(1(\.0)?/1,?000|1,000분의 1(?![.\d]))},
    "일비 20,000원" => /일비[^\n]{0,20}(20,000|2만 ?원(?!5))/,
    "정액급식비 14만원" => /정액급식비[^\n]{0,30}14만|14만 ?원 균일/,
    "낙찰하한율 근거 §42의2·§43·§43의2" => /낙찰하한율[^\n]{0,80}(제42조의2|§ ?42의2|제43조의2|§ ?43의2|시행령 제43조(?!의))|(제42조의2|§ ?42의2|제43조의2|§ ?43의2|시행령 제43조)[^\n]{0,10}\(?낙찰하한율/
  }.freeze

  def files(globs)
    globs.flat_map { |g| Dir[Rails.root.join(g)] }.map { |f| f.delete_prefix("#{Rails.root}/") }
         .reject { |f| f.match?(EXCLUDED) || MATCHERS.include?(f) }.uniq.sort
  end

  def hits(pattern, globs)
    files(globs).flat_map do |f|
      File.readlines(Rails.root.join(f)).each_with_index.select { |line, _| !line.match?(COMMENT) && line.match?(pattern) }.map { |_, i| "#{f}:#{i + 1}" }
    end
  end

  PATTERNS.each do |name, pattern|
    test "NORMAL: app·db/seeds 에 «#{name}» 구기준 문구가 없다" do
      assert_equal [], hits(pattern, %w[app/**/*.{rb,erb,js} db/seeds.rb db/seeds/**/*.rb])
    end
  end

  test "EDGE: 패턴은 옛 문구를 실제로 잡고 현행 문구는 통과시킨다" do
    {
      "1인 견적 500만원" => [ "※ 500만 원 이하는 1개 업체 견적도 가능", "※ 2천만 원 이하는 1개 업체 견적도 가능" ],
      "공사 지체상금 1/1,000·0.1%/일" => [ "| 지연배상금률 | 1/1,000 (공사, 1일당) |", "| 지연배상금률 | 0.5/1,000 (공사, 1일당) |" ],
      "임대차 지체상금률" => [ "임대차: 1,000분의 1 (시행규칙 제75조)", "임대차 요율은 따로 없고 물품 대여는 1,000분의 1.3" ],
      "일비 20,000원" => [ "| 일비 (1일) | 20,000원 | 20,000원 |", "| 일비 (1일) | 25,000원 | 25,000원 |" ],
      "정액급식비 14만원" => [ "정액급식비 월 14만원, 교통보조비 월 6만원", "정액급식비 월 16만원 (§18)" ],
      "낙찰하한율 근거 §42의2·§43·§43의2" => [ "지방계약법 시행령 제43조의2 (낙찰하한율) 규정에 따라", "지방계약법 시행령 제42조와 「지방자치단체 입찰시 낙찰자 결정기준」" ]
    }.each do |name, (stale, current)|
      assert_match PATTERNS.fetch(name), stale, name
      assert_no_match PATTERNS.fetch(name), current, name
    end
  end

  test "LOWER_BOUND: 적격심사 FAQ 근거는 삭제된 §42의2 가 아니라 §42, 낙찰하한율 시행일은 2026.1.2 가 아니다" do
    faq = Rails.root.join("app/controllers/faq_controller.rb").read
    assert_not_includes faq, "시행령 제42조의2)"
    assert_not_includes faq, "2026.1.2 변경"
    assert_includes Rails.root.join("app/views/tools/predetermined_price.html.erb").read, "value = '89.745'"
    assert_includes Rails.root.join("app/views/qualification_evaluations/index.html.erb").read, "§42의2는 2016. 1. 15. 삭제"
  end

  # 정부조직 개편(2026-01-02): 시드 원천이 운영 DB(20260917130000 치환)와 갈라지지 않게 한다.
  # 남는 것은 공통표준용어 등재 당시 기관명(데이터셋 원자료)과, 옛 문구를 찾는 과거 치환 스크립트의 old 값·잔존 검사값뿐이다.
  test "UPPER_BOUND: db/seeds 의 «기획재정부/기재부» 는 검토된 예외뿐이다" do
    allowed = {
      "db/seeds/standard_terms.csv" => 5,
      "db/seeds/topic_content_fix_2026_06_04_batch19.rb" => 3,
      "db/seeds/topic_content_fix_2026_06_15_bid_period.rb" => 2,
      "db/seeds/topic_s77_scope_fix_2026_09_06.rb" => 2
    }
    counts = Dir[Rails.root.join("db/seeds/**/*.{rb,csv,yml,json}"), Rails.root.join("db/seeds.rb")].to_h do |f|
      [ f.delete_prefix("#{Rails.root}/"), File.read(f).scan(/기획재정부|기재부/).size ]
    end.select { |_, n| n.positive? }
    assert_equal allowed, counts
  end

  test "EXCEPTION: 검출기 예외 목록은 실제로 옛 문자열을 «찾는» 파일에만 준다" do
    assert_match(/wrong_patterns/, Rails.root.join("app/services/blog_legal_verifier.rb").read)
    assert_match(/\[ "\| 공사 \| \*\*1\/1,000\*\* \|", "\| 공사 \| \*\*0\.5\/1,000\*\* \|" \]/,
                 Rails.root.join("db/seeds/topic_content_fix_2026_08_04_penaltyrates.rb").read)
  end
end
