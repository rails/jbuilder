Jbuilder
============

Jbuilder gives you a simple DSL for declaring JSON structures that beats massaging giant hash structures. This is particularly helpful when the generation process is fraught with conditionals and loops. Here's a simple example:

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
    end

This will build the following structure:

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
      ]
    }

You can either use Jbuilder stand-alone or directly as an ActionView template language. When required in Rails, you can create views ala show.json.jbuilder (the json is already yielded):

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
    render @message.comments, json: json

Note: This is similar to Garrett Bjerkhoel's json_builder, which I discovered after making this, but the DSL has taken a different turn and will retain the explicit yield style (vs json_builder's 3.0's move to instance_eval).