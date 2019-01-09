require 'jbuilder'
require 'jbuilder/jbuilder_template'
require 'oj'
require 'multi_json'
MultiJson.use :oj

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

# Fill the cache
JbuilderTemplate.encode FakeContext.new do |json|
  json.cached do
    json.cache! 'jbcached' do
      json.array! 0..100 do |i|
        json.a i
        json.b i
        json.c i
        json.d i
        json.e i

        json.subitems 0..100 do |j|
          json.f i.to_s * j
          json.g i.to_s * j
          json.h i.to_s * j
          json.i i.to_s * j
          json.j i.to_s * j
        end
      end
    end
  end
end

# Everthing before this is run once initially, after is the test
__SETUP__

JbuilderTemplate.encode FakeContext.new do |json|
  json.cached do
    json.cache! 'jbcached' do
      json.array! 0..100 do |i|
        json.a i
        json.b i
        json.c i
        json.d i
        json.e i

        json.subitems 0..100 do |j|
          json.f i.to_s * j
          json.g i.to_s * j
          json.h i.to_s * j
          json.i i.to_s * j
          json.j i.to_s * j
        end
      end
    end
  end
end
