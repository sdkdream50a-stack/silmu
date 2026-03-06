// 4대보험 계산기 Stimulus 컨트롤러 (별도 번들)
// 보험 계산기 페이지에서만 <script> 태그로 로드
import { application } from "./controllers/application"

import InsuranceCalculatorController from "./controllers/insurance_calculator_controller"
application.register("insurance-calculator", InsuranceCalculatorController)
