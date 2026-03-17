class SeasNotificationService
  class << self
    # Called when evaluation is created/sent to mentee
    # System message (no author) to the mentee
    def evaluation_sent(evaluation)
      mentee_user = evaluation.mentee.user
      seas_path = Rails.application.routes.url_helpers.seas_evaluation_path(evaluation.token)
      message = Message.create!(
        author: nil,
        subject: "Your SEAS Self Evaluation is ready",
        message: "Hi #{mentee_user.first_name}, your annual SEAS Self Evaluation is " \
                 "<a href=\"#{seas_path}\" class=\"text-indigo-600 hover:text-indigo-900 underline\">ready to complete</a>.",
        reply_mode: :no_replies
      )
      message.recipients << mentee_user
      message.broadcast_to_recipients
      evaluation.update_column(:in_app_sent_at, Time.current)
    end

    # Called when mentee submits evaluation
    # Support message from mentee so all staff see it
    def evaluation_submitted(evaluation)
      mentee_user = evaluation.mentee.user
      review_path = Rails.application.routes.url_helpers.review_seas_evaluation_path(evaluation)
      MessagesService.new(mentee_user).compose(
        subject: "SEAS Evaluation submitted — #{mentee_user.first_name} #{mentee_user.last_name}",
        body: "#{mentee_user.first_name} #{mentee_user.last_name} has submitted their SEAS Self Evaluation " \
              "and it is <a href=\"#{review_path}\" class=\"text-indigo-600 hover:text-indigo-900 underline\">ready for staff review</a>.",
        recipient_ids: ["support"]
      )
    end
  end
end
