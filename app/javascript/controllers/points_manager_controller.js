import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pointsDisplay", "pointsInput", "resultDisplay", "messageArea"]
  static values = {
    currentPoints: Number,
    adjustment: { type: Number, default: 0 }
  }

  connect() {
    // Get current points from the display element
    const resultElement = this.resultDisplayTarget
    const currentPointsText = resultElement.textContent
    this.currentPointsValue = parseInt(currentPointsText.replace(/[^0-9-]/g, '')) || 0
    this.updateDisplay()
  }

  increment() {
    this.adjustmentValue += 1
    this.updateDisplay()
  }

  decrement() {
    // Prevent going below 0 total points
    const newTotal = this.currentPointsValue + this.adjustmentValue - 1
    if (newTotal < 0) {
      // Flash a warning or prevent
      return
    }
    this.adjustmentValue -= 1
    this.updateDisplay()
  }

  updateDisplay() {
    // Update the points display
    this.pointsDisplayTarget.textContent = this.adjustmentValue >= 0 ? `+${this.adjustmentValue}` : this.adjustmentValue
    
    // Update the hidden input
    this.pointsInputTarget.value = this.adjustmentValue
    
    // Update the result display
    const newTotal = this.currentPointsValue + this.adjustmentValue
    this.resultDisplayTarget.textContent = `${newTotal}pts`
    
    // Color code the result
    if (newTotal < 0) {
      this.resultDisplayTarget.classList.remove('text-indigo-600')
      this.resultDisplayTarget.classList.add('text-red-600')
    } else {
      this.resultDisplayTarget.classList.remove('text-red-600')
      this.resultDisplayTarget.classList.add('text-indigo-600')
    }
  }

  toggleMessage(event) {
    if (event.target.checked) {
      this.messageAreaTarget.classList.remove('hidden')
    } else {
      this.messageAreaTarget.classList.add('hidden')
    }
  }
}