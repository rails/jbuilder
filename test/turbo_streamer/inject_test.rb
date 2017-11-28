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

  test 'support inject! method in a block with a string with multiple keys' do
    result = jbuild do |json|
      json.object! do
        json.author do
          json.object! do
            json.attr1 "value1"
            json.inject! '"name":"Pavel","age":30'
            json.attr2 "value2"
          end
        end
      end
    end

    assert_equal 'Pavel', result['author']['name']
    assert_equal 30, result['author']['age']
    assert_equal 'value1', result['author']['attr1']
    assert_equal 'value2', result['author']['attr2']
  end

end
