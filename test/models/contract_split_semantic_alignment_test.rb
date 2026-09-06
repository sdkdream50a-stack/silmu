# frozen_string_literal: true

require "test_helper"

#
# R2 ↔ 레거시 콘텐츠 의미 정합 회귀 (2026-09-06)
#
# R2 판단 엔진과 레거시 본문이 **같은 질문에 반대 결론**을 내던 5건을 고정한다.
# 엔진 semantics 는 손대지 않는다 — 틀린 쪽은 전부 레거시 문구였다.
#
# 정본 (law.go.kr 실측 2026-09-06 · docs/silmu-p2/r2-align/_data/sources_verified.json):
#   지방계약법 시행령 [시행 2026. 6. 3.] [대통령령 제36338호] MST 286149 · 현행
#     §7제2호   추정가격의 산정 — 분할되어 이루어지는 계약은 직전/직후 12개월 또는
#               해당 회계연도 총액을 추정가격으로 본다. (금지 조항이 아니다)
#     §25①5호   다목 청년창업기업 2천만 초과 5천만 이하
#               라목 소기업·소상공인 2천만 초과 1억 이하
#               마목 학술연구·원가계산·건설기술 등 2천만 초과 1억 이하
#               바목 여성·장애인·사회적기업·사회적협동조합·자활기업·마을기업 2천만 초과 1억 이하
#               → 부칙에 유효기간 조항 없음. "2026.6.30 만료 후 3천만원 회귀"는 부존재.
#     §28       분할수의계약 — §25①6호가목·§26·§27 에 한정하여 수인에게 분할 계약 가능
#     §30①2호   1인 견적 2천만 이하, 단 청년창업·여성·장애인(가목) ·
#               사회적기업·사회적협동조합·자활기업·마을기업(나목) 은 5천만 이하
#     §77       **공사의** 분할계약 금지 — 표제·본문 모두 "공사". ①단서 1~3호 허용.
#   행정안전부 예규 「지방자치단체 입찰 및 계약 집행기준」 [시행 2026. 7. 1.] 예규 제372호
#     제1장 제1절 5.라 — "계약담당자는 용역·물품 계약에 대하여도 단일 사업을 **부당하게**
#     분할하거나 시기적으로 나누어 체결하지 않도록 해야 한다. 다만, 도서 등 간행물 구매 시
#     … 불가피한 사유가 있는 경우에는 분할하여 구매할 수 있다."
#     → 물품·용역 분할의 근거는 §77 이 아니라 이 예규 + §7제2호다. 그리고 "부당한" 분할이지
#       금액과 무관한 절대 금지가 아니며, 명시된 예외가 있다.
#
# 이 테스트는 DB 시드 여부에 의존하지 않도록 **원천 파일 텍스트**를 직접 검사한다.
# 각 탐지기는 BEFORE 문구에서 양성으로 먼저 증명한 뒤 현재 원천에서 0을 단언한다.
# (양성 대조 없는 "0건"은 탐지기가 죽었을 때와 구별되지 않는다.)
#
class ContractSplitSemanticAlignmentTest < ActiveSupport::TestCase
  # ── 탐지기 ────────────────────────────────────────────────
  DETECTORS = {
    # A — §77 을 계약유형 무관 "분할계약 금지" 조문으로 매핑
    d_77_unscoped_mapping: {
      re: /-\s*분할계약 금지\s*:\s*시행령 제77조/,
      before: "      - 분할계약 금지: 시행령 제77조",
      desc: "§77(공사 한정)을 계약유형 무관 분할금지 조문으로 매핑"
    },
    # B — 물품 분할이 금액과 무관하게 금지된다는 단정
    d_goods_split_absolute: {
      re: /분할계약은\s*금액과\s*무관하게\s*금지/,
      before: "다만 동일 물품을 나눠서 수의계약하는 분할계약은 금액과 무관하게 금지됩니다.",
      desc: "물품 분할을 금액 무관 절대금지로 단정 (예규 5.라 = '부당한' 분할 + 명시 예외)"
    },
    # C — 분할 자체를 절대 금지로 단정
    d_split_absolute_headline: {
      re: /분할계약\s*절대\s*금지/,
      before: "            분할계약 절대 금지!",
      desc: "분할계약 절대금지 단정 (§77①1~3호·예규 5.나/5.라 단서·§28 이 허용 경로를 둔다)"
    },
    d_any_split_is_flagged: {
      re: /1건의 계약을 2개 이상으로 분할하면/,
      before: "<p class=\"text-red-700\">1건의 계약을 2개 이상으로 분할하면 <strong>감사 1순위 지적 대상</strong>입니다.</p>",
      desc: "나눴다는 사실만으로 위법·지적이라는 단정"
    },
    # D — §25 특례를 5천만원으로 단정 / 만료 주장
    d_special_sunset_2026: {
      # 좁혀야 한다 — 2026.6.30 에 실제로 종료된 한시특례(보증금·절차, 행안부 고시 제2025-72호)가
      # 따로 있고 그 서술은 정본이다. 결함은 **§25 한도 특례 금액**에 그 만료를 붙인 것이다.
      re: /한시적 특례[^)]{0,90}(?:5천만원\s*~\s*1억원|3천만원으로 회귀)/,
      before: "(한시적 특례: 청년창업·소기업·여성·장애인·사회적기업 등은 5천만원~1억원 이하 ~2026.6.30 시행, 만료 후 종전 3천만원으로 회귀)",
      desc: "§25①5호 특례의 2026.6.30 만료·3천만원 회귀 주장 — 부칙에 유효기간 조항 부존재"
    },
    # E — §25 1억 특례 열거에서 소상공인(라목 명시 대상) 누락
    d_1eok_list_missing_micro: {
      re: /소기업·여성·장애인/,
      before: "특례: 소기업·여성·장애인·사회적기업 등 1억",
      desc: "§25①5호라목이 명시한 '소상공인'이 1억 특례 열거에서 누락"
    },
    # E — 대상을 밝히지 않은 "특례 1억" (청년창업 5천만을 1억으로 쓸어담는다)
    d_special_1eok_unqualified: {
      re: /\(특례\s*1억\)/,
      before: "<td style=\"border:1px solid #d1d5db; padding:12px; color:#1d4ed8;\">2천만원 (특례 1억)</td>",
      desc: "대상 없는 '특례 1억' — 청년창업기업(5천만·다목)까지 1억으로 읽힌다"
    }
  }.freeze

  # D 는 정규식이 아니라 **슬러그 블록 범위**로 판정한다.
  # 같은 문자열("특례기업 5천만원")이 §30(1인 견적)에서는 정본이고 §25(수의계약 한도)에서는
  # 틀리기 때문이다. 문맥 창(±90자)으로는 슬러그까지 닿지 않는다.
  SLUG_SCOPED = {
    "db/seeds/quick_stats.rb" => {
      wrong: %w[private-contract-limit],          # §25 한도
      right: %w[private-contract-amount]          # §30 견적
    },
    "db/seeds/quick_stats_sprint3.rb" => {
      wrong: %w[small-amount-contract],
      right: %w[single-quote]
    },
    "db/seeds/topic_fold_summary_2026_06_05_batch2.rb" => {
      wrong: %w[private-contract-limit small-amount-contract],
      right: %w[private-contract-amount]
    },
    "db/seeds/topic_fold_summary_2026_06_05.rb" => {
      wrong: [],
      right: %w[single-quote]
    }
  }.freeze
  # §25 한도 문맥의 결함 = "특례의 상한이 5천만원"이라는 단정.
  # 같은 낱말이 §30(1인 견적)에서는 정본이므로 **문자열**이 아니라 **블록의 결론**으로 판정한다:
  #   특례를 말하면서 5천만원을 상한으로 쓰고 1억원 계층이 없으면 §25 기준으로 틀렸다.
  SPECIAL_MENTION = /특례/
  FIVE_THOUSAND   = /5[,]?000만원|5천만원/
  ONE_EOK         = /1억/
  def special_capped_at_5000?(block)
    block.match?(SPECIAL_MENTION) && block.match?(FIVE_THOUSAND) && !block.match?(ONE_EOK)
  end

  SOURCES = %w[
    app/services/regulation_verifier.rb
    app/views/guides/contract_flow.html.erb
    app/views/contract_reasons/index.html.erb
    db/seeds/subtopics.rb
    db/seeds/quick_stats.rb
    db/seeds/quick_stats_sprint3.rb
    db/seeds/topic_fold_summary_2026_06_05.rb
    db/seeds/topic_fold_summary_2026_06_05_batch2.rb
  ].freeze

  def read_source(rel)
    path = Rails.root.join(rel)
    assert path.exist?, "원천 파일 부재: #{rel}"
    path.read
  end

  def scan(text, detector)
    hits = []
    text.to_s.scan(detector[:re]) { hits << Regexp.last_match }
    hits.map { |m| text[[ m.begin(0) - 60, 0 ].max...(m.end(0) + 60)].to_s }
  end

  # `"slug" =>` 부터 다음 최상위 항목(줄머리 두 칸 + 따옴표) 직전까지를 그 슬러그의 블록으로 본다.
  def slug_block(text, slug)
    start = text.index(/^\s*"#{Regexp.escape(slug)}"\s*=>/)
    return nil if start.nil?
    rest = text[(start + 1)..]
    stop = rest.index(/\n\s{0,4}"[a-z0-9-]+"\s*=>/)
    stop.nil? ? text[start..] : text[start, stop + 1]
  end

  # ── 0. 양성 대조 ────────────────────────────────────────
  test "양성 대조: 탐지기 전부가 BEFORE 문구에서 검출된다" do
    DETECTORS.each do |key, d|
      assert_match d[:re], d[:before],
                   "탐지기 #{key} 가 BEFORE 문구를 잡지 못한다 — 탐지기가 죽었다 (#{d[:desc]})"
    end
    # "특례 상한 = 5천만" 판정기도 BEFORE 표기에서 양성이어야 한다 (표기가 3가지였다).
    [
      %({ "label" => "물품·용역", "value" => "2,000만원", "note" => "특례기업 5,000만원" }),
      "물품·용역 2천만원(특례기업 5천만원) 이하입니다.",
      %({ "label" => "물품·용역", "value" => "2천만원 이하", "note" => "특례기업 5천만원" })
    ].each_with_index do |sample, i|
      assert special_capped_at_5000?(sample),
             "특례상한 판정기가 BEFORE 표기 ##{i} 를 잡지 못한다: #{sample[0, 50]}"
    end
    # 그리고 1억 계층이 함께 있으면 더 이상 잡으면 안 된다 (음성).
    refute special_capped_at_5000?(%({ "note" => "청년창업 5,000만원·소기업 등 1억원" })),
           "정정문(5천만+1억 두 계층)을 여전히 결함으로 센다"
  end

  test "양성 대조: 슬러그 블록 추출이 실제로 해당 구간만 잘라낸다" do
    src = read_source("db/seeds/quick_stats.rb")
    limit = slug_block(src, "private-contract-limit")
    amount = slug_block(src, "private-contract-amount")
    assert limit, "private-contract-limit 블록을 못 찾는다"
    assert amount, "private-contract-amount 블록을 못 찾는다"
    assert_includes limit, "종합공사", "한도 블록이 자기 내용을 담지 않는다"
    assert_not_includes limit, "1인 견적", "한도 블록이 견적 블록까지 삼켰다 — 범위 분리가 안 된다"
    assert_includes amount, "1인 견적", "견적 블록이 자기 내용을 담지 않는다"
  end

  # ── 음성 대조 ────────────────────────────────────────────
  test "음성 대조: 정정문에서는 검출되지 않는다" do
    after_samples = {
      d_77_unscoped_mapping: "      - 공사의 분할계약 금지: 시행령 제77조 (표제·본문 모두 \"공사\" — 물품·용역에 인용 금지)",
      d_goods_split_absolute: "동일 물품을 나눠 사면 시행령 §7제2호로 추정가격을 12개월/회계연도 총액으로 합산하며, 단일 사업을 부당하게 분할하는 것은 예규(집행기준 1장1절 5.라)로 금지됩니다.",
      d_split_absolute_headline: "            부당한 분할계약 금지",
      d_any_split_is_flagged: "<p class=\"text-red-700\">한도·경쟁을 회피하려고 단일 사업을 나누면 <strong>감사 1순위 지적 대상</strong>입니다.</p>",
      d_special_sunset_2026: "(특례: 청년창업기업 5천만원 이하, 소기업·소상공인·여성·장애인·사회적기업 등 1억원 이하 — 시행령 §25①5호 다목~바목, 부칙상 유효기간 없음)",
      # (아래 음성 대조 테스트가 '진짜 한시특례 종료' 서술도 함께 지킨다)
      d_1eok_list_missing_micro: "특례: 청년창업 5천만 · 소기업·소상공인·여성·장애인·사회적기업 등 1억",
      d_special_1eok_unqualified: "2천만원 (청년창업 5천만·소기업 등 1억)"
    }
    DETECTORS.each_key do |key|
      refute_match DETECTORS[key][:re], after_samples.fetch(key),
                   "탐지기 #{key} 가 정정문에 오검출한다"
    end
  end

  # §77 을 **공사 문맥에서 정당하게** 인용하는 문장은 잡히면 안 된다.
  test "음성 대조: 공사 문맥의 정당한 §77 인용은 잡지 않는다" do
    legit = [
      "**지방계약법 시행령 제77조 (공사의 분할계약 금지):**",
      "<strong>공사</strong> — 지방계약법 시행령 <strong>제77조제1항</strong>이 동일 구조물·단일공사로서",
      "지방계약법 시행령 제77조가 공사의 분할계약 금지를 규정합니다."
    ]
    legit.each do |s|
      assert_empty scan(s, DETECTORS[:d_77_unscoped_mapping]),
                   "공사 한정 인용을 결함으로 오검출한다: #{s[0, 40]}"
    end
  end

  test "음성 대조: 실제로 2026.6.30 종료된 보증금·절차 한시특례 서술은 결함이 아니다" do
    legit = [
      "한시적 특례 종료 (2026.6.30 만료)\n※ 행안부 고시 제2025-72호 (2026.1.1~6.30) — 2026.7.1 이후 공고분부터 원칙 기준",
      "행안부 고시 제2025-72호에 따른 지방계약 한시적 특례는 2026.6.30자로 종료되었습니다."
    ]
    legit.each do |s|
      assert_empty scan(s, DETECTORS[:d_special_sunset_2026]),
                   "실제 종료된 보증금·절차 한시특례(고시 제2025-72호) 서술을 결함으로 오검출한다"
    end
  end

  test "음성 대조: §77③ 로 한정된 '회피 목적 분할은 위법' 진술은 절대금지로 세지 않는다" do
    scoped = "✓ 입찰 또는 계약 방법을 회피할 목적으로 계약을 분할하면 위법입니다 (시행령 제77조)"
    %i[d_goods_split_absolute d_split_absolute_headline d_any_split_is_flagged].each do |key|
      assert_empty scan(scoped, DETECTORS[key]),
                   "조문 요건(회피 목적)으로 한정된 진술을 절대금지 단정으로 오검출한다 (#{key})"
    end
  end

  # §30(1인 견적)의 "특례기업 5천만원"은 정본이다. 이 문자열 자체를 결함으로 세면 안 된다.
  test "음성 대조: §30 견적 문맥의 '특례기업 5천만원'은 정본이므로 보존된다" do
    SLUG_SCOPED.each do |rel, spec|
      src = read_source(rel)
      spec[:right].each do |slug|
        block = slug_block(src, slug)
        assert block, "#{rel}: #{slug} 블록 부재"
        assert_match FIVE_THOUSAND, block,
                     "#{rel}[#{slug}]: §30①2호의 1인 견적 5천만원 특례가 사라졌다 — 과잉정정"
        assert_match SPECIAL_MENTION, block,
                     "#{rel}[#{slug}]: §30 특례 표기 자체가 사라졌다 — 과잉정정"
      end
    end
  end

  # ── 1. 현재 원천에서 0건 ────────────────────────────────
  test "A~C·E: 분할·특례 관련 잘못된 단정이 원천에 0건" do
    SOURCES.each do |rel|
      s = read_source(rel)
      DETECTORS.each do |key, d|
        found = scan(s, d)
        assert_empty found, "#{rel}: #{d[:desc]}\n  적발: #{found.first.inspect}"
      end
    end
  end

  test "D: §25(수의계약 한도) 문맥에서 특례를 5천만원으로 단정하지 않는다" do
    SLUG_SCOPED.each do |rel, spec|
      src = read_source(rel)
      spec[:wrong].each do |slug|
        block = slug_block(src, slug)
        assert block, "#{rel}: #{slug} 블록 부재"
        refute special_capped_at_5000?(block),
               "#{rel}[#{slug}]: §25 한도 문맥인데 특례 상한을 5천만원으로 단정한다 " \
               "(정본: 청년창업 5천만·다목 / 소기업·소상공인 등 1억·라목~바목)"
      end
    end
  end

  # ── 2. 정정된 정본 표현이 실제로 실려 있다 (양성) ────────
  test "정본 표현 양성: §77 공사 한정 · 예규 5.라 · §7제2호가 실려 있다" do
    verifier = read_source("app/services/regulation_verifier.rb")
    assert_includes verifier, "공사의 분할계약 금지: 시행령 제77조",
                    "§77 을 공사 한정으로 표기하지 않았다"
    assert_includes verifier, "제7조제2호",
                    "물품·용역 분할의 실제 근거(§7제2호 합산)가 조문 체크리스트에 없다"
    # 금액 체크리스트가 §25①5호 4계층을 모두 들고 있어야 한다. 하나라도 빠지면 이 검증기는
    # **맞는 콘텐츠를 틀렸다고 지적한다** (라목~바목이 통째로 빠져 있던 것이 이번 결함이다).
    {
      "나목" => "물품/용역 - 일반: 2천만원 이하",
      "다목" => "청년창업기업: 2천만원 초과 5천만원 이하",
      "라목" => "소기업·소상공인: 2천만원 초과 1억원 이하",
      "바목" => "여성·장애인·사회적기업·사회적협동조합·자활기업·마을기업: 2천만원 초과 1억원 이하"
    }.each do |ho, needle|
      assert_includes verifier, needle,
                      "regulation_verifier 금액 체크리스트에 §25①5호 #{ho} 계층이 없다"
    end
    # §25 와 §30 의 "특례"가 다른 금액·다른 대상임을 검증기가 알고 있어야 한다.
    assert_includes verifier, "제30조제1항제2호 가목",
                    "§30 의 5천만원 특례가 어느 목인지 밝히지 않으면 §25 특례와 합쳐 읽힌다"

    flow = read_source("app/views/guides/contract_flow.html.erb")
    assert_includes flow, "제7조제2호", "goods-3 안내가 §7제2호 합산 근거를 제시하지 않는다"

    subs = read_source("db/seeds/subtopics.rb")
    assert_includes subs, "부당한 분할계약 금지", "분할 경고 문구가 '부당한' 한정을 갖지 않는다"
    assert_includes subs, "소기업·소상공인", "§25①5호라목의 '소상공인'이 특례 열거에 없다"
  end

  # ── 3. 엔진 ↔ 콘텐츠 의미 충돌 0 (결론 semantics 비교) ──
  # 문자열 동일성이 아니라 **결론**을 비교한다.
  test "의미 정합: 물품 분할을 엔진은 절대금지로 판정하지 않는다" do
    r = ContractDecision::SplitProcurementEvaluator.call(
      contract_type: "goods",
      factors: { same_purpose: "yes", within_window: "yes" },
      current_amount: 5_000_000, prior_amounts: [ 5_000_000 ]
    )
    assert_equal "REVIEW_NEEDED", r.state,
                 "엔진이 물품 소액 분할을 REVIEW_NEEDED 로 내지 않는다 — 콘텐츠 정합 판정의 전제가 무너진다"
    refute_includes r.legal_basis.to_s, "제77조",
                    "엔진이 물품 트랙에 §77 을 인용한다"

    # 같은 사안에 대해 레거시 본문이 절대금지로 단정하면 충돌이다.
    SOURCES.each do |rel|
      s = read_source(rel)
      %i[d_goods_split_absolute d_split_absolute_headline d_any_split_is_flagged].each do |key|
        assert_empty scan(s, DETECTORS[key]),
                     "#{rel}: 엔진=REVIEW_NEEDED 인데 본문이 절대금지로 단정한다 (#{DETECTORS[key][:desc]})"
      end
    end
  end

  test "의미 정합: 엔진이 POSSIBLE 로 내는 특례 구간을 본문이 부정하지 않는다" do
    # 소기업 8천만원 물품 → §25①5호라목 (1억 이하) → 수의계약 가능
    small = ContractDecision::PrivateContractEvaluator.call(
      agency_scope: "LOCAL_GOVERNMENT", contract_type: "goods",
      estimated_price: 80_000_000, counterparty_type: "SMALL_ENTERPRISE"
    )
    assert_equal "POSSIBLE", small.state,
                 "엔진이 소기업 8천만원 물품을 수의계약 가능으로 내지 않는다"

    # 청년창업기업 8천만원 물품 → 다목 5천만 초과 → 수의계약 불가
    youth = ContractDecision::PrivateContractEvaluator.call(
      agency_scope: "LOCAL_GOVERNMENT", contract_type: "goods",
      estimated_price: 80_000_000, counterparty_type: "YOUTH_STARTUP"
    )
    assert_equal "COMPETITIVE_PROCEDURE_REQUIRED", youth.state,
                 "엔진이 청년창업 8천만원을 경쟁입찰 대상으로 내지 않는다 — 5천만/1억 구분이 무너졌다"

    # 두 결론이 갈리므로 본문도 두 계층을 갈라 적어야 한다.
    SLUG_SCOPED.each do |rel, spec|
      src = read_source(rel)
      spec[:wrong].each do |slug|
        block = slug_block(src, slug)
        assert_match(/1억/, block,
                     "#{rel}[#{slug}]: 엔진은 소기업 1억까지 POSSIBLE 인데 본문에 1억 계층이 없다")
      end
    end
  end
end
