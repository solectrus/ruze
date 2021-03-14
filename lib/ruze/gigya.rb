require 'net/http'
require 'json'

module Ruze
  class Gigya
    BASE_URL = 'https://accounts.eu1.gigya.com'.freeze

    def initialize(email, password)
      raise ArgumentError unless email.is_a?(String) && password.is_a?(String)

      @email = email
      @password = password
    end
    attr_reader :email, :password

    def person_id
      @person_id ||= return_from Net::HTTP.post_form(
        uri('/accounts.getAccountInfo'),
        'ApiKey'      => api_key,
        'login_token' => session_cookie_value
      ), keys: %w[data personId]
    end

    def jwt
      @jwt ||= return_from Net::HTTP.post_form(
        uri('/accounts.getJWT'),
        'ApiKey'      => api_key,
        'login_token' => session_cookie_value,
        'fields'      => 'data.personId,data.gigyaDataCenter',
        'expiration'  => 900
      ), keys: %w[id_token]
    end

    def session_cookie_value
      @session_cookie_value ||= return_from Net::HTTP.post_form(
        uri('/accounts.login'),
        'ApiKey'   => api_key,
        'loginID'  => email,
        'password' => password
      ), keys: %w[sessionInfo cookieValue]
    end

    private

    def api_key
      ENV.fetch('GIGYA_API_KEY')
    end

    def uri(path)
      URI("#{BASE_URL}#{path}")
    end

    def return_from(response, keys:)
      unless response.is_a?(Net::HTTPOK)
        caller = caller_locations(1, 1)[0].label
        raise Error, "Error in #{caller}: #{response.message} (#{response.code})"
      end

      json = JSON.parse(response.body)
      unless json['errorCode']&.zero?
        caller = caller_locations(1, 1)[0].label
        raise Error, "Error in #{caller}: #{json['errorDetails']}"
      end

      json.dig(*keys)
    end
  end
end
