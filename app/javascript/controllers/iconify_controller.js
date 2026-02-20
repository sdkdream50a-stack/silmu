// Created: 2026-02-20 23:25
// Iconify 자동 변환 컨트롤러
// Material Symbols 클래스를 Iconify로 자동 변환 (1.1MB → 50KB)

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.convertIcons()
  }

  convertIcons() {
    // 모든 material-symbols-outlined 요소 찾기
    const icons = document.querySelectorAll('.material-symbols-outlined:not(.iconify)')

    icons.forEach(icon => {
      const iconName = icon.textContent.trim()

      if (iconName) {
        // Material Symbols 이름을 Iconify 형식으로 변환
        // 예: arrow_forward → material-symbols:arrow-forward
        const iconifyName = iconName.replace(/_/g, '-')

        // Iconify 속성 설정
        icon.classList.add('iconify')
        icon.setAttribute('data-icon', `material-symbols:${iconifyName}`)
        icon.textContent = '' // 텍스트 제거
      }
    })
  }
}
