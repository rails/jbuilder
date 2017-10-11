require 'bundler/setup'
require "bundler/gem_tasks"
Bundler.require(:development)

require 'fileutils'
require "rake/testtask"

# Test Task
Rake::TestTask.new do |t|
    t.libs << 'lib' << 'test'
    t.test_files = FileList['test/**/*_test.rb']
    t.warning = true
    t.verbose = false
end

task default: :test