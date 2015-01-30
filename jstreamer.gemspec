Gem::Specification.new do |s|
  s.name     = 'jstreamer'
  s.version  = '3.0.0'
  s.authors  = ['Jon Bracy']
  s.email    = ['jonbracy@gmail.com']
  s.summary  = 'Create JSON structures via a Builder-style DSL'
  s.homepage = 'https://github.com/malomalo/jstreamer'
  s.license  = 'MIT'

  s.required_ruby_version = '>= 2.0.0'

  s.add_dependency 'activesupport', '>= 4.0.0', '< 5'
  s.add_dependency 'wankel',    '~> 0.5'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
end
