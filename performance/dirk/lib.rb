$LOAD_PATH << File.expand_path('../lib', __FILE__)

require "active_support"
require 'action_view'
require 'action_view/testing/resolvers'


class FakeController
  def perform_caching
    true
  end
  
  def instrument_fragment_cache(a, b)
    yield
  end

end

class FakeContext
  attr_reader :controller

  def initialize
    @controller = FakeController.new
  end
end