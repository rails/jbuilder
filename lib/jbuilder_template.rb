class JbuilderTemplate < Jbuilder
  def initialize(context, *args)
    @context = context
    super(*args)
  end

  def partial!(options, locals = {})
    case options
    when ::Hash
      options[:locals] ||= {}
      options[:locals].merge!(:json => self)
      @context.render(options)
    else
      @context.render(options, locals.merge(:json => self))
    end
  end

  # Caches the json constructed within the block passed. Has the same signature as the `cache` helper
  # method in `ActionView::Helpers::CacheHelper` and so can be used in the same way.
  #
  # Example:
  #
  #   json.cache! ['v1', @person], :expires_in => 10.minutes do
  #     json.extract! @person, :name, :age
  #   end
  def cache!(key=nil, options={}, &block)
    fragment = self.extract_output_buffer_change do
      @context.cache(key, options) do
        @context.safe_concat(
          ::MultiJson.encode(_scope { yield self }).html_safe
        )
      end
    end
    _merge(::MultiJson.load(fragment))
  end

  protected
  def reset_safety_on_output_buffer
    if @context.output_buffer
      if @context.output_buffer.html_safe?
        @context.output_buffer = @context.output_buffer.class.new(@context.output_buffer)
      end
    else
      @context.output_buffer = ::ActionView::OutputBuffer.new
    end
  end

  def extract_output_buffer_change
    self.reset_safety_on_output_buffer
    pos = @context.output_buffer.length
    yield
    @context.output_buffer.slice!(pos..-1)
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
