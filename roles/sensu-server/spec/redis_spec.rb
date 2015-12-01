require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_metrics']
  describe 'addons : Redis |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/redis-rc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'redis-rc.yaml')) }
      end

      describe k8s_replication_controller('redis-master-v1', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq 1 }
        its(:containers) { should deep_include(
          'name' => 'redis-master',
          'image' => 'kubernetes/redis:v1',
          'ports' => [{
            'containerPort' => 6379,
            'protocol' => 'TCP'
          }],
          'env' => [{
            'name' => 'MASTER',
            'value' => 'true'
          }]
        ) }
        its(:pod_count) { should eq 1 }
        its(:pods) { should deep_include(
          'status' => {
            'phase' => 'Running'
          }
        ) }
        its(:volumes) { should deep_include(
          'name' => 'data',
          'emptyDir' => {}
        ) }
        its(:labels) { should include 'name' => 'redis-master' }
        its(:labels) { should include 'version' => 'v1' }
        its(:selector) { should include 'name' => 'redis-master' }
        its(:selector) { should include 'version' => 'v1' }
      end
    end

    describe 'Service |' do
      describe file('/etc/kubernetes/manifests/redis-svc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'redis-svc.yaml')) }
      end

      describe k8s_service('redis-master', 'kube-system') do
        it { should be_present }
        its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
        its(:ports) { should deep_include(
          'port' => 6379,
          'targetPort' => 6379,
          'protocol' => 'TCP'
        ) }
        its(:labels) { should include 'name' => 'redis-master' }
        its(:selector) { should include 'name' => 'redis-master' }
      end
    end
  end
end
