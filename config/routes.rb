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
  get "guides/contract-flow", to: "guides#contract_flow", as: :contract_flow
  get "guides/pre-contract-checklist", to: "guides#pre_contract_checklist", as: :pre_contract_checklist
  get "guides/resources", to: "guides#resources", as: :guide_resources
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

  # 내역서+시공지시서 생성기
  get "tools/cost-estimate", to: "cost_estimates#index", as: :cost_estimate
  get "cost-estimates/default-items/:type", to: "cost_estimates#default_items", as: :cost_estimate_default_items
  post "cost-estimates/generate", to: "cost_estimates#generate"

  # 설계변경 검토서 도우미
  get "tools/design-change", to: "design_changes#index", as: :design_change
  get "design-changes/detail/:reason", to: "design_changes#detail", as: :design_change_detail
  post "design-changes/generate", to: "design_changes#generate"

  # 기성검사 체크리스트
  get "tools/progress-inspection", to: "progress_inspections#index", as: :progress_inspection
  post "progress-inspections/generate", to: "progress_inspections#generate"

  # 원가계산서 검토 가이드
  get "tools/cost-calculation", to: "cost_calculations#index", as: :cost_calculation
  post "cost-calculations/review", to: "cost_calculations#review"

  # 예정가격 계산기
  get "tools/estimated-price", to: "estimated_prices#index", as: :estimated_price
  post "estimated-prices/calculate", to: "estimated_prices#calculate"

  # 법정기간 계산기
  get "tools/legal-period", to: "legal_periods#index", as: :legal_period
  post "legal-periods/calculate", to: "legal_periods#calculate"

  # 계약보증금 계산기
  get "tools/contract-guarantee", to: "contract_guarantees#index", as: :contract_guarantee
  post "contract-guarantees/calculate", to: "contract_guarantees#calculate"

  # FAQ
  get "faq", to: "faq#index", as: :faq

  # 문서 분석 (AI)
  post "document-analysis/analyze", to: "document_analysis#analyze"

  # 커뮤니티
  get "community", to: "community#index", as: :community

  # 마이페이지
  get "mypage", to: "mypage#index", as: :mypage

  # 서비스 소개
  get "about", to: "home#about", as: :about
end
