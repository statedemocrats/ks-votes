source 'https://rubygems.org'

ruby '3.4.5'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


gem 'rails', '>= 6.1.7.1'
gem 'pg'
gem 'term-ansicolor'
gem 'ansi'
gem 'httparty'

gem 'rgeo-geojson'
gem 'fuzzy_match', git: 'https://github.com/karpet/fuzzy_match.git'
gem 'fuzzy_tools', github: 'statedemocrats/fuzzy_tools', branch: 'nan-fix'

gem 'elasticsearch'
gem 'elasticsearch-model', '~> 6'
gem 'elasticsearch-rails', '~> 6'
gem 'elasticsearch-rails-ha'

group :development, :test do
  gem 'capybara', '~> 2.13'
end

group :development do
  gem 'listen', '>= 3.0.5', '< 3.2'
end
