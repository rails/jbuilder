Gem::Specification.new do |s|
  s.name    = 'jbuilder'
  s.version = '1.0.2'
  s.author  = 'David Heinemeier Hansson'
  s.email   = 'david@37signals.com'
  s.summary = 'Create JSON structures via a Builder-style DSL'
  s.license = 'MIT'

  s.add_dependency 'activesupport', '>= 3.0.0'
  s.add_development_dependency 'rake', '~> 10.0.3'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
end
