import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rows", "row", "template"]

  addRow(event) {
    event.preventDefault()

    const index = this.rowTargets.length
    const html = this.templateTarget.innerHTML.replaceAll("__INDEX__", index)
    this.rowsTarget.insertAdjacentHTML("beforeend", html)
  }
}
