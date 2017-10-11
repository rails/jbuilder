require 'rails/railtie'
require 'jstreamer/handler'
require 'jstreamer/template'

require File.expand_path('../../ext/actionview/buffer', __FILE__)
require File.expand_path('../../ext/actionview/streaming_template_renderer', __FILE__)

class Jstreamer
  class Railtie < ::Rails::Railtie
    initializer :jstreamer do
      ActiveSupport.on_load :action_view do
        ActionView::Template.register_template_handler :jstreamer, Jstreamer::Handler
        require 'jstreamer/dependency_tracker'
      end
    end
  end
end