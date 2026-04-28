# frozen_string_literal: true

# Sprint #2-C — 토픽 행동 이벤트 수집 (batch 허용)
class TopicEventsController < ApplicationController
  protect_from_forgery with: :null_session # JS beacon — 비동기 batch 전송용
  skip_before_action :verify_authenticity_token, only: :create

  wrap_parameters false # JSON body 그대로 사용 (events 배열 보존)

  def create
    events = parse_events_from_request
    events = events.first(20)
    ip_hash = compute_ip_hash
    persisted = 0

    events.each do |raw|
      next unless raw.is_a?(Hash) || raw.is_a?(ActionController::Parameters)
      slug = raw["topic_slug"] || raw[:topic_slug]
      type = raw["event_type"] || raw[:event_type]
      val  = (raw["event_value"] || raw[:event_value]).to_i
      next unless slug.present? && TopicEvent::EVENT_TYPES.include?(type)

      TopicEvent.create(
        topic_slug: slug.to_s,
        event_type: type.to_s,
        event_value: val,
        ip_hash: ip_hash
      )
      persisted += 1
    end

    render json: { ok: true, persisted: persisted }, status: :created
  rescue => e
    Rails.logger.warn "[TopicEventsController] #{e.class}: #{e.message}"
    head :bad_request
  end

  private

  # JSON body 또는 form-encoded 모두 처리. sendBeacon은 application/json blob.
  def parse_events_from_request
    if request.content_type.to_s.include?("application/json")
      body = request.body.read
      return [] if body.blank?
      json = JSON.parse(body)
      return Array(json["events"]) if json.is_a?(Hash) && json["events"]
      return Array(json) if json.is_a?(Array)
      [ json ]
    else
      Array(params[:events]).presence || [ params.to_unsafe_h ]
    end
  rescue JSON::ParserError
    []
  end

  def compute_ip_hash
    raw = "#{request.remote_ip}|#{request.user_agent.to_s[0, 200]}"
    Digest::SHA256.hexdigest(raw)
  end
end
