import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "hamburger"]

  connect() {
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    this.boundSyncNavbarHeight = this.syncNavbarHeight.bind(this)

    this.syncNavbarHeight()
    window.addEventListener("resize", this.boundSyncNavbarHeight)

    this.resizeObserver = new ResizeObserver(this.boundSyncNavbarHeight)
    this.resizeObserver.observe(this.element)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnClickOutside)
    window.removeEventListener("resize", this.boundSyncNavbarHeight)
    this.resizeObserver?.disconnect()
  }

  syncNavbarHeight() {
    this.element.style.setProperty("--navbar-height", `${this.element.offsetHeight}px`)
  }

  toggle(event) {
    event.stopPropagation()
    this.syncNavbarHeight()
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

