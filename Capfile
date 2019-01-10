# Load DSL and Setup Up Stages
require 'capistrano/setup'
require 'capistrano/deploy'

require 'capistrano/rails'
require 'capistrano/bundler'
require 'capistrano/rvm'
require 'capistrano/puma'
require 'capistrano/secrets_yml'
# require File.expand_path("#{File.dirname(__FILE__)}/lib/gems/capistrano-db-tasks-0.4-fixed/lib/capistrano-db-tasks.rb")

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
