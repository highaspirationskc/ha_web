class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  def current_user
    if spoofing?
      @current_user ||= User.find_by(id: session[:spoofed_user_id])
    else
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end

  def real_current_user
    @real_current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def spoofing?
    session[:spoofed_user_id].present? && real_current_user&.admin?
  end

  def unread_message_count
    return 0 unless current_user
    @unread_message_count ||= begin
      # Count unread threads (root messages with any unread message for this user)
      unread_message_ids = current_user.message_recipients.unread.pluck(:message_id)
      return 0 if unread_message_ids.empty?

      # Get root IDs for these unread messages
      unread_messages = Message.where(id: unread_message_ids)
      root_ids = unread_messages.map { |m| m.parent_id || m.id }.uniq
      root_ids.count
    end
  end

  helper_method :current_user, :real_current_user, :spoofing?, :unread_message_count
end
