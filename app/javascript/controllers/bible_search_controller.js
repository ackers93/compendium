import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "results"]
  
  connect() {
    this.searchTimeout = null
    this.selectedIndex = -1
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener('click', this.handleClickOutside)
  }
  
  disconnect() {
    document.removeEventListener('click', this.handleClickOutside)
  }
  
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }
  
  search(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.trim()
    
    if (query.length === 0) {
      this.hideDropdown()
      return
    }
    
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }
  
  async performSearch(query) {
    try {
      const response = await fetch(`/bible_verses/autocomplete?q=${encodeURIComponent(query)}`)
      const results = await response.json()
      
      this.displayResults(results, query)
    } catch (error) {
      console.error("Error fetching Bible search results:", error)
    }
  }
  
  displayResults(results, query) {
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
    
    if (results.length === 0) {
      this.hideDropdown()
      return
    }
    
    // Display results
    results.forEach((result, index) => {
      const li = document.createElement("li")
      li.className = "px-4 py-2 hover:bg-gray-100 cursor-pointer"
      
      let displayText = ""
      let url = ""
      
      if (result.type === "book") {
        displayText = result.book
        url = `/bible_verses/${encodeURIComponent(result.book)}/chapters`
      } else if (result.type === "chapter") {
        displayText = `${result.book} ${result.chapter}`
        url = `/bible_verses/${encodeURIComponent(result.book)}/${result.chapter}`
      } else if (result.type === "verse") {
        displayText = `${result.book} ${result.chapter}:${result.verse}`
        url = `/bible_verses/${encodeURIComponent(result.book)}/${result.chapter}/${result.verse}`
      }
      
      li.innerHTML = this.escapeHtml(displayText)
      li.dataset.action = "click->bible-search#selectResult"
      li.dataset.url = url
      li.dataset.index = index
      this.resultsTarget.appendChild(li)
    })
    
    this.showDropdown()
  }
  
  selectResult(event) {
    const url = event.currentTarget.dataset.url
    if (url) {
      window.location.href = url
    }
  }
  
  handleKeydown(event) {
    const items = this.resultsTarget.querySelectorAll("li")
    
    if (items.length === 0) return
    
    switch(event.key) {
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
      case "Escape":
        this.hideDropdown()
        break
    }
  }
  
  highlightItem(items) {
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add("bg-gray-100")
      } else {
        item.classList.remove("bg-gray-100")
      }
    })
  }
  
  showDropdown() {
    this.dropdownTarget.classList.remove("hidden")
  }
  
  hideDropdown() {
    this.dropdownTarget.classList.add("hidden")
    this.selectedIndex = -1
  }
  
  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
