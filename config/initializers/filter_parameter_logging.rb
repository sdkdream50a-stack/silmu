# Be sure to restart your server when you modify this file.

# Configure parameters to be partially matched (e.g. passw matches password) and filtered from the log file.
# Use this to limit dissemination of sensitive information.
# See the ActiveSupport::ParameterFilter documentation for supported notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
]

# 검색어·질문·급여 입력을 로그에서 지운다 (P1-9 · LECTURE_READINESS_AUDIT).
#   · `q`        — 통합검색·실무검색 질의. 사용자가 무엇을 입력하는지 통제할 수 없다.
#   · `question` — AI 어시스턴트 입력. 외부 API 로도 나가므로 최소한 로그에는 남기지 않는다.
#   · `content`·`memo` — 자유 입력 본문.
#   · `monthly_wage`·`hire_date` — 급여 도구 입력. 개인 식별로 이어질 수 있는 값이다.
#
# ⚠️ `filter_parameters` 의 심볼·문자열은 **부분일치**다(`:passw` 가 `password` 를 잡는 그 규칙).
#    `:q` 를 넣으면 `quantity`·`quote_id`·`request_id` 까지 전부 `[FILTERED]` 가 된다(실측).
#    한 글자짜리 키는 반드시 앵커 정규식으로 적는다.
#
# lograge 의 `custom_options` 는 `event.payload[:params]` 를 쓰는데, Rails 8 의
# ActionController::Instrumentation 이 그것을 `request.filtered_parameters` 로 채우므로
# 이 목록에 넣으면 lograge 출력에도 그대로 적용된다(actionpack instrumentation.rb:66).
Rails.application.config.filter_parameters += [
  /\Aq\z/, :question, :content, :memo, :monthly_wage, :hire_date
]
