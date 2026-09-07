# frozen_string_literal: true

# .kamal/hooks/pre-deploy 의 판별력 회귀.
#
# 이 테스트는 Rails 를 띄우지 않는다(test_helper 미사용) — 대상이 셸 게이트이기 때문이다.
#   단독 실행: ruby -Itest test/scripts/deploy_preflight_test.rb
#   CI:        bin/rails test 가 test/**/*_test.rb 로 함께 수집한다.
#
# 게이트의 외부 의존(gh · ssh)은 PATH 앞에 shim 을 놓아 대체한다 — 게이트 코드에 테스트 전용
# 분기를 넣지 않기 위해서다. git 은 실물을 쓴다(계보 판정이 진짜여야 의미가 있다).

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "json"
require "open3"

class DeployPreflightTest < Minitest::Test
  REPO_ROOT = File.expand_path("../..", __dir__)
  HOOK = ENV.fetch("SILMU_PREFLIGHT_HOOK", File.join(REPO_ROOT, ".kamal/hooks/pre-deploy"))

  GREEN = %w[test lint scan_ruby].map { |n| { "name" => n, "started_at" => "2026-09-07T00:00:00Z", "conclusion" => "success" } }
  PROD_IMAGE_PREFIX = "ghcr.io/sdkdream50a-stack/silmu:"

  def setup
    @dir = Dir.mktmpdir("silmu-preflight")
    @upstream = File.join(@dir, "upstream")
    @checkout = File.join(@dir, "checkout")
    @shim = File.join(@dir, "shim")
    build_upstream
    build_checkout
    build_shims
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  # ── positive control ────────────────────────────────────────────────
  def test_pc1_clean_checkout_at_green_main_tip_passes
    out, status = run_hook(target: @main_tip)
    assert status.success?, "expected PASS, got:\n#{out}"
    assert_includes out, "PREFLIGHT_PASS"
    assert_includes out, @main_tip
  end

  # ── negative controls ───────────────────────────────────────────────
  def test_nc1a_implicit_target_is_blocked
    # 역사적 사고의 형태: 옛 리비전에 머문 checkout 에서 그냥 kamal deploy 를 부른 경우.
    checkout_detached(@old_commit)
    out, status = run_hook(target: nil)
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G1_TARGET_MISMATCH"
  end

  def test_nc1b_target_not_matching_head_is_blocked
    out, status = run_hook(target: @old_commit) # HEAD 는 여전히 main tip
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G1_TARGET_MISMATCH"
  end

  def test_nc3a_nonexistent_sha_is_blocked
    out, status = run_hook(target: "0" * 40)
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G1_TARGET_MISMATCH"
  end

  def test_nc2_dirty_checkout_is_blocked
    File.write(File.join(@checkout, "README.md"), "dirty\n")
    out, status = run_hook(target: @main_tip)
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G2_DIRTY"
  end

  def test_nc3b_commit_off_main_lineage_is_blocked
    side = git(@checkout, "commit --allow-empty -q -m side && git -C #{@checkout} rev-parse HEAD").strip
    out, status = run_hook(target: side)
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G3_NOT_MAIN_LINEAGE"
  end

  def test_nc4a_failed_required_check_is_blocked
    checks = GREEN.map { |c| c["name"] == "lint" ? c.merge("conclusion" => "failure") : c }
    out, status = run_hook(target: @main_tip, checks: checks)
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G4_CI_NOT_GREEN"
    assert_includes out, "lint"
  end

  def test_nc4b_missing_required_check_is_blocked
    out, status = run_hook(target: @main_tip, checks: GREEN.reject { |c| c["name"] == "scan_ruby" })
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G4_CI_NOT_GREEN"
    assert_includes out, "scan_ruby"
  end

  def test_nc4c_pending_required_check_is_blocked
    checks = GREEN.map { |c| c["name"] == "test" ? c.merge("conclusion" => nil) : c }
    out, status = run_hook(target: @main_tip, checks: checks)
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G4_CI_NOT_GREEN"
  end

  def test_nc4d_stale_green_run_does_not_mask_newer_failure
    # 같은 이름이 두 번 돌았고 최신이 실패면 실패로 읽어야 한다.
    checks = GREEN + [ { "name" => "test", "started_at" => "2026-09-08T00:00:00Z", "conclusion" => "failure" } ]
    out, status = run_hook(target: @main_tip, checks: checks)
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G4_CI_NOT_GREEN"
  end

  def test_nc5_unresolvable_rollback_is_blocked
    out, status = run_hook(target: @main_tip, prod_image: "#{PROD_IMAGE_PREFIX}latest")
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G5_ROLLBACK_UNKNOWN"
  end

  def test_nc6_missing_secret_path_is_blocked
    FileUtils.rm_f(File.join(@checkout, ".kamal/secrets"))
    out, status = run_hook(target: @main_tip)
    refute status.success?
    assert_includes out, "PREFLIGHT_BLOCK=G6_SECRET_PATH_INVALID"
  end

  def test_secret_values_are_never_printed
    out, = run_hook(target: @main_tip)
    refute_includes out, "SUPER_SECRET_VALUE"
  end

  private
    def run_hook(target:, checks: GREEN, prod_image: "#{PROD_IMAGE_PREFIX}#{'a' * 40}")
      File.write(File.join(@dir, "checks.json"), JSON.dump({ "check_runs" => checks }))
      env = {
        "PATH" => "#{@shim}:#{ENV['PATH']}",
        "FAKE_CHECKS_FILE" => File.join(@dir, "checks.json"),
        "FAKE_PROD_IMAGE" => prod_image
      }
      env["DEPLOY_TARGET_SHA"] = target if target
      out, status = Open3.capture2e(env, HOOK, chdir: @checkout)
      [ out, status ]
    end

    def build_upstream
      FileUtils.mkdir_p(@upstream)
      git(@upstream, "init -q -b main")
      git(@upstream, "config user.email t@example.com && git -C #{@upstream} config user.name t")
      File.write(File.join(@upstream, "README.md"), "silmu\n")
      git(@upstream, "add -A && git -C #{@upstream} commit -q -m first")
      @old_commit = git(@upstream, "rev-parse HEAD").strip
      git(@upstream, "commit --allow-empty -q -m second")
      @main_tip = git(@upstream, "rev-parse HEAD").strip
    end

    def build_checkout
      system("git clone -q #{@upstream} #{@checkout}", exception: true)
      git(@checkout, "config user.email t@example.com && git -C #{@checkout} config user.name t")
      # 원격 «신원»은 GitHub slug 여야 하고(게이트가 여기서 repo 를 유도한다),
      # 실제 fetch 는 로컬 fixture 로 가야 한다 — insteadOf 가 그 둘을 갈라 준다.
      git(@checkout, "config url.#{@upstream}.insteadOf https://github.com/sdkdream50a-stack/silmu.git")
      git(@checkout, "remote set-url origin https://github.com/sdkdream50a-stack/silmu.git")
      checkout_detached(@main_tip)

      FileUtils.mkdir_p(File.join(@checkout, ".kamal/hooks"))
      FileUtils.mkdir_p(File.join(@checkout, "config"))
      File.write(File.join(@checkout, ".kamal/secrets"), "SOME_KEY=SUPER_SECRET_VALUE\n")
      File.write(File.join(@checkout, "config/master.key"), "SUPER_SECRET_VALUE\n")
      File.write(File.join(@checkout, "config/deploy.yml"), <<~YML)
        service: silmu
        servers:
          web:
            - 203.0.113.10
        ssh:
          port: 2222
      YML
      # 위 파일들은 실제 repo 에서 gitignore 되지만 fixture 저장소에는 그 규칙이 없다 —
      # G2(dirty) 를 의도치 않게 때리지 않도록 여기서 무시 규칙을 만들어 준다.
      File.write(File.join(@checkout, ".git/info/exclude"), <<~EX)
        .kamal/
        config/
      EX
    end

    def checkout_detached(sha)
      git(@checkout, "checkout -q --detach #{sha}")
    end

    def build_shims
      FileUtils.mkdir_p(@shim)
      write_shim("gh", <<~SH)
        #!/usr/bin/env bash
        # 이 테스트가 쓰는 유일한 형태: gh api repos/<slug>/commits/<sha>/check-runs --paginate
        cat "$FAKE_CHECKS_FILE"
      SH
      write_shim("ssh", <<~SH)
        #!/usr/bin/env bash
        echo "$FAKE_PROD_IMAGE"
      SH
    end

    def write_shim(name, body)
      path = File.join(@shim, name)
      File.write(path, body)
      FileUtils.chmod(0o755, path)
    end

    def git(dir, args)
      out, status = Open3.capture2e("git -C #{dir} #{args}")
      raise "git #{args} failed in #{dir}:\n#{out}" unless status.success?
      out
    end
end
