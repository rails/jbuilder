require 'test/unit'
require 'active_support/test_case'
require 'active_support/inflector'
require 'action_dispatch'
require 'action_view'

require 'jbuilder'
require 'jbuilder_template'

class JbuilderTemplateTest < ActiveSupport::TestCase
  test "rendering" do
    json = JbuilderTemplate.encode(binding) do |json|
      json.content "hello"
    end
    
    assert_equal "hello", JSON.parse(json)["content"]
  end

  test "key_format! with parameter" do
    json = JbuilderTemplate.new(binding)
    json.key_format! :camelize => [:lower]
    json.camel_style "for JS"

    assert_equal ['camelStyle'], json.attributes!.keys
  end

  test "key_format! propagates to child elements" do
    json = JbuilderTemplate.new(binding)
    json.key_format! :upcase
    json.level1 "one"
    json.level2 do |json|
      json.value "two"
    end

    result = json.attributes!
    assert_equal "one", result["LEVEL1"]
    assert_equal "two", result["LEVEL2"]["VALUE"]
  end
end
