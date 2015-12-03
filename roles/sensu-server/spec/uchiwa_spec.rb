require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_metrics'] and INVENTORY['master']['hosts'].first == CURRENT_HOST
  describe 'sensu-server : Uchiwa |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/uchiwa-rc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'uchiwa-rc.yaml')) }
      end

      describe k8s_replication_controller('uchiwa-v1', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq 1 }
        its(:containers) { should deep_include(
          'name' => 'uchiwa',
          'image' => 'sstarcher/uchiwa',
          'ports' => [{
            'containerPort' => 3000,
            'protocol' => 'TCP'
          }],
          'env' => [
            {
              'name' => 'SENSU_DC_NAME',
              'value' => 'Sensu'
            },
            {
              'name' => 'SENSU_HOSTNAME',
              'value' => 'sensu-api'
            },
            {
              'name' => 'SENSU_PORT',
              'value' => '4567'
            },
            {
              'name' => 'UCHIWA_PORT',
              'value' => '3000'
            }
          ]
        ) }
        its(:pod_count) { should eq 1 }
        its(:pods) { should deep_include(
          'status' => {
            'phase' => 'Running'
          }
        ) }
        its(:labels) { should include 'k8s-app' => 'uchiwa' }
        its(:labels) { should include 'version' => 'v1' }
        its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
        its(:selector) { should include 'k8s-app' => 'uchiwa' }
        its(:selector) { should include 'version' => 'v1' }
      end
    end

    describe 'Service |' do
      describe file('/etc/kubernetes/manifests/uchiwa-svc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'uchiwa-svc.yaml')) }
      end

      describe k8s_service('uchiwa', 'kube-system') do
        it { should be_present }
        its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
        its(:ports) { should deep_include(
          'port' => 3000,
          'targetPort' => 3000,
          'protocol' => 'TCP'
        ) }
        its(:labels) { should include 'k8s-app' => 'uchiwa' }
        its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
        its(:labels) { should include 'kubernetes.io/name' => 'Uchiwa' }
        its(:selector) { should include 'k8s-app' => 'uchiwa' }
      end
    end
  end
end
