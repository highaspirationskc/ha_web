import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hidden", "list", "option"]

  connect() {
    this.selectedIndex = -1
    this.isOpen = false

    // Close on click outside
    this.clickOutsideHandler = (event) => {
      if (!this.element.contains(event.target)) {
        this.close()
      }
    }
    document.addEventListener("click", this.clickOutsideHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.clickOutsideHandler)
  }

  open() {
    this.isOpen = true
    this.listTarget.classList.remove("hidden")
    this.filter()
  }

  close() {
    this.isOpen = false
    this.listTarget.classList.add("hidden")
    this.selectedIndex = -1
    this.clearHighlight()
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase().trim()
    let visibleCount = 0

    this.optionTargets.forEach((option, index) => {
      const text = option.textContent.toLowerCase()
      const matches = query === "" || text.includes(query)

      option.classList.toggle("hidden", !matches)
      if (matches) visibleCount++
    })

    // Reset selection when filtering
    this.selectedIndex = -1
    this.clearHighlight()
  }

  select(event) {
    const option = event.currentTarget
    this.selectOption(option)
  }

  selectOption(option) {
    const value = option.dataset.value
    const text = option.textContent.trim()

    this.hiddenTarget.value = value
    this.inputTarget.value = text
    this.close()

    // Dispatch change event for any listeners
    this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  clear() {
    this.hiddenTarget.value = ""
    this.inputTarget.value = ""
    this.inputTarget.focus()
    this.open()
  }

  keydown(event) {
    if (!this.isOpen && (event.key === "ArrowDown" || event.key === "ArrowUp")) {
      this.open()
      return
    }

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.moveSelection(1)
        break
      case "ArrowUp":
        event.preventDefault()
        this.moveSelection(-1)
        break
      case "Enter":
        event.preventDefault()
        if (this.selectedIndex >= 0) {
          const visibleOptions = this.visibleOptions()
          if (visibleOptions[this.selectedIndex]) {
            this.selectOption(visibleOptions[this.selectedIndex])
          }
        }
        break
      case "Escape":
        this.close()
        this.inputTarget.blur()
        break
    }
  }

  moveSelection(direction) {
    const visibleOptions = this.visibleOptions()
    if (visibleOptions.length === 0) return

    this.clearHighlight()

    this.selectedIndex += direction
    if (this.selectedIndex < 0) {
      this.selectedIndex = visibleOptions.length - 1
    } else if (this.selectedIndex >= visibleOptions.length) {
      this.selectedIndex = 0
    }

    visibleOptions[this.selectedIndex].classList.add("bg-indigo-600", "text-white")
    visibleOptions[this.selectedIndex].scrollIntoView({ block: "nearest" })
  }

  clearHighlight() {
    this.optionTargets.forEach((option) => {
      option.classList.remove("bg-indigo-600", "text-white")
    })
  }

  visibleOptions() {
    return this.optionTargets.filter((option) => !option.classList.contains("hidden"))
  }
}
