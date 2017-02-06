json.partial! "<%= plural_table_name.gsub('_', '/') %>/<%= singular_table_name %>", <%= singular_table_name %>: @<%= singular_table_name %>
