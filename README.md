Jbuilder
========

Jbuilder gives you a simple DSL for declaring JSON structures that beats massaging giant hash structures. This is particularly helpful when the generation process is fraught with conditionals and loops. Here's a simple example:

``` ruby
Jbuilder.encode do |json|
  json.content format_content(@message.content)
  json.(@message, :created_at, :updated_at)

  json.author do |json|
    json.name @message.creator.name.familiar
    json.email_address @message.creator.email_address_with_name
    json.url url_for(@message.creator, format: :json)
  end

  if current_user.admin?
    json.visitors calculate_visitors(@message)
  end

  json.comments @message.comments, :content, :created_at
  
  json.attachments @message.attachments do |json, attachment|
    json.filename attachment.filename
    json.url url_for(attachment)
  end
end
```

This will build the following structure:

``` javascript
{ 
  "content": "<p>This is <i>serious</i> monkey business",
  "created_at": "2011-10-29T20:45:28-05:00",
  "updated_at": "2011-10-29T20:45:28-05:00",

  "author": {
    "name": "David H.",
    "email_address": "'David Heinemeier Hansson' <david@heinemeierhansson.com>",
    "url": "http://example.com/users/1-david.json"
  },

  "visitors": 15,

  "comments": [
    { "content": "Hello everyone!", "created_at": "2011-10-29T20:45:28-05:00" },
    { "content": "To you my good sir!", "created_at": "2011-10-29T20:47:28-05:00" }
  ],
  
  "attachment": [
    { "filename": "forecast.xls", "url": "http://example.com/downloads/forecast.xls" },
    { "filename": "presentation.pdf", "url": "http://example.com/downloads/presentation.pdf" }
  ]
}
```

You can either use Jbuilder stand-alone or directly as an ActionView template language. When required in Rails, you can create views ala show.json.jbuilder (the json is already yielded):

``` ruby
# Any helpers available to views are available to the builder
json.content format_content(@message.content)
json.(@message, :created_at, :updated_at)

json.author do |json|
  json.name @message.creator.name.familiar
  json.email_address @message.creator.email_address_with_name
  json.url url_for(@message.creator, format: :json)
end

if current_user.admin?
  json.visitors calculate_visitors(@message)
end

# You can use partials as well, just remember to pass in the json instance
json.partial! "api/comments/comments", @message.comments
```

Libraries similar to this in some form or another includes:

* RABL: https://github.com/nesquena/rabl
* JsonBuilder: https://github.com/nov/jsonbuilder
* JSON Builder: https://github.com/dewski/json_builder
* Jsonify: https://github.com/bsiggelkow/jsonify
* RepresentationView: https://github.com/mdub/representative_view

Compatibility Notes
===================

Jbuilder works best with Ruby 1.9.  It does not work so well with Ruby 1.8.

Jbuilder leverages "block local variables" found in Ruby 1.9.  So when you 
write code like:

``` ruby
json.author do |json|
  # notice json variable in here
  json.name @message.creator.name.familiar
end
```

The issue is that the "inner" json in the block overwrites the parent and 
causes issues to appear quite strange.
