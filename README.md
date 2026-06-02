# RuZE
[![Test](https://github.com/solectrus/ruze/actions/workflows/main.yml/badge.svg)](https://github.com/solectrus/ruze/actions/workflows/main.yml)
[![wakatime](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/60f52429-f36d-4981-84e7-930c71a92d95.svg)](https://wakatime.com/badge/user/697af4f5-617a-446d-ba58-407e7f3e0243/project/60f52429-f36d-4981-84e7-930c71a92d95)

Unofficial Ruby client to access the API of Renault ZE. Get vehicle data like mileage, charging state and GPS location.

Requires an account at https://myr.renault.de (or local equivalent).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruze'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install ruze


## Obtaining API keys

You need two API keys. Both can be obtained from Renault; they're the same for everyone and shouldn't be confused with your email/password credentials. Since the API is apparently not intended for the public, I do not want to publish the API keys here. It's your turn to find them, then store them as ENV variables:

```bash
export GIGYA_API_KEY=...
export KAMEREON_API_KEY=...
```



## Usage

```ruby
car = Ruze::Car.new('john@example.com', 'my-password')

car.battery
# {
#                                   "timestamp" => "2026-03-13T09:59:12Z",
#                                "batteryLevel" => 66,
#                             "batteryAutonomy" => 194,
#                                  "plugStatus" => 0,
#                              "chargingStatus" => 0.0,
#                       "chargingRemainingTime" => 55,
#     "chargingRemainingTimeLastUpdateDateTime" => "2026-03-13T09:30:00Z"
# }

car.cockpit
# {
#     "fuelAutonomy" => 0.0,
#     "fuelQuantity" => 0.0,
#     "totalMileage" => 12345.67,
#        "timestamp" => "2026-03-13T09:59:12Z"
# }

car.location
# {
#       "gpsDirection" => nil,
#        "gpsLatitude" => 50.12345678,
#       "gpsLongitude" => 6.12345678,
#     "lastUpdateTime" => "2026-03-12T11:43:18Z"
# }
```


## Two-factor authentication

Renault enforces two-factor authentication (2FA) on Gigya accounts, so a
password alone is no longer enough to log in. RuZE handles this by establishing
a *trusted device* once: after a single email verification, Renault remembers
the device for about 30 days, during which logins succeed without a prompt.

### One-time setup

Trigger a verification code, confirm it with the 6-digit code Renault emails to
your account, then read the resulting trusted-device pair:

```ruby
gigya = Ruze::Gigya.new('john@example.com', 'my-password')

gigya.request_verification_code # emails a 6-digit code (returns nil if none is needed)

gigya.verify_code('123456')

gmid = gigya.device.gmid
ucid = gigya.device.ucid
# Store this gmid/ucid pair somewhere durable (env vars, a file, a database).
```

`Ruze::Device` keeps the pair in memory only, so persisting it is up to you. The
pair stays valid across renewals, so you store it once.

### Normal usage

Seed a device with your stored pair and `Ruze::Car` logs in without prompting:

```ruby
device = Ruze::Device.new(gmid: gmid, ucid: ucid)
car = Ruze::Car.new('john@example.com', 'my-password', device: device)
```

When the device is missing or has expired, login raises
`Ruze::TwoFactorRequired` — repeat the one-time setup to renew it.


## Background

Thanks to James Muscat (@jamesremuscat) for making PyZE, the Python client for Renault ZE API:

* https://github.com/jamesremuscat/pyze
* https://muscatoxblog.blogspot.com/2019/07/delving-into-renaults-new-api.html


There is an iOS and macOS application called "Zeddy" from Matt Cheetham (@MattCheetham) which seems to use the same API:

* https://apps.apple.com/de/app/zeddy/id1451295003


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solectrus/ruze. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/solectrus/ruze/blob/main/CODE_OF_CONDUCT.md).


## Disclaimer

This project is not affiliated with, endorsed by, or connected to Renault. I accept no responsibility for any consequences, intended or accidental, as a result of interacting with Renault's API using this project.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).


Copyright (c) 2021-2026 Georg Ledermann, released under the AGPL-3.0 License

## Code of Conduct

Everyone interacting in the Renault project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/solectrus/ruze/blob/main/CODE_OF_CONDUCT.md).
