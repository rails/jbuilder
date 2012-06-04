require 'blankslate'
require 'active_support/ordered_hash'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/enumerable'
require 'active_support/json'

class Jbuilder < BlankSlate
  # Yields a builder and automatically turns the result into a JSON string
  def self.encode
    new._tap { |jbuilder| yield jbuilder }.target!
  end

  define_method(:__class__, find_hidden_method(:class))
  define_method(:_tap, find_hidden_method(:tap))

  def initialize
    @attributes = ActiveSupport::OrderedHash.new
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
      @attributes[key] = value
    end
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
  #
  # If you omit the block then you can set the top level array directly:
  #
  #   json.array! [1, 2, 3]
  #
  #   [1,2,3]
  def array!(collection)
    if block_given?
      @attributes = [] and return if collection.empty?
      
      collection.each do |element|
        child! do |child|
          yield child, element
        end
      end
    else
      @attributes = collection || []
    end
  end

  # Extracts the mentioned attributes from the passed object and turns them into attributes of the JSON.
  #
  # Example:
  #
  #   json.extract! @person, :name, :age
  #
  #   { "name": David", "age": 32 }, { "name": Jamie", "age": 31 }
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

  # Caches the json constructed within the block passed. Has the same signature as the `cache` helper 
  # method in `ActionView::Helpers::CacheHelper` and so can be used in the same way.
  #
  # Example:
  #
  #   json.cache! ['v1', @person], :expires_in => 10.minutes do |json|
  #     json.extract! @person, :name, :age
  #   end
  def cache!(key = nil, options = {}, &block)
    cache_key = ActiveSupport::Cache.expand_cache_key(key.is_a?(Hash) ? url_for(key).split("://").last : key, :jbuilder)
    value = Rails.cache.read(cache_key, options)

    if ! value
      attributes = self.attributes!.clone
      yield self
      new_value = self.attributes!.is_a?(Hash) ? self.attributes!.diff(attributes) : self.attributes!
      Rails.cache.write(cache_key, new_value, options)
    else
      if value.is_a?(Array)
        self.array! value
      else
        value.each do |k, v|
          self.set! k, v
        end
      end
    end
  end

  private
    def method_missing(method, *args)
      case
      # json.comments @post.comments { |json, comment| ... }
      # { "comments": [ { ... }, { ... } ] }
      when args.one? && block_given?
        _yield_iteration(method, args.first) { |child, element| yield child, element }

      # json.age 32
      # { "age": 32 }
      when args.length == 1
        set! method, args.first

      # json.comments { |json| ... }
      # { "comments": ... }
      when args.empty? && block_given?
        _yield_nesting(method) { |jbuilder| yield jbuilder }
      
      # json.comments(@post.comments, :content, :created_at)
      # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
      when args.many? && args.first.is_a?(Enumerable)
        _inline_nesting method, args.first, args.from(1)

      # json.author @post.creator, :name, :email_address
      # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
      when args.many?
        _inline_extract method, args.first, args.from(1)
      end
    end

    # Overwrite in subclasses if you need to add initialization values
    def _new_instance
      __class__.new
    end

    def _yield_nesting(container)
      set! container, _new_instance._tap { |jbuilder| yield jbuilder }.attributes!
    end

    def _inline_nesting(container, collection, attributes)
      __send__(container) do |parent|
        parent.array!(collection) and return if collection.empty?
        
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

require "jbuilder_template" if defined?(ActionView::Template)
