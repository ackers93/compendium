import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "modal"]
  static values = { open: Boolean }

  connect() {
    if (this.openValue) {
      this.open()
    }
  }

  open() {
    this.openValue = true
    document.body.style.overflow = 'hidden'
    this.overlayTarget.classList.add('modal-open')
    this.modalTarget.classList.add('modal-open')
    
    // Focus management
    const focusableElements = this.modalTarget.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    )
    if (focusableElements.length > 0) {
      focusableElements[0].focus()
    }
  }

  close() {
    this.openValue = false
    document.body.style.overflow = ''
    this.overlayTarget.classList.remove('modal-open')
    this.modalTarget.classList.remove('modal-open')
  }

  // Close on escape key
  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  // Close on overlay click
  closeOnOverlayClick(event) {
    if (event.target === this.overlayTarget) {
      this.close()
    }
  }

  // Close on close button click
  closeModal() {
    this.close()
  }
} 