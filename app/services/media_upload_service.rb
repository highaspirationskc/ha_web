# frozen_string_literal: true

class MediaUploadService
  Result = Struct.new(:success?, :medium, :error, keyword_init: true)

  def initialize(user)
    @user = user
  end

  def upload(file:, category: "general", media_type: "image", alt_text: nil)
    return Result.new(success?: false, error: "No file provided") unless file

    category = "general" unless Medium::CATEGORIES.include?(category)
    media_type = "image" unless %w[image video].include?(media_type)

    result = if media_type == "video"
      CloudflareStreamService.upload(file)
    else
      CloudflareImagesService.upload(file)
    end

    medium = Medium.new(
      uploaded_by: @user,
      cloudflare_id: result[:cloudflare_id],
      filename: result[:filename],
      content_type: result[:content_type],
      width: result[:width],
      height: result[:height],
      media_type: media_type,
      category: category,
      alt_text: alt_text
    )

    if medium.save
      Result.new(success?: true, medium: medium)
    else
      Result.new(success?: false, error: medium.errors.full_messages.join(", "))
    end
  rescue CloudflareImagesService::UploadError, CloudflareStreamService::UploadError => e
    Result.new(success?: false, error: e.message)
  rescue CloudflareImagesService::ConfigurationError, CloudflareStreamService::ConfigurationError
    Result.new(success?: false, error: "Cloudflare is not configured properly")
  end

  def delete(medium)
    return Result.new(success?: false, error: "Medium not found") unless medium

    begin
      if medium.video?
        CloudflareStreamService.delete(medium.cloudflare_id)
      else
        CloudflareImagesService.delete(medium.cloudflare_id)
      end
    rescue CloudflareImagesService::DeleteError, CloudflareStreamService::DeleteError => e
      Rails.logger.warn("Failed to delete #{medium.media_type} from Cloudflare: #{e.message}")
    end

    medium.destroy!
    Result.new(success?: true)
  rescue StandardError => e
    Result.new(success?: false, error: e.message)
  end
end
