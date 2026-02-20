// Created: 2026-02-20 23:25
// Updated: 2026-02-20 23:40
// Iconify 자동 변환 컨트롤러
// Material Symbols 클래스를 Iconify로 자동 변환 (1.1MB → 50KB)

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Iconify 스크립트가 로드될 때까지 대기
    this.waitForIconify()
  }

  waitForIconify() {
    if (typeof Iconify !== 'undefined') {
      this.convertIcons()
    } else {
      // Iconify가 아직 로드되지 않았으면 100ms 후 재시도
      setTimeout(() => this.waitForIconify(), 100)
    }
  }

  convertIcons() {
    // 모든 material-symbols-outlined 요소 찾기
    const icons = document.querySelectorAll('.material-symbols-outlined:not([data-icon])')

    icons.forEach(icon => {
      const iconName = icon.textContent.trim()

      if (iconName) {
        // Material Symbols 이름을 Iconify 형식으로 변환
        // 예: arrow_forward → material-symbols:arrow-forward
        const iconifyName = iconName.replace(/_/g, '-')

        // Iconify 속성 설정
        icon.setAttribute('data-icon', `material-symbols:${iconifyName}`)
        icon.textContent = '' // 텍스트 제거

        // Iconify에 새 아이콘 스캔 요청
        if (typeof Iconify !== 'undefined' && Iconify.scan) {
          Iconify.scan(icon)
        }
      }
    })
  }
}
