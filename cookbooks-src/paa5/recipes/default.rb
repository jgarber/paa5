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

node['rbenv']['rubies'] = [ node['paa5']['ruby_version'] ]

include_recipe "apt"
package "build-essential"
include_recipe "ruby_build"
include_recipe "nodejs"
include_recipe "database::postgresql"
include_recipe "postgresql::server"

include_recipe "rbenv::system"
include_recipe "rbenv::vagrant"

rbenv_global node['paa5']['ruby_version']
rbenv_gem "bundler"
rbenv_gem "bluepill"

node['nginx']['init_style'] = "bluepill"
include_recipe "nginx::source"

include_recipe "paa5::git_setup"
include_recipe "paa5::app"
