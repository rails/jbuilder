require 'rails/generators/test_case'
require 'generators/rails/jbuilder_scaffold_controller_generator'

class JbuilderScaffoldControllerGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::JbuilderScaffoldControllerGenerator
  arguments %w(Post title body:text)
  destination File.expand_path('../tmp', File.dirname(__FILE__))
  setup :prepare_destination

  test 'controller content' do
    run_generator

    assert_file 'app/controllers/posts_controller.rb' do |content|
      assert_instance_method :index, content do |m|
        assert_match /@posts = Post\.all/, m
      end

      assert_instance_method :show, content do |m|
        assert m.blank?
      end

      assert_instance_method :new, content do |m|
        assert_match /@post = Post\.new/, m
      end

      assert_instance_method :edit, content do |m|
        assert m.blank?
      end

      assert_instance_method :create, content do |m|
        assert_match /@post = Post\.new\(post_params\)/, m
        assert_match /@post\.save/, m
        assert_match /format\.html \{ redirect_to @post, notice: 'Post was successfully created\.' \}/, m
        assert_match /format\.json \{ render action: 'show', status: :created, location: @post \}/, m
        assert_match /format\.html \{ render action: 'new' \}/, m
        assert_match /format\.json \{ render json: @post\.errors, status: :unprocessable_entity \}/, m
      end

      assert_instance_method :update, content do |m|
        assert_match /format\.html \{ redirect_to @post, notice: 'Post was successfully updated\.' \}/, m
        assert_match /format\.json \{ head :no_content \}/, m
        assert_match /format\.html \{ render action: 'edit' \}/, m
        assert_match /format\.json \{ render json: @post.errors, status: :unprocessable_entity \}/, m
      end

      assert_instance_method :destroy, content do |m|
        assert_match /@post\.destroy/, m
        assert_match /format\.html { redirect_to posts_url \}/, m
        assert_match /format\.json \{ head :no_content \}/, m
      end

      assert_match(/def post_params/, content)
      assert_match(/params\.require\(:post\)\.permit\(:title, :body\)/, content)
    end
  end
end