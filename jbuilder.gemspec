Gem::Specification.new do |s|
  s.name     = 'jbuilder'
  s.version  = '2.0.8'
  s.authors  = ['David Heinemeier Hansson', 'Pavel Pravosud']
  s.email    = ['david@37signals.com', 'pavel@pravosud.com']
  s.summary  = 'Create JSON structures via a Builder-style DSL'
  s.homepage = 'https://github.com/rails/jbuilder'
  s.license  = 'MIT'

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'activesupport', '>= 3.0.0', '< 5'
  s.add_dependency 'multi_json',    '~> 1.2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
end
