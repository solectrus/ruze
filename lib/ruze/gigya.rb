require 'net/http'
require 'json'
require_relative 'errors'
require_relative 'device'

module Ruze
  class Gigya
    BASE_URL      = 'https://accounts.eu1.gigya.com'.freeze
    SOCIALIZE_URL = 'https://socialize.eu1.gigya.com'.freeze

    def initialize(email, password, device: Device.new)
      raise ArgumentError unless email.is_a?(String) && password.is_a?(String)

      @email = email
      @password = password
      @device = device
    end
    attr_reader :email, :password, :device

    def person_id
      @person_id ||= dig_from post(
        "#{BASE_URL}/accounts.getAccountInfo",
        { 'apiKey' => api_key, 'login_token' => session_cookie_value }
      ), label: 'person_id', keys: %w[data personId]
    end

    def jwt
      @jwt ||= dig_from post(
        "#{BASE_URL}/accounts.getJWT",
        { 'apiKey'      => api_key,
          'login_token' => session_cookie_value,
          'fields'      => 'data.personId,data.gigyaDataCenter',
          'expiration'  => 900 }
      ), label: 'jwt', keys: %w[id_token]
    end

    # Logs in using the trusted device and returns the session cookie value.
    # Raises TwoFactorRequired when Renault demands a fresh 2FA verification.
    def session_cookie_value
      @session_cookie_value ||= login
    end

    # --- Two-factor bootstrap ------------------------------------------------
    #
    # The Gigya 2FA trusted-device flow below (initTFA -> getEmails ->
    # sendVerificationCode -> completeVerification -> finalizeTFA -> re-login)
    # was reverse-engineered by the renault-api community:
    # https://github.com/hacf-fr/renault-api/issues/2132
    #
    # Run once interactively to establish a trusted device:
    #
    #   gigya = Ruze::Gigya.new(email, password)
    #   puts "Code sent to #{gigya.request_verification_code}"
    #   gigya.verify_code(gets.strip)
    #
    # After that, session_cookie_value works headlessly for ~30 days.

    # Triggers the email verification code and returns the obfuscated address it
    # was sent to. Returns nil when no verification is needed -- either the
    # account has no 2FA or this device is already trusted.
    def request_verification_code
      ids = device_ids
      reg_token = login_reg_token(ids)
      return nil unless reg_token

      assertion = init_tfa(reg_token, ids)
      mail = first_email(assertion, ids)
      phv_token = send_verification_code(mail['id'], assertion, ids)

      @bootstrap = { ids: ids, reg_token: reg_token, assertion: assertion, phv_token: phv_token }
      mail['obfuscated']
    end

    # Completes the 2FA flow with the emailed code, finalizes the device as
    # trusted (remembered for ~30 days) and persists it.
    def verify_code(code)
      raise Error, 'Call request_verification_code before verify_code' unless @bootstrap

      ids = @bootstrap[:ids]
      provider_assertion = complete_verification(code, ids)
      finalize_tfa(provider_assertion, ids)

      @session_cookie_value = login(ids)
      device.save(gmid: ids[:gmid], ucid: ids[:ucid])
      @session_cookie_value
    end

    private

    def login(ids = device_ids)
      json = parse post(
        "#{BASE_URL}/accounts.login",
        login_params(ids), cookie: cookie(ids)
      )

      case json['errorCode']
      when 0
        json.dig('sessionInfo', 'cookieValue')
      when 403_101
        raise TwoFactorRequired,
              'Two-factor authentication required. Run the bootstrap flow to trust this device.'
      else
        raise Error, "Error in session_cookie_value: #{error_detail(json)}"
      end
    end

    # Like #login but returns the regToken from a pending-2FA response instead of
    # raising. Returns nil when the account is already logged in without 2FA.
    def login_reg_token(ids)
      json = parse post(
        "#{BASE_URL}/accounts.login",
        login_params(ids), cookie: cookie(ids)
      )
      return json['regToken'] if json['errorCode'] == 403_101
      return nil if json['errorCode']&.zero?

      raise Error, "Error in session_cookie_value: #{error_detail(json)}"
    end

    def login_params(ids)
      {
        'apiKey'   => api_key,
        'loginID'  => email,
        'password' => password,
        'gmid'     => ids[:gmid],
        'ucid'     => ids[:ucid]
      }
    end

    def init_tfa(reg_token, ids)
      dig_from post(
        "#{BASE_URL}/accounts.tfa.initTFA",
        { 'apiKey' => api_key, 'regToken' => reg_token, 'provider' => 'gigyaEmail',
          'mode' => 'verify', 'gmid' => ids[:gmid], 'ucid' => ids[:ucid] },
        cookie: cookie(ids)
      ), label: 'init_tfa', keys: %w[gigyaAssertion]
    end

    def first_email(assertion, ids)
      emails = dig_from post(
        "#{BASE_URL}/accounts.tfa.email.getEmails",
        { 'apiKey' => api_key, 'gigyaAssertion' => assertion, 'gmid' => ids[:gmid], 'ucid' => ids[:ucid] },
        cookie: cookie(ids)
      ), label: 'get_emails', keys: %w[emails]
      raise Error, 'No verified email address available for 2FA' if emails.nil? || emails.empty?

      emails.first
    end

    def send_verification_code(email_id, assertion, ids)
      dig_from post(
        "#{BASE_URL}/accounts.tfa.email.sendVerificationCode",
        { 'apiKey' => api_key, 'emailID' => email_id, 'gigyaAssertion' => assertion,
          'lang' => 'en', 'gmid' => ids[:gmid], 'ucid' => ids[:ucid] },
        cookie: cookie(ids)
      ), label: 'send_verification_code', keys: %w[phvToken]
    end

    def complete_verification(code, ids)
      dig_from post(
        "#{BASE_URL}/accounts.tfa.email.completeVerification",
        { 'apiKey' => api_key, 'gigyaAssertion' => @bootstrap[:assertion],
          'phvToken' => @bootstrap[:phv_token], 'code' => code,
          'gmid' => ids[:gmid], 'ucid' => ids[:ucid] },
        cookie: cookie(ids)
      ), label: 'complete_verification', keys: %w[providerAssertion]
    end

    # tempDevice=false marks the device as remembered (no 2FA for ~30 days).
    def finalize_tfa(provider_assertion, ids)
      json = parse post(
        "#{BASE_URL}/accounts.tfa.finalizeTFA",
        { 'apiKey' => api_key, 'gigyaAssertion' => @bootstrap[:assertion],
          'providerAssertion' => provider_assertion, 'tempDevice' => 'false',
          'regToken' => @bootstrap[:reg_token], 'gmid' => ids[:gmid], 'ucid' => ids[:ucid] },
        cookie: cookie(ids)
      )
      raise Error, "Error in finalize_tfa: #{error_detail(json)}" unless json['errorCode']&.zero?

      json
    end

    def device_ids
      @device_ids ||= device.load || fetch_ids
    end

    def fetch_ids
      json = parse post("#{SOCIALIZE_URL}/socialize.getIDs", { 'apiKey' => api_key })
      raise Error, "Error in fetch_ids: #{error_detail(json)}" unless json['errorCode']&.zero?

      { gmid: json['gmid'], ucid: json['ucid'] }
    end

    def cookie(ids)
      "gmid=#{ids[:gmid]}; ucid=#{ids[:ucid]}"
    end

    def api_key
      ENV.fetch('GIGYA_API_KEY')
    end

    def post(url, params, cookie: nil)
      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(params.merge('format' => 'json'))
      request['Cookie'] = cookie if cookie
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end
    end

    def parse(response)
      JSON.parse(response.body)
    end

    def dig_from(response, label:, keys:)
      json = parse(response)
      raise Error, "Error in #{label}: #{error_detail(json)}" unless json['errorCode']&.zero?

      json.dig(*keys)
    end

    def error_detail(json)
      json['errorDetails'] || json['errorMessage'] || "errorCode #{json['errorCode']}"
    end
  end
end
