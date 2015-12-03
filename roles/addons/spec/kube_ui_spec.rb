require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_ui'] and INVENTORY['master']['hosts'].first == CURRENT_HOST
  describe 'addons : Kube-UI |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/kube-ui-rc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'kube-ui-rc.yaml')) }
      end

      describe k8s_replication_controller('kube-ui-v3', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq 1 }
        its(:containers) { should deep_include(
          'name' => 'kube-ui',
          'image' => 'gcr.io/google_containers/kube-ui:v3',
          'ports' => [{
            'containerPort' => 8080,
            'protocol' => 'TCP'
          }]
        ) }
        its(:pod_count) { should eq 1 }
        its(:pods) { should deep_include(
          'status' => {
            'phase' => 'Running'
          }
        ) }
        its(:labels) { should include 'k8s-app' => 'kube-ui' }
        its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
        its(:labels) { should include 'version' => 'v3' }
        its(:selector) { should include 'k8s-app' => 'kube-ui' }
        its(:selector) { should include 'version' => 'v3' }
      end
    end

    describe 'Service |' do
      describe file('/etc/kubernetes/manifests/kube-ui-svc.yaml') do
        it { should exist }
        it { should be_file }
        its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'kube-ui-svc.yaml')) }
      end

      describe k8s_service('kube-ui', 'kube-system') do
        it { should be_present }
        its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
        its(:ports) { should deep_include(
          'port' => 80,
          'targetPort' => 8080,
          'protocol' => 'TCP'
        ) }
        its(:labels) { should include 'k8s-app' => 'kube-ui' }
        its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
        its(:labels) { should include 'kubernetes.io/name' => 'KubeUI' }
        its(:selector) { should include 'k8s-app' => 'kube-ui' }
      end
    end
  end
end
