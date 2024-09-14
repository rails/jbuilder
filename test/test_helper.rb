require "bundler/setup"

require "rails"

require "jbuilder"

require "active_support/core_ext/array/access"
require "active_support/cache/memory_store"
require "active_support/json"
require "active_model"
require 'action_controller/railtie'
require 'action_view/railtie'

require "active_support/testing/autorun"
require "mocha/minitest"

ActiveSupport.test_order = :random

ENV["RAILS_ENV"] ||= "test"

class << Rails
  def cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

Jbuilder::CollectionRenderer.collection_cache = Rails.cache

class Post < Struct.new(:id, :body, :author_name)
  def cache_key
    "post-#{id}"
  end
end

class Racer < Struct.new(:id, :name)
  extend ActiveModel::Naming
  include ActiveModel::Conversion
end

# Instantiate an Application in order to trigger the initializers
Class.new(Rails::Application) do
  config.secret_key_base = 'secret'
  config.eager_load = false
end.initialize!

# Touch AV::Base in order to trigger :action_view on_load hook before running the tests
ActionView::Base.inspect
