#
# Cookbook Name:: paa5
# Recipe:: default
#
# Copyright 2013, Jason Garber
#
# See LICENSE for details
#
include_recipe "rvm::gem_package"

node['rvm']['default_ruby'] = node['paa5']['ruby_version']
node['rvm']['gem_package']['rvm_string'] = node['paa5']['ruby_version']
node['rvm']['group_users'] = ['vagrant']

include_recipe "apt"
include_recipe "build-essential"
include_recipe "rvm::vagrant"
include_recipe "rvm::system"
include_recipe "nodejs"
include_recipe "database::postgresql"
include_recipe "postgresql::server"

rvm_gem "bundler"
rvm_gem "bluepill"
rvm_gem "foreman"
node["bluepill"]["bin"] = "#{node[:languages][:ruby][:gems_dir]}/bin/bluepill"
node['nginx']['init_style'] = "bluepill"
include_recipe "nginx::source"

include_recipe "paa5::git_setup"
include_recipe "paa5::app"
