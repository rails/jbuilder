require 'test_helper'
require 'jbuilder/jbuilder_dependency_tracker'

class FakeTemplate
    attr_reader :source, :handler
    def initialize(source, handler = :jbuilder)
      @source, @handler = source, handler
    end
end

FakeResolvedPath = Struct.new(:prefix, :virtual_path) do
    def to_s
      virtual_path
    end
end

class FakeViewPath
    def initialize(*template_paths)
      @template_paths = template_paths
    end

    def all_template_paths
      @template_paths
    end
end


class JbuilderDependencyTrackerTest < ActiveSupport::TestCase
    def make_tracker(name, source)
      template = FakeTemplate.new(source)
      Jbuilder::DependencyTracker.new(name, template)
    end

    def track_dependencies(source)
      make_tracker('jbuilder_template', source).dependencies
    end

    test 'detects dependency via direct partial! call' do
      dependencies = track_dependencies <<-RUBY
        json.partial! 'path/to/partial', foo: bar
        json.partial! 'path/to/another/partial', :fizz => buzz
      RUBY

      assert_equal %w[path/to/partial path/to/another/partial], dependencies
    end

    test 'detects dependency via direct partial! call with parens' do
      dependencies = track_dependencies <<-RUBY
        json.partial!("path/to/partial")
      RUBY

      assert_equal %w[path/to/partial], dependencies
    end

    test 'detects partial with options (1.9 style)' do
      dependencies = track_dependencies <<-RUBY
        json.partial! hello: 'world', partial: 'path/to/partial', foo: :bar
      RUBY

      assert_equal %w[path/to/partial], dependencies
    end

    test 'detects partial with options (1.8 style)' do
      dependencies = track_dependencies <<-RUBY
        json.partial! :hello => 'world', :partial => 'path/to/partial', :foo => :bar
      RUBY

      assert_equal %w[path/to/partial], dependencies
    end

    test 'detects partial in indirect collection calls' do
      dependencies = track_dependencies <<-RUBY
        json.comments @post.comments, partial: 'comments/comment', as: :comment
      RUBY

      assert_equal %w[comments/comment], dependencies
    end

    test 'detects explicit dependency' do
      dependencies = track_dependencies <<-RUBY
        # Template Dependency: path/to/partial
        json.foo 'bar'
      RUBY

      assert_equal %w[path/to/partial], dependencies
    end

    test 'is registered as the dependency tracker for the :jbuilder handler' do
      handler = ActionView::Template.handler_for_extension(:jbuilder)
      template = FakeTemplate.new("json.partial! 'path/to/partial'", handler)

      dependencies = ActionView::DependencyTracker.find_dependencies('jbuilder_template', template, [])

      assert_equal %w[path/to/partial], dependencies
    end

    test 'receives the view paths so wildcard dependencies resolve' do
      handler = ActionView::Template.handler_for_extension(:jbuilder)
      template = FakeTemplate.new('# Template Dependency: comments/*', handler)
      view_paths = [ FakeViewPath.new(FakeResolvedPath.new('comments', 'comments/_comment')) ]

      dependencies = ActionView::DependencyTracker.find_dependencies('jbuilder_template', template, view_paths)

      assert_equal %w[comments/_comment], dependencies
    end
end
