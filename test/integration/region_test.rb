require 'test_helper'

class RegionIntegrationTest < ActionDispatch::IntegrationTest
  test "Can get Region if employed at Organization" do
    org = Organization.create!
    reg = Region.create!(organization: org, name: 'Foo')
    user = User.create!
    Employment.create!(organization: org, user: user)

    get "/test_api/region/#{reg.id}?user_id=#{user.id}", as: :json
    assert_equal 200, status

    assert_match_object response.parsed_body, {'name' => 'Foo'}
  end

  test "Can't get Region if not employed at Organization" do
    org = Organization.create!
    reg = Region.create!(organization: org, name: 'Foo')
    user = User.create!

    get "/test_api/region/#{reg.id}?user_id=#{user.id}", as: :json
    assert_equal 401, status
  end

  test "Can't create Region if not admin" do
    org = Organization.create!
    reg = Region.create!(organization: org, name: 'Foo')
    user = User.create!
    Employment.create!(organization: org, user: user)

    post "/test_api/region",
         params: { name: 'Bar', organization_id: org.id },
         as: :json

    assert_equal 403, status
  end

  test "Can create Region if admin" do
    org = Organization.create!
    reg = Region.create!(organization: org, name: 'Foo')
    user = User.create!(role: "admin")
    Employment.create!(organization: org, user: user)

    post "/test_api/region",
         params: { name: 'Bar', organization_id: org.id, user_id: user.id },
         as: :json

    assert_equal 200, status

    assert_match_object response.parsed_body,
                        { "name" => 'Bar', "organization_id" => org.id }
  end

  test "Can delete Region" do
    org = Organization.create!
    reg = Region.create!(organization: org, name: 'Foo')
    user = User.create!(role: "admin")
    Employment.create!(organization: org, user: user)

    delete "/test_api/region/#{reg.id}?user_id=#{user.id}", as: :json

    assert_equal 200, status

    assert_match_object response.parsed_body, { "success" => true }
  end
end
