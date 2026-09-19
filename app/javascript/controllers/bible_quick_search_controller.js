import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "panel",
    "backdrop",
    "fab",
    "input",
    "results",
    "preview",
    "previewEmpty",
    "previewContent",
    "previewReference",
    "previewText",
    "previewLink"
  ]

  static values = {
    url: { type: String, default: "/bible_verses/quick_search" },
    mobileBreakpoint: { type: Number, default: 768 }
  }

  connect() {
    this.searchTimeout = null
    this.selectedIndex = -1
    this.open = false
    this.resultItems = []
    this.boundHandleKeydown = this.handleGlobalKeydown.bind(this)
    this.boundSyncNavbarHeight = this.syncNavbarHeight.bind(this)
    this.boundHandleResize = this.handleResize.bind(this)

    this.syncNavbarHeight()
    window.addEventListener("resize", this.boundSyncNavbarHeight)
    window.addEventListener("resize", this.boundHandleResize)
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  disconnect() {
    clearTimeout(this.searchTimeout)
    window.removeEventListener("resize", this.boundSyncNavbarHeight)
    window.removeEventListener("resize", this.boundHandleResize)
    document.removeEventListener("keydown", this.boundHandleKeydown)
    this.setOpen(false)
  }

  syncNavbarHeight() {
    const navbar = document.querySelector(".navbar")
    const height = navbar ? `${navbar.offsetHeight}px` : "5rem"
    document.documentElement.style.setProperty("--navbar-height", height)
  }

  isMobile() {
    return window.matchMedia(`(max-width: ${this.mobileBreakpointValue - 1}px)`).matches
  }

  toggle(event) {
    event?.stopPropagation()
    this.setOpen(!this.open)
  }

  close(event) {
    event?.stopPropagation()
    this.setOpen(false)
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  setOpen(nextOpen) {
    this.open = nextOpen
    this.syncNavbarHeight()

    this.panelTarget.classList.toggle("is-open", nextOpen)
    this.panelTarget.setAttribute("aria-hidden", nextOpen ? "false" : "true")
    this.fabTarget.classList.toggle("is-open", nextOpen)
    this.fabTarget.setAttribute("aria-expanded", nextOpen ? "true" : "false")
    this.fabTarget.setAttribute("aria-label", nextOpen ? "Close Bible search" : "Open Bible search")

    if (this.hasBackdropTarget) {
      this.backdropTarget.hidden = !(nextOpen && this.isMobile())
      this.backdropTarget.classList.toggle("is-visible", nextOpen && this.isMobile())
    }

    document.body.classList.toggle("bible-quick-search-open", nextOpen && !this.isMobile())
    document.body.classList.toggle("bible-quick-search-modal-open", nextOpen && this.isMobile())

    if (nextOpen) {
      requestAnimationFrame(() => this.inputTarget.focus())
      if (this.isMobile()) {
        document.body.style.overflow = "hidden"
      }
    } else {
      // Keep scroll locked if an app modal is still open underneath
      if (!document.querySelector(".modal-overlay")) {
        document.body.style.overflow = ""
      }
    }
  }

  handleResize() {
    if (!this.open) return
    // Re-apply mobile vs desktop chrome when crossing the breakpoint
    this.setOpen(true)
  }

  handleGlobalKeydown(event) {
    if (event.key === "Escape" && this.open) {
      event.preventDefault()
      this.close()
    }
  }

  search(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.trim()

    if (query.length === 0) {
      this.clearResults()
      return
    }

    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(
        `${this.urlValue}?q=${encodeURIComponent(query)}`,
        { headers: { Accept: "application/json" } }
      )
      if (!response.ok) throw new Error(`Search failed (${response.status})`)
      const data = await response.json()
      this.displayResults(data)
    } catch (error) {
      console.error("Bible quick search error:", error)
      this.resultsTarget.innerHTML =
        `<li class="bible-quick-search__empty">Search failed. Try again.</li>`
    }
  }

  displayResults(data) {
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
    this.resultItems = []

    const references = data.references || []
    const content = data.content || []
    const items = []

    references.forEach((result) => {
      if (result.type === "verse") {
        items.push({
          ...result,
          label: `${result.book} ${result.chapter}:${result.verse}`,
          meta: "Reference"
        })
      } else if (result.type === "chapter") {
        items.push({
          ...result,
          label: `${result.book} ${result.chapter}`,
          meta: "Chapter",
          text: null
        })
      } else if (result.type === "book") {
        items.push({
          ...result,
          label: result.book,
          meta: "Book",
          text: null
        })
      }
    })

    content.forEach((result) => {
      const alreadyListed = items.some(
        (item) =>
          item.type === "verse" &&
          item.book === result.book &&
          item.chapter === result.chapter &&
          item.verse === result.verse
      )
      if (alreadyListed) return

      items.push({
        ...result,
        label: `${result.book} ${result.chapter}:${result.verse}`,
        meta: "Content"
      })
    })

    this.resultItems = items

    if (items.length === 0) {
      this.resultsTarget.innerHTML =
        `<li class="bible-quick-search__empty">No matches found.</li>`
      return
    }

    items.forEach((item, index) => {
      const li = document.createElement("li")
      li.className = "bible-quick-search__result"
      li.setAttribute("role", "option")
      li.dataset.index = String(index)
      li.dataset.action = "click->bible-quick-search#selectResult"

      const snippet = item.text
        ? `<span class="bible-quick-search__snippet">${this.escapeHtml(this.truncate(item.text, 90))}</span>`
        : ""

      li.innerHTML = `
        <span class="bible-quick-search__result-main">
          <span class="bible-quick-search__result-label">${this.escapeHtml(item.label)}</span>
          <span class="bible-quick-search__result-meta">${this.escapeHtml(item.meta)}</span>
        </span>
        ${snippet}
      `
      this.resultsTarget.appendChild(li)
    })
  }

  selectResult(event) {
    const li = event.currentTarget
    const index = Number(li.dataset.index)
    const item = this.resultItems[index]
    if (!item) return

    this.highlightSelected(li)

    if (item.type === "book") {
      this.showPreview({
        reference: item.book,
        text: "Open this book to browse chapters.",
        href: `/bible_verses/${encodeURIComponent(item.book)}/chapters`
      })
      return
    }

    if (item.type === "chapter") {
      this.showPreview({
        reference: `${item.book} ${item.chapter}`,
        text: "Open this chapter to read its verses.",
        href: `/bible_verses/${encodeURIComponent(item.book)}/${item.chapter}`
      })
      return
    }

    // verse or content
    if (item.text) {
      this.showPreview({
        reference: `${item.book} ${item.chapter}:${item.verse}`,
        text: item.text,
        href: `/bible_verses/${encodeURIComponent(item.book)}/${item.chapter}/${item.verse}`
      })
      return
    }

    this.fetchVersePreview(item.book, item.chapter, item.verse)
  }

  async fetchVersePreview(book, chapter, verse) {
    try {
      const response = await fetch(
        `/bible_verses/${encodeURIComponent(book)}/${chapter}`,
        { headers: { Accept: "application/json" } }
      )
      if (!response.ok) throw new Error("Verse fetch failed")
      const data = await response.json()
      const match = (data.verses || []).find((v) => String(v.verse) === String(verse))
      this.showPreview({
        reference: `${book} ${chapter}:${verse}`,
        text: match?.text || "Verse text unavailable.",
        href: `/bible_verses/${encodeURIComponent(book)}/${chapter}/${verse}`
      })
    } catch (error) {
      console.error("Verse preview error:", error)
      this.showPreview({
        reference: `${book} ${chapter}:${verse}`,
        text: "Could not load verse text.",
        href: `/bible_verses/${encodeURIComponent(book)}/${chapter}/${verse}`
      })
    }
  }

  showPreview({ reference, text, href }) {
    this.previewEmptyTarget.hidden = true
    this.previewContentTarget.hidden = false
    this.previewReferenceTarget.textContent = reference
    this.previewTextTarget.textContent = text
    this.previewLinkTarget.href = href
  }

  clearResults() {
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
    this.resultItems = []
  }

  handleInputKeydown(event) {
    const items = this.resultsTarget.querySelectorAll(".bible-quick-search__result")
    if (items.length === 0) return

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1)
        this.highlightItem(items)
        break
      case "ArrowUp":
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.highlightItem(items)
        break
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0 && items[this.selectedIndex]) {
          items[this.selectedIndex].click()
        }
        break
    }
  }

  highlightItem(items) {
    items.forEach((item, index) => {
      item.classList.toggle("is-active", index === this.selectedIndex)
    })
    if (this.selectedIndex >= 0) {
      items[this.selectedIndex].scrollIntoView({ block: "nearest" })
    }
  }

  highlightSelected(li) {
    this.resultsTarget.querySelectorAll(".bible-quick-search__result").forEach((item) => {
      item.classList.toggle("is-selected", item === li)
      item.classList.remove("is-active")
    })
  }

  truncate(text, max) {
    if (!text || text.length <= max) return text || ""
    return `${text.slice(0, max).trim()}…`
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
