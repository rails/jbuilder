require 'jbuilder'
require 'oj'
require 'multi_json'
MultiJson.use :oj

__SETUP__

Jbuilder.encode do |json|
  json.article do
    json.author($author, :name, :birthyear, :bio)
    json.title "Profiling Jbuilder"
    json.body "How to profile Jbuilder"
    json.date $now
    json.references $arr do |ref|
      json.name "Introduction to profiling"
      json.url "http://example.com/"
    end
    json.comments $arr do |comment|
      json.author($author, :name, :birthyear, :bio)
      json.email "rolf@example.com"
      json.body "Great article"
      json.date $now
    end
  end
end
