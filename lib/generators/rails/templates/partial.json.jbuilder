json.extract! <%= singular_table_name %>, <%= attributes_list_with_timestamps %>
json.url <%= singular_table_name %>_url(<%= singular_table_name %>, format: :json)
