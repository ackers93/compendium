import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { active: String }

  connect() {
    this.show(this.activeValue || "comments")
  }

  select(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab
    this.show(tab)

    const url = new URL(window.location)
    url.searchParams.set("tab", tab)
    history.replaceState({}, "", url)
  }

  show(tab) {
    this.tabTargets.forEach((element) => {
      element.classList.toggle("active", element.dataset.tab === tab)
    })

    this.panelTargets.forEach((element) => {
      element.classList.toggle("active", element.dataset.tab === tab)
    })
  }
}
