const INLINE_IMAGE_TYPES = ["image/png", "image/jpeg", "image/gif", "image/webp"]
const MAX_INLINE_IMAGE_BYTES = 5 * 1024 * 1024

// Only allow reasonably sized images as inline Action Text attachments
document.addEventListener("trix-file-accept", function(event) {
  const { file } = event
  if (!INLINE_IMAGE_TYPES.includes(file.type)) {
    event.preventDefault()
    alert("Only PNG, JPEG, GIF, or WebP images can be attached inline.")
    return
  }
  if (file.size > MAX_INLINE_IMAGE_BYTES) {
    event.preventDefault()
    alert("Inline images must be 5 MB or smaller.")
  }
})

// Custom Trix buttons/dialogs for Bible verses and content tables
document.addEventListener("trix-initialize", function(event) {
  const trixEditor = event.target
  const { toolbarElement } = trixEditor
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
    initializeVerseDialog(verseDialog, trixEditor)
  }

  if (dialogsContainer && !dialogsContainer.querySelector('[data-trix-dialog="content-table"]')) {
    const tableDialog = document.createElement('div')
    tableDialog.className = 'trix-dialog trix-dialog--content-table'
    tableDialog.setAttribute('data-trix-dialog', 'content-table')
    tableDialog.innerHTML = `
      <div class="trix-dialog__table-fields">
        <input type="search" class="trix-input trix-input--dialog" placeholder="Search tables..." data-table-search aria-label="Search tables">
        <div class="trix-dialog__table-list" data-table-list>
          <div class="trix-dialog__table-empty">Loading tables…</div>
        </div>
        <div class="trix-dialog__table-actions">
          <a class="trix-button trix-button--dialog" href="/content_tables/new?from=trix" target="_blank" rel="noopener" data-table-create-link>Create table</a>
          <input type="button" class="trix-button trix-button--dialog" value="Insert" data-table-insert-button>
          <input type="button" class="trix-button trix-button--dialog" value="Refresh" data-table-refresh-button>
        </div>
      </div>
    `
    dialogsContainer.appendChild(tableDialog)
    initializeContentTableDialog(tableDialog, trixEditor)
  }

  const linkTools = toolbarElement.querySelector('[data-trix-button-group="text-tools"]')
  if (linkTools && !toolbarElement.querySelector('[data-trix-action="verse"]')) {
    const bibleVerseGroup = document.createElement('span')
    bibleVerseGroup.className = 'trix-button-group trix-button-group--bible-tools'

    const button = document.createElement('button')
    button.type = 'button'
    button.className = 'trix-button trix-button--bible-verse'
    button.setAttribute('data-trix-action', 'verse')
    button.setAttribute('title', 'Insert Bible Verse Reference')
    button.setAttribute('tabindex', '-1')
    button.innerHTML = '<i class="fa-solid fa-book"></i>'

    bibleVerseGroup.appendChild(button)
    linkTools.parentNode.insertBefore(bibleVerseGroup, linkTools.nextSibling)
  }

  if (linkTools && !toolbarElement.querySelector('[data-trix-action="content-table"]')) {
    const tableGroup = document.createElement('span')
    tableGroup.className = 'trix-button-group trix-button-group--table-tools'

    const button = document.createElement('button')
    button.type = 'button'
    button.className = 'trix-button trix-button--content-table'
    button.setAttribute('data-trix-action', 'content-table')
    button.setAttribute('title', 'Insert Table')
    button.setAttribute('tabindex', '-1')
    button.innerHTML = '<i class="fa-solid fa-table"></i>'

    tableGroup.appendChild(button)
    const after = toolbarElement.querySelector('.trix-button-group--bible-tools') || linkTools
    after.parentNode.insertBefore(tableGroup, after.nextSibling)
  }
})

document.addEventListener("trix-action-invoke", function(event) {
  if (event.actionName === "verse") {
    event.preventDefault()
    const dialog = event.target.toolbarElement.parentElement.querySelector('[data-trix-dialog="verse"]')
    if (dialog) {
      dialog.classList.add('trix-active')
      dialog.querySelector('[data-verse-select="book"]').focus()
    }
  }

  if (event.actionName === "content-table") {
    event.preventDefault()
    const dialog = event.target.toolbarElement.parentElement.querySelector('[data-trix-dialog="content-table"]')
    if (dialog) {
      dialog.classList.add('trix-active')
      const search = dialog.querySelector('[data-table-search]')
      if (search) search.focus()
      if (typeof dialog._reloadTables === "function") {
        dialog._reloadTables()
      }
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
        option.textContent = `${chapter}`
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
        option.textContent = `${verse.verse}`
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

function initializeContentTableDialog(dialog, trixEditor) {
  const list = dialog.querySelector('[data-table-list]')
  const searchInput = dialog.querySelector('[data-table-search]')
  const insertButton = dialog.querySelector('[data-table-insert-button]')
  const refreshButton = dialog.querySelector('[data-table-refresh-button]')
  let tables = []
  let selectedId = null

  async function loadTables() {
    list.innerHTML = '<div class="trix-dialog__table-empty">Loading tables…</div>'
    selectedId = null

    try {
      const response = await fetch('/content_tables.json', {
        credentials: 'same-origin',
        headers: { Accept: 'application/json' }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      tables = await response.json()
      renderList()
    } catch (error) {
      console.error("Error loading tables:", error)
      list.innerHTML = '<div class="trix-dialog__table-error">Could not load tables. Sign in as a contributor and try again.</div>'
    }
  }

  function filteredTables() {
    const query = (searchInput.value || "").trim().toLowerCase()
    if (!query) return tables
    return tables.filter((table) => (table.title || "").toLowerCase().includes(query))
  }

  function renderList() {
    const items = filteredTables()
    if (items.length === 0) {
      list.innerHTML = '<div class="trix-dialog__table-empty">No tables yet. Create one first.</div>'
      return
    }

    list.innerHTML = ""
    items.forEach((table) => {
      const button = document.createElement('button')
      button.type = 'button'
      button.className = 'trix-dialog__table-option'
      if (String(table.id) === String(selectedId)) {
        button.classList.add('is-selected')
      }
      button.dataset.tableId = table.id
      button.innerHTML = `<strong></strong><small></small>`
      button.querySelector('strong').textContent = table.title
      button.querySelector('small').textContent = `${table.row_count}×${table.column_count}`
      button.addEventListener('click', () => {
        selectedId = table.id
        renderList()
      })
      list.appendChild(button)
    })
  }

  searchInput.addEventListener('input', renderList)
  refreshButton.addEventListener('click', (event) => {
    event.preventDefault()
    loadTables()
  })

  insertButton.addEventListener('click', async (event) => {
    event.preventDefault()

    if (!selectedId) {
      alert("Select a table to insert")
      return
    }

    try {
      const response = await fetch(`/content_tables/${selectedId}/attachable`, {
        credentials: 'same-origin',
        headers: { Accept: 'application/json' }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      const attachment = new window.Trix.Attachment({
        sgid: data.sgid,
        contentType: data.contentType,
        filename: data.filename,
        content: data.content
      })
      trixEditor.editor.insertAttachment(attachment)

      dialog.classList.remove('trix-active')
      const allDialogs = trixEditor.toolbarElement.parentElement.querySelectorAll('[data-trix-dialog]')
      allDialogs.forEach((d) => d.classList.remove('trix-active'))
      trixEditor.focus()
      selectedId = null
      searchInput.value = ""
      renderList()
    } catch (error) {
      console.error("Error inserting table:", error)
      alert("Could not insert that table. Please try again.")
    }
  })

  dialog._reloadTables = loadTables
  loadTables()
}

