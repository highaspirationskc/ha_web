import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "trigger", "grid"]
  static values = { selected: String }

  connect() {
    if (this.selectedValue) {
      this.inputTarget.value = this.selectedValue
    }
    this.closeHandler = (event) => {
      if (this.isOpen() && !this.element.contains(event.target)) {
        this.close()
      }
    }
    document.addEventListener("click", this.closeHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.closeHandler)
  }

  toggle(event) {
    event.preventDefault()
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.gridTarget.classList.remove("hidden")
  }

  close() {
    this.gridTarget.classList.add("hidden")
  }

  isOpen() {
    return !this.gridTarget.classList.contains("hidden")
  }

  select(event) {
    event.preventDefault()
    const color = event.params.color

    this.inputTarget.value = color
    this.triggerTarget.style.backgroundColor = color
    this.close()
  }
}
