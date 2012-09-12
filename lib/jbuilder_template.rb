class JbuilderTemplate < Jbuilder
  def self.encode(context)
    new(context)._tap { |jbuilder| yield jbuilder }.target!
  end

  def initialize(context, *args)
    @context = context
    super(*args)
  end

  def partial!(options, locals = {})
    case options
    when Hash
      options[:locals] ||= {}
      options[:locals].merge!(:json => self)
      @context.render(options)
    else
      @context.render(options, locals.merge(:json => self))
    end
  end
end

class JbuilderHandler
  cattr_accessor :default_format
  self.default_format = Mime::JSON

  def self.call(template)
    # this juggling is required to keep line numbers right in the error
    %{__already_defined = defined?(json); json||=JbuilderTemplate.new(self); #{template.source}
      json.target! unless __already_defined}
  end
end

ActionView::Template.register_template_handler :jbuilder, JbuilderHandler
