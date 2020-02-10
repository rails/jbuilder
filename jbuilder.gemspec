Gem::Specification.new do |s|
  s.name     = 'jbuilder'
  s.version  = '2.10.0'
  s.authors  = 'David Heinemeier Hansson'
  s.email    = 'david@basecamp.com'
  s.summary  = 'Create JSON structures via a Builder-style DSL'
  s.homepage = 'https://github.com/rails/jbuilder'
  s.license  = 'MIT'

  s.required_ruby_version = '>= 2.2.2'

  s.add_dependency 'activesupport', '>= 5.0.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
end
