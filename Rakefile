require 'bundler'
require 'rake/testtask'

Bundler.require

Rake::TestTask.new do |test|
  test.libs << 'lib'
  test.test_files = FileList['test/*_test.rb']
end

task :default => :test
