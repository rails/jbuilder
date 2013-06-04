require 'action_dispatch/http/mime_type'

class JbuilderTemplate < Jbuilder
  def initialize(context, *args, &block)
    @context = context
    super(*args, &block)
  end

  def partial!(options, locals = {})
    case options
    when ::Hash
      options[:locals] ||= {}
      options[:locals].merge!(:json => self)
      @context.render(options.reverse_merge(:handlers => [:jbuilder]))
    else # String
      @context.render(:partial => options, :locals => locals.merge(:json => self), :handlers => [:jbuilder])
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
    options[:force] = true unless @context.controller.perform_caching
    value = ::Rails.cache.fetch(_cache_key(key), options) do
      _scope { yield self }
    end

    _merge(value)
  end

  protected
    def _cache_key(key)
      if @context.respond_to?(:cache_fragment_name)
        # Current compatibility, fragment_name_with_digest is private again and cache_fragment_name
        # should be used instead.
        @context.cache_fragment_name(key)
      elsif @context.respond_to?(:fragment_name_with_digest)
        # Backwards compatibility for period of time when fragment_name_with_digest was made public.
        @context.fragment_name_with_digest(key)
      else
        ::ActiveSupport::Cache.expand_cache_key(key.is_a?(::Hash) ? url_for(key).split('://').last : key, :jbuilder)
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