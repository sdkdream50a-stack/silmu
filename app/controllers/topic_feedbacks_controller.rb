# frozen_string_literal: true

class TopicFeedbacksController < ApplicationController
  # 익명 허용 (비로그인도 1클릭 가능 — NN/g 응답률 권고)
  protect_from_forgery with: :exception

  def create
    topic_slug = params[:topic_slug].to_s
    rating     = params[:rating].to_i
    memo       = params[:memo].to_s.strip.presence

    unless Topic.exists?(slug: topic_slug)
      head :not_found and return
    end

    unless [ 0, 1 ].include?(rating)
      head :bad_request and return
    end

    ip_hash = compute_ip_hash

    if TopicFeedback.duplicate_within_24h?(topic_slug, ip_hash)
      respond_to do |format|
        format.html { redirect_to topic_path(topic_slug), notice: "이미 의견을 남기셨어요. 감사합니다 :)" }
        format.json { render json: { ok: false, reason: "duplicate" }, status: :conflict }
      end
      return
    end

    TopicFeedback.create!(
      topic_slug: topic_slug,
      rating: rating,
      memo: memo,
      user_id: current_user&.id,
      ip_hash: ip_hash
    )

    respond_to do |format|
      format.html { redirect_to topic_path(topic_slug), notice: "의견 감사합니다 — silmu 콘텐츠 개선에 반영하겠습니다." }
      format.json { render json: { ok: true }, status: :created }
    end
  end

  private

  def compute_ip_hash
    raw = "#{request.remote_ip}|#{request.user_agent.to_s[0, 200]}"
    Digest::SHA256.hexdigest(raw)
  end
end
