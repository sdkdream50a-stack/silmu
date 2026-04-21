require "test_helper"

class SitemapPingEngineJobTest < ActiveSupport::TestCase
  test "host별로 그룹핑하여 submit_indexnow 호출 (silmu.kr + exam.silmu.kr)" do
    captured = []

    # submit_indexnow를 스파이로 교체 — 실제 네트워크 호출 없이 인자만 관찰
    SitemapPingEngineJob.class_eval do
      alias_method :__orig_submit_indexnow, :submit_indexnow unless private_method_defined?(:__orig_submit_indexnow)
      define_method(:submit_indexnow) { |engine, host, urls| captured << [engine, host, urls]; :ok }
    end

    begin
      SitemapPingEngineJob.perform_now("www.bing.com", [
        "https://silmu.kr/topics/a",
        "https://silmu.kr/topics/b",
        "https://exam.silmu.kr/"
      ])
    ensure
      SitemapPingEngineJob.class_eval do
        alias_method :submit_indexnow, :__orig_submit_indexnow if private_method_defined?(:__orig_submit_indexnow)
      end
    end

    assert_equal 2, captured.size, "host가 2개면 submit_indexnow도 2회 호출"

    silmu_call = captured.find { |c| c[1] == "silmu.kr" }
    exam_call  = captured.find { |c| c[1] == "exam.silmu.kr" }

    assert silmu_call, "silmu.kr 호출이 존재해야 함"
    assert exam_call,  "exam.silmu.kr 호출이 존재해야 함"

    assert_equal "www.bing.com", silmu_call[0]
    assert_equal %w[https://silmu.kr/topics/a https://silmu.kr/topics/b].sort, silmu_call[2].sort
    assert_equal ["https://exam.silmu.kr/"], exam_call[2]
  end
end
