import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { topicSlug: String }

  track(event) {
    const slot = event.params.slot
    if (typeof gtag === "function") {
      gtag("event", "next_action_click", {
        topic_slug: this.topicSlugValue,
        slot: slot,
        // GA 로드 전에 큐에 쌓인 클릭은 Turbo 이동 뒤에 처리된다 — 클릭한 페이지(UTM 포함)로 귀속을 고정한다.
        page_location: window.location.href
      })
    }
  }
}
