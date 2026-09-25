import { Controller } from "@hotwired/stimulus"

// Aligns range-bracket elbows with each ranged comment's connector line.
export default class extends Controller {
  connect() {
    this.sync = this.sync.bind(this)
    this.scheduleSync = this.scheduleSync.bind(this)
    this.sync()
    this.resizeObserver = new ResizeObserver(this.scheduleSync)
    this.resizeObserver.observe(this.element)
    window.addEventListener("load", this.scheduleSync)
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    window.removeEventListener("load", this.scheduleSync)
    if (this.rafId) cancelAnimationFrame(this.rafId)
  }

  scheduleSync() {
    // Skip while a comment is expanded — mutating styles mid-hover causes
    // spurious mouseleave events that collapse the preview.
    if (this.element.querySelector(".comment-preview.is-expanded")) return

    if (this.rafId) return
    this.rafId = requestAnimationFrame(() => {
      this.rafId = null
      if (this.element.querySelector(".comment-preview.is-expanded")) return
      this.sync()
    })
  }

  sync() {
    this.element.querySelectorAll(".verse-table-row").forEach((row) => {
      row.querySelectorAll(".ranged-comment-with-connector").forEach((wrap) => {
        const track = wrap.style.getPropertyValue("--range-track").trim()
        const connector = wrap.querySelector(".range-comment-connector")
        const railSlot = row.querySelector(`.range-rail-slot[data-track="${track}"]`)
        if (!connector || !railSlot) return

        const slotRect = railSlot.getBoundingClientRect()
        const connectorRect = connector.getBoundingClientRect()
        const next = `${Math.max(connectorRect.top + connectorRect.height / 2 - slotRect.top, 0)}px`
        if (railSlot.style.getPropertyValue("--range-elbow-y") === next) return
        railSlot.style.setProperty("--range-elbow-y", next)
      })
    })
  }
}
