# see https://github.com/vincentbernat/serverspec-example/blob/master/Rakefile

require 'rake'
require 'rbconfig'
require 'rspec/core/rake_task'
require 'json'
require 'yaml'


class ServerspecTask < RSpec::Core::RakeTask

  attr_accessor :hosts

  def run_task(verbose)
    hosts.each_pair do |hostname, vars|
      puts "Running tests on #{hostname} [#{vars['ansible_ssh_host']}]"

      success = system("env TARGET_HOST=#{vars['ansible_ssh_host']} TARGET_HOST_NAME=#{hostname} TARGET_PORT=#{vars['ansible_ssh_port']} TARGET_USER=#{vars['ansible_ssh_user']} #{spec_command}")
      raise "Failed!" if not success
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
