import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "backdrop"]

  connect() {
    // Close on escape key
    this.escapeHandler = (event) => {
      if (event.key === "Escape" && this.isOpen()) {
        this.close()
      }
    }
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  open(event) {
    // If a specific modal target is specified, use that
    const targetId = event?.currentTarget?.dataset?.modalTarget
    if (targetId && targetId !== "dialog" && targetId !== "backdrop") {
      const targetModal = document.getElementById(targetId)
      if (targetModal) {
        targetModal.classList.remove("hidden")
        document.body.classList.add("overflow-hidden")
        return
      }
    }

    // Default behavior - open this controller's dialog
    if (this.hasDialogTarget) {
      this.dialogTarget.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
    }
  }

  close() {
    if (this.hasDialogTarget) {
      this.dialogTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }

  closeOnBackdrop(event) {
    // Only close if clicking directly on the backdrop, not on modal content
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  isOpen() {
    return this.hasDialogTarget && !this.dialogTarget.classList.contains("hidden")
  }
}
