require 'stringio'
require 'turbostreamer/key_formatter'

class TurboStreamer

  BLANK = ::Object.new


  ENCODERS = {
    json: {oj: 'Oj', wankel: 'Wankel'},
    msgpack: {msgpack: 'MessagePack'}
  }

  @@default_encoders = {}
  @@key_formatter = nil

  undef_method :==
  undef_method :equal?

  def self.encode(options = {}, &block)
    new(options, &block).target!
  end

  def initialize(options = {})
    @output_buffer = options[:output_buffer] || ::StringIO.new
    @encoder = options[:encoder] || TurboStreamer.default_encoder_for(options[:mime] || :json).new(@output_buffer)

    @key_formatter = options.fetch(:key_formatter){ @@key_formatter ? @@key_formatter.clone : nil }

    yield self if ::Kernel.block_given?
  end

  def key!(key)
    @encoder.key(_key(key))
  end

  def value!(value)
    @encoder.value(value)
  end

  def object!(&block)
    @encoder.map_open
    _scope { block.call } if block
    @encoder.map_close
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
    @encoder.array_open

    if _blank?(collection)
      _scope(&block) if block
    else
      _extract_collection(collection, *attributes, &block)
    end

    @encoder.array_close
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

  def self.set_default_encoder(mime, encoder)
    if encoder.is_a?(Symbol)
      @@default_encoders[mime] = get_encoder(mime, encoder)
    else
      @@default_encoders[mime] = encoder
    end
  end

  def self.get_encoder(mime, key)
    require "turbostreamer/encoders/#{key}"
    Object.const_get("TurboStreamer::#{ENCODERS[mime][key]}Encoder")
  end

  def self.default_encoder_for(mime)
    if @@default_encoders[mime]
      @@default_encoders[mime]
    else
      ENCODERS[mime].to_a.find do |key, class_name|
        next if !const_defined?(class_name)
        return get_encoder(mime, key)
      end

      ENCODERS[mime].to_a.find do |key, class_name|
        begin
          return get_encoder(mime, key)
        rescue ::LoadError
          next
        end
      end

      raise ArgumentError, "Could not find an adapter to use"
    end
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
    @encoder.inject(json_text)
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
    @encoder.key(_key(key))
    @encoder.value(value)
  end

  def _key(key)
    @key_formatter ? @key_formatter.format(key) : key.to_s
  end

  def _set_value(key, value)
    return if _blank?(value)
    _write key, value
  end

  def _capture(to=nil, &block)
    @encoder.capture(to, &block)
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


require 'turbostreamer/railtie' if defined?(Rails)
