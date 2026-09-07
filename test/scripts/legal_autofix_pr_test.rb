# frozen_string_literal: true

# bin/legal_autofix_pr 의 판별력 회귀 + legal_check 워크플로의 «main 직접 push 없음» 계약.
#
#   단독 실행: ruby -Itest test/scripts/legal_autofix_pr_test.rb
#   CI:        bin/rails test 가 test/**/*_test.rb 로 함께 수집한다.
#
# gh 는 PATH 앞 shim 으로 대체하고 git 은 실물을 쓴다 — 브랜치·원격 상태가 진짜여야
# «main 이 변하지 않았다» 를 실제로 잴 수 있기 때문이다.

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"

class LegalAutofixPrTest < Minitest::Test
  REPO_ROOT = File.expand_path("../..", __dir__)
  SCRIPT = File.join(REPO_ROOT, "bin/legal_autofix_pr")
  WORKFLOW = File.join(REPO_ROOT, ".github/workflows/legal_check.yml")

  def setup
    @dir = Dir.mktmpdir("legal-autofix")
    @origin = File.join(@dir, "origin.git")
    @work = File.join(@dir, "work")
    @shim = File.join(@dir, "shim")
    @ghlog = File.join(@dir, "gh_calls.log")
    @prstate = File.join(@dir, "open_prs.txt")

    sh("git init -q --bare -b main #{@origin}")
    sh("git init -q -b main #{@work}")
    git("config user.email seed@example.com")
    git("config user.name seed")
    File.write(File.join(@work, "config"), "v1\n")
    git("add -A"); git("commit -q -m seed")
    git("remote add origin #{@origin}")
    git("push -q origin main")
    @main_before = git("rev-parse HEAD").strip

    FileUtils.mkdir_p(@shim)
    File.write(File.join(@shim, "gh"), <<~SH)
      #!/usr/bin/env bash
      echo "$@" >> "$GH_LOG"
      if [ "$1" = "pr" ] && [ "$2" = "list" ]; then
        # --head <branch> 뒤의 값을 찾아 열린 PR 목록에서 조회
        head=""; prev=""
        for a in "$@"; do [ "$prev" = "--head" ] && head="$a"; prev="$a"; done
        grep -m1 "^$head " "$PR_STATE" 2>/dev/null | awk '{print $2}'
        exit 0
      fi
      if [ "$1" = "pr" ] && [ "$2" = "create" ]; then
        head=""; prev=""
        for a in "$@"; do [ "$prev" = "--head" ] && head="$a"; prev="$a"; done
        echo "$head 777" >> "$PR_STATE"
        exit 0
      fi
      exit 0
    SH
    FileUtils.chmod(0o755, File.join(@shim, "gh"))
    FileUtils.touch(@prstate)
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.exist?(@dir)
  end

  # ── 계약: 워크플로에 main 직접 push 경로가 없다 ──────────────────────
  def test_workflow_has_no_direct_main_push
    yml = File.read(WORKFLOW)
    refute_match(/^\s*git push\s*$/, yml, "bare `git push` (=현재 브랜치로 직접 push) 가 남아 있다")
    refute_match(/git push .*\bmain\b/, yml)
    assert_includes yml, "bin/legal_autofix_pr", "auto-fix 단계가 PR 스크립트를 호출해야 한다"
  end

  # ── 제어: 변경 없음 ────────────────────────────────────────────────
  def test_no_diff_creates_nothing
    out, status = run_script
    assert status.success?, out
    assert_includes out, "NO_DIFF"
    assert_equal @main_before, remote_main
    assert_equal [], remote_branches - [ "main" ]
    assert_equal "", gh_calls
  end

  # ── 제어: 변경 있음 → 브랜치 + PR ────────────────────────────────
  def test_diff_creates_branch_and_pr_but_never_touches_main
    File.write(File.join(@work, "config"), "v2\n")
    out, status = run_script
    assert status.success?, out
    assert_includes out, "PR_CREATED"
    assert_equal @main_before, remote_main, "main 이 변했다"
    assert_includes remote_branches, branch_name
    assert_equal 1, gh_calls.lines.count { |l| l.start_with?("pr create") }
  end

  # ── 제어: 두 번째 실행 → PR 중복 생성 0 ──────────────────────────
  def test_second_run_updates_the_same_pr_without_creating_a_duplicate
    File.write(File.join(@work, "config"), "v2\n")
    run_script
    File.write(File.join(@work, "config"), "v3\n")
    out, status = run_script
    assert status.success?, out
    assert_includes out, "PR_UPDATED #777"
    assert_equal 1, gh_calls.lines.count { |l| l.start_with?("pr create") }, "PR 이 두 번 생성됐다"
    assert_equal @main_before, remote_main
  end

  private
    def run_script
      env = { "PATH" => "#{@shim}:#{ENV['PATH']}", "GH_LOG" => @ghlog, "PR_STATE" => @prstate }
      Open3.capture2e(env, SCRIPT, chdir: @work)
    end

    def branch_name = "auto/legal-standards-#{Time.now.strftime('%Y-%m-%d')}"
    def remote_main = git("--git-dir=#{@origin} rev-parse main").strip
    def remote_branches = git("--git-dir=#{@origin} for-each-ref --format='%(refname:short)' refs/heads").split
    def gh_calls = File.exist?(@ghlog) ? File.read(@ghlog) : ""

    def sh(cmd)
      out, status = Open3.capture2e(cmd)
      raise "#{cmd} failed:\n#{out}" unless status.success?
      out
    end

    def git(args) = sh("git -C #{@work} #{args}")
end
