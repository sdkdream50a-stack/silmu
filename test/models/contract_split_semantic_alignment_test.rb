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
    # D — «만료되면 3천만원으로 돌아간다»는 주장 자체. 위 탐지기는 "한시적 특례"라는 말이
    # 앞에 붙어 있어야 잡는데, 그 말만 지우면 같은 거짓 주장이 그대로 통과한다(뮤턴트 M13 생존).
    # §25①5호에 3천만원 기준은 **어느 목에도 없고** 부칙에 유효기간 조항도 없다.
    d_revert_to_30m: {
      re: /(?:3천만원|3,000만원)\s*(?:으?로)\s*(?:회귀|환원|복귀)|종전\s*3천만원/,
      before: "~2026.6.30 시행, 만료 후 종전 3천만원으로 회귀)",
      desc: "§25 특례 만료 시 3천만원 회귀 주장 — 조문·부칙에 근거 부존재"
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
      d_revert_to_30m: "행안부 고시 제2025-72호에 따른 보증금·절차 한시특례는 2026.6.30자로 종료되어 원칙 기준(입찰보증금 5% 이상 등)으로 환원됩니다.",
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

  # ── 2-bis. 독립검증 blocking 수리 (B1·B2·N1 · 2026-09-06) ──────
  #
  # 최종 독립검증(kimi)이 잡은 2건 + 같은 수정선의 오기 1건.
  # 공통 축은 «§25 를 하나의 숫자·하나의 호로 단정하지 않는다» 이다 —
  # §25①5호의 한도는 계약유형(가~바목)과 상대방 요건에 따라 갈린다.
  #
  # 양성 대조는 정정 전 커밋(132d463)의 blob 에서 읽는다. 다 고친 뒤 워킹트리에는
  # 결함 표본이 없으므로, 지금 남아 있는 것만으로 대조를 세우면 탐지기가 죽어도 0 이 나온다.
  REPAIR_BEFORE_COMMIT = "132d463"
  # F1·F5 는 그 다음 커밋(ada9b48)까지 남아 있었다
  REPAIR_BEFORE_COMMIT_F = "ada9b48"

  # «수의계약 한도 = 5천만원» 보편 단정. 사건 사실의 5천만원(계약금액·기관 내부통제)은 잡지 않는다.
  D_LIMIT_5000_UNIVERSAL = /수의계약\s*한도(?:액)?\s*\(\s*5천만원\s*\)|5천만원\(용역·물품\)/
  # §25①1호는 천재지변·긴급이다. 소액수의 체계는 제5호.
  D_ART25_HO1_AS_SMALL   = /제25조\s*제1항\s*제1호\s*\(소액 수의계약\)/
  # 1억원 특례의 근거를 제9호로 적은 오기. 정본은 제5호.
  D_ART25_HO9            = /제25조제1항\(제9호\s*등\)/

  AUDIT_CASE_SRC = "db/seeds/audit_cases/topic_audit_cases_batch_01.rb"
  LIMIT_FLOWCHART = "app/views/topics/flowcharts/_private_contract_limit.html.erb"

  def blob(commit, rel)
    out = `git -C #{Rails.root} show #{commit}:#{rel} 2>/dev/null`
    assert $?.success?, "blob 취득 실패: #{commit}:#{rel}"
    out
  end

  # 대상 레코드 구간만 잘라낸다 — 같은 오기가 **다른 레코드**에도 있으나 이번 수리 범위가 아니다.
  # (범위를 안 자르면 «0건» 단언이 범위 밖까지 요구하게 되고, 그건 이 수리가 한 일이 아니다)
  def split_over_limit_record(text)
    s = text.index("private-contract-split-over-limit")
    assert s, "대상 레코드를 찾지 못했다"
    e = text.index("AuditCase.find_or_create_by!", s) || text.length
    text[s...e]
  end

  test "양성 대조: 수리 전 커밋에서 B1·B2·N1 이 실제로 검출된다" do
    before_case = blob(REPAIR_BEFORE_COMMIT, AUDIT_CASE_SRC)
    before_view = blob(REPAIR_BEFORE_COMMIT, LIMIT_FLOWCHART)

    b1 = before_case.scan(D_LIMIT_5000_UNIVERSAL)
    assert_operator b1.size, :>=, 5,
                    "B1 탐지기가 수리 전 «한도 = 5천만원» 단정을 5건 미만으로 잡는다(#{b1.size}) — 탐지기가 좁다"
    assert_match D_ART25_HO1_AS_SMALL, split_over_limit_record(before_case),
                 "B2 탐지기가 수리 전 «§25①1호 (소액 수의계약)» 를 잡지 못한다"
    assert_match D_ART25_HO9, before_view,
                 "N1 탐지기가 수리 전 «제25조제1항(제9호 등)» 을 잡지 못한다"
  end

  test "B1: «수의계약 한도 = 5천만원» 보편 단정이 원천에 0건" do
    src = Rails.root.join(AUDIT_CASE_SRC).read
    found = src.scan(D_LIMIT_5000_UNIVERSAL)
    assert_empty found, "«한도 = 5천만원» 단정 잔존: #{found.inspect}"
  end

  test "B1: 다른 단일 금액으로 치환하지 않고 §25①5호 적용조건으로 되돌렸다" do
    rec = split_over_limit_record(Rails.root.join(AUDIT_CASE_SRC).read)
    assert_includes rec, "제25조제1항제5호",
                    "§25①5호 근거 표기가 없다"
    assert_includes rec, "계약유형(공사 / 물품·용역)과 상대방 요건",
                    "계약유형·상대방 요건에 따라 한도가 갈린다는 안내가 없다"
    # 하나의 숫자로 바꿔치기하지 않았는지 — 새 한도 단정이 생기면 실패한다
    refute_match(/수의계약\s*한도(?:액)?\s*\(\s*\d[\d,]*\s*(?:천만원|억원|만원)\s*\)/, rec,
                 "한도를 다시 하나의 숫자로 단정했다")
  end

  test "B1 음성 대조: 사건 사실·기관 내부통제의 5천만원은 보존된다" do
    rec = split_over_limit_record(Rails.root.join(AUDIT_CASE_SRC).read)
    [
      "총사업비 1억 5천만원",                       # 사건 사실
      "5,000만원",                                  # 계약 3호 금액
      "5천만원 이상 수의계약 전 교육지원청장 사전 승인 의무화"  # 기관 내부통제
    ].each { |s| assert_includes rec, s, "사건 사실/내부통제 표현이 지워졌다: #{s}" }
  end

  test "B2: 대상 레코드의 legal_basis 가 §25①5호이고 세부 목을 임의 지정하지 않는다" do
    rec = split_over_limit_record(Rails.root.join(AUDIT_CASE_SRC).read)
    refute_match D_ART25_HO1_AS_SMALL, rec, "§25①1호를 소액 수의계약으로 인용한다"
    assert_includes rec, "제25조 제1항 제5호 (소액 수의계약 — 세부 목은 계약유형·상대방 요건에 따라 확인)",
                    "제5호 정정 + 세부목 미확정 표기가 없다"
    # 사건 근거로 확정되지 않은 목을 legal_basis 에 지정하면 안 된다
    legal_basis = rec[/ac\.legal_basis = '[^']*'/].to_s
    refute_match(/제5호\s*[가-바]목/, legal_basis,
                 "사건 근거 없이 §25①5호의 세부 목을 임의 지정했다: #{legal_basis}")
  end

  test "N1: 1억원 특례 근거가 제5호로 정정됐다" do
    v = Rails.root.join(LIMIT_FLOWCHART).read
    refute_match D_ART25_HO9, v, "«제9호 등» 오기 잔존"
    assert_includes v, "제25조제1항제5호에 따른 상시 제도입니다", "제5호 정정문이 없다"
    # 같은 문장의 정당한 기준들이 함께 지워지지 않았는지
    assert_includes v, "일반 물품·용역 수의계약 한도는 2천만원, 청년창업기업은 5천만원",
                    "같은 문장의 정당한 금액 기준이 훼손됐다"
  end

  # ── 2-ter. 배포 blocker F1·F5 (독립검증 MUST_FIX · 2026-09-06) ──
  #
  # §25①1호 = 천재지변·감염병… 입찰에 부칠 여유가 없는 경우.  소액수의 체계 = §25①5호.
  # F1 은 이 오기가 **다른 published 감사사례**에 남아 있던 것이고, F5 는 한도 토픽 표제였다.
  # 대상 slug 하나만 검사하면 F1 이 또 빠져나간다 — **db/seeds 전역**으로 센다.
  #
  # 단 §25①1호를 «긴급계약» 문맥으로 정확히 쓴 곳은 정본이므로 잡으면 안 된다(음성 대조).
  D_HO1_AS_SMALL_AMOUNT = /제25조\s*제1항\s*제1호[^\n]{0,40}\(\s*소액\s*수의계약/
  D_HO1_AS_LIMIT        = /제25조\s*제1항\s*제1호[^\n]{0,40}\(\s*수의계약\s*한도/
  D_HO1_EMERGENCY       = /제25조\s*제1항\s*제1호[^\n]{0,60}(?:천재지변|긴급|재난)/

  # 정정 시드는 «치환표» 다 — old 문자열로 정정 전 문구를 **반드시** 들고 있어야 한다.
  # 그걸 결함으로 세면 고칠수록 숫자가 나빠진다(이 프로젝트에서 실제로 겪었다).
  # 사용자에게 나가는 콘텐츠가 아니므로 이름을 명시해 제외하되,
  # **제외가 실제로 필요한 파일만** 목록에 둔다 — 안 걸리는 파일을 넣어두면 목록이 은신처가 된다.
  CORRECTIVE_SEEDS = %w[
    db/seeds/topic_deploy_blocker_fix_2026_09_06.rb
  ].freeze

  def all_seed_files
    Dir[Rails.root.join("db/seeds/**/*.rb")]
  end

  def seed_files
    all_seed_files.reject do |f|
      CORRECTIVE_SEEDS.include?(Pathname.new(f).relative_path_from(Rails.root).to_s)
    end
  end

  test "제외 목록은 «제외가 실제로 필요한» 정정 시드만이고 조용히 늘지 않는다" do
    assert_equal 1, CORRECTIVE_SEEDS.size, "정정 시드 제외 목록이 바뀌었다 — 판정 없이 늘리지 않는다"
    CORRECTIVE_SEEDS.each do |rel|
      path = Rails.root.join(rel)
      assert path.exist?, "제외 목록에 없는 파일이 있다: #{rel}"
      src = path.read
      # 제외 근거 = 이 파일이 실제로 탐지기에 걸린다는 것. 안 걸리면 제외할 이유가 없다.
      assert src.match?(D_HO1_AS_SMALL_AMOUNT) || src.match?(D_HO1_AS_LIMIT),
             "#{rel} 은 탐지기에 걸리지 않는다 — 제외 목록에 있을 이유가 없다"
      # 그리고 «치환표» 여야 한다: 정정 후 문자열도 함께 들고 있어야 한다.
      assert_includes src, "제25조 제1항 제5호", "#{rel} 이 치환표가 아니다(정정 후 문자열 없음)"
    end
  end

  test "양성 대조: 수리 전 커밋에서 F1·F5 오기가 실제로 검출된다" do
    f1 = blob(REPAIR_BEFORE_COMMIT_F, "db/seeds/audit_cases/topic_audit_cases_batch_01.rb")
    f5 = blob(REPAIR_BEFORE_COMMIT_F, "db/seeds/subtopics.rb")
    assert_match D_HO1_AS_SMALL_AMOUNT, f1,
                 "F1 탐지기가 수리 전 «§25①1호 (소액 수의계약)» 를 잡지 못한다"
    assert_match D_HO1_AS_LIMIT, f5,
                 "F5 탐지기가 수리 전 «§25①1호 (수의계약 한도)» 를 잡지 못한다"
  end

  test "F1: db/seeds 전역에서 «§25①1호 = 소액 수의계약» 결합이 0건" do
    offenders = seed_files.filter_map do |f|
      src = File.read(f)
      next unless src.match?(D_HO1_AS_SMALL_AMOUNT)
      "#{Pathname.new(f).relative_path_from(Rails.root)}"
    end
    assert_empty offenders, "§25①1호를 소액 수의계약으로 인용하는 시드가 남아 있다: #{offenders.inspect}"
  end

  test "F5: db/seeds 전역에서 «§25①1호 = 수의계약 한도» 결합이 0건" do
    offenders = seed_files.filter_map do |f|
      src = File.read(f)
      next unless src.match?(D_HO1_AS_LIMIT)
      "#{Pathname.new(f).relative_path_from(Rails.root)}"
    end
    assert_empty offenders, "§25①1호를 수의계약 한도로 인용하는 시드가 남아 있다: #{offenders.inspect}"
  end

  test "음성 대조: §25①1호를 긴급계약으로 정확히 쓴 곳은 보존된다" do
    # 실측(2026-09-06): 4곳. 하나라도 사라지면 과잉정정이다.
    kept = seed_files.count { |f| File.read(f).match?(D_HO1_EMERGENCY) }
    assert_operator kept, :>=, 4,
                    "§25①1호의 정당한 긴급계약 인용이 줄었다(#{kept}건) — 과잉정정"
    # 그리고 그 문맥이 F1/F5 탐지기에 걸리면 안 된다
    [
      "| **긴급 수의** | 시행령 제25조 제1항 제1호 | 천재지변, 긴급 행사 등 경쟁 여유 없음 |",
      "시행령 제25조 제1항 제1호·제2호 (천재지변·재난 긴급복구)",
      "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령 제25조제1항제1호(긴급입찰)"
    ].each do |s|
      refute_match D_HO1_AS_SMALL_AMOUNT, s, "정당한 긴급계약 인용을 F1 결함으로 오검출한다: #{s[0, 40]}"
      refute_match D_HO1_AS_LIMIT, s, "정당한 긴급계약 인용을 F5 결함으로 오검출한다: #{s[0, 40]}"
    end
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
