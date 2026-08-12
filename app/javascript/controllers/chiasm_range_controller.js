import { Controller } from "@hotwired/stimulus"

// Cascading book/chapter/verse pickers for chiasm start/end range.
export default class extends Controller {
  static targets = [
    "startBook", "startChapter", "startVerse", "startVerseId",
    "endBook", "endChapter", "endVerse", "endVerseId"
  ]

  connect() {
    this.initializeExisting()
  }

  async initializeExisting() {
    const startChapterSelected = this.startChapterTarget.dataset.selected
    const startVerseSelected = this.startVerseTarget.dataset.selected
    const endChapterSelected = this.endChapterTarget.dataset.selected
    const endVerseSelected = this.endVerseTarget.dataset.selected

    if (this.startBookTarget.value) {
      await this.loadChapters(this.startBookTarget.value, this.startChapterTarget, startChapterSelected)
      if (this.startChapterTarget.value) {
        await this.loadVerses(this.startBookTarget.value, this.startChapterTarget.value, this.startVerseTarget, startVerseSelected)
      }
    }

    this.syncEndBook()

    if (this.endBookTarget.value) {
      await this.loadChapters(this.endBookTarget.value, this.endChapterTarget, endChapterSelected)
      if (this.endChapterTarget.value) {
        await this.loadVerses(this.endBookTarget.value, this.endChapterTarget.value, this.endVerseTarget, endVerseSelected)
      }
    }
  }

  async startBookChanged() {
    this.syncEndBook()
    this.startChapterTarget.innerHTML = '<option value="">Ch...</option>'
    this.startVerseTarget.innerHTML = '<option value="">V...</option>'
    this.startChapterTarget.disabled = true
    this.startVerseTarget.disabled = true
    this.startVerseIdTarget.value = ""

    if (!this.startBookTarget.value) return

    await this.loadChapters(this.startBookTarget.value, this.startChapterTarget)
    this.endChapterTarget.innerHTML = '<option value="">Ch...</option>'
    this.endVerseTarget.innerHTML = '<option value="">V...</option>'
    this.endChapterTarget.disabled = true
    this.endVerseTarget.disabled = true
    this.endVerseIdTarget.value = ""
    await this.loadChapters(this.endBookTarget.value, this.endChapterTarget)
  }

  async startChapterChanged() {
    this.startVerseTarget.innerHTML = '<option value="">V...</option>'
    this.startVerseTarget.disabled = true
    this.startVerseIdTarget.value = ""

    if (!this.startBookTarget.value || !this.startChapterTarget.value) return
    await this.loadVerses(this.startBookTarget.value, this.startChapterTarget.value, this.startVerseTarget)
  }

  async startVerseChanged() {
    await this.resolveVerseId(
      this.startBookTarget.value,
      this.startChapterTarget.value,
      this.startVerseTarget.value,
      this.startVerseIdTarget
    )
  }

  async endChapterChanged() {
    this.endVerseTarget.innerHTML = '<option value="">V...</option>'
    this.endVerseTarget.disabled = true
    this.endVerseIdTarget.value = ""

    if (!this.endBookTarget.value || !this.endChapterTarget.value) return
    await this.loadVerses(this.endBookTarget.value, this.endChapterTarget.value, this.endVerseTarget)
  }

  async endVerseChanged() {
    await this.resolveVerseId(
      this.endBookTarget.value,
      this.endChapterTarget.value,
      this.endVerseTarget.value,
      this.endVerseIdTarget
    )
  }

  syncEndBook() {
    this.endBookTarget.value = this.startBookTarget.value
  }

  async loadChapters(book, selectEl, selected = null) {
    const response = await fetch(`/bible_verses/${encodeURIComponent(book)}/chapters`, {
      headers: { Accept: "application/json" }
    })
    const data = await response.json()
    selectEl.innerHTML = '<option value="">Ch...</option>'
    data.chapters.forEach((ch) => {
      const option = document.createElement("option")
      option.value = ch
      option.textContent = ch
      if (String(ch) === String(selected)) option.selected = true
      selectEl.appendChild(option)
    })
    selectEl.disabled = false
  }

  async loadVerses(book, chapter, selectEl, selected = null) {
    const response = await fetch(`/bible_verses/${encodeURIComponent(book)}/${chapter}`, {
      headers: { Accept: "application/json" }
    })
    const data = await response.json()
    selectEl.innerHTML = '<option value="">V...</option>'
    data.verses.forEach((v) => {
      const option = document.createElement("option")
      option.value = v.verse
      option.textContent = v.verse
      if (String(v.verse) === String(selected)) option.selected = true
      selectEl.appendChild(option)
    })
    selectEl.disabled = false
  }

  async resolveVerseId(book, chapter, verse, hiddenInput) {
    if (!book || !chapter || !verse) {
      hiddenInput.value = ""
      return
    }

    const response = await fetch(`/bible_verses/${encodeURIComponent(book)}/${chapter}`, {
      headers: { Accept: "application/json" }
    })
    const data = await response.json()
    const match = data.verses.find((v) => String(v.verse) === String(verse))
    hiddenInput.value = match ? match.id : ""
  }
}
