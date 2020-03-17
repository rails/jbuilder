require "bundler/setup"

require "active_support"
require "active_support/core_ext/array/access"
require "active_support/cache/memory_store"
require "active_support/json"
require "active_model"
require "action_view"
require "rails/version"

require "jbuilder"

require "active_support/testing/autorun"
require "mocha/minitest"

ActiveSupport.test_order = :random

class << Rails
  def cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

class Post < Struct.new(:id, :body, :author_name); end

class Racer < Struct.new(:id, :name)
  extend ActiveModel::Naming
  include ActiveModel::Conversion
end

ActionView::Template.register_template_handler :jbuilder, JbuilderHandler

ActionView::Base.remove_possible_method :fragment_name_with_digest
ActionView::Base.remove_possible_method :cache_fragment_name
