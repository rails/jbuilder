require "oj"

class TurboStreamer
  class OjEncoder

    def initialize(io, options={})
      @stack = []
      @indexes = []

      @options = options

      @output = io
      @stream_writer = ::Oj::StreamWriter.new(
        io,
        {mode: :json}.merge(options),
      )
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
        # self.output.write(',') if @indexes.last > 0
        @indexes[-1] += 1
      elsif @stack.last == :map
        # self.output.write(',') if @indexes.last > 0
        @indexes[-1] += 1
      end

      # For string containing key and value like `"key":"value"`
      # OJ stream writer does NOT allow writing the whole string
      # But instead requiring key and value to be input separately
      key_value_match_data = /\A"(\w+?)":(.+)\Z/.match(string)
      if key_value_match_data
        stream_writer.push_json(
          key_value_match_data[2],
          key_value_match_data[1],
        )
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
      @stream_writer = ::Oj::StreamWriter.new(
        output,
        {mode: :json}.merge(options),
      )

      # This is to prevent error from OJ streamer
      # We will strip the brackets afterward
      stream_writer.push_object if @stack.last == :map
      stream_writer.push_array if @stack.last == :array

      yield

      stream_writer.pop_all
      stream_writer.flush
      result = output.string.gsub(/\A,|,\Z/, '')
      # Strip brackets as promised above
      result = result.gsub(/\A{\s*|\s*}\Z/, '') if @stack.last == :map
      result = result.gsub(/\A\[\s*|\s*\]\Z/, '') if @stack.last == :array
      result
    ensure
      @indexes.pop
      @stream_writer = old_writer
      @output = old_output
    end

    def flush
      stream_writer.flush
    end

  end
end
