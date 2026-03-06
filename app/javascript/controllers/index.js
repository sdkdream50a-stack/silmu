// Stimulus 컨트롤러 등록
// 경량 컨트롤러만 메인 번들에 포함
// 무거운 컨트롤러(exam, insurance)는 별도 JS 파일로 분리 → 해당 페이지에서만 로드

import { application } from "./application"

// --- 전역 경량 컨트롤러 ---
import MobileMenuController from "./mobile_menu_controller"
application.register("mobile-menu", MobileMenuController)

import UtmBannerController from "./utm_banner_controller"
application.register("utm-banner", UtmBannerController)

import TabsController from "./tabs_controller"
application.register("tabs", TabsController)

import HomeBookmarkController from "./home_bookmark_controller"
application.register("home-bookmark", HomeBookmarkController)

import HomePriceController from "./home_price_controller"
application.register("home-price", HomePriceController)

import HomeSearchController from "./home_search_controller"
application.register("home-search", HomeSearchController)

import HomeQuizController from "./home_quiz_controller"
application.register("home-quiz", HomeQuizController)

import MermaidController from "./mermaid_controller"
application.register("mermaid", MermaidController)

// --- 무거운 컨트롤러는 별도 entrypoint로 분리 ---
// exam_controllers.js → 모의고사 페이지에서 javascript_include_tag "exam_controllers"
// insurance_controller.js → 보험계산기 페이지에서 javascript_include_tag "insurance_controller"
// ExamProgressController는 exam_progress.js (이미 별도 entrypoint)
