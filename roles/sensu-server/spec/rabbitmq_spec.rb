require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_metrics']
  describe 'sensu-server : RabbitMQ |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/rabbitmq-rc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'rabbitmq-rc.yaml')) }
      end

      describe k8s_replication_controller('rabbitmq-master-v1', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq 1 }
        its(:containers) { should deep_include(
          'name' => 'rabbitmq-master',
          'image' => 'bijukunjummen/rabbitmq-server',
          'ports' => [
            {
              'containerPort' => 5672,
              'name' => 'amqp',
              'protocol' => 'TCP'
            },
            {
              'containerPort' => 25672,
              'name' => 'amqp-cluster',
              'protocol' => 'TCP'
            },
            {
              'containerPort' => 4369,
              'name' => 'epmd',
              'protocol' => 'TCP'
            },
            {
              'containerPort' => 44001,
              'name' => 'epmd-cluster',
              'protocol' => 'TCP'
            },
            {
              'containerPort' => 15672,
              'name' => 'management',
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
        its(:labels) { should include 'name' => 'rabbitmq-master' }
        its(:labels) { should include 'version' => 'v1' }
        its(:selector) { should include 'name' => 'rabbitmq-master' }
        its(:selector) { should include 'version' => 'v1' }
      end
    end

    describe 'Service |' do
      describe file('/etc/kubernetes/manifests/rabbitmq-svc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'rabbitmq-svc.yaml')) }
      end

      describe k8s_service('rabbitmq-master', 'kube-system') do
        it { should be_present }
        its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
        its(:ports) { should deep_include(
          'port' => 5672,
          'targetPort' => 5672,
          'name' => 'amqp',
          'protocol' => 'TCP'
        ) }
        its(:ports) { should deep_include(
          'port' => 4369,
          'targetPort' => 4369,
          'name' => 'epmd',
          'protocol' => 'TCP'
        ) }
        its(:ports) { should deep_include(
          'port' => 44001,
          'targetPort' => 44001,
          'name' => 'epmd-cluser',
          'protocol' => 'TCP'
        ) }
        its(:ports) { should deep_include(
          'port' => 25672,
          'targetPort' => 25672,
          'name' => 'amqp-cluster',
          'protocol' => 'TCP'
        ) }
        its(:ports) { should deep_include(
          'port' => 15672,
          'targetPort' => 15672,
          'name' => 'management',
          'protocol' => 'TCP'
        ) }
        its(:labels) { should include 'name' => 'rabbitmq-master' }
        its(:selector) { should include 'name' => 'rabbitmq-master' }
      end
    end
  end
end
