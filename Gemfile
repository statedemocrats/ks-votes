source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


gem 'rails', '~> 5.1.3'
gem 'pg'
gem 'puma', '~> 3.7'
gem 'sass-rails', '~> 5.0'
gem 'jbuilder', '~> 2.5'
gem 'jsonapi-resources'
gem "font-awesome-rails"
gem 'jquery-rails'

group :development, :test do
  gem 'capybara', '~> 2.13'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
end
