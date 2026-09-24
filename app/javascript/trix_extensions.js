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

// Custom Trix button/dialog for content tables
document.addEventListener("trix-initialize", function(event) {
  const trixEditor = event.target
  const { toolbarElement } = trixEditor
  const dialogsContainer = toolbarElement.parentElement.querySelector('[data-trix-dialogs]')

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
    linkTools.parentNode.insertBefore(tableGroup, linkTools.nextSibling)
  }
})

document.addEventListener("trix-action-invoke", function(event) {
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
