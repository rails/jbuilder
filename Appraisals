# frozen_string_literal: true

appraise "rails-7-0" do
  gem "rails", "~> 7.0.0"
  gem "concurrent-ruby", "< 1.3.5" # to avoid problem described in https://github.com/rails/rails/pull/54264
end

appraise "rails-7-1" do
  gem "rails", "~> 7.1.0"
end

appraise "rails-7-2" do
  gem "rails", "~> 7.2.0"
end

appraise "rails-8-0" do
  gem "rails", "~> 8.0.0"
end

appraise "rails-head" do
  gem "rails", github: "rails/rails", branch: "main"
end
