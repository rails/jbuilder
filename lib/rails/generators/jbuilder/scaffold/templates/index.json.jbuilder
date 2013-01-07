json.array!(@<% plural_table_name %>) do |<%= singular_table_name %>|
  json.extract! <%= singular_table_name %>, <%= attributes.map{ |a| ":#{a.name}" } * ', ' %>
end