require 'test_helper'

class JstreamerTest < ActiveSupport::TestCase

  test 'outputting a top-level primative value' do
    result = jbuild { |json| json.value! nil  }
    assert_nil result
    
    [1, true, false, "string"].each do |primative|
      result = jbuild { |json| json.value! primative  }
      assert_equal primative, result
    end
  end

  test 'empty top-level object' do
    result = jbuild do |json|
      json.object!
    end

    assert_equal({}, result)
  end
  
  test 'empty top-level array' do
    result = jbuild do |json|
      json.array!
    end

    assert_equal [], result
  end
  
  test 'object! with single key and primative' do
    [nil, 1, true, false, "string"].each do |primative|
      result = jbuild do |json|
        json.object! { json.content primative }
      end
      
      assert_equal({'content' => primative}, result)
    end
  end

  test 'object! with multiple keys' do
    result = jbuild do |json|
      json.object! do
        json.title 'hello'
        json.content 'world'
      end
    end

    assert_equal({'title' => 'hello', 'content' => 'world'}, result)
  end
  
  test 'set a key/value in an object with set!' do
    result = jbuild do |json|
      json.object! { json.set! :each, 'stuff' }
    end

    assert_equal({'each' => 'stuff'}, result)
  end

  test 'set a key to a primative value via json.key(value)' do
    result = jbuild do |json|
      json.object! do
        json.key true
      end
    end

    assert_equal({'key' => true}, result)
  end
  
  test 'set a key with a block' do    
    result = jbuild do |json|
      json.object! do
        json.key do
          json.value! 10
        end
      end
    end

    assert_equal({'key' => 10}, result)
  end

  test 'set a key to a object via pluck' do
    value = {id: 1, name: "Jon"}
    
    result = jbuild do |json|
      json.object! do
        json.key value, :name
      end
    end

    assert_equal({'key' => {'name' => 'Jon'}}, result)
  end
  
  test 'set a key to an array via pluck' do
    value = [{id: 1, name: "Jon"}]
    
    result = jbuild do |json|
      json.object! do
        json.key value, :name
      end
    end

    assert_equal({'key' => [{'name' => 'Jon'}]}, result)
  end
  
  test 'set a key to an array with a block' do
    value = [{id: 1, name: "Jon"}]
    
    result = jbuild do |json|
      json.object! do
        json.key value do |item|
          json.child! item[:name]
        end
      end
    end

    assert_equal({'key' => ['Jon']}, result)
  end
  
  test 'pluck! on an object' do
    person = Struct.new(:name, :age).new('David', 32)

    result = jbuild do |json|
      json.pluck! person, :name, :age
    end

    assert_equal({'name' => 'David', 'age' => 32}, result)
  end
  
  test 'pluck! on an hash' do
    person = {name: 'Jim', age: 34}

    result = jbuild do |json|
      json.pluck! person, :name, :age
    end

    assert_equal({'name' => 'Jim', 'age' => 34}, result)
  end

  test 'extract! from an object' do
    person = Struct.new(:name, :age).new('David', 32)

    result = jbuild do |json|
      json.object! do
        json.extract! person, :name, :age
      end
    end

    assert_equal({'name' => 'David', 'age' => 32}, result)
  end

  test 'extract! from a hash' do
    person = {name: 'Jim', age: 34}

    result = jbuild do |json|
      json.object! do
        json.extract! person, :name, :age
      end
    end

    assert_equal({'name' => 'Jim', 'age' => 34}, result)
  end
  
  test 'array! with an array of primatives' do
    result = jbuild do |json|
      json.array! [nil, 1, true, false, "string"]
    end
      
    assert_equal([nil, 1, true, false, "string"], result)
  end

  test 'array! with a nil collection' do
    result = jbuild do |json|
      json.object! do
        json.comments nil do |comment|
          json.child! 1
        end
      end
    end

    assert_equal({'comments' => []}, result)
  end
  
  test 'array! block calling child! with a collection' do
    result = jbuild do |json|
      json.array! do
        json.child! [1, 2]
      end
    end
      
    assert_equal([[1, 2]], result)
  end
  
  test 'array! block calling child! with a collection to pluck' do
    result = jbuild do |json|
      json.array! do
        json.child! [{id: 1, name: 'one'}, {id: 2, name: 'two'}], :name
      end
    end
      
    assert_equal([[{'name' => 'one'}, {'name' => 'two'}]], result)
  end
  
  
  test 'array! block calling child! with a object to pluck' do
    result = jbuild do |json|
      json.array! do
        json.child!({id: 1, name: 'one'}, :name)
      end
    end
      
    assert_equal([{'name' => 'one'}], result)
  end
  
  test 'array! block calling child! with a collection and a block' do
    result = jbuild do |json|
      json.array! do
        json.child! [1, 2] do |x|
          json.value! x*2
        end
      end
    end
      
    assert_equal([[2, 4]], result)
  end

  test 'array! with a collection and attributes to pluck from each' do
    comments = [ {id: 1, content: 'hello'}, {id: 2, content: 'world'} ]

    result = jbuild do |json|
      json.array! comments, :id
    end

    assert_equal([{"id" => 1},{"id" => 2}], result)
  end
  
  test 'array! with an array and a block' do
    result = jbuild do |json|
      json.array! [1, "string"] do |value|
        json.child! value*2
      end
    end
      
    assert_equal([2, "stringstring"], result)
  end
  
  
  test 'array! with an array and attributes to pluck' do
    result = jbuild do |json|
      json.array! [{a: 1, b: 2}, {a: 3, b: 4}], :b
    end
      
    assert_equal([{'b' => 2}, {'b' => 4}], result)
  end

  test 'set! a key for an object' do
    result = jbuild do |json|
      json.object! do
        json.set! :key, "value"
      end
    end

    assert_equal({"key" => "value"}, result)
  end

  test 'set! a key/nested child with block' do
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

    assert_equal({"author" => {"name" => "David", "age" => 32}}, result)
  end

end