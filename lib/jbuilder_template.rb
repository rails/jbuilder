class JbuilderTemplate < Jbuilder
  def self.encode(context)
    new(context)._tap { |jbuilder| yield jbuilder }.target!
  end

  def initialize(context)
    @context = context
    super()
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

  private
    def _new_instance
      __class__.new(@context)
    end
end

class JbuilderHandler
  cattr_accessor :default_format
  self.default_format = Mime::JSON

  def self.call(template)
    %{
      if defined?(json)
        #{template.source}
      else
        JbuilderTemplate.encode(self) do |json|
          #{template.source}
        end
      end
    }
  end
end

ActionView::Template.register_template_handler :jbuilder, JbuilderHandler
