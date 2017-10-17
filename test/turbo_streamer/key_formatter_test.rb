require 'test_helper'

class TurboStreamer::KeyFormatterTest < ActiveSupport::TestCase

  test 'initialize via options hash' do
    turbo_streamer = TurboStreamer.new(key_formatter: 1)
    assert_equal 1, turbo_streamer.instance_eval{ @key_formatter }
  end

  test 'key_format! with parameter' do
    result = jbuild do |json|
      json.object! do
        json.key_format! camelize: [:lower]
        json.camel_style 'for JS'
      end
    end

    assert_equal ['camelStyle'], result.keys
  end

  test 'key_format! with parameter not as an array' do
    result = jbuild do |json|
      json.object! do
        json.key_format! camelize: :lower
        json.camel_style 'for JS'
      end
    end

    assert_equal ['camelStyle'], result.keys
  end

  test 'key_format! propagates to child elements' do
    result = jbuild do |json|
      json.object! do
        json.key_format! :upcase
        json.level1 'one'
        json.level2 do
          json.object! do
            json.value 'two'
          end
        end
      end
    end

    assert_equal 'one', result['LEVEL1']
    assert_equal 'two', result['LEVEL2']['VALUE']
  end

  test 'key_format! resets after child element' do
    result = jbuild do |json|
      json.object! do
        json.level2 do
          json.key_format! :upcase
          json.object! { json.value 'two' }
        end
        json.level1 'one'
      end
    end

    assert_equal 'two', result['level2']['VALUE']
    assert_equal 'one', result['level1']
  end

  test 'key_format! with no parameter' do
    result = jbuild do |json|
      json.object! do
        json.key_format! :upcase
        json.lower 'Value'
      end
    end

    assert_equal ['LOWER'], result.keys
  end

  test 'key_format! with multiple steps' do
    result = jbuild do |json|
      json.object! do
        json.key_format! :upcase, :pluralize
        json.pill 'foo'
      end
    end

    assert_equal ['PILLs'], result.keys
  end

  test 'key_format! with lambda/proc' do
    result = jbuild do |json|
      json.object! do
        json.key_format! ->(key){ key + ' and friends' }
        json.oats 'foo'
      end
    end

    assert_equal ['oats and friends'], result.keys
  end

  test 'default key_format!' do
    TurboStreamer.key_format camelize: :lower
    result = jbuild{ |json| json.object! { json.camel_style 'for JS' } }
    assert_equal ['camelStyle'], result.keys
    TurboStreamer.send :class_variable_set, '@@key_formatter', TurboStreamer::KeyFormatter.new
  end

  test 'do not use default key formatter directly' do
    TurboStreamer.key_formatter = TurboStreamer::KeyFormatter.new
    turbo_streamer = TurboStreamer.new
    assert_not_equal TurboStreamer.class_variable_get(:@@key_formatter).object_id, turbo_streamer.object_id
  end

end
