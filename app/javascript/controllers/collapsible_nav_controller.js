import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]
  static values = { open: Boolean }

  connect() {
    this.render()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  openValueChanged() {
    this.render()
  }

  render() {
    if (this.hasContentTarget) {
      this.contentTarget.classList.toggle("hidden", !this.openValue)
    }
    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("rotate-90", this.openValue)
    }
  }
}
