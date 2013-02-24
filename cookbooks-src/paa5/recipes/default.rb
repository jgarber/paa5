#
# Cookbook Name:: paa5
# Recipe:: default
#
# Copyright 2013, Jason Garber
#
# See LICENSE for details
#
class Chef::Recipe
    # mix in recipe helpers
    include Chef::RubyBuild::RecipeHelpers
end

app_dir = node['paa5']['app_directory']

node['rbenv']['rubies'] = [ node['paa5']['ruby_version'] ]

include_recipe "apt"
package "build-essential"
include_recipe "ruby_build"

include_recipe "rbenv::system"
include_recipe "rbenv::vagrant"

rbenv_global node['paa5']['ruby_version']
rbenv_gem "bundler"
rbenv_gem "rake"
rbenv_gem "bluepill"

node['nginx']['init_style'] = "bluepill"
include_recipe "nginx::source"

postgresql_connection_info = {:host => "localhost",
                              :port => node['postgresql']['config']['port'],
                              :username => 'postgres',
                              :password => node['postgresql']['password']['postgres']}

postgresql_database 'paa5_production' do
  connection postgresql_connection_info
  action :create
end

postgresql_database_user 'paa5' do
  connection postgresql_connection_info
  password 'paa5'
  action :create
end

postgresql_database_user 'paa5' do
  connection postgresql_connection_info
  database_name 'paa5_production'
  privileges [:all]
  action :grant
end

rbenv_script "run-paa5-admin" do
  rbenv_version node['paa5']['ruby_version']
  cwd app_dir
  environment 'RAILS_ENV' => 'production'

  code <<-EOD
    bundle install
    bundle exec rake db:migrate
    bundle exec rake assets:precompile
    rm -f tmp/pids/server.pid
    bundle exec puma -b unix:/tmp/puma.paa5.sock --pidfile tmp/pids/server.pid -e $RAILS_ENV -d
  EOD
end

template "/etc/nginx/sites-enabled/default" do
  owner "root"
  group "root"
  mode "644"
  source "nginx.erb"
  variables( :static_root => "#{app_dir}/public")
  notifies :restart, "service[nginx]"
end
