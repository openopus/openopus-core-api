require 'test_helper'

class OrganizationIntegrationTest < ActionDispatch::IntegrationTest
  test "Can get Organization" do
    Organization.create!(name: 'Foo')
    Organization.create!(name: 'Bar')

    get "/test_api/organization", as: :json
    assert_equal 200, status
    json_response = response.parsed_body
    expected_response = [ {"name" => "Foo"}, {"name" => "Bar"} ]

    assert_match_object json_response, expected_response
  end

  test "Can show Organization" do
    org = Organization.create!(name: 'Foo')

    get "/test_api/organization/#{org.id}", as: :json
    assert_equal 200, status

    assert_match_object response.parsed_body, { "name" => 'Foo' }
  end

  test "Can query Organization by name" do
    Organization.create!(name: 'Foo')
    Organization.create!(name: 'Bar')

    get "/test_api/organization?name=Foo", as: :json
    assert_equal 200, status

    assert_match_object response.parsed_body, [{ "name" => 'Foo' }]
  end

  test "Cannot query Organization by latitude" do
    Organization.create!(name: 'Foo', latitude: 1)
    Organization.create!(name: 'Bar')

    get "/test_api/organization?latitude=1", as: :json
    assert_equal 200, status

    # Note that we get all responses back.
    # No filter was applied on the latitude
    assert_match_object response.parsed_body, [
                          {"name" => 'Foo', "latitude" => "1.0"},
                          {"name" => 'Bar'}
                        ]
  end

  test "Regular user can't update Organization" do
    org = Organization.create!(name: 'Foo')
    user = User.create!()
    put "/test_api/organization/#{org.id}",
        params: { name: 'Bar', user_id: user.id },
        as: :json
    assert_equal 401, status
  end

  test "Admin's can update Organizations they're employed at" do
    org = Organization.create!(name: 'Foo')
    user = User.create!(role: "admin")
    Employment.create!(organization: org, user: user)

    put "/test_api/organization/#{org.id}",
        params: { name: 'Bar', user_id: user.id },
        as: :json

    assert_equal 200, status

    assert_match_object response.parsed_body, { "name" => 'Bar' }
  end

  test "Cannot create Organization" do
    assert_throws2 ActionController::RoutingError do
      post "/test_api/organization"
    end
  end

  test "Cannot delete Organization" do
    assert_throws2 ActionController::RoutingError do
      delete "/test_api/organization"
    end
  end
end
