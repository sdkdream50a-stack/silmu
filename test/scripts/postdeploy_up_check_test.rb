# frozen_string_literal: true

# bin/postdeploy-up-check 의 판별력 회귀 (2026-09-28 ad5270f 배포: 배포 성공 + 로컬 DNS exit 6 → «실패» 오판).
#
# Rails 를 띄우지 않는다 — 대상이 셸 스크립트다.
#   단독 실행: ruby -Itest test/scripts/postdeploy_up_check_test.rb
# curl · dig · ssh 는 PATH 앞 shim 으로 대체한다(스크립트에 테스트 분기를 넣지 않는다).

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "open3"

class PostdeployUpCheckTest < Minitest::Test
  SCRIPT = File.expand_path("../../bin/postdeploy-up-check", __dir__)

  def setup
    @dir = Dir.mktmpdir("silmu-upcheck")
    @plan = File.join(@dir, "curl_plan")
    shim "curl", <<~SH
      #!/usr/bin/env bash
      # --resolve 가 붙은 호출 = 공개 리졸버 경로
      for a in "$@"; do
        if [ "$a" = "--resolve" ]; then
          set -- ${FAKE_CURL_RESOLVED:-6 000}; printf '%s' "$2"; exit "$1"
        fi
      done
      line="$(head -1 "#{@plan}")"; tail -n +2 "#{@plan}" > "#{@plan}.n"; mv "#{@plan}.n" "#{@plan}"
      set -- ${line:-6 000}; printf '%s' "$2"; exit "$1"
    SH
    shim "dig", %(#!/usr/bin/env bash\n[ -n "${FAKE_DIG_IP:-}" ] && echo "$FAKE_DIG_IP"\nexit 0\n)
    shim "ssh", %(#!/usr/bin/env bash\nprintf '%s' "${FAKE_ORIGIN:-}"\n)
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  # ── DNS_NORMAL ──────────────────────────────────────────────────────
  def test_dns_normal_target_up
    out, st = run_check([ "0 200" ])
    assert st.success?, out
    assert_includes out, "UP_CHECK=TARGET_UP path=system_dns"
  end

  # ── DNS_TEMP_FAILURE (일시) → 재시도로 회복 ─────────────────────────
  def test_dns_temp_failure_recovers_on_retry
    out, st = run_check([ "6 000", "6 000", "0 200" ])
    assert st.success?, out
    assert_includes out, "attempt=3"
    assert_includes out, "UP_CHECK=TARGET_UP path=system_dns"
  end

  # ── DNS_TEMP_FAILURE (지속) → 공개 리졸버 경로로 확인 ───────────────
  def test_dns_persistent_failure_uses_fallback_resolver
    out, st = run_check([ "6 000" ] * 5, "FAKE_DIG_IP" => "203.0.113.7", "FAKE_CURL_RESOLVED" => "0 200")
    assert st.success?, out
    assert_includes out, "UP_CHECK=TARGET_UP path=fallback_resolver"
    assert_includes out, "local_dns=DNS_TEMP_FAILURE"
  end

  # ── DNS 전부 실패 + 원본 200 → 배포 성공, 공개 경로 미확인으로 표시 ─
  def test_dns_total_failure_origin_up_is_not_deploy_failure
    out, st = run_check([ "6 000" ] * 5, "PROD_HOST" => "prod", "FAKE_ORIGIN" => "200")
    assert st.success?, out
    assert_includes out, "UP_CHECK=DNS_TEMP_FAILURE origin=TARGET_UP public=UNVERIFIED_FROM_THIS_HOST"
  end

  # ── 음성 대조: TARGET_DOWN 은 여전히 실패여야 한다 ────────────────
  def test_target_down_http_fails
    out, st = run_check([ "0 502" ] * 5)
    refute st.success?, out
    assert_includes out, "UP_CHECK=TARGET_DOWN http=502"
  end

  def test_target_down_connect_refused_fails
    out, st = run_check([ "7 000" ] * 5)
    refute st.success?, out
    assert_includes out, "UP_CHECK=TARGET_DOWN curl_exit=7"
  end

  def test_fallback_resolver_non_200_fails
    out, st = run_check([ "6 000" ] * 5, "FAKE_DIG_IP" => "203.0.113.7", "FAKE_CURL_RESOLVED" => "0 503")
    refute st.success?, out
    assert_includes out, "UP_CHECK=TARGET_DOWN http=503"
  end

  def test_dns_total_failure_origin_down_fails
    out, st = run_check([ "6 000" ] * 5, "PROD_HOST" => "prod", "FAKE_ORIGIN" => "502")
    refute st.success?, out
    assert_includes out, "UP_CHECK=TARGET_DOWN origin_http=502"
  end

  def test_dns_total_failure_without_origin_check_fails
    out, st = run_check([ "6 000" ] * 5)
    refute st.success?, out
    assert_includes out, "UP_CHECK=DNS_TEMP_FAILURE origin=UNCHECKED"
  end

  private

  def shim(name, body)
    path = File.join(@dir, name)
    File.write(path, body)
    File.chmod(0o755, path)
  end

  def run_check(plan, env = {})
    File.write(@plan, plan.join("\n") + "\n")
    base = { "PATH" => "#{@dir}:#{ENV.fetch('PATH')}", "UP_BACKOFF" => "0", "UP_ATTEMPTS" => "5",
             "PROD_HOST" => nil, "FAKE_DIG_IP" => nil, "FAKE_CURL_RESOLVED" => nil, "FAKE_ORIGIN" => nil }
    Open3.capture2e(base.merge(env), SCRIPT)
  end
end
