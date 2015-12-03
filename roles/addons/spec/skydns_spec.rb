require 'spec_helper'

if ANSIBLE_GROUP_VARS['dns_setup'] and INVENTORY['master']['hosts'].first == CURRENT_HOST
  describe 'addons : SkyDNS |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/skydns-rc.yaml') do
        it { should exist }
        it { should be_file }
        # TODO add rc-file content checks
        # its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'skydns-rc.yaml')) }
      end

      describe k8s_replication_controller('kube-dns-v8', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq ANSIBLE_GROUP_VARS['dns_replicas'] }
        its(:containers) { should deep_include(
          'name' => 'etcd',
          'image' => 'gcr.io/google_containers/etcd:2.0.9',
          'volumeMounts' => [{
            'name' => 'etcd-storage',
            'mountPath' => '/var/etcd/data'
          }]
        ) }
        its(:containers) { should deep_include(
          'name' => 'kube2sky',
          'image' => 'gcr.io/google_containers/kube2sky:1.11'
        ) }
        its(:containers) { should deep_include(
          'name' => 'skydns',
          'image' => 'gcr.io/google_containers/skydns:2015-03-11-001',
          'ports' => [
            {
              'name' => 'dns',
              'containerPort' => 53,
              'protocol' => 'UDP'
            },
            {
              'name' => 'dns-tcp',
              'containerPort' => 53,
              'protocol' => 'TCP'
            }
          ]
        ) }
        its(:containers) { should deep_include(
          'name' => 'healthz',
          'image' => 'gcr.io/google_containers/exechealthz:1.0',
          'ports' => [{
            'containerPort' => 8080,
            'protocol' => 'TCP'
          }]
        ) }
        its(:pod_count) { should eq ANSIBLE_GROUP_VARS['dns_replicas'] }
        its(:pods) { should deep_include(
          'status' => {
            'phase' => 'Running'
          }
        ) }
        its(:volumes) { should deep_include(
          'name' => 'etcd-storage',
          'emptyDir' => {}
        ) }
        its(:labels) { should include 'k8s-app' => 'kube-dns' }
        its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
        its(:labels) { should include 'version' => 'v8' }
        its(:selector) { should include 'k8s-app' => 'kube-dns' }
        its(:selector) { should include 'version' => 'v8' }
      end
    end

    describe 'Service |' do
      describe file('/etc/kubernetes/manifests/skydns-svc.yaml') do
        it { should exist }
        it { should be_file }
        # TODO add svc-file content checks
        # its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'skydns-svc.yaml')) }
      end

      describe k8s_service('kube-dns', 'kube-system') do
        it { should be_present }
        its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
        its(:ports) { should deep_include(
          'name' => 'dns',
          'port' => 53,
          'targetPort' => 53,
          'protocol' => 'UDP'
        ) }
        its(:ports) { should deep_include(
          'name' => 'dns-tcp',
          'port' => 53,
          'targetPort' => 53,
          'protocol' => 'TCP'
        ) }
        its(:labels) { should include 'k8s-app' => 'kube-dns' }
        its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
        its(:labels) { should include 'kubernetes.io/name' => 'KubeDNS' }
        its(:selector) { should include 'k8s-app' => 'kube-dns' }
      end
    end
  end
end
