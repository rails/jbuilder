require 'rails/railtie'

class Jbuilder
  class Railtie < ::Rails::Railtie
    generators do |app|
      Rails::Generators.configure! app.config.generators
      Rails::Generators.hidden_namespaces.uniq!
      require 'generators/rails/scaffold_controller_generator'
    end
  end
end