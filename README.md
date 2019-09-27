# Openopus::Core::Api
Define CRUD endpoints via configuration in an extensible manner

## Usage
All APIs are defined under `./app/apis/`.

In ./app/apis/describe_the_group_of_endpoints.rb
```ruby
class AGroupOfEndpoints < Openopus::Core::Api::BaseApi
  on '/the_base_extension' do
    expose User route: '/the_user_route', query_by: ['name']
  end
end
```

Now a set of REST endpoints will be define on `/the_base_extension/the_user_route` with query parameters restricted to `name`.

Additionally, a set of analogous GraphQL endpoints will be defined on `/graphql`. These can be inspected on development by navigating to `/graphiql`


## Installation
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

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
