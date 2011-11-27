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
  def child!
    @attributes = [] unless @attributes.is_a? Array
    jbuilder = Jbuilder.new
    yield jbuilder
    @attributes << jbuilder.attributes!
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

  alias :call :extract! if RUBY_VERSION > '1.9'

  # Returns the attributes of the current builder.
  def attributes!
    @attributes
  end
  
  # Encodes the current builder as JSON.
  def target!
    ActiveSupport::JSON.encode @attributes
  end


  private
    def method_missing(method, *args, &block)
      case
      when args.one? && block_given?
        _yield_iteration method, args.first, block
      when args.one?
        _assign method, args.first
      when args.empty? && block_given?
        _yield_nesting method, block
      when args.many? && args.first.is_a?(Enumerable)
        _inline_nesting method, args.first, args.from(1)
      when args.many?
        _inline_extract method, args.first, args.from(1)
      end
    end

    def _assign(key, value)
      @attributes[key] = value
    end

    def _yield_nesting(container, block)
      jbuilder = Jbuilder.new
      block.call jbuilder
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
    
    def _yield_iteration(container, collection, block)
      __send__(container) do |parent|
        collection.each do |element|
          parent.child! do |child|
            block.call child, element
          end
        end
      end
    end
    
    def _inline_extract(container, record, attributes)
      __send__(container) { |parent| parent.extract! record, *attributes }
    end
end
