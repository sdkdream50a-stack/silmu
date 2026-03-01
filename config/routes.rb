Rails.application.routes.draw do
  # exam.silmu.kr 서브도메인 — 공공조달관리사 시험 대비
  constraints subdomain: 'exam' do
    scope module: 'exam', as: 'exam' do
      root to: 'home#index'
      resources :subjects, only: [:index, :show] do
        resources :chapters, only: [:show], param: :number
      end
      get 'keywords', to: 'keywords#index', as: :keywords
      get 'quiz', to: 'quizzes#index', as: :quiz_index
      get 'quiz/subject/:subject_id/chapter/:chapter_num', to: 'quizzes#chapter', as: :quiz_chapter
      get 'quiz/mini', to: 'quizzes#mini', as: :quiz_mini
      get 'quiz/wrong', to: 'quizzes#wrong', as: :quiz_wrong
      get 'quiz/simulation', to: 'quizzes#simulation', as: :quiz_simulation
      get 'quiz/analysis', to: 'quizzes#analysis', as: :quiz_analysis
      get 'quiz/:id', to: 'quizzes#show', as: :quiz
      get 'exam-info', to: 'exam_info#index', as: :exam_info
      get 'exam-strategy', to: 'strategy#index', as: :exam_strategy
      get 'sitemap.xml', to: 'sitemap#index', defaults: { format: :xml }
    end
  end

  # Kamal 헬스체크용
  get "up" => "rails/health#show", as: :rails_health_check

  # SEO 최적화: 404 방지 리디렉션
  get "favicon.ico", to: redirect("/favicon.svg")
  get "audit_cases", to: redirect("/audit-cases", status: 301), as: :audit_cases_underscore
  get "audit_cases/:slug", to: redirect("/audit-cases/%{slug}", status: 301), as: :audit_case_underscore

  # SEO: POST 전용 엔드포인트 GET 접근 시 리디렉트 (Googlebot 404 방지)
  get "pdf_tools/split", to: redirect("/tools/pdf")
  get "pdf_tools/merge", to: redirect("/tools/pdf")
  get "pdf_tools/add_page_numbers", to: redirect("/tools/pdf")
  get "pdf_tools/info", to: redirect("/tools/pdf")
  get "estimations/calculate", to: redirect("/tools/budget-estimator")
  get "contract-documents/generate", to: redirect("/tools/contract-documents")
  get "contract-methods/determine", to: redirect("/tools/contract-method")
  get "cost-estimates/generate", to: redirect("/tools/cost-estimate")
  get "design-changes/generate", to: redirect("/tools/design-change")
  get "progress-inspections/generate", to: redirect("/tools/progress-inspection")
  get "quote-documents/extract", to: redirect("/tools/quote-auto")
  get "quote-reviews/analyze", to: redirect("/tools/quote-review")
  get "cost-calculations/review", to: redirect("/tools/cost-calculation")
  get "official-documents/generate", to: redirect("/tools/official-document")
  get "estimated-prices/calculate", to: redirect("/tools/estimated-price")
  get "legal-periods/calculate", to: redirect("/tools/legal-period")
  get "contract-guarantees/calculate", to: redirect("/tools/contract-guarantee")
  get "qualification-evaluations/evaluate", to: redirect("/tools/qualification-evaluation")
  get "document-analysis/analyze", to: redirect("/tools")
  get "cost-estimates/default-items", to: redirect("/tools/cost-estimate")

  devise_for :users
  root "home#index"

  # 챗봇
  get "chatbot", to: "chatbot#index", as: :chatbot
  get "chatbot/search", to: "chatbot#search", as: :chatbot_search
  get "chatbot/price", to: "chatbot#price_guide", as: :chatbot_price

  # 토픽 (법령 가이드)
  get "topics", to: "topics#index", as: :topics
  get "topics/:slug", to: "topics#show", as: :topic

  # 문서 양식
  resources :templates, only: [:index, :show]

  # 업무 가이드
  get "guides/contract-flow", to: "guides#contract_flow", as: :contract_flow
  get "guides/pre-contract-checklist", to: "guides#pre_contract_checklist", as: :pre_contract_checklist
  get "guides/resources", to: "guides#resources", as: :guide_resources
  resources :guides, only: [:index, :show], param: :slug

  # 업무달력 데이터 동기화
  resource :calendar_data, only: [:show, :update]

  # 업무 AI 가이드
  get "task_guides", to: "task_guides#show"

  # 실무 도구
  get "tools", to: "tools#index", as: :tools
  get "tools/travel-calculator", to: "tools#travel_calculator", as: :travel_calculator
  get "tools/task-calendar", to: "tools#task_calendar", as: :task_calendar

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

  # 물량내역서+시방서 생성기
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

  # 견적서 일괄 문서생성
  get "tools/quote-auto", to: "quote_documents#index", as: :quote_auto
  post "quote-documents/extract", to: "quote_documents#extract"

  # 견적서 검토 시스템 (로그인 불필요)
  get "tools/quote-review", to: "quote_reviews#index", as: :quote_review
  post "quote-reviews/analyze", to: "quote_reviews#analyze"

  # 사업계획서 생성기
  get "tools/project-plan", to: "project_plans#index", as: :project_plan

  # 공문서 AI 작성 도우미
  get "tools/official-document", to: "official_documents#index", as: :official_document
  post "official-documents/generate", to: "official_documents#generate"

  # 수의계약 사유서 생성기
  get "tools/contract-reason", to: "contract_reasons#index", as: :contract_reason

  # 예정가격 계산기
  get "tools/estimated-price", to: "estimated_prices#index", as: :estimated_price
  post "estimated-prices/calculate", to: "estimated_prices#calculate"

  # 법정기간 계산기
  get "tools/legal-period", to: "legal_periods#index", as: :legal_period
  post "legal-periods/calculate", to: "legal_periods#calculate"

  # 계약보증금 계산기
  get "tools/contract-guarantee", to: "contract_guarantees#index", as: :contract_guarantee
  post "contract-guarantees/calculate", to: "contract_guarantees#calculate"

  # 적격심사 자동 채점기
  get "tools/qualification-evaluation", to: "qualification_evaluations#index", as: :qualification_evaluation
  post "qualification-evaluations/evaluate", to: "qualification_evaluations#evaluate"

  # 4대보험 정산보험료 계산기
  get "tools/insurance-calculator", to: "insurance_calculators#index", as: :insurance_calculator

  # 예산 집행률 계산기
  get "tools/budget-execution-rate", to: "tools#budget_execution_rate", as: :budget_execution_rate

  # 예비비 한도 계산기
  get "tools/contingency-fund", to: "tools#contingency_fund", as: :contingency_fund

  # 초과근무수당 계산기
  get "tools/overtime-calculator", to: "tools#overtime_calculator", as: :overtime_calculator

  # 연가일수 계산기
  get "tools/annual-leave-calculator", to: "tools#annual_leave_calculator", as: :annual_leave_calculator

  # 퇴직금 계산기
  get "tools/severance-calculator", to: "tools#severance_calculator", as: :severance_calculator

  # 성과상여금 계산기
  get "tools/performance-bonus-calculator", to: "tools#performance_bonus_calculator", as: :performance_bonus_calculator

  # 감사사례
  get "audit-cases", to: "audit_cases#index", as: :audit_cases
  get "audit-cases/:slug", to: "audit_cases#show", as: :audit_case

  # FAQ
  get "faq", to: "faq#index", as: :faq

  # 문서 분석 (AI)
  post "document-analysis/analyze", to: "document_analysis#analyze"

  # 의견보내기
  get "feedback", to: "feedback#index", as: :feedback
  post "feedback", to: "feedback#create"

  # 마이페이지
  get "mypage", to: "mypage#index", as: :mypage

  # 서비스 소개
  get "about", to: "home#about", as: :about

  # 업데이트 소식
  get "updates", to: "home#updates", as: :updates

  # 법적 페이지
  get "privacy", to: "home#privacy", as: :privacy
  get "terms", to: "home#terms", as: :terms

  # 관리자
  namespace :admin do
    resources :newsletters, only: [:new, :create]
    get "analytics", to: "analytics#index", as: :analytics
  end

  # 사이트맵
  get "sitemap.xml", to: "sitemap#index", as: :sitemap, defaults: { format: :xml }

  # RSS 피드 (백링크·구독자 확보용)
  get "feed.rss", to: "feed#index", defaults: { format: :rss }, as: :feed
end
