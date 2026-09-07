import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "grid",
    "dimensions",
    "rowCount",
    "columnCount",
    "cellsField",
    "styleField",
    "headerRow",
    "headerColumn",
    "showTitle",
    "textAlign",
    "borderWidth",
    "headerBg",
    "headerText",
    "bodyBg",
    "bodyText",
    "stripeBg",
    "borderColor"
  ]

  static values = {
    maxRows: { type: Number, default: 50 },
    maxColumns: { type: Number, default: 20 }
  }

  connect() {
    this.cells = this.parseCells()
    this.renderGrid()
    this.syncStyle()
    this.element.addEventListener("submit", this.beforeSubmit)
  }

  disconnect() {
    this.element.removeEventListener("submit", this.beforeSubmit)
  }

  beforeSubmit = () => {
    this.persistFields()
  }

  parseCells() {
    try {
      const parsed = JSON.parse(this.cellsFieldTarget.value || "[]")
      if (Array.isArray(parsed) && parsed.length > 0) {
        return parsed.map((row) => (Array.isArray(row) ? row.map((c) => String(c ?? "")) : []))
      }
    } catch (_error) {
      // fall through to defaults
    }

    const rows = Math.max(parseInt(this.rowCountTarget.value, 10) || 3, 1)
    const cols = Math.max(parseInt(this.columnCountTarget.value, 10) || 3, 1)
    return Array.from({ length: rows }, () => Array.from({ length: cols }, () => ""))
  }

  renderGrid() {
    const rows = this.cells.length
    const cols = this.cells[0]?.length || 0
    const style = this.currentStyle()

    this.gridTarget.style.setProperty("--ct-header-bg", style.header_bg)
    this.gridTarget.style.setProperty("--ct-header-text", style.header_text)
    this.gridTarget.style.setProperty("--ct-body-bg", style.body_bg)
    this.gridTarget.style.setProperty("--ct-body-text", style.body_text)
    this.gridTarget.style.setProperty("--ct-stripe-bg", style.stripe_bg)
    this.gridTarget.style.setProperty("--ct-border-color", style.border_color)
    this.gridTarget.style.setProperty("--ct-border-width", `${style.border_width}px`)
    this.gridTarget.style.setProperty("--ct-text-align", style.text_align)

    this.gridTarget.classList.toggle("has-header-row", style.header_row)
    this.gridTarget.classList.toggle("has-header-column", style.header_column)

    this.gridTarget.innerHTML = ""
    this.cells.forEach((row, rowIndex) => {
      const tr = document.createElement("tr")
      if (style.header_row ? rowIndex > 0 && rowIndex % 2 === 0 : rowIndex % 2 === 1) {
        tr.classList.add("is-stripe")
      }

      row.forEach((cell, colIndex) => {
        const isHeader =
          (style.header_row && rowIndex === 0) || (style.header_column && colIndex === 0)
        const td = document.createElement(isHeader ? "th" : "td")
        const input = document.createElement("input")
        input.type = "text"
        input.value = cell
        input.className = "content-table-cell-input"
        input.dataset.row = String(rowIndex)
        input.dataset.col = String(colIndex)
        input.addEventListener("input", this.onCellInput)
        td.appendChild(input)
        tr.appendChild(td)
      })

      this.gridTarget.appendChild(tr)
    })

    this.dimensionsTarget.textContent = `${rows}×${cols}`
    this.rowCountTarget.value = String(rows)
    this.columnCountTarget.value = String(cols)
  }

  onCellInput = (event) => {
    const row = parseInt(event.target.dataset.row, 10)
    const col = parseInt(event.target.dataset.col, 10)
    if (!this.cells[row]) return
    this.cells[row][col] = event.target.value
  }

  addRow() {
    if (this.cells.length >= this.maxRowsValue) return
    const cols = this.cells[0]?.length || 1
    this.cells.push(Array.from({ length: cols }, () => ""))
    this.renderGrid()
  }

  removeRow() {
    if (this.cells.length <= 1) return
    this.cells.pop()
    this.renderGrid()
  }

  addColumn() {
    const cols = this.cells[0]?.length || 0
    if (cols >= this.maxColumnsValue) return
    this.cells.forEach((row) => row.push(""))
    this.renderGrid()
  }

  removeColumn() {
    const cols = this.cells[0]?.length || 0
    if (cols <= 1) return
    this.cells.forEach((row) => row.pop())
    this.renderGrid()
  }

  syncStyle() {
    this.renderGrid()
    this.persistFields()
  }

  currentStyle() {
    return {
      header_row: this.headerRowTarget.checked,
      header_column: this.headerColumnTarget.checked,
      show_title: this.showTitleTarget.checked,
      text_align: this.textAlignTarget.value,
      border_width: parseInt(this.borderWidthTarget.value, 10) || 0,
      header_bg: this.headerBgTarget.value,
      header_text: this.headerTextTarget.value,
      body_bg: this.bodyBgTarget.value,
      body_text: this.bodyTextTarget.value,
      stripe_bg: this.stripeBgTarget.value,
      border_color: this.borderColorTarget.value
    }
  }

  persistFields() {
    this.rowCountTarget.value = String(this.cells.length)
    this.columnCountTarget.value = String(this.cells[0]?.length || 0)
    this.cellsFieldTarget.value = JSON.stringify(this.cells)
    this.styleFieldTarget.value = JSON.stringify(this.currentStyle())
  }
}
