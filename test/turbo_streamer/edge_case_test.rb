require 'test_helper'

class TurboStreamer::EdgeCaseTest < ActiveSupport::TestCase
  
  Comment = Struct.new(:content, :id)
  
  class Person
    attr_reader :name, :age

    def initialize(name, age)
      @name, @age = name, age
    end
  end

  class NonEnumerable
    def initialize(collection)
      @collection = collection
    end

    def each(&block)
      @collection.each(&block)
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

    assert_equal({'author' => {'name' => 'David', 'age' => 32}}, result)
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

    assert_equal({'foo' => 'bar', 'author' => {}}, result)
  end

  test 'nesting single child with inline extract' do
    person = Person.new('David', 32)

    result = jbuild do |json|
      json.object! do
        json.author person, :name, :age
      end
    end

    assert_equal({'author' => {'name' => 'David', 'age' => 32}}, result)
  end

  test 'nesting multiple children from array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.object! do
        json.comments comments, :content
      end
    end

    assert_equal({'comments' => [{'content' => 'hello'}, {'content' => 'world'}]}, result)
  end

  test 'nesting multiple children from array when child array is empty' do
    comments = []

    result = jbuild do |json|
      json.object! do
        json.name 'Parent'
        json.comments comments, :content
      end
    end

    assert_equal({'name' => 'Parent', 'comments' => []}, result)
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

    assert_equal({'comments' => [{'content' => 'hello'}, {'content' => 'world'}]}, result)
  end

  test 'nesting multiple children from a non-Enumerable that responds to #each' do
    comments = NonEnumerable.new([ Comment.new('hello', 1), Comment.new('world', 2) ])

    result = jbuild do |json|
      json.object! do
        json.comments comments, :id
      end
    end

    assert_equal({'comments' => [{'id' => 1}, {'id' => 2}]}, result)
  end

  test 'nesting multiple chilren from a non-Enumerable that responds to #each with inline loop' do
    comments = NonEnumerable.new([ Comment.new('hello', 1), Comment.new('world', 2) ])

    result = jbuild do |json|
      json.object! do
        json.comments comments do |comment|
          json.object! { json.id comment.id }
        end
      end
    end

    assert_equal({'comments' => [{'id' => 1}, {'id' => 2}]}, result)
  end

  test 'nesting multiple children from array with inline loop on root' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.array! comments do |comment|
        json.object! { json.id comment.id }
      end
    end

    assert_equal([{'id' => 1}, {'id' => 2}], result)
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

    assert_equal({
      "author"=>{
        "name"=>"David",
        "age"=>32,
        "comments"=>[{"content"=>"hello"}, {"content"=>"world"}]
      }
    }, result)
  end

  test 'array nested inside array' do
    result = jbuild do |json|
      json.object! do
        json.comments do
          json.array! do
            json.child! do
              json.object! do
                json.authors do
                  json.array! do
                    json.child! do
                      json.object! { json.name 'david' }
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    assert_equal({"comments" => [{"authors" => [{"name" => "david"}]}]}, result)
  end

  test 'directly set an array nested in another array' do
    data = [ { :department => 'QA', :not_in_json => 'hello', :names => ['John', 'David'] } ]

    result = jbuild do |json|
      json.array! data do |object|
        json.object! do
          json.department object[:department]
          json.names do
            json.array! do
              object[:names].each { |e| json.child! e }
            end
          end
        end
      end
    end

    assert_equal([{"department" => "QA", "names" => ["John", "David"]}], result)
  end

  test 'allows using next in array block to skip value' do
    comments = [ Comment.new('hello', 1), Comment.new('skip', 2), Comment.new('world', 3) ]
    
    result = jbuild do |json|
      json.array! comments do |comment|
        next if comment.id == 2

        json.object! { json.content comment.content }
      end
    end

    assert_equal([{"content" => "hello"}, {"content" => "world"}], result)
  end

  test 'query like object' do
    result = jbuild do |json|
      json.object! do
        json.relations RelationMock.new, :name, :age
      end
    end

    assert_equal({"relations"=>[{"name"=>"Bob", "age"=>30}, {"name"=>"Frank", "age"=>50}]}, result)
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

    assert_equal({
      "author" => {
        "name" => {
          "comments" => [
            {"content" => "hello"},
            {"id" => 42, "content" => "world"}
          ],
          "other_comments" => [1,2,3],
          "other_other_comments" => [
            {"id" => 1, "name" => nil},
            {"id" => 2, "name" => nil},
            {"id" => 3, "name" => nil}
          ]
        }
      }
    }, result)
  end

end
