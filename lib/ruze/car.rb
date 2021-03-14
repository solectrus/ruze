require_relative 'gigya'
require_relative 'kamereon'

module Ruze
  class Car
    def initialize(email, password, vin = nil)
      gigya = Ruze::Gigya.new(email, password)
      @kamereon = Ruze::Kamereon.new(gigya.person_id, gigya.jwt, vin)
    end

    def battery
      @kamereon.battery
    end

    def cockpit
      @kamereon.cockpit
    end

    def location
      @kamereon.location
    end
  end
end
