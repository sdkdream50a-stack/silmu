import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  bookmark() {
    alert("북마크 추가 방법:\n\nWindows: Ctrl+D\nmacOS: ⌘+D\n모바일: 브라우저 메뉴 > 북마크 추가")
  }
}
