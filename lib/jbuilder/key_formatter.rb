# frozen_string_literal: true

require 'jbuilder/jbuilder'

class Jbuilder
  class KeyFormatter
    def initialize(*formats, **formats_with_options)
      @mutex = Mutex.new
      @formats = formats
      @formats_with_options = formats_with_options
      @cache = {}
    end

    def format(key)
      @mutex.synchronize do
        @cache[key] ||= begin
          value = key.is_a?(Symbol) ? key.name : key.to_s

          @formats.each do |func|
            value = func.is_a?(Proc) ? func.call(value) : value.send(func)
          end

          @formats_with_options.each do |func, params|
            value = func.is_a?(Proc) ? func.call(value, *params) : value.send(func, *params)
          end

          value
        end
      end
    end
  end
end
