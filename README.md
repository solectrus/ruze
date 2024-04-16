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
car = Ruze::Car.new('me@example.com', 'my-password')

car.battery
# {
#                      "timestamp" => "2021-03-13T09:59:12Z",
#                   "batteryLevel" => 66,
#             "batteryTemperature" => 20,
#                "batteryAutonomy" => 194,
#                "batteryCapacity" => 0,
#         "batteryAvailableEnergy" => 33,
#                     "plugStatus" => 0,
#                 "chargingStatus" => 0.0,
#          "chargingRemainingTime" => 55,
#     "chargingInstantaneousPower" => 0.0
# }

car.cockpit
# {
#     "fuelAutonomy" => 0.0,
#     "fuelQuantity" => 0.0,
#     "totalMileage" => 12345.67
# }

car.location
# {
#       "gpsDirection" => nil,
#        "gpsLatitude" => 50.12345678,
#       "gpsLongitude" => 6.12345678,
#     "lastUpdateTime" => "2021-03-12T11:43:18Z"
# }
```


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


Copyright (c) 2021-2024 Georg Ledermann, released under the AGPL-3.0 License

## Code of Conduct

Everyone interacting in the Renault project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/solectrus/ruze/blob/main/CODE_OF_CONDUCT.md).
