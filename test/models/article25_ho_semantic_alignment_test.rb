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
  BEFORE_COMMIT = "5a70437" # 공개 양식 표기 수리 직전 HEAD
  THIS_ROUND_BEFORE = "96a1afb" # R-A(사유서 생성기 긴급수의)·R-H(유찰) 수리 직전 HEAD

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
    "app/views/guides/resources.html.erb" => (470..480),
    # R-A — 사유서를 **생성해 주는** 화면. 카드(:249)와 데이터(:447~:452)가 한 근거를 공유한다.
    "app/views/contract_reasons/index.html.erb" => (230..460)
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
    # (3) 유찰은 이번 라운드에서 **고친** 자리다. §25① 어느 호도 아니고 영 제26조다.
    assert_includes line, "2회 유찰되어 지방계약법 시행령 제26조제1항에 따라",
                    "R-H(유찰=영 제26조) 수리가 가이드 예시문에 들어가지 않았다"
    refute_includes line, "2회 유찰되어 지방계약법 시행령 제25조제1항",
                    "유찰을 아직도 §25① 로 적는다"
  end

  # R-A — 「사유서를 만들어 주는」 화면이라 카드·근거·예시문이 한 호를 말해야 한다.
  # §25① 축 탐지기는 이 자리를 못 본다: 뮤테이션 M1·M3·M4·M5·M7 이 살아남아 드러났다.
  # 자기 근거도 없고 옆에 충돌 신호도 없어서 «어긋남» 자체가 계측되지 않는 모양이다.
  # 그래서 이 화면만은 탐지기의 «없음» 이 아니라 **내용의 «있음»** 으로 잠근다.
  test "AFTER(사유서 생성기): 카드·근거·예시문 3건이 모두 §25①1호를 가리킨다" do
    src = Rails.root.join("app/views/contract_reasons/index.html.erb").read

    card = src[%r{data-reason="urgent".*?</div>\s*</div>}m]
    assert card, "긴급 사유 카드를 못 읽었다"
    assert_includes card, "지방계약법 시행령 제25조제1항제1호", "카드가 §25①1호를 말하지 않는다"

    block = src[/^  urgent: \{.*?^  \},/m]
    assert block, "urgent 데이터 블록을 못 읽었다"
    assert_includes block, "law: '지방계약법 시행령 제25조제1항제1호'"

    # lawText 는 제1호 **원문**이어야 한다. 원문이 사라지면 이 화면은 근거 없는 인용이 된다.
    [ "천재·지변", "작전상 병력이동", "긴급한 행사", "원자재의 가격급등" ].each do |t|
      assert_includes block, t, "제1호 원문 표지 «#{t}» 가 lawText 에서 사라졌다"
    end

    # 예시문은 `law`·`lawText` 와 **한 장으로** 결재서류에 실린다(HWPX 내보내기).
    # 서로 다른 호를 말하면 그 문서 자체가 자기모순이다.
    hos = block.scan(/제25조제1항제(\d+)호/).flatten.uniq
    assert_equal [ "1" ], hos, "urgent 블록 안에서 호가 갈린다: #{hos.inspect}"
    assert_equal 3, block.scan(/제25조제1항제1호에 따라 수의계약으로 긴급 추진/).size,
                 "예시문 3건(물품·용역·공사)이 모두 제1호를 싣지 않는다"
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

  # ── R-H: 유찰 수의 = 영 제26조 (다른 semantic class) ──────────
  # 앞 라운드는 이 축을 「다른 class · 기록만」으로 판정하고 넘겼다. 그 판정이 원장에 남아
  # 세 경로가 서로 다른 말을 하는 상태를 **잠가** 버렸다 — 원장이 은신처가 된 두 번째 자리다.
  # 이번에는 판정 대신 계측으로 바꾼다. 세 경로를 하나의 class 로 함께 본다.
  FAILED_BID_SIG = /유찰|재공고입찰|낙찰자가\s*없|입찰이\s*성립하지|경쟁입찰이\s*성립되지/
  ART25_HO_CITE = /제\s*25\s*조\s*제?\s*1\s*항\s*제?\s*\d+\s*호/

  # 한 줄에 자료가 여러 건 들어가는 파일만 `\n\n`(이스케이프된 문단)으로 더 쪼갠다.
  # 더 쪼개면 안 되는 파일도 있다 — faq_controller 는 한 Q&A 가 한 줄이고 「유찰」과 「근거:」 사이에
  # `\n\n` 이 있어서, 일률적으로 쪼개면 인용이 자기 주장에서 떨어져 나가 결함이 빠져나간다.
  FAILED_BID_UNIT = { "app/views/guides/resources.html.erb" => :escaped_paragraph }.freeze

  FAILED_BID_REPAIRED = %w[
    app/views/guides/resources.html.erb
    app/controllers/faq_controller.rb
    app/services/contract_method_service.rb
  ].freeze

  # 수리 전(#{THIS_ROUND_BEFORE}) 실제로 걸리던 자리. 「몇 건」이 아니라 줄로 못박는다.
  FAILED_BID_POSITIVE = {
    "app/views/guides/resources.html.erb" => [ 476 ],
    "app/controllers/faq_controller.rb" => [ 58 ],
    "app/services/contract_method_service.rb" => [ 296, 323 ]
  }.freeze

  # 한 문장 안에 「유찰」과 §25① 인용이 같이 있어도, 그 인용이 **자기 사유를 데리고 있으면**
  # 유찰 주장의 근거가 아니다 (예: "…유찰 확정 후에야 전환 가능. 긴급의 경우 별도 요건
  # (§25①1호·2호 — 천재지변·재난 긴급복구)을 검토"). 자기 근거는 §25① 축 탐지기의 SIG 를 그대로 쓴다.
  SELF_JUSTIFIED_W = 90

  def self_justified?(seg, m)
    ho = m[/\d+(?=\s*호)/].to_i
    sig = SIG[ho]
    return false unless sig
    i = seg.index(m)
    # 시작에서 잘린 만큼 «뒤로» 더 보게 되면 창이 조용히 넓어진다.
    # 길이가 아니라 양끝을 각각 계산한다.
    lo = [ i - SELF_JUSTIFIED_W, 0 ].max
    hi = i + m.length + SELF_JUSTIFIED_W
    seg[lo...hi].to_s.match?(sig)
  end

  # 유찰 주장이 **인용을 달고 있는** 자리. 「파일 어딘가에 §26 이 있다」로 재면
  # 두 자리 중 한 곳이 무너져도 통과한다(뮤테이션 M13 이 그렇게 살아남았다) — 자리마다 잰다.
  DECREE_CITE = /시행령\s*제\s*\d+\s*조(?:\s*제?\s*\d+\s*항)?(?:\s*제?\s*\d+\s*호)?/

  def failed_bid_citing_segments(src, path = nil)
    src.lines.each_with_index.flat_map do |line, i|
      segs = FAILED_BID_UNIT[path] == :escaped_paragraph ? line.split('\n\n') : [ line ]
      segs.filter_map do |seg|
        next unless seg.match?(FAILED_BID_SIG)
        cite = seg[DECREE_CITE]
        cite && { line: i + 1, cite: cite }
      end
    end
  end

  def failed_bid_mismatches(src, path = nil)
    src.lines.each_with_index.flat_map do |line, i|
      segs = FAILED_BID_UNIT[path] == :escaped_paragraph ? line.split('\n\n') : [ line ]
      segs.filter_map do |seg|
        next unless seg.match?(FAILED_BID_SIG)
        cite = seg[ART25_HO_CITE]
        next unless cite
        next if self_justified?(seg, cite)
        { line: i + 1, cite: cite }
      end
    end
  end

  test "정본: 재공고입찰 불성립·낙찰자 없음은 §25① 이 아니라 영 제26조다" do
    y = Rails.root.join("config/contract_decision_rules.yml").read
    assert_includes y, '- locator: "제26조"'
    assert_includes y, "재공고입찰이 성립하지 않거나 낙찰자가 없는 경우"
    # 기본 요건이 §26① 이라는 것은 repo 안 정정 시드가 이미 확정해 둔 사실이다
    assert_includes Rails.root.join("db/seeds/fix_law_references_2026_03.rb").read,
                    "시행령 제26조 제1항 | 재공고입찰 유찰 후 수의계약의 기본 요건"
  end

  test "양성 대조(R-H): 수리 전(#{THIS_ROUND_BEFORE}) 세 경로가 유찰을 §25① 로 적고 있었다" do
    FAILED_BID_POSITIVE.each do |path, lines|
      hits = failed_bid_mismatches(blob(THIS_ROUND_BEFORE, path), path).map { |h| h[:line] }
      lines.each do |l|
        assert_includes hits, l,
                        "#{path}:#{l} — 수리 전 유찰 오기를 탐지기가 못 잡는다 (탐지기가 죽었다). 잡힌 줄: #{hits.inspect}"
      end
    end
  end

  test "AFTER(R-H): 세 경로의 유찰 인용이 «자리마다» 영 제26조제1항이다" do
    FAILED_BID_REPAIRED.each do |path|
      src = Rails.root.join(path).read
      assert_empty failed_bid_mismatches(src, path),
                   "#{path}: 유찰을 아직 §25① 로 적는 자리가 남아 있다"

      sites = failed_bid_citing_segments(src, path)
      refute_empty sites, "#{path}: 유찰 인용 자리를 하나도 못 찾았다 — 게이트가 헛돈다"
      sites.each do |site|
        assert_includes site[:cite], "제26조제1항",
                        "#{path}:#{site[:line]} 의 유찰 근거가 «#{site[:cite]}» 다 — 한 자리만 무너져도 세 경로가 다른 말을 한다"
      end
    end
    # 수리 전에는 이 자리들이 §26 을 말하지 않았다 — 게이트가 원래부터 통과하던 것이 아니다
    FAILED_BID_REPAIRED.each do |path|
      before = failed_bid_citing_segments(blob(THIS_ROUND_BEFORE, path), path)
      refute before.all? { |x| x[:cite].include?("제26조제1항") },
             "#{path}: 수리 전에도 이미 §26①이었다 — 이 게이트의 근거가 없다"
    end
  end

  test "음성 대조(R-H): 유찰이 아닌 재난 긴급복구 예시(제2호)는 그대로다" do
    line = Rails.root.join("app/views/guides/resources.html.erb").read.lines[475]
    assert_includes line,
                    "긴급 복구가 필요하여 경쟁입찰에 부칠 여유가 없으므로 지방계약법 시행령 제25조제1항제2호",
                    "정당한 §25①2호(재난 긴급복구)까지 함께 치환됐다 — 문자열만 보고 일괄 치환한 지문"
    # 계측기 쪽에서도 확인: 그 문단은 유찰 주장이 아니라 애초에 대상이 아니다
    seg = line.split('\n\n').find { |x| x.include?("긴급 복구가 필요하여") }
    refute_match FAILED_BID_SIG, seg, "재난 긴급복구 문단이 유찰 class 로 분류된다"
  end

  test "계측기 대조(R-H): 유찰 주장 없이 §25① 만 있는 줄은 세지 않는다" do
    refute_empty failed_bid_mismatches("2회 유찰 시 지방계약법 시행령 제25조제1항제2호"),
                 "유찰+§25① 조합을 못 잡는다"
    assert_empty failed_bid_mismatches("천재지변으로 지방계약법 시행령 제25조제1항제1호"),
                 "유찰 주장이 없는 줄을 잡는다"
    assert_empty failed_bid_mismatches("2회 유찰 시 지방계약법 시행령 제26조제1항"),
                 "이미 정본(§26)인 줄을 잡는다"

    # 면제는 «바로 옆» 근거만 놓아 줘야 한다. 창이 넓어지면 한참 떨어진 무관한 낱말이
    # 결함을 덮는다 — 창 크기를 합성 문장으로 잠근다(뮤테이션 M16).
    cite = "제25조제1항제2호"
    far = "2회 유찰되어 지방계약법 시행령 #{cite}에 따라 최초 입찰에 부친 조건과 " \
          "동일한 조건으로 예정가격 이내에서 수의계약을 체결할 수 있습니다. 계약 담당자는 " \
          "관련 서류를 갖추어 결재를 받고, 계약심사 대상 여부와 지출원인행위 시기를 함께 " \
          "확인해야 합니다. 참고로 재난 긴급복구는 전혀 다른 절차다."
    # 창은 인용의 «앞뒤» 로 열린다 — 뒤쪽 끝은 인용 끝 + W 다. 대조는 그 경계 밖에 놓아야 성립한다.
    assert_operator far.index("재난") - far.index(cite), :>, SELF_JUSTIFIED_W + cite.length,
                    "합성 대조가 성립하지 않는다 — 무관한 낱말이 이미 창 안에 있다"
    refute_empty failed_bid_mismatches(far),
                 "창 밖의 무관한 «재난» 이 유찰 결함을 면제해 준다"
  end

  # scope 밖 잔존 — 목록이 은신처가 되지 않도록 `경로:줄` 로 못박는다.
  # 이번 라운드는 사용자가 R-A·R-H 3경로로 범위를 동결했으므로 아래는 **기록만** 한다.
  FAILED_BID_OUT_OF_SCOPE = {
    # R-J 실재 오류 — 「재공고에도 1인만 참가하면 그 1인과 수의계약(시행령 §25①5호)」.
    # §25①5호는 **금액 기준**이고, 재공고입찰 불성립·낙찰자 없음은 영 제26조다.
    # R-H 와 같은 semantic class 지만 사용자가 이번 scope 를 R-A + R-H 3경로로 동결했다 → 기록만.
    "db/seeds/topic_bid_announcement.rb:54" => "R-J 실재 오류 (운영 콘텐츠 시드)",
    "db/seeds/topic_bidding.rb:76" => "R-J 실재 오류 (한시적 특례 종료 문구)",
    "db/seeds/topic_bidding.rb:218" => "R-J 실재 오류 (한시적 특례 종료 문구)",
    "db/seeds/topic_bidding.rb:315" => "R-J 실재 오류 (유찰 FAQ 답변)",
    "db/seeds/topic_restricted_bidding.rb:329" => "R-J 실재 오류 (한시적 특례 종료 문구)",
    "db/seeds/topic_restricted_bidding.rb:405" => "R-J 실재 오류 (제한경쟁 유찰 FAQ 답변)",

    # R-J 의 치환표 사본. old/new 양쪽에 같은 문장이 들어 있어 «고칠수록 숫자가 나빠지는» 자리다.
    # 원문(위 6곳)을 먼저 고치고 그때 함께 갱신해야 한다 — 따로 고치면 앵커가 깨진다.
    "db/seeds/topic_content_fix_2026_07_06_hansi_expiry.rb:47" => "R-J 치환표 사본",
    "db/seeds/topic_content_fix_2026_07_06_hansi_expiry.rb:53" => "R-J 치환표 사본",
    "db/seeds/topic_content_fix_2026_07_06_hansi_expiry.rb:76" => "R-J 치환표 사본",
    "db/seeds/topic_content_fix_2026_07_06_hansi_expiry.rb:77" => "R-J 치환표 사본",
    "db/seeds/topic_content_fix_2026_07_06_hansi_expiry.rb:84" => "R-J 치환표 사본",
    "db/seeds/topic_content_fix_2026_07_06_hansi_expiry.rb:107" => "R-J 치환표 사본",
    "db/seeds/topic_content_fix_2026_07_06_hansi_expiry.rb:108" => "R-J 치환표 사본",

    # 결함이 아니다 — 「§25①6호 → §26①」 정정을 **이미 수행한** 스크립트라 정정 «전» 문자열을 들고 있다.
    "db/seeds/fix_law_references_2026_03.rb:4" => "정정 치환표 (주석 · 결함 아님)",
    "db/seeds/fix_law_references_2026_03.rb:63" => "정정 치환표 (old 앵커 · 결함 아님)",
    "db/seeds/fix_law_references_2026_03.rb:76" => "정정 치환표 (old 앵커 · 결함 아님)",
    "db/seeds/fix_law_references_2026_03.rb:111" => "정정 치환표 (old 앵커 · 결함 아님)"
  }.freeze

  test "면제 규칙은 «필요해서» 있다 — 자기 근거를 데린 인용 1건이 실제로 존재한다" do
    src = Rails.root.join("db/seeds/topic_bid_failure.rb").read
    line = src.lines[184]
    assert_match FAILED_BID_SIG, line, "이 줄에 유찰 신호가 없다 — 면제 규칙의 근거가 사라졌다"
    assert_match ART25_HO_CITE, line, "이 줄에 §25① 인용이 없다 — 면제 규칙의 근거가 사라졌다"
    assert self_justified?(line, line[ART25_HO_CITE]),
           "자기 근거(천재지변·재난)를 데린 인용인데 면제되지 않는다"
    # 면제가 진짜 인용을 놓아 주지는 않는지 — 세 경로의 수리 전 자리는 여전히 잡혀야 한다
    FAILED_BID_POSITIVE.each do |path, lines|
      hits = failed_bid_mismatches(blob(THIS_ROUND_BEFORE, path), path).map { |h| h[:line] }
      assert_equal lines.sort, (hits & lines).sort,
                   "#{path}: 면제 규칙이 실제 결함까지 놓아 준다"
    end
  end

  test "잔존(R-H): scope 밖 유찰 mismatch 는 판정 목록과 정확히 일치한다" do
    actual = scope_files.flat_map do |f|
      r = rel(f)
      next [] if FAILED_BID_REPAIRED.include?(r)
      failed_bid_mismatches(File.read(f), r).map { |x| "#{r}:#{x[:line]}" }
    end.uniq

    unknown = actual - FAILED_BID_OUT_OF_SCOPE.keys
    assert_empty unknown, "판정되지 않은 유찰↔§25① mismatch 가 있다: #{unknown.inspect}"

    stale = FAILED_BID_OUT_OF_SCOPE.keys - actual
    assert_empty stale, "판정 목록에 있는데 실제로는 없다: #{stale.inspect}"
  end
end
