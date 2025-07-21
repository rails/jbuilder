# frozen_string_literal: true

class Jbuilder::DependencyTracker
  EXPLICIT_DEPENDENCY = /# Template Dependency: (\S+)/

  # Matches:
  #   json.partial! "messages/message"
  #   json.partial!('messages/message')
  #
  DIRECT_RENDERS = /
        \w+\.partial!     # json.partial!
        \(?\s*            # optional parenthesis
        (['"])([^'"]+)\1  # quoted value
      /x

  # Matches:
  #   json.partial! partial: "comments/comment"
  #   json.comments @post.comments, partial: "comments/comment", as: :comment
  #   json.array! @posts, partial: "posts/post", as: :post
  #   = render partial: "account"
  #
  INDIRECT_RENDERS = /
        (?::partial\s*=>|partial:)  # partial: or :partial =>
        \s*                         # optional whitespace
        (['"])([^'"]+)\1            # quoted value
      /x

  def self.call(name, template, view_paths = nil)
    new(name, template, view_paths).dependencies
  end

  def initialize(name, template, view_paths = nil)
    @name, @template, @view_paths = name, template, view_paths
  end

  def dependencies
    direct_dependencies + indirect_dependencies + explicit_dependencies
  end

  private

  attr_reader :name, :template

  def direct_dependencies
    source.scan(DIRECT_RENDERS).map(&:second)
  end

  def indirect_dependencies
    source.scan(INDIRECT_RENDERS).map(&:second)
  end

  def explicit_dependencies
    dependencies = source.scan(EXPLICIT_DEPENDENCY).flatten.uniq

    wildcards, explicits = dependencies.partition { |dependency| dependency.end_with?("/*") }

    (explicits + resolve_directories(wildcards)).uniq
  end

  def resolve_directories(wildcard_dependencies)
    return [] unless @view_paths
    return [] if wildcard_dependencies.empty?

    # Remove trailing "/*"
    prefixes = wildcard_dependencies.map { |query| query[0..-3] }

    @view_paths.flat_map(&:all_template_paths).uniq.filter_map { |path|
      path.to_s if prefixes.include?(path.prefix)
    }.sort
  end

  def source
    template.source
  end
end
