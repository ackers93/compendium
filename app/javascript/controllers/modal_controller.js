import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    document.addEventListener('turbo:submit-end', this.handleSubmit)
    this.backgroundId = 'modal-background';
    this.backgroundHtml = this._backgroundHTML();
    document.body.insertAdjacentHTML('beforeend', this.backgroundHtml);
    document.getElementById(this.backgroundId).addEventListener('click', this.close.bind(this));
    document.addEventListener('keyup', this.handleKeyup.bind(this));
  }

  disconnect() {
    document.removeEventListener('turbo:submit-end', this.handleSubmit)
    document.getElementById(this.backgroundId).removeEventListener('click', this.close.bind(this));
    document.removeEventListener('keyup', this.handleKeyup.bind(this));
    document.getElementById(this.backgroundId).remove();
  }

  close() {
    // Remove the modal element so it doesn't blanket the screen
    this.element.remove()

    // Remove src reference from parent frame element
    // Without this, turbo won't re-open the modal on subsequent clicks
    this.element.closest("turbo-frame").src = undefined
  }

  _backgroundHTML() {
    return `<div id="${this.backgroundId}" class="fixed top-0 left-0 w-full h-full" style="background-color: rgba(0, 0, 0, 0.7); z-index: 9998;"></div>`;
  }

  handleKeyup(e) {
    if (e.code == "Escape") {
      this.close()
    }
  }

  handleSubmit = (e) => {
    if (e.detail.success) {
      this.close()
    }
  }
}