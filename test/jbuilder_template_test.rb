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
end
