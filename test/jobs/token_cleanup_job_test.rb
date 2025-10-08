require "test_helper"

class TokenCleanupJobTest < ActiveJob::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password: "Password123!")
  end

  test "job calls AuthService.cleanup_inactive_tokens" do
    # Just verify it runs without error - the actual cleanup is tested in AuthService specs
    assert_nothing_raised do
      TokenCleanupJob.perform_now
    end
  end

  test "job deletes tokens older than 30 days" do
    old_token = @user.tokens.create!(token_hash: "old_hash")
    old_token.update_column(:updated_at, 31.days.ago)

    recent_token = @user.tokens.create!(token_hash: "recent_hash")

    assert_difference "Token.count", -1 do
      TokenCleanupJob.perform_now
    end

    assert_nil Token.find_by(id: old_token.id)
    assert_not_nil Token.find_by(id: recent_token.id)
  end

  test "job can be enqueued" do
    assert_enqueued_jobs 1 do
      TokenCleanupJob.perform_later
    end
  end

  test "job uses default queue" do
    assert_equal "default", TokenCleanupJob.new.queue_name
  end
end
