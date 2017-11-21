require "bundler/setup"
require "active_support"
require 'active_support/core_ext/array/access'
require "rails/version"
require "jbuilder"

if Rails::VERSION::STRING > "4.0"
  require "active_support/testing/autorun"
else
  require "test/unit"
end


if ActiveSupport.respond_to?(:test_order=)
  ActiveSupport.test_order = :random
end
