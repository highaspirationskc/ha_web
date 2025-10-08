class AuthService
  # Generates a new token for a user and stores the hashed version in the database
  # Returns the plaintext token string that should be sent to the client
  def self.generate_token(user, device_name: nil)
    plaintext_token = SecureRandom.urlsafe_base64(32)
    hashed_token = hash_token(plaintext_token)

    user.tokens.create!(
      token_hash: hashed_token,
      device_name: device_name
    )

    plaintext_token
  end

  # Authenticates a token and returns the associated user
  # Updates the token's updated_at timestamp if it hasn't been updated in 7 days (throttled touch)
  # Returns nil if token is invalid or not found
  def self.authenticate_token(plaintext_token)
    return nil if plaintext_token.blank?

    hashed_token = hash_token(plaintext_token)
    token = Token.find_by(token_hash: hashed_token)

    return nil unless token

    # Throttled touch - only update if last updated more than 7 days ago
    if token.updated_at < 7.days.ago
      token.touch
    end

    token.user
  end

  # Removes tokens that haven't been used in 30 days
  # Should be called by a daily background job
  def self.cleanup_inactive_tokens
    Token.where("updated_at < ?", 30.days.ago).destroy_all
  end

  private

  # Hashes a plaintext token using SHA256
  def self.hash_token(plaintext_token)
    Digest::SHA256.hexdigest(plaintext_token)
  end
end
