# see https://github.com/vincentbernat/serverspec-example/blob/master/Rakefile

require 'rake'
require 'rbconfig'
require 'rspec/core/rake_task'
require 'json'
require 'yaml'


class ServerspecTask < RSpec::Core::RakeTask

  attr_accessor :hosts

  def run_task(verbose)
    hosts.each_pair do |k, v|
      # instead of `k` (hostname) IP at `v['ansible_ssh_host']` could be used
      system("env TARGET_HOST=#{k} TARGET_PORT=#{v['ansible_ssh_port']} TARGET_USER=#{v['ansible_ssh_user']} #{spec_command}")
    end
  end
end


playbook = YAML.load_file File.join('.', 'setup.yml')

inventory = JSON.parse `./plugins/inventory/terraform.py --list`
hosts = inventory['_meta']['hostvars']


namespace :check do
  namespace :play do
    playbook.each do |play|
      checkable_hosts = hosts.select { |host|
        play['hosts'] == 'all' or
        play['hosts'].include? hosts[host]['role']
      }

      desc "Run serverspec to play #{play['name']}"
      ServerspecTask.new(play['name'].to_sym) do |t|
        t.hosts = checkable_hosts
        t.pattern = File.join('.', 'roles', '{' + play['roles'].join(",") + '}', 'spec', '*_spec.rb')
      end
    end
  end
end

task :default => ['check:play:All']
