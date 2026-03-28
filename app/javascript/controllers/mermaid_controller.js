import { Controller } from "@hotwired/stimulus"

// Mermaid.js 다이어그램 렌더링 컨트롤러
// flowchart_mermaid 필드에 저장된 Mermaid 코드를 SVG로 변환
// CDN 동적 로드 방식으로 메인 번들 크기에 영향 없음

export default class extends Controller {
  static targets = ["source"]

  async connect() {
    if (this.sourceTargets.length === 0) return
    try {
      await this.loadMermaid()
      await this.renderAll()
    } catch (error) {
      console.error("[MermaidController] 플로차트 로드 실패:", error)
      this.showFallback()
    }
  }

  async loadMermaid() {
    if (window.__mermaidLoaded) return
    const mod = await import("https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs")
      .catch(() => { throw new Error("Mermaid CDN 로드 실패") })
    window.mermaid = mod.default
    window.mermaid.initialize({
      startOnLoad: false,
      theme: "base",
      themeVariables: {
        primaryColor: "#eef2ff",
        primaryBorderColor: "#6366f1",
        primaryTextColor: "#1e293b",
        secondaryColor: "#ecfdf5",
        secondaryBorderColor: "#10b981",
        tertiaryColor: "#fef3c7",
        lineColor: "#94a3b8",
        fontSize: "14px"
      },
      flowchart: {
        curve: "basis",
        padding: 16,
        useMaxWidth: true
      }
    })
    window.__mermaidLoaded = true
  }

  async renderAll() {
    for (const el of this.sourceTargets) {
      const code = el.textContent.trim()
      if (!code) continue
      const id = `mermaid-${Math.random().toString(36).slice(2, 9)}`
      try {
        const { svg } = await window.mermaid.render(id, code)
        // SVG를 새 div로 교체 (pre 요소 대신)
        const wrapper = document.createElement("div")
        wrapper.className = "mermaid-diagram overflow-x-auto"
        wrapper.innerHTML = svg
        el.replaceWith(wrapper)
      } catch (e) {
        console.warn("[Mermaid] 렌더링 오류:", e)
        el.className = "p-4 bg-red-50 rounded-xl text-sm text-red-600"
        el.textContent = "다이어그램 렌더링 중 오류가 발생했습니다."
      }
    }
  }

  // CDN 로드 실패 시 fallback: 원본 코드를 텍스트로 표시
  showFallback() {
    for (const el of this.sourceTargets) {
      const code = el.textContent.trim()
      const escapedCode = code
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")

      const wrapper = document.createElement("div")
      wrapper.innerHTML = `
        <div class="bg-amber-50 border border-amber-200 rounded-lg p-4 text-sm">
          <p class="text-amber-800 font-medium mb-2">⚠️ 플로차트를 표시할 수 없습니다</p>
          <p class="text-amber-700 text-xs mb-3">네트워크 연결을 확인하거나 잠시 후 새로고침해주세요.</p>
          ${escapedCode ? `<pre class="text-xs text-gray-600 bg-gray-50 p-3 rounded overflow-auto whitespace-pre-wrap">${escapedCode}</pre>` : ""}
        </div>
      `
      el.replaceWith(wrapper)
    }
  }
}
