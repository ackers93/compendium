import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["summary", "details"]

  toggle(event) {
    event.preventDefault()

    const expanding = this.detailsTarget.hidden
    this.detailsTarget.hidden = !expanding
    this.summaryTarget.hidden = expanding
  }
}
