module Exam
  class ExplanationsController < ApplicationController
    layout false

    EXPLANATION_CACHE_TTL = 30.days

    def create
      question_id = params[:question_id].to_i
      selected_index = params[:selected_index].to_i

      q = ExamQuestion.find_question(question_id)
      return render json: { error: "문제를 찾을 수 없습니다." }, status: :not_found unless q

      cache_key = "exam_ai_explanation_v1_q#{question_id}_s#{selected_index}"

      explanation = Rails.cache.fetch(cache_key, expires_in: EXPLANATION_CACHE_TTL) do
        generate_ai_explanation(q, selected_index)
      end

      render json: { explanation: explanation }
    end

    private

    def generate_ai_explanation(q, selected_index)
      client = Anthropic::Client.new

      selected_option = q[:options][selected_index]
      correct_option = q[:options][q[:correct]]

      prompt = <<~PROMPT
        공공조달관리사 시험 문제 해설을 작성해주세요.

        문제: #{q[:question]}

        선택지:
        #{q[:options].each_with_index.map { |opt, i| "#{i + 1}. #{opt}#{i == selected_index ? ' (학습자 선택)' : ''}#{i == q[:correct] ? ' (정답)' : ''}" }.join("\n")}

        기존 해설: #{q[:explanation]}

        다음 내용을 포함하여 100~150자 내외로 추가 해설을 작성해주세요:
        1. 학습자가 선택한 "#{selected_option}"이 왜 틀렸는지 (해당하는 경우)
        2. 정답 "#{correct_option}"이 맞는 이유
        3. 관련 법령이나 실무 포인트 한 가지

        반드시 한국어로, 공무원/계약담당자가 이해하기 쉽게 작성하세요.
      PROMPT

      response = client.messages(
        model: "claude-haiku-4-5-20251001",
        max_tokens: 300,
        messages: [ { role: "user", content: prompt } ]
      )

      response.content.first.text
    rescue => e
      Rails.logger.error "AI explanation error: #{e.message}"
      "AI 해설을 불러오는 중 오류가 발생했습니다. 기존 해설을 참고하세요."
    end
  end
end
