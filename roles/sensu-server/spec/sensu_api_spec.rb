require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_metrics'] and INVENTORY['master']['hosts'].first == CURRENT_HOST
  describe 'sensu-server : Sensu API |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/sensu-api-rc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'sensu-api-rc.yaml')) }
      end

      describe k8s_replication_controller('sensu-api-v1', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq 1 }
        its(:containers) { should deep_include(
          'name' => 'sensu-api',
          'image' => 'oslobod/sensu',
          'ports' => [{
            'containerPort' => 4567,
            'protocol' => 'TCP'
          }],
          'env' => [
            {
              'name' => 'RABBITMQ_HOST',
              'value' => 'rabbitmq-master'
            },
            {
              'name' => 'RABBITMQ_PORT',
              'value' => '5672'
            },
            {
              'name' => 'REDIS_HOST',
              'value' => 'redis-master'
            },
            {
              'name' => 'REDIS_PORT',
              'value' => '6379'
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
        its(:labels) { should include 'name' => 'sensu-api' }
        its(:labels) { should include 'version' => 'v1' }
        its(:selector) { should include 'name' => 'sensu-api' }
        its(:selector) { should include 'version' => 'v1' }
      end
    end

    describe 'Service |' do
      describe file('/etc/kubernetes/manifests/sensu-api-svc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'sensu-api-svc.yaml')) }
      end

      describe k8s_service('sensu-api', 'kube-system') do
        it { should be_present }
        its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
        its(:ports) { should deep_include(
          'port' => 4567,
          'targetPort' => 4567,
          'protocol' => 'TCP'
        ) }
        its(:labels) { should include 'name' => 'sensu-api' }
        its(:selector) { should include 'name' => 'sensu-api' }
      end
    end
  end
end
