require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/rbenv'    # for rbenv support. (http://rbenv.org)
require 'mina/rvm'    # for rvm support. (http://rvm.io)
require 'yaml'

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

set :domain, '33.33.33.10'
set :user, 'vagrant'
set :port, '22'
set :deploy_to, '/srv/paa5'
set :repository, '/vagrant/'
set :branch, 'master'
set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'log', '.env']

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.

set_default :foreman_app,  lambda { deploy_to.split('/').last }
set_default :foreman_user, lambda { user }
set_default :foreman_log,  lambda { "#{deploy_to!}/#{shared_path}/log" }
set_default :bluepill_bin, "#{foreman_app}_bluepill"

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .rbenv-version to your repository.
  # queue %{export RBENV_ROOT=#{rbenv_path}} # for system-wide install
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  invoke :'rvm:use[ruby-1.9.3-p392]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  db_yaml = {"production"=>{"adapter"=>"postgresql", "encoding"=>"unicode", "host"=>"localhost", "database"=>"#{foreman_app}_production", "pool"=>5, "username"=>"paa5", "password"=>"paa5"}}.to_yaml
  queue  %[echo #{Shellwords.escape(db_yaml)} > #{deploy_to}/shared/config/database.yml]

  queue! %[echo "RACK_ENV=production" > #{deploy_to}/shared/.env]
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
      in_directory '/' do # Escape vendored bundle
        queue "sudo #{bluepill_bin} load /etc/bluepill/#{foreman_app}.pill"
        queue "sudo ln -sf #{bluepill_bin} /etc/init.d/#{foreman_app}"
        queue "sudo #{bluepill_bin} nginx restart"
        invoke 'foreman:restart'
      end
    end
  end
end

# ### rvm:wrapper[]
# Creates a rvm wrapper for a given executable
#
# This is usually placed in the `:setup` task.
#
#     task ::setup => :environment do
#       ...
#       invoke :'rvm:wrapper[ruby-1.9.3-p125@gemset_name,wrapper_name,binary_name]'
#     end
#
task :'rvm:wrapper', :env, :name, :bin do |t,args|
  unless args[:env] && args[:name] && args[:bin]
    print_error "Task 'rvm:wrapper' needs an RVM environment name, an wrapper name and the binary name as arguments"
    print_error "Example: invoke :'rvm:use[ruby-1.9.2@myapp,myapp,unicorn_rails]'"
    die
  end

  queue %{
    echo "-----> creating RVM wrapper '#{args[:name]}_#{args[:bin]}' using '#{args[:env]}'"
    if [[ ! -s "#{rvm_path}" ]]; then
      echo "! Ruby Version Manager not found"
      echo "! If RVM is installed, check your :rvm_path setting."
      exit 1
    fi

    source #{rvm_path}
    #{echo_cmd %{sudo rvm wrapper #{args[:env]} #{args[:name]} #{args[:bin]} }} || exit 1
  }
end

namespace :foreman do
  desc 'Export the Procfile to Bluepill scripts'
  task :export => [:environment, :rvm_wrap] do
    export_cmd = "foreman export bluepill /etc/bluepill -a #{foreman_app} --user #{foreman_user} --log #{foreman_log} --env #{deploy_to!}/#{shared_path}/.env --root=#{deploy_to!}/#{current_path!} --procfile=./Procfile"

    queue %{
      echo "-----> Exporting foreman procfile for #{foreman_app}"
      #{echo_cmd export_cmd}
    }
  end

  desc 'Make an RVM wrapper for bluepill'
  task :rvm_wrap => :environment do
    invoke :"rvm:wrapper[ruby-1.9.3-p392,#{foreman_app},`which bluepill`]"
  end

  desc "Start the application services"
  task :start do
    queue %{
      echo "-----> Starting #{foreman_app} services"
      #{echo_cmd %[sudo #{bluepill_bin} #{foreman_app} start]}
    }
  end

  desc "Stop the application services"
  task :stop do
    queue %{
      echo "-----> Stopping #{foreman_app} services"
      #{echo_cmd %[sudo #{bluepill_bin} #{foreman_app} stop]}
    }
  end

  desc "Restart the application services"
  task :restart do
    queue %{
      echo "-----> Restarting #{foreman_app} services"
      # No-ops if not started
      #{echo_cmd %[sudo #{bluepill_bin} #{foreman_app} restart]}
      # No-ops if already running
      #{echo_cmd %[sudo #{bluepill_bin} #{foreman_app} start]}
    }
  end
end

