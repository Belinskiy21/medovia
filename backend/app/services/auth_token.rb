class AuthToken
  TOKEN_TTL = 12.hours

  def self.issue(user)
    verifier.generate(
        {
          "sub" => user.id,
          "email" => user.email,
          "type" => "user"
        },
      expires_in: TOKEN_TTL
    )
  end

  def self.authenticate(raw_token)
    payload = verifier.verified(raw_token)
    return unless payload&.fetch("type", nil) == "user"

    user = User.find_by(id: payload["sub"])
    return unless user

    AuthenticatedPrincipal.new(actor: user.email, role: nil, kind: "user", record: user)
  end

  def self.verifier
    Rails.application.message_verifier("meditrack.auth_token")
  end
end
