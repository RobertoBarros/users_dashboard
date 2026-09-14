import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["link"]

  edit(event) {
    if (event.target.closest("a, button, input, select, textarea")) return
    if (window.getSelection().toString()) return

    this.linkTarget.click()
  }
}
