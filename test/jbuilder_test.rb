require 'test/unit'
require 'active_support/test_case'

require 'jbuilder'

class JbuilderTest < ActiveSupport::TestCase
  test "single key" do
    json = Jbuilder.encode do |json|
      json.content "hello"
    end

    assert_equal "hello", JSON.parse(json)["content"]
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

  if RUBY_VERSION > '1.9'
  eval <<-EOF
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
  EOF
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
      json.comments do |comments|
        comments.child! { |child| child.content "hello" }
        comments.child! { |child| child.content "world" }
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

  if RUBY_VERSION > '1.9'
  eval <<-EOT
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
  EOT
  end

  test "array nested inside nested hash" do
    json = Jbuilder.encode do |json|
      json.author do |author|
        author.name "David"
        author.age  32

        author.comments do |comments|
          comments.child! { |child| child.content "hello" }
          comments.child! { |child| child.content "world" }
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

  test "dynamically set a key/value" do
    json = Jbuilder.encode do |json|
      json.set!(:each, "stuff")
    end

    assert_equal "stuff", JSON.parse(json)["each"]
  end

  test "false/nil values can be set" do
    json = Jbuilder.encode do |json|
      json.false_value false
      json.nil_value nil
    end

    JSON.parse(json).tap do |parsed|
      assert parsed.key?("false_value"), "The false value key is not present"
      assert_equal false, parsed["false_value"]

      assert parsed.key?("nil_value"), "The nil value key is not present"
      assert_equal nil, parsed["nil_value"]
    end
  end

  test "empty arrays are not encoded as objects" do
    json = Jbuilder.encode do |json|
      json.comments([]) do |json, comment|
        json.author = comment.author
      end
    end

    JSON.parse(json).tap do |parsed|
      assert parsed.key?("comments"), "The comments key is not present"
      assert parsed["comments"].is_a?(Array), "The comments key is not an array"
      assert parsed["comments"].empty?, "The comments array is not empty"
    end
  end
end