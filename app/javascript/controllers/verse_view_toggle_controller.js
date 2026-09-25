import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardView", "listView", "toggleButton"]
  
  static values = {
    defaultView: { type: String, default: "card" }
  }

  connect() {
    this.applySavedView()
  }

  // Re-apply when turbo frame swaps skeleton → annotated content.
  cardViewTargetConnected() {
    this.applySavedView()
  }

  listViewTargetConnected() {
    this.applySavedView()
  }

  toggle(event) {
    event.preventDefault()
    if (!this.hasCardViewTarget || !this.hasListViewTarget) return

    const currentView = this.cardViewTarget.classList.contains("hidden") ? "list" : "card"
    const newView = currentView === "card" ? "list" : "card"
    this.switchView(newView)
  }

  applySavedView() {
    if (!this.hasCardViewTarget || !this.hasListViewTarget) return

    const savedView = localStorage.getItem("verseViewMode") || this.defaultViewValue
    this.switchView(savedView)
  }

  switchView(view) {
    if (!this.hasCardViewTarget || !this.hasListViewTarget) return

    if (view === "card") {
      this.cardViewTarget.classList.remove("hidden")
      this.listViewTarget.classList.add("hidden")
      if (this.hasToggleButtonTarget) {
        this.toggleButtonTarget.textContent = "Switch to List View"
      }
      localStorage.setItem("verseViewMode", "card")
    } else {
      this.cardViewTarget.classList.add("hidden")
      this.listViewTarget.classList.remove("hidden")
      if (this.hasToggleButtonTarget) {
        this.toggleButtonTarget.textContent = "Switch to Card View"
      }
      localStorage.setItem("verseViewMode", "list")
    }
  }
}

