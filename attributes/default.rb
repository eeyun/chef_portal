default['chef_portal']['user'] = 'root' # sudo picks up ec2-metadata
default['chef_portal']['password'] = 'chefportal'

default['chef_portal']['versions']['chef_dk'] = '0.6.2'
default['chef_portal']['versions']['chef_provisioning'] = '1.2.1'
default['chef_portal']['versions']['chef_provisioning_aws'] = '1.3.0'

default['chef_portal']['app_root'] = '/var/www/chef_portal'
default['chef_portal']['app_repo'] = 'https://github.com/eeyun/portal_site.git'

default['unicorn-ng']['config']['config_file'] = "#{node['chef_portal']['app_root']}/unicorn.rb"
