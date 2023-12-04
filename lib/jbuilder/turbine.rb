require 'jets'
require 'jbuilder/jbuilder_template'

class Jbuilder
  class Engine < ::Jets::Engine
    initializer :jbuilder do
      ActiveSupport.on_load :action_view do
        ActionView::Template.register_template_handler :jbuilder, JbuilderHandler
        require 'jbuilder/jbuilder_dependency_tracker'
      end
    end
  end
end
