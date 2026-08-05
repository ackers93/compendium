import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step",
    "dot",
    "prev",
    "next",
    "finish",
    "counter",
    "skip",
    "agreementCheckbox",
    "agreeSubmit",
    "viewerSubmit"
  ]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.showStep(this.indexValue)
    this.syncAgreementState()
  }

  next() {
    if (this.indexValue < this.stepTargets.length - 1) {
      this.showStep(this.indexValue + 1)
    }
  }

  previous() {
    if (this.indexValue > 0) {
      this.showStep(this.indexValue - 1)
    }
  }

  goTo(event) {
    const index = Number(event.currentTarget.dataset.stepIndex)
    if (!Number.isNaN(index)) {
      this.showStep(index)
    }
  }

  jumpToAgreement() {
    const agreementIndex = this.stepTargets.findIndex(
      (step) => step.dataset.stepKey === "agreement"
    )
    if (agreementIndex >= 0) {
      this.showStep(agreementIndex)
    }
  }

  syncAgreementState() {
    if (!this.hasAgreementCheckboxTarget || !this.hasAgreeSubmitTarget) return

    const checked = this.agreementCheckboxTarget.checked
    this.agreeSubmitTarget.disabled = !checked
  }

  showStep(index) {
    this.indexValue = index
    const lastIndex = this.stepTargets.length - 1

    this.stepTargets.forEach((step, i) => {
      step.hidden = i !== index
      step.classList.toggle("is-active", i === index)
    })

    this.dotTargets.forEach((dot, i) => {
      dot.classList.toggle("is-active", i === index)
      dot.classList.toggle("is-complete", i < index)
      dot.setAttribute("aria-current", i === index ? "step" : "false")
    })

    if (this.hasPrevTarget) {
      this.prevTarget.disabled = index === 0
    }

    const isLast = index === lastIndex
    if (this.hasNextTarget) {
      this.nextTarget.hidden = isLast
    }
    if (this.hasFinishTarget) {
      this.finishTarget.hidden = !isLast
    }
    if (this.hasSkipTarget) {
      this.skipTarget.hidden = isLast
    }

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `Step ${index + 1} of ${this.stepTargets.length}`
    }

    this.syncAgreementState()
  }
}
