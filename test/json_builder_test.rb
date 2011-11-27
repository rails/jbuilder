require 'test/unit'
require 'active_support/test_case'

require 'json_builder'


class JsonBuilderTest < ActiveSupport::TestCase
  test "single key" do
    json = JsonBuilder.encode do |json|
      json.content "hello"
    end
    
    assert_equal "hello", JSON.parse(json)["content"]
  end

  test "multiple keys" do
    json = JsonBuilder.encode do |json|
      json.title "hello"
      json.content "world"
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "hello", parsed["title"]
      assert_equal "world", parsed["content"]
    end
  end
  
  test "extracting from object" do
    person = Struct.new(:name, :age).new("David", 32)
    
    json = JsonBuilder.encode do |json|
      json.extract! person, :name, :age
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "David", parsed["name"]
      assert_equal 32, parsed["age"]
    end
  end
  
  test "nesting single child with block" do
    json = JsonBuilder.encode do |json|
      json.author do |json|
        json.name "David"
        json.age  32
      end
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "David", parsed["author"]["name"]
      assert_equal 32, parsed["author"]["age"]
    end
  end
  
  test "nesting multiple children with block" do
    json = JsonBuilder.encode do |json|
      json.comments do |json|
        json.child! { |json| json.content "hello" }
        json.child! { |json| json.content "world" }
      end
    end

    JSON.parse(json).tap do |parsed|
      assert_equal "hello", parsed["comments"].first["content"]
      assert_equal "world", parsed["comments"].second["content"]
    end
  end
  
  test "nesting multiple children from array" do
    comments = [ Struct.new(:content).new("hello"), Struct.new(:content).new("world") ]
    
    json = JsonBuilder.encode do |json|
      json.comments comments, :content
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "hello", parsed["comments"].first["content"]
      assert_equal "world", parsed["comments"].second["content"]
    end
  end
  
  test "double nesting" do
    json = JsonBuilder.encode do |json|
      json.author do |json|
        json.name "David"
        json.age  32
        
        json.comments do |json|
          json.child! { |json| json.content "hello" }
          json.child! { |json| json.content "world" }
        end
      end
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "hello", parsed["author"]["comments"].first["content"]
      assert_equal "world", parsed["author"]["comments"].second["content"]
    end
  end
end