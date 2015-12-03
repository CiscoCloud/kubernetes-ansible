require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_metrics']
  describe 'sensu-server : Kafka |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/kafka-rc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'kafka-rc.yaml')) }
      end

      describe k8s_replication_controller('kafka-v1', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq 1 }
        its(:containers) { should deep_include(
          'name' => 'kafka',
          'image' => 'spotify/kafka',
          'ports' => [
            {
              'containerPort' => 2181,
              'name' => 'zookeeper',
              'protocol' => 'TCP'
            },
            {
              'containerPort' => 9092,
              'name' => 'kafka',
              'protocol' => 'TCP'
            }
          ]
        ) }
        its(:pod_count) { should eq 1 }
        its(:pods) { should deep_include(
          'status' => {
            'phase' => 'Running'
          }
        ) }
        its(:labels) { should include 'name' => 'kafka' }
        its(:labels) { should include 'version' => 'v1' }
        its(:selector) { should include 'name' => 'kafka' }
        its(:selector) { should include 'version' => 'v1' }
      end
    end

    describe 'Service |' do
      describe file('/etc/kubernetes/manifests/kafka-svc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'kafka-svc.yaml')) }
      end

      describe k8s_service('kafka', 'kube-system') do
        it { should be_present }
        its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
        its(:ports) { should deep_include(
          'port' => 2181,
          'targetPort' => 2181,
          'name' => 'zookeeper',
          'protocol' => 'TCP'
        ) }
        its(:ports) { should deep_include(
          'port' => 9092,
          'targetPort' => 9092,
          'name' => 'kafka',
          'protocol' => 'TCP'
        ) }
        its(:labels) { should include 'name' => 'kafka' }
        its(:selector) { should include 'name' => 'kafka' }
      end
    end
  end
end
