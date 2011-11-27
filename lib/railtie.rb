class Jbuilder < BlankSlate
  class Railtie < Rails::Railtie
    initializer "jbuilder.template_handler" do
      ActionView::Template.register_template_handler :jbuilder, -> template { "Jbuilder.encode do |json|;#{template.source};end;" }
    end
  end
end