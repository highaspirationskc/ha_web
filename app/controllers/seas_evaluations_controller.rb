class SeasEvaluationsController < ApplicationController
  layout :choose_layout

  before_action :set_evaluation
  before_action :set_current_season, if: -> { current_user }
  before_action :check_token_validity

  def show
    if @evaluation.completed?
      @snapshot = @evaluation.parsed_snapshot
      if @snapshot
        @domains = @snapshot["domains"]
        @responses_by_question = @evaluation.seas_responses.includes(:seas_question).index_by(&:seas_question_id)
      else
        @domains = SeasDomain.includes(:seas_questions).order(:position).map { |d| domain_to_hash(d) }
        @responses_by_question = @evaluation.seas_responses.includes(:seas_question).index_by(&:seas_question_id)
      end
      render :results
      return
    end

    step = params[:step]

    if step == "review"
      if all_domains_answered?
        @snapshot = @evaluation.parsed_snapshot
        if @snapshot
          @domains = @snapshot["domains"]
        else
          @domains = SeasDomain.includes(:seas_questions).order(:position).map { |d| domain_to_hash(d) }
        end
        @responses_by_question = @evaluation.seas_responses.index_by(&:seas_question_id)
        render partial_for_step("review")
      else
        redirect_to seas_evaluation_path(@evaluation.token, step: current_step)
      end
      return
    end

    @snapshot = @evaluation.parsed_snapshot

    # Load data for the welcome screen
    if step.blank? || step == "0"
      if @snapshot
        @domains = @snapshot["domains"]
      else
        @domains = SeasDomain.order(:position).map { |d| domain_to_hash(d) }
      end
      @welcome_image = SeasSetting.welcome_image
    end

    step = step.present? ? step.to_i : current_step

    if @snapshot
      domain_data = @snapshot["domains"].find { |d| d["position"] == step }
    end

    if domain_data
      @domain = domain_data
    else
      db_domain = SeasDomain.includes(:seas_questions).find_by(position: step)
      unless db_domain
        redirect_to seas_evaluation_path(@evaluation.token, step: 0)
        return
      end
      @domain = domain_to_hash(db_domain)
    end

    question_ids = @domain["questions"].map { |q| q["id"] }
    @existing_responses = @evaluation.seas_responses
      .where(seas_question_id: question_ids)
      .index_by(&:seas_question_id)
    @total_domains = @snapshot ? @snapshot["domains"].size : SeasDomain.count
    @current_step = step
  end

  def save_section
    domain = SeasDomain.find_by!(position: params[:domain_position])
    questions = domain.seas_questions

    unless params[:responses].present? && params[:responses].keys.size == questions.count
      redirect_to seas_evaluation_path(@evaluation.token, step: domain.position),
        alert: "Please answer all questions before continuing."
      return
    end

    params[:responses].each do |question_id, score|
      @evaluation.seas_responses.find_or_initialize_by(seas_question_id: question_id).tap do |response|
        response.score = score.to_i
        response.save!
      end
    end

    @evaluation.update!(status: "in_progress") if @evaluation.status == "pending"

    next_domain = SeasDomain.where("position > ?", domain.position).order(:position).first
    @evaluation.update!(current_domain_position: next_domain&.position)

    if next_domain
      redirect_to seas_evaluation_path(@evaluation.token, step: next_domain.position)
    else
      redirect_to seas_evaluation_path(@evaluation.token, step: "review")
    end
  end

  def complete
    unless all_domains_answered?
      redirect_to seas_evaluation_path(@evaluation.token, step: current_step),
        alert: "Please complete all sections before submitting."
      return
    end

    @evaluation.update!(status: "submitted", completed_at: Time.current)
    @evaluation.update_snapshot_with_scores!
    SeasEvaluationReviewMessage.new(@evaluation).deliver
    redirect_to seas_evaluation_path(@evaluation.token)
  end

  private

  def choose_layout
    current_user ? "application" : "seas"
  end

  def set_evaluation
    @evaluation = SeasEvaluation.find_by!(token: params[:token])
    @mentee = @evaluation.mentee
  rescue ActiveRecord::RecordNotFound
    render :not_found, layout: "seas", status: :not_found
  end

  def check_token_validity
    if @evaluation.expired? && !@evaluation.completed?
      render :expired
    end
  end

  def current_step
    if @evaluation.current_domain_position.present?
      @evaluation.current_domain_position
    else
      first_unanswered_domain_position || 0
    end
  end

  def first_unanswered_domain_position
    answered_question_ids = @evaluation.seas_responses.pluck(:seas_question_id)
    snapshot = @evaluation.parsed_snapshot
    if snapshot
      snapshot["domains"].sort_by { |d| d["position"] }.each do |domain|
        domain_question_ids = domain["questions"].map { |q| q["id"] }
        unless (domain_question_ids - answered_question_ids).empty?
          return domain["position"]
        end
      end
    else
      SeasDomain.includes(:seas_questions).order(:position).each do |domain|
        domain_question_ids = domain.seas_questions.pluck(:id)
        unless (domain_question_ids - answered_question_ids).empty?
          return domain.position
        end
      end
    end
    nil
  end

  def all_domains_answered?
    snapshot = @evaluation.parsed_snapshot
    if snapshot
      total_questions = snapshot["domains"].sum { |d| d["questions"].size }
    else
      total_questions = SeasQuestion.count
    end
    @evaluation.seas_responses.count == total_questions
  end

  def domain_to_hash(domain)
    {
      "id" => domain.id,
      "name" => domain.name,
      "description" => domain.description,
      "position" => domain.position,
      "questions" => domain.seas_questions.order(:position).map do |q|
        { "id" => q.id, "text" => q.text, "position" => q.position }
      end
    }
  end

  def partial_for_step(step)
    case step.to_s
    when "0" then "seas_evaluations/show"
    when "review" then "seas_evaluations/show"
    else "seas_evaluations/show"
    end
  end
end
