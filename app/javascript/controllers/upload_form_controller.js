import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submit", "progress", "progressBar", "progressText"]

  connect() {
    this.formTarget.addEventListener("submit", this.handleSubmit.bind(this))
  }

  handleSubmit(event) {
    const fileInput = this.formTarget.querySelector('input[type="file"]')
    if (!fileInput || !fileInput.files[0]) {
      return
    }

    event.preventDefault()

    const file = fileInput.files[0]
    const formData = new FormData(this.formTarget)

    this.showProgress()

    const xhr = new XMLHttpRequest()

    xhr.upload.addEventListener("progress", (e) => {
      if (e.lengthComputable) {
        const percent = Math.round((e.loaded / e.total) * 100)
        this.updateProgress(percent, e.loaded, e.total)
      }
    })

    xhr.addEventListener("load", () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        this.updateProgressText("Processing...")
        // Let the redirect happen via Turbo
        Turbo.visit(window.location.href)
      } else {
        this.hideProgress()
        alert("Upload failed. Please try again.")
      }
    })

    xhr.addEventListener("error", () => {
      this.hideProgress()
      alert("Upload failed. Please try again.")
    })

    xhr.open("POST", this.formTarget.action)
    xhr.setRequestHeader("Accept", "text/html")
    xhr.setRequestHeader("X-CSRF-Token", this.csrfToken())
    xhr.send(formData)
  }

  showProgress() {
    this.submitTarget.disabled = true
    this.submitTarget.classList.add("opacity-50", "cursor-not-allowed")
    if (this.hasProgressTarget) {
      this.progressTarget.classList.remove("hidden")
    }
  }

  hideProgress() {
    this.submitTarget.disabled = false
    this.submitTarget.classList.remove("opacity-50", "cursor-not-allowed")
    if (this.hasProgressTarget) {
      this.progressTarget.classList.add("hidden")
    }
  }

  updateProgress(percent, loaded, total) {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percent}%`
    }
    if (this.hasProgressTextTarget) {
      const loadedMB = (loaded / (1024 * 1024)).toFixed(1)
      const totalMB = (total / (1024 * 1024)).toFixed(1)
      if (percent < 100) {
        this.progressTextTarget.textContent = `Uploading... ${percent}% (${loadedMB}MB / ${totalMB}MB)`
      } else {
        this.progressTextTarget.textContent = "Processing..."
      }
    }
  }

  updateProgressText(text) {
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = text
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
