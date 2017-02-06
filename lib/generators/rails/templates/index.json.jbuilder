json.array! @<%= plural_table_name %>, partial: '<%= plural_table_name.gsub('_', '/') %>/<%= singular_table_name %>', as: :<%= singular_table_name %>
