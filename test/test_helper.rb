# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new


# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end


# Attempt to mimic behavior of the below
# https://jestjs.io/docs/en/expect#tomatchobjectobject
def assert_match_object actual, expected
  if actual.class == Array and expected.class == Array
    assert actual.length == expected.length
    actual.zip(expected).each do |ac, ex|
      assert_match_object ac, ex
    end
  elsif actual.class == Hash and expected.class == Hash
    expected.keys.each do |k|
      ex = expected[k]
      ac = actual[k]
      assert_equal ex, ac, "#{k}: #{ex} #{ac}"
    end
  else
    raise ArgumentError.new("#{actual} and #{expected} must either both be Array's or Hash's")
  end
end


# For some reason the standard assert_throws isn't catching correctly
def assert_throws2 sym, msg = nil
  caught = nil

  begin
    yield
    caught = false
  rescue sym
    caught = true
  end

  assert caught, message(msg) { default }
end
