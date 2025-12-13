# frozen_string_literal: true

class GradeCardsService
  Result = Struct.new(:success?, :grade_card, :error, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def list
    return GradeCard.none unless @user&.can?(:index, :grade_cards)

    Authorization.accessible_grade_cards(@user)
  end

  def find(id)
    return nil unless @user&.can?(:show, :grade_cards)

    Authorization.accessible_grade_cards(@user).find_by(id: id)
  end

  def create(mentee:, file: nil, medium: nil, description: nil)
    unless mentee
      return Result.new(success?: false, error: "Mentee not found")
    end

    unless @user.can?(:create, :grade_cards, mentee)
      return Result.new(success?: false, error: "You don't have permission to add grade cards for this mentee")
    end

    # Either upload a new file or use an existing medium
    if file
      upload_result = MediaUploadService.new(@user).upload(
        file: file,
        category: "grade_card",
        media_type: "image"
      )

      unless upload_result.success?
        return Result.new(success?: false, error: upload_result.error)
      end

      medium = upload_result.medium
    elsif medium.nil?
      return Result.new(success?: false, error: "Please select a file to upload")
    end

    grade_card = GradeCard.new(
      mentee: mentee,
      medium: medium,
      description: description
    )

    if grade_card.save
      Result.new(success?: true, grade_card: grade_card)
    else
      Result.new(success?: false, error: grade_card.errors.full_messages.join(", "))
    end
  end

  def delete(grade_card)
    unless grade_card
      return Result.new(success?: false, error: "Grade card not found")
    end

    unless @user.can?(:delete, :grade_cards)
      return Result.new(success?: false, error: "You don't have permission to delete grade cards")
    end

    # GradeCard has after_destroy callback that cleans up the medium
    grade_card.destroy!
    Result.new(success?: true)
  rescue StandardError => e
    Result.new(success?: false, error: e.message)
  end
end
