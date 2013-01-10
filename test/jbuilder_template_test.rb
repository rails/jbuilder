require 'test/unit'
require 'action_view'
require 'action_view/testing/resolvers'
require 'active_support/cache'
require 'jbuilder'

module Rails
  class Cache
    def initialize
      clear
    end

    def clear; @cache = {}; end

    def write(k, v, opt={})
      @cache[k] = v
    end

    def read(k, opt={})
      @cache[k]
    end

    def fetch(k, opt={}, &block)
      @cache[k] || @cache[k] = block.call
    end
  end

  def self.cache; @cache ||= Cache.new; end
end

class JbuilderTemplateTest < ActionView::TestCase
  def partials
    { "_partial.json.jbuilder" => 'json.content "hello"' }
  end

  def render_jbuilder(source)
    @rendered = []
    lookup_context.view_paths = [ActionView::FixtureResolver.new(partials.merge("test.json.jbuilder" => source))]
    ActionView::Template.new(source, "test", JbuilderHandler, :virtual_path => "test").render(self, {}).strip
  end

  test "rendering" do
    json = render_jbuilder <<-JBUILDER
      json.content "hello"
    JBUILDER

    assert_equal "hello", MultiJson.load(json)["content"]
  end

  test "key_format! with parameter" do
    json = render_jbuilder <<-JBUILDER
      json.key_format! :camelize => [:lower]
      json.camel_style "for JS"
    JBUILDER

    assert_equal ['camelStyle'], MultiJson.load(json).keys
  end

  test "key_format! propagates to child elements" do
    json = render_jbuilder <<-JBUILDER
      json.key_format! :upcase
      json.level1 "one"
      json.level2 do
        json.value "two"
      end
    JBUILDER

    result = MultiJson.load(json)
    assert_equal "one", result["LEVEL1"]
    assert_equal "two", result["LEVEL2"]["VALUE"]
  end

  test "partial! renders partial" do
    json = render_jbuilder <<-JBUILDER
      json.partial! 'partial'
    JBUILDER

    assert_equal "hello", MultiJson.load(json)["content"]
  end

  test "fragment caching a JSON object" do
    self.controller.perform_caching = true
    Rails.cache.clear
    render_jbuilder <<-JBUILDER
      json.cache!("cachekey") do
        json.name "Cache"
      end
    JBUILDER

    json = render_jbuilder <<-JBUILDER
      json.cache!("cachekey") do
        json.name "Miss"
      end
    JBUILDER

    MultiJson.load(json).tap do |parsed|
      assert_equal "Cache", parsed['name']
    end
  end

  test "fragment caching deserializes an array" do
    Rails.cache.clear
    self.controller.perform_caching = true
    render_jbuilder <<-JBUILDER
      json.cache!("cachekey") do
        json.array! ['a', 'b', 'c']
      end
    JBUILDER

    json = render_jbuilder <<-JBUILDER
      json.cache!("cachekey") do
        json.array! ['1', '2', '3']
      end
    JBUILDER

    MultiJson.load(json).tap do |parsed|
      assert_equal ["a", "b", "c"], parsed
    end
  end

end
