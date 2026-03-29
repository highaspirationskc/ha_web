import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content", "button", "modal"]
  static values = { active: String }

  connect() {
    // Set initial active tab from URL or default to individual
    const urlParams = new URLSearchParams(window.location.search)
    const tabFromUrl = urlParams.get('tab') || 'individual'
    this.switchToTab(tabFromUrl)
  }

  switch(event) {
    const tabId = event.currentTarget.dataset.tab
    this.switchToTab(tabId)
    
    // Update URL without reload
    const url = new URL(window.location)
    url.searchParams.set('tab', tabId)
    window.history.pushState({}, '', url)
  }

  switchToTab(tabId) {
    // Update buttons
    this.buttonTargets.forEach(button => {
      if (button.dataset.tab === tabId) {
        button.classList.add('border-indigo-500', 'text-indigo-600')
        button.classList.remove('border-transparent', 'text-gray-500')
      } else {
        button.classList.remove('border-indigo-500', 'text-indigo-600')
        button.classList.add('border-transparent', 'text-gray-500')
      }
    })

    // Show/hide content
    this.contentTargets.forEach(content => {
      if (content.dataset.tab === tabId) {
        content.classList.remove('hidden')
      } else {
        content.classList.add('hidden')
      }
    })
  }

  openRedemptionModal(event) {
    const incentiveId = event.currentTarget.dataset.incentiveId
    const modal = document.getElementById(`redemption-modal-${incentiveId}`)
    if (modal) {
      modal.classList.remove('hidden')
    }
  }

  closeRedemptionModal(event) {
    // Close the closest modal ancestor
    const modal = event.currentTarget.closest('[data-rewards-target="modal"]')
    if (modal) {
      modal.classList.add('hidden')
    }
  }

  submitRedemption(event) {
    // Let the form submit normally, but close the modal after submit
    const modal = event.currentTarget.closest('[data-rewards-target="modal"]')
    if (modal) {
      modal.classList.add('hidden')
    }
  }
}
