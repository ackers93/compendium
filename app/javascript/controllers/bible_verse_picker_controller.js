import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bookSelect", "chapterSelect", "verseSelect", "preview"]
  
  connect() {
    this.trixEditor = document.activeElement
    if (this.trixEditor && this.trixEditor.tagName === "TRIX-EDITOR") {
      this.element.dataset.trixEditor = true
    }
  }
  
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
  
  insertVerse(event) {
    event.preventDefault()
    
    const book = this.bookSelectTarget.value
    const chapter = this.chapterSelectTarget.value
    const verse = this.verseSelectTarget.value
    
    if (!book || !chapter || !verse) {
      alert("Please select a book, chapter, and verse")
      return
    }
    
    const reference = `${book} ${chapter}:${verse}`
    const url = `/bible_verses/${encodeURIComponent(book)}/${chapter}/${verse}`
    
    console.log("Attempting to insert verse:", reference)
    
    // Get the active Trix editor from the global variable
    let trixEditor = window.activeTrixEditorForVerse
    
    if (!trixEditor) {
      console.log("No editor in global variable, trying querySelector")
      trixEditor = document.querySelector("trix-editor[data-awaiting-verse-link='true']")
    }
    
    if (!trixEditor) {
      console.log("No editor with awaiting flag, checking for any trix-editor")
      const allEditors = document.querySelectorAll("trix-editor")
      console.log("Found", allEditors.length, "trix editors")
      if (allEditors.length === 1) {
        trixEditor = allEditors[0]
      }
    }
    
    if (trixEditor) {
      console.log("Found trix editor, attempting insert")
      const editor = trixEditor.editor
      
      if (!editor) {
        console.error("Trix editor element found but no editor instance")
        alert("Error: Could not access the editor. Please try again.")
        return
      }
      
      const selectedRange = editor.getSelectedRange()
      console.log("Current selection range:", selectedRange)
      
      // Insert the link
      editor.setSelectedRange(selectedRange)
      editor.insertHTML(`<a href="${url}">${reference}</a>`)
      
      console.log("Verse inserted successfully")
      
      // Clean up
      delete trixEditor.dataset.awaitingVerseLink
      window.activeTrixEditorForVerse = null
      
      // Close modal
      this.closeModal()
    } else {
      console.error("Could not find any trix editor")
      alert("Error: Could not find the editor. Please try clicking the verse button again.")
    }
  }
  
  closeModal() {
    const closeButton = this.element.querySelector(".modal-close")
    if (closeButton) {
      closeButton.click()
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

