require "bundler/setup"
require "rails/version"

if Rails::VERSION::STRING > "4.0"
  require "active_support/testing/autorun"
else
  require "test/unit"
end

require "active_support/test_case"
