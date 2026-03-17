import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "radio", "submitButton"]

  connect() {
    this.updateSubmitState()
  }

  selectScore(event) {
    const label = event.target.closest("label")
    if (!label) return

    const questionContainer = label.closest(".py-5")
    const allLabels = questionContainer.querySelectorAll("label")

    allLabels.forEach(l => {
      l.classList.remove("bg-indigo-50")
      l.querySelector("span").classList.remove("text-gray-900", "font-medium")
      l.querySelector("span").classList.add("text-gray-500")
    })

    label.classList.add("bg-indigo-50")
    label.querySelector("span").classList.remove("text-gray-500")
    label.querySelector("span").classList.add("text-gray-900", "font-medium")

    this.updateSubmitState()
  }

  updateSubmitState() {
    if (!this.hasSubmitButtonTarget) return

    const questions = this.element.querySelectorAll(".py-5:has(input[type='radio'])")
    const totalQuestions = questions.length
    let answeredCount = 0

    questions.forEach(q => {
      if (q.querySelector("input[type='radio']:checked")) {
        answeredCount++
      }
    })

    this.submitButtonTarget.disabled = answeredCount < totalQuestions
  }
}
