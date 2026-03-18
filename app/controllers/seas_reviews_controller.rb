class SeasReviewsController < AuthenticatedController
  before_action :set_evaluation
  before_action :authorize_review, except: [:destroy]
  before_action :authorize_delete, only: [:destroy]

  def review
    @snapshot = @evaluation.parsed_snapshot
    if @snapshot
      @domains = @snapshot["domains"]
    else
      @domains = SeasDomain.includes(:seas_questions).order(:position)
    end
    @responses_by_question = @evaluation.seas_responses.includes(:seas_question).index_by(&:seas_question_id)
    @reviewed_count = @evaluation.seas_responses.count(&:reviewed?)
    @total_count = @evaluation.seas_responses.count
    @mentee_user = @evaluation.mentee.user
    @read_only = read_only?
  end

  def claim_review
    unless @evaluation.status == "submitted"
      redirect_to review_seas_evaluation_path(@evaluation), alert: "This evaluation cannot be claimed for review."
      return
    end

    @evaluation.update!(reviewer: current_user, status: "in_review", review_started_at: Time.current)
    redirect_to review_seas_evaluation_path(@evaluation), notice: "You have claimed this evaluation for review."
  end

  def save_review
    response = @evaluation.seas_responses.find(params[:response_id])

    unless @evaluation.status == "in_review" && @evaluation.reviewer == current_user
      head :forbidden
      return
    end

    response.update!(
      review_action: params[:review_action],
      adjusted_score: params[:review_action] == "adjusted" ? params[:adjusted_score].to_i : nil,
      feedback: params[:feedback].presence
    )

    reviewed_count = @evaluation.seas_responses.reload.count(&:reviewed?)
    total_count = @evaluation.seas_responses.count

    render json: { reviewed_count: reviewed_count, total_count: total_count }
  end

  def complete_review
    unless @evaluation.status == "in_review" && @evaluation.reviewer == current_user
      redirect_to review_seas_evaluation_path(@evaluation), alert: "You cannot complete this review."
      return
    end

    unless @evaluation.seas_responses.all?(&:reviewed?)
      redirect_to review_seas_evaluation_path(@evaluation), alert: "Please review all questions before completing."
      return
    end

    @evaluation.update!(status: "reviewed", reviewed_at: Time.current)
    @evaluation.update_snapshot_with_review_data!
    redirect_to user_path(@evaluation.mentee.user), notice: "SEAS review completed successfully."
  end

  def destroy
    user = @evaluation.mentee.user
    @evaluation.destroy!
    redirect_to user_path(user), notice: "SEAS evaluation was successfully deleted.", status: :see_other
  end

  def discard_review
    unless @evaluation.status == "in_review" && @evaluation.reviewer == current_user
      redirect_to review_seas_evaluation_path(@evaluation), alert: "You cannot discard this review."
      return
    end

    @evaluation.seas_responses.update_all(review_action: nil, adjusted_score: nil, feedback: nil)
    @evaluation.update!(reviewer: nil, status: "submitted")
    redirect_to review_seas_evaluation_path(@evaluation), notice: "Review discarded. The evaluation is back in the queue."
  end

  private

  def set_evaluation
    @evaluation = SeasEvaluation.find(params[:id])
  end

  def authorize_review
    unless current_user.can?(:review, :seas_evaluations)
      redirect_to dashboard_path, alert: "You don't have permission to review evaluations."
    end
  end

  def authorize_delete
    unless current_user.can?(:delete, :seas_evaluations)
      redirect_to dashboard_path, alert: "You don't have permission to delete evaluations."
    end
  end

  def read_only?
    return true if @evaluation.status == "reviewed"
    return true if @evaluation.status == "in_review" && @evaluation.reviewer != current_user
    return true if @evaluation.status == "submitted" # hasn't been claimed yet
    false
  end
end
