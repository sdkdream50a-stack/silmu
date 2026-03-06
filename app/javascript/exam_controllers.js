// 모의고사 관련 Stimulus 컨트롤러 (별도 번들)
// 모의고사 페이지에서만 <script> 태그로 로드
import { application } from "./controllers/application"

import ExamQuizController from "./controllers/exam_quiz_controller"
application.register("exam-quiz", ExamQuizController)

import ExamSimulationController from "./controllers/exam_simulation_controller"
application.register("exam-simulation", ExamSimulationController)

import ExamAnalysisController from "./controllers/exam_analysis_controller"
application.register("exam-analysis", ExamAnalysisController)
