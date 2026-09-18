require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Silmu
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Seoul"
    # 서브도메인 파싱: "silmu.kr" → tld=1 (exam.silmu.kr 지원)
    config.action_dispatch.tld_length = 1
    # 세션 쿠키를 .silmu.kr 전체에서 공유 (silmu.kr ↔ exam.silmu.kr 로그인 공유)
    config.session_store :cookie_store, key: "_silmu_session", domain: ".silmu.kr", same_site: :lax
    # Rate Limiting — 미들웨어 등록은 rack-attack gem 의 railtie 가 한다
    #   (rack/attack/railtie.rb: initializer "rack-attack.middleware" → app.middleware.use(Rack::Attack)).
    # 여기서 한 번 더 use 하면 스택에 **두 개**가 쌓인다(2026-09-18 실측: middleware 목록에 2회 · G-62).
    # 두 번째 인스턴스는 `rack.attack.called` 가드에 걸려 그냥 통과하므로 이중 카운트는 없었지만,
    # 요청마다 쓸모없는 미들웨어를 한 겹 더 지나고 스택을 읽는 사람을 헷갈리게 한다.
    # 규칙은 config/initializers/rack_attack.rb 가 소유한다 — 등록을 지워도 규칙은 그대로다.
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
