require 'yaml'

# end of server selection ---------------------

set :repo_url,        'git@github.com:numantayyab/seven_keys.git'
set :branch, ENV["BRANCH"] ? ENV["BRANCH"] : 'master'
set :application,     'seven_keys'
set :user,            'deploy'
set :branch, "master"
set :puma_threads,    [4, 16]
set :puma_workers,    0

# Don't change these unless you know what you're doing
set :pty,             false
set :use_sudo,        false
set :stage,           :production
set :deploy_via,      :remote_cache
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log,  "#{release_path}/log/puma.access.log"
set :ssh_options,     { forward_agent: true, user: fetch(:user), keys: %w(~/.ssh/id_rsa.pub) }
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord
set :log_level, :debug
## Defaults:
# set :scm,           :git
# set :branch,        :master
# set :format,        :pretty
# set :log_level,     :debug
# set :keep_releases, 5

# See https://github.com/sgruhier/capistrano-db-tasks

# if you want to remove the dump files from the server after downloading
set :db_remote_clean, true
set :db_local_clean, true
# if you want to exclude table from dump
set :db_ignore_tables, []
# if you want to exclude table data (but not table schema) from dump
set :db_ignore_data_tables, []
# if you are highly paranoid and want to prevent any push operation to the server
set :disallow_pushing, false
# if you want to work on a specific local environment (default = ENV['RAILS_ENV'] || 'development')
set :locals_rails_env, "development"
## Linked Files & Directories (Default None):  https://github.com/capistrano/rails/issues/104#issuecomment-83111845
set :linked_files, %w{config/database.yml config/secrets.yml}

# JP - check if besides public/ system and assets we didn't miss other folders for uploaded data
set :linked_dirs,  %w{ log tmp/pids tmp/cache tmp/sockets vendor/bundle public/assets public/system}

set :migration_role, :app