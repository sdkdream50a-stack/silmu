# 2026-05-19 권위자 P6(CTO) 권고 #B — dispatcher silent failure 검증
#
# 배경: Phase A~E batch #1~#4에서 정정한 폐지·부정확 법령 인용이
#       시드 dispatcher 누락(예: budget_execution_part2.rb 단독 실행)으로 운영 DB에
#       silent failure로 잔존할 수 있음. 본 테스트는 dispatcher 실행 후
#       정정 패턴이 실제로 적용됐는지 자동 검증한다.
#
# 패턴: skip if 시드 데이터 없는 환경 (CI에서 fixture 환경 보호)
#       시드 dispatcher 실행은 별도 (rake silmu:seed_all 또는 운영 DB)
#       본 테스트는 "이미 시드된 DB"에서 부정확 잔존 0건 보장
#
# 사용: bin/rails test test/integration/dispatcher_safety_test.rb

require "test_helper"

class DispatcherSafetyTest < ActiveSupport::TestCase
  # ── batch #1 — 회계·재정 정정 패턴 (commit eed4ceb) ──────────────────────
  test "batch #1: budget-planning-complete-3~9 폐지 조문 §47의3·시행령 §45 잔존 0건" do
    skip "시드 환경 미설정" if Guide.where("slug LIKE ?", "budget-planning-complete-%").count.zero?

    (3..9).each do |n|
      g = Guide.find_by(slug: "budget-planning-complete-#{n}")
      next unless g
      s = g.sections.to_json
      assert_not_includes s, "제47조의3", "budget-planning-complete-#{n}에 폐지된 §47의3 잔존"
      assert_not_includes s, "시행령 제45조", "budget-planning-complete-#{n}에 폐지된 시행령 §45 잔존"
      assert_not_includes s, "지방재정법 제51조", "budget-planning-complete-#{n}에 폐지된 §51 잔존"
      assert_not_includes s, "지방재정법 제52조", "budget-planning-complete-#{n}에 폐지된 §52 잔존"
    end
  end

  test "batch #1: budget-execution-complete-6~8 폐지 조문 + 부정확 매핑 잔존 0건" do
    skip "시드 환경 미설정" if Guide.where("slug LIKE ?", "budget-execution-complete-%").count.zero?

    %w[budget-execution-complete-6 budget-execution-complete-7 budget-execution-complete-8].each do |slug|
      g = Guide.find_by(slug: slug)
      next unless g
      s = g.sections.to_json
      assert_not_includes s, "시행령 제46조", "#{slug}에 부정확 매핑 시행령 §46(주민참여 ≠ 과목구분) 잔존"
      assert_not_includes s, "시행령 제65조", "#{slug}에 부정확 매핑 시행령 §65(재정분석 ≠ 예비비) 잔존"
      assert_not_includes s, "시행령 제72조", "#{slug}에 부정확 매핑 시행령 §72(긴급재정 ≠ 사고이월) 잔존"
      assert_not_includes s, "지방재정법 제51조", "#{slug}에 폐지된 §51 잔존"
    end
  end

  # ── batch #2 — 지방계약법 §42 정정 (commit 1484de6~35944f7) ──────────────
  test "batch #2: construction-contract-complete-3 §39+공고기간 / §42+현장설명 잔존 0건" do
    skip "시드 환경 미설정" if Guide.where("slug LIKE ?", "construction-contract-complete-%").count.zero?

    g = Guide.find_by(slug: "construction-contract-complete-3")
    return unless g
    s = g.sections.to_json

    # §39 = 입찰서 무효 (공고 기간 아님). §35가 공고 기간 본조
    assert_not(s.include?("시행령 제39조") && s.include?("공고 기간"),
               "construction-contract-complete-3에 §39+공고기간 부정확 매핑 잔존")

    # §42 = 낙찰자 결정 본조. "현장설명"·"입찰보증금"·"2인 이상" 컨텍스트는 부정확
    refute_match(/시행령\s*제42조[^.]{0,60}현장설명/, s,
                 "construction-contract-complete-3에 §42+현장설명 부정확 잔존 (정확: §15)")
  end

  test "batch #2: construction-contract-complete-* 입찰금액 vs 추정가격 정확" do
    skip "시드 환경 미설정" if Guide.where("slug LIKE ?", "construction-contract-complete-%").count.zero?

    Guide.where("slug LIKE ?", "construction-contract-complete-%").find_each do |g|
      s = g.sections.to_json
      # "입찰보증금 + 추정가격의 5%" 부정확 패턴 (정확: 입찰금액의 5% = §37 ①항)
      refute_match(/입찰보증금[^.]{0,40}추정가격의\s*5\s*%/, s,
                   "#{g.slug}에 입찰보증금+추정가격 5% 부정확 잔존")
    end
  end

  # ── batch #3 — 공무원수당·여비 정정 (commit 4e27d90) ────────────────────
  test "batch #3: travel-expense-complete-* 폐지 §14 + 부정확 §21/§18/§11 잔존 0건" do
    skip "시드 환경 미설정" if Guide.where("slug LIKE ?", "travel-expense-complete-%").count.zero?

    Guide.where("slug LIKE ?", "travel-expense-complete-%").find_each do |g|
      s = g.sections.to_json

      # §14 = 삭제된 조문 (silmu가 "일일출장 정의"로 잘못 인용했었음)
      assert_not_includes s, "공무원여비규정 제14조", "#{g.slug}에 폐지된 여비규정 §14 잔존"

      # §21 = 국내 가족여비 (silmu가 "숙박비 실비"로 잘못 인용)
      refute_match(/공무원여비규정\s*제21조[^.]{0,30}숙박비/, s,
                   "#{g.slug}에 §21+숙박비 부정확 잔존 (정확: §16 ①)")

      # §11 = 선박운임 (silmu가 "자가용 마일리지"로 잘못 인용)
      refute_match(/공무원여비규정\s*제11조[^.]{0,30}자가용/, s,
                   "#{g.slug}에 §11+자가용 부정확 잔존 (정확: 별표 2)")

      # §18 = 근무지 내 출장 (silmu가 "관사 숙박비 제외"로 잘못 인용)
      refute_match(/공무원여비규정\s*제18조[^.]{0,30}(자가용|관사)/, s,
                   "#{g.slug}에 §18+자가용/관사 부정확 잔존 (정확: 별표 2 + 처리지침)")
    end
  end

  test "batch #3: hr-welfare-complete-7 §18의3+성과상여금 부정확 잔존 0건" do
    skip "시드 환경 미설정" if Guide.where("slug LIKE ?", "hr-welfare-complete-%").count.zero?

    g = Guide.find_by(slug: "hr-welfare-complete-7")
    return unless g
    s = g.sections.to_json

    # §18의3 = 명절휴가비 (silmu가 "성과상여금"으로 잘못 인용했음. 정확: §7의2)
    refute_match(/공무원수당[등에 ]*관한\s*규정\s*제18조의3[^.]{0,30}성과상여금/, s,
                 "hr-welfare-complete-7에 §18의3+성과상여금 부정확 잔존 (정확: §7의2)")

    # §5~§12 범위 인용 (§5·§6 삭제 포함)
    assert_not_includes s, "공무원수당 등에 관한 규정 제5조~제12조",
                        "hr-welfare-complete-7에 §5~§12 범위 인용 잔존 (§5·§6 삭제)"
  end

  # ── batch #4 — 지방회계법 §29 시행령 위임 (commit 48be993) ──────────────
  test "batch #4: expenditure-commitment / budget-execution 토픽 §29+시행령 위임 잔존 0건" do
    skip "시드 환경 미설정" if Topic.count.zero?

    %w[expenditure-commitment budget-execution].each do |slug|
      t = Topic.find_by(slug: slug)
      next unless t
      content = [ t.law_content, t.decree_content, t.rule_content, t.commentary ].compact.join("\n")

      # §29는 시행령 직접 위임 없음 (②항이 "법령·조례·규칙" 일반 위임만)
      refute_match(/제29조[^.]{0,80}시행령에서\s*정한다/, content,
                   "Topic #{slug}에 §29+시행령 위임 부정확 잔존")
    end
  end

  # ── 권위자 재검증 — 「공무원 여비 업무 처리 기준」 부정확 명칭 (commit 8a638e0) ──
  test "권위자 #2: 「공무원 여비 업무 처리 기준」 부정확 명칭 잔존 0건" do
    skip "시드 환경 미설정" if Guide.count.zero?

    bad_name = "공무원 여비 업무 처리 기준"  # mcp 행정규칙 DB 미등록 명칭

    Guide.find_each do |g|
      s = (g.sections || {}).to_json
      assert_not_includes s, "「#{bad_name}」", "Guide #{g.slug}에 부정확 예규 명칭 잔존"
    end

    Topic.find_each do |t|
      content = [ t.law_content, t.decree_content, t.rule_content, t.commentary ].compact.join("\n")
      assert_not_includes content, "「#{bad_name}」", "Topic #{t.slug}에 부정확 예규 명칭 잔존"
    end

    AuditCase.find_each do |ac|
      content = [ ac.legal_basis, ac.issue, ac.detail, ac.lesson ].compact.join("\n")
      assert_not_includes content, "「#{bad_name}」", "AuditCase #{ac.slug}에 부정확 예규 명칭 잔존"
    end
  end

  # ── 5단계 게이트 정합성 (batch #2 hotfix-2 — bid-deposit 운영 DB 직접 부정확) ──
  test "batch #2 hotfix-2: bid-deposit Topic 폐지·부정확 인용 잔존 0건" do
    skip "시드 환경 미설정" if Topic.where(slug: "bid-deposit").count.zero?

    t = Topic.find_by(slug: "bid-deposit")
    return unless t
    content = [ t.law_content, t.decree_content, t.rule_content, t.commentary ].compact.join("\n")

    # §41 = 수입 입찰 낙찰자 결정 (silmu가 입찰보증금 본조로 잘못 인용)
    refute_match(/입찰보증금[^.]{0,40}시행령\s*제41조|시행령\s*제41조[^.]{0,40}입찰보증금/, content,
                 "bid-deposit Topic에 §41+입찰보증금 부정확 잔존 (정확: §37)")

    # §78 = 장기계속계약 (silmu가 입찰보증금 국고 귀속으로 잘못 인용)
    refute_match(/입찰보증금[^.]{0,40}시행령\s*제78조|시행령\s*제78조[^.]{0,40}(입찰보증금|국고에\s*귀속)/, content,
                 "bid-deposit Topic에 §78+입찰보증금 부정확 잔존 (정확: §38)")
  end
end
