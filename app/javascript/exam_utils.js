// exam.silmu.kr 공통 유틸리티 함수
// escapeHtml, getCsrfToken 등 여러 컨트롤러에서 공통으로 사용하는 함수 모음

/**
 * HTML 특수문자 이스케이프 (XSS 방지)
 * exam_quiz, exam_simulation, exam_flashcard 컨트롤러에서 공통 사용
 */
export function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
}

/**
 * CSRF 토큰 캐싱 조회
 * 매번 DOM querySelector 호출 대신 한 번만 조회하여 캐싱
 */
let _csrfToken = null

export function getCsrfToken() {
  if (_csrfToken === null) {
    _csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ''
  }
  return _csrfToken
}
