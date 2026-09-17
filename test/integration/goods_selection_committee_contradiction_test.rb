# frozen_string_literal: true

require "test_helper"

# P0-5 (LECTURE_READINESS_AUDIT R3) — 물품선정위원회 토픽 내부 모순·허위 근거.
#
# 이 테스트는 두 층으로 되어 있다.
#
#   ① 시드 없이도 도는 층 — migration 파일 자체를 읽어, 정정 대상 문구를 «옛 것 → 새 것» 으로
#      다루고 있는지와 지문(sha256) 가드가 붙어 있는지를 본다. 시드 환경에 의존하지 않는다.
#   ② 시드가 있을 때만 도는 층 — 실제 Topic 본문에 문제 문구가 0건인지 본다.
#      (기존 dispatcher_safety_test 의 콘텐츠 가드와 같은 방식 · 운영 검증은 배포 스모크가 맡는다)
#
# 원문 대조 근거(2026-09-18): 행안부 「지방자치단체 입찰 및 계약집행기준」·지방계약법·시행령 전문에
#   «물품선정위원회» 0건 · 집행기준의 «선정위원회» 14건은 전부 공법선정위원회 · 시행령 제43조 부재.
class GoodsSelectionCommitteeContradictionTest < ActionDispatch::IntegrationTest
  MIGRATION = Rails.root.join(
    "db/content_migrations/20260918150000_goods_selection_committee_contradictions.rb"
  )

  # 문장 단위 치환으로 정정한 문구 — migration 안에 «옛 것» 으로 적혀 있어야 한다.
  SUBSTITUTED = [
    "| 의무 개최 | 추정가격 **500만원** 이상",          # decree — qa 3,000만원·interp 2억원과 충돌
    "| **합계** | **3~5명** |",                          # decree — regulation «최소 5인 이상» 과 충돌
    "위원회 소집 (3일 전 통보)",                          # rule — regulation «7일 전» 과 충돌
    "위원회 구성 (3~5인)",                                # tips
    "위원회 소집 통보 (3일 전)",                          # tips
    "추정가격 **3,000만원 이상** 물품 구매 시",            # qa
    "위원 수: 통상 5명 이상",                             # qa
    "외부위원 비율: 전체의 1/3 이상 권장",                 # qa
    "구매 담당 부서를 구속하는 효력을 가집니다",            # interp — 법정 위원회가 아닌데 구속력 단정
    "행정안전부 예규에서는 외부 전문가 참여를 권장하고 있으나", # interp — 예규에 규정 0건
    "2억 원 이상의 물품 구매에서",                         # interp
    "(행정안전부 유권해석)",                               # interp — 원문 미확인 출처 표기
    # ⚠️ 통합 스모크가 잡은 누락 — 본문 탭만 보고 JSONB·해설 탭을 놓쳤다.
    #    faqs 는 **FAQPage 구조화 데이터로도 노출**돼 검색 결과에 그대로 나간다.
    "3~5명이 일반적이며",                                  # faqs — 인원 축
    "500만원 이상 물품 구매 시 내부 규정으로 의무화",        # faqs — 금액 축
    # ⚠️ commentary 원문에는 <strong> 태그가 끼어 있다 — 태그를 건너뛰는 조각으로 센다.
    "물품 구매 시 개최하도록 내부 규정을 두고",              # commentary — 금액 축
    "보통 500만원 미만"                                    # commentary — 금액 축
  ].freeze

  # regulation_content 는 허위 근거 «구조» 라 문장 치환으로 닫히지 않아 전체를 교체했다.
  # 따라서 이 문구들은 migration 안에 옛 것으로 적히지 않고, 새 본문에 없어야 한다.
  REPLACED_AWAY = [
    "### 제1장 물품선정위원회의 의의 및 근거",   # 원문에 없는 예규 장 구조
    "**최소 구성:** 5인 이상",                   # decree 3~5명과 충돌
    "심의 7일 전 위원에게 안건 자료 배포"        # rule 3일 전과 충돌
  ].freeze

  # 본문(운영) 층에서 0건이어야 하는 문구 = 위 둘의 합집합.
  CONTRADICTIONS = (SUBSTITUTED + REPLACED_AWAY).freeze

  # 정정 후 반드시 있어야 하는 정직한 서술.
  REQUIRED = [
    "«물품선정위원회» **0건**",
    "제32조(계약심의위원회의 설치ㆍ운영)",
    "실무 판단 예시 — 유권해석 원문 미확인"
  ].freeze

  # ── ① 시드 없이도 도는 층
  test "migration 파일이 존재하고 지문 가드를 갖고 있다" do
    assert MIGRATION.exist?, "P0-5 content migration 이 없다"
    src = MIGRATION.read
    assert_match(/Digest::SHA256\.hexdigest/, src, "지문 가드 없이 본문을 덮어쓴다")
    assert_match(/DRY_RUN/, src, "DRY_RUN 경로가 없다")
    assert_match(/raise .*substitution did not apply/, src,
                 "치환이 실제로 적용됐는지 단정하지 않는다")
  end

  test "migration 이 치환 대상 모순 문구 전부를 다룬다" do
    src = MIGRATION.read
    SUBSTITUTED.each do |bad|
      assert_includes src, bad,
                      "migration 이 이 문구를 다루지 않는다 — 정정 범위에서 빠졌다: #{bad.inspect}"
    end
  end

  test "전체 교체한 본문에 허위 근거 구조가 되살아나 있지 않다" do
    src = MIGRATION.read
    REPLACED_AWAY.each do |bad|
      assert_not_includes src, bad,
                          "새 regulation_content 에 허위 근거가 남아 있다: #{bad.inspect}"
    end
    # 그리고 시행령 제43조는 «근거» 로 쓰이지 않고 «부재» 로만 언급돼야 한다.
    assert_includes src, "현행 시행령에는 제43조 자체가 없으며"
    assert_not_includes src, "「지방계약법 시행령」 제43조, 「물품관리법」 및 행정안전부 예규에 근거합니다"
  end

  test "faqs·commentary 축도 migration 이 다룬다 (JSONB·구조화 데이터 노출면)" do
    src = MIGRATION.read
    assert_includes src, "FAQ_SUBSTITUTIONS", "faqs 를 다루지 않는다 — 검색 결과에 옛 수치가 남는다"
    assert_includes src, "FAQS_FINGERPRINT", "faqs 에 지문 가드가 없다"
    assert_includes src, "COMMENTARY_SUBSTITUTIONS", "commentary 를 다루지 않는다"
    assert_includes src, "COMMENTARY_FINGERPRINT", "commentary 에 지문 가드가 없다"
    assert_match(/faqs still contains/, src, "faqs 치환 후 옛 문구 잔존을 단정하지 않는다")
  end

  test "본문 층 검사가 faqs·commentary 도 본다" do
    skip "시드 환경 미설정" if Topic.count.zero?
    topic = Topic.find_by(slug: "goods-selection-committee")
    skip "토픽 미시드" if topic.nil?

    surfaces = [ topic.faqs.to_json, topic.commentary.to_s ].join("\n")
    [ "3~5명이 일반적이며", "500만원 이상 물품 구매 시 내부 규정으로 의무화",
      "물품 구매 시 개최하도록 내부 규정을 두고", "보통 500만원 미만" ].each do |bad|
      assert_not_includes surfaces, bad, "faqs/commentary 에 모순 문구 잔존: #{bad.inspect}"
    end
  end

  test "migration 이 새 서술로 확인된 사실만 쓴다" do
    src = MIGRATION.read
    REQUIRED.each { |good| assert_includes src, good, "새 서술 누락: #{good.inspect}" }
    # 어느 숫자도 공식 근거가 없으므로 «옳은 숫자» 로 바꾸지 않았는지 본다.
    assert_includes src, "소속 기관 규정에서 정한 금액 이상"
    assert_includes src, "기관 규정에서 정한 인원"
  end

  # ── ② 시드가 있을 때만 도는 층
  test "물품선정위원회 토픽 본문에 모순 문구 0건" do
    skip "시드 환경 미설정" if Topic.count.zero?
    topic = Topic.find_by(slug: "goods-selection-committee")
    skip "토픽 미시드" if topic.nil?

    body = %i[law_content decree_content rule_content regulation_content
              practical_tips interpretation_content qa_content commentary]
           .map { |c| topic.public_send(c) }.compact.join("\n")

    CONTRADICTIONS.each do |bad|
      assert_not_includes body, bad, "물품선정위원회 토픽에 모순 문구 잔존: #{bad.inspect}"
    end
  end
end
