# frozen_string_literal: true

require 'rails'
require 'jbuilder/jbuilder_template'

class Jbuilder
  class Railtie < ::Rails::Railtie
    initializer :jbuilder do
      ActiveSupport.on_load :action_view do
        ActionView::Template.register_template_handler :jbuilder, JbuilderHandler
        require 'jbuilder/jbuilder_dependency_tracker'
      end

      module ::ActionController
        module ApiRendering
          include ActionView::Rendering
        end
      end

      ActiveSupport.on_load :action_controller_api do
        include ActionController::Helpers
        include ActionController::ImplicitRender
        helper_method :combined_fragment_cache_key
        helper_method :view_cache_dependencies
      end
    end

    generators do |app|
      Rails::Generators.configure! app.config.generators
      Rails::Generators.hidden_namespaces.uniq!
      require 'generators/rails/scaffold_controller_generator'
    end
  end
end
