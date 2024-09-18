require 'test_helper'
require 'rails/generators/test_case'
require 'generators/rails/scaffold_controller_generator'

class ScaffoldControllerGeneratorTest < Rails::Generators::TestCase
  tests Rails::Generators::ScaffoldControllerGenerator
  arguments %w(Post title body:text images:attachments --skip-routes)
  destination File.expand_path('../tmp', __FILE__)
  setup :prepare_destination

  test 'controller content' do
    run_generator

    assert_file 'app/controllers/posts_controller.rb' do |content|
      assert_instance_method :index, content do |m|
        assert_match %r{@posts = Post\.all}, m
      end

      assert_instance_method :show, content do |m|
        assert m.blank?
      end

      assert_instance_method :new, content do |m|
        assert_match %r{@post = Post\.new}, m
      end

      assert_instance_method :edit, content do |m|
        assert m.blank?
      end

      assert_instance_method :create, content do |m|
        assert_match %r{@post = Post\.new\(post_params\)}, m
        assert_match %r{@post\.save}, m
        assert_match %r{format\.html \{ redirect_to @post, notice: "Post was successfully created\." \}}, m
        assert_match %r{format\.json \{ render :show, status: :created, location: @post \}}, m
        assert_match %r{format\.html \{ render :new, status: :unprocessable_entity \}}, m
        assert_match %r{format\.json \{ render json: @post\.errors, status: :unprocessable_entity \}}, m
      end

      assert_instance_method :update, content do |m|
        assert_match %r{format\.html \{ redirect_to @post, notice: "Post was successfully updated\.", status: :see_other \}}, m
        assert_match %r{format\.json \{ render :show, status: :ok, location: @post \}}, m
        assert_match %r{format\.html \{ render :edit, status: :unprocessable_entity \}}, m
        assert_match %r{format\.json \{ render json: @post.errors, status: :unprocessable_entity \}}, m
      end

      assert_instance_method :destroy, content do |m|
        assert_match %r{@post\.destroy}, m
        assert_match %r{format\.html \{ redirect_to posts_path, notice: "Post was successfully destroyed\.", status: :see_other \}}, m
        assert_match %r{format\.json \{ head :no_content \}}, m
      end

      assert_match %r{def set_post}, content
      if Rails::VERSION::MAJOR >= 8
        assert_match %r{params\.expect\(:id\)}, content
      else
        assert_match %r{params\[:id\]}, content
      end

      assert_match %r{def post_params}, content
      if Rails::VERSION::MAJOR >= 8
        assert_match %r{params\.expect\(post: \[ :title, :body, images: \[\] \]\)}, content
      else
        assert_match %r{params\.require\(:post\)\.permit\(:title, :body, images: \[\]\)}, content
      end
    end
  end

  test 'controller with namespace' do
    run_generator %w(Admin::Post --model-name=Post --skip-routes)
    assert_file 'app/controllers/admin/posts_controller.rb' do |content|
      assert_instance_method :create, content do |m|
        assert_match %r{format\.html \{ redirect_to \[:admin, @post\], notice: "Post was successfully created\." \}}, m
      end

      assert_instance_method :update, content do |m|
        assert_match %r{format\.html \{ redirect_to \[:admin, @post\], notice: "Post was successfully updated\.", status: :see_other \}}, m
      end

      assert_instance_method :destroy, content do |m|
        assert_match %r{format\.html \{ redirect_to admin_posts_path, notice: "Post was successfully destroyed\.", status: :see_other \}}, m
      end
    end
  end

  test "don't use require and permit if there are no attributes" do
    run_generator %w(Post --skip-routes)

    assert_file 'app/controllers/posts_controller.rb' do |content|
      assert_match %r{def post_params}, content
      assert_match %r{params\.fetch\(:post, \{\}\)}, content
    end
  end

  test 'handles virtual attributes' do
    run_generator %w(Message content:rich_text video:attachment photos:attachments --skip-routes)

    assert_file 'app/controllers/messages_controller.rb' do |content|
      if Rails::VERSION::MAJOR >= 8
        assert_match %r{params\.expect\(message: \[ :content, :video, photos: \[\] \]\)}, content
      else
        assert_match %r{params\.require\(:message\)\.permit\(:content, :video, photos: \[\]\)}, content
      end
    end
  end
end
