require "bundler/setup"
require "active_support"
require "active_support/cache"
require "rails/version"

if Rails::VERSION::STRING > "4.0"
  require "active_support/testing/autorun"
else
  require "test/unit"
end

if ActiveSupport.respond_to?(:test_order=)
  ActiveSupport.test_order = :random
end

class MemoryStore < ActiveSupport::Cache::MemoryStore
  attr_reader :fetch_multi_calls
  attr_reader :write_calls

  def initialize(*)
    super

    @fetch_multi_calls = []
    @write_calls = []
  end

  def clear
    @fetch_multi_calls.clear
    @write_calls.clear

    super
  end

  def fetch_multi(*args)
    fetch_multi_calls << args

    super
  end

  def write(*args)
    write_calls << args

    super
  end
end

module Rails
  def self.cache
    @cache ||= MemoryStore.new
  end
end
