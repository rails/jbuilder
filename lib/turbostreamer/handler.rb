require "turbostreamer"
require "active_support/core_ext"
# This module makes TurboStreamer work with Rails using the template handler API.

class TurboStreamer
  class Handler
    
    class_attribute :default_format
    self.default_format = :json
    
    def self.supports_streaming?
      true
    end
    
    # TODO: setting source=nil is for rails 5.x compatability, once unsppored
    # source can be a required param and
    # `source = template.source if source.nil?` can be removed
    def self.call(template, source=nil)
      source = template.source if source.nil?
      # this juggling is required to keep line numbers right in the error
      %{__already_defined = defined?(json); json||=TurboStreamer::Template.new(self, output_buffer: output_buffer || ActionView::OutputBuffer.new); #{source}
        json.target! unless (__already_defined && __already_defined != "method")}
    end
    
  end
end