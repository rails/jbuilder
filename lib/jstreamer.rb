require 'jstreamer/jstreamer'
require 'jstreamer/key_formatter'
require 'wankel'
require 'stringio'

class Jstreamer
  
  @@key_formatter = KeyFormatter.new
  @@ignore_nil    = false
  attr_accessor :encoder, :output, :stack, :possible_key_stack, :flag_depth
  def initialize(options = {})
    @stack = []
    @output = ::StringIO.new
    @encoder = ::Wankel::StreamEncoder.new(@output)

    @key_formatter = options.fetch(:key_formatter){ @@key_formatter.clone }
    @ignore_nil = options.fetch(:ignore_nil, @@ignore_nil)

    yield self if ::Kernel.block_given?
  end

  # Yields a builder and automatically turns the result into a JSON string
  def self.encode(*args, &block)
    new(*args, &block).target!
  end

  BLANK = ::Object.new

  def set!(key, value = BLANK, *args, &block)

    if block
      @encoder.string(_key(key))

      if !_blank?(value)
        # json.comments @post.comments { |comment| ... }
        # { "comments": [ { ... }, { ... } ] }
        _scope{ array! value, &block }
      else
        # json.comments { ... }
        # { "comments": ... }
        # _merge_block(key){ yield self }
        
        _scope(&block)
      end
    elsif args.empty?
      if ::Jstreamer === value
        # json.age 32
        # json.person another_jstreamer
        # { "age": 32, "person": { ...  }
        
        @encoder.string(_key(key))
        
        @encoder.output = ::StringIO.new
        @output << ":" << value.target!
        @encoder.string("")
        @encoder.output = @output
      else
        # json.age 32
        # { "age": 32 }
        _set_value(key, value)
      end
    elsif _eachable_arguments?(value, *args)
      # json.comments @post.comments, :content, :created_at
      # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
      
      @encoder.string(_key(key))
      _scope{ array! value, *args }
    else
      # json.author @post.creator, :name, :email_address
      # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
      # _merge_block(key){ extract! value, *args }

      @encoder.string(_key(key))
      object!{ extract! value, *args }
    end

  end

  alias_method :method_missing, :set!
  private :method_missing

  def key!(key, &block)
    @encoder.string(_key(key))
  end
  def null!
    @encoder.null
  end
  
  # Specifies formatting to be applied to the key. Passing in a name of a function
  # will cause that function to be called on the key.  So :upcase will upper case
  # the key.  You can also pass in lambdas for more complex transformations.
  #
  # Example:
  #
  #   json.key_format! :upcase
  #   json.author do
  #     json.name "David"
  #     json.age 32
  #   end
  #
  #   { "AUTHOR": { "NAME": "David", "AGE": 32 } }
  #
  # You can pass parameters to the method using a hash pair.
  #
  #   json.key_format! camelize: :lower
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

  # If you want to skip adding nil values to your JSON hash. This is useful
  # for JSON clients that don't deal well with nil values, and would prefer
  # not to receive keys which have null values.
  #
  # Example:
  #   json.ignore_nil! false
  #   json.id User.new.id
  #
  #   { "id": null }
  #
  #   json.ignore_nil!
  #   json.id User.new.id
  #
  #   {}
  #
  def ignore_nil!(value = true)
    @ignore_nil = value
  end

  # Same as instance method ignore_nil! except sets the default.
  def self.ignore_nil(value = true)
    @@ignore_nil = value
  end

  # Turns the current element into an array and yields a builder to add a hash.
  #
  # Example:
  #
  #   json.comments do
  #     json.child! { json.content "hello" }
  #     json.child! { json.content "world" }
  #   end
  #
  #   { "comments": [ { "content": "hello" }, { "content": "world" } ]}
  #
  # More commonly, you'd use the combined iterator, though:
  #
  #   json.comments(@post.comments) do |comment|
  #     json.content comment.formatted_content
  #   end
  def child!(value = BLANK, *args, &block)
    if block
      if !_blank?(value)
      else
        # json.child! { ... }
        # [...]
        _scope(&block)
      end
    elsif args.empty?
      if ::Jstreamer === value
      else
        @encoder.value(value)
      end
    elsif _eachable_arguments?(value, *args)
    else
    end
    
  end

  # Turns the current element into an array and iterates over the passed collection, adding each iteration as
  # an element of the resulting array.
  #
  # Example:
  #
  #   json.array!(@people) do |person|
  #     json.name person.name
  #     json.age calculate_age(person.birthday)
  #   end
  #
  #   [ { "name": David", "age": 32 }, { "name": Jamie", "age": 31 } ]
  #
  # It's generally only needed to use this method for top-level arrays. If you have named arrays, you can do:
  #
  #   json.people(@people) do |person|
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
  def array!(collection = BLANK, *attributes, &block)
    @stack << :array
    @encoder.array_open
    
    if _blank?(collection)
      _scope{ yield self }
    else
      _extract_collection(collection, *attributes, &block)
    end

    @encoder.array_close
    @stack.pop
  end
  
  def _extract_collection(collection, *attributes, &block)
    if collection.nil?
      # noop
    elsif block
      collection.each do |element|
        _scope{ yield element }
      end
    elsif attributes.any?
      collection.each { |element| object! { extract!(element, *attributes) } }
    else
      collection.each { |element| @encoder.value(element) }
    end
  end
  
  def object!(&block)
    @stack << :map
    @encoder.map_open
    _scope{ yield self }
    @encoder.map_close
    @stack.pop
  end

  # Extracts the mentioned attributes or hash elements from the passed object and turns them into attributes of the JSON.
  #
  # Example:
  #
  #   @person = Struct.new(:name, :age).new('David', 32)
  #
  #   or you can utilize a Hash
  #
  #   @person = { name: 'David', age: 32 }
  #
  #   json.extract! @person, :name, :age
  #
  #   { "name": David", "age": 32 }, { "name": Jamie", "age": 31 }
  def extract!(object, *attributes)
    if ::Hash === object
      attributes.each{ |key| _set_value key, object.fetch(key) }
    else
      attributes.each{ |key| _set_value key, object.public_send(key) }
    end
  end

  # Merges stack and data into the current builder.
  def merge!(json_text)
    @encoder.flush
    if json_text.length > 0
      _capture do
        @encoder.string("")
        @encoder.string("") if @stack.last == :map
      end
    else
    end
    @output << json_text
  end

  # Encodes the current builder as JSON.
  def target!
    @encoder.flush
    @output.string
  end

  private
  
  def _write(key, value)
    @encoder.string(_key(key))
    @encoder.value(value)
  end

  def _key(key)
    @key_formatter.format(key)
  end

  def _set_value(key, value)
    return if @ignore_nil && value.nil?
    return if _blank?(value)
    _write key, value
  end

  def _capture
    to = ::StringIO.new
    @encoder.output = to
    
    yield
    
    to.string
  ensure
    @encoder.output = @output
  end
  
  def _scope
    parent_attributes, parent_formatter = @attributes, @key_formatter
    yield
  ensure
    @attributes, @key_formatter = parent_attributes, parent_formatter
  end

  def _eachable_arguments?(value, *args)
    value.respond_to?(:each)
  end

  def _blank?(value=@attributes)
    BLANK == value
  end
end

require 'jstreamer/railtie' if defined?(Rails)
