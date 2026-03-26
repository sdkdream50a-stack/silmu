// 가이드 AI 오디오 플레이어 (NotebookLM 오버뷰 등)
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "playBtn", "playIcon", "progressBar", "currentTime", "duration", "speed"]
  static values = { url: String }

  connect() {
    this.audioTarget.src = this.urlValue
    this.audioTarget.addEventListener("timeupdate", () => this.onTimeUpdate())
    this.audioTarget.addEventListener("loadedmetadata", () => this.onLoaded())
    this.audioTarget.addEventListener("ended", () => this.onEnded())
  }

  disconnect() {
    this.audioTarget.pause()
  }

  togglePlay() {
    if (this.audioTarget.paused) {
      this.audioTarget.play()
      this.playIconTarget.textContent = "pause"
      this.playBtnTarget.classList.replace("bg-emerald-600", "bg-amber-500")
    } else {
      this.audioTarget.pause()
      this.playIconTarget.textContent = "play_arrow"
      this.playBtnTarget.classList.replace("bg-amber-500", "bg-emerald-600")
    }
  }

  seek(e) {
    const rect = this.progressBarTarget.parentElement.getBoundingClientRect()
    const ratio = (e.clientX - rect.left) / rect.width
    this.audioTarget.currentTime = ratio * (this.audioTarget.duration || 0)
  }

  changeSpeed() {
    const speeds = [1, 1.25, 1.5, 2]
    const cur = this.audioTarget.playbackRate
    const next = speeds[(speeds.indexOf(cur) + 1) % speeds.length]
    this.audioTarget.playbackRate = next
    this.speedTarget.textContent = `${next}×`
  }

  onTimeUpdate() {
    const cur = this.audioTarget.currentTime
    const dur = this.audioTarget.duration || 0
    this.progressBarTarget.style.width = `${dur ? (cur / dur) * 100 : 0}%`
    if (this.hasCurrentTimeTarget) this.currentTimeTarget.textContent = this.fmt(cur)
  }

  onLoaded() {
    if (this.hasDurationTarget) this.durationTarget.textContent = this.fmt(this.audioTarget.duration)
  }

  onEnded() {
    this.playIconTarget.textContent = "play_arrow"
    this.playBtnTarget.classList.replace("bg-amber-500", "bg-emerald-600")
    this.progressBarTarget.style.width = "0%"
    this.audioTarget.currentTime = 0
  }

  fmt(sec) {
    if (!sec || isNaN(sec)) return "0:00"
    const m = Math.floor(sec / 60)
    const s = Math.floor(sec % 60).toString().padStart(2, "0")
    return `${m}:${s}`
  }
}
