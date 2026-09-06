# frozen_string_literal: true

require "test_helper"

#
# 배포 blocker 정정 시드 — **기존 row UPDATE 경로** 회귀 (2026-09-06)
#
# 독립검증(agy)이 F3 로 잡은 것: 원천 시드는 `find_or_create_by!` 라서 **이미 적재된 운영 row 를
# 갱신하지 않는다.** 파일에 정정 문구가 있다는 것과 운영 row 가 바뀐다는 것은 다른 사실이다.
# 그래서 이 테스트는 «파일에 문자열이 있는가»가 아니라 **«기존 row 가 실제로 update 되는가»**를 잰다.
#
# 없는 row 를 새로 만들어 통과시키면 실패다 — created == 0 을 함께 단언한다.
#
class DeployBlockerFixSeedTest < ActiveSupport::TestCase
  SEED = "db/seeds/topic_deploy_blocker_fix_2026_09_06.rb"

  # 운영 실측(2026-09-06 READ-ONLY probe)과 같은 «정정 전» 값
  OLD_ISSUE = "□□도 ○○교육지원청에서 실내환경 개선사업(총사업비 1억 5천만원)을 수의계약 한도액(5천만원)을 " \
              "초과한다는 이유로 동일 업체와 3개 계약(각 5천만원)으로 분할 체결하였다."
  OLD_LEGAL = "지방계약법 시행령 제25조 제1항 제1호 (소액 수의계약), 지방계약법 시행령 제77조 (계약 분할 금지), " \
              "행정안전부 예규 제2023-24호 제5장 제2절 (계약 분할 금지 기준)"
  OLD_LEGAL_F1 = "지방계약법 시행령 제25조 제1항 제1호 (소액 수의계약), 행정안전부 예규 제2023-24호 제5장 제3절 " \
                 "(2인 이상 견적서 징구 기준), 지방계약법 시행규칙 제43조 (견적서 제출 업체 독립성)"
  OLD_CHECKPOINTS = [ "총사업비가 수의계약 한도(5천만원)를 초과하는지 사업 전체 기준으로 판단" ].to_json
  OLD_TOPIC_LAW = "<strong>지방계약법 시행령 제25조 제1항 제1호 (수의계약 한도)</strong>\n<li>가. 공사</li>"
  # G1 — 괄호 표기가 없어 앞 라운드 탐지기를 빠져나간 같은 오용 (본문 detail)
  OLD_DETAIL_G1 = "담당자는 이 사업을 \"기성 소프트웨어 패키지 구매\"로 분류하여, " \
                  "지방계약법 시행령 제25조 제1항 제1호의 물품 수의계약 기준(2,000만원 초과 시 경쟁 원칙)을 " \
                  "무시하고 특정 IT 업체 A사와 직접 수의계약을 체결했습니다."

  # §25①1호를 **정확히** 긴급계약 문맥으로 쓴 레코드 — 건드리면 안 된다(음성 대조)
  EMERGENCY_LEGAL = "지방계약법 시행령 제25조 제1항 제1호 (천재지변·긴급 — 입찰에 부칠 여유가 없는 경우)"

  # 모듈만 로드한다. autorun 을 켜두면 load 시점에 이미 적용돼
  # «기존 row 가 update 되는가» 라는 양성 대조가 무력해진다(실제로 3건 실패했다).
  def seed_module
    ENV["SILMU_SEED_AUTORUN"] = "0"
    load Rails.root.join(SEED)
    SilmuDeployBlockerFix20260906
  end

  def build_existing_rows!
    @split = AuditCase.create!(
      slug: "private-contract-split-over-limit", title: "계약 쪼개기", published: true,
      issue: OLD_ISSUE, legal_basis: OLD_LEGAL, checkpoints: OLD_CHECKPOINTS,
      verification_source: SilmuDeployBlockerFix20260906.expected_verification_source(OLD_LEGAL)
    )
    @quote = AuditCase.create!(
      slug: "quote-collection-same-vendor-double", title: "견적 2인 동일업체", published: true,
      legal_basis: OLD_LEGAL_F1
    )
    @emergency = AuditCase.create!(
      slug: "test-emergency-contract-25-1-1", title: "긴급 수의계약", published: true,
      legal_basis: EMERGENCY_LEGAL
    )
    @goods = AuditCase.create!(
      slug: "software-dev-misclassified-as-goods", title: "SW 개발을 물품구매로 오분류", published: true,
      detail: OLD_DETAIL_G1
    )
    @topic = Topic.create!(slug: "private-contract-limit", name: "수의계약 한도", law_content: OLD_TOPIC_LAW)
  end

  setup do
    seed_module   # 모듈 정의만 (autorun OFF)
    AuditCase.where(slug: %w[private-contract-split-over-limit quote-collection-same-vendor-double
                            software-dev-misclassified-as-goods
                            test-emergency-contract-25-1-1]).delete_all
    Topic.where(slug: "private-contract-limit").delete_all
    build_existing_rows!
  end

  # ── P3 — 기존 row UPDATE 양성 대조 ────────────────────────────
  test "P3: 기존 row 가 존재할 때 UPDATE 가 실제로 수행된다 (created 0)" do
    before_count = AuditCase.count + Topic.count
    s = seed_module.apply!
    assert_operator s[:updated], :>, 0, "기존 row 가 있는데 updated=0 — UPDATE 경로가 죽었다"
    assert_equal 0, s[:created], "정정 시드가 row 를 새로 만들었다 — create 로 통과시키면 실패다"
    assert_equal before_count, AuditCase.count + Topic.count, "row 수가 변했다 = create/delete 가 일어났다"
    assert_empty s[:missing], "대상 row 를 못 찾았다: #{s[:missing].inspect}"
  end

  test "P3: 없는 row 를 새로 만들지 않는다 (missing 으로 보고)" do
    AuditCase.where(slug: "quote-collection-same-vendor-double").delete_all
    s = seed_module.apply!
    assert_includes s[:missing], "AuditCase:quote-collection-same-vendor-double"
    assert_nil AuditCase.find_by(slug: "quote-collection-same-vendor-double"),
               "없는 row 를 새로 만들었다"
  end

  # ── B1 / B2 / F1 / F5 값 대조 ────────────────────────────────
  test "B1: 기존 row 의 「한도 = 5천만원」 단정이 실제로 사라진다" do
    seed_module.apply!
    r = AuditCase.find_by(slug: "private-contract-split-over-limit")
    assert_not_includes r.issue, "수의계약 한도액(5천만원)"
    assert_not_includes r.checkpoints.to_s, "수의계약 한도(5천만원)"
    assert_includes r.checkpoints.to_s, "제25조제1항제5호의 계약유형·상대방 요건에 따라 다름"
    # 사건 사실은 보존 (과잉정정 0)
    assert_includes r.issue, "총사업비 1억 5천만원"
    assert_includes r.issue, "3개 계약(각 5천만원)"
    # 다른 하나의 고정 숫자로 바꿔치기하지 않았는지
    assert_no_match(/수의계약\s*한도(?:액)?\s*\(\s*\d[\d,]*\s*(?:천만원|억원|만원)\s*\)/, r.issue.to_s + r.checkpoints.to_s)
  end

  test "B2·F1: 두 published 레코드의 §25①1호 오기가 제5호로 정정된다" do
    seed_module.apply!
    %w[private-contract-split-over-limit quote-collection-same-vendor-double].each do |slug|
      lb = AuditCase.find_by(slug: slug).legal_basis
      assert_not_includes lb, "제25조 제1항 제1호 (소액 수의계약)", "#{slug}: §25①1호 오기 잔존"
      assert_includes lb, "제25조 제1항 제5호 (소액 수의계약 — 세부 목은 계약유형·상대방 요건에 따라 확인)",
                      "#{slug}: 제5호 정정문 없음"
      assert_no_match(/제5호\s*[가-바]목/, lb, "#{slug}: 세부 목을 임의 지정했다")
    end
  end

  test "F5: Topic 의 한도 표제가 제5호로 정정된다" do
    seed_module.apply!
    lc = Topic.find_by(slug: "private-contract-limit").law_content
    assert_not_includes lc, "제25조 제1항 제1호 (수의계약 한도)"
    assert_includes lc, "제25조 제1항 제5호 (수의계약 한도)"
  end

  test "G1: 괄호 없는 §25①1호 오용이 본문에서 제5호 나목으로 정정된다" do
    seed_module.apply!
    d = AuditCase.find_by(slug: "software-dev-misclassified-as-goods").detail
    assert_not_includes d, "제25조 제1항 제1호의 물품 수의계약 기준", "§25①1호 오용 잔존"
    assert_includes d, "제25조 제1항 제5호 나목의 물품 수의계약 기준", "제5호 나목 정정문 없음"
    # 사건 사실·금액은 보존 (과잉정정 0). 새 한도 숫자를 만들지 않았다.
    assert_includes d, "2,000만원 초과 시 경쟁 원칙"
    assert_includes d, "기성 소프트웨어 패키지 구매"
  end

  # ── F2 — verification_source 동기화 ──────────────────────────
  test "P2: legal_basis 정정 전 verification_source 는 stale 로 검출되고, 정정 후 0 이 된다" do
    mod = seed_module
    r = AuditCase.find_by(slug: "private-contract-split-over-limit")
    # BEFORE: 아직 legal_basis 가 옛 값이라 파생값과 «일치» 한다 → stale 아님
    assert_equal mod.expected_verification_source(r.legal_basis), r.verification_source

    # legal_basis 만 고치고 verification_source 를 두면 stale 이 만들어진다 (양성 대조)
    r.update_column(:legal_basis, r.legal_basis.sub("제1호 (소액 수의계약)", "제5호 (소액 수의계약)"))
    r.reload
    assert_not_equal mod.expected_verification_source(r.legal_basis), r.verification_source,
                     "stale 탐지기가 죽었다 — legal_basis 를 바꿨는데 stale 로 안 잡힌다"

    # 시드가 같은 생성 계약으로 다시 만든다
    mod.apply!
    r.reload
    assert_equal mod.expected_verification_source(r.legal_basis), r.verification_source,
                 "STALE_VERIFICATION_SOURCE != 0"
    assert r.verification_source.start_with?(mod::VS_PREFIX), "생성 계약(prefix)을 벗어났다"
    assert_operator r.verification_source.length, :<=, mod::VS_MAX, "생성 계약의 길이 예산 초과"
  end

  test "F2 음성 대조: 파생 계약이 아닌 verification_source 는 건드리지 않는다" do
    r = AuditCase.find_by(slug: "quote-collection-same-vendor-double")
    r.update_column(:verification_source, "사람이 직접 쓴 검증 메모")
    seed_module.apply!
    assert_equal "사람이 직접 쓴 검증 메모", r.reload.verification_source,
                 "파생 계약이 아닌 값을 덮어썼다"
  end

  # ── 음성 대조 — 정당한 §25①1호 긴급계약 ──────────────────────
  test "음성 대조: §25①1호를 긴급계약으로 정확히 쓴 레코드는 수정되지 않는다" do
    seed_module.apply!
    assert_equal EMERGENCY_LEGAL, AuditCase.find_by(slug: "test-emergency-contract-25-1-1").legal_basis,
                 "정당한 §25①1호 긴급계약 인용을 과잉정정했다"
  end

  # ── 멱등 ────────────────────────────────────────────────────
  test "멱등: 두 번째 실행은 아무 row 도 갱신하지 않는다" do
    mod = seed_module
    first = mod.apply!
    assert_operator first[:updated], :>, 0
    second = mod.apply!
    assert_equal 0, second[:updated], "멱등하지 않다 — 두 번째 실행이 또 갱신한다"
    assert_equal 0, second[:created]
  end
end
