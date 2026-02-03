Rails.application.routes.draw do
  devise_for :users
  root "home#index"

  # 챗봇
  get "chatbot", to: "chatbot#index", as: :chatbot
  get "chatbot/search", to: "chatbot#search", as: :chatbot_search
  get "chatbot/price", to: "chatbot#price_guide", as: :chatbot_price

  # 토픽 (법령 가이드)
  get "topics/:slug", to: "topics#show", as: :topic

  # 문서 양식
  resources :templates, only: [:index, :show]

  # 업무 가이드
  resources :guides, only: [:index, :show]

  # 실무 도구
  get "tools", to: "tools#index", as: :tools
  get "tools/travel-calculator", to: "tools#travel_calculator", as: :travel_calculator

  # PDF 도구
  get "tools/pdf", to: "pdf_tools#index", as: :pdf_tools
  post "pdf_tools/split", to: "pdf_tools#split"
  post "pdf_tools/merge", to: "pdf_tools#merge"
  post "pdf_tools/add_page_numbers", to: "pdf_tools#add_page_numbers"
  post "pdf_tools/info", to: "pdf_tools#info"

  # 커뮤니티
  get "community", to: "community#index", as: :community

  # 마이페이지
  get "mypage", to: "mypage#index", as: :mypage

  # 서비스 소개
  get "about", to: "home#about", as: :about
end
