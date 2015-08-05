#
# Cookbook Name:: chef_portal
# Recipe:: fundamentals_3x
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

include_recipe 'chef_portal::provisioner_node'

# Clone the classroom git repo
package 'git'

execute 'berks_vendor_cookbooks' do
	action :nothing
	command 'berks vendor cookbooks'
	cwd '/root/chef_classroom'
end

git '/root/chef_classroom' do
  repository 'git://github.com/gmiranda23/chef_classroom.git'
  revision 'master'
  action :sync
	notifies :run, 'execute[berks_vendor_cookbooks]', :immediately
end

# Setup the web portal interface for fundamentals_3x
include_recipe 'chef_portal::fundamentals_3x_webapp'

# Now go deploy infrastructure like a fucking wizard
# chef-client -z -r 'recipe[chef_classroom::deploy_workstations]'
# chef-client -z -r 'recipe[chef_classroom::deploy_server]'
# chef-client -z -r 'recipe[chef_classroom::deploy_first_nodes]'
# chef-client -z -r 'recipe[chef_classroom::deploy_multi_nodes]'
