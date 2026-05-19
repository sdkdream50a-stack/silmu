# P8 ROI 계측 — GA4 커스텀 이벤트 발화 헬퍼
#
# 사용처: Topic/AuditCase show 뷰 끝에서 ContentMigration 영향 슬러그면 발화.

module AnalyticsHelper
  # content_type: "topic" | "audit_case"
  def roi_content_migration_tag(content_type:, slug:)
    affected = case content_type
               when "topic"      then Analytics::RoiScope.affected_topic?(slug)
               when "audit_case" then Analytics::RoiScope.affected_audit_case?(slug)
               else false
               end
    return "" unless affected

    payload = { content_type: content_type, slug: slug }.to_json
    content_tag(:script, raw(<<~JS), type: "text/javascript")
      (function(){
        if (typeof gtag === 'function') {
          gtag('event', 'content_migration_view', #{payload});
        }
      })();
    JS
  end
end
