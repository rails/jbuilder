require 'oj'
require 'rabl'

__SETUP__

Rabl.render(
  nil,
  "template",
  view_path: File.expand_path("../performance/rolftimmermans/rabl/views/", __FILE__),
  format: :json,
)
