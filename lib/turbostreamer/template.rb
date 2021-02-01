require 'turbostreamer'

class TurboStreamer::Template < TurboStreamer
  
  class << self
    attr_accessor :template_lookup_options
  end

  self.template_lookup_options = { handlers: [:streamer] }

  def initialize(context, *args, &block)
    @context = context
    super(*args, &block)
  end
  
  def partial!(name_or_options, locals = {})
    if name_or_options.class.respond_to?(:model_name) && name_or_options.respond_to?(:to_partial_path)
      @context.render(name_or_options, json: self)
    else
      if name_or_options.is_a?(Hash)
        options = name_or_options
      else
        if locals.one? && (locals.keys.first == :locals)
          options = locals.merge(partial: name_or_options)
        else
          options = { partial: name_or_options, locals: locals }
        end
        # partial! 'name', foo: 'bar'
        as = locals.delete(:as)
        options[:as] = as if as.present?
        options[:collection] = locals[:collection] if locals.key?(:collection)
      end
      
      _render_partial_with_options options
    end
  end

  def array!(collection = BLANK, *attributes, &block)
    options = attributes.extract_options!

    if options.key?(:partial)
      partial! options.merge(collection: collection)
    else
      super
    end
  end

  # Caches the json constructed within the block passed. Has the same signature
  # as the `cache` helper method in `ActionView::Helpers::CacheHelper` and so
  # can be used in the same way.
  #
  # Example:
  #
  #   json.cache! ['v1', @person], expires_in: 10.minutes do
  #     json.extract! @person, :name, :age
  #   end
  def cache!(key=nil, options={})
    if @context.controller.perform_caching
      value = _cache_fragment_for(key, options) do
        _capture { _scope { yield self }; }
      end

      inject!(value)
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
      results = _read_multi_fragment_cache(keys_to_collection_map.keys, options)
      
      array! do
        keys_to_collection_map.each_key do |key|
          if results[key]
            inject!(results[key])
          else
            value = _write_fragment_cache(key, options) do
              _capture { _scope { yield keys_to_collection_map[key] } }
            end
            inject!(value)
          end
        end
      end
    else
      array! collection, options, &block
    end
  end

  # Conditionally catches the json depending in the condition given as first
  # parameter. Has the same signature as the `cache` helper method in
  # `ActionView::Helpers::CacheHelper` and so can be used in the same way.
  #
  # Example:
  #
  #   json.cache_if! !admin?, @person, expires_in: 10.minutes do
  #     json.extract! @person, :name, :age
  #   end
  def cache_if!(condition, *args, &block)
    condition ? cache!(*args, &block) : yield
  end

  private

  def _render_partial_with_options(options)

    options.reverse_merge! ::TurboStreamer::Template.template_lookup_options
    as = options[:as]&.to_sym
    options[:locals] ||= {}
    options[:locals][:json] = self

    if as && options.key?(:collection)
      # Option 1, nice simple, fast, calls find_template once
      array! { @context.render(options) }

      # Option 2, the jBuilder way, slow because find_template for every item
      # in the collection (a method which is known as one of the heaviest parts
      # of Action View)
      # as = as.to_sym
      # collection = options.delete(:collection)
      # locals = options.delete(:locals)
      # array! collection do |member|
      #   member_locals = locals.clone
      #   member_locals.merge! collection: collection
      #   member_locals.merge! as => member
      #   _render_partial options.merge(locals: member_locals)
      # end

      # Option 3, the fastest, haven't looked into precisely why, but would need
      # to customeize to the rails version
      # lookup_context = @context.view_renderer.lookup_context
      # options[:locals][:json] = self
      # options[:locals][:collection] = options[:collection]
      #
      # pr = ActionView::PartialRenderer.new(lookup_context)
      # pr.send(:setup, @context, options, as, nil)
      # path = pr.instance_variable_get(:@path)
      # a, b, c = pr.send(:retrieve_variable, path, as)
      # template_keys = pr.send(:retrieve_template_keys, a).compact
      # # + [:"#{a}__counter", :"#{a}_iteration"]
      # template = pr.send(:find_partial, path, template_keys)
      # locals = options[:locals]
      # array! options[:collection] do |member|
      #   locals[as] = member
      #   template.render(@context, locals)
      # end
    else
      @context.render(options)
    end
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

  def _cache_fragment_for(key, options, &block)
    key = _cache_key(key, options)
    _read_fragment_cache(key, options) || _write_fragment_cache(key, options, &block)
  end

  def _read_multi_fragment_cache(keys, options = nil)
    @context.controller.instrument_fragment_cache :read_multi_fragment, keys do
      ::Rails.cache.read_multi(*keys, options)
    end
  end

  def _read_fragment_cache(key, options = nil)
    @context.controller.instrument_fragment_cache :read_fragment, key do
      ::Rails.cache.read(key, options)
    end
  end

  def _write_fragment_cache(key, options = nil)
    @context.controller.instrument_fragment_cache :write_fragment, key do
      yield.tap do |value|
        ::Rails.cache.write(key, value, options)
      end
    end
  end

  def _cache_key(key, options)
    name_options = options.slice(:skip_digest, :virtual_path)
    key = _fragment_name_with_digest(key, name_options)

    if @context.respond_to?(:combined_fragment_cache_key)
      key = @context.combined_fragment_cache_key(key)
    elsif @context.respond_to?(:fragment_cache_key)
      # TODO: remove after droping rails 5.1 support
      key = @context.fragment_cache_key(key)
    elsif ::Hash === key
      key = url_for(key).split('://', 2).last
    end

    ::ActiveSupport::Cache.expand_cache_key(key, :streamer)
  end

  def _fragment_name_with_digest(key, options)
    if @context.respond_to?(:cache_fragment_name)
      # Current compatibility, fragment_name_with_digest is private again and cache_fragment_name
      # should be used instead.
      @context.cache_fragment_name(key, **options)
    elsif @context.respond_to?(:fragment_name_with_digest)
      # Backwards compatibility for period of time when fragment_name_with_digest was made public.
      @context.fragment_name_with_digest(key)
    else
      key
    end
  end

  def _partial_options?(options)
    ::Hash === options && options.key?(:as) && options.key?(:partial)
  end

  def _is_active_model?(object)
    object.class.respond_to?(:model_name) && object.respond_to?(:to_partial_path)
  end

  def _eachable_arguments?(value, *args)
    return true if super
    options = args.last
    ::Hash === options && options.key?(:as)
  end
end