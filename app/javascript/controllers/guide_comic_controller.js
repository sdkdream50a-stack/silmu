// 4단만화 — 패널 클릭 시 확대(lightbox) 지원
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay", "overlayImg"]

  open(e) {
    const src = e.currentTarget.querySelector("img")?.src
    if (!src || !this.hasOverlayTarget) return
    this.overlayImgTarget.src = src
    this.overlayTarget.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  close() {
    if (!this.hasOverlayTarget) return
    this.overlayTarget.classList.add("hidden")
    this.overlayImgTarget.src = ""
    document.body.style.overflow = ""
  }

  closeOnBackdrop(e) {
    if (e.target === this.overlayTarget) this.close()
  }
}
