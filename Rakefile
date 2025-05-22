# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |test|
  require 'rails/version'

  test.libs << 'test'

  test.test_files = FileList['test/*_test.rb']
end

task default: :test
