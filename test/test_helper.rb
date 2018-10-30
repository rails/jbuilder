require "bundler/setup"
require "active_support"
require 'active_support/core_ext/array/access'
require "rails/version"
require "jbuilder"

require "active_support/testing/autorun"

ActiveSupport.test_order = :random
