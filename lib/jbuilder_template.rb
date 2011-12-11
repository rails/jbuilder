class JbuilderTemplate < Jbuilder
  def self.encode(context)
    new(context)._tap { |jbuilder| yield jbuilder }.target!
  end

  def initialize(context)
    @context = context
    super()
  end
  
  def partial!(partial_name, options = {})
    @context.render(partial_name, options.merge(:json => self))
  end
  
  private
    def _new_instance
      __class__.new(@context)
    end
end

ActionView::Template.register_template_handler :jbuilder, Proc.new { |template|
  "if defined?(json); #{template.source}; else; JbuilderTemplate.encode(self) do |json|;#{template.source};end; end;"
}
