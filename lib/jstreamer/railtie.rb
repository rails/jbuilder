require 'rails/railtie'
require 'jstreamer/jstreamer_template'

class Jstreamer
  class Railtie < ::Rails::Railtie
    initializer :jstreamer do |app|
      ActiveSupport.on_load :action_view do
        ActionView::Template.register_template_handler :jstreamer, JstreamerHandler
        require 'jstreamer/dependency_tracker'
      end
    end

    generators do |app|
      Rails::Generators.configure! app.config.generators
      Rails::Generators.hidden_namespaces.uniq!
      require 'generators/rails/scaffold_controller_generator'
    end

  end
end

module ActionView
  class StreamingBuffer #:nodoc:
    alias :write :safe_concat
  end
end