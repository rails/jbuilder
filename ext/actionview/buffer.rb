module ActionView
  class OutputBuffer
    alias :write :safe_concat
  end
  
  class StreamingBuffer #:nodoc:
    alias :write :safe_concat
  end
  
  class JSONStreamingBuffer #:nodoc:
    def initialize(block)
      @block = block
    end

    def <<(value)
      @block.call(value.to_s)
    end
    alias :write  :<<
    alias :concat  :<<
    alias :append= :<<
    alias :safe_concat :<<
    alias :safe_append= :<<
  end
  
end
