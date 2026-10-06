module Ruze
  class Error < StandardError; end

  # Raised when Renault rejects the login or the token (HTTP 401 or 403).
  # A new login can help.
  class AuthenticationError < Error; end

  # Raised when Renault/Gigya requires two-factor authentication and no trusted
  # device is available. Run the bootstrap flow (request_verification_code +
  # verify_code) to establish a trusted device.
  class TwoFactorRequired < Error; end
end
