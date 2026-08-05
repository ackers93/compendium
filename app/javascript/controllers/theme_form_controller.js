import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker", "hex", "swatch"]

  preview(event) {
    const input = event.currentTarget
    const key = input.dataset.themeKey
    if (!key) return

    let value = input.value.trim()
    if (!value.startsWith("#")) value = `#${value}`

    if (!/^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/.test(value)) return

    const normalized = this.expandHex(value)
    document.documentElement.style.setProperty(`--color-${key}`, normalized)

    if (key === "primary") {
      document.documentElement.style.setProperty(
        "--color-primary-dark",
        this.mix(normalized, "#000000", 0.22)
      )
      document.documentElement.style.setProperty(
        "--color-primary-light",
        this.mix(normalized, "#ffffff", 0.28)
      )
    }

    if (key === "header") {
      document.documentElement.style.setProperty(
        "--color-header-text",
        this.readableOnDark(normalized)
      )
    }

    this.syncPair(key, normalized)
  }

  syncPair(key, hex) {
    this.pickerTargets.forEach((el) => {
      if (el.dataset.themeKey === key) el.value = hex
    })
    this.hexTargets.forEach((el) => {
      if (el.dataset.themeKey === key) el.value = hex
    })
    this.swatchTargets.forEach((el) => {
      if (el.dataset.themeKey === key) el.style.backgroundColor = hex
    })
  }

  expandHex(hex) {
    if (hex.length === 4) {
      return "#" + [...hex.slice(1)].map((c) => c + c).join("")
    }
    return hex.toLowerCase()
  }

  mix(hex, toward, amount) {
    const [r1, g1, b1] = this.toRgb(hex)
    const [r2, g2, b2] = this.toRgb(toward)
    const r = Math.round(r1 + (r2 - r1) * amount)
    const g = Math.round(g1 + (g2 - g1) * amount)
    const b = Math.round(b1 + (b2 - b1) * amount)
    return this.toHex(r, g, b)
  }

  readableOnDark(hex) {
    const [r, g, b] = this.toRgb(hex)
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    return luminance > 0.55 ? "#1a2e24" : "#b5c0b9"
  }

  toRgb(hex) {
    const value = this.expandHex(hex)
    return [
      parseInt(value.slice(1, 3), 16),
      parseInt(value.slice(3, 5), 16),
      parseInt(value.slice(5, 7), 16)
    ]
  }

  toHex(r, g, b) {
    return (
      "#" +
      [r, g, b]
        .map((n) => Math.max(0, Math.min(255, n)).toString(16).padStart(2, "0"))
        .join("")
    )
  }
}
