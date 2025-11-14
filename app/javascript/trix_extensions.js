// Custom Trix button and dialog for Bible verse references
document.addEventListener("trix-initialize", function(event) {
  const trixEditor = event.target
  const { toolbarElement } = trixEditor
  
  // Add the custom dialog to the dialogs container
  const dialogsContainer = toolbarElement.parentElement.querySelector('[data-trix-dialogs]')
  if (dialogsContainer && !dialogsContainer.querySelector('[data-trix-dialog="verse"]')) {
    const verseDialog = document.createElement('div')
    verseDialog.className = 'trix-dialog trix-dialog--verse'
    verseDialog.setAttribute('data-trix-dialog', 'verse')
    verseDialog.innerHTML = `
      <div class="trix-dialog__verse-fields">
        <select class="trix-input trix-input--dialog" data-verse-select="book" aria-label="Book">
          <option value="">Select book...</option>
        </select>
        <select class="trix-input trix-input--dialog" data-verse-select="chapter" disabled aria-label="Chapter">
          <option value="">Select chapter...</option>
        </select>
        <select class="trix-input trix-input--dialog" data-verse-select="verse" disabled aria-label="Verse">
          <option value="">Select verse...</option>
        </select>
        <div class="trix-button-group">
          <input type="button" class="trix-button trix-button--dialog" value="Insert" data-verse-insert-button>
        </div>
      </div>
    `
    dialogsContainer.appendChild(verseDialog)
    
    // Initialize the dialog with books
    initializeVerseDialog(verseDialog, trixEditor)
  }
  
  // Find the link tools group and insert after it
  const linkTools = toolbarElement.querySelector('[data-trix-button-group="text-tools"]')
  if (linkTools) {
    const bibleVerseGroup = document.createElement('span')
    bibleVerseGroup.className = 'trix-button-group trix-button-group--bible-tools'
    
    const button = document.createElement('button')
    button.type = 'button'
    button.className = 'trix-button trix-button--bible-verse'
    button.setAttribute('data-trix-action', 'verse')
    button.setAttribute('title', 'Insert Bible Verse Reference')
    button.setAttribute('tabindex', '-1')
    button.textContent = 'Verse'
    
    bibleVerseGroup.appendChild(button)
    linkTools.parentNode.insertBefore(bibleVerseGroup, linkTools.nextSibling)
  }
})

// Handle the verse action to show the dialog
document.addEventListener("trix-action-invoke", function(event) {
  if (event.actionName === "verse") {
    event.preventDefault()
    const dialog = event.target.toolbarElement.parentElement.querySelector('[data-trix-dialog="verse"]')
    if (dialog) {
      dialog.classList.add('trix-active')
      dialog.querySelector('[data-verse-select="book"]').focus()
    }
  }
})

// Initialize the verse dialog with data and handlers
async function initializeVerseDialog(dialog, trixEditor) {
  const bookSelect = dialog.querySelector('[data-verse-select="book"]')
  const chapterSelect = dialog.querySelector('[data-verse-select="chapter"]')
  const verseSelect = dialog.querySelector('[data-verse-select="verse"]')
  const insertButton = dialog.querySelector('[data-verse-insert-button]')
  
  // Load books
  try {
    const response = await fetch('/bible_verses/books.json', {
      credentials: 'same-origin',
      headers: {
        'Accept': 'application/json'
      }
    })
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }
    
    const data = await response.json()
    
    // Populate books
    if (data.old_testament && data.old_testament.length > 0) {
      data.old_testament.forEach(book => {
        const option = document.createElement('option')
        option.value = book
        option.textContent = book
        bookSelect.appendChild(option)
      })
      
      const divider = document.createElement('option')
      divider.disabled = true
      divider.textContent = '───────────'
      bookSelect.appendChild(divider)
    }
    
    if (data.new_testament && data.new_testament.length > 0) {
      data.new_testament.forEach(book => {
        const option = document.createElement('option')
        option.value = book
        option.textContent = book
        bookSelect.appendChild(option)
      })
    }
    
  } catch (error) {
    console.error("Error loading books:", error)
  }
  
  // Book selection handler
  bookSelect.addEventListener('change', async function() {
    const book = this.value
    chapterSelect.innerHTML = '<option value="">Select chapter...</option>'
    verseSelect.innerHTML = '<option value="">Select verse...</option>'
    chapterSelect.disabled = true
    verseSelect.disabled = true
    
    if (!book) return
    
    try {
      const response = await fetch(`/bible_verses/${encodeURIComponent(book)}/chapters`, {
        headers: { "Accept": "application/json" }
      })
      const data = await response.json()
      
      data.chapters.forEach(chapter => {
        const option = document.createElement('option')
        option.value = chapter
        option.textContent = `Chapter ${chapter}`
        chapterSelect.appendChild(option)
      })
      chapterSelect.disabled = false
    } catch (error) {
      console.error("Error loading chapters:", error)
    }
  })
  
  // Chapter selection handler
  chapterSelect.addEventListener('change', async function() {
    const book = bookSelect.value
    const chapter = this.value
    verseSelect.innerHTML = '<option value="">Select verse...</option>'
    verseSelect.disabled = true
    
    if (!book || !chapter) return
    
    try {
      const response = await fetch(`/bible_verses/${encodeURIComponent(book)}/${chapter}`, {
        headers: { "Accept": "application/json" }
      })
      const data = await response.json()
      
      data.verses.forEach(verse => {
        const option = document.createElement('option')
        option.value = verse.verse
        option.textContent = `Verse ${verse.verse}`
        verseSelect.appendChild(option)
      })
      verseSelect.disabled = false
    } catch (error) {
      console.error("Error loading verses:", error)
    }
  })
  
  // Insert button handler
  insertButton.addEventListener('click', function(e) {
    e.preventDefault()
    
    const book = bookSelect.value
    const chapter = chapterSelect.value
    const verse = verseSelect.value
    
    if (!book || !chapter || !verse) {
      alert("Please select a book, chapter, and verse")
      return
    }
    
    const reference = `${book} ${chapter}:${verse}`
    const url = `/bible_verses/${encodeURIComponent(book)}/${chapter}/${verse}`
    
    // Insert the link into the editor
    const editor = trixEditor.editor
    editor.insertHTML(`<a href="${url}">${reference}</a>`)
    
    // Close the dialog properly
    dialog.classList.remove('trix-active')
    
    // Hide all dialogs by blurring and refocusing
    const allDialogs = trixEditor.toolbarElement.parentElement.querySelectorAll('[data-trix-dialog]')
    allDialogs.forEach(d => d.classList.remove('trix-active'))
    
    // Refocus the editor
    trixEditor.focus()
    
    // Reset the form
    bookSelect.value = ''
    chapterSelect.innerHTML = '<option value="">Select chapter...</option>'
    verseSelect.innerHTML = '<option value="">Select verse...</option>'
    chapterSelect.disabled = true
    verseSelect.disabled = true
  })
}

