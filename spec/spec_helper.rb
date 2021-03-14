require 'ruze'
require 'vcr'
require 'dotenv/load'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# https://stackoverflow.com/a/16681085/57950
class Hash
  def deep_find(key, object = self, found = nil)
    if object.respond_to?(:key?) && object.key?(key)
      object[key]
    elsif object.is_a? Enumerable
      object.find { |*a| found = deep_find(key, a.last) }
      found
    end
  end
end

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = File.expand_path('cassettes', __dir__)
  config.hook_into :webmock
  config.ignore_request { ENV['DISABLE_VCR'] }
  config.ignore_localhost = true

  # Let's you set default VCR mode with VCR=new_episodes for re-recording
  # episodes. :once is VCR default
  record_mode = ENV['VCR'] ? ENV['VCR'].to_sym : :once
  config.default_cassette_options = { record: record_mode, allow_playback_repeats: true }

  config.configure_rspec_metadata!

  sensitive_environment_variables = %w[
    GIGYA_API_KEY
    KAMEREON_API_KEY
    RENAULT_EMAIL
    RENAULT_PASSWORD
    RENAULT_PERSON_ID
    RENAULT_VIN
    RENAULT_ACCOUNT_ID
  ]
  sensitive_environment_variables.each do |key_name|
    config.filter_sensitive_data("<#{key_name}>") { CGI.escape(ENV.fetch(key_name)) }
    config.filter_sensitive_data("<#{key_name}>") { ENV.fetch(key_name) }
  end

  # Hide some sensitive data from responses
  sensitive_responses = {
    'idpId'        => '<IDP_ID>',
    'partyId'      => '<PARTY_ID>',
    'gpsLatitude'  => 52.000,
    'gpsLongitude' => 10.000,
    'totalMileage' => 30_000,
    'mileage'      => 29_900,
    'firstName'    => '<FIRST_NAME>',
    'lastName'     => '<LAST_NAME>',
    'addressLine1' => '<ADDRESS_LINE_1>',
    'city'         => '<CITY>',
    'postalCode'   => '<POSTAL_CODE>',
    'phoneValue'   => '<PHONE_VALUE>',
    'dealerId'     => '<DEALER_ID>',
    'dealerName'   => '<DEALER_NAME>'
  }

  sensitive_responses.each_pair do |key, value|
    config.filter_sensitive_data(value) do |interaction|
      JSON.parse(interaction.response.body).deep_find(key)
    end
  end
end
