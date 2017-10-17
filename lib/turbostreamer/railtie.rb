require 'rails/railtie'
require 'turbostreamer/handler'
require 'turbostreamer/template'

require File.expand_path('../../../ext/actionview/buffer', __FILE__)
require File.expand_path('../../../ext/actionview/streaming_template_renderer', __FILE__)

class TurboStreamer
  class Railtie < ::Rails::Railtie
    initializer :turbostreamer do
      ActiveSupport.on_load :action_view do
        ActionView::Template.register_template_handler :streamer, TurboStreamer::Handler
        require 'turbostreamer/dependency_tracker'
      end
    end
  end
end