# JStreamer ![Build Status](https://api.travis-ci.org/malomalo/jstreamer.svg)

JStreamer gives you a simple DSL for generating JSON that beats massaging giant
hash structures. This is particularly helpful when the generation process is
fraught with conditionals and loops.


[Jbuilder](https://github.com/rails/jbuilder) builds a Hash as it renders the
template and once complete converts the Hash to JSON. JStreamer on the other
hand writes directly to the output as it is rendering the template. Because of
this some of the magic cannot be done and requires a little more verboseness.

Examples
--------

``` ruby
# app/views/message/show.json.jstreamer

json.object! do
  json.content format_content(@message.content)
  json.extract! @message, :created_at, :updated_at

  json.author do
    json.object! do
      json.name @message.creator.name.familiar
      json.email_address @message.creator.email_address_with_name
      json.url url_for(@message.creator, format: :json)
    end
  end

  if current_user.admin?
    json.visitors calculate_visitors(@message)
  end
  
  json.tags do
    json.array! do
      @message.tags.each { |tag| json.child! tag }
    end
  end

  json.comments @message.comments, :content, :created_at

  json.attachments @message.attachments do |attachment|
    json.object! do
      json.filename attachment.filename
      json.url url_for(attachment)
    end
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

  "tags": ['public'],
  
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
json.object! do
  json.set! :author do
    json.object! do
      json.set! :name, 'David'
    end
  end
end

# => { "author": { "name": "David" } }
```

Top level arrays can be handled directly.  Useful for index and other collection
actions.

``` ruby
json.array! @comments do |comment|
  next if comment.marked_as_spam_by?(current_user)

  json.object! do
    json.body comment.body
    json.author do
      json.first_name comment.author.first_name
      json.last_name comment.author.last_name
    end
  end
end

# => [ { "body": "great post...", "author": { "first_name": "Joe", "last_name": "Bloe" }} ]
```

You can also extract attributes from array directly.

``` ruby
# @people = People.all

json.array! @people, :id, :name

# => [ { "id": 1, "name": "David" }, { "id": 2, "name": "Jamie" } ]
```

You can either use JStreamer stand-alone or directly as an ActionView template
language. When required in Rails, you can create views ala show.json.jstreamer
(the json is already yielded):

``` ruby
# Any helpers available to views are available to the builder
json.object! do
  json.content format_content(@message.content)
  json.extract! @message, :created_at, :updated_at

  json.author do
    json.object! do
      json.name @message.creator.name.familiar
      json.email_address @message.creator.email_address_with_name
      json.url url_for(@message.creator, format: :json)
    end
  end
  
  if current_user.admin?
    json.visitors calculate_visitors(@message)
  end
end
```

You can use partials as well. The following will render the file
`views/comments/_comments.json.jstreamer`, and set a local variable
`comments` with all this message's comments, which you can use inside
the partial.

```ruby
json.partial! 'comments/comments', comments: @message.comments
```

It's also possible to render collections of partials:

```ruby
json.array! @posts, partial: 'posts/post', as: :post

# or

json.partial! 'posts/post', collection: @posts, as: :post

# or

json.partial! partial: 'posts/post', collection: @posts, as: :post

# or

json.comments @post.comments, partial: 'comment/comment', as: :comment
```

You can explicitly make JStreamer object return null if you want:

``` ruby
json.extract! @post, :id, :title, :content, :published_at
json.author do
  if @post.anonymous?
    json.null! # or json.nil!
  else
    json.object! do
      json.first_name @post.author_first_name
      json.last_name @post.author_last_name
    end
  end
end
```

Fragment caching is supported, it uses `Rails.cache` and works like caching in
HTML templates:

```ruby
json.object! do
  json.cache! ['v1', @person], expires_in: 10.minutes do
    json.extract! @person, :name, :age
  end
end
```

You can also conditionally cache a block by using `cache_if!` like this:

```ruby
json.object! do
  json.cache_if! !admin?, ['v1', @person], expires_in: 10.minutes do
    json.extract! @person, :name, :age
  end
end
```

The only caveat with caching is inside and object you must cache both the key
and the value. You cannot just cache the value. For example:

```ruby
json.boject! do
  json.key do
    json.cache! :key do
    	json.value! 'Cache this.'
    end
  end
end
```

Will error out, but can easily be rewritten as:

```ruby
json.boject! do
  json.cache! :key do
    json.key do
      json.value! 'Cache this.'
    end
  end
end
```

Keys can be auto formatted using `key_format!`, this can be used to convert
keynames from the standard ruby_format to camelCase:

``` ruby
json.key_format! camelize: :lower
json.object! do
  json.first_name 'David'
end

# => { "firstName": "David" }
```

You can set this globally with the class method `key_format` (from inside your
environment.rb for example):

``` ruby
JStreamer.key_format camelize: :lower
```

Syntax Differences from Jbuilder
--------------------------------

- You must open JSON object or array if you want an object or array.
- You can directly output a value with `json.value! value`, this will
  allow you to put a number, string, or other JSON value if you wish
  to not have an object or array.
- The call syntax has been removed (eg. `json.(@person, :name, :age)`)
- Caching inside of a object must cache both the key and the value.

JSON backends
-------------

Currently JStreamer only uses the [Wankel JSON backend](https://github.com/malomalo/wankel),
which supports streaming parsing and encoding.

Special Thanks & Contributors
-----------------------------

JStreamer is a fork of [Jbuilder](https://github.com/rails/jbuilder), built of
what they have accopmlished and with out Jbuilder JStreamer would not be here today.
Thanks to everyone who's been a part of Jbuilder!

* David Heinemeier Hansson - http://david.heinemeierhansson.com/ - for writing Jbuidler!!
* Pavel Pravosud - http://pavel.pravosud.com/ - for maintaing and pushing Jbuilder forward
