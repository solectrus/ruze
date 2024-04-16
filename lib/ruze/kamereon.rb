require 'net/http'
require 'json'

module Ruze
  class Kamereon
    BASE_URL = 'https://api-wired-prod-1-euw1.wrd-aws.com/commerce/v1'.freeze
    COUNTRY  = 'DE'.freeze

    def initialize(person_id, gigya_token, vin = nil)
      raise ArgumentError unless person_id.is_a?(String) && gigya_token.is_a?(String)

      @person_id = person_id
      @gigya_token = gigya_token
      @vin = vin
    end
    attr_reader :person_id, :gigya_token

    def account_id
      accounts.first['accountId']
    end

    def accounts
      @accounts ||= return_from get(
        uri("/persons/#{person_id}?country=#{COUNTRY}"),
        headers
      ), keys: %w[accounts]
    end

    def vehicles
      @vehicles ||= return_from get(
        uri("/accounts/#{account_id}/vehicles?country=#{COUNTRY}"),
        headers
      ), keys: %w[vehicleLinks]
    end

    def vin
      @vin ||= vehicles.first.dig('vehicleDetails', 'vin')
    end

    def battery
      @battery ||= return_from get(
        uri("/accounts/#{account_id}/kamereon/kca/car-adapter/v2/cars/#{vin}/battery-status?country=#{COUNTRY}"),
        headers
      ), keys: %w[data attributes]
    end

    def cockpit
      @cockpit ||= return_from get(
        uri("/accounts/#{account_id}/kamereon/kca/car-adapter/v1/cars/#{vin}/cockpit?country=#{COUNTRY}"),
        headers
      ), keys: %w[data attributes]
    end

    def location
      @location ||= return_from get(
        uri("/accounts/#{account_id}/kamereon/kca/car-adapter/v1/cars/#{vin}/location?country=#{COUNTRY}"),
        headers
      ), keys: %w[data attributes]
    rescue Error => e
      raise e unless e.message.include?('404')

      {}
    end

    private

    def api_key
      ENV.fetch('KAMEREON_API_KEY')
    end

    def headers
      {
        'apikey'           => api_key,
        'x-gigya-id_token' => gigya_token
      }
    end

    def uri(path)
      URI("#{BASE_URL}#{path}")
    end

    def get(url, headers)
      Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(url)
        headers.each_pair { |key, value| request[key] = value }
        http.request(request)
      end
    end

    def return_from(response, keys:)
      unless response.is_a?(Net::HTTPOK)
        caller = caller_locations(1, 1)[0].label
        raise Error, "Error in #{caller}: #{response.message} (#{response.code})"
      end

      json = JSON.parse(response.body)
      json.dig(*keys)
    end
  end
end
