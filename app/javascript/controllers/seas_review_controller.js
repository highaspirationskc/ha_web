import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["questionBlock", "adjustPanel", "reviewedCount", "completeButton", "progressText", "reviewedBadge", "feedback"]

  setReviewAction(event) {
    const responseId = event.target.dataset.responseId
    const action = event.target.value

    // Toggle adjust panel visibility
    const panel = this.adjustPanelTargets.find(p => p.dataset.responseId === responseId)
    if (panel) {
      if (action === "adjusted") {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    }

    // Get feedback for this response
    const feedbackEl = this.feedbackTargets.find(f => f.dataset.responseId === responseId)
    const feedback = feedbackEl ? feedbackEl.value : null

    // Get adjusted score if adjusting
    let adjustedScore = null
    if (action === "adjusted") {
      const checkedAdjust = this.element.querySelector(`input[name="adjusted_score_${responseId}"]:checked`)
      adjustedScore = checkedAdjust ? checkedAdjust.value : null
    }

    this.saveReview(responseId, action, adjustedScore, feedback)
  }

  setAdjustedScore(event) {
    const responseId = event.target.dataset.responseId
    const adjustedScore = event.target.value

    const feedbackEl = this.feedbackTargets.find(f => f.dataset.responseId === responseId)
    const feedback = feedbackEl ? feedbackEl.value : null

    this.saveReview(responseId, "adjusted", adjustedScore, feedback)
  }

  saveFeedback(event) {
    const responseId = event.target.dataset.responseId
    const feedback = event.target.value

    // Get current review action
    const checkedAction = this.element.querySelector(`input[name="review_action_${responseId}"]:checked`)
    if (!checkedAction) return // Don't save feedback alone without a review action

    const action = checkedAction.value
    let adjustedScore = null
    if (action === "adjusted") {
      const checkedAdjust = this.element.querySelector(`input[name="adjusted_score_${responseId}"]:checked`)
      adjustedScore = checkedAdjust ? checkedAdjust.value : null
    }

    this.saveReview(responseId, action, adjustedScore, feedback)
  }

  async saveReview(responseId, reviewAction, adjustedScore, feedback) {
    const evaluationId = window.location.pathname.match(/\/seas_evaluations\/(\d+)/)?.[1]
    if (!evaluationId) return

    const token = document.querySelector('meta[name="csrf-token"]')?.content

    const body = {
      response_id: responseId,
      review_action: reviewAction,
      adjusted_score: adjustedScore,
      feedback: feedback
    }

    try {
      const response = await fetch(`/seas_evaluations/${evaluationId}/save_review`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token
        },
        body: JSON.stringify(body)
      })

      if (response.ok) {
        const data = await response.json()
        this.updateProgress(data.reviewed_count, data.total_count)
        this.showReviewedBadge(responseId)
      }
    } catch (error) {
      console.error("Failed to save review:", error)
    }
  }

  updateProgress(reviewedCount, totalCount) {
    if (this.hasReviewedCountTarget) {
      this.reviewedCountTarget.textContent = reviewedCount
    }

    if (this.hasCompleteButtonTarget) {
      this.completeButtonTarget.disabled = reviewedCount < totalCount
    }
  }

  showReviewedBadge(responseId) {
    // Find or create badge
    let badge = this.reviewedBadgeTargets.find(b => b.dataset.responseId === responseId)
    if (!badge) {
      const actionRadios = this.element.querySelector(`input[name="review_action_${responseId}"]`)
      if (actionRadios) {
        const container = actionRadios.closest(".flex.items-center.space-x-4")
        if (container) {
          badge = document.createElement("span")
          badge.className = "px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800"
          badge.dataset.seasReviewTarget = "reviewedBadge"
          badge.dataset.responseId = responseId
          badge.textContent = "Reviewed"
          container.appendChild(badge)
        }
      }
    }
  }
}
