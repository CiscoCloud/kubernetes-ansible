# see https://github.com/vincentbernat/serverspec-example/blob/master/Rakefile

require 'rake'
require 'rbconfig'
require 'rspec/core/rake_task'
require 'json'
require 'yaml'


# set JSON format as default one
ENV['FORMAT'] ||= 'json'

$results = []


class ServerspecTask < RSpec::Core::RakeTask

  attr_accessor :target_host
  attr_accessor :target_host_vars
  attr_accessor :target_play_role

  def run_task(verbose)
    command = "TARGET_HOST=#{target_host_vars['ansible_ssh_host']} "
    command << "TARGET_HOST_NAME=#{target_host} "
    command << "TARGET_PORT=#{target_host_vars['ansible_ssh_port']} "
    command << "TARGET_USER=#{target_host_vars['ansible_ssh_user']} "
    command << "#{spec_command}"

    if ENV['FORMAT'] == 'json'
      output = `#{command}`

      $results << {
        :name => self.name,
        :exit_code => $?.to_i,
        :output => JSON.parse(output)
      }
    else
      puts "Running \"#{target_play_role}\" tests on #{target_host} [#{target_host_vars['ansible_ssh_host']}]"

      succeed = system "#{command}"
      raise "Failed!" if not succeed
    end
  end
end


playbook = YAML.load_file File.join('.', 'setup.yml')

inventory = JSON.parse `./plugins/inventory/terraform.py --list`
hosts = inventory['_meta']['hostvars']


namespace :spec do
  all_tasks = []

  playbook.each do |play|
    checkable_hosts = hosts.select { |host|
      play['hosts'] == 'all' or
      play['hosts'].include? hosts[host]['role']
    }

    play_tasks = []

    play['roles'].each do |play_role|
      checkable_hosts.each do |hostname, vars|
        task_name = "#{play_role}::#{hostname}".to_sym

        desc "Run serverspec for \"#{play_role}\" role at #{hostname}"
        ServerspecTask.new(task_name) do |t|
          t.target_host = hostname
          t.target_host_vars = vars
          t.target_play_role = play_role
          t.pattern = File.join('.', 'roles', play_role, 'spec', '*_spec.rb')
        end

        play_tasks << task_name
        all_tasks << task_name
      end
    end

    namespace :play do
      desc "Run serverspec to play \"#{play['name']}\""
      task play['name'].to_sym => play_tasks
    end
  end

  desc "Run all serverspecs at once"
  task ':all' => all_tasks

  task :aggregate_results do
    summary = {
      :succeed => true,
      :example_count => 0,
      :failure_count => 0
    }

    $results.each do |result|
      summary[:succeed] &&= result[:exit_code] == 0
      summary[:example_count] += result[:output]['summary']['example_count']
      summary[:failure_count] += result[:output]['summary']['failure_count']
    end


    # save tonns of output to file
    File.write File.join(__dir__, 'serverspec_results.json'), JSON.pretty_generate($results)

    puts JSON.pretty_generate(summary)
    exit 1 if not summary[:succeed]
  end
end

task :default => ['spec::all']


# add JSON result aggregation as last task
if ENV['FORMAT'] == 'json'
  at_exit { Rake::Task['spec:aggregate_results'].invoke if $!.nil? }
end
