require 'ruze'
require 'vcr'
require 'dotenv/load'

module TrustedDeviceHelper
  # A Ruze::Device seeded with the trusted gmid/ucid from the environment, so
  # specs log in via the trusted device instead of hitting socialize.getIDs.
  def trusted_device
    Ruze::Device.new(
      gmid: ENV.fetch('RUZE_GMID', 'gmid.test'),
      ucid: ENV.fetch('RUZE_UCID', 'ucid.test')
    )
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include TrustedDeviceHelper

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
  config.ignore_request { ENV.fetch('DISABLE_VCR', false) }
  config.ignore_localhost = true

  # Let's you set default VCR mode with VCR=new_episodes for re-recording
  # episodes. :once is VCR default
  record_mode = ENV['VCR'] ? ENV['VCR'].to_sym : :once
  config.default_cassette_options = { record: record_mode, allow_playback_repeats: true }

  config.configure_rspec_metadata!

  # Net::HTTP returns response bodies as ASCII-8BIT (reinterpret as UTF-8, else
  # String#include? raises Encoding::CompatibilityError later) and scrub volatile
  # secrets that flow across requests/responses and would slip past key-based
  # filters: JWTs, Gigya session/reg tokens and device ids.
  scrub = lambda do |string|
    return string if string.nil?

    string
      .force_encoding('UTF-8')
      .gsub(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/, '<JWT>')
      .gsub(/st2\.s\.[A-Za-z0-9._-]+/, '<TOKEN>')
      .gsub(/gmid\.ver4\.[A-Za-z0-9._-]+/, '<GMID>')
  end

  config.before_record do |interaction|
    interaction.request.body = scrub.call(interaction.request.body)
    interaction.response.body = scrub.call(interaction.response.body)
    [interaction.request.headers, interaction.response.headers].each do |headers|
      headers.each { |name, values| headers[name] = Array(values).map { |v| scrub.call(v) } }
    end
  end

  sensitive_environment_variables = %w[
    GIGYA_API_KEY
    KAMEREON_API_KEY
    RENAULT_EMAIL
    RENAULT_PASSWORD
    RENAULT_PERSON_ID
    RENAULT_VIN
    RENAULT_ACCOUNT_ID
    RUZE_GMID
    RUZE_UCID
  ]
  sensitive_environment_variables.each do |key_name|
    config.filter_sensitive_data("<#{key_name}>") { CGI.escape(ENV.fetch(key_name)) }
    config.filter_sensitive_data("<#{key_name}>") { ENV.fetch(key_name) }
  end

  # Hide some sensitive data from responses
  sensitive_responses = {
    'UID'          => '<UID>',
    'UIDSignature' => '<UID_SIGNATURE>',
    'originUserId'  => '<ORIGIN_USER_ID>',
    'mdmId'         => '<MDM_ID>',
    'externalId'    => '<EXTERNAL_ID>',
    'idpId'        => '<IDP_ID>',
    'partyId'      => '<PARTY_ID>',
    'trackingId'   => '<TRACKING_ID>',
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
