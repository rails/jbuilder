Jbuilder [![Build Status](https://travis-ci.org/rails/jbuilder.png)](https://travis-ci.org/rails/jbuilder) [![Gem Version](https://badge.fury.io/rb/jbuilder.png)](https://rubygems.org/gems/jbuilder) [![Code Climate](https://codeclimate.com/github/rails/jbuilder.png)](https://codeclimate.com/github/rails/jbuilder)
========

Jbuilder gives you a simple DSL for declaring JSON structures that beats massaging giant hash structures. This is particularly helpful when the generation process is fraught with conditionals and loops. Here's a simple example:

``` ruby
Jbuilder.encode do |json|
  json.content format_content(@message.content)
  json.(@message, :created_at, :updated_at)

  json.author do
    json.name @message.creator.name.familiar
    json.email_address @message.creator.email_address_with_name
    json.url url_for(@message.creator, format: :json)
  end

  if current_user.admin?
    json.visitors calculate_visitors(@message)
  end

  json.comments @message.comments, :content, :created_at

  json.attachments @message.attachments do |attachment|
    json.filename attachment.filename
    json.url url_for(attachment)
  end
end
```

This will build the following structure:

``` javascript
{
  "content": "<p>This is <i>serious</i> monkey business</p>",
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

To define attribute and structure names dynamically, use the `set!` method:

``` ruby
json.set! :author do
  json.set! :name, 'David'
end

# => "author": { "name": "David" }
```

Top level arrays can be handled directly.  Useful for index and other collection actions.

``` ruby
# @people = People.all
json.array! @people do |person|
  json.name person.name
  json.age calculate_age(person.birthday)
end

# => [ { "name": "David", "age": 32 }, { "name": "Jamie", "age": 31 } ]
```

You can also extract attributes from array directly.

``` ruby
# @people = People.all
json.array! @people, :id, :name

# => [ { "id": 1, "name": "David" }, { "id": 2, "name": "Jamie" } ]
```


Jbuilder objects can be directly nested inside each other.  Useful for composing objects.

``` ruby
class Person
  # ... Class Definition ... #
  def to_builder
    Jbuilder.new do |person|
      person.(self, :name, :age)
    end
  end
end

class Company
  # ... Class Definition ... #
  def to_builder
    Jbuilder.new do |company|
      company.name name
      company.president president.to_builder
    end
  end
end

company = Company.new('Doodle Corp', Person.new('John Stobs', 58))
company.to_builder.target!

# => {"name":"Doodle Corp","president":{"name":"John Stobs","age":58}}
```

You can either use Jbuilder stand-alone or directly as an ActionView template language. When required in Rails, you can create views ala show.json.jbuilder (the json is already yielded):

``` ruby
# Any helpers available to views are available to the builder
json.content format_content(@message.content)
json.(@message, :created_at, :updated_at)

json.author do
  json.name @message.creator.name.familiar
  json.email_address @message.creator.email_address_with_name
  json.url url_for(@message.creator, format: :json)
end

if current_user.admin?
  json.visitors calculate_visitors(@message)
end

# You can use partials as well. The following line will render the file
# RAILS_ROOT/app/views/api/comments/_comments.json.jbuilder, and set a local variable
# 'comments' with all this message's comments, which you can use inside
# the partial.
json.partial! 'api/comments/comments', comments: @message.comments
```

You can explicitly make Jbuilder object return null if you want:

``` ruby
json.extract! @post, :id, :title, :content, :published_at
json.author do
  if @post.anonymous?
    json.null! # or json.nil!
  else
    json.first_name @post.author_first_name
    json.last_name @post.author_last_name
  end
end
```

Keys can be auto formatted using `key_format!`, this can be used to convert keynames from the standard ruby_format to CamelCase:

``` ruby
json.key_format! :camelize => :lower
json.first_name 'David'

# => { "firstName": "David" }
```

You can set this globally with the class method `key_format` (from inside your environment.rb for example):

``` ruby
Jbuilder.key_format :camelize => :lower
```

Libraries similar to this in some form or another include:

* RABL: https://github.com/nesquena/rabl
* JsonBuilder: https://github.com/nov/jsonbuilder
* JSON Builder: https://github.com/dewski/json_builder
* Jsonify: https://github.com/bsiggelkow/jsonify
* RepresentationView: https://github.com/mdub/representative_view
