# Openopus::Core::Api
This enging delivers a RoR Gem that creates a complete and featureful RESTful API for your existing database.  Installing it for the most basic use takes 10 seconds.

After installation, you have an unsecured RESTful API for your existing database.  The entire way in which this was built is non-invasive, and doesn't require code modification - uninstalling it is as simple as removing the gem and single added route.

To secure and modify the behavior of the API, you will provide your own authentication methods.  An example of how to do this appears below.


## Usage
Add this line to your application's Gemfile:

```ruby
gem 'openopus-core-api'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install openopus-core-api
```

Then:

```bash
  $ bundle exec rails generate openopus:core:api:install
  $ bundle install --path=vendor
```

## Contributing
Send us a pull request, and we promise to read it!

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).




