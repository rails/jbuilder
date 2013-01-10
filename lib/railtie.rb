require 'rails/engine'

class Jbuilder
  class Engine < ::Rails::Engine
    config.app_generators.scaffold_controller = :jbuilder_scaffold_controller
    config.app_generators.json_template_engine = :jbuilder
  end
end