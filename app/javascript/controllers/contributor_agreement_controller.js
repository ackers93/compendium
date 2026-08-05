import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submit"]

  connect() {
    this.sync()
  }

  sync() {
    if (!this.hasCheckboxTarget || !this.hasSubmitTarget) return
    this.submitTarget.disabled = !this.checkboxTarget.checked
  }
}
