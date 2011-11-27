Json Builder
============

Json builder gives you a simple DSL for declaring JSON structures that beats massaging giant hash structures. This is particularly helpful when the generation process is fraught with conditionals and loops. Here's a simple example:

JsonBuilder.encode do |json|
  json.content format_content(@message.content)
  json.extract! @message, :created_at, :updated_at
  
  json.author do |json|
    json.name @message.creator.name.familiar
    json.email_address @message.creator.email_address_with_name
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
      "email_address": "'David Heinemeier Hansson' <david@heinemeierhansson.com>"
    },
    
    "visitors": 15,
    
    "comments": [
      { "content": "Hello everyone!", "created_at": "2011-10-29T20:45:28-05:00" },
      { "content": "To you my good sir!", "created_at": "2011-10-29T20:47:28-05:00" }
    ]
  }

You can either use JsonBuilder stand-alone or directly as an ActionView template language. When required in Rails, you can create views ala show.json.jbuilder (the json is already yielded):

# Any helpers available to views are available to the builder
json.content format_content(@message.content)
json.extract! @message, :created_at, :updated_at

json.author do |json|
  json.name @message.creator.name.familiar
  json.email_address @message.creator.email_address_with_name
end

if current_user.admin?
  json.visitors calculate_visitors(@message)
end

# You can use partials as well, just remember to pass in the json instance
render @message.comments, json: json