#
# Cookbook Name:: chef_portal
# Recipe:: _refesh_iam_creds
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

ohai 'reload_ec2' do
  action :nothing
  plugin 'ec2'
end

directory '/etc/chef/ohai/hints' do
  recursive true
end

%w(ec2 iam).each do |hint|
  file "/etc/chef/ohai/hints/#{hint}.json" do
    notifies :reload, 'ohai[reload_ec2]', :immediately
  end
end

# put my IAM credentials somewhere chef-provisioning can use them
directory '/root/.aws' do
  user 'root'
  group 'root'
  mode '0700'
end

iam_role_name = node['chef_classroom']['iam_instance_profile'].split('/')[1]

template '/root/.aws/config' do
  source 'aws_config.erb'
  variables(
    lazy do
      {
        :access_key => node['ec2']['iam']['security-credentials'][iam_role_name]['AccessKeyId'],
        :secret_access_key => node['ec2']['iam']['security-credentials'][iam_role_name]['SecretAccessKey']
      }
    end
  )
  user 'root'
  group 'root'
  mode '0600'
end
