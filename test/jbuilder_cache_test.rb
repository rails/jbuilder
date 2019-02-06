require "test_helper"
require "jbuilder"
require "jbuilder/cache"

class JbuilderCacheTest < ActiveSupport::TestCase
  setup do
    Rails.cache.clear
  end

  test "resolve flat" do
    cache = Jbuilder::Cache.new
    cache.add("x", {}) { "x" }
    cache.add("y", {}) { [ "y" ] }
    cache.add("z", {}) { { key: "value" } }

    assert_equal(["x", ["y"], { key: "value" }], cache.resolve)
  end

  test "resolve nested" do
    cache = Jbuilder::Cache.new
    cache.add("x", {}) do
      cache.add("y", {}) do
        cache.add("z", {}) do
          { key: "value" }
        end

        ["y"]
      end

      "x"
    end

    assert_equal(["x", ["y"], { key: "value" }], cache.resolve)
  end

  test "cache calls" do
    3.times do
      cache = Jbuilder::Cache.new
      cache.add("x", {}) { "x" }
      cache.add("y", {}) { [ "y" ] }
      cache.add("z", { expires_in: 10.minutes }) { { key: "value" } }
      cache.resolve
    end

    # cache miss:
    #
    #   1. x + y
    #   2. z
    #
    # cache hit:
    #
    #   3. x + y
    #   4. z
    #   5. x + y
    #   6. z
    assert_equal 6, Rails.cache.fetch_multi_calls.length

    # cache miss:
    #
    #   1. x
    #   2. y
    #   2. z
    assert_equal 3, Rails.cache.write_calls.length
  end

  test "nested cache calls" do
    3.times do
      cache = Jbuilder::Cache.new
      cache.add("x", {}) do
        cache.add("y", {}) do
          cache.add("z", {}) do
            { key: "value" }
          end

          ["y"]
        end

        "x"
      end
      cache.resolve
    end

    # cache miss:
    #
    #   1. x
    #   2. y
    #   3. z
    #
    # cache hit:
    #
    #   4. x + y + z
    #   5. x + y + z
    assert_equal 5, Rails.cache.fetch_multi_calls.length

    # cache miss:
    #
    #   1. x
    #   2. y
    #   2. z
    assert_equal 3, Rails.cache.write_calls.length
  end

  test "different options" do
    3.times do
      cache = Jbuilder::Cache.new
      cache.add("x", {}) { "x" }
      cache.add("y", {}) { [ "y" ] }
      cache.add("z", { expires_in: 10.minutes }) { { key: "value" } }
      cache.resolve
    end

    # cache miss:
    #
    #   1. x + y
    #   2. z
    #
    # cache hit:
    #
    #   3. x + y
    #   4. z
    #   5. x + y
    #   6. z
    assert_equal 6, Rails.cache.fetch_multi_calls.length

    # cache miss:
    #
    #   1. x
    #   2. y
    #   2. z
    assert_equal 3, Rails.cache.write_calls.length
  end
end
