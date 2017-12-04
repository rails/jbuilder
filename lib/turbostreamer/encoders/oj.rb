require "oj"

class TurboStreamer
  class OjEncoder

    def initialize(io, options={})
      @stack = []
      @indexes = []

      @options = {mode: :json}.merge(options)

      @output = io
      @stream_writer = ::Oj::StreamWriter.new(io, @options)
    end

    attr_reader :options
    attr_reader :output
    attr_reader :stream_writer

    def key(k)
      stream_writer.push_key(k)
    end

    def value(v)
      if @stack.last == :array || @stack.last == :map
        @indexes[-1] += 1
      end
      stream_writer.push_value(v)
    end

    def map_open
      @stack << :map
      @indexes << 0
      stream_writer.push_object
    end

    def map_close
      @indexes.pop
      @stack.pop
      stream_writer.pop
    end

    def array_open
      @stack << :array
      @indexes << 0
      stream_writer.push_array
    end

    def array_close
      @indexes.pop
      @stack.pop
      stream_writer.pop
    end

    def inject(string)
      stream_writer.flush

      if @stack.last == :array
        @indexes[-1] += 1
      elsif @stack.last == :map
        @indexes[-1] += 1
      end

      # For string containing key and value like `"key":"value"`
      # OJ stream writer does NOT allow writing the whole string
      # But instead requiring key and value to be input separately

      # `Regexp#match?` is much faster than `=~`
      # https://stackoverflow.com/a/11908214/838346
      string_contain_key = if REGEXP_SUPPORT_FAST_MATCH
        JSON_OBJ_KEY_REGEXP.match?(string)
      else
        JSON_OBJ_KEY_REGEXP =~ string
      end

      if string_contain_key
        # Using `String[Regexp, index]`
        # is faster than `#match` according to benchmark
        # Of course still slower than `=~` & `match?`
        key = string[JSON_OBJ_KEY_REGEXP, 1]
        # 2 quotes, 1 colon
        # Use range form to get substring is fastest
        #
        # See benchmark on SO
        # https://stackoverflow.com/a/3614592/838346
        value = string[(3 + key.length)..-1]

        stream_writer.push_json(value, key)
      else
        stream_writer.push_json(string)
      end
    end

    def capture(to=nil)
      stream_writer.flush

      old_writer = self.stream_writer
      old_output = self.output
      @indexes << 0

      @output = (to || ::StringIO.new)
      @stream_writer = ::Oj::StreamWriter.new(@output, @options)

      # This is to prevent error from OJ streamer
      # We will strip the brackets afterward
      if @stack.last == :map
        stream_writer.push_object
      elsif @stack.last == :array
        stream_writer.push_array
      end

      yield

      stream_writer.pop_all
      stream_writer.flush
      result = output.string.sub(/\A,/, ''.freeze).chomp(",".freeze).strip
      # Strip brackets as promised above
      if @stack.last == :map
        result = result.sub(/\A{/, ''.freeze).chomp("}".freeze)
      elsif @stack.last == :array
        result = result.sub(/\A\[/, ''.freeze).chomp("]".freeze)
      end

      result
    ensure
      @indexes.pop
      @stream_writer = old_writer
      @output = old_output
    end

    def flush
      stream_writer.flush
    end

    JSON_OBJ_KEY_REGEXP = /\A"(\w+?)":/.freeze
    private_constant :JSON_OBJ_KEY_REGEXP

    REGEXP_SUPPORT_FAST_MATCH = JSON_OBJ_KEY_REGEXP.respond_to?(:match?)
    private_constant :REGEXP_SUPPORT_FAST_MATCH

  end
end
