require 'rails/generators/named_base'
require 'rails/generators/resource_helpers'

class Jbuilder
  module Generators
    class ScaffoldGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __FILE__)
      include Rails::Generators::ResourceHelpers

      def create_root_folder
        empty_directory File.join('app/views', controller_file_path)
      end

      def copy_view_files
        %w(index show).each do |name|
          filename = filename_with_extensions(name)
          template filename, File.join('app/views', controller_file_path, filename)
        end
      end

      def filename_with_extensions(name)
        [name, :json, :jbuilder]  * '.'
      end
    end
  end
end