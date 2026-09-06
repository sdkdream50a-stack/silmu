# frozen_string_literal: true

require "test_helper"

#
# 원천 품질 회귀 — 계약서 작성(§14/§49/§50) · 입찰공고 시기(§35)
# CPSC-P3D-001 · CPEB-P3C-001 (2026-09-06)
#
# 정본 재대조(law.go.kr 2026-09-06):
#   지방계약법 [시행 2024. 2. 17.] [법률 제19634호]
#     §14① 목적·계약금액·이행기간·계약보증금·위험부담·지연배상금(遲延賠償金) + 단서(작성 생략 위임)
#     §14② 전자문서에 의한 계약서 작성 의무(천재지변 등 예외)
#   지방계약법 시행령 [시행 2026. 6. 3.] [대통령령 제36338호]
#     §49 계약서 서식을 행정안전부령에 위임          §50① 생략 5개 호(금액 기준 5천만원 단일)
#     §35③ 10억미만 7 / 10~50억 15 / 50억~고시금액 30 / 고시금액 이상 40
#     §35⑤ 1억 미만 10 / 1억~10억 20 / 10억 이상 40
#
# 이 테스트는 DB 시드 여부에 의존하지 않도록 **시드 원천 파일 텍스트**를 직접 검사한다.
# 각 탐지기는 "옛 문구(BEFORE)"에 대해 반드시 양성으로 먼저 증명한 뒤 현재 원천에서 0을 단언한다.
# (양성 대조 없는 "0건"은 탐지기가 죽었을 때와 구별되지 않는다.)
#
class ContractBidSourceAccuracyTest < ActiveSupport::TestCase
  # ── 탐지기 정의 ───────────────────────────────────────────
  DETECTORS = {
    # CPSC — 계약서 작성
    d_49_items: {
      re: /###\s*제49조\s*\(계약서의 작성\)\s*\n+\s*계약서에 기재해야 할 사항/,
      before: "### 제49조 (계약서의 작성)\n\n계약서에 기재해야 할 사항:\n1. 계약의 **목적**",
      desc: "시행령 §49를 기재사항 조문으로 오귀속 (정본: 서식 위임)"
    },
    # 넓은 형태 — "**1억원 이하**(공사)" / "공사는 1억원 이하" / "(공사 1억원 이하)" 를 모두 잡는다.
    # (좁은 정규식은 같은 파일 안 다른 표기를 놓쳤다 — 2026-09-06 실제 발생)
    #
    # 단, 넓히면 음성도 다시 재야 한다. "공사 추정가격 1억원 이하 계약보증금 면제"는
    # 시행령 §53(보증금 면제) 사안이지 §50(계약서 생략)이 아니다 → context 로 갈라낸다.
    d_50_construction_1eok: {
      re: /(?:공사[^\n]{0,12}1억원?\s*이하|1억원?\s*이하[^\n]{0,6}\(?\s*공사)/,
      context_require: /계약서|생략|제50조|§50/,
      context_exclude: /면제/,
      before: "- 계약금액 **5천만원 이하** (물품·용역)\n- 계약금액 **1억원 이하** (공사)",
      desc: "시행령 §50①에 부존재하는 '공사 1억원' 기준"
    },
    d_14_2_as_omission: {
      re: /②\s*다만,\s*대통령령으로 정하는 경우에는 계약서 작성을\s*\*\*생략\*\*할 수 있다/,
      before: "② 다만, 대통령령으로 정하는 경우에는 계약서 작성을 **생략**할 수 있다.",
      desc: "법 §14②를 '작성 생략' 조항으로 오기재 (정본: 전자문서 작성 의무)"
    },
    d_meta_49_items: {
      re: /§49\(기재[:：]/,
      before: "시행령 §49(기재: 목적·금액·이행기간·보증금·지체상금)·§50(생략: 물품/용역 5천만·공사 1억 이하)",
      desc: "verification_source 가 §49를 기재사항 조문으로 서술"
    },
    d_meta_50_construction: {
      re: /§50\(생략[^)]*공사\s*1억/,
      before: "§50(생략: 물품/용역 5천만·공사 1억 이하)",
      desc: "verification_source 의 '공사 1억' 기준"
    },
    # CPEB — 입찰공고 시기
    # "50억 이상"과 "40일" 사이에 표 구분자·jsonb 라벨·괄호가 끼는 실제 표기가 있다
    # (예: `"label" => "공고기간(50억 이상)", "value" => "40일 이상"`, `50억 이상(40일)`).
    # 좁은 정규식은 이 둘을 통과시켰다 — 뮤테이션 M15·M17 생존으로 드러남.
    d_50eok_collapsed: {
      re: /50억\s*(?:원\s*)?이상[^\n]{0,45}?40일/,
      before: "10억 미만 7일·10~50억 15일·50억 이상 40일 이상 게시해야 하며",
      desc: "§35③의 30일 구간(50억~고시금액) 누락 — 50억 이상을 40일로 단일화"
    },
    d_1eok_inverted: {
      re: /추정가격\s*1억\s*이상\s*시?\s*10일/,
      before: "일반 7일 이상, 추정가격 1억 이상 시 10일 이상, 긴급 시 5일 이상.",
      desc: "§35⑤ 역전 — 정본은 1억 '미만'이 10일"
    }
  }.freeze

  # 이번 정정의 사정거리(scope). 이 밖의 잔존은 별도 판단 대상으로 남긴다.
  CPSC_SOURCES = %w[
    db/seeds/topic_contract_execution.rb
    db/seeds/zz_topic_verification_2026_06_09_batch2.rb
    db/seeds/topic_fold_summary_2026_06_05_batch2.rb
    app/services/contract_document_service.rb
    app/views/guides/contract_flow.html.erb
    db/seeds/subtopics.rb
  ].freeze

  CPEB_SOURCES = %w[
    db/seeds/topic_fold_summary_2026_06_05_batch2.rb
    db/seeds/howto_steps.rb
    db/seeds/topic_howto_backfill_2026_06_15_batch2.rb
    db/seeds/quick_stats_sprint3.rb
    app/services/regulation_verifier.rb
  ].freeze

  def read_source(rel)
    path = Rails.root.join(rel)
    assert path.exist?, "원천 파일 부재: #{rel}"
    path.read
  end

  # 탐지기를 문맥 창(±90자)과 함께 적용한다. context_require/exclude 가 있으면
  # 그 창에 대해 판정하므로, 같은 수치가 다른 조문(예: §53 보증금 면제)에서 쓰인 경우를
  # 결함으로 잘못 세지 않는다. 반환값 = 적발된 창 목록.
  def scan(text, detector)
    hits = []
    text.to_s.scan(detector[:re]) { hits << Regexp.last_match }
    hits.select do |m|
      window = text[[ m.begin(0) - 90, 0 ].max...(m.end(0) + 90)].to_s
      ok = true
      ok &&= window.match?(detector[:context_require]) if detector[:context_require]
      ok &&= !window.match?(detector[:context_exclude]) if detector[:context_exclude]
      ok
    end.map { |m| text[[ m.begin(0) - 50, 0 ].max...(m.end(0) + 50)].to_s }
  end

  def assert_no_hits(text, key, label)
    found = scan(text, DETECTORS.fetch(key))
    assert_empty found, "#{label}: #{DETECTORS[key][:desc]}\n  적발: #{found.first.inspect}"
  end

  # ── 0. 양성 대조 — 탐지기가 실제로 옛 문구를 잡는지 먼저 증명 ──
  test "양성 대조: 7개 탐지기 전부가 BEFORE 문구에서 검출된다" do
    DETECTORS.each do |key, d|
      assert_match d[:re], d[:before],
                   "탐지기 #{key} 가 BEFORE 문구를 잡지 못한다 — 탐지기가 죽었다 (#{d[:desc]})"
    end
  end

  # 넓힌 탐지기는 실제로 발견됐던 4가지 표기를 모두 잡아야 한다.
  # (처음 쓴 좁은 정규식은 이 중 첫 번째만 잡았고, 같은 파일 안 나머지를 통과시켰다.)
  # 표본은 정정 전 원문 그대로다 — 문맥을 떼어내면 문맥 조건이 헛돈다.
  test "양성 대조: '공사 1억' 탐지기가 실제 발견된 3개 표기를 모두 잡는다" do
    [
      "### 제50조 (계약서 작성 생략)\n\n다음 경우 계약서 작성 생략 가능:\n- 계약금액 **5천만원 이하** (물품·용역)\n- 계약금액 **1억원 이하** (공사)",
      "**A:** 계약금액 **5천만원 이하**(물품·용역) 또는 **1억원 이하**(공사), 전기·가스·수도 공급계약, 경매 계약 시 생략 가능합니다(시행령 제50조).",
      "물품·용역은 계약금액 5천만원 이하, 공사는 1억원 이하일 때 생략 가능합니다",
      "계약금액 **5천만원 이하**(공사 1억원 이하)인 경우 계약서 작성을 생략할 수 있습니다"
    ].each_with_index do |sample, i|
      assert_not_empty scan(sample, DETECTORS[:d_50_construction_1eok]),
                       "표기 ##{i} 를 놓친다 — 탐지 범위가 좁다: #{sample[0, 40]}"
    end
  end

  # 그리고 넓힌 탐지기가 §53(계약보증금 면제)을 결함으로 오검출하지 않아야 한다.
  # 같은 "공사 1억원 이하" 문자열이지만 다른 조문이다.
  test "음성 대조: '공사 1억' 탐지기는 §53 계약보증금 면제 문맥을 잡지 않는다" do
    guarantee_exemption = "(외)계약보증금·계약이행보증서, (내)면제 사유 검토·결정[공사 추정가격 1억원 이하 면제 가능]"
    assert_empty scan(guarantee_exemption, DETECTORS[:d_50_construction_1eok]),
                 "계약보증금 면제(§53) 문맥을 계약서 생략(§50) 결함으로 오검출한다"
  end

  test "음성 대조: 각 탐지기는 정정된 AFTER 문구에서 검출되지 않는다" do
    after_samples = {
      d_49_items: "### 제49조 (계약서의 작성)\n\n법 제14조제1항에 따라 계약담당자가 작성하는 **계약서의 서식과 그 밖에 필요한 사항은 행정안전부령**으로 정한다.",
      d_50_construction_1eok: "1. 계약금액이 **5천만원 이하**인 계약을 체결하는 경우",
      d_14_2_as_omission: "② 지방자치단체의 장 또는 계약담당자는 계약을 체결하려는 경우에는 **천재지변 등 대통령령으로 정하는 경우를 제외하고는** 전자문서에 의한 계약서를 작성하여야 한다.",
      d_meta_49_items: "시행령 §49(서식 위임)·§50①(생략: 5천만원 이하 등 5개 호)",
      d_meta_50_construction: "§50①(생략: 5천만원 이하 등 5개 호)",
      d_50eok_collapsed: "10억 미만 7일·10~50억 15일·50억~고시금액 30일·고시금액 이상 40일",
      d_1eok_inverted: "규격·기술입찰과 협상에 의한 계약은 1억 미만 10일·1억~10억 20일·10억 이상 40일(§35⑤)"
    }
    DETECTORS.each_key do |key|
      sample = after_samples.fetch(key)
      refute_match DETECTORS[key][:re], sample, "탐지기 #{key} 가 정정문에 오검출한다"
    end
  end

  # ── 1. CPSC — 현재 원천에서 0건 ──────────────────────────
  test "CPSC-P3D-001: 계약서 작성 원천에 §49 기재사항 오귀속 · §14② 오기재 · '공사 1억' 잔존 0건" do
    CPSC_SOURCES.each do |rel|
      s = read_source(rel)
      %i[d_49_items d_50_construction_1eok d_14_2_as_omission d_meta_49_items d_meta_50_construction].each do |key|
        assert_no_hits(s, key, rel)
      end
    end
  end

  test "CPSC-P3D-001: 정정된 정본 표현이 실제로 실려 있다(양성)" do
    exec_src = read_source("db/seeds/topic_contract_execution.rb")
    assert_includes exec_src, "전자문서에 의한 계약서",
                    "법 §14②(전자문서 작성 의무)가 law_content 에 없다"
    assert_includes exec_src, "계약서의 서식과 그 밖에 필요한 사항은 행정안전부령",
                    "시행령 §49(서식 위임) 원문이 decree_content 에 없다"
    # 열거 자체를 단언한다 — 다른 곳에 같은 낱말이 남아 있으면 "포함" 검사는 삭제를 못 본다
    # (뮤테이션 M20: decree 의 3호를 지워도 qa_content 의 같은 표현 때문에 통과했다).
    decree_50 = exec_src[/### 제50조 \(계약서 작성의 생략 등\).*?※/m].to_s
    assert_not_equal "", decree_50, "시행령 §50 블록을 찾지 못했다"
    {
      "1." => "5천만원 이하",
      "2." => "경매",
      "3." => "매수인이 즉시 대금을 내고",
      "4." => "국가기관",
      "5." => "공급계약"
    }.each do |no, needle|
      assert_includes decree_50, "#{no} ", "시행령 §50① 제#{no.chomp('.')}호 항목번호가 없다"
      assert_includes decree_50, needle, "시행령 §50① 제#{no.chomp('.')}호(#{needle})가 누락됐다"
    end
    assert_includes exec_src, "위험부담",
                    "법 §14① 기재사항 '위험부담'이 없다"

    meta_src = read_source("db/seeds/zz_topic_verification_2026_06_09_batch2.rb")
    assert_includes meta_src, "§49(서식 위임)", "verification_source 가 §49를 서식 위임으로 고치지 않았다"
  end

  test "CPSC: 지방계약법 정본 용어는 '지연배상금'이며 '지체상금'으로 되돌아가지 않았다" do
    exec_src = read_source("db/seeds/topic_contract_execution.rb")
    meta_src = read_source("db/seeds/zz_topic_verification_2026_06_09_batch2.rb")
    fold_src = read_source("db/seeds/topic_fold_summary_2026_06_05_batch2.rb")

    # 법 §14①·시행령 §50 을 다루는 이 원천들에서 '지체상금'은 국가계약법 용어이므로 나타나면 안 된다.
    refute_includes exec_src, "지체상금",
                    "지방계약법 토픽 본문에 국가계약법 용어 '지체상금' 잔존"
    refute_match(/§49\(기재[^)]*지체상금/, meta_src,
                 "verification_source 에 '지체상금' 잔존")

    # 그리고 원래 옳았던 표현은 보존돼야 한다(과잉정정 방지).
    assert_includes exec_src, "지연배상금", "정본 용어 '지연배상금'이 사라졌다"
    assert_includes fold_src, "지연배상금", "요약문의 정본 용어 '지연배상금'이 사라졌다"
    assert_includes fold_src, "전자문서로 작성하는 것이 원칙",
                    "법 §14② 근거가 실재하는데 '전자문서 원칙' 표현이 삭제됐다"
    # CPSC 가 지목한 유일한 실재 결함 = 요약문의 '위험부담' 누락. 요약문 자체에서 단언한다.
    assert_includes fold_src, "계약보증금·위험부담·지연배상금",
                    "요약문의 §14① 기재사항에서 '위험부담'이 다시 빠졌다"
  end

  # ── 2. CPEB — 현재 원천에서 0건 ──────────────────────────
  test "CPEB-P3C-001: 입찰공고 시기 원천에 '50억 이상 40일' · '1억 이상 10일' 잔존 0건" do
    CPEB_SOURCES.each do |rel|
      s = read_source(rel)
      assert_no_hits(s, :d_50eok_collapsed, rel)
      assert_no_hits(s, :d_1eok_inverted, rel)
    end
  end

  test "CPEB-P3C-001: §35③ 4단계와 §35⑤ 3단계가 실제로 실려 있다(양성)" do
    fold = read_source("db/seeds/topic_fold_summary_2026_06_05_batch2.rb")
    howto = read_source("db/seeds/howto_steps.rb")

    assert_includes fold, "50억~고시금액 30일", "§35③ 30일 구간이 요약에 없다"
    assert_includes fold, "고시금액 이상 40일", "§35③ 40일 구간이 요약에 없다"

    assert_includes howto, "1억 미만 10일", "§35⑤ 1호(1억 미만 10일)가 how-to 에 없다"
    assert_includes howto, "1억~10억 20일", "§35⑤ 2호가 how-to 에 없다"
    assert_includes howto, "10억 이상 40일", "§35⑤ 3호가 how-to 에 없다"
  end

  # ── 3. 충돌 판정 — 표(§35③)와 how-to(§35⑤)는 적용범위가 다르다 ──
  # CPEB 는 "표 vs how-to 모순"으로 보고됐으나 정본상 서로 다른 공고유형이다.
  # 모순이 아니라는 판정은 "두 진술이 각자의 적용범위를 명시하는가"로 검사한다.
  test "CPEB 판정: 두 진술 모두 공고유형 한정을 명시한다(BOTH_CONTEXTUAL)" do
    fold = read_source("db/seeds/topic_fold_summary_2026_06_05_batch2.rb")
    howto = read_source("db/seeds/howto_steps.rb")

    assert_includes fold, "공사입찰(현장설명 미실시)",
                    "표 계열 진술이 §35③ 적용범위를 명시하지 않는다 — 범위 없는 수치는 모순으로 읽힌다"
    assert_includes howto, "규격·기술입찰과 협상에 의한 계약",
                    "how-to 진술이 §35⑤ 적용범위를 명시하지 않는다"
    assert_includes howto, "공사입찰 현장설명 미실시",
                    "how-to 가 §35③ 경로를 함께 제시하지 않는다"
  end

  # ── 4. 회귀 경계 — 정정이 다른 조문 주장을 만들지 않았는지 ──
  test "정정이 국가계약법 §74(지체상금) 대비 서술을 훼손하지 않았다" do
    # 지방=시행령 §90(지연배상금) / 국가=시행령 §74(지체상금) 대비는 별도 자산이며 유지돼야 한다.
    verifier = read_source("app/services/regulation_verifier.rb")
    assert_includes verifier, "제90조", "지방 지연배상금 조문(§90) 서술이 사라졌다"
  end
end
