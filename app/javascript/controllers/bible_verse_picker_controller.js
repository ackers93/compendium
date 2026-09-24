import { Controller } from "@hotwired/stimulus"

// Cascading book → chapter → verse selects (used by topic "add verse" form).
export default class extends Controller {
  static targets = ["bookSelect", "chapterSelect", "verseSelect", "preview"]

  async bookSelected(event) {
    const book = event.target.value
    if (!book) {
      this.clearChapterSelect()
      this.clearVerseSelect()
      return
    }

    try {
      const response = await fetch(`/bible_verses/${encodeURIComponent(book)}/chapters`, {
        headers: {
          "Accept": "application/json"
        }
      })
      const data = await response.json()
      this.populateChapterSelect(data.chapters)
    } catch (error) {
      console.error("Error loading chapters:", error)
    }
  }

  async chapterSelected(event) {
    const book = this.bookSelectTarget.value
    const chapter = event.target.value
    if (!book || !chapter) {
      this.clearVerseSelect()
      return
    }

    try {
      const response = await fetch(`/bible_verses/${encodeURIComponent(book)}/${chapter}`, {
        headers: {
          "Accept": "application/json"
        }
      })
      const data = await response.json()
      this.populateVerseSelect(data.verses)
    } catch (error) {
      console.error("Error loading verses:", error)
    }
  }

  verseSelected(event) {
    const book = this.bookSelectTarget.value
    const chapter = this.chapterSelectTarget.value
    const verse = event.target.value

    if (book && chapter && verse) {
      const reference = `${book} ${chapter}:${verse}`
      if (this.hasPreviewTarget) {
        this.previewTarget.textContent = reference
      }
    }
  }

  populateChapterSelect(chapters) {
    this.clearChapterSelect()
    chapters.forEach(chapter => {
      const option = document.createElement("option")
      option.value = chapter
      option.textContent = `${chapter}`
      this.chapterSelectTarget.appendChild(option)
    })
    this.chapterSelectTarget.disabled = false
  }

  populateVerseSelect(verses) {
    this.clearVerseSelect()
    verses.forEach(verse => {
      const option = document.createElement("option")
      option.value = verse.verse
      option.textContent = `${verse.verse}`
      this.verseSelectTarget.appendChild(option)
    })
    this.verseSelectTarget.disabled = false
  }

  clearChapterSelect() {
    this.chapterSelectTarget.innerHTML = '<option value="">Select chapter...</option>'
    this.chapterSelectTarget.disabled = true
    this.clearVerseSelect()
  }

  clearVerseSelect() {
    this.verseSelectTarget.innerHTML = '<option value="">Select verse...</option>'
    this.verseSelectTarget.disabled = true
    if (this.hasPreviewTarget) {
      this.previewTarget.textContent = ""
    }
  }
}
