import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardView", "listView", "toggleButton"]
  
  static values = {
    defaultView: { type: String, default: "card" }
  }

  connect() {
    // Load saved preference or use default
    const savedView = localStorage.getItem("verseViewMode") || this.defaultViewValue
    this.switchView(savedView)
  }

  toggle(event) {
    event.preventDefault()
    const currentView = this.cardViewTarget.classList.contains("hidden") ? "list" : "card"
    const newView = currentView === "card" ? "list" : "card"
    this.switchView(newView)
  }

  switchView(view) {
    if (view === "card") {
      this.cardViewTarget.classList.remove("hidden")
      this.listViewTarget.classList.add("hidden")
      this.toggleButtonTarget.textContent = "Switch to List View"
      localStorage.setItem("verseViewMode", "card")
    } else {
      this.cardViewTarget.classList.add("hidden")
      this.listViewTarget.classList.remove("hidden")
      this.toggleButtonTarget.textContent = "Switch to Card View"
      localStorage.setItem("verseViewMode", "list")
    }
  }
}

