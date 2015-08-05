#
# Cookbook Name:: chef_portal
# Recipe:: provisioner_node
#
# Author:: George Miranda (<gmiranda@chef.io>)
# License:: MIT
# Copyright (c) 2015 Chef Software, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


portal_user = node['chef_portal']['user']
portal_pass = node['chef_portal']['password'].crypt("$6$" + rand(36**8).to_s(36))
chefdk_ver = node['chef_portal']['versions']['chef_dk']
provis_ver = node['chef_portal']['versions']['chef_provisioning']
cp_aws_ver = node['chef_portal']['versions']['chef_provisioning_aws']

# Setup the portal user
user portal_user do
  comment 'Chef Portal User'
  shell '/bin/bash'
  password portal_pass
end

# Give non-root users sudo
# sudo portal_user do
#   user portal_user
#   nopasswd true
#   defaults ['!requiretty']
# end

# enable password login
service 'sshd' do
  action :nothing
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :restart, 'service[sshd]', :immediately
end

# install explicitly pinned ChefDK
chef_dk 'install' do
	version chefdk_ver
  global_shell_init true
end

template '/root/.bashrc' do
  source 'bashrc.erb'
  mode '0640'
end

# Explicitly pin chef-provisioning
# Explicitly pin chef-provisioning-aws
# (shell init may not be yet available, so we have to fake it)
execute 'update_chef_provisioning' do
  command "chef gem install chef-provisioning -v #{provis_ver}"
    environment(
    'PATH' => '/opt/chefdk/bin:/opt/chefdk/embedded/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
    'GEM_ROOT' => '/opt/chefdk/embedded/lib/ruby/gems/2.1.0',
    'GEM_HOME' => '/root/.chefdk/gem/ruby/2.1.0',
    'GEM_PATH' => '/root/.chefdk/gem/ruby/2.1.0:/opt/chefdk/embedded/lib/ruby/gems/2.1.0'
  )
  # not_if 'gem update is idempotent enough for now'
end

execute 'update_chef_provisioning' do
  command "chef gem install chef-provisioning-aws -v #{cp_aws_ver}"
    environment(
    'PATH' => '/opt/chefdk/bin:/opt/chefdk/embedded/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin',
    'GEM_ROOT' => '/opt/chefdk/embedded/lib/ruby/gems/2.1.0',
    'GEM_HOME' => '/root/.chefdk/gem/ruby/2.1.0',
    'GEM_PATH' => '/root/.chefdk/gem/ruby/2.1.0:/opt/chefdk/embedded/lib/ruby/gems/2.1.0'
  )
  # not_if 'gem update is idempotent enough for now'
end

# get my AWS creds from IAM
include_recipe 'chef_portal::_refresh_iam_creds'

# disable selinux & iptables because complexity and webapp
case node['platform']
  when 'redhat', 'centos', 'fedora'
  template '/etc/selinux/config' do
    source 'selinux-config.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end
end

service 'iptables' do
  supports :status => true, :restart => true, :reload => true
  action [:stop, :disable]
end
