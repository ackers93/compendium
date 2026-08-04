import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  connect() {
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    this.boundCloseOnEscape = this.closeOnEscape.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnClickOutside)
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.hidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.hidden = false
    this.buttonTarget.setAttribute("aria-expanded", "true")
    setTimeout(() => {
      document.addEventListener("click", this.boundCloseOnClickOutside)
      document.addEventListener("keydown", this.boundCloseOnEscape)
    }, 0)
  }

  close() {
    this.menuTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
    document.removeEventListener("click", this.boundCloseOnClickOutside)
    document.removeEventListener("keydown", this.boundCloseOnEscape)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
