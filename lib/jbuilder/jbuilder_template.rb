require 'action_dispatch/http/mime_type'

class JbuilderTemplate < Jbuilder
  class << self
    attr_accessor :template_lookup_options
  end

  self.template_lookup_options = { :handlers => [:jbuilder] }

  def initialize(context, *args, &block)
    @context = context
    super(*args, &block)
  end

  def partial!(name_or_options, locals = {})
    case name_or_options
    when ::Hash
      # partial! partial: 'name', locals: { foo: 'bar' }
      options = name_or_options
    else
      # partial! 'name', foo: 'bar'
      options = { :partial => name_or_options, :locals => locals }
      as = locals.delete(:as)
      options[:as] = as if as.present?
      options[:collection] = locals[:collection] if locals.key?(:collection)
    end

    options[:collection] ||= [] if options.key?(:collection)

    _handle_partial_options options
  end

  def array!(collection = [], *attributes, &block)
    options = attributes.extract_options!

    if options.key?(:partial)
      partial! options[:partial], options.merge(:collection => collection)
    else
      super
    end
  end

  # Caches the json constructed within the block passed. Has the same signature as the `cache` helper
  # method in `ActionView::Helpers::CacheHelper` and so can be used in the same way.
  #
  # Example:
  #
  #   json.cache! ['v1', @person], expires_in: 10.minutes do
  #     json.extract! @person, :name, :age
  #   end
  def cache!(key=nil, options={}, &block)
    if @context.controller.perform_caching
      value = ::Rails.cache.fetch(_cache_key(key), options) do
        _scope { yield self }
      end

      _merge(value)
    else
      yield
    end
  end

  protected
    def _handle_partial_options(options)
      options.reverse_merge! :locals => {}
      options.reverse_merge! ::JbuilderTemplate.template_lookup_options
      collection = options.delete(:collection)
      as = options[:as]

      if collection && as
        array!(collection) do |member|
          options[:locals].merge!(as => member, :collection => collection)
          _render_partial options
        end
      else
        _render_partial options
      end
    end

    def _render_partial(options)
      options[:locals].merge!(:json => self)
      @context.render options
    end

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

  private

    def _mapable_arguments?(value, *args)
      return true if super
      options = args.last
      ::Hash === options && options.key?(:as)
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
