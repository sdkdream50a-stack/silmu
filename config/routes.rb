Rails.application.routes.draw do
  devise_for :users
  root "home#index"

  # 챗봇
  get "chatbot", to: "chatbot#index", as: :chatbot
  get "chatbot/search", to: "chatbot#search", as: :chatbot_search
  get "chatbot/price", to: "chatbot#price_guide", as: :chatbot_price

  # 토픽 (법령 가이드)
  get "topics/:slug", to: "topics#show", as: :topic
end
