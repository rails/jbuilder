require "action_controller"
require "action_controller/railtie"
require "action_view"
require "jbuilder/railtie"
require "rails"

class JbuilderRailtieTest < ActiveSupport::TestCase
  if Rails::VERSION::MAJOR >= 5
    test 'ActionView::Rendering is included in ActionController::API after initialization' do
      assert_equal false, ActionController::API.include?(ActionView::Rendering)

      Jbuilder::Railtie.run_initializers
      
      assert_equal true, ActionController::API.include?(ActionView::Rendering)
    end
  end
end
