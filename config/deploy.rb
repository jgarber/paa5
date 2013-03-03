require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'    # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, 'localhost'
set :user, 'vagrant'
set :port, '2222'
set :deploy_to, '/srv/paa5'
set :repository, '/vagrant/'
set :branch, 'master'
set :rbenv_path, '/usr/local/rbenv'
set :bundle_bin, '/usr/local/rbenv/shims/bundle' # FIXME: shouldn't have to

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'config/config.yml', 'log']

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
  #queue  %[-----> Be sure to edit 'shared/config/database.yml'.]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'
    invoke :'foreman:export'

    to :launch do
      queue 'sudo bluepill restart nginx'
      invoke 'foreman:restart' # FIXME: needs some logic for when not already started
    end
  end
end

set_default :foreman_app,  lambda { application }
set_default :foreman_user, lambda { user }
set_default :foreman_log,  lambda { "#{deploy_to!}/#{shared_path}/log" }

namespace :foreman do
  desc 'Export the Procfile to Bluepill scripts'
  task :export do
    export_cmd = "sudo #{bundle_bin} exec foreman export bluepill /etc/bluepill -a #{foreman_app} -u #{foreman_user} -l #{foreman_log}"

    queue %{
      echo "-----> Exporting foreman procfile for #{foreman_app}"
      #{echo_cmd %[cd #{deploy_to!}/#{current_path!} ; #{export_cmd}]}
    }
  end

  desc "Start the application services"
  task :start do
    queue %{
      echo "-----> Starting #{foreman_app} services"
      #{echo_cmd %[sudo "bluepill start #{foreman_app}"]}
    }
  end

  desc "Stop the application services"
  task :stop do
    queue %{
      echo "-----> Stopping #{foreman_app} services"
      #{echo_cmd %[sudo "bluepill stop #{foreman_app}"]}
    }
  end

  desc "Restart the application services"
  task :restart do
    queue %{
      echo "-----> Restarting #{foreman_app} services"
      #{echo_cmd %[sudo bluepill restart #{foreman_app}]}
    }
  end
end

