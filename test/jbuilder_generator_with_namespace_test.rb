require 'test_helper'
require 'rails/generators/test_case'
require 'generators/rails/jbuilder_generator'

class JbuilderGeneratorWithNamespaceTest < Rails::Generators::TestCase
  tests Rails::Generators::JbuilderGenerator
  arguments %w(api/foo bar:integer baz:string)
  destination File.expand_path('../tmp', __FILE__)
  setup :prepare_destination

  test 'all views are generated' do
    run_generator

    %w(index show).each do |view|
      assert_file "app/views/api/foos/#{view}.json.jbuilder"
    end
    assert_file "app/views/api/foos/_api_foo.json.jbuilder"
  end

  test 'the files are correctly structured to work' do
    run_generator

    assert_file 'app/views/api/foos/index.json.jbuilder' do |content|
      assert_match %r{json.array! @api_foos, partial: 'api/foos/api_foo', as: :api_foo}, content
    end

    assert_file 'app/views/api/foos/show.json.jbuilder' do |content|
      assert_match %r{json.partial! \"api/foos/api_foo\", api_foo: @api_foo}, content
    end
    
    assert_file 'app/views/api/foos/_api_foo.json.jbuilder' do |content|            
      assert_match %r{json\.extract! api_foo, :id, :bar, :baz, :created_at, :updated_at}, content
      assert_match %r{json\.url api_foo_url\(api_foo, format: :json\)}, content
    end
    

  end
end
