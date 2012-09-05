require 'test/unit'
require 'active_support/test_case'
require 'active_support/inflector'

require 'jbuilder'

class JbuilderTest < ActiveSupport::TestCase
  test "single key" do
    json = Jbuilder.encode do |json|
      json.content "hello"
    end
    
    assert_equal "hello", JSON.parse(json)["content"]
  end

  test "single key with false value" do
    json = Jbuilder.encode do |json|
      json.content false
    end

    assert_equal false, JSON.parse(json)["content"]
  end

  test "single key with nil value" do
    json = Jbuilder.encode do |json|
      json.content nil
    end

    assert JSON.parse(json).has_key?("content")
    assert_equal nil, JSON.parse(json)["content"]
  end

  test "multiple keys" do
    json = Jbuilder.encode do |json|
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
    
    json = Jbuilder.encode do |json|
      json.extract! person, :name, :age
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "David", parsed["name"]
      assert_equal 32, parsed["age"]
    end
  end
  
  test "extracting from object using call style for 1.9" do
    person = Struct.new(:name, :age).new("David", 32)
    
    json = Jbuilder.encode do |json|
      json.(person, :name, :age)
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "David", parsed["name"]
      assert_equal 32, parsed["age"]
    end
  end

  test "extracting from hash" do
    person = {:name => "Jim", :age => 34}

    json = Jbuilder.encode do |json|
      json.extract! person, :name, :age
    end

    JSON.parse(json).tap do |parsed|
      assert_equal "Jim", parsed["name"]
      assert_equal 34, parsed["age"]
    end
  end

  test "nesting single child with block" do
    json = Jbuilder.encode do |json|
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
    json = Jbuilder.encode do |json|
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
  
  test "nesting single child with inline extract" do
    person = Class.new do
      attr_reader :name, :age
      
      def initialize(name, age)
        @name, @age = name, age
      end
    end.new("David", 32)
    
    json = Jbuilder.encode do |json|
      json.author person, :name, :age
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "David", parsed["author"]["name"]
      assert_equal 32,      parsed["author"]["age"]
    end
  end
  
  test "nesting multiple children from array" do
    comments = [ Struct.new(:content, :id).new("hello", 1), Struct.new(:content, :id).new("world", 2) ]
    
    json = Jbuilder.encode do |json|
      json.comments comments, :content
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal ["content"], parsed["comments"].first.keys
      assert_equal "hello", parsed["comments"].first["content"]
      assert_equal "world", parsed["comments"].second["content"]
    end
  end
  
  test "nesting multiple children from array when child array is empty" do
    comments = []
    
    json = Jbuilder.encode do |json|
      json.name "Parent"
      json.comments comments, :content
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "Parent", parsed["name"]
      assert_equal [], parsed["comments"]
    end
  end
  
  test "nesting multiple children from array with inline loop" do
    comments = [ Struct.new(:content, :id).new("hello", 1), Struct.new(:content, :id).new("world", 2) ]
    
    json = Jbuilder.encode do |json|
      json.comments comments do |json, comment|
        json.content comment.content
      end
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal ["content"], parsed["comments"].first.keys
      assert_equal "hello", parsed["comments"].first["content"]
      assert_equal "world", parsed["comments"].second["content"]
    end
  end

  test "nesting multiple children from array with inline loop on root" do
    comments = [ Struct.new(:content, :id).new("hello", 1), Struct.new(:content, :id).new("world", 2) ]
    
    json = Jbuilder.encode do |json|
      json.(comments) do |json, comment|
        json.content comment.content
      end
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "hello", parsed.first["content"]
      assert_equal "world", parsed.second["content"]
    end
  end
  
  test "array nested inside nested hash" do
    json = Jbuilder.encode do |json|
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
  
  test "array nested inside array" do
    json = Jbuilder.encode do |json|
      json.comments do |json|
        json.child! do |json| 
          json.authors do |json|
            json.child! do |json|
              json.name "david"
            end
          end
        end
      end
    end
    
    assert_equal "david", JSON.parse(json)["comments"].first["authors"].first["name"]
  end

  test "nested jbuilder objects" do
    to_nest = Jbuilder.new
    to_nest.nested_value "Nested Test"
    json = Jbuilder.encode do |json|
      json.value "Test"
      json.nested to_nest
    end
    parsed = JSON.parse(json)
    assert_equal "Test", parsed['value']
    assert_equal "Nested Test", parsed["nested"]["nested_value"]
  end

  test "top-level array" do
    comments = [ Struct.new(:content, :id).new("hello", 1), Struct.new(:content, :id).new("world", 2) ]

    json = Jbuilder.encode do |json|
      json.array!(comments) do |json, comment|
        json.content comment.content
      end
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "hello", parsed.first["content"]
      assert_equal "world", parsed.second["content"]
    end
  end 
  
  test "empty top-level array" do
    comments = []
    
    json = Jbuilder.encode do |json|
      json.array!(comments) do |json, comment|
        json.content comment.content
      end
    end
    
    assert_equal [], JSON.parse(json)
  end
  
  test "dynamically set a key/value" do
    json = Jbuilder.encode do |json|
      json.set!(:each, "stuff")
    end
    
    assert_equal "stuff", JSON.parse(json)["each"]
  end

  test "dynamically set a key/nested child with block" do
    json = Jbuilder.encode do |json|
      json.set!(:author) do |json|
        json.name "David"
        json.age 32
      end
    end
    
    JSON.parse(json).tap do |parsed|
      assert_equal "David", parsed["author"]["name"]
      assert_equal 32, parsed["author"]["age"]
    end
  end

  test "query like object" do
    class Person
      attr_reader :name, :age

      def initialize(name, age)
        @name, @age = name, age
      end
    end
    class RelationMock
      def each(&block)
        [Person.new("Bob", 30), Person.new("Frank", 50)].each(&block)
      end
      def empty?
        false
      end
    end

    result = Jbuilder.encode do |json|
      json.relations RelationMock.new, :name, :age
    end

    parsed = JSON.parse(result)
    assert_equal 2, parsed["relations"].length
    assert_equal "Bob", parsed["relations"][0]["name"]
    assert_equal 50, parsed["relations"][1]["age"]
  end

  test "key_format! with parameter" do
    json = Jbuilder.new
    json.key_format! :camelize => [:lower]
    json.camel_style "for JS"

    assert_equal ['camelStyle'], json.attributes!.keys
  end

  test "key_format! with parameter not as an array" do
    json = Jbuilder.new
    json.key_format! :camelize => :lower
    json.camel_style "for JS"

    assert_equal ['camelStyle'], json.attributes!.keys
  end

  test "key_format! propagates to child elements" do
    json = Jbuilder.new
    json.key_format! :upcase
    json.level1 "one"
    json.level2 do |json|
      json.value "two"
    end

    result = json.attributes!
    assert_equal "one", result["LEVEL1"]
    assert_equal "two", result["LEVEL2"]["VALUE"]
  end

  test "key_format! with no parameter" do
    json = Jbuilder.new
    json.key_format! :upcase
    json.lower "Value"

    assert_equal ['LOWER'], json.attributes!.keys
  end

  test "key_format! with multiple steps" do
    json = Jbuilder.new
    json.key_format! :upcase, :pluralize
    json.pill ""

    assert_equal ["PILLs"], json.attributes!.keys
  end

  test "key_format! with lambda/proc" do
    json = Jbuilder.new
    json.key_format! ->(key){ key + " and friends" }
    json.oats ""

    assert_equal ["oats and friends"], json.attributes!.keys
  end

  test "default key_format!" do
    Jbuilder.key_format :camelize => :lower
    json = Jbuilder.new
    json.camel_style "for JS"

    assert_equal ['camelStyle'], json.attributes!.keys
    Jbuilder.class_variable_set("@@key_formatter", Jbuilder::KeyFormatter.new)
  end

  test "don't use default key formatter directly" do
    json = Jbuilder.new
    json.key "value"

    assert_equal [], Jbuilder.class_variable_get("@@key_formatter").instance_variable_get("@cache").keys
  end
end
