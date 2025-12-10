import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "previewImage", "previewName", "placeholder", "modal", "modalContent", "backdrop", "uploadForm", "fileInput", "uploadButton", "uploadError", "uploadProgress", "categoryInput"]
  static values = {
    category: { type: String, default: "general" },
    mediaType: { type: String, default: "image" }
  }

  connect() {
    this.updatePreview()
    this.escapeHandler = (event) => {
      if (event.key === "Escape" && this.isOpen()) {
        this.closeModal()
      }
    }
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  openModal(event) {
    event.preventDefault()
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.loadPicker()
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget) {
      this.closeModal()
    }
  }

  isOpen() {
    return !this.modalTarget.classList.contains("hidden")
  }

  async loadPicker() {
    try {
      const url = `/media/picker?category=${encodeURIComponent(this.categoryValue)}&media_type=${encodeURIComponent(this.mediaTypeValue)}`
      const response = await fetch(url)
      const html = await response.text()
      this.modalContentTarget.innerHTML = html
    } catch (error) {
      const mediaLabel = this.mediaTypeValue === "video" ? "videos" : "images"
      this.modalContentTarget.innerHTML = `<p class="p-4 text-red-600">Failed to load ${mediaLabel}</p>`
    }
  }

  select(event) {
    const { id, url, filename } = event.params
    this.selectImage(id, url, filename)
  }

  clear(event) {
    event.preventDefault()
    this.inputTarget.value = ""

    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("hidden")
    }
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.remove("hidden")
    }
  }

  updatePreview() {
    const hasValue = this.inputTarget.value && this.inputTarget.value !== ""

    if (this.hasPreviewTarget && this.hasPlaceholderTarget) {
      if (hasValue) {
        this.previewTarget.classList.remove("hidden")
        this.placeholderTarget.classList.add("hidden")
      } else {
        this.previewTarget.classList.add("hidden")
        this.placeholderTarget.classList.remove("hidden")
      }
    }
  }

  async upload(event) {
    event.preventDefault()

    if (!this.hasFileInputTarget) return

    const file = this.fileInputTarget.files[0]
    if (!file) {
      this.showUploadError("Please select a file to upload")
      return
    }

    this.showUploadProgress()

    const formData = new FormData()
    formData.append("file", file)

    // Get category from hidden input in the picker form
    if (this.hasCategoryInputTarget) {
      formData.append("category", this.categoryInputTarget.value)
    } else {
      formData.append("category", this.categoryValue)
    }

    // Include media type for video uploads
    formData.append("media_type", this.mediaTypeValue)

    try {
      const response = await fetch("/media", {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: formData
      })

      const data = await response.json()

      if (response.ok) {
        this.selectImage(data.id, data.url, data.filename)
      } else {
        this.showUploadError(data.error || "Upload failed")
      }
    } catch (error) {
      this.showUploadError("Upload failed. Please try again.")
    }
  }

  selectImage(id, url, filename) {
    this.inputTarget.value = id

    if (this.hasPreviewImageTarget) {
      this.previewImageTarget.src = url
    }
    if (this.hasPreviewNameTarget) {
      this.previewNameTarget.textContent = filename
    }
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.add("hidden")
    }
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.remove("hidden")
    }

    this.closeModal()
  }

  showUploadError(message) {
    if (this.hasUploadErrorTarget) {
      this.uploadErrorTarget.textContent = message
      this.uploadErrorTarget.classList.remove("hidden")
    }
    if (this.hasUploadProgressTarget) {
      this.uploadProgressTarget.classList.add("hidden")
    }
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.disabled = false
    }
  }

  showUploadProgress() {
    if (this.hasUploadErrorTarget) {
      this.uploadErrorTarget.classList.add("hidden")
    }
    if (this.hasUploadProgressTarget) {
      this.uploadProgressTarget.classList.remove("hidden")
    }
    if (this.hasUploadButtonTarget) {
      this.uploadButtonTarget.disabled = true
    }
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ""
  }
}
