require 'wankel'

class TurboStreamer
  class WankelEncoder < ::Wankel::StreamEncoder

    def initialize(io, options={})
      @stack = []
      @indexes = []

      super(io, {mode: :as_json}.merge(options))
    end

    def key(k)
      string(k)
    end

    def value(v)
      if @stack.last == :array || @stack.last == :map
        @indexes[-1] += 1
      end
      super
    end

    def map_open
      @stack << :map
      @indexes << 0
      super
    end

    def map_close
      @indexes.pop
      @stack.pop
      super
    end

    def array_open
      @stack << :array
      @indexes << 0
      super
    end

    def array_close
      @indexes.pop
      @stack.pop
      super
    end

    def inject(string)
      flush

      if @stack.last == :array
        self.output.write(',') if @indexes.last > 0
        @indexes[-1] += 1
      elsif @stack.last == :map
        self.output.write(',') if @indexes.last > 0
        capture do
          string("")
          string("")
        end
        @indexes[-1] += 1
      end

      self.output.write(string)
    end

    def capture(to=nil)
      flush
      old_output = self.output
      to = to || ::StringIO.new
      @indexes << 0
      self.output = to

      yield

      flush
      to.string.gsub(/\A,|,\Z/, '')
    ensure
      @indexes.pop
      self.output = old_output
    end

  end
end
