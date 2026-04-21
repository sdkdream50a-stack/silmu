# frozen_string_literal: true

# blog_autopilot 전용 Topic 생성·수정 API
# POST /api/v1/topics        — 신규 생성
# PATCH /api/v1/topics/:slug — 기존 수정
# Authorization: Bearer <BLOG_API_KEY>
module Api
  module V1
    class TopicsController < ActionController::API
      before_action :authenticate_api_key!
      before_action :find_topic, only: [ :update ]

      # POST /api/v1/topics
      def create
        topic = Topic.new(topic_params)
        topic.published = params[:published].nil? ? false : ActiveModel::Type::Boolean.new.cast(params[:published])

        if topic.save
          render json: topic_response(topic), status: :created
        else
          render json: { error: topic.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/topics/:slug
      def update
        if @topic.update(topic_params)
          render json: topic_response(@topic), status: :ok
        else
          render json: { error: @topic.errors.full_messages.join(", ") }, status: :unprocessable_entity
        end
      end

      private

      def topic_params
        params.permit(
          :name, :slug, :category, :sector, :summary, :keywords,
          :law_content, :decree_content, :rule_content,
          :interpretation_content, :commentary, :practical_tips,
          :qa_content, :faqs, :flowchart_mermaid,
          :parent_id, :published
        )
      end

      def find_topic
        @topic = Topic.find_by!(slug: params[:slug])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "토픽을 찾을 수 없습니다: #{params[:slug]}" }, status: :not_found
      end

      def topic_response(topic)
        {
          id: topic.id,
          slug: topic.slug,
          name: topic.name,
          category: topic.category,
          published: topic.published,
          url: "https://silmu.kr/topics/#{topic.slug}"
        }
      end

      def authenticate_api_key!
        token = request.headers["Authorization"].to_s.delete_prefix("Bearer ").strip
        expected = Rails.application.credentials.dig(:blog_api, :key).to_s.presence ||
                   ENV["BLOG_API_KEY"].to_s

        unless expected.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected)
          render json: { error: "인증 실패" }, status: :unauthorized
        end
      end
    end
  end
end
