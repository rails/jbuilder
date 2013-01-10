require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'

module Rails
  module Generators
    class JbuilderScaffoldControllerGenerator < ScaffoldControllerGenerator
      source_root File.expand_path('../templates', __FILE__)

      hook_for :json_template_engine, as: :scaffold
    end
  end
end