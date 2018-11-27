require 'oj'
require 'rabl'

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

# Fill the cache
Rabl.render(
  nil,
  "template",
  view_path: File.expand_path("../performance/dirk/rabl/views/", __FILE__),
  format: :json,
)

# Everthing before this is run once initially, after is the test
__SETUP__

Rabl.render(
  nil,
  "template",
  view_path: File.expand_path("../performance/dirk/rabl/views/", __FILE__),
  format: :json,
)
