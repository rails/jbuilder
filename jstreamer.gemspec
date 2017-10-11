require File.expand_path("../lib/jstreamer/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name          = "jstreamer"
  spec.version       = Jstreamer::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["Jon Bracy"]
  spec.email         = ["jonbracy@gmail.com"]
  spec.homepage      = "https://github.com/malomalo/jstreamer"
  spec.summary       = 'Stream JSON via a Builder-style DSL'
  # spec.description   = %q{}

  spec.extra_rdoc_files = %w(README.md)
  spec.rdoc_options.concat ['--main', 'README.md']

  spec.files         = `git ls-files -- README.md {lib,ext}/*`.split("\n")
  spec.test_files    = `git ls-files -- {test}/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'activesupport', '>= 4.2.0'
  spec.add_runtime_dependency 'wankel',        '~> 0.6'
    
  spec.add_development_dependency "rake"
  spec.add_development_dependency "bundler", '~> 1.11', '>= 1.11.2'
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "actionview"
  spec.add_development_dependency "actionpack"
  # spec.add_development_dependency 'sdoc',                '~> 0.4'
  # spec.add_development_dependency 'sdoc-templates-42floors', '~> 0.3'
end
