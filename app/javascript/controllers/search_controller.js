import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["input", "form"]
  
  // Define the search frames and their endpoints
  static values = {
    frames: { type: Object, default: {} }
  }
  
  connect() {
    this.searchTimeout = null
    // Define all search frames - each will load independently
    this.searchFrames = [
      { id: 'topics-search-results', path: '/search/topics' },
      { id: 'threads-search-results', path: '/search/threads' },
      { id: 'notes-search-results', path: '/search/notes' },
      // Add more frames here as we add other content types
    ]
  }
  
  disconnect() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
  }
  
  search(event) {
    clearTimeout(this.searchTimeout)
    const query = event.target.value.trim()
    
    // Debounce the search to avoid too many requests
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }
  
  performSearch(query) {
    // Update browser URL without reload
    const currentUrl = new URL(window.location.href)
    if (query.length > 0) {
      currentUrl.searchParams.set('q', query)
    } else {
      currentUrl.searchParams.delete('q')
    }
    window.history.pushState({}, '', currentUrl.toString())
    
    // Update all Turbo Frame contents independently
    this.searchFrames.forEach(({ id, path }) => {
      const frame = document.getElementById(id)
      if (frame) {
        const url = new URL(path, window.location.origin)
        if (query.length > 0) {
          url.searchParams.set('q', query)
        } else {
          url.searchParams.delete('q')
        }
        frame.src = url.toString()
      }
    })
  }
}
