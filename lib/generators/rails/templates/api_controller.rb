<% if namespaced? -%>
require_dependency "<%= namespaced_path %>/application_controller"

<% end -%>
<% module_namespacing do -%>
class <%= controller_class_name %>Controller < ApplicationController
  before_action :set_<%= singular_table_name %>, only: %i[ show update destroy ]

  # GET <%= route_url %>
  # GET <%= route_url %>.json
  def index
    @<%= plural_table_name %> = <%= orm_class.all(class_name) %>
  end

  # GET <%= route_url %>/1
  # GET <%= route_url %>/1.json
  def show
  end

  # POST <%= route_url %>
  # POST <%= route_url %>.json
  def create
    @<%= singular_table_name %> = <%= orm_class.build(class_name, "#{singular_table_name}_params") %>

    if @<%= orm_instance.save %>
      render :show, status: :created, location: <%= "@#{singular_table_name}" %>
    else
      render json: <%= "@#{orm_instance.errors}" %>, status: :unprocessable_entity
    end
  end

  # PATCH/PUT <%= route_url %>/1
  # PATCH/PUT <%= route_url %>/1.json
  def update
    if @<%= orm_instance.update("#{singular_table_name}_params") %>
      render :show, status: :ok, location: <%= "@#{singular_table_name}" %>
    else
      render json: <%= "@#{orm_instance.errors}" %>, status: :unprocessable_entity
    end
  end

  # DELETE <%= route_url %>/1
  # DELETE <%= route_url %>/1.json
  def destroy
    @<%= orm_instance.destroy %>
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_<%= singular_table_name %>
      @<%= singular_table_name %> = <%= orm_class.find(class_name, "params[:id]") %>
    end

    # Only allow a list of trusted parameters through.
    def <%= "#{singular_table_name}_params" %>
      <%- if attributes_names.empty? -%>
      params.fetch(<%= ":#{singular_table_name}" %>, {})
      <%- else -%>
      params.require(<%= ":#{singular_table_name}" %>).permit(<%= permitted_params %>)
      <%- end -%>
    end
end
<% end -%>
