# frozen_string_literal: true

require "test_helper"

#
# §25①1호 의미 오용 잔여 정리 (2026-09-06)
#
# 앞 라운드(F1·F5)의 탐지기는 **괄호 표기**(`제1호 (소액 수의계약)`)를 요구했다.
# 그래서 같은 오용이라도 표기가 다르면 전부 빠져나갔다 — 실제로 7건이 남아 있었다.
# 이 탐지기는 문자열이 아니라 **의미 결합**을 본다: 표기를 정규화해 «호 번호»를 뽑고,
# 금액·한도 주장(CLAIM_KIND)이 어느 호에 매여 있는지를 판정한다.
#
# 정본 (지방계약법 시행령 [시행 2026. 6. 3.] · config/contract_decision_rules.yml verified_at 2026-09-06):
#   §25①1호 = 천재지변·감염병 등 입찰에 부칠 여유가 없는 경우   ← 금액 조항이 아니다
#   §25①5호 = 소액수의 금액 체계
#     가목 공사 4억 / 2억 / 1억6천만   나목 물품·용역 2천만
#     다목 청년창업 5천만  라목 소기업·소상공인 1억  마목 1억  바목 여성·장애인·사회적기업 등 1억
#   → 세부 목은 계약유형과 상대방 요건이 함께 정한다. 근거 없이 목을 지정하지 않는다.
#
class Article25SemanticResidualTest < ActiveSupport::TestCase
  BEFORE_COMMIT = "29664de" # 이번 잔여 정리 직전 HEAD

  # ── 표기 정규화 — 호 번호를 캡처한다 ────────────────────────────
  # 제25조 제1항 제1호 / 제25조제1항제1호 / §25①1호 / 25조 1항 1호 를 모두 같은 것으로 본다.
  # 앞자리 숫자 배제(제125조 등)로 오검출을 막는다.
  CITE = /
    (?:(?<![0-9])§\s*25\s*①\s*(?<a>\d+)\s*호)
    |
    (?:제?\s*(?<![0-9])25\s*조\s*제?\s*1\s*항\s*제?\s*(?<b>\d+)\s*호)
  /x

  # ── CLAIM_KIND — 소액수의 / 수의계약한도 / 금액기준 / 한도판정 ──
  CLAIM = /소액\s*수의|수의계약\s*한도|한도액|기준금액|한도\s*이하|추정가격[^\n]{0,24}이하|수의계약\s*기준/

  # ── §25①1호가 실제로 말하는 것 ────────────────────────────────
  EMERG = /천재지변|긴급|재난|감염병|여유가\s*없|응급|복구/

  W_CLAIM = 120 # CLAIM ↔ 인용 결속 창
  W_EMERG = 100 # 인용 ↔ 긴급문맥 창

  # 검사 대상 = 사용자에게 나가는 콘텐츠 · 운영 시드 · 판정 규칙 · 검증 로그
  def scope_files
    (
      Dir[Rails.root.join("app/**/*.rb")] +
      Dir[Rails.root.join("app/**/*.erb")] +
      Dir[Rails.root.join("db/seeds/**/*.rb")] +
      Dir[Rails.root.join("config/**/*.yml")] +
      [ Rails.root.join("FULL_VERIFICATION_LOG.md").to_s ]
    ).reject { |f| EXCLUDED.include?(rel(f)) }
  end

  # 정정 시드는 «치환표» 라서 정정 전 문자열을 반드시 들고 있다. 그걸 결함으로 세면
  # 고칠수록 숫자가 나빠진다. 제외 근거는 테스트가 직접 확인한다(아래).
  EXCLUDED = %w[
    db/seeds/topic_deploy_blocker_fix_2026_09_06.rb
  ].freeze

  # 이번 semantic class 가 **아니라고 판정한** §25①1호 인용. 조용히 늘지 않게 이름으로 고정한다.
  # (같은 class 가 새로 생기면 아래 «잔여 0» 테스트가 먼저 깨진다.)
  # 2026-09-06 2차 — `app/views/guides/resources.html.erb` 는 목록에서 **빠졌다**.
  # 「제1호를 특정인의 기술·특허로 인용」 하던 그 자리를 이번 라운드가 제4호로 실제 정정했기 때문이다.
  # 판정 목록은 실재와 함께 움직여야 한다 — 고친 뒤에도 남겨 두면 목록이 은신처가 된다.
  JUDGED_NON_CLASS = {
    "db/seeds/audit_cases/topic_goods_selection_committee.rb" =>
      "CONTEXT_AMBIGUOUS — 라벨이 «수의계약 사유» 이고 사실관계가 어느 호였는지 사례에 없다. 임의로 호를 지정하지 않는다",
    "db/seeds/budget_execution_part1.rb" =>
      "CONTEXT_AMBIGUOUS — 품의서 기재 예시의 «법령상 사유» 예로 든 것. 제1호도 실재하는 사유다"
  }.freeze

  # ── 탐지기 본체 ──────────────────────────────────────────────
  def citations(src)
    src.to_enum(:scan, CITE).map do
      m = Regexp.last_match
      { begin: m.begin(0), end: m.end(0), ho: (m[:a] || m[:b]).to_i }
    end
  end

  def line_of(src, pos)
    src[0...pos].count("\n") + 1
  end

  # D-A: 금액·한도 주장에 «가장 가까운» 인용이 제1호면 조문 오용이다.
  def wrong_article_hits(src)
    cites = citations(src)
    return [] if cites.empty?

    src.to_enum(:scan, CLAIM).filter_map do
      cm = Regexp.last_match
      cp = (cm.begin(0) + cm.end(0)) / 2
      near = cites.select { |c| ((c[:begin] + c[:end]) / 2 - cp).abs <= W_CLAIM }
      next if near.empty?

      nearest = near.min_by { |c| ((c[:begin] + c[:end]) / 2 - cp).abs }
      next unless nearest[:ho] == 1

      { line: line_of(src, nearest[:begin]), claim: cm[0] }
    end
  end

  # D-C: 제1호를 인용하면서 긴급 문맥이 없으면 «정당화되지 않은 인용» 이다.
  def unjustified_ho1_hits(src)
    citations(src).filter_map do |c|
      next unless c[:ho] == 1

      win = src[[ c[:begin] - W_EMERG, 0 ].max...(c[:end] + W_EMERG)].to_s
      next if win.match?(EMERG)

      { line: line_of(src, c[:begin]) }
    end
  end

  # 제1호를 «정당하게» 긴급 문맥으로 쓴 인용 수 — 과잉정정 축의 계기
  def valid_emergency_hits(src)
    citations(src).count do |c|
      next false unless c[:ho] == 1

      src[[ c[:begin] - W_EMERG, 0 ].max...(c[:end] + W_EMERG)].to_s.match?(EMERG)
    end
  end

  def rel(path)
    Pathname.new(path.to_s).relative_path_from(Rails.root).to_s
  end

  def blob(commit, path)
    out = `git -C #{Rails.root} show #{commit}:#{path} 2>/dev/null`
    assert $?.success?, "blob 취득 실패: #{commit}:#{path}"
    out
  end

  # ── 계측기 자체 대조 ─────────────────────────────────────────
  test "정규화: 네 가지 표기를 모두 같은 «제1호» 로 읽는다" do
    [
      "제25조 제1항 제1호", "제25조제1항제1호", "§25①1호", "25조 1항 1호"
    ].each do |form|
      cs = citations(form)
      assert_equal 1, cs.size, "표기를 못 읽는다: #{form}"
      assert_equal 1, cs.first[:ho], "호 번호를 잘못 읽는다: #{form}"
    end
    # 다른 호는 다른 호로 읽는다
    assert_equal 5, citations("제25조제1항제5호").first[:ho]
    # 앞자리 숫자에 걸려 다른 조문을 25조로 읽지 않는다
    assert_empty citations("제125조 제1항 제1호"), "제125조를 제25조로 오독한다"
  end

  test "이 탐지기가 필요한 이유 — 앞 라운드의 괄호 의존 탐지기는 이번 7건을 못 잡는다" do
    paren = /제25조\s*제1항\s*제1호[^\n]{0,40}\(\s*(?:소액\s*수의계약|수의계약\s*한도)/
    %w[
      app/views/topics/flowcharts/_private_contract_limit.html.erb
      app/views/topics/show.html.erb
      app/services/blog_legal_verifier.rb
      db/seeds/audit_cases/contract_topic_audit_cases.rb
    ].each do |path|
      before = blob(BEFORE_COMMIT, path)
      refute_match paren, before, "#{path}: 괄호 탐지기가 이미 잡았다면 이 탐지기의 근거가 없다"
      assert wrong_article_hits(before).any? || unjustified_ho1_hits(before).any?,
             "#{path}: 새 탐지기가 수리 전 오용을 잡지 못한다"
    end
  end

  # ── 양성 대조 — 수리 전 커밋에서 실제로 검출된다 ──────────────
  POSITIVE_CONTROL = {
    "app/views/topics/flowcharts/_private_contract_limit.html.erb" => { wrong: 2, unjust: 4 },
    "app/views/topics/show.html.erb"                              => { wrong: 1, unjust: 1 },
    "app/services/blog_legal_verifier.rb"                         => { wrong: 3, unjust: 4 },
    "db/seeds/audit_cases/contract_topic_audit_cases.rb"          => { wrong: 1, unjust: 1 },
    "db/seeds/zz_auditcase_verification_2026_06_18_batch14.rb"    => { wrong: 1, unjust: 1 },
    "FULL_VERIFICATION_LOG.md"                                    => { wrong: 0, unjust: 2 }
  }.freeze

  test "양성 대조: 수리 전(#{BEFORE_COMMIT}) 원천에서 잔여 7건이 실제로 검출된다" do
    total_files = 0
    POSITIVE_CONTROL.each do |path, want|
      before = blob(BEFORE_COMMIT, path)
      w = wrong_article_hits(before).map { |h| h[:line] }.uniq
      u = unjustified_ho1_hits(before).map { |h| h[:line] }.uniq
      assert_operator w.size, :>=, want[:wrong],
                      "#{path}: 조문오용 양성 대조 미달 (#{w.size} < #{want[:wrong]}) — 탐지기가 죽었다"
      assert_operator u.size, :>=, want[:unjust],
                      "#{path}: 미정당 인용 양성 대조 미달 (#{u.size} < #{want[:unjust]})"
      total_files += 1
    end
    assert_equal 6, total_files
  end

  # ── 음성 대조 — 정당한 긴급계약 인용은 살아남는다 ─────────────
  VALID_EMERGENCY = [
    "| **긴급 수의** | 시행령 제25조 제1항 제1호 | 천재지변, 긴급 행사 등 경쟁 여유 없음 |",
    "시행령 제25조 제1항 제1호·제2호 (천재지변·재난 긴급복구)",
    "지방자치단체를 당사자로 하는 계약에 관한 법률 시행령 제25조제1항제1호(긴급입찰)",
    '- locator: "제25조제1항제1호"' + "\n" +
      '  label: "천재지변·감염병·긴급행사·원자재 가격급등 등 입찰에 부칠 여유가 없는 경우"',
    "**§25 ① 1호** — 천재지변·긴급복구 등 입찰 여유가 없는 경우"
  ].freeze

  test "음성 대조: 정당한 §25①1호 긴급계약 인용을 결함으로 세지 않는다" do
    VALID_EMERGENCY.each do |s|
      assert_empty wrong_article_hits(s), "정당한 긴급계약 인용을 조문오용으로 오검출: #{s[0, 40]}"
      assert_empty unjustified_ho1_hits(s), "정당한 긴급계약 인용을 미정당으로 오검출: #{s[0, 40]}"
    end
  end

  test "음성 대조: 정당한 금액 기준(청년창업 5천만·§30 5천만·공사 4억/2억/1.6억·소기업 1억)은 건드리지 않았다" do
    v = Rails.root.join("app/views/topics/flowcharts/_private_contract_limit.html.erb").read
    assert_includes v, "일반 물품·용역 수의계약 한도는 2천만원, 청년창업기업은 5천만원",
                    "일반 2천만 / 청년창업 5천만 문장이 훼손됐다"
    assert_includes v, "소기업·소상공인 (1억원)", "소기업·소상공인 1억 카드가 사라졌다"
    assert_includes v, "종합 4억 / 전문 2억 / 기타 1.6억", "공사 3축 한도가 훼손됐다"
    assert_includes v, "제25조제1항제5호에 따른 상시 제도입니다", "앞 라운드 제5호 정정문이 사라졌다"

    y = Rails.root.join("config/contract_decision_rules.yml").read
    { "제25조제1항제5호가목" => 3, "제25조제1항제5호나목" => 1 }.each do |loc, n|
      assert_operator y.scan(loc).size, :>=, n, "판정 규칙집의 #{loc} 근거가 줄었다"
    end
    assert_includes y, "1억6천만원 이하", "그 밖의 공사 1억6천만 기준이 사라졌다"

    b = Rails.root.join("app/services/blog_legal_verifier.rb").read
    assert_includes b, "제30조 제1항", "§30 1인 견적 근거가 §25로 오치환됐다"
    assert_includes b, "제30조 제1항 단서", "§30 단서 근거가 사라졌다"
  end

  # 과잉정정 축 — 실측(2026-09-06) 파일별 정당한 긴급 인용 수.
  # 총량만 세면 «한 곳이 줄고 다른 곳이 늘어도» 통과한다. 파일별로 잠근다.
  EMERGENCY_BASELINE = {
    "app/services/blog_legal_verifier.rb" => 1,
    # 사유서 생성기(R-A) — 카드 1 + `law` 1 + 예시문 3. 한 근거(§25①1호)를 다섯 자리가 공유한다.
    "app/views/contract_reasons/index.html.erb" => 5,
    "app/views/topics/flowcharts/_private_contract_justification.html.erb" => 1,
    "config/contract_decision_rules.yml" => 1,
    "db/seeds/fix_law_references_2026_03.rb" => 1,
    "db/seeds/guides.rb" => 1,
    "db/seeds/topic_bid_failure.rb" => 1,
    "db/seeds/topic_fence_installation.rb" => 1,
    "db/seeds/topic_quick_stats_backfill_2026_06_03_batch6.rb" => 1,
    "db/seeds/subtopics.rb" => 1,
    "db/seeds/topics.rb" => 2,
    "db/seeds/zz_auditcase_verification_2026_06_18_batch14.rb" => 1
  }.freeze

  test "과잉정정 0: 정당한 §25①1호 긴급 인용이 파일별로 줄지 않았다" do
    actual = scope_files.each_with_object({}) do |f, acc|
      n = valid_emergency_hits(File.read(f))
      acc[rel(f)] = n if n.positive?
    end
    EMERGENCY_BASELINE.each do |path, want|
      assert_operator actual.fetch(path, 0), :>=, want,
                      "#{path}: 정당한 긴급 §25①1호 인용이 #{want} → #{actual.fetch(path, 0)} 로 줄었다 (과잉정정)"
    end
    # 11 → 12. 늘어난 1건은 `db/seeds/subtopics.rb:982` — 긴급수의 근거를 제4호에서 제1호로
    # 정정하면서 «정당한 §25①1호 긴급 인용» 이 하나 생겼다. 과잉정정이 아니라 정정의 결과다.
    # 12 → 17. 늘어난 5건은 `app/views/contract_reasons/index.html.erb` (R-A) — 사유서 생성기가
    # 긴급수의를 §25①2호로 적던 다섯 자리를 제1호로 정정했다. 같은 이유로 «늘어난» 것이다.
    # 총량은 «줄지 않았다» 를 재는 축이 아니다(그건 위의 파일별 >= 가 잰다). 조용한 증감을 막는 축이라
    # 정정할 때마다 사유와 함께 갱신한다.
    assert_equal 17, actual.values.sum, "정당한 긴급 인용 총량이 17 에서 벗어났다: #{actual.inspect}"
  end

  # ── 잔여 0 ───────────────────────────────────────────────────
  test "잔여: 금액·한도 주장을 §25①1호에 매단 곳이 0건" do
    offenders = scope_files.flat_map do |f|
      wrong_article_hits(File.read(f)).map { |h| "#{rel(f)}:#{h[:line]} (#{h[:claim]})" }
    end
    assert_empty offenders, "§25①1호를 금액·한도 근거로 인용하는 곳이 남아 있다: #{offenders.inspect}"
  end

  test "잔여: 긴급 문맥 없이 §25①1호를 인용한 곳은 «판정된» 2건뿐이다" do
    hits = scope_files.each_with_object({}) do |f, acc|
      h = unjustified_ho1_hits(File.read(f))
      acc[rel(f)] = h.map { |x| x[:line] } if h.any?
    end
    unknown = hits.keys - JUDGED_NON_CLASS.keys
    assert_empty unknown, "판정되지 않은 §25①1호 인용이 있다: #{unknown.inspect}"
    assert_equal JUDGED_NON_CLASS.keys.sort, hits.keys.sort,
                 "판정 목록과 실제 잔존이 어긋난다 — 목록이 은신처가 되지 않게 함께 움직여야 한다"
  end

  test "제외 목록은 «제외가 실제로 필요한» 정정 시드만이고 조용히 늘지 않는다" do
    assert_equal 1, EXCLUDED.size, "제외 목록이 바뀌었다 — 판정 없이 늘리지 않는다"
    EXCLUDED.each do |r|
      src = Rails.root.join(r).read
      assert wrong_article_hits(src).any?, "#{r} 은 탐지기에 걸리지 않는다 — 제외할 이유가 없다"
      assert_includes src, "제25조 제1항 제5호", "#{r} 이 치환표가 아니다(정정 후 문자열 없음)"
    end
  end

  # ── 계측 하네스 자체의 결함 (2026-09-06 실측) ────────────────
  #
  # 뮤테이션 스크립트가 `cp` 백업 → `mv` 복원을 쓰면 파일의 **mtime 이 백업 시각으로 되돌아간다.**
  # 크기까지 같은 뮤턴트(«제5호»↔«제1호» 는 바이트 수가 같다)면 (mtime,size) 로 키를 잡는
  # 컴파일 캐시가 **뮤턴트 바이트코드를 계속 물고 있다.** 그러면 그 뒤의 모든 뮤턴트가
  # 이미 빨간 베이스라인 위에서 «KILLED» 로 보인다 — 죽인 게 아니라 원래 죽어 있었다.
  # 실측: 복원 직후 파일에는 제5호가 있는데 실행 결과는 제1호 뮤턴트였다.
  test "뮤테이션 하네스는 복원 시 mtime 도 되돌린다(touch)" do
    scripts = Dir[Rails.root.join("docs/silmu-p2/**/_measure/mutation_*.sh")]
    assert_operator scripts.size, :>=, 4, "뮤테이션 스크립트를 못 찾았다"
    scripts.each do |f|
      src = File.read(f)
      assert_match(/touch "\$/, src,
                   "#{rel(f)}: 복원 후 touch 가 없다 — 크기 같은 뮤턴트가 캐시에 남는다")
      assert_includes src, "BASELINE_RED", "#{rel(f)}: 베이스라인 확인이 없다"
    end
  end

  # ── 검증기(정답 원천) 별도 확인 ───────────────────────────────
  test "검증기는 금액 기준의 «정답» 으로 제1호를 가르치지 않는다" do
    sources = BlogLegalVerifier::AMOUNT_CHECKS.map { |r| r[:source] }
    assert_empty sources.select { |s| s.include?("제25조 제1항 제1호") },
                 "검증기가 §25①1호를 금액 기준으로 가르친다"
    assert_equal 3, sources.count { |s| s.include?("제25조 제1항 제5호") },
                 "§25 금액 룰 3건이 제5호를 가리키지 않는다"
    assert_equal 2, sources.count { |s| s.include?("제30조") }, "§30 룰이 함께 옮겨졌다"
    # 계약유형만으로 목이 정해지는 축만 목을 붙였다
    assert_includes sources, "「지방자치단체를 당사자로 하는 계약에 관한 법률 시행령」 제25조 제1항 제5호 나목"
    assert_equal 2, sources.count { |s| s.end_with?("제25조 제1항 제5호 가목") }
  end
end
