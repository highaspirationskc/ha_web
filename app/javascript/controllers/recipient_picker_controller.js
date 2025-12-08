import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chip", "chipsContainer", "hiddenInputs", "modal", "backdrop", "searchInput", "userList", "userOption", "replyModeContainer"]

  connect() {
    this.selectedUsers = new Map()

    // Close modal on escape
    this.escapeHandler = (event) => {
      if (event.key === "Escape" && this.isModalOpen()) {
        this.closeModal()
      }
    }
    document.addEventListener("keydown", this.escapeHandler)
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
  }

  openModal() {
    this.modalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.searchInputTarget.focus()
    this.filterUsers()
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.searchInputTarget.value = ""
    this.filterUsers()
  }

  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget) {
      this.closeModal()
    }
  }

  isModalOpen() {
    return !this.modalTarget.classList.contains("hidden")
  }

  filterUsers() {
    const query = this.searchInputTarget.value.toLowerCase().trim()

    this.userOptionTargets.forEach((option) => {
      const text = option.dataset.searchText.toLowerCase()
      const matches = query === "" || text.includes(query)
      option.classList.toggle("hidden", !matches)
    })
  }

  selectUser(event) {
    const option = event.currentTarget
    const userId = option.dataset.userId
    const userName = option.dataset.userName
    const userRole = option.dataset.userRole

    if (this.selectedUsers.has(userId)) {
      return // Already selected
    }

    this.selectedUsers.set(userId, { name: userName, role: userRole })
    this.renderChips()
    this.updateHiddenInputs()
    this.updateUserListState()
  }

  removeUser(event) {
    const userId = event.currentTarget.dataset.userId
    this.selectedUsers.delete(userId)
    this.renderChips()
    this.updateHiddenInputs()
    this.updateUserListState()
  }

  renderChips() {
    // Clear existing chips (except the add button)
    const existingChips = this.chipsContainerTarget.querySelectorAll('[data-recipient-chip]')
    existingChips.forEach(chip => chip.remove())

    // Add chips for each selected user
    const addButton = this.chipsContainerTarget.querySelector('[data-add-button]')

    this.selectedUsers.forEach((user, userId) => {
      const chip = document.createElement('span')
      chip.setAttribute('data-recipient-chip', '')
      chip.className = 'inline-flex items-center gap-x-1.5 rounded-md bg-indigo-100 px-2 py-1 text-sm font-medium text-indigo-700'
      chip.innerHTML = `
        ${user.name}
        <button type="button" data-user-id="${userId}" data-action="recipient-picker#removeUser" class="group relative -mr-1 h-3.5 w-3.5 rounded-sm hover:bg-indigo-200">
          <span class="sr-only">Remove</span>
          <svg viewBox="0 0 14 14" class="h-3.5 w-3.5 stroke-indigo-700/50 group-hover:stroke-indigo-700/75">
            <path d="M4 4l6 6m0-6l-6 6" />
          </svg>
        </button>
      `
      this.chipsContainerTarget.insertBefore(chip, addButton)
    })
  }

  updateHiddenInputs() {
    // Clear existing hidden inputs
    this.hiddenInputsTarget.innerHTML = ""

    // Add hidden input for each selected user
    this.selectedUsers.forEach((user, userId) => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'message[recipient_ids][]'
      input.value = userId
      this.hiddenInputsTarget.appendChild(input)
    })
  }

  updateUserListState() {
    // Update visual state of user options in the modal
    this.userOptionTargets.forEach((option) => {
      const userId = option.dataset.userId
      const isSelected = this.selectedUsers.has(userId)

      if (isSelected) {
        option.classList.add("bg-indigo-50", "text-indigo-700")
        option.querySelector('[data-checkmark]')?.classList.remove("hidden")
      } else {
        option.classList.remove("bg-indigo-50", "text-indigo-700")
        option.querySelector('[data-checkmark]')?.classList.add("hidden")
      }
    })

    // Show/hide reply mode options based on recipient count
    this.updateReplyModeVisibility()
  }

  updateReplyModeVisibility() {
    if (!this.hasReplyModeContainerTarget) return

    // Show reply mode options if multiple recipients OR if any group is selected
    const hasGroup = Array.from(this.selectedUsers.keys()).some(id => id.startsWith("group:"))

    if (this.selectedUsers.size > 1 || hasGroup) {
      this.replyModeContainerTarget.classList.remove("hidden")
    } else {
      this.replyModeContainerTarget.classList.add("hidden")
    }
  }
}
