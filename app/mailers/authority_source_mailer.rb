# frozen_string_literal: true

# P1.55B §10 — 공식 출처가 조용히 죽는 것을 막는다.
#
# 이 메일러는 **상태만 알린다.** 게시 콘텐츠를 수정하지 않으며,
# 구 `LegalComplianceMailer` / `LegalComplianceJob` 과 아무 결합이 없다.
class AuthoritySourceMailer < ApplicationMailer
  def failure_alert(source)
    @source = source
    @threshold = AuthoritySource::ALERT_THRESHOLD
    @degraded = source.failure_count >= AuthorityFreshnessCheckJob::MAX_CONSECUTIVE_FAILURES

    mail(
      to: ENV["ADMIN_EMAIL"] || "hello@silmu.kr",
      subject: "[실무.kr] ⚠️ 공식 출처 연속 실패 #{source.failure_count}회 — #{source.name}"
    )
  end
end
