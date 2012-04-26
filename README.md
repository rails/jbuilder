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
  
  "attachments": [
    { "filename": "forecast.xls", "url": "http://example.com/downloads/forecast.xls" },
    { "filename": "presentation.pdf", "url": "http://example.com/downloads/presentation.pdf" }
  ]
}
```

Top level arrays can be handled directly.  Useful for index and other collection actions.

``` ruby
# @people = People.all
json.array!(@people) do |json, person|
  json.name person.name
  json.age calculate_age(person.birthday)
end
# => [ { "name": David", "age": 32 }, { "name": Jamie", "age": 31 } ]
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

# You can use partials as well. The following line will render the file
# RAILS_ROOT/app/views/api/comments/_comments, and set a local variable
# 'comments' with all this message's comments, which you can use inside
# the partial.
json.partial! "api/comments/comments", comments: @message.comments
```

You can configure Jbuilder to not serialize nil values.  By default nil values will be serialized to javascript null.

``` ruby
# You can set the default behavior of all Jbuilder instances to not serialize nil
Jbuilder.serialize_nil false

json.author do |json|
  json.name nil
  json.age 32
end
# => { author: {"age": 32 } }

# Or you can set the behavior per instance
json.author do |json|
  json.serialize_nil! false
  json.name nil
  json.age 32
end
# => { author: {"age": 32 } }
```

Libraries similar to this in some form or another include:

* RABL: https://github.com/nesquena/rabl
* JsonBuilder: https://github.com/nov/jsonbuilder
* JSON Builder: https://github.com/dewski/json_builder
* Jsonify: https://github.com/bsiggelkow/jsonify
* RepresentationView: https://github.com/mdub/representative_view