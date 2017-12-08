require 'turbostreamer'
TurboStreamer.set_default_encoder(:json, :oj)

__SETUP__

TurboStreamer.encode(encoder: :oj) do |json|
  json.object! do
    json.article do
      json.object! do
        json.author do
          json.object! do
            json.extract!($author, :name, :birthyear, :bio)
          end
        end
        json.title "Profiling Jbuilder"
        json.body "How to profile Jbuilder"
        json.date $now
        json.references $arr do |ref|
          json.object! do
            json.name "Introduction to profiling"
            json.url "http://example.com/"
          end
        end
        json.comments $arr do |comment|
          json.object! do
            json.author($author, :name, :birthyear, :bio)
            json.email "rolf@example.com"
            json.body "Great article"
            json.date $now
          end
        end
      end
    end
  end
end