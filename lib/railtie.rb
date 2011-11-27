class JsonBuilder
  class Railtie < Rails::Railtie
    initializer "json_builder.template_handler" do
      ActionView::Template.register_template_handler :jbuilder, -> template { "JsonBuilder.encode do |json|;#{template.source};end;" }
    end
  end
end