require 'blankslate' unless defined? BasicObject
require 'active_support/ordered_hash'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/enumerable'
require 'active_support/json'
require 'multi_json'
class Jbuilder < (defined? BasicObject ? BasicObject : BlankSlate)
  class KeyFormatter
    def initialize(*args)
      @format = {}
      @cache = {}

      options = args.extract_options!
      args.each do |name|
        @format[name] = []
      end
      options.each do |name, paramaters|
        @format[name] = paramaters
      end
    end

    def initialize_copy(original)
      @cache = {}
    end

    def format(key)
      @cache[key] ||= @format.inject(key.to_s) do |result, args|
        func, args = args
        if func.is_a? Proc
          func.call(result, *args)
        else
          result.send(func, *args)
        end
      end
    end
  end
  
  # Yields a builder and automatically turns the result into a JSON string
  def self.encode
    new._tap { |jbuilder| yield jbuilder }.target!
  end

  @@key_formatter = KeyFormatter.new

  define_method(:__class__, find_hidden_method(:class))
  define_method(:_tap, find_hidden_method(:tap))
  reveal(:respond_to?)

  def initialize(key_formatter = @@key_formatter.clone)
    @attributes = ActiveSupport::OrderedHash.new
    @key_formatter = key_formatter
  end

  # Dynamically set a key value pair.
  #
  # Example:
  #
  #   json.set!(:each, "stuff")
  #
  #   { "each": "stuff" }
  #
  # You can also pass a block for nested attributes
  #
  #   json.set!(:author) do |json|
  #     json.name "David"
  #     json.age 32
  #   end
  #
  #   { "author": { "name": "David", "age": 32 } }
  def set!(key, value = nil)
    if block_given?
      _yield_nesting(key) { |jbuilder| yield jbuilder }
    else
      _set_value(key, value)
    end
  end

  # Specifies formatting to be applied to the key. Passing in a name of a function
  # will cause that function to be called on the key.  So :upcase will upper case
  # the key.  You can also pass in lambdas for more complex transformations.
  #
  # Example:
  #
  #   json.key_format! :upcase
  #   json.author do |json|
  #     json.name "David"
  #     json.age 32
  #   end
  #
  #   { "AUTHOR": { "NAME": "David", "AGE": 32 } }
  #
  # You can pass parameters to the method using a hash pair.
  #
  #   json.key_format! :camelize => :lower
  #   json.first_name "David"
  #
  #   { "firstName": "David" }
  #
  # Lambdas can also be used.
  #
  #   json.key_format! ->(key){ "_" + key }
  #   json.first_name "David"
  #
  #   { "_first_name": "David" }
  #
  def key_format!(*args)
    @key_formatter = KeyFormatter.new(*args)
  end
  
  # Same as the instance method key_format! except sets the default.
  def self.key_format(*args)
    @@key_formatter = KeyFormatter.new(*args)
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
    @attributes << _new_instance._tap { |jbuilder| yield jbuilder }.attributes!
  end

  # Turns the current element into an array and iterates over the passed collection, adding each iteration as 
  # an element of the resulting array.
  #
  # Example:
  #
  #   json.array!(@people) do |json, person|
  #     json.name person.name
  #     json.age calculate_age(person.birthday)
  #   end
  #
  #   [ { "name": David", "age": 32 }, { "name": Jamie", "age": 31 } ]
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
  #   { "people": [ { "name": David", "age": 32 }, { "name": Jamie", "age": 31 } ] }
  def array!(collection)
    @attributes = []
    collection.each do |element| #[] and return if collection.empty?
      @attributes << _new_instance._tap { |jbuilder| yield jbuilder, element }.attributes!
    end
  end

  # Extracts the mentioned attributes or hash elements from the passed object and turns them into attributes of the JSON.
  #
  # Example:
  #
  #   @person = Struct.new(:name, :age).new("David", 32)
  #
  #   or you can utilize a Hash
  #
  #   @person = {:name => "David", :age => 32}
  #
  #   json.extract! @person, :name, :age
  #
  #   { "name": David", "age": 32 }, { "name": Jamie", "age": 31 }
  #
  # If you are using Ruby 1.9+, you can use the call syntax instead of an explicit extract! call:
  #
  #   json.(@person, :name, :age)
  def extract!(object, *attributes)
    if object.is_a?(Hash)
      attributes.each {|attribute| _set_value attribute, object.send(:fetch, attribute)}
    else
      attributes.each {|attribute| _set_value attribute, object.send(attribute)}
    end
  end

  if RUBY_VERSION > '1.9'
    def call(object = nil, *attributes)
      if attributes.empty?
        array!(object) { |json, element| yield json, element }
      else
        extract!(object, *attributes)
      end
    end
  end

  # Returns the attributes of the current builder.
  def attributes!
    @attributes
  end
  
  # Encodes the current builder as JSON.
  def target!
    MultiJson.encode @attributes
  end


  protected
    def _set_value(key, value)
      @attributes[@key_formatter.format(key)] = value
    end


  private
    def method_missing(method, value = nil, *args)
      if block_given?
        if value
          # json.comments @post.comments { |json, comment| ... }
          # { "comments": [ { ... }, { ... } ] }
          _yield_iteration(method, value) { |child, element| yield child, element }
        else
          # json.comments { |json| ... }
          # { "comments": ... }
          _yield_nesting(method) { |jbuilder| yield jbuilder }
        end
      else
        if args.empty?
          if Jbuilder === value
            # json.age 32
            # json.person another_jbuilder
            # { "age": 32, "person": { ...  }
            _set_value method, value.attributes!
          else
            # json.age 32
            # { "age": 32 }
            _set_value method, value
          end
        else
          if value.respond_to?(:each)
            # json.comments(@post.comments, :content, :created_at)
            # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
            _inline_nesting method, value, args
          else
            # json.author @post.creator, :name, :email_address
            # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
            _inline_extract method, value, args
          end
        end
      end
    end

    # Overwrite in subclasses if you need to add initialization values
    def _new_instance
      __class__.new(@key_formatter)
    end

    def _yield_nesting(container)
      _set_value container, _new_instance._tap { |jbuilder| yield jbuilder }.attributes!
    end

    def _inline_nesting(container, collection, attributes)
      _yield_nesting(container) do |parent|
        parent.array!(collection) do |child, element|
          attributes.each do |attribute|
            child._set_value attribute, element.send(attribute)
          end
        end
      end
    end
    
    def _yield_iteration(container, collection)
      _yield_nesting(container) do |parent|
        parent.array!(collection) do |child, element|
          yield child, element
        end
      end
    end
    
    def _inline_extract(container, record, attributes)
      _yield_nesting(container) { |parent| parent.extract! record, *attributes }
    end
end

require "jbuilder_template" if defined?(ActionView::Template)
