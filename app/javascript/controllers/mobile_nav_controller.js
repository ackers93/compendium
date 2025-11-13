import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "hamburger"]

  connect() {
    // Close menu when clicking outside
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnClickOutside)
  }

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.menuTarget.classList.contains("active")
    
    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.menuTarget.classList.add("active")
    this.hamburgerTarget.classList.add("active")
    document.body.style.overflow = "hidden"
    
    // Add listener to close on outside click
    setTimeout(() => {
      document.addEventListener("click", this.boundCloseOnClickOutside)
    }, 10)
  }

  close() {
    this.menuTarget.classList.remove("active")
    this.hamburgerTarget.classList.remove("active")
    document.body.style.overflow = ""
    document.removeEventListener("click", this.boundCloseOnClickOutside)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  // Close menu when a nav link is clicked
  closeMenu() {
    this.close()
  }
}

