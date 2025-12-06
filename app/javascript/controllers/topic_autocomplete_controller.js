import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "results", "topicId"]
  
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
      this.topicIdTarget.value = ""
      return
    }
    
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }
  
  async performSearch(query) {
    try {
      const response = await fetch(`/topics/autocomplete?q=${encodeURIComponent(query)}`)
      const topics = await response.json()
      
      this.displayResults(topics, query)
    } catch (error) {
      console.error("Error fetching topics:", error)
    }
  }
  
  displayResults(topics, query) {
    this.resultsTarget.innerHTML = ""
    this.selectedIndex = -1
    
    if (topics.length === 0) {
      // Show option to create new topic
      const li = document.createElement("li")
      li.className = "px-4 py-2 hover:bg-gray-100 cursor-pointer"
      li.innerHTML = `<span class="text-gray-600">Create new topic: "<strong>${this.escapeHtml(query)}</strong>"</span>`
      li.dataset.action = "click->topic-autocomplete#selectNewTopic"
      li.dataset.topicName = query
      this.resultsTarget.appendChild(li)
    } else {
      // Show existing topics
      topics.forEach((topic, index) => {
        const li = document.createElement("li")
        li.className = "px-4 py-2 hover:bg-gray-100 cursor-pointer"
        li.innerHTML = this.escapeHtml(topic.name)
        li.dataset.action = "click->topic-autocomplete#selectTopic"
        li.dataset.topicId = topic.id
        li.dataset.topicName = topic.name
        li.dataset.index = index
        this.resultsTarget.appendChild(li)
      })
      
      // Also show option to create new topic if query doesn't match exactly
      const exactMatch = topics.find(t => t.name.toLowerCase() === query.toLowerCase())
      if (!exactMatch) {
        const li = document.createElement("li")
        li.className = "px-4 py-2 hover:bg-gray-100 cursor-pointer border-t border-gray-200"
        li.innerHTML = `<span class="text-gray-600">Create new topic: "<strong>${this.escapeHtml(query)}</strong>"</span>`
        li.dataset.action = "click->topic-autocomplete#selectNewTopic"
        li.dataset.topicName = query
        this.resultsTarget.appendChild(li)
      }
    }
    
    this.showDropdown()
  }
  
  selectTopic(event) {
    const topicId = event.currentTarget.dataset.topicId
    const topicName = event.currentTarget.dataset.topicName
    
    this.inputTarget.value = topicName
    this.topicIdTarget.value = topicId
    this.hideDropdown()
  }
  
  selectNewTopic(event) {
    const topicName = event.currentTarget.dataset.topicName
    
    this.inputTarget.value = topicName
    this.topicIdTarget.value = ""
    this.hideDropdown()
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

