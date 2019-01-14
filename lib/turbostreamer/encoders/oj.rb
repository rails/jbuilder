require "oj"

class TurboStreamer
  class OjEncoder

    attr_reader :output

    def initialize(io, options={})
      @stack = []
      @indexes = []

      @options = {mode: :json}.merge(options)

      @output = io
      @stream_writer = ::Oj::StreamWriter.new(io, @options)
      @write_comma_on_next_push = false
    end

    def key(k)
      if @write_comma_on_next_push && (@stack.last == :array || @stack.last == :map)
        @stream_writer.flush
        @output.write(",".freeze)
        @write_comma_on_next_push = false
      end
      @stream_writer.push_key(k)
    end

    def value(v)
      if @stack.last == :array || @stack.last == :map
        @indexes[-1] += 1

        if @write_comma_on_next_push
          @stream_writer.flush
          @output.write(",".freeze)
          @write_comma_on_next_push = false
        end
      end
      @stream_writer.push_value(v)
    end

    def map_open
      @stack << :map
      @indexes << 0
      if @write_comma_on_next_push
        @stream_writer.flush
        @output.write(",".freeze)
        @write_comma_on_next_push = false
      end
      @stream_writer.push_object
    end

    def map_close
      @indexes.pop
      @stack.pop
      @stream_writer.pop
    end

    def array_open
      @stack << :array
      @indexes << 0
      if @write_comma_on_next_push
        @stream_writer.flush
        @output.write(",".freeze)
        @write_comma_on_next_push = false
      end
      @stream_writer.push_array
    end

    def array_close
      @indexes.pop
      @stack.pop
      @stream_writer.pop
    end

    def inject(string)
      @stream_writer.flush

      # It's possible to have
      # `@write_comma_on_next_push == true` and `@indexes.last > 0`
      # So there might be double comma written without this flag
      comma_written = false
      if @write_comma_on_next_push
        @output.write(",".freeze)
        @write_comma_on_next_push = false
        comma_written = true
      end

      if @stack.last == :array && !string.empty?
        if @indexes.last > 0
          self.output.write(",") unless comma_written
        else
          @write_comma_on_next_push = true
        end
        @indexes[-1] += 1
      elsif @stack.last == :map && !string.empty?
        if @indexes.last > 0
          self.output.write(",") unless comma_written
        else
          @write_comma_on_next_push = true
        end
        @indexes[-1] += 1
      end

      self.output.write(string.sub(/\A,/, ''.freeze).chomp(",".freeze).strip)
    end

    def capture(to=nil)
      @stream_writer.flush

      old_writer = @stream_writer
      old_output = @output
      @indexes << 0

      @output = (to || ::StringIO.new)
      @stream_writer = ::Oj::StreamWriter.new(@output, @options)

      # This is to prevent error from OJ streamer
      # We will strip the brackets afterward
      if @stack.last == :map
        @stream_writer.push_object
      elsif @stack.last == :array
        @stream_writer.push_array
      end

      yield

      @stream_writer.pop_all
      @stream_writer.flush
      result = output.string.sub(/\A,/, ''.freeze).chomp(",".freeze).strip

      # Strip brackets as promised above
      if @stack.last == :map
        result = result.sub(/\A{/, ''.freeze).chomp("}".freeze)
      elsif @stack.last == :array
        result = result.sub(/\A\[/, ''.freeze).chomp("]".freeze)
      end

      # Possible for `output.string` to have value like
      # `[,{"key":"value"}]\n`
      # Thus the comma must be removed here
      result.sub(/\A,/, ''.freeze)
    ensure
      @indexes.pop
      @stream_writer = old_writer
      @output = old_output
    end

    def flush
      @stream_writer.flush
    end

  end
end
