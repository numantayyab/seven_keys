require 'yaml'

# end of server selection ---------------------

# set :repo_url,        'git@bitbucket.org:skuteam/skustore-0.0.git'
set :branch, ENV["BRANCH"] ? ENV["BRANCH"] : 'master'
set :application,     'prosku'
set :user,            'deploy'
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
set :linked_files, %w{config/database.yml config/secrets.yml config/variables.yml config/google_integration.yml}

# JP - check if besides public/ system and assets we didn't miss other folders for uploaded data
set :linked_dirs,  %w{ log tmp/pids tmp/cache tmp/sockets vendor/bundle public/assets public/system company_data}

namespace :rails do
  desc "log in on the remote machine using SSH and run it there"
  task :console do
    on roles(:app) do
      puts "\nlog in on the remote machine using SSH and run it there\n"
      # run_interactively "bundle exec rails console production"
    end
  end
end


namespace :database do
  desc 'dump'
  task :dump do
    on roles(:app) do
    end
  end

  desc 'load'
  task :load do
    on roles(:app) do
    end
  end
end

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :logs do
  desc "tail rails logs" 
  task :tail_rails do
    on roles(:app) do
      execute "tail -f #{shared_path}/log/#{fetch(:rails_env)}.log"
    end
  end
end

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING: HEAD is not the same as origin/master"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc 'Initial Deploy'
  task :initial do
    on roles(:app) do
      before 'deploy:restart', 'puma:start'
      invoke 'deploy'
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'puma:restart'
    end
  end

  desc 'Invoke rake task on the server'
  task :invoke do
    fail 'no task provided' unless ENV['task']

    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          file = ENV['file']
          cmd = ENV['task'].dup
          cmd << %Q[ file=#{file}] unless file.nil?
          execute :rake, cmd
        end
      end
    end
  end

  #before :starting,   :copy_db_config
  #before :starting,     :check_revision
  after  :finishing,    :compile_assets
  after  :finishing,    :cleanup
  after  :finishing,    :restart
end

namespace :memcached do
  task :deploy_restart_and_clean_cache do
    on roles(:app) do
      invoke "memcached:restart_cache"
      invoke "memcached:clear_cache"
    end
  end

  desc 'Restarting cache'
  task :restart_cache do
    on roles(:app) do
      execute "sudo /etc/init.d/memcached restart"
    end
  end

  desc 'Cleaning cache'
  task :clear_cache do
    on roles(:app) do
      execute rake: " memcached:clear"
    end
  end

  before :deploy_restart_and_clean_cache, :deploy
end

namespace :logs do
  desc "tail rails logs" 
  task :rails do
    on roles(:app) do
      # execute "tail -n 1024 -f #{shared_path}/log/`ls -r #{shared_path}/log/ | grep #{fetch(:rails_env)}- | head -1`"
      execute "tail -n 1024 -f #{shared_path}/log/#{fetch(:rails_env)}.log"
    end
  end

  task :nginx_access do
    on roles(:app) do
      execute "tail -n 1024 -f #{shared_path}/log/nginx.access.log"
    end    
  end

  task :nginx_error do
    on roles(:app) do
      execute "tail -n 1024 -f #{shared_path}/log/nginx.error.log"
    end    
  end


end

## Sidekiq should be restarted after each deploy to point to current copy of code
namespace :sidekiq do

  task :restart do
    # invoke 'sidekiq:stop'
    # invoke 'sidekiq:start'
    on roles(:app) do
      within current_path do
        begin
          # Process.kill('QUIT', pid)
          execute("sudo monit restart sidekiq")
        rescue Exception => ex
          puts "Sidekiq was not running"
        ensure
          puts "Inside ensure"
        end
      end
    end
  end

  before 'deploy:finished', 'sidekiq:restart'

  task :stop do
    on roles(:app) do
      within current_path do
        pid = p capture "ps aux | grep '[s]idekiq' | awk '{print $2}' | sed -n 1p"
        puts "we are going to stop sidekiq"
        puts "The sidekiq pid was: #{pid}"
        begin
          # Process.kill('QUIT', pid)
          execute("sudo monit stop sidekiq")
          # execute("sudo kill -9 #{pid}")
        rescue Exception => ex
          puts "Sidekiq was not running"
        ensure
          ##NT Sidekiq worker takes 8seconds to stop. We wait for 10 seconds to ensure changes take place.
          sleep(10)
        end
      end
    end
  end

  task :start do
    on roles(:app) do
      within current_path do
        execute("echo 'we are going to start sidekiq'")
        execute("sudo monit start sidekiq")
        # execute :bundle, "exec sidekiq -e #{fetch(:stage)} -C config/sidekiq.yml -d"
      end
    end
  end
end

# ps aux | grep puma    # Get puma pid
# kill -s SIGUSR2 pid   # Restart puma
# kill -s SIGTERM pid   # Stop puma
