require 'blankslate'
require 'active_support/ordered_hash'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/enumerable'
require 'active_support/json'
require 'railtie' if defined? Rails

class Jbuilder < BlankSlate
  # Yields a builder and automatically turns the result into a JSON string
  def self.encode
    jbuilder = new
    yield jbuilder
    jbuilder.target!
  end

  def initialize
    @attributes = ActiveSupport::OrderedHash.new
  end

  # Turns the current element into an array and yields a builder to add a hash.
  #
  # Example:
  #
  #   json.comments do |json|
  #     json.child! { |json| json.content "hello" }
  #     json.child! { |json| json.content "world" }
  #   end
  #
  #   { "comments": [ { "content": "hello" }, { "content": "world" } ]}
  #
  # More commonly, you'd use the combined iterator, though:
  #
  #   json.comments(@post.comments) do |json, comment|
  #     json.content comment.formatted_content
  #   end  
  def child!
    @attributes = [] unless @attributes.is_a? Array
    jbuilder = Jbuilder.new
    yield jbuilder
    @attributes << jbuilder.attributes!
  end

  # Iterates over the passed collection and adds each iteration as an element of the resulting array.
  #
  # Example:
  #
  #   json.array!(@people) do |json, person|
  #     json.name person.name
  #     json.age calculate_age(person.birthday)
  #   end
  #
  #   [ { "David", 32 }, { "Jamie", 31 } ]
  #
  # If you are using Ruby 1.9+, you can use the call syntax instead of an explicit extract! call:
  #
  #   json.(@people) { |json, person| ... }
  #
  # It's generally only needed to use this method for top-level arrays. If you have named arrays, you can do:
  #
  #   json.people(@people) do |json, person|
  #     json.name person.name
  #     json.age calculate_age(person.birthday)
  #   end  
  #
  #   { "people": [ { "David", 32 }, { "Jamie", 31 } ] }
  def array!(collection)
    collection.each do |element|
      child! do |child|
        yield child, element
      end
    end
  end

  # Extracts the mentioned attributes from the passed object and turns them into attributes of the JSON.
  #
  # Example:
  #
  #   json.extract! @person, :name, :age
  #
  #   { "David", 32 }, { "Jamie", 31 }
  #
  # If you are using Ruby 1.9+, you can use the call syntax instead of an explicit extract! call:
  #
  #   json.(@person, :name, :age)
  def extract!(object, *attributes)
    attributes.each do |attribute|
      __send__ attribute, object.send(attribute)
    end
  end

  if RUBY_VERSION > '1.9'
    def call(*args)
      case
      when args.one?
        array!(args.first) { |json, element| yield json, element }
      when args.many?
        extract!(*args)
      end
    end
  end

  # Returns the attributes of the current builder.
  def attributes!
    @attributes
  end
  
  # Encodes the current builder as JSON.
  def target!
    ActiveSupport::JSON.encode @attributes
  end


  private
    def method_missing(method, *args)
      case
      when args.one? && block_given?
        _yield_iteration(method, args.first) { |child, element| yield child, element }
      when args.one?
        _assign method, args.first
      when args.empty? && block_given?
        _yield_nesting(method) { |jbuilder| yield jbuilder }
      when args.many? && args.first.is_a?(Enumerable)
        _inline_nesting method, args.first, args.from(1)
      when args.many?
        _inline_extract method, args.first, args.from(1)
      end
    end

    def _assign(key, value)
      @attributes[key] = value
    end

    def _yield_nesting(container)
      jbuilder = Jbuilder.new
      yield jbuilder
      @attributes[container] = jbuilder.attributes!
    end

    def _inline_nesting(container, collection, attributes)
      __send__(container) do |parent|
        collection.each do |element|
          parent.child! do |child|
            attributes.each do |attribute|
              child.__send__ attribute, element.send(attribute)
            end
          end
        end
      end
    end
    
    def _yield_iteration(container, collection)
      __send__(container) do |parent|
        parent.array!(collection) do |child, element|
          yield child, element
        end
      end
    end
    
    def _inline_extract(container, record, attributes)
      __send__(container) { |parent| parent.extract! record, *attributes }
    end
end
