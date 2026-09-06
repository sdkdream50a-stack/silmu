# frozen_string_literal: true

require "test_helper"

#
# §25① «호 ↔ 사유» 전역 정합 (2026-09-06)
#
# 앞 라운드 탐지기(article25_semantic_residual_test)는 **제1호 한 축만** 봤다.
# 그래서 「국가기관을 제2호로」·「특정인의 기술을 제3호로」 처럼 호가 통째로 밀린 오류는
# 한 건도 걸리지 않았다 — 실제로 공개 양식이 제2호부터 한 칸씩 밀린 채 서빙되고 있었다.
#
# 이 탐지기는 호 1~5 를 **전부** 본다. 인용에서 호 번호를 뽑고,
#   OWN   자기 호의 의미 신호가 넉넉한 창(±240)에 하나도 없고
#   OTHER 다른 호의 의미 신호가 좁은 창(±90, 인접 인용의 중점에서 절단)에 있으면
# → 조문 ↔ 사유 mismatch 로 센다.
#
# 창을 비대칭으로 둔 이유는 실측이다. 대칭으로 두면
#   · 좁게: `topics.rb:1194`(정당한 긴급 사유서 예시)가 거짓양성 — 자기 근거가 180자 밖에 있었다
#   · 넓게: `_private_contract_justification.html.erb:29`(정답 4쌍 배열)이 거짓양성 — 옆 쌍의 라벨을 물었다
# 「없음」을 재는 축은 관대하게, 「충돌이 옆에 있음」을 재는 축은 좁게.
#
# 정본 (지방계약법 시행령 · config/contract_decision_rules.yml `non_amount_grounds` verified_at 2026-09-06
#       · db/seeds/topic_content_fix_2026_06_04_batch18.rb 호별 표):
#   제1호 천재지변·감염병·작전상 병력이동·긴급행사·원자재 가격급등 등 입찰에 부칠 여유가 없는 경우
#   제2호 입찰에 부칠 여유가 없는 긴급복구가 필요한 재난 등
#   제3호 국가기관·다른 지방자치단체(조합 포함)와 계약
#   제4호 특정인의 기술·용역 또는 특정한 위치·구조·품질·성능·효율 등으로 경쟁 불가
#   제5호 금액 체계(가~사목)
#   ※ 재공고입찰 불성립·낙찰자 없음은 §25① 이 아니라 **영 제26조** 다.
#
class Article25HoSemanticAlignmentTest < ActiveSupport::TestCase
  BEFORE_COMMIT = "5a70437" # 이번 공개표기 수리 직전 HEAD

  CITE = /
    (?:(?<![0-9])§\s*25\s*①\s*(?<a>\d+)\s*호)
    |
    (?:제?\s*(?<![0-9])25\s*조\s*제?\s*1\s*항\s*제?\s*(?<b>\d+)\s*호)
  /x

  SIG = {
    # 「입찰에 부칠 여유가 없는」 은 제1호와 제2호가 **함께** 쓰는 말이라 호를 구별하지 못한다.
    # 신호는 «있는 말» 이 아니라 «가르는 말» 이어야 한다.
    1 => /천재지변|천재·지변|감염병|전염병|긴급한?\s*행사|원자재[^\n]{0,6}가격\s*급등|작전상/,
    2 => /긴급\s*복구|긴급복구|재난|재해/,
    3 => /국가기관|다른\s*지방자치단체|지방자치단체조합/,
    4 => /특정인의\s*기술|특허|저작권|유일|독점|특정한?\s*위치|경쟁[^\n]{0,10}(?:불가|할\s*수\s*없|곤란)/,
    5 => /소액\s*수의|수의계약\s*한도|한도액|기준금액|한도\s*이하|금액\s*기준\s*이하|추정가격[^\n]{0,30}이하|2천만|5천만|1억|4억|1억6천만/
  }.freeze

  W_OWN = 240   # 자기 근거가 «없다» 고 말하려면 넉넉히 보고 말한다
  W_OTHER = 90  # 충돌 신호는 «바로 옆» 일 때만 센다

  # 목록 항목의 경계. 뒤로 볼 때 여기서 끊지 않으면 «앞 항목의 설명» 을 자기 근거로 착각한다.
  # 실측(5a70437): 한 칸씩 밀린 체크박스는 자기 근거가 87~95자 뒤(= 항목 경계 너머)에 있었고,
  # 한 문장 안에서 정당하게 앞서 나온 근거는 40~51자였다. 숫자로 가르지 않고 경계로 가른다.
  ITEM_BOUNDARY = /\n|\\n/

  # 정정 시드는 치환표라서 정정 «전» 문자열을 반드시 들고 있다. 고칠수록 숫자가 나빠지는 자리다.
  EXCLUDED = %w[
    db/seeds/topic_deploy_blocker_fix_2026_09_06.rb
  ].freeze

  # 이번 라운드 scope 밖으로 **판정한** 잔존. `경로:줄` 로 못박는다 —
  # 파일 이름으로만 잠그면 이미 알려진 결함 하나가 같은 파일의 새 결함을 숨겨 준다.
  ADJUDICATED_OUT_OF_SCOPE = {
    "app/views/contract_reasons/index.html.erb:447" =>
      "R-A 실재 오류 — 긴급 사유를 §25①2호로. `lawText` 는 §25①1호 **원문**(천재·지변·작전상 병력이동·" \
      "긴급한 행사·원자재 가격급등)이다. 같은 오기가 예시문 3건(:450 :451 :452)에도 복제돼 있다. " \
      "이 화면은 사유서를 **생성해 주는** 자리라 공개 양식보다 파급이 크다. 사용자가 이번 scope 를 A/B/C 로 " \
      "동결했으므로 고치지 않았다 — 다음 라운드 1순위",
    "app/views/guides/resources.html.erb:476" =>
      "R-H 다른 class — 유찰(2회) 수의를 §25①2호로. 정본은 **영 제26조**(재공고입찰 불성립). " \
      "같은 오기가 `app/controllers/faq_controller.rb:58` 과 **R2 core** `app/services/contract_method_service.rb:296` " \
      "에도 있다. 한 곳만 고치면 세 곳이 서로 다른 말을 하고, 셋을 함께 고치면 R2_CORE_MODIFIED=0 이 깨진다. " \
      "이 탐지기의 호↔사유 mapping(1~5호) 밖이기도 하다 → 별도 라운드",
    "db/seeds/audit_cases.rb:83" =>
      "R-B 실재 오류 — 「제2호가 정한 긴급수의 사유는 천재지변, 작전상 병력이동…」. 실제 제1호. scope 밖",
    "db/seeds/subtopics.rb:1115" =>
      "R-C 실재 오류 — 태풍 피해 복구 긴급수의를 제4호로. 실제 제1호(천재지변) 또는 제2호(긴급복구 재난) 축이고 " \
      "제4호는 어느 쪽도 아니다. 이번에 고친 :982 와 **같은 파일 같은 class** 지만 사용자가 지목한 줄이 아니다. scope 밖",
    "db/seeds/suui_contract_series.rb:98" =>
      "R-D 실재 오류 — 「제2호: 경쟁에 부치기 어려운 경우(특허·저작권·천재지변 등)」. 1호와 4호를 2호로 섞었다. scope 밖",
    "db/seeds/topics.rb:152" =>
      "R-E 실재 오류 — 금액 기준 소액수의를 제4호로. 실제 제5호. scope 밖",
    "db/seeds/topics.rb:1194" =>
      "R-I CONTEXT_AMBIGUOUS — 사유서 예시가 「폭우로 인한 시설 파손 → 긴급 복구 → 입찰 여유 없음」 을 제1호로 인용한다. " \
      "폭우=천재지변 이면 제1호, 「긴급복구가 필요한 재난」 이면 제2호다. 조문 어느 쪽으로도 읽히므로 " \
      "임의로 호를 지정하지 않는다 — 사람 판정 대상",
    "db/seeds/zz_guide_verification_2026_06_09_batch8.rb:11" =>
      "R-F 실재 오류 — verification_source 가 §25①4호(긴급 수의)로 «검증 근거» 를 가르친다. 실제 제1호. scope 밖",
    "db/seeds/zz_topic_verification_2026_06_09.rb:18" =>
      "R-G 실재 오류 — 위와 같은 verification_source 오기. scope 밖"
  }.freeze

  # 이번 라운드가 실제로 수리한 «자리». AFTER 는 여기서 0 이어야 한다.
  # 파일 전체가 아니라 줄 범위로 잠근다 — subtopics.rb 는 :982 만 scope 였고
  # :1115 는 같은 파일 같은 class 지만 사용자가 동결한 범위 밖이다(아래 R-C).
  REPAIRED = {
    "public/forms/수의계약사유서.html" => (1..413),
    "db/seeds/subtopics.rb" => (975..990),
    "app/views/guides/resources.html.erb" => (470..480)
  }.freeze

  # ── 탐지기 본체 ──────────────────────────────────────────────
  # 조·항을 머리말에 한 번만 적고 호를 «맨몸» 으로 나열하는 표기.
  # 공개 양식이 정확히 이 모양이라 조·항 인접만 보는 탐지기는 체크박스를 통째로 못 봤다.
  ANCHOR = /제?\s*(?<![0-9])25\s*조\s*제?\s*1\s*항(?!\s*제?\s*\d+\s*호)/
  BARE_HO = /제\s*(\d+)\s*호/
  ANCHOR_SPAN = 800 # 머리말이 지배하는 범위. 다음 «제N조» 가 나오면 거기서 끊는다
  NEXT_ARTICLE = /제\s*\d+\s*조/

  def cites(src)
    direct = src.to_enum(:scan, CITE).map do
      m = Regexp.last_match
      { b: m.begin(0), e: m.end(0), ho: (m[:a] || m[:b]).to_i }
    end
    (direct + anchored_cites(src, direct)).sort_by { |c| c[:b] }
  end

  def anchored_cites(src, direct)
    taken = direct.map { |c| (c[:b]...c[:e]) }
    src.to_enum(:scan, ANCHOR).flat_map do
      a = Regexp.last_match
      tail = src[a.end(0), ANCHOR_SPAN].to_s
      stop = tail.index(NEXT_ARTICLE) || tail.length
      region = tail[0...stop]
      region.to_enum(:scan, BARE_HO).map do
        m = Regexp.last_match
        { b: a.end(0) + m.begin(0), e: a.end(0) + m.end(0), ho: m[1].to_i }
      end
    end.reject { |c| taken.any? { |r| r.cover?(c[:b]) } }
  end

  # 인접 인용의 «중점» 에서 자른다 — 각 인용은 자기에게 더 가까운 텍스트만 소유한다.
  def bounded(src, cs, i, w)
    c = cs[i]
    lo = [ c[:b] - w, 0 ].max
    lo = [ lo, (cs[i - 1][:e] + c[:b]) / 2 ].max if i.positive?
    hi = c[:e] + w
    hi = [ hi, (c[:e] + cs[i + 1][:b]) / 2 ].min if cs[i + 1]
    src[lo...hi].to_s
  end

  # 자기 근거를 찾는 창: 뒤로는 «항목 경계» 까지만, 앞으로는 다음 인용까지 넉넉히.
  # 목록에서 각 항목의 설명은 자기 번호 «뒤» 에 온다 — 앞을 넓게 보면 옆 항목을 훔친다.
  def own_window(src, cs, i)
    c = cs[i]
    lo = [ c[:b] - W_OWN, 0 ].max
    head = src[lo...c[:b]].to_s
    if (m = head.enum_for(:scan, ITEM_BOUNDARY).map { Regexp.last_match.end(0) }.last)
      lo += m
    end
    hi = c[:e] + W_OWN
    hi = [ hi, cs[i + 1][:b] ].min if cs[i + 1]
    src[lo...hi].to_s
  end

  def mismatches(src)
    cs = cites(src)
    cs.each_with_index.filter_map do |c, i|
      next unless (1..5).cover?(c[:ho])
      next if own_window(src, cs, i).match?(SIG[c[:ho]])

      others = SIG.keys.select { |k| k != c[:ho] && bounded(src, cs, i, W_OTHER).match?(SIG[k]) }
      next if others.empty?

      { line: src[0...c[:b]].count("\n") + 1, ho: c[:ho], expected: others }
    end
  end

  def rel(path)
    Pathname.new(path.to_s).relative_path_from(Rails.root).to_s
  end

  # user-facing 영역 — 공개 정적 양식을 포함한다.
  # 앞 라운드 탐지기가 `public/**` 을 아예 안 봐서 공개 양식이 통째로 빠져나갔다.
  def scope_files
    (
      Dir[Rails.root.join("public/**/*.{html,md}")] +
      Dir[Rails.root.join("app/**/*.{rb,erb}")] +
      Dir[Rails.root.join("db/seeds/**/*.rb")] +
      Dir[Rails.root.join("config/**/*.yml")]
    ).reject { |f| EXCLUDED.include?(rel(f)) }
  end

  def blob(commit, path)
    out = `git -C #{Rails.root} show #{commit}:"#{path}" 2>/dev/null`
    assert $?.success?, "blob 취득 실패: #{commit}:#{path}"
    out
  end

  # ── 계측기 자체 대조 ─────────────────────────────────────────
  test "이 탐지기의 존재 이유 — 앞 라운드 탐지기는 public/ 을 아예 보지 않았다" do
    prior = Rails.root.join("test/models/article25_semantic_residual_test.rb").read
    refute_match(/Dir\[Rails\.root\.join\("public/, prior,
                 "앞 탐지기가 이미 public/ 을 봤다면 이 테스트의 근거가 없다")
    assert scope_files.any? { |f| rel(f).start_with?("public/forms/") },
           "이 탐지기의 검사 범위에 공개 양식이 없다"
  end

  test "정규화: 표기 4종을 같은 호로 읽고 다른 조문을 25조로 오독하지 않는다" do
    [ "제25조 제1항 제3호", "제25조제1항제3호", "§25①3호", "25조 1항 3호" ].each do |f|
      assert_equal 3, cites(f).first[:ho], "표기를 못 읽는다: #{f}"
    end
    assert_empty cites("제125조 제1항 제1호"), "제125조를 제25조로 오독한다"
  end

  # ── 양성 대조 — 수리 전 커밋에서 이번 3대상이 실제로 검출된다 ──
  #    (줄까지 지목한다. 「몇 건」 만 세면 다른 데가 걸려도 통과한다.)
  # 한 줄에 인용이 여러 개인 파일이 있어(resources 는 자료 1건이 1줄) 줄→호 «집합» 으로 본다.
  POSITIVE_CONTROL = {
    "public/forms/수의계약사유서.html" => { 124 => [ 2 ], 125 => [ 3 ], 126 => [ 4 ], 136 => [ 4 ] },
    "db/seeds/subtopics.rb" => { 982 => [ 4 ] },
    # :476 은 수리 전에 두 건이 함께 있었다 — (4) 특허를 제1호로 · (2) 긴급을 제4호로
    "app/views/guides/resources.html.erb" => { 476 => [ 1, 4 ] }
  }.freeze

  test "양성 대조: 수리 전(#{BEFORE_COMMIT}) 3대상에서 밀린 호 대응이 실제로 검출된다" do
    POSITIVE_CONTROL.each do |path, want|
      hits = mismatches(blob(BEFORE_COMMIT, path)).group_by { |h| h[:line] }
      want.each do |line, hos|
        found = hits[line]
        assert found, "#{path}:#{line} — 수리 전 오류를 탐지기가 못 잡는다 (탐지기가 죽었다)"
        hos.each do |ho|
          assert_includes found.map { |h| h[:ho] }, ho,
                          "#{path}:#{line} — 제#{ho}호 오기를 못 잡는다 (잡힌 것: #{found.map { |h| h[:ho] }.inspect})"
        end
      end
    end
  end

  test "양성 대조(폼 전용): 수리 전 스냅샷에 밀린 대응과 2,200만원이 함께 있었다" do
    before = blob(BEFORE_COMMIT, "public/forms/수의계약사유서.html")
    assert_includes before, "제2호: 국가기관, 다른 지방자치단체와 계약하는 경우",
                    "밀린 체크박스 대응이 수리 전 스냅샷에 없다 — 양성 대조가 성립하지 않는다"
    assert_includes before, "제4호: 추정가격이 수의계약 기준금액 이하인 경우"
    assert_includes before, "기준금액(2,200만원) 이하", "비정본 2,200만원이 수리 전 스냅샷에 없다"
    assert_operator mismatches(before).size, :>=, 4,
                    "수리 전 폼에서 4건 미만만 검출된다 — 탐지기가 무뎌졌다"
  end

  # ── 음성 대조 — 옳은 것을 막지 않는다 ─────────────────────────
  NEGATIVE_CONTROL = [
    "시행령 제25조 제1항 제1호 — 천재지변, 긴급한 행사 등 경쟁에 부칠 여유가 없는 경우",
    "시행령 제25조 제1항 제1호·제2호 (천재지변·재난 긴급복구)",
    '- locator: "제25조제1항제2호"' + "\n" + '  label: "긴급복구가 필요한 재난 등"',
    "제3호: 국가기관, 다른 지방자치단체와 계약하는 경우",
    "제4호: 특정인의 기술/용역 또는 특정 위치/구조 등으로 경쟁 불가",
    "본 건은 추정가격 15,000,000원으로 지방계약법 시행령 제25조 제1항 제5호 나목에 따른 " \
      "물품의 제조·구매계약 수의계약 기준금액(2천만원) 이하에 해당하여 수의계약으로 진행하고자 합니다.",
    # 정답 4쌍 배열 — 넓은 창이면 옆 쌍의 라벨을 물어 거짓양성이 난다
    '[["소액 수의", "시행령 제25조 제1항 제5호"], ["긴급 수의", "시행령 제25조 제1항 제1호"], ' \
      '["특정 수의", "시행령 제25조 제1항 제4호"], ["국가기관", "시행령 제25조 제1항 제3호"]]'
  ].freeze

  test "음성 대조: 정본과 일치하는 인용을 결함으로 세지 않는다" do
    NEGATIVE_CONTROL.each do |s|
      assert_empty mismatches(s), "정본 일치 인용을 오검출: #{s[0, 50]}"
    end
  end

  test "음성 대조: 자기 근거가 여러 줄 뒤에 있어도 정당한 인용은 세지 않는다" do
    # 근거가 인용에서 100자 넘게 «뒤» 에 떨어져 있는 실제 서식 모양
    src = <<~S
      「지방계약법」 제9조 제1항 단서 및 같은 법 시행령 제25조 제1항 제1호에 따라,
      2026년 ○월 ○일 발생한 태풍(천재지변)으로 ○○시설이 파손되었고,
      입찰 공고 및 낙찰자 선정에 소요되는 시간(최소 10일)을 고려할 때
      경쟁입찰에 부칠 여유가 없어 수의계약을 체결하고자 함.
    S
    assert_empty mismatches(src), "정당한 §25①1호 긴급 사유서를 오검출한다"
  end

  # 「입찰에 부칠 여유가 없는」 을 제1호의 신호로 쓰면 제2호 정본 원문이 통째로 거짓양성이 된다.
  # 신호가 «가르는 말» 인지 «공유하는 말» 인지를 계측기에 못박는다.
  test "신호는 호를 «구별» 해야 한다 — 1호·2호 공유 표현을 1호 신호로 쓰지 않는다" do
    shared = "입찰에 부칠 여유가 없는"
    refute_match SIG[1], shared, "제1호 신호가 1호·2호 공유 표현에 걸린다"
    # 정본 제2호 원문은 그 표현을 실제로 포함한다 — 그래서 공유다
    assert_includes Rails.root.join("db/seeds/topic_content_fix_2026_06_04_batch18.rb").read,
                    "입찰에 부칠 여유가 없는 긴급복구가 필요한 재난 등",
                    "정본 제2호 원문이 바뀌었다 — 이 판정의 근거가 사라졌다"
  end

  # ── AFTER — 이번에 고친 3대상은 0 ────────────────────────────
  test "AFTER: 이번 라운드 3대상의 §25① 호↔사유 mismatch 가 0" do
    REPAIRED.each do |path, lines|
      hits = mismatches(Rails.root.join(path).read)
              .select { |h| lines.cover?(h[:line]) }
              .reject { |h| ADJUDICATED_OUT_OF_SCOPE.key?("#{path}:#{h[:line]}") }
      assert_empty hits, "#{path}: 수리 후에도 판정되지 않은 mismatch 가 남아 있다 — #{hits.inspect}"
    end
  end

  # 뮤테이션 M15 가 살아남아 드러난 구멍 —
  # `resources.html.erb` 는 자료 1건이 **한 줄**이라, 그 줄에 이미 판정된 잔존(R-H 유찰)이 있으면
  # 같은 줄의 **새 결함까지** 판정 원장이 덮어 준다. 원장이 은신처가 된 것이다.
  # 그래서 이 줄만은 탐지기의 «없음» 이 아니라 **내용의 «있음»** 으로 잠근다.
  test "AFTER(가이드 예시문): 사유별 예시 4건의 호가 정본과 1:1 이다" do
    line = Rails.root.join("app/views/guides/resources.html.erb").read.lines[475]
    {
      "지방계약법 시행령 제25조제1항제5호에 따라 수의계약이 가능한 금액 기준 이하" => "(1) 소액수의 = 제5호",
      "긴급 복구가 필요하여 경쟁입찰에 부칠 여유가 없으므로 지방계약법 시행령 제25조제1항제2호" => "(2) 긴급복구 재난 = 제2호",
      "특허권·저작권 등에 의하여 ○○만이 제조·공급할 수 있어 지방계약법 시행령 제25조제1항제4호" => "(4) 특정인의 기술 = 제4호"
    }.each do |frag, label|
      assert_includes line, frag, "#{label} 대응이 정본과 어긋난다"
    end
    # (3) 유찰은 이번 라운드에서 고치지 않기로 «판정» 한 자리다. 조용히 사라지거나 바뀌면
    # 판정 근거가 무너지므로 그 상태 그대로 있음을 못박는다(R-H).
    assert_includes line, "2회 유찰되어 지방계약법 시행령 제25조제1항제2호",
                    "R-H(유찰=영 제26조) 판정 대상이 바뀌었다 — 판정과 실재가 어긋난다"
  end

  test "AFTER(폼): 새 정본 대응이 실제로 들어갔고 2,200만원이 사라졌다" do
    form = Rails.root.join("public/forms/수의계약사유서.html").read
    { "제3호: 국가기관" => 1, "제4호: 특정인의 기술" => 2, "제5호: 추정가격이" => 1 }.each do |frag, n|
      assert_operator form.scan(frag).size, :>=, n, "새 정본 대응 «#{frag}» 이 실제로 들어가지 않았다"
    end
    refute_includes form, "2,200만원", "근거 없는 2,200만원이 남아 있다"
    assert_includes form, "제25조 제1항 제5호 나목", "금액 근거가 정본 목(나목)을 가리키지 않는다"
    assert_includes form, "기준금액(2천만원) 이하", "정본 금액(2천만원)이 없다"

    # Word 내보내기 경로는 «있는가» 가 아니라 «화면과 같은 호를 말하는가» 로 잰다.
    # 두 목록을 파일에서 각각 뽑아 id → 호 로 대조한다 — 한쪽만 고치면 여기서 깨진다.
    screen = form.scan(/id="(legal_\d)"> 제(\d+)호:/).to_h
    export = form.scan(/data\.(legal_\d)\) legalBasis\.push\('제(\d+)호:/).to_h
    assert_equal 4, screen.size, "체크박스 4칸을 못 읽었다"
    assert_equal screen, export,
                 "Word 내보내기가 화면과 다른 호를 싣는다 — 화면 #{screen.inspect} / 내보내기 #{export.inspect}"
    assert_equal({ "legal_1" => "1", "legal_2" => "3", "legal_3" => "4", "legal_4" => "5" }, screen,
                 "체크박스 호 대응이 정본과 다르다")
  end

  test "폼은 «전체 목록» 이 아니라 «일부 + 기타» 라 없는 호를 만들어 넣지 않았다" do
    form = Rails.root.join("public/forms/수의계약사유서.html").read
    assert_includes form, 'id="legal_etc"', "기타 자유기재 칸이 없다 — 그러면 일부 목록이라는 판정이 성립하지 않는다"
    # 6~8호도 없다. 전체 목록이었다면 2호만 빠질 수 없다.
    %w[제6호 제7호 제8호 제2호].each do |ho|
      refute_includes form, "#{ho}: ", "폼이 #{ho} 를 제공한다 — 일부 목록 판정을 재검토해야 한다"
    end
  end

  # ── 잔존 — 판정 목록과 «정확히» 일치해야 한다 ────────────────
  test "잔존: 남은 mismatch 는 판정된 scope 밖 파일뿐이고 목록이 은신처가 되지 않는다" do
    actual = scope_files.flat_map do |f|
      mismatches(File.read(f)).map { |x| "#{rel(f)}:#{x[:line]}" }
    end.uniq

    unknown = actual - ADJUDICATED_OUT_OF_SCOPE.keys
    assert_empty unknown, "판정되지 않은 §25① 호 mismatch 가 있다: #{unknown.inspect}"

    stale = ADJUDICATED_OUT_OF_SCOPE.keys - actual
    assert_empty stale, "판정 목록에 있는데 실제로는 없다 — 목록이 실재와 어긋난다: #{stale.inspect}"
  end

  test "제외 목록은 «정정 시드» 만이고 제외가 실제로 필요하다" do
    assert_equal 1, EXCLUDED.size, "제외 목록이 바뀌었다 — 판정 없이 늘리지 않는다"
    EXCLUDED.each do |r|
      src = Rails.root.join(r).read
      assert mismatches(src).any?, "#{r} 은 탐지기에 걸리지 않는다 — 제외할 이유가 없다"
      assert_includes src, "제25조 제1항 제5호", "#{r} 이 치환표가 아니다(정정 후 문자열 없음)"
    end
  end

  # ── 이 탐지기가 다루지 않는 축 (다른 class · 기록만) ──────────
  test "유찰 수의는 §25① 이 아니라 영 제26조 — 이 탐지기의 mapping 밖이라 별도 FINDING 이다" do
    # 정본 확인: 재공고입찰 불성립은 §26 에서 정한다
    y = Rails.root.join("config/contract_decision_rules.yml").read
    assert_includes y, '- locator: "제26조"'
    assert_includes y, "재공고입찰이 성립하지 않거나 낙찰자가 없는 경우"

    # 실재 확인: 세 곳이 유찰을 §25①2호로 적고 있다. 그중 하나는 **R2 core** 라
    # 이번 라운드 제약(R2_CORE_MODIFIED=0)에서 한꺼번에 정합시킬 수 없다 → 손대지 않았다.
    core = Rails.root.join("app/services/contract_method_service.rb").read
    assert_includes core, "2회 유찰(재공고 포함) 시 수의계약으로 전환할 수 있습니다",
                    "R2 core 의 유찰 안내가 사라졌다 — 이번 라운드는 이 파일을 건드리지 않는다"
    assert_includes core, "제25조제1항제2호",
                    "R2 core 의 유찰 근거가 바뀌었다 — 이 라운드에서 고치지 않기로 판정한 자리다"
  end
end
