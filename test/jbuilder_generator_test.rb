require 'rails/generators/test_case'
require 'generators/rails/jbuilder_generator'

class JbuilderGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::JbuilderGenerator
  arguments %w(Post title body:text)
  destination File.expand_path('../tmp', File.dirname(__FILE__))
  setup :prepare_destination

  test 'views are generated' do
    run_generator

    %w(index show).each do |view|
      assert_file "app/views/posts/#{view}.json.jbuilder"
    end
  end

  test 'index content' do
    run_generator

    assert_file 'app/views/posts/index.json.jbuilder' do |content|
      assert_match /json\.array!\(@posts\) do \|post\|/, content
      assert_match /json\.extract! post, :title, :body, :created_at, :updated_at/, content
      assert_match /json\.url post_url\(post\)/, content
    end

    assert_file 'app/views/posts/show.json.jbuilder' do |content|
      assert_match /json\.extract! @post, :title, :body, :created_at, :updated_at/, content
      assert_match /json\.url post_url\(@post\)/, content
    end
  end
end