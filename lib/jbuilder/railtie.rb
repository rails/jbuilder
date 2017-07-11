require 'rails/railtie'
require 'jbuilder/jbuilder_template'

class Jbuilder
  class Railtie < ::Rails::Railtie
    initializer :jbuilder do
      ActiveSupport.on_load :action_view do
        ActionView::Template.register_template_handler :jbuilder, JbuilderHandler
        require 'jbuilder/dependency_tracker'
      end

      if Rails::VERSION::MAJOR >= 5
        ActiveSupport.on_load :action_controller do
          if self == ActionController::API
            include ActionController::Helpers
            include ActionController::ImplicitRender
            include ActionView::Rendering
          end
        end
      end
    end

    if Rails::VERSION::MAJOR >= 4
      generators do |app|
        Rails::Generators.configure! app.config.generators
        Rails::Generators.hidden_namespaces.uniq!
        require 'generators/rails/scaffold_controller_generator'
      end
    end
  end
end
