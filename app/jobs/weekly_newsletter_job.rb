class WeeklyNewsletterJob < ApplicationJob
  queue_as :default

  CHECKPOINTS_CONFIG = YAML.load_file(
    Rails.root.join("config", "newsletter_checkpoints.yml"),
    permitted_classes: [],
    symbolize_names: false
  ).freeze

  def perform
    users = User.where(newsletter_agreed: true)
    return if users.none?

    subject = "📋 이번 주 계약 실무 체크포인트 — #{Time.zone.today.strftime("%m월 %d일")}주차"
    body = build_body

    users.find_each do |user|
      NewsletterMailer.send_newsletter(user, subject, body).deliver_later
    end
  end

  private

  def build_body
    month = Time.zone.today.month
    checkpoints = monthly_checkpoints(month)

    items_html = checkpoints.map do |item|
      "<li style='margin-bottom: 10px;'>#{item}</li>"
    end.join("\n")

    <<~HTML
      <h2 style="font-size: 20px; font-weight: 700; color: #1e3a5f; margin-bottom: 16px;">
        #{Time.zone.today.strftime("%m월 %d일")}주차 업무 체크포인트
      </h2>

      <p style="color: #374151; margin-bottom: 20px;">
        안녕하세요, 공무원 계약실무 가이드 <strong>실무.kr</strong>입니다.<br>
        이번 주 놓치지 말아야 할 계약 실무 핵심 체크포인트를 정리했습니다.
      </p>

      <div style="background: #f0f4ff; border-left: 4px solid #2563eb; padding: 20px; border-radius: 8px; margin-bottom: 24px;">
        <h3 style="font-size: 16px; font-weight: 700; color: #1e40af; margin: 0 0 12px;">📌 이번 주 핵심 체크리스트</h3>
        <ul style="color: #1f2937; padding-left: 20px; margin: 0; line-height: 1.8;">
          #{items_html}
        </ul>
      </div>

      <div style="display: flex; flex-direction: column; gap: 10px; margin-bottom: 24px;">
        <a href="https://silmu.kr/tools/task-calendar"
           style="display: inline-block; background: #2563eb; color: #ffffff; text-decoration: none; padding: 12px 20px; border-radius: 8px; font-weight: 600; font-size: 15px; text-align: center;">
          📅 업무달력 바로가기
        </a>
        <a href="https://silmu.kr/audit-cases"
           style="display: inline-block; background: #059669; color: #ffffff; text-decoration: none; padding: 12px 20px; border-radius: 8px; font-weight: 600; font-size: 15px; text-align: center;">
          🔍 감사사례 보기
        </a>
        <a href="https://silmu.kr/silmu-search"
           style="display: inline-block; background: #d97706; color: #ffffff; text-decoration: none; padding: 12px 20px; border-radius: 8px; font-weight: 600; font-size: 15px; text-align: center;">
          🔍 실무 검색하기
        </a>
      </div>

      <p style="color: #6b7280; font-size: 13px; border-top: 1px solid #e5e7eb; padding-top: 16px;">
        뉴스레터 수신을 원하지 않으시면
        <a href="https://silmu.kr/mypage" style="color: #2563eb;">마이페이지</a>에서 수신 해제하실 수 있습니다.
      </p>
    HTML
  end

  def monthly_checkpoints(month)
    config = CHECKPOINTS_CONFIG["checkpoints"]
    config[month] || config["default"] || []
  end
end
