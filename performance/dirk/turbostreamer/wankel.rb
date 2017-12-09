require 'turbostreamer'
require 'turbostreamer/handler'
require 'turbostreamer/template'
TurboStreamer.set_default_encoder(:json, :wankel)

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

# Fill the cache
TurboStreamer::Template.encode FakeContext.new do |json|
  json.object! do
    json.cache! 'tscached' do
      json.cached do
        json.array! 0..100 do |i|
          json.object! do
            json.a i
            json.b i
            json.c i
            json.d i
            json.e i

            json.subitems 0..100 do |j|
              json.object! do
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
    end
  end
end

# Everthing before this is run once initialy, after is the test
__SETUP__

TurboStreamer::Template.encode FakeContext.new do |json|
  json.object! do
    json.cache! 'tscached' do
      json.cached do
        json.array! 0..100 do |i|
          json.object! do
            json.a i
            json.b i
            json.c i
            json.d i
            json.e i

            json.subitems 0..100 do |j|
              json.object! do
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
    end
  end
end