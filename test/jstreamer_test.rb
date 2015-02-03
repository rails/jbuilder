require 'test_helper'
require 'active_support/inflector'
require 'jstreamer'

def jbuild(*args, &block)
  ::Wankel.parse(Jstreamer.new(*args, &block).target!)
end

Comment = Struct.new(:content, :id)

class NonEnumerable
  def initialize(collection)
    @collection = collection
  end

  def each(&block)
    @collection.each(&block)
  end
end

class VeryBasicWrapper < BasicObject
  def initialize(thing)
    @thing = thing
  end

  def method_missing(name, *args, &block)
    @thing.send name, *args, &block
  end
end

# This is not Struct, because structs are Enumerable
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


class JstreamerTest < ActiveSupport::TestCase
  
  test 'single key' do
    result = jbuild do |json|
      json.object! do
        json.content 'hello'
      end
    end

    assert_equal 'hello', result['content']
  end

  test 'single key with false value' do
    result = jbuild do |json|
      json.object! do
        json.content false
      end
    end

    assert_equal false, result['content']
  end

  test 'single key with nil value' do
    result = jbuild do |json|
      json.object! do
        json.content nil
      end
    end

    assert result.has_key?('content')
    assert_equal nil, result['content']
  end

  test 'multiple keys' do
    result = jbuild do |json|
      json.object! do
        json.title 'hello'
        json.content 'world'
      end
    end

    assert_equal 'hello', result['title']
    assert_equal 'world', result['content']
  end

  test 'extracting from object' do
    person = Struct.new(:name, :age).new('David', 32)

    result = jbuild do |json|
      json.object! do
        json.extract! person, :name, :age
      end
    end

    assert_equal 'David', result['name']
    assert_equal 32, result['age']
  end

  test 'extracting from hash' do
    person = {:name => 'Jim', :age => 34}

    result = jbuild do |json|
      json.object! do
        json.extract! person, :name, :age
      end
    end

    assert_equal 'Jim', result['name']
    assert_equal 34, result['age']
  end

  test 'nesting single child with block' do
    result = jbuild do |json|
      json.object! do
        json.author do
          json.object! do
            json.name 'David'
            json.age  32
          end
        end
      end
    end

    assert_equal 'David', result['author']['name']
    assert_equal 32, result['author']['age']
  end

  test 'empty block handling' do
    result = jbuild do |json|
      json.object! do
        json.foo 'bar'
        json.author do
          json.object! do
          end
        end
      end
    end

    assert_equal 'bar', result['foo']
    assert_equal({}, result['author'])
  end

  test 'support merge! method' do
    result = jbuild do |json|
      json.merge! '{"foo":"bar"}'
    end

    assert_equal 'bar', result['foo']
  end

  test 'support merge! method in a block' do
    result = jbuild do |json|
      json.object! do
        json.author do
          json.object! do
            json.merge! '"name":"Pavel"'
          end
        end
      end
    end

    assert_equal 'Pavel', result['author']['name']
  end

  test 'nesting single child with inline extract' do
    person = Person.new('David', 32)

    result = jbuild do |json|
      json.object! do
        json.author person, :name, :age
      end
    end

    assert_equal 'David', result['author']['name']
    assert_equal 32,      result['author']['age']
  end

  test 'nesting multiple children from array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.object! do
        json.comments comments, :content
      end
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'nesting multiple children from array when child array is empty' do
    comments = []

    result = jbuild do |json|
      json.object! do
        json.name 'Parent'
        json.comments comments, :content
      end
    end

    assert_equal 'Parent', result['name']
    assert_equal [], result['comments']
  end

  test 'nesting multiple children from array with inline loop' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.object! do
        json.comments comments do |comment|
          json.object! { json.content comment.content }
        end
      end
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'handles nil-collections as empty arrays' do
    result = jbuild do |json|
      json.object! do
        json.comments nil do |comment|
          json.object! do
            json.content comment.content
          end
        end
      end
    end

    assert_equal [], result['comments']
  end

  test 'nesting multiple children from a non-Enumerable that responds to #each' do
    comments = NonEnumerable.new([ Comment.new('hello', 1), Comment.new('world', 2) ])

    result = jbuild do |json|
      json.object! do
        json.comments comments, :content
      end
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'nesting multiple chilren from a non-Enumerable that responds to #each with inline loop' do
    comments = NonEnumerable.new([ Comment.new('hello', 1), Comment.new('world', 2) ])

    result = jbuild do |json|
      json.object! do
        json.comments comments do |comment|
          json.object! { json.content comment.content }
        end
      end
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'array! casts array-like objects to array before merging' do
    wrapped_array = VeryBasicWrapper.new(%w[foo bar])

    result = jbuild do |json|
      json.array! wrapped_array
    end

    assert_equal %w[foo bar], result
  end

  test 'nesting multiple children from array with inline loop on root' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.array! comments do |comment|
        json.object! { json.content comment.content }
      end
    end

    assert_equal 'hello', result.first['content']
    assert_equal 'world', result.second['content']
  end
  
  test 'array nested inside nested hash' do
    result = jbuild do |json|
      json.object! do
        json.author do
          json.object! do
            json.name 'David'
            json.age  32

            json.comments do
              json.array! do
                json.child! { json.object! { json.content 'hello' } }
                json.child! { json.object! { json.content 'world' } }
              end
            end
          end
        end
      end
    end

    assert_equal 'hello', result['author']['comments'].first['content']
    assert_equal 'world', result['author']['comments'].second['content']
  end

  test 'array nested inside array' do
    result = jbuild do |json|
      json.object! do
        json.comments :emit => :array do
          json.child! do
            json.object! do
              json.authors :emit => :array do
                json.child! do
                  json.object! do
                    json.name 'david'
                  end
                end
              end
            end
          end
        end
      end
    end

    assert_equal 'david', result['comments'].first['authors'].first['name']
  end

  test 'directly set an array nested in another array' do
    data = [ { :department => 'QA', :not_in_json => 'hello', :names => ['John', 'David'] } ]

    result = jbuild do |json|
      json.array! data do |object|
        json.object! do
          json.department object[:department]
          json.names :emit => :array do
            object[:names].each { |e| json.child! e }
          end
        end
      end
    end
    
    assert_equal 'David', result[0]['names'].last
    assert !result[0].key?('not_in_json')
  end

  test 'nested jstreamer objects' do
    to_nest = Jstreamer.new{ |json| json.object! { json.nested_value 'Nested Test' } }

    result = jbuild do |json|
      json.object! do
        json.value 'Test'
        json.nested to_nest
      end
    end

    expected = {'value' => 'Test', 'nested' => {'nested_value' => 'Nested Test'}}
    assert_equal expected, result
  end

  test 'nested jstreamer object via set!' do
    to_nest = Jstreamer.new{ |json| json.object! { json.nested_value 'Nested Test' } }

    result = jbuild do |json|
      json.object! do
        json.value 'Test'
        json.set! :nested, to_nest
      end
    end

    expected = {'value' => 'Test', 'nested' => {'nested_value' => 'Nested Test'}}
    assert_equal expected, result
  end

  test 'top-level array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.array! comments do |comment|
        json.object! { json.content comment.content }
      end
    end

    assert_equal 'hello', result.first['content']
    assert_equal 'world', result.second['content']
  end

  test 'it allows using next in array block to skip value' do
    comments = [ Comment.new('hello', 1), Comment.new('skip', 2), Comment.new('world', 3) ]
    result = jbuild do |json|
      json.array! comments do |comment|
        next if comment.id == 2
        
        json.object! { json.content comment.content }
      end
    end

    assert_equal 2, result.length
    assert_equal 'hello', result.first['content']
    assert_equal 'world', result.second['content']
  end

  test 'extract attributes directly from array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.array! comments, :content, :id
    end

    assert_equal 'hello', result.first['content']
    assert_equal       1, result.first['id']
    assert_equal 'world', result.second['content']
    assert_equal       2, result.second['id']
  end

  test 'empty top-level array' do
    comments = []

    result = jbuild do |json|
      json.array! comments do |comment|
        json.content comment.content
      end
    end

    assert_equal [], result
  end

  test 'dynamically set a key/value' do
    result = jbuild do |json|
      json.object! do
        json.set! :each, 'stuff'
      end
    end

    assert_equal 'stuff', result['each']
  end

  test 'dynamically set a key/nested child with block' do
    result = jbuild do |json|
      json.object! do
        json.set! :author do
          json.object! do
            json.name 'David'
            json.age 32
          end
        end
      end
    end

    assert_equal 'David', result['author']['name']
    assert_equal 32, result['author']['age']
  end

  test 'dynamically sets a collection' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.object! do
        json.set! :comments, comments, :content
      end
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'query like object' do
    result = jbuild do |json|
      json.object! do
        json.relations RelationMock.new, :name, :age
      end
    end

    assert_equal 2, result['relations'].length
    assert_equal 'Bob', result['relations'][0]['name']
    assert_equal 50, result['relations'][1]['age']
  end

  test 'initialize via options hash' do
    jstreamer = Jstreamer.new(key_formatter: 1, ignore_nil: 2)
    assert_equal 1, jstreamer.instance_eval{ @key_formatter }
    assert_equal 2, jstreamer.instance_eval{ @ignore_nil }
  end

  test 'key_format! with parameter' do
    result = jbuild do |json|
      json.object! do
        json.key_format! camelize: [:lower]
        json.camel_style 'for JS'
      end
    end

    assert_equal ['camelStyle'], result.keys
  end

  test 'key_format! with parameter not as an array' do
    result = jbuild do |json|
      json.object! do
        json.key_format! :camelize => :lower
        json.camel_style 'for JS'
      end
    end

    assert_equal ['camelStyle'], result.keys
  end

  test 'key_format! propagates to child elements' do
    result = jbuild do |json|
      json.object! do
        json.key_format! :upcase
        json.level1 'one'
        json.level2 do
          json.object! do
            json.value 'two'
          end
        end
      end
    end
    puts result
    assert_equal 'one', result['LEVEL1']
    assert_equal 'two', result['LEVEL2']['VALUE']
  end

  test 'key_format! resets after child element' do
    result = jbuild do |json|
      json.object! do
        json.level2 do
          json.key_format! :upcase
          json.object! { json.value 'two' }
        end
        json.level1 'one'
      end
    end

    assert_equal 'two', result['level2']['VALUE']
    assert_equal 'one', result['level1']
  end

  test 'key_format! with no parameter' do
    result = jbuild do |json|
      json.object! do
        json.key_format! :upcase
        json.lower 'Value'
      end
    end

    assert_equal ['LOWER'], result.keys
  end

  test 'key_format! with multiple steps' do
    result = jbuild do |json|
      json.object! do
        json.key_format! :upcase, :pluralize
        json.pill 'foo'
      end
    end

    assert_equal ['PILLs'], result.keys
  end

  test 'key_format! with lambda/proc' do
    result = jbuild do |json|
      json.object! do
        json.key_format! ->(key){ key + ' and friends' }
        json.oats 'foo'
      end
    end

    assert_equal ['oats and friends'], result.keys
  end

  test 'default key_format!' do
    Jstreamer.key_format camelize: :lower
    result = jbuild{ |json| json.object! { json.camel_style 'for JS' } }
    assert_equal ['camelStyle'], result.keys
    Jstreamer.send :class_variable_set, '@@key_formatter', Jstreamer::KeyFormatter.new
  end

  test 'do not use default key formatter directly' do
    jbuild{ |json| json.object! { json.key 'value' } }
    cache = Jstreamer.send(:class_variable_get, '@@key_formatter').instance_variable_get('@cache')
    assert_empty cache
  end

  test 'ignore_nil! without a parameter' do
    result = jbuild do |json|
      json.object! do
        json.ignore_nil!
        json.test nil
      end
    end

    assert_empty result.keys
  end

  test 'ignore_nil! with parameter' do
    result = jbuild do |json|
      json.object! do
        json.ignore_nil! true
        json.name 'Bob'
        json.dne nil
      end
    end

    assert_equal ['name'], result.keys

    result = jbuild do |json|
      json.object! do
        json.ignore_nil! false
        json.name 'Bob'
        json.dne nil
      end
    end

    assert_equal ['name', 'dne'], result.keys
  end

  test 'default ignore_nil!' do
    Jstreamer.ignore_nil

    result = jbuild do |json|
      json.object! do
        json.name 'Bob'
        json.dne nil
      end
    end

    assert_equal ['name'], result.keys
    Jstreamer.send(:class_variable_set, '@@ignore_nil', false)
  end

  test 'collection' do
    BlogPost = Struct.new(:id, :body, :author_name)
    blog_authors = [ 'David Heinemeier Hansson', 'Pavel Pravosud' ].cycle
    blog_posts = 10.times.map{ |i| BlogPost.new(i+1, "post body #{i+1}", blog_authors.next) }

    result = jbuild do |json|
      json.object! do
        json.posts blog_posts do |blog_post|
          json.extract! blog_post, :id, :body
          json.author do
            name = blog_post.author_name.split(nil, 2)
            json.first_name name[0]
            json.last_name  name[1]
          end
        end
      end
    end
  end

  test "_capture" do
    old_buf_size = Wankel::DEFAULTS[:write_buffer_size]
    builder = Jstreamer.new
    capture = nil

    begin
      Wankel::DEFAULTS[:write_buffer_size]  = 1_000_000

      builder.object! do
        builder.key1 'value1'
        capture = builder.__send__(:_capture) do
          builder.key2 'value2'
        end
        builder.key3 'value3'
      end
    ensure
      Wankel::DEFAULTS[:write_buffer_size] = old_buf_size
    end

    assert_equal ',"key2":"value2"', capture
    assert_equal '{"key1":"value1","key3":"value3"}', builder.target!
  end

  test 'hash nested inside array nested inside hash' do
    result = jbuild do |json|
      json.object! do
        json.author do
          json.object! do
            json.name do
              json.object! do
                json.comments do
                  json.array! do
                    json.child! { json.object! { json.content 'hello' } }
                    json.child! do
                      json.object! do
                        json.id 42
                        json.content 'world'
                      end
                    end
                  end
                end
                json.other_comments [1,2,3]
                json.other_other_comments [1,2,3] do |c|
                  json.object! do
                    json.id c
                    json.name nil
                  end
                end
              end
            end
          end
        end
      end
    end

    puts result
    assert_equal 'hello', result['author']['name']['comments'].first['content']
    assert_equal 42, result['author']['name']['comments'].second['id']
    assert_equal 'world', result['author']['name']['comments'].second['content']
    assert_equal [1,2,3], result['author']['name']['other_comments']
    assert_equal [{'id' => 1, 'name' => nil},{'id' => 2, 'name' => nil},{'id' => 3, 'name' => nil}], result['author']['name']['other_other_comments']
  end

end
