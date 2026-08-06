import { Controller } from "@hotwired/stimulus"

// Aligns range-bracket elbows with each ranged comment's connector line.
export default class extends Controller {
  connect() {
    this.sync = this.sync.bind(this)
    this.sync()
    this.resizeObserver = new ResizeObserver(this.sync)
    this.resizeObserver.observe(this.element)
    window.addEventListener("load", this.sync)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    window.removeEventListener("load", this.sync)
  }

  sync() {
    this.element.querySelectorAll(".verse-table-row").forEach((row) => {
      row.querySelectorAll(".ranged-comment-with-connector").forEach((wrap) => {
        const track = wrap.style.getPropertyValue("--range-track").trim()
        const connector = wrap.querySelector(".range-comment-connector")
        const railSlot = row.querySelector(`.range-rail-slot[data-track="${track}"]`)
        if (!connector || !railSlot) return

        // Elbow Y is relative to the rail slot (which bleeds into row padding)
        const slotRect = railSlot.getBoundingClientRect()
        const connectorRect = connector.getBoundingClientRect()
        const elbowY = connectorRect.top + connectorRect.height / 2 - slotRect.top
        railSlot.style.setProperty("--range-elbow-y", `${Math.max(elbowY, 0)}px`)
      })
    })
  }
}
