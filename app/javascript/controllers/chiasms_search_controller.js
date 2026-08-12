import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["input", "form"]

  connect() {
    this.searchTimeout = null
  }

  disconnect() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }

  search(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.trim()

    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  performSearch(query) {
    const url = new URL(this.formTarget.action, window.location.origin)

    if (query.length > 0) {
      url.searchParams.set("search", query)
    } else {
      url.searchParams.delete("search")
    }

    window.history.pushState({}, "", url.toString())

    const frame = document.getElementById("chiasms-list")
    if (frame) {
      frame.src = url.toString()
    } else {
      Turbo.visit(url.toString())
    }
  }
}
