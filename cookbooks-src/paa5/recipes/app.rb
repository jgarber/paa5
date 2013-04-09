#
# Cookbook Name:: paa5
# Recipe:: app
#
# Copyright 2013, Jason Garber
#
# See LICENSE for details
#

app_dir = node['paa5']['app_directory']
repo_path = "/home/git/repositories/paa5.git"

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

directory repo_path do
  recursive true
  owner 'git'
  group 'git'
  mode 0770
end

group "git" do
  members ["vagrant"]
  append  true
end

directory '/etc/bluepill' do
  owner 'vagrant'
  group 'git'
  mode 0770
end

directory '/srv' do
  owner 'vagrant'
  group 'git'
  mode 0770
end

template "/etc/nginx/sites-enabled/default" do
  owner "root"
  group "root"
  mode "644"
  source "nginx.erb"
  variables( :static_root => "#{app_dir}/public")
  notifies :restart, "service[nginx]"
end
