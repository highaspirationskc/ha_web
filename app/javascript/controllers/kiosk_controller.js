import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "searchInput",
    "searchModal",
    "searchTerm",
    "searchResults",
    "successModal",
    "exitModal",
    "exitEmail",
    "exitPassword",
    "exitError"
  ]

  static values = {
    eventId: Number,
    searchUrl: String,
    checkinUrl: String,
    exitUrl: String
  }

  connect() {
    // Close modals on escape key
    this.escapeHandler = (event) => {
      if (event.key === "Escape") {
        this.closeModal()
        this.closeExitModal()
      }
    }
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  async search() {
    const query = this.searchInputTarget.value.trim()
    if (!query) return

    try {
      const response = await fetch(`${this.searchUrlValue}?query=${encodeURIComponent(query)}`, {
        headers: {
          "Accept": "application/json"
        },
        credentials: "include"
      })

      if (!response.ok) {
        if (response.status === 401) {
          this.showExitModal()
          return
        }
        throw new Error("Search failed")
      }

      const data = await response.json()
      this.showSearchResults(query, data.users)
    } catch (error) {
      console.error("Search error:", error)
    }
  }

  showSearchResults(query, users) {
    this.searchTermTarget.textContent = query

    if (users.length === 0) {
      this.searchResultsTarget.innerHTML = `
        <div class="p-6 text-center text-gray-500">
          No registered users found matching "${query}"
        </div>
      `
    } else {
      this.searchResultsTarget.innerHTML = users.map(user => `
        <div class="flex items-center justify-between p-4 border-b border-gray-100 last:border-b-0">
          <div>
            <div class="font-semibold text-gray-900">${user.name}</div>
            <div class="text-sm text-gray-500">${user.email}</div>
          </div>
          <button type="button"
                  data-user-id="${user.id}"
                  data-action="click->kiosk#checkin"
                  class="bg-[#1e3a5f] hover:bg-[#152a45] text-white font-semibold py-2 px-4 rounded-lg transition-colors">
            Check In
          </button>
        </div>
      `).join("")
    }

    this.searchModalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  async checkin(event) {
    const userId = event.currentTarget.dataset.userId

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      const response = await fetch(this.checkinUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": csrfToken
        },
        credentials: "include",
        body: JSON.stringify({ user_id: userId })
      })

      if (!response.ok) {
        if (response.status === 401) {
          this.closeModal()
          this.showExitModal()
          return
        }
        throw new Error("Check-in failed")
      }

      const data = await response.json()
      if (data.success) {
        this.closeModal()
        this.showSuccess()
      } else {
        alert(data.errors?.join(", ") || "Check-in failed")
      }
    } catch (error) {
      console.error("Check-in error:", error)
      alert("Check-in failed. Please try again.")
    }
  }

  showSuccess() {
    this.successModalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  closeModal() {
    this.searchModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  back() {
    this.successModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.searchInputTarget.value = ""
  }

  showExitModal() {
    this.exitModalTarget.classList.remove("hidden")
    this.exitErrorTarget.classList.add("hidden")
    document.body.classList.add("overflow-hidden")
    this.exitEmailTarget.focus()
  }

  closeExitModal() {
    this.exitModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  async submitLogin(event) {
    event.preventDefault()

    const email = this.exitEmailTarget.value
    const password = this.exitPasswordTarget.value

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      // First, attempt login
      const loginResponse = await fetch("/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": csrfToken
        },
        credentials: "include",
        body: new URLSearchParams({ email, password }),
        redirect: "manual"
      })

      // Login success redirects (302), failure renders login page (401)
      // With redirect: manual, we get the redirect response directly
      if (loginResponse.status !== 302 && loginResponse.type !== "opaqueredirect") {
        // Login failed
        this.exitErrorTarget.textContent = "Invalid email or password."
        this.exitErrorTarget.classList.remove("hidden")
        return
      }

      // Login succeeded, now check if user has permission to exit
      const exitResponse = await fetch(this.exitUrlValue, {
        method: "GET",
        credentials: "include",
        headers: {
          "Accept": "application/json"
        }
      })

      if (exitResponse.ok) {
        const data = await exitResponse.json()
        if (data.success) {
          window.location.href = data.redirect_url
          return
        }
      }

      // User doesn't have permission
      this.exitErrorTarget.textContent = "You don't have permission to exit kiosk mode. Staff access required."
      this.exitErrorTarget.classList.remove("hidden")
    } catch (error) {
      console.error("Login error:", error)
      this.exitErrorTarget.textContent = "Login failed. Please try again."
      this.exitErrorTarget.classList.remove("hidden")
    }
  }
}
