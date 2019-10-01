require "test_helper"

class StationIntegrationTest < ActionDispatch::IntegrationTest
  test "Requesting a Station without workers returns the standard Station" do
    org = Organization.create!
    reg = Region.create!(organization: org, name: 'Foo')
    stat = Station.create!(region: reg, name: 'Bar')

    get "/test_api/station/#{stat.id}", as: :json

    assert_equal 200, status

    assert_match_object response.parsed_body, { "name" => "Bar" }

    assert_nil response.parsed_body["workers"]
  end

  test "Requesting a Station with workers returns said workers" do
    org = Organization.create!
    reg = Region.create!(organization: org, name: 'Foo')
    stat = Station.create!(region: reg, name: 'Bar')

    bob = User.create!(name: 'Bob')
    jim = User.create!(name: 'Jim')

    StationRole.create(station: stat, job_title: "Bob's title", user: bob)
    StationRole.create(station: stat, job_title: "Jim's title", user: jim)

    get "/test_api/station/#{stat.id}?workers=true", as: :json

    assert_equal 200, status

    expected_workers = [
      {
        "worker" => "Bob",
        "job_title" => "Bob's title"
      },
      {
        "worker" => "Jim",
        "job_title" => "Jim's title"
      }
    ]

    assert_match_object response.parsed_body, { "name" => "Bar", "workers" => expected_workers }
  end

  test "Requesting multiple Stations with workers returns workers for all stations" do
    org = Organization.create!
    reg = Region.create!(organization: org, name: 'Foo')

    stat1 = Station.create!(region: reg, name: 'Bar')
    stat2 = Station.create!(region: reg, name: 'Baz')

    bob = User.create!(name: 'Bob')
    jim = User.create!(name: 'Jim')

    StationRole.create(station: stat1, job_title: "Bob's title", user: bob)
    StationRole.create(station: stat1, job_title: "Jim's title", user: jim)


    StationRole.create(station: stat2, job_title: "Bob's title", user: bob)
    StationRole.create(station: stat2, job_title: "Jim's title", user: jim)


    get "/test_api/station?workers=true", as: :json

    assert_equal 200, status

    expected_workers = [
      {
        "worker" => "Bob",
        "job_title" => "Bob's title"
      },
      {
        "worker" => "Jim",
        "job_title" => "Jim's title"
      }
    ]

    assert_match_object response.parsed_body, [
                          { "name" => "Bar", "workers" => expected_workers },
                          { "name" => "Baz", "workers" => expected_workers }
                        ]
  end
end
