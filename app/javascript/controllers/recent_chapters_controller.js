import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "recentBibleChapters"
const MAX_STORED = 4
const MAX_DISPLAY = 3

export default class extends Controller {
  static targets = ["list"]

  static values = {
    book: String,
    chapter: Number
  }

  connect() {
    const history = this.#load()
    this.#render(history)
    this.#save(this.#record(history))
  }

  #load() {
    try {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (!raw) return []

      const parsed = JSON.parse(raw)
      if (!Array.isArray(parsed)) return []

      return parsed.filter((entry) => (
        entry &&
        typeof entry.book === "string" &&
        entry.book.length > 0 &&
        Number.isFinite(Number(entry.chapter))
      )).map((entry) => ({
        book: entry.book,
        chapter: Number(entry.chapter)
      }))
    } catch {
      return []
    }
  }

  #save(history) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(history))
  }

  #record(history) {
    const current = { book: this.bookValue, chapter: this.chapterValue }
    return [
      current,
      ...history.filter((entry) => !this.#isCurrent(entry))
    ].slice(0, MAX_STORED)
  }

  #isCurrent(entry) {
    return entry.book === this.bookValue && entry.chapter === this.chapterValue
  }

  #render(history) {
    const recent = history.filter((entry) => !this.#isCurrent(entry)).slice(0, MAX_DISPLAY)

    if (recent.length === 0) {
      this.listTarget.hidden = true
      this.listTarget.replaceChildren()
      this.element.classList.remove("has-recent-chapters")
      return
    }

    const fragment = document.createDocumentFragment()
    recent.forEach((entry) => {
      const link = document.createElement("a")
      link.href = `/bible_verses/${encodeURIComponent(entry.book)}/${entry.chapter}`
      link.className = "recent-chapter-link"
      link.textContent = `${entry.book} ${entry.chapter}`
      link.setAttribute("aria-label", `Recent chapter: ${entry.book} ${entry.chapter}`)
      fragment.appendChild(link)
    })

    this.listTarget.replaceChildren(fragment)
    this.listTarget.hidden = false
    this.element.classList.add("has-recent-chapters")
  }
}
