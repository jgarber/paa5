#
# Cookbook Name:: paa5
# Recipe:: git_setup
#
# Copyright 2013, Jason Garber
#
# See LICENSE for details
#
user 'git' do
  comment "Git User"
  home '/home/git'
  shell "/bin/bash"
end

group 'git' do
  members ['git']
end

directory '/home/git' do
  owner 'git'
  group 'git'
  mode 0770
end


