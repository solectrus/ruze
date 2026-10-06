require_relative 'gigya'
require_relative 'kamereon'

module Ruze
  # One Car can be queried repeatedly: it keeps the login and renews the JWT
  # when needed. Call #reload to fetch fresh vehicle data.
  #
  # logger is any object with #info. It gets a message for each login and
  # each new token.
  class Car
    def initialize(email, password, vin = nil, device: Ruze::Device.new, logger: nil)
      @email = email
      @password = password
      @vin = vin
      @device = device
      @logger = logger
      @gigya = new_gigya
    end

    def battery
      with_session { kamereon.battery }
    end

    def cockpit
      with_session { kamereon.cockpit }
    end

    def location
      with_session { kamereon.location }
    end

    # Forgets the vehicle data, but keeps the login
    def reload
      @kamereon&.reload
      self
    end

    private

    def kamereon
      @kamereon ||= Ruze::Kamereon.new(@gigya.person_id, -> { @gigya.jwt }, @vin)
    end

    def new_gigya
      Ruze::Gigya.new(@email, @password, device: @device, logger: @logger)
    end

    # A reused login can expire. If Renault rejects it, log in again and retry
    # once. A fresh login gets no retry, because it would fail the same way.
    # Other errors (like a failing server) get no new login.
    def with_session
      reused = !@kamereon.nil?
      yield
    rescue AuthenticationError => e
      raise unless reused

      @logger&.info("Login expired (#{e.message}), logging in again")
      @gigya = new_gigya
      @kamereon = nil
      yield
    end
  end
end
