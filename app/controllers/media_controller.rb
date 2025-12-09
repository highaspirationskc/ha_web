class MediaController < ApplicationController
  include ApiAuthentication
  skip_forgery_protection if: :token_request?

  before_action :require_navigation_access, only: %i[index show destroy usage]
  before_action :set_medium, only: %i[show destroy usage]
  before_action :authorize_destroy, only: %i[destroy]

  def index
    @category = params[:category].presence || "general"
    @media = media_scope.images.where(category: @category).recent.page(params[:page]).per(24)
  end

  def show
  end

  def create
    unless current_user.can?(:create, :media)
      return redirect_to media_path, alert: "You don't have permission to upload media"
    end

    file = params[:file]
    unless file
      return redirect_to media_path, alert: "Please select a file to upload"
    end

    result = CloudflareImagesService.upload(file)

    category = params[:category].presence || "general"
    category = "general" unless Medium::CATEGORIES.include?(category)

    @medium = Medium.new(
      uploaded_by: current_user,
      cloudflare_id: result[:cloudflare_id],
      filename: result[:filename],
      content_type: result[:content_type],
      width: result[:width],
      height: result[:height],
      media_type: "image",
      category: category,
      alt_text: params[:alt_text]
    )

    if @medium.save
      respond_to do |format|
        format.html { redirect_to media_path, notice: "Image uploaded successfully." }
        format.json do
          render json: {
            id: @medium.id,
            url: @medium.thumbnail_url,
            filename: @medium.filename
          }
        end
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to media_path, alert: "Failed to save image: #{@medium.errors.full_messages.join(', ')}" }
        format.json { render json: { error: @medium.errors.full_messages.join(", ") }, status: :unprocessable_entity }
      end
    end
  rescue CloudflareImagesService::UploadError => e
    respond_to do |format|
      format.html { redirect_to media_path, alert: e.message }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  rescue CloudflareImagesService::ConfigurationError => e
    respond_to do |format|
      format.html { redirect_to media_path, alert: "Cloudflare Images is not configured properly." }
      format.json { render json: { error: "Cloudflare Images is not configured properly." }, status: :unprocessable_entity }
    end
  end

  def destroy
    if @medium.in_use?
      redirect_to medium_path(@medium), alert: "Cannot delete image that is in use. Remove it from all #{@medium.usage_count} usages first."
      return
    end

    begin
      CloudflareImagesService.delete(@medium.cloudflare_id)
    rescue CloudflareImagesService::DeleteError => e
      Rails.logger.warn("Failed to delete image from Cloudflare: #{e.message}")
    end

    @medium.destroy!
    redirect_to media_path, notice: "Image deleted successfully.", status: :see_other
  end

  def usage
    @usages = @medium.usage
  end

  def picker
    @category = params[:category].presence || "general"
    @category = "general" unless Medium::CATEGORIES.include?(@category)
    @media = media_scope.images.where(category: @category).recent.limit(50)
    render layout: false
  end

  private

  def set_medium
    @medium = Medium.find(params[:id])
  end

  def media_scope
    if current_user.can?(:manage_all, :media)
      Medium.all
    else
      current_user.uploaded_media
    end
  end

  def authorize_destroy
    return if current_user.can?(:manage_all, :media)
    return if @medium.uploaded_by == current_user

    redirect_to medium_path(@medium), alert: "You don't have permission to delete this image"
  end

  def current_user
    api_current_user
  end

  def require_navigation_access
    unless current_user&.can_access?(:media)
      respond_to do |format|
        format.html { redirect_to dashboard_path, alert: "You don't have permission to access this page" }
        format.json { render json: { error: "Forbidden" }, status: :forbidden }
      end
    end
  end

  def token_request?
    request.headers["Authorization"].present?
  end
end
