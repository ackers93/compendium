import { Controller } from "@hotwired/stimulus"

// Expands chapter card comment previews.
// Range-bracket layout sync can fire spurious mouseleave while the cursor is
// still over the comment. We treat "still over" via elementFromPoint, and track
// document mousemove so a real exit still closes after a spurious leave.
export default class extends Controller {
  open() {
    clearTimeout(this.closeTimer)
    this.element.classList.add("is-expanded")
    this.#ensureTracking()
  }

  scheduleClose(event) {
    if (event) {
      this.lastX = event.clientX
      this.lastY = event.clientY
    }

    clearTimeout(this.closeTimer)
    this.closeTimer = setTimeout(() => this.#closeIfPointerLeft(), 100)
  }

  disconnect() {
    clearTimeout(this.closeTimer)
    this.#removeTracking()
  }

  #closeIfPointerLeft() {
    const under = document.elementFromPoint(this.lastX ?? -1, this.lastY ?? -1)
    if (under && this.element.contains(under)) {
      this.element.classList.add("is-expanded")
      return
    }

    this.element.classList.remove("is-expanded")
    this.#removeTracking()
  }

  #ensureTracking() {
    if (this.moveListener) return

    this.moveListener = (event) => {
      this.lastX = event.clientX
      this.lastY = event.clientY
      if (!this.element.classList.contains("is-expanded")) return

      const under = document.elementFromPoint(event.clientX, event.clientY)
      if (under && this.element.contains(under)) {
        clearTimeout(this.closeTimer)
      } else {
        this.scheduleClose(event)
      }
    }

    document.addEventListener("mousemove", this.moveListener)
  }

  #removeTracking() {
    if (!this.moveListener) return
    document.removeEventListener("mousemove", this.moveListener)
    this.moveListener = null
  }
}
