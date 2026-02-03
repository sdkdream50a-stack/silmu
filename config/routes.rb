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
  get "guides/contract-flow", to: "guides#contract_flow", as: :contract_flow
  get "guides/pre-contract-checklist", to: "guides#pre_contract_checklist", as: :pre_contract_checklist
  get "guides/resources", to: "guides#resources", as: :guide_resources

  # 실무 도구
  get "tools", to: "tools#index", as: :tools
  get "tools/travel-calculator", to: "tools#travel_calculator", as: :travel_calculator

  # PDF 도구
  get "tools/pdf", to: "pdf_tools#index", as: :pdf_tools
  post "pdf_tools/split", to: "pdf_tools#split"
  post "pdf_tools/merge", to: "pdf_tools#merge"
  post "pdf_tools/add_page_numbers", to: "pdf_tools#add_page_numbers"
  post "pdf_tools/info", to: "pdf_tools#info"

  # 소요예산 추정기
  get "tools/budget-estimator", to: "estimations#index", as: :budget_estimator
  post "estimations/calculate", to: "estimations#calculate"

  # 계약서류 원클릭 생성기
  get "tools/contract-documents", to: "contract_documents#index", as: :contract_documents
  get "contract-documents/documents/:type", to: "contract_documents#documents", as: :contract_documents_by_type
  post "contract-documents/generate", to: "contract_documents#generate"

  # 계약방식 결정 도구
  get "tools/contract-method", to: "contract_methods#index", as: :contract_method
  post "contract-methods/determine", to: "contract_methods#determine"
  get "contract-methods/table/:type", to: "contract_methods#table", as: :contract_method_table

  # 커뮤니티
  get "community", to: "community#index", as: :community

  # 마이페이지
  get "mypage", to: "mypage#index", as: :mypage

  # 서비스 소개
  get "about", to: "home#about", as: :about
end
