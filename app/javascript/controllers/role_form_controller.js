import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roleSelect", "staffFields", "menteeFields"]

  connect() {
    this.toggleFields()
  }

  toggleFields() {
    const selectedRole = this.roleSelectTarget.value

    // Hide all role-specific fields
    this.staffFieldsTargets.forEach(el => el.style.display = "none")
    this.menteeFieldsTargets.forEach(el => el.style.display = "none")

    // Show fields for the selected role
    switch (selectedRole) {
      case "staff":
        this.staffFieldsTargets.forEach(el => el.style.display = "block")
        break
      case "mentee":
        this.menteeFieldsTargets.forEach(el => el.style.display = "block")
        break
    }
  }
}
