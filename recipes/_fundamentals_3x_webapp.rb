#
# Cookbook Name:: chef_portal
# Recipe:: _fundamentals_3x_webapp
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
include_recipe 'apt'
include_recipe 'ruby::1.9.1'
include_recipe 'unicorn-ng::install'

package 'git'
package 'nginx'

service 'iptables' do
  action [:disable, :stop]
end

cookbook_file '/etc/nginx/nginx.conf' do
 source 'nginx.conf'
end

directory node['chef_portal']['app_root'] do
  recursive true
end

service 'nginx' do
 action [:enable, :start]
end

# Clone the app repo down to the app_root
# directory, install the bundle and start
# unicorn.
git 'chef portal' do
 repository node['chef_portal']['app_repo']
 destination node['chef_portal']['app_root']
 revision 'gemfile_test'
 action :sync
end

execute 'bundle install' do
  cwd node['chef_portal']['app_root']
end

unicorn_ng_service 'default' do
  config node['unicorn-ng']['config']['config_file']
  bundle_gemfile "#{node['chef_portal']['app_root']}/Gemfile"
  rails_root node['chef_portal']['app_root']
  only_if { node['chef_portal']['app_root'] }
  notifies :restart, 'service[nginx]'
end

# lazy create the guacamole user map and monkeypatch it
# search returns nil during compilation
include_recipe 'guacamole'

chef_gem 'chef-rewind'
require 'chef/rewind'

rewind 'template[/etc/guacamole/user-mapping.xml]' do
  variables(
    lazy do
      { :usermap => guacamole_user_map }
    end
  )
end
