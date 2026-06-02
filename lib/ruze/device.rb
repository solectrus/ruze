module Ruze
  # Holds the Gigya trusted-device identity (gmid/ucid) that lets us skip the
  # two-factor prompt on subsequent logins.
  #
  # This default implementation keeps the pair in memory only. For headless
  # operation across process restarts, seed it from durable storage and persist
  # the pair (see #gmid/#ucid) after a successful bootstrap:
  #
  #   device = Ruze::Device.new(gmid: stored_gmid, ucid: stored_ucid)
  #   Ruze::Car.new(email, password, device: device)
  class Device
    def initialize(gmid: nil, ucid: nil)
      @gmid = gmid
      @ucid = ucid
    end
    attr_reader :gmid, :ucid

    # Returns { gmid:, ucid: } or nil when no (complete) device is available.
    def load
      return nil if gmid.to_s.empty? || ucid.to_s.empty?

      { gmid: gmid, ucid: ucid }
    end

    def save(gmid:, ucid:)
      @gmid = gmid
      @ucid = ucid
    end
  end
end
