require 'wankel'
require 'stringio'
require 'jstreamer/key_formatter'

class Jstreamer
  
  BLANK = ::Object.new
  
  @@key_formatter = nil

  undef_method :==
  undef_method :equal?
  
  def self.encode(options = {}, &block)
    new(options, &block).target!
  end
  
  def initialize(options = {})
    @stack = []
    @array_indexes = []
    
    @output_buffer = options[:output_buffer] || ::StringIO.new
    @encoder = ::Wankel::StreamEncoder.new(@output_buffer, mode: :as_json)

    @key_formatter = options.fetch(:key_formatter){ @@key_formatter ? @@key_formatter.clone : nil }

    yield self if ::Kernel.block_given?
  end
  
  def key!(key)
    @encoder.string(_key(key))
  end
    
  def value!(value)
    if @stack.last == :array
      @array_indexes[-1] -= 1
    end
    @encoder.value(value)
  end
  
  def object!(&block)
    @stack << :map
    @encoder.map_open
    _scope { block.call } if block
    @encoder.map_close
    @stack.pop
  end
  
  # Extracts the mentioned attributes or hash elements from the passed object 
  # and turns them into a JSON object.
  #
  # Example:
  #
  #   @person = Struct.new(:name, :age).new('David', 32)
  #
  #   or you can utilize a Hash
  #
  #   @person = { name: 'David', age: 32 }
  #
  #   json.pluck! @person, :name, :age
  #
  #   { "name": David", "age": 32 }
  def pluck!(object, *attributes)
    object! do
      extract!(object, *attributes)
    end
  end
  
  # Extracts the mentioned attributes or hash elements from the passed object 
  # and turns them into attributes of the JSON.
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
  
  # Turns the current element into an array and iterates over the passed
  # collection, adding each iteration as an element of the resulting array.
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
  # It's generally only needed to use this method for top-level arrays. If you 
  # have named arrays, you can do:
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
    @array_indexes << 0
    @encoder.array_open
    
    if _blank?(collection)
      _scope(&block) if block
    else
      _extract_collection(collection, *attributes, &block)
    end

    @encoder.array_close
    @array_indexes.pop
    @stack.pop
  end

  
  def set!(key, value = BLANK, *args, &block)
    key!(key)
    
    if block
      if !_blank?(value)
        # json.comments @post.comments { |comment| ... }
        # { "comments": [ { ... }, { ... } ] }
        _scope { array!(value, &block) }
      else
        # json.comments { ... }
        # { "comments": ... }
        _scope(&block)
      end
    elsif args.empty?
      # json.age 32
      # { "age": 32 }
      value!(value)
    elsif _eachable_arguments?(value, *args)
      # json.comments @post.comments, :content, :created_at
      # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
      _scope{ array!(value, *args) }
    else
      # json.author @post.creator, :name, :email_address
      # { "author": { "name": "David", "email_address": "david@thinking.com" } }
      object!{ extract!(value, *args) }
    end
  end

  alias_method :method_missing, :set!
  private :method_missing

  # Specifies formatting to be applied to the key. Passing in a name of a
  # function  will cause that function to be called on the key.  So :upcase
  # will upper case the key.  You can also pass in lambdas for more complex
  # transformations.
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

  def self.key_formatter=(formatter)
    @@key_formatter = formatter
  end
  

  def _extract_collection(collection, *attributes, &block)
    if collection.nil?
      # noop
    elsif block
      collection.each do |element|
        _scope{ yield element }
      end
    elsif attributes.any?
      collection.each { |element| pluck!(element, *attributes) }
    else
      collection.each { |element| value!(element) }
    end
  end

  # Inject a valid JSON string into the current
  def inject!(json_text)
    @encoder.flush
    
    if @stack.last == :array
      @encoder.output.write(',') if @array_indexes.last != 0
      @array_indexes[-1] -= 1
    elsif @stack.last == :map
      _capture do
        @encoder.string("")
        @encoder.string("")
      end
    end
    
    @encoder.output.write(json_text)
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
      if _eachable_arguments?(value, *args)
        # json.child! comments { |c| ... }
        _scope { array!(value, &block) }
      else
        # json.child! { ... }
        # [...]
        _scope(&block)
      end
    elsif args.empty?
      value!(value)
    elsif _eachable_arguments?(value, *args)
      _scope{ array!(value, *args) }
    else
      object!{ extract!(value, *args) }
    end
    
  end
  
  # Encodes the current builder as JSON.
  def target!
    @encoder.flush
    
    if @encoder.output.is_a?(::StringIO)
      @encoder.output.string
    else
      @encoder.output
    end
  end
  
  private
  
  def _write(key, value)
    @encoder.string(_key(key))
    @encoder.value(value)
  end

  def _key(key)
    @key_formatter ? @key_formatter.format(key) : key.to_s
  end

  def _set_value(key, value)
    return if _blank?(value)
    _write key, value
  end

  def _capture(to=nil)
    @encoder.flush
    old, to = @encoder.output, to || ::StringIO.new
    @encoder.output = to
    
    yield
    
    @encoder.flush
    to.string.gsub(/\A,|,\Z/, '')
  ensure
    @encoder.output = old
  end
    
  def _scope
    parent_formatter = @key_formatter
    yield
  ensure
    @key_formatter = parent_formatter
  end

  def _eachable_arguments?(value, *args)
    value.respond_to?(:each) && !value.is_a?(Hash)
  end

  def _blank?(value=@attributes)
    BLANK == value
  end
  
end

require 'jstreamer/railtie' if defined?(Rails)