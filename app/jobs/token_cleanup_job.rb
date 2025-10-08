class TokenCleanupJob < ApplicationJob
  queue_as :default

  def perform
    AuthService.cleanup_inactive_tokens
  end
end
