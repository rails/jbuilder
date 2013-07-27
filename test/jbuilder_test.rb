require 'test/unit'
require 'active_support/test_case'
require 'active_support/inflector'
require 'jbuilder'

Comment = Struct.new(:content, :id)

unless JbuilderProxy.method_defined? :instance_eval
  # Faking Object#instance_eval for 1.8 and some newer JRubies
  class JbuilderProxy
    def instance_eval(code)
      eval code
    end
  end
end

class NonEnumerable
  def initialize(collection)
    @collection = collection
  end

  def map(&block)
    @collection.map(&block)
  end
end

class JbuilderTest < ActiveSupport::TestCase
  test 'single key' do
    json = Jbuilder.encode do |json|
      json.content 'hello'
    end

    assert_equal 'hello', MultiJson.load(json)['content']
  end

  test 'single key with false value' do
    json = Jbuilder.encode do |json|
      json.content false
    end

    assert_equal false, MultiJson.load(json)['content']
  end

  test 'single key with nil value' do
    json = Jbuilder.encode do |json|
      json.content nil
    end

    assert MultiJson.load(json).has_key?('content')
    assert_equal nil, MultiJson.load(json)['content']
  end

  test 'multiple keys' do
    json = Jbuilder.encode do |json|
      json.title 'hello'
      json.content 'world'
    end

    parsed = MultiJson.load(json)
    assert_equal 'hello', parsed['title']
    assert_equal 'world', parsed['content']
  end

  test 'extracting from object' do
    person = Struct.new(:name, :age).new('David', 32)

    json = Jbuilder.encode do |json|
      json.extract! person, :name, :age
    end

    parsed = MultiJson.load(json)
    assert_equal 'David', parsed['name']
    assert_equal 32, parsed['age']
  end

  test 'extracting from object using private method' do
    person = Struct.new(:name) do
      private
      def age
        32
      end
    end.new('David')

    message = 'Private method :age was used to extract value. This will be' +
      ' an error in future versions of Jbuilder'

    ::ActiveSupport::Deprecation.expects(:warn).with(message)
    json = Jbuilder.encode do |json|
      json.extract! person, :name, :age
    end
  end

  test 'extracting from object using call style for 1.9' do
    person = Struct.new(:name, :age).new('David', 32)

    json = Jbuilder.encode do |json|
      if ::RUBY_VERSION > '1.9'
        instance_eval 'json.(person, :name, :age)'
      else
        instance_eval 'json.call(person, :name, :age)'
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'David', parsed['name']
    assert_equal 32, parsed['age']
  end

  test 'extracting from hash' do
    person = {:name => 'Jim', :age => 34}

    json = Jbuilder.encode do |json|
      json.extract! person, :name, :age
    end

    parsed = MultiJson.load(json)
    assert_equal 'Jim', parsed['name']
    assert_equal 34, parsed['age']
  end

  test 'nesting single child with block' do
    json = Jbuilder.encode do |json|
      json.author do
        json.name 'David'
        json.age  32
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'David', parsed['author']['name']
    assert_equal 32, parsed['author']['age']
  end

  test 'nesting multiple children with block' do
    json = Jbuilder.encode do |json|
      json.comments do
        json.child! { json.content 'hello' }
        json.child! { json.content 'world' }
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'hello', parsed['comments'].first['content']
    assert_equal 'world', parsed['comments'].second['content']
  end

  test 'nesting single child with inline extract' do
    person = Class.new do
      attr_reader :name, :age

      def initialize(name, age)
        @name, @age = name, age
      end
    end.new('David', 32)

    json = Jbuilder.encode do |json|
      json.author person, :name, :age
    end

    parsed = MultiJson.load(json)
    assert_equal 'David', parsed['author']['name']
    assert_equal 32,      parsed['author']['age']
  end

  test 'nesting multiple children from array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    json = Jbuilder.encode do |json|
      json.comments comments, :content
    end

    parsed = MultiJson.load(json)
    assert_equal ['content'], parsed['comments'].first.keys
    assert_equal 'hello', parsed['comments'].first['content']
    assert_equal 'world', parsed['comments'].second['content']
  end

  test 'nesting multiple children from array when child array is empty' do
    comments = []

    json = Jbuilder.encode do |json|
      json.name 'Parent'
      json.comments comments, :content
    end

    parsed = MultiJson.load(json)
    assert_equal 'Parent', parsed['name']
    assert_equal [], parsed['comments']
  end

  test 'nesting multiple children from array with inline loop' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    json = Jbuilder.encode do |json|
      json.comments comments do |comment|
        json.content comment.content
      end
    end

    parsed = MultiJson.load(json)
    assert_equal ['content'], parsed['comments'].first.keys
    assert_equal 'hello', parsed['comments'].first['content']
    assert_equal 'world', parsed['comments'].second['content']
  end

  test 'handles nil-collections as empty arrays' do
    json = Jbuilder.encode do |json|
      json.comments nil do |comment|
        json.content comment.content
      end
    end

    assert_equal [], MultiJson.load(json)['comments']
  end

  test 'nesting multiple children from a non-Enumerable that responds to #map' do
    comments = NonEnumerable.new([ Comment.new('hello', 1), Comment.new('world', 2) ])

    json = Jbuilder.encode do |json|
      json.comments comments, :content
    end

    parsed = MultiJson.load(json)
    assert_equal ['content'], parsed['comments'].first.keys
    assert_equal 'hello', parsed['comments'].first['content']
    assert_equal 'world', parsed['comments'].second['content']
  end

  test 'nesting multiple chilren from a non-Enumerable that responds to #map with inline loop' do
    comments = NonEnumerable.new([ Comment.new('hello', 1), Comment.new('world', 2) ])

    json = Jbuilder.encode do |json|
      json.comments comments do |comment|
        json.content comment.content
      end
    end

    parsed = MultiJson.load(json)
    assert_equal ['content'], parsed['comments'].first.keys
    assert_equal 'hello', parsed['comments'].first['content']
    assert_equal 'world', parsed['comments'].second['content']
  end

  test 'nesting multiple children from array with inline loop with old api' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    json = Jbuilder.encode do |json|
      ::ActiveSupport::Deprecation.silence do
        json.comments comments do |json, comment|
          json.content comment.content
        end
      end
    end

    parsed = MultiJson.load(json)
    assert_equal ['content'], parsed['comments'].first.keys
    assert_equal 'hello', parsed['comments'].first['content']
    assert_equal 'world', parsed['comments'].second['content']
  end

  test 'nesting multiple children from array with inline loop on root' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    json = Jbuilder.encode do |json|
      json.call(comments) do |comment|
        json.content comment.content
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'hello', parsed.first['content']
    assert_equal 'world', parsed.second['content']
  end

  test 'nesting multiple children from array with inline loop on root with old api' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    json = Jbuilder.encode do |json|
      ::ActiveSupport::Deprecation.silence do
        json.call(comments) do |json, comment|
          json.content comment.content
        end
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'hello', parsed.first['content']
    assert_equal 'world', parsed.second['content']
  end

  test 'array nested inside nested hash' do
    json = Jbuilder.encode do |json|
      json.author do
        json.name 'David'
        json.age  32

        json.comments do
          json.child! { json.content 'hello' }
          json.child! { json.content 'world' }
        end
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'hello', parsed['author']['comments'].first['content']
    assert_equal 'world', parsed['author']['comments'].second['content']
  end

  test 'array nested inside array' do
    json = Jbuilder.encode do |json|
      json.comments do
        json.child! do
          json.authors do
            json.child! do
              json.name 'david'
            end
          end
        end
      end
    end

    assert_equal 'david', MultiJson.load(json)['comments'].first['authors'].first['name']
  end

  test 'directly set an array nested in another array' do
    data = [ { :department => 'QA', :not_in_json => 'hello', :names => ['John', 'David'] } ]
    json = Jbuilder.encode do |json|
      json.array! data do |object|
        json.department object[:department]
        json.names do
          json.array! object[:names]
        end
      end
    end

    assert_equal 'David', MultiJson.load(json)[0]['names'].last
    assert_not_equal 'hello', MultiJson.load(json)[0]['not_in_json']
  end

  test 'directly set an array nested in another array with old api' do
    data = [ { :department => 'QA', :not_in_json => 'hello', :names => ['John', 'David'] } ]
    json = Jbuilder.encode do |json|
      ::ActiveSupport::Deprecation.silence do
        json.array! data do |json, object|
          json.department object[:department]
          json.names do
            json.array! object[:names]
          end
        end
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'David', parsed.first['names'].last
    assert_not_equal 'hello', parsed.first['not_in_json']
  end

  test 'nested jbuilder objects' do
    to_nest = Jbuilder.new
    to_nest.nested_value 'Nested Test'
    json = Jbuilder.encode do |json|
      json.value 'Test'
      json.nested to_nest
    end

    result = {'value' => 'Test', 'nested' => {'nested_value' => 'Nested Test'}}
    assert_equal result, MultiJson.load(json)
  end

  test 'nested jbuilder object via set!' do
    to_nest = Jbuilder.new
    to_nest.nested_value 'Nested Test'
    json = Jbuilder.encode do |json|
      json.value 'Test'
      json.set! :nested, to_nest
    end

    result = {'value' => 'Test', 'nested' => {'nested_value' => 'Nested Test'}}
    assert_equal result, MultiJson.load(json)
  end

  test 'top-level array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    json = Jbuilder.encode do |json|
      json.array!(comments) do |comment|
        json.content comment.content
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'hello', parsed.first['content']
    assert_equal 'world', parsed.second['content']
  end

  test 'extract attributes directly from array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    json = Jbuilder.encode do |json|
      json.array! comments, :content, :id
    end

    parsed = MultiJson.load(json)
    assert_equal 'hello', parsed.first['content']
    assert_equal       1, parsed.first['id']
    assert_equal 'world', parsed.second['content']
    assert_equal       2, parsed.second['id']
  end

  test 'empty top-level array' do
    comments = []

    json = Jbuilder.encode do |json|
      json.array!(comments) do |comment|
        json.content comment.content
      end
    end

    assert_equal [], MultiJson.load(json)
  end

  test 'dynamically set a key/value' do
    json = Jbuilder.encode do |json|
      json.set! :each, 'stuff'
    end

    assert_equal 'stuff', MultiJson.load(json)['each']
  end

  test 'dynamically set a key/nested child with block' do
    json = Jbuilder.encode do |json|
      json.set!(:author) do
        json.name 'David'
        json.age 32
      end
    end

    parsed = MultiJson.load(json)
    assert_equal 'David', parsed['author']['name']
    assert_equal 32, parsed['author']['age']
  end

  test 'dynamically sets a collection' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    json = Jbuilder.encode do |json|
      json.set! :comments, comments, :content
    end

    parsed = MultiJson.load(json)
    assert_equal ['content'], parsed['comments'].first.keys
    assert_equal 'hello', parsed['comments'].first['content']
    assert_equal 'world', parsed['comments'].second['content']
  end

  test 'query like object' do
    class Person
      attr_reader :name, :age

      def initialize(name, age)
        @name, @age = name, age
      end
    end
    class RelationMock
      include Enumerable

      def each(&block)
        [Person.new('Bob', 30), Person.new('Frank', 50)].each(&block)
      end
      def empty?
        false
      end
    end

    result = Jbuilder.encode do |json|
      json.relations RelationMock.new, :name, :age
    end

    parsed = MultiJson.load(result)
    assert_equal 2, parsed['relations'].length
    assert_equal 'Bob', parsed['relations'][0]['name']
    assert_equal 50, parsed['relations'][1]['age']
  end

  test 'initialize via options hash' do
    jbuilder = Jbuilder.new(:key_formatter => 1, :ignore_nil => 2)
    assert_equal 1, jbuilder.instance_eval('@key_formatter')
    assert_equal 2, jbuilder.instance_eval('@ignore_nil')
  end

  test 'key_format! with parameter' do
    json = Jbuilder.new
    json.key_format! :camelize => [:lower]
    json.camel_style 'for JS'

    assert_equal ['camelStyle'], json.attributes!.keys
  end

  test 'key_format! with parameter not as an array' do
    json = Jbuilder.new
    json.key_format! :camelize => :lower
    json.camel_style 'for JS'

    assert_equal ['camelStyle'], json.attributes!.keys
  end

  test 'key_format! propagates to child elements' do
    json = Jbuilder.new
    json.key_format! :upcase
    json.level1 'one'
    json.level2 do
      json.value 'two'
    end

    result = json.attributes!
    assert_equal 'one', result['LEVEL1']
    assert_equal 'two', result['LEVEL2']['VALUE']
  end

  test 'key_format! resets after child element' do
    json = Jbuilder.new
    json.level2 do
      json.key_format! :upcase
      json.value 'two'
    end
    json.level1 'one'

    result = json.attributes!
    assert_equal 'two', result['level2']['VALUE']
    assert_equal 'one', result['level1']
  end

  test 'key_format! with no parameter' do
    json = Jbuilder.new
    json.key_format! :upcase
    json.lower 'Value'

    assert_equal ['LOWER'], json.attributes!.keys
  end

  test 'key_format! with multiple steps' do
    json = Jbuilder.new
    json.key_format! :upcase, :pluralize
    json.pill ''

    assert_equal ['PILLs'], json.attributes!.keys
  end

  test 'key_format! with lambda/proc' do
    json = Jbuilder.new
    json.key_format! lambda { |key| key + ' and friends' }
    json.oats ''

    assert_equal ['oats and friends'], json.attributes!.keys
  end

  test 'default key_format!' do
    Jbuilder.key_format :camelize => :lower
    json = Jbuilder.new
    json.camel_style 'for JS'

    assert_equal ['camelStyle'], json.attributes!.keys
    Jbuilder.send(:class_variable_set, '@@key_formatter', Jbuilder::KeyFormatter.new)
  end

  test 'do not use default key formatter directly' do
    json = Jbuilder.new
    json.key 'value'

    assert_equal [], Jbuilder.send(:class_variable_get, '@@key_formatter').instance_variable_get('@cache').keys
  end

  test 'ignore_nil! without a parameter' do
    json = Jbuilder.new
    json.ignore_nil!
    json.test nil

    assert_equal [], json.attributes!.keys
  end

  test 'ignore_nil! with parameter' do
    json = Jbuilder.new
    json.ignore_nil! true
    json.name 'Bob'
    json.dne nil

    assert_equal ['name'], json.attributes!.keys

    json = Jbuilder.new
    json.ignore_nil! false
    json.name 'Bob'
    json.dne nil

    assert_equal ['name', 'dne'], json.attributes!.keys
  end

  test 'default ignore_nil!' do
    Jbuilder.ignore_nil
    json = Jbuilder.new
    json.name 'Bob'
    json.dne nil

    assert_equal ['name'], json.attributes!.keys
    Jbuilder.send(:class_variable_set, '@@ignore_nil', false)
  end

  test 'nil!' do
    json = Jbuilder.new
    json.key 'value'
    json.nil!
    assert_nil json.attributes!
  end

  test 'null!' do
    json = Jbuilder.new
    json.key 'value'
    json.null!
    assert_nil json.attributes!
  end

  test 'throws meaningfull error when on trying to add properties to null' do
    json = Jbuilder.new
    json.null!
    assert_raise(Jbuilder::NullError) { json.foo 'bar' }
  end
end
