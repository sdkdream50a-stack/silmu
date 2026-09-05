# frozen_string_literal: true

# P1.55B §10 — 소스 장애 알림에 필요한 최소 상태 2개.
#
#   first_failed_at : 장애 episode 가 언제 시작됐는지 (지속 시간 관측용)
#   alerted_at      : 그 episode 에서 이미 알렸는지 (중복 발송 억제)
#
# 나머지(failure_count · last_failure_kind · last_success_at)는 이미 있다.
# 알림은 관측일 뿐이며 게시 콘텐츠를 건드리지 않는다.
#
# ADDITIVE ONLY / NULLABLE / NON-DESTRUCTIVE / REVERSIBLE
class AddFailureAlertStateToAuthoritySources < ActiveRecord::Migration[8.1]
  def change
    add_column :authority_sources, :first_failed_at, :datetime
    add_column :authority_sources, :alerted_at, :datetime
  end
end
