require 'test_helper'

class TurboStreamer::InjectTest < ActiveSupport::TestCase

  test 'support inject! method' do
    result = jbuild do |json|
      json.inject! '{"foo":"bar"}'
    end

    assert_equal({'foo' => 'bar'}, result)
  end

  test 'support inject! method in a block' do
    result = jbuild do |json|
      json.object! do
        json.author do
          json.object! do
            json.inject! '"name":"Pavel"'
          end
        end
      end
    end

    assert_equal 'Pavel', result['author']['name']
  end

end
