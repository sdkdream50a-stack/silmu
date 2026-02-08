import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    if (localStorage.getItem("silmu_utm_banner_dismissed")) {
      this.bannerTarget.remove()
    }
  }

  dismiss() {
    localStorage.setItem("silmu_utm_banner_dismissed", "true")
    this.bannerTarget.style.transition = "all 0.3s ease"
    this.bannerTarget.style.opacity = "0"
    this.bannerTarget.style.maxHeight = "0"
    this.bannerTarget.style.padding = "0"
    setTimeout(() => this.bannerTarget.remove(), 300)
  }
}
