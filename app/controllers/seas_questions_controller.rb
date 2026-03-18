class SeasQuestionsController < AuthenticatedController
  before_action { require_navigation_access(:seas_domains) }
  before_action :set_seas_domain

  def new
    @seas_question = @seas_domain.seas_questions.new
  end

  def edit
    @seas_question = @seas_domain.seas_questions.find(params.expect(:id))
  end

  def create
    @seas_question = @seas_domain.seas_questions.new(seas_question_params)

    respond_to do |format|
      if @seas_question.save
        format.html { redirect_to seas_domain_path(@seas_domain), notice: "Question was successfully created." }
        format.json { render json: @seas_question, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @seas_question.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @seas_question = @seas_domain.seas_questions.find(params.expect(:id))

    respond_to do |format|
      if @seas_question.update(seas_question_params)
        format.html { redirect_to seas_domain_path(@seas_domain), notice: "Question was successfully updated.", status: :see_other }
        format.json { render json: @seas_question, status: :ok }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @seas_question.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @seas_question = @seas_domain.seas_questions.find(params.expect(:id))
    @seas_question.destroy!

    respond_to do |format|
      format.html { redirect_to seas_domain_path(@seas_domain), notice: "Question was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_seas_domain
    @seas_domain = SeasDomain.find(params.expect(:seas_domain_id))
  end

  def seas_question_params
    params.expect(seas_question: [ :text, :position ])
  end
end
