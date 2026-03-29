import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["redeemView", "denyView", "messageArea"]

  showDeny() {
    if (this.hasRedeemViewTarget) this.redeemViewTarget.classList.add("hidden")
    if (this.hasDenyViewTarget) this.denyViewTarget.classList.remove("hidden")
  }

  showRedeem() {
    if (this.hasDenyViewTarget) this.denyViewTarget.classList.add("hidden")
    if (this.hasRedeemViewTarget) this.redeemViewTarget.classList.remove("hidden")
  }

  toggleMessage(event) {
    const checkbox = event.currentTarget
    const messageArea = checkbox.closest("[data-controller='redemption-form']")?.querySelector("[data-redemption-form-target='messageArea']")
      || this.messageAreaTarget

    if (checkbox.checked) {
      messageArea.classList.remove("hidden")
    } else {
      messageArea.classList.add("hidden")
    }
  }
}
