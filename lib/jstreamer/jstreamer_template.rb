require 'jstreamer'
require 'stringio'
require 'action_dispatch/http/mime_type'
require 'active_support/cache'

class JstreamerTemplate < Jstreamer
  
  class << self
    attr_accessor :template_lookup_options
  end

  self.template_lookup_options = { handlers: [:jstreamer] }

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
      options = { partial: name_or_options, locals: locals }
      as = locals.delete(:as)
      options[:as] = as if as.present?
      options[:collection] = locals[:collection] if locals.key?(:collection)
    end

    _render_partial_with_options options
  end

  def array!(collection = BLANK, *attributes, &block)
    options = attributes.extract_options!

    if options.key?(:partial)
      partial! options[:partial], options.merge(collection: collection)
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
  def cache!(key=nil, options={})
    if @context.controller.perform_caching
      value = ::Rails.cache.fetch(_cache_key(key, options), options) do
        _capture { _scope { yield self }; }
      end
      merge!(value)
    else
      yield
    end
  end
  
  # Caches a collection of objects using fetch_multi, if supported.
  # Requires a block for each item in the array. Accepts optional 'key' attribute
  # in options (e.g. key: 'v1').
  #
  # Example:
  #
  # json.cache_collection! @people, expires_in: 10.minutes do |person|
  #   json.partial! 'person', :person => person
  # end
  def cache_collection!(collection, options = {}, &block)
    if @context.controller.perform_caching
      keys_to_collection_map = _keys_to_collection_map(collection, options)  
      results = ::Rails.cache.read_multi(*keys_to_collection_map.keys, options)
      
      array! do
        keys_to_collection_map.keys.each do |key|
          if results[key]
            merge!(results[key])
          else
            value = _capture { _scope { yield keys_to_collection_map[key] } }
            ::Rails.cache.write(key, value, options)
            merge!(value)
          end
        end
      end
    else
      array! collection, options, &block
    end
  end

  # Conditionally catches the json depending in the condition given as first parameter. Has the same
  # signature as the `cache` helper method in `ActionView::Helpers::CacheHelper` and so can be used in
  # the same way.
  #
  # Example:
  #
  #   json.cache_if! !admin?, @person, expires_in: 10.minutes do
  #     json.extract! @person, :name, :age
  #   end
  def cache_if!(condition, *args, &block)
    condition ? cache!(*args, &block) : yield
  end

  protected

  def _render_partial_with_options(options)
    options.reverse_merge! locals: {}
    options.reverse_merge! ::JstreamerTemplate.template_lookup_options
    as = options[:as]

    if as && options.key?(:collection)
      as = as.to_sym
      collection = options.delete(:collection)
      locals = options.delete(:locals)
      array! collection do |member|
        member_locals = locals.clone
        member_locals.merge! collection: collection
        member_locals.merge! as => member
        _render_partial options.merge(locals: member_locals)
      end
    else
      _render_partial options
    end
  end

  def _render_partial(options)
    options[:locals].merge! json: self
    @context.render options
  end

  def _cache_key(key, options)
    key = _fragment_name_with_digest(key, options)
    key = url_for(key).split('://', 2).last if ::Hash === key
    ::ActiveSupport::Cache.expand_cache_key(key, :jstreamer)
  end

  def _keys_to_collection_map(collection, options)
    key = options.delete(:key)

    collection.inject({}) do |result, item|
      key = key.respond_to?(:call) ? key.call(item) : key
      cache_key = key ? [key, item] : item
      result[_cache_key(cache_key, options)] = item
      result
    end
  end
    
  private

  def _fragment_name_with_digest(key, options)
    if @context.respond_to?(:cache_fragment_name)
      # Current compatibility, fragment_name_with_digest is private again and cache_fragment_name
      # should be used instead.
      @context.cache_fragment_name(key, options)
    elsif @context.respond_to?(:fragment_name_with_digest)
      # Backwards compatibility for period of time when fragment_name_with_digest was made public.
      @context.fragment_name_with_digest(key)
    else
      key
    end
  end

  def _eachable_arguments?(value, *args)
    return true if super
    options = args.last
    ::Hash === options && options.key?(:as)
  end
end

class JstreamerHandler
  cattr_accessor :default_format
  self.default_format = Mime::JSON

  def self.supports_streaming?
    true
  end
  
  def self.call(template)
    # this juggling is required to keep line numbers right in the error
    %{__already_defined = defined?(json); json ||= JstreamerTemplate.new(self); json.encoder.output = output_buffer if output_buffer; #{template.source}
      json.target! unless (__already_defined && __already_defined != "method")}
  end
end
