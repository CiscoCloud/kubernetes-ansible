require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_metrics']
  describe 'addons : Sensu Server |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/sensu-server-rc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'sensu-server-rc.yaml')) }
      end

      describe k8s_replication_controller('sensu-server-v1', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq 1 }
        its(:containers) { should deep_include(
          'name' => 'sensu-server',
          'image' => 'oslobod/sensu',
          'env' => [
            {
              'name' => 'RABBITMQ_HOST',
              'value' => 'rabbitmq-master'
            },
            {
              'name' => 'REDIS_HOST',
              'value' => 'redis-master'
            },
            {
              'name' => 'KAFKA_HOST',
              'value' => 'kafka'
            },
            {
              'name' => 'KAFKA_TOPIC',
              'value' => 'sensu'
            },
            {
              'name' => 'API_HOST',
              'value' => 'sensu-api'
            },
            {
              'name' => 'API_PORT',
              'value' => '4567'
            }
          ]
        ) }
        its(:pod_count) { should eq 1 }
        its(:pods) { should deep_include(
          'status' => {
            'phase' => 'Running'
          }
        ) }
        its(:labels) { should include 'name' => 'sensu-server' }
        its(:labels) { should include 'version' => 'v1' }
        its(:selector) { should include 'name' => 'sensu-server' }
        its(:selector) { should include 'version' => 'v1' }
      end
    end
  end
end
