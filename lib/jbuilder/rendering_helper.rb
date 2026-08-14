# frozen_string_literal: true

class Jbuilder
  module RenderingHelper # :nodoc:
    def _layout_for(*args, &block)
      if block.nil? && (content = @_jbuilder)
        @_jbuilder = nil
        content
      else
        super
      end
    end

    def _jbuilder=(content)
      @_jbuilder = content
    end
  end
end
