require "test_helper"

class SitemapPingJobTest < ActiveJob::TestCase
  test "24시간 내 변경 없으면 IndexNow 제출 잡 큐잉 안 함" do
    # 모든 Topic/AuditCase/Guide updated_at을 2일 전으로 이동
    Topic.published.update_all(updated_at: 2.days.ago)
    AuditCase.published.update_all(updated_at: 2.days.ago)
    Guide.published.update_all(updated_at: 2.days.ago) if defined?(Guide)

    assert_no_enqueued_jobs(only: SitemapPingEngineJob) do
      SitemapPingJob.perform_now
    end
  end

  test "24시간 내 변경 있으면 engine job이 큐잉되고 URL에 홈페이지 포함" do
    topic = Topic.published.first
    skip "published topic 없음" if topic.nil?

    topic.update!(updated_at: Time.current)

    captured_args = nil
    SitemapPingEngineJob.class_eval do
      alias_method :__orig_perform, :perform unless method_defined?(:__orig_perform)
      define_method(:perform) { |engine, urls| captured_args = [engine, urls] }
    end

    begin
      SitemapPingJob.perform_now
      perform_enqueued_jobs
    ensure
      SitemapPingEngineJob.class_eval do
        alias_method :perform, :__orig_perform if method_defined?(:__orig_perform)
      end
    end

    assert captured_args, "SitemapPingEngineJob이 실행되어야 함"
    assert_includes captured_args[1], "https://silmu.kr/",
                    "변경 URL이 있을 때 홈페이지도 함께 제출"
    assert(captured_args[1].any? { |u| u.include?("/topics/") }, "변경된 topic URL 포함")
  end
end
