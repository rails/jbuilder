require 'test_helper'

PARTIAL_TEMPLATE = <<-JSTREAMER
  json.object! { json.content "hello" }
JSTREAMER

BLOG_POST_TEMPLATE = <<-JSTREAMER
  json.object! do
    json.extract! blog_post, :id, :body
    json.author do
      name = blog_post.author_name.split(nil, 2)
      json.object! do
        json.first_name name[0]
        json.last_name  name[1]
      end
    end
  end
JSTREAMER

COLLECTION_TEMPLATE = <<-JSTREAMER
  json.object! do
    json.extract! collection, :id, :name
  end
JSTREAMER

CACHE_KEY_PROC = Proc.new { |blog_post| true }

BlogPost = Struct.new(:id, :body, :author_name)
Collection = Struct.new(:id, :name)
blog_authors = [ 'David Heinemeier Hansson', 'Pavel Pravosud' ].cycle
BLOG_POST_COLLECTION = 10.times.map{ |i| BlogPost.new(i+1, "post body #{i+1}", blog_authors.next) }
COLLECTION_COLLECTION = 5.times.map{ |i| Collection.new(i+1, "collection #{i+1}") }

ActionView::Template.register_template_handler :jstreamer, Jstreamer::Handler

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

class JstreamerTemplateTest < ActionView::TestCase
  setup do
    @context = self
    @virtual_path = nil
    Rails.cache.clear
  end

  def partials
    {
      '_partial.json.jstreamer'  => PARTIAL_TEMPLATE,
      '_blog_post.json.jstreamer' => BLOG_POST_TEMPLATE,
      '_collection.json.jstreamer' => COLLECTION_TEMPLATE
    }
  end

  def render_jstreamer(source)
    @rendered = []
    lookup_context.view_paths = [ActionView::FixtureResolver.new(partials.merge('test.json.jstreamer' => source))]
    ActionView::Template.new(source, 'test', Jstreamer::Handler, virtual_path: 'test').render(self, {}).strip
  end

  def undef_context_methods(*names)
    self.class_eval do
      names.each do |name|
        undef_method name.to_sym if method_defined?(name.to_sym)
      end
    end
  end

  def assert_collection_rendered(json, *selector)
    result = Wankel.load(json)
    overrides = selector.last.is_a?(Hash) ? selector.pop : {}
    result = result.dig(*selector) if !selector.empty?

    assert_equal 10, result.length
    assert_equal Array, result.class

    overrides.each do |index, value|
      assert_equal value, result[index]
    end
    
    assert_equal('post body 5', result[4]['body']) unless overrides[4]
    assert_equal('Heinemeier Hansson', result[2]['author']['last_name']) unless overrides[2]
    assert_equal('Pavel', result[5]['author']['first_name']) unless overrides[5]
  end

  test 'rendering' do
    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.content 'hello'
      end
    JSTREAMER

    assert_equal({"content" => 'hello'}, Wankel.load(json))
  end

  # Partial Test ===========================================================

  test 'partial! renders partial' do
    json = render_jstreamer <<-JSTREAMER
      json.partial! 'partial'
    JSTREAMER

    assert_equal({"content" => 'hello'}, Wankel.load(json))
  end

  test 'partial! renders collections' do
    json = render_jstreamer <<-JSTREAMER
      json.partial! 'blog_post', :collection => BLOG_POST_COLLECTION, :as => :blog_post
    JSTREAMER

    assert_collection_rendered json
  end

  test 'partial! renders collections when as argument is a string' do
    json = render_jstreamer <<-JSTREAMER
      json.partial! 'blog_post', collection: BLOG_POST_COLLECTION, as: "blog_post"
    JSTREAMER

    assert_collection_rendered json
  end

  test 'partial! renders collections as collections' do
    json = render_jstreamer <<-JSTREAMER
      json.partial! 'collection', collection: COLLECTION_COLLECTION, as: :collection
    JSTREAMER

    assert_equal 5, Wankel.load(json).length
  end

  test 'partial! renders as empty array for nil-collection' do
    json = render_jstreamer <<-JSTREAMER
      json.partial! 'blog_post', :collection => nil, :as => :blog_post
    JSTREAMER

    assert_equal '[]', json
  end

  test 'partial! renders collection (alt. syntax)' do
    json = render_jstreamer <<-JSTREAMER
      json.partial! :partial => 'blog_post', :collection => BLOG_POST_COLLECTION, :as => :blog_post
    JSTREAMER

    assert_collection_rendered json
  end

  test 'partial! renders as empty array for nil-collection (alt. syntax)' do
    json = render_jstreamer <<-JSTREAMER
      json.partial! :partial => 'blog_post', :collection => nil, :as => :blog_post
    JSTREAMER

    assert_equal '[]', json
  end

  test 'render array of partials' do
    json = render_jstreamer <<-JSTREAMER
      json.array! BLOG_POST_COLLECTION, :partial => 'blog_post', :as => :blog_post
    JSTREAMER

    assert_collection_rendered json
  end

  test 'render array of partials as empty array with nil-collection' do
    json = render_jstreamer <<-JSTREAMER
      json.array! nil, :partial => 'blog_post', :as => :blog_post
    JSTREAMER

    assert_equal '[]', json
  end

  test 'render array if partials as a value' do
    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.posts BLOG_POST_COLLECTION, :partial => 'blog_post', :as => :blog_post
      end
    JSTREAMER

    assert_collection_rendered json, 'posts'
  end

  test 'render as empty array if partials as a nil value' do
    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.posts nil, :partial => 'blog_post', :as => :blog_post
      end
    JSTREAMER

    assert_equal '{"posts":[]}', json
  end

  # Caching Test ===========================================================

  test 'fragment caching a JSON object' do
    undef_context_methods :cache_fragment_name

    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.cache! 'cachekey' do
          json.name 'Cache'
        end
      end
    JSTREAMER
    assert_equal({'name' => 'Cache'}, Wankel.load(json))

    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.cache! 'cachekey' do
          json.name 'Miss'
        end
      end
    JSTREAMER
    assert_equal({'name' => 'Cache'}, Wankel.load(json))
  end

  test 'conditionally fragment caching a JSON object' do
    undef_context_methods :cache_fragment_name

    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.cache_if! true, 'cachekey' do
          json.test1 'Cache'
        end
        json.cache_if! false, 'cachekey' do
          json.test2 'Cache'
        end
      end
    JSTREAMER
    assert_equal({'test1' => 'Cache', 'test2' => 'Cache'}, Wankel.load(json))

    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.cache_if! true, 'cachekey' do
          json.test1 'Miss'
        end
        json.cache_if! false, 'cachekey' do
          json.test2 'Miss'
        end
      end
    JSTREAMER
    assert_equal({'test1' => 'Cache', 'test2' => 'Miss'}, Wankel.load(json))
  end

  test 'fragment caching deserializes an array' do
    undef_context_methods :cache_fragment_name

    json = render_jstreamer <<-JSTREAMER
      json.cache! 'cachekey' do
        json.array! %w[a b c]
      end
    JSTREAMER

    # cache miss output correct
    assert_equal(%w[a b c], Wankel.load(json))

    json = render_jstreamer <<-JSTREAMER
      json.cache! 'cachekey' do
        json.array! %w[1 2 3]
      end
    JSTREAMER

    # cache hit output correct
    assert_equal(%w[a b c], Wankel.load(json))
  end

  test 'fragment caching works with current cache digests' do
    @context.expects(:cache_fragment_name).with('cachekey', {})

    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.cache! 'cachekey' do
          json.name 'Cache'
        end
      end
    JSTREAMER

    assert_equal({'name' => 'Cache'}, Wankel.load(json))
  end

  test 'current cache digest option accepts options' do
    @context.expects(:cache_fragment_name).with('cachekey', skip_digest: true)

    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.cache! 'cachekey', skip_digest: true do
          json.name 'Cache'
        end
      end
    JSTREAMER

    assert_equal({'name' => 'Cache'}, Wankel.load(json))
  end

  test 'does not perform caching when controller.perform_caching is false' do
    controller.perform_caching = false

    json = render_jstreamer <<-JSTREAMER
      json.object! do
        json.cache! 'cachekey' do
          json.name 'Cache'
        end
      end
    JSTREAMER

    assert_equal Rails.cache.inspect[/entries=(\d+)/, 1], '0'
    assert_equal({'name' => 'Cache'}, Wankel.load(json))
  end

  test 'renders cached array of block partials' do
    undef_context_methods :cache_fragment_name

    Rails.cache.write("jstreamer/8/post body 8/Pavel Pravosud", '"CACHE HIT"')
    
    json = render_jstreamer <<-JSTREAMER
      json.cache_collection! BLOG_POST_COLLECTION do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JSTREAMER
    
    assert_collection_rendered(json, {7 => 'CACHE HIT'})
  end

  test 'renders cached array with a key specified as a proc' do
    undef_context_methods :cache_fragment_name
    CACHE_KEY_PROC.expects(:call)

    Rails.cache.write("jstreamer/1/post body 1/David Heinemeier Hansson", '"CACHE HIT"')
    
    json = render_jstreamer <<-JSTREAMER
      json.cache_collection! BLOG_POST_COLLECTION, key: CACHE_KEY_PROC do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JSTREAMER

    assert_collection_rendered(json, {0 => 'CACHE HIT'})
  end

  test 'reverts to array! when controller.perform_caching is false' do
    controller.perform_caching = false

    json = render_jstreamer <<-JSTREAMER
      json.cache_collection! BLOG_POST_COLLECTION do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JSTREAMER

    assert_collection_rendered json
  end
  
end
