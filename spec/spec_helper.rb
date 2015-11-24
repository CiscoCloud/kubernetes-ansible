require 'json'
require 'net/ssh'
require 'serverspec'
require 'serverspec_extensions'
require 'yaml'


ANSIBLE_GROUP_VARS = YAML.load_file File.join(__dir__, '..', 'group_vars', 'all.yml')
INVENTORY = JSON.parse `#{File.join(__dir__, '..', 'plugins', 'inventory', 'terraform.py')} --list`


set :backend, :ssh
set :request_pty, true


if ENV['ASK_SUDO_PASSWORD']
  begin
    require 'highline/import'
  rescue LoadError
    fail "highline is not available. Try installing it."
  end
  set :sudo_password, ask("Enter sudo password: ") { |q| q.echo = false }
else
  set :sudo_password, ENV['SUDO_PASSWORD']
end


host = ENV['TARGET_HOST']

options = Net::SSH::Config.for(host)

options[:user] ||= ENV['TARGET_USER']
options[:port] ||= ENV['TARGET_PORT']
options[:keys] ||= ENV['TARGET_PRIVATE_KEY']

set :host,        options[:host_name] || host
set :ssh_options, options

CURRENT_HOST = options[:host_name] || host


# `serverspec` could not properly automatically detect `CentOS 7`
set :os, :family => 'redhat', :release => 7
