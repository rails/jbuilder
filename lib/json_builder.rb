require 'active_support/ordered_hash'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/enumerable'
require 'active_support/json'
require 'railtie'

class JsonBuilder
  # Yields a builder and automatically turns the result into a JSON string
  def self.encode
    new.tap { |json| yield json }.target!
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
    @attributes << JsonBuilder.new.tap { |json_builder| yield json_builder }.attributes!
  end

  # Extracts the mentioned attributes from the passed object and turns them into attributes of the JSON.
  #
  # Example:
  #
  #   json.people @people, :name, :age
  #
  #   { "people": [ { "David", 32 }, { "Jamie", 31 } ] }
  def extract!(object, *attributes)
    attributes.each do |attribute|
      send attribute, object.send(attribute)
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
    def method_missing(method, *args, &block)
      case
      when args.one?
        _assign method, args.first
      when args.empty? && block_given?
        _yield_nesting method, block
      when args.many?
        _inline_nesting method, args.first, args.from(1)
      end
    end

    def _assign(key, value)
      @attributes[key] = value
    end

    def _yield_nesting(container, block)
      @attributes[container] = JsonBuilder.new.tap { |json_builder| block.call json_builder }.attributes!
    end

    def _inline_nesting(container, collection, attributes)
      send(container) do |parent|
        collection.each do |element|
          parent.child! do |child|
            attributes.each do |attribute|
              child.send attribute, element.send(attribute)
            end
          end
        end
      end
    end
end
