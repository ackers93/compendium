import { Controller } from "@hotwired/stimulus"

// Maps text selections in the canonical passage to chiasm limb offsets.
export default class extends Controller {
  static targets = ["passage", "limbsList", "emptyState", "template"]

  connect() {
    // Capture canonical passage before any highlight markup is applied.
    this.passageText = this.passageTarget.textContent
    this.limbIndex = this.limbsListTarget.querySelectorAll(".chiasm-limb-editor-item:not([data-destroyed])").length
    this.renderPassageHighlights()
    this.renumberPositions()
  }

  addFromSelection(event) {
    event.preventDefault()
    const selection = window.getSelection()
    if (!selection || selection.isCollapsed || selection.rangeCount === 0) {
      alert("Select text in the passage first.")
      return
    }

    const offsets = this.offsetsFromSelection(selection)
    if (!offsets) {
      alert("Selection must be within the passage.")
      return
    }

    if (offsets.start >= offsets.end) {
      alert("Please select some text.")
      return
    }

    if (this.overlapsExisting(offsets.start, offsets.end)) {
      alert("That selection overlaps an existing limb.")
      return
    }

    this.appendLimb(offsets.start, offsets.end, "")
    selection.removeAllRanges()
    this.renumberPositions()
    this.renderPassageHighlights()
    this.updateEmptyState()
  }

  removeLimb(event) {
    event.preventDefault()
    const item = event.currentTarget.closest(".chiasm-limb-editor-item")
    if (!item) return

    const destroyInput = item.querySelector('input[name*="[_destroy]"]')
    if (destroyInput && item.dataset.persisted === "true") {
      destroyInput.value = "1"
      item.dataset.destroyed = "true"
      item.hidden = true
    } else {
      item.remove()
    }

    this.renumberPositions()
    this.renderPassageHighlights()
    this.updateEmptyState()
  }

  offsetsFromSelection(selection) {
    const range = selection.getRangeAt(0)
    if (!this.passageTarget.contains(range.commonAncestorContainer)) {
      return null
    }

    const preRange = document.createRange()
    preRange.selectNodeContents(this.passageTarget)
    preRange.setEnd(range.startContainer, range.startOffset)
    const start = preRange.toString().length
    const end = start + range.toString().length
    return { start, end }
  }

  activeLimbs() {
    return Array.from(this.limbsListTarget.querySelectorAll(".chiasm-limb-editor-item"))
      .filter((item) => !item.hidden && item.dataset.destroyed !== "true")
      .map((item) => ({
        el: item,
        start: parseInt(item.querySelector('input[name*="[start_offset]"]').value, 10),
        end: parseInt(item.querySelector('input[name*="[end_offset]"]').value, 10),
        note: item.querySelector('textarea[name*="[note]"]')?.value || ""
      }))
      .sort((a, b) => a.start - b.start)
  }

  overlapsExisting(start, end) {
    return this.activeLimbs().some((limb) => !(end <= limb.start || start >= limb.end))
  }

  appendLimb(start, end, note) {
    const index = Date.now() + this.limbIndex
    this.limbIndex += 1
    const position = this.activeLimbs().length + 1
    const html = this.templateTarget.innerHTML
      .replaceAll("__INDEX__", String(index))
      .replaceAll("__POSITION__", String(position))
      .replaceAll("__START__", String(start))
      .replaceAll("__END__", String(end))
      .replaceAll("__NOTE__", this.escapeHtml(note))
      .replaceAll("__SNIPPET__", this.escapeHtml(this.passageText.slice(start, end)))

    const wrapper = document.createElement("div")
    wrapper.innerHTML = html.trim()
    this.limbsListTarget.appendChild(wrapper.firstElementChild)
  }

  renumberPositions() {
    const limbs = this.activeLimbs()
    const n = limbs.length

    limbs.forEach((limb, index) => {
      const positionInput = limb.el.querySelector('input[name*="[position]"]')
      const label = limb.el.querySelector("[data-limb-label]")
      const depth = Math.min(index, n - 1 - index)
      if (positionInput) positionInput.value = index + 1
      if (label) label.textContent = this.labelFor(index, n)
      limb.el.style.setProperty("--chiasm-layer-color", this.colorAt(depth))
      this.limbsListTarget.appendChild(limb.el)
    })
  }

  labelFor(index, n) {
    if (index < Math.ceil(n / 2)) {
      return String.fromCharCode(65 + index)
    }
    return `${String.fromCharCode(65 + (n - 1 - index))}'`
  }

  updateEmptyState() {
    if (!this.hasEmptyStateTarget) return
    this.emptyStateTarget.hidden = this.activeLimbs().length > 0
  }

  renderPassageHighlights() {
    const text = this.passageText
    const limbs = this.activeLimbs()
    if (limbs.length === 0) {
      this.passageTarget.textContent = text
      return
    }

    const n = limbs.length
    let html = ""
    let cursor = 0

    limbs.forEach((limb, readingIndex) => {
      const depth = Math.min(readingIndex, n - 1 - readingIndex)
      const color = this.colorAt(depth)
      const label = this.labelFor(readingIndex, n)

      if (limb.start > cursor) {
        html += this.escapeHtml(text.slice(cursor, limb.start))
      }
      html += `<mark class="chiasm-passage-mark" style="--chiasm-layer-color: ${color}" data-label="${this.escapeHtml(label)}">${this.escapeHtml(text.slice(limb.start, limb.end))}</mark>`
      cursor = limb.end
    })

    if (cursor < text.length) {
      html += this.escapeHtml(text.slice(cursor))
    }

    this.passageTarget.innerHTML = html
  }

  colorAt(depth) {
    return `var(--color-range-${(depth % 4) + 1})`
  }

  escapeHtml(value) {
    return String(value)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }
}
