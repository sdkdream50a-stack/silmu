import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { topicSlug: String }

  track(event) {
    const slot = event.params.slot
    if (typeof gtag === "function") {
      gtag("event", "next_action_click", {
        topic_slug: this.topicSlugValue,
        slot: slot
      })
    }
  }
}
