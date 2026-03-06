import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hint"]

  inputChanged() {
    if (this.inputTarget.value.trim().length >= 3) {
      this.hintTarget.classList.remove("hidden")
    } else {
      this.hintTarget.classList.add("hidden")
    }
  }

  blurred() {
    setTimeout(() => this.hintTarget.classList.add("hidden"), 200)
  }

  submit(event) {
    if (this.inputTarget.value.trim().length === 0) {
      event.preventDefault()
      this.inputTarget.focus()
    }
  }
}
