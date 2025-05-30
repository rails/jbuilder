require 'jbuilder/jbuilder'

class Jbuilder
  class KeyFormatter
    def initialize(*formats, **formats_with_options)
      @cache =
        Hash.new do |hash, key|
          value = key.is_a?(Symbol) ? key.name : key.to_s

          formats.each do |func|
            value = func.is_a?(Proc) ? func.call(value) : value.send(func)
          end

          formats_with_options.each do |func, params|
            value = func.is_a?(Proc) ? func.call(value, *params) : value.send(func, *params)
          end

          hash[key] = value
        end
    end

    def format(key)
      @cache[key]
    end
  end
end
