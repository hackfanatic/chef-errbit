#
# Author:: Sachin Sagar Rai <millisami@gmail.com>
# Cookbook Name:: errbit
# Recipe:: setup
#
# Copyright (C) 2013 Millisami
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.set['build_essential']['compile_time'] = true

include_recipe "build-essential"
include_recipe "git"
include_recipe "nginx"
include_recipe "mongodb::default"

mongodb_instance "mongodb" do
  dbpath node['mongodb']['config']['dbpath']
end

extend SELinuxPolicy::Helpers
include_recipe 'selinux_policy::install' if use_selinux

home_dir = "/home/#{node['errbit']['user']}"
rails_env = node['errbit']['config']['rails_env']

group node['errbit']['group']

user node['errbit']['user'] do
  action :create
  comment "Errbit user"
  gid node['errbit']['group']
  shell "/bin/bash"
  home home_dir
  supports :manage_home => true
  system false
end

<<<<<<< HEAD
execute "update sources list" do
  command "apt-get update"
  action :nothing
end.run_action(:run)

%w(libxml2-dev libxslt1-dev libcurl4-gnutls-dev).each do |pkg|
  r = package pkg do
    action :nothing
  end
  r.run_action(:install)
=======
# Ensure nginx can read within this directory
directory home_dir do
  mode 0701
end

# setup rbenv (after git user setup)
%w{ ruby_build rbenv::user_install }.each do |requirement|
  include_recipe requirement
end

# Install appropriate Ruby with rbenv
rbenv_ruby node['errbit']['install_ruby'] do
  action :install
  user node['errbit']['user']
end

# Set as the rbenv default ruby
rbenv_global node['errbit']['install_ruby'] do
  user node['errbit']['user']
end

# Install required Ruby Gems(via rbenv)
rbenv_gem "bundler" do
  action :install
  user node['errbit']['user']
>>>>>>> upstream/master
end

include_recipe "ruby_build"

# Install appropriate Ruby
ruby_build_ruby node['errbit']['install_ruby'] do
  prefix_path "/usr/local/"
end

# Install required Ruby Gems
gem_package "bundler" do
  gem_binary "/usr/local/bin/gem"
  options "--no-ri --no-rdoc"
end

# update all gems, is required for ubuntu 13.04 and 13.10
execute "gem update" do
  command <<-EOS
    gem update --system
  EOS
end

directory node['errbit']['deploy_to'] do
  owner node['errbit']['user']
  group node['errbit']['group']
  action :create
  recursive true
end

directory "#{node['errbit']['deploy_to']}/shared" do
  owner node['errbit']['user']
  group node['errbit']['group']
  mode 00755
end

%w( config log pids sockets ).each do |dir|
  directory "#{node['errbit']['deploy_to']}/shared/#{dir}" do
    owner node['errbit']['user']
    group node['errbit']['group']
    mode 0775
    recursive true
  end
end

<<<<<<< HEAD
# errbit config.yml
template "#{node['errbit']['deploy_to']}/shared/config/config.yml" do
  source "config.yml.erb"
  owner node['errbit']['user']
  group node['errbit']['group']
  mode 00644
  variables(params: {
    host: node['errbit']['config']['host'],
    enforce_ssl: node['errbit']['config']['enforce_ssl'],
    email_from: node['errbit']['config']['email_from'],
    per_app_email_at_notices: node['errbit']['config']['per_app_email_at_notices'],
    email_at_notices: node['errbit']['config']['email_at_notices'],
    confirm_resolve_err: node['errbit']['config']['confirm_resolve_err'],
    user_has_username: node['errbit']['config']['user_has_username'],
    allow_comments_with_issue_tracker: node['errbit']['config']['allow_comments_with_issue_tracker'],
    use_gravatar: node['errbit']['config']['use_gravatar'],
    gravatar_default: node['errbit']['config']['gravatar_default'],
    github_authentication: node['errbit']['config']['github_authentication'],
    github_client_id: node['errbit']['config']['github_client_id'],
    github_secret: node['errbit']['config']['github_secret'],
    github_access_scope: node['errbit']['config']['github_access_scope'],
    smtp_address: node['errbit']['config']['smtp_address'],
    smtp_domain: node['errbit']['config']['smtp_domain'],
    smtp_port: node['errbit']['config']['smtp_port'],
    smtp_username: node['errbit']['config']['smtp_username'],
    smtp_authentication: node['errbit']['config']['smtp_authentication'],
    smtp_password: node['errbit']['config']['smtp_password']
  })
end

template "#{node['errbit']['deploy_to']}/shared/config/mongoid.yml" do
  source "mongoid.yml.erb"
=======
require 'securerandom'
node.normal_unless['errbit']['config']['secret_key_base'] = SecureRandom.urlsafe_base64(96)

file "#{node['errbit']['deploy_to']}/shared/config/env" do
  content node['errbit']['config'].map { |key, value|
    case value
    when nil
    when Array
      "export #{key.upcase}=\"[#{value.join ','}]\""
    else
      "export #{key.upcase}=#{value.inspect}"
    end
  }.compact.join("\n") + "\n"

>>>>>>> upstream/master
  owner node['errbit']['user']
  group node['errbit']['group']
  mode 0644
end

deploy_revision node['errbit']['deploy_to'] do
  repo node['errbit']['repo_url']
  revision node['errbit']['revision']
  shallow_clone true

  user node['errbit']['user']
  group node['errbit']['group']

  environment(
    'HOME' => home_dir,
    'RAILS_ENV' => rails_env
  )

  migration_command "#{home_dir}/.rbenv/bin/rbenv exec bundle exec rake db:migrate"
  migrate true

  symlink_before_migrate('config/env' => '.env')
  symlinks('log' => 'log', 'pids' => 'tmp/pids', 'sockets' => 'tmp/sockets')

  before_migrate do
<<<<<<< HEAD
    directory "#{release_path}/vendor" do
      action :create
    end
    link "#{release_path}/vendor/bundle" do
      to "#{node['errbit']['deploy_to']}/shared/vendor_bundle"
    end
    common_groups = %w{development test cucumber staging production}
    execute "bundle install" do
      user node['errbit']['user']
      group node['errbit']['group']
      cwd release_path
      command "bundle install --jobs=3 --deployment --without #{(common_groups - ([node['errbit']['environment']])).join(' ')}"
=======
    template "#{release_path}/UserGemfile" do
      source "UserGemfile.erb"
      owner node['errbit']['user']
      group node['errbit']['group']
      mode 0644
    end

    common_groups = %w{development test production heroku} - [rails_env]

    rbenv_script 'bundle install' do
      code "bundle install --system --without '#{common_groups.join ' '}'"
      cwd release_path
      user node['errbit']['user']
>>>>>>> upstream/master
    end

<<<<<<< HEAD
  symlink_before_migrate nil
  symlinks(
    "config/config.yml" => "config/config.yml",
    "config/mongoid.yml" => "config/mongoid.yml"
  )
  environment 'RAILS_ENV' => node['errbit']['environment']
  shallow_clone false
  action :deploy #:deploy or :rollback or :force_deploy

  before_restart do

    Chef::Log.info "*" * 20 + "COMPILING ASSETS" + "*" * 20
    execute "asset_precompile" do
      user node['errbit']['user']
      group node['errbit']['group']
      cwd release_path
      command "bundle exec rake assets:precompile --trace RAILS_ENV=#{node['errbit']['environment']}"
=======
    selinux_policy_fcontext "#{release_path}/(app/assets|public)(/.*)?" do
      secontext 'httpd_sys_content_t'
    end

    Chef::Log.info "*" * 20 + "COMPILING ASSETS" + "*" * 20

    rbenv_script 'rake assets:precompile' do
      code 'bundle exec rake assets:precompile RAILS_ENV=' + rails_env
      cwd release_path
      user node['errbit']['user']
>>>>>>> upstream/master
    end
  end
end

selinux_policy_fcontext "#{node['errbit']['deploy_to']}/current" do
  secontext 'httpd_sys_content_t'
end

selinux_policy_fcontext "#{node['errbit']['deploy_to']}/shared/sockets/[^/]*\.sock" do
  secontext 'httpd_var_run_t'
end

selinux_policy_module 'nginx-errbit-socket' do
  content <<-EOF
    module nginx-errbit-socket 0.1;

    require {
      type httpd_t;
      type init_t;
      class unix_stream_socket connectto;
    }

    allow httpd_t init_t:unix_stream_socket connectto;
  EOF
end

template "#{node['nginx']['dir']}/sites-available/#{node['errbit']['name']}" do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 00644
  variables( :server_names => node['errbit']['config']['server_names'] )
end

nginx_site node['errbit']['name'] do
  enable true
end
