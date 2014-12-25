require 'jbuilder/jbuilder'
require 'jbuilder/key_formatter'
require 'jbuilder/errors'
require 'wankel'
require 'stringio'

class Jbuilder
  @@key_formatter = KeyFormatter.new
  @@ignore_nil    = false
  attr_accessor :encoder, :output, :stack
  def initialize(options = {})
    @flag_depth = 0
    @stack = []
    @possible_key_stack = []
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
      if !_blank?(value)
        # json.comments @post.comments { |comment| ... }
        # { "comments": [ { ... }, { ... } ] }
        
        _flag_key_for_possible_write(key)
        _scope{ array! value, &block }
      else
        # json.comments { ... }
        # { "comments": ... }
        # _merge_block(key){ yield self }

        _flag_key_for_possible_write(key)
        _with_possible_map { _scope{ yield self } }
      end
    elsif args.empty?
      if ::Jbuilder === value
        # json.age 32
        # json.person another_jbuilder
        # { "age": 32, "person": { ...  }
        
        _open_map_if_flagged
        @encoder.string(_key(key))
        @encoder.flush
        @output << ":" << value.target!
      else
        # json.age 32
        # { "age": 32 }

        _possibly_write_key
        _open_map_if_flagged
        _set_value(key, value)
      end
    elsif _eachable_arguments?(value, *args) #TODO change to iteratable argument
      # json.comments @post.comments, :content, :created_at
      # { "comments": [ { "content": "hello", "created_at": "..." }, { "content": "world", "created_at": "..." } ] }
      
      _open_map if !_in_map?
      @encoder.string(_key(key))
      _scope{ array! value, *args }
    else
      # json.author @post.creator, :name, :email_address
      # { "author": { "name": "David", "email_address": "david@loudthinking.com" } }
      # _merge_block(key){ extract! value, *args }
      currently_in_array = _in_array?
      
      _open_map_if_flagged
      _possibly_write_key

      _open_map if !currently_in_array
      @encoder.string(_key(key))
      _flag_map_open_needed
      _scope{ extract! value, *args }
      _close_map
      _close_map if !currently_in_array
    end

  end

  alias_method :method_missing, :set!
  private :method_missing

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
  def child!
    _possibly_write_key
    _open_array if !_in_array?
    _unflag_map_open_needed
    _scope{ yield self }
    _close
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
  # If you are using Ruby 1.9+, you can use the call syntax instead of an explicit extract! call:
  #
  #   json.(@people) { |person| ... }
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
  def array!(collection = [], *attributes, &block)
    _possibly_write_key
    _open_array
    
    if collection.nil?
      # noop
    elsif block
      _each_collection(collection, &block)
    elsif attributes.any?
      _each_collection(collection) { |element|
        extract!(element, *attributes)
      }
    else
      collection.each { |element| @encoder.value(element) }
    end

    _close_array
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
  #
  # You can also use the call syntax instead of an explicit extract! call:
  #
  #   json.(@person, :name, :age)
  def extract!(object, *attributes)
    _open_map_if_flagged
    if ::Hash === object
      _extract_hash_values(object, *attributes)
    else
      _extract_method_values(object, *attributes)
    end
  end

  def call(object, *attributes, &block)
    if block
      array! object, &block
    else
      extract! object, *attributes
    end
  end

  # Returns the nil JSON.
  def nil!
    _possibly_write_key
    @encoder.null
  end

  alias_method :null!, :nil!

  # Merges stack and data into the current builder.
  def merge!(json_text, state={})
    @encoder.output = ::StringIO.new
    
    if state[:stack]
      state[:stack].each {|m| self.__send__("_open_#{m}") } 
    end
    @encoder.string("")
    @encoder.string("")
    @output << json_text
    @encoder.output = @output
  end

  # Encodes the current builder as JSON.
  def target!
    _open_map if @stack.size == 0
    _close_stack
    @encoder.flush
    @output.string
  end

  private
  
  def _flag_map_open_needed
    @flag_depth += 1
  end
  
  def _unflag_map_open_needed
    @flag_depth -= 1 if @flag_depth > 0
  end
  
  def _open_map_if_flagged
    if @flag_depth > 0
      _open_map
      _unflag_map_open_needed
    end
  end

  def _open_map
    @encoder.map_open
    @stack.push(:map)
  end
  
  def _close_map
    @encoder.map_close
    @stack.pop
  end
  
  def _in_map?
    @stack.last == :map
  end
  
  def _open_array
    @encoder.array_open
    @stack.push(:array)
  end
  
  def _close_array
    @encoder.array_close
    @stack.pop
  end
  
  def _in_array?
    @stack.last == :array
  end
  
  def _close
    return if @stack.size == 0
    
    if @stack.last == :array
      _close_array
    else
      _close_map
    end
  end
  
  def _close_stack
    while @stack.size > 0
      _close
    end
  end
  
  def _extract_hash_values(object, *attributes)
    attributes.each{ |key| _set_value key, object.fetch(key) }
  end

  def _extract_method_values(object, *attributes)
    attributes.each{ |key| _set_value key, object.public_send(key) }
  end

  def _merge_block(key)
  end

  def _merge_values(current_value, updates)
    if _blank?(updates)
      current_value
    elsif _blank?(current_value) || updates.nil?
      updates
    elsif ::Array === updates
      ::Array === current_value ? current_value + updates : updates
    elsif ::Hash === current_value
      current_value.merge(updates)
    else
      raise "Can't merge #{updates.inspect} with #{current_value.inspect}"
    end
  end

  def _write(key, value)
    if !_in_map?
      _open_map 
    end
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

  def _each_collection(collection)
    collection.each do |element|
      _with_possible_map { _scope{ yield element; } }
    end
  end
  
  def _with_possible_map
    depth = _flag_map_open_needed
    yield
    if @flag_depth <= depth
      _close_map if @stack.last == :map
      _unflag_map_open_needed if @flag_depth <= depth
    end
  end
  
  def _flag_key_for_possible_write(key)
    @possible_key_stack << _key(key)
  end
  
  def _possibly_write_key
    return if @possible_key_stack.size == 0
    _open_map if !_in_map?
    @encoder.string(@possible_key_stack.pop)
  end

  def _capture
    to = ::StringIO.new
    @encoder.output = to
    
    yield
    
    [to.string, {:stack => @stack}]
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

require 'jbuilder/railtie' if defined?(Rails)
