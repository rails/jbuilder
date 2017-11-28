require 'bundler/setup'
require "bundler/gem_tasks"
Bundler.require(:development)

require 'fileutils'
require "rake/testtask"

ENCODERS = %w(wankel oj)

# Test Task
ENCODERS.each do |encoder|
  namespace :test do
    Rake::TestTask.new(encoder => ["#{encoder}:env", "test:coverage"]) do |t|
      t.libs << 'lib' << 'test'
      t.test_files = FileList['test/**/*_test.rb']
      t.warning = true
      t.verbose = false
    end
    
    namespace encoder do
      task(:env) { ENV["TSENCODER"] = encoder }
    end
  end
end

namespace :test do
  
  task :coverage do
    require 'simplecov'
    SimpleCov.start do
      add_group 'lib', 'lib'
      add_group 'ext', 'ext'
      add_filter "/test"
    end
  end
  
  desc "Run test with all encoders"
  task all: ENCODERS.shuffle.map{ |e| "test:#{e}" }

end


task test: "test:all"