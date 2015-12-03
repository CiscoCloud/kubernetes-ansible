require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_logging'] and INVENTORY['master']['hosts'].first == CURRENT_HOST
  describe 'addons : Logging |' do
    describe 'Kibana |' do
      describe 'ReplicationController |' do
        describe file('/etc/kubernetes/manifests/kibana-rc.yaml') do
          it { should exist }
          it { should be_file }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'kibana-rc.yaml')) }
        end

        describe k8s_replication_controller('kibana-logging-v1', 'kube-system') do
          it { should be_present }
          its(:desired_replicas) { should eq 1 }
          its(:containers) { should deep_include(
            'name' => 'kibana-logging',
            'image' => 'gcr.io/google_containers/kibana:1.3',
            'ports' => [{
              'name' => 'ui',
              'containerPort' => 5601,
              'protocol' => 'TCP'
            }]
          ) }
          its(:pod_count) { should eq 1 }
          its(:pods) { should deep_include(
            'status' => {
              'phase' => 'Running'
            }
          ) }
          its(:labels) { should include 'k8s-app' => 'kibana-logging' }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'version' => 'v1' }
          its(:selector) { should include 'k8s-app' => 'kibana-logging' }
          its(:selector) { should include 'version' => 'v1' }
        end
      end

      describe 'Service |' do
        describe file('/etc/kubernetes/manifests/kibana-svc.yaml') do
          it { should exist }
          it { should be_file }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'kibana-svc.yaml')) }
        end

        describe k8s_service('kibana-logging', 'kube-system') do
          it { should be_present }
          its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
          its(:ports) { should deep_include(
            'port' => 5601,
            'targetPort' => 'ui',
            'protocol' => 'TCP'
          ) }
          its(:labels) { should include 'k8s-app' => 'kibana-logging' }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'kubernetes.io/name' => 'Kibana' }
          its(:selector) { should include 'k8s-app' => 'kibana-logging' }
        end
      end
    end

    describe 'ES |' do
      describe 'ReplicationController |' do
        describe file('/etc/kubernetes/manifests/es-rc.yaml') do
          it { should exist }
          it { should be_file }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'es-rc.yaml')) }
        end

        describe k8s_replication_controller('elasticsearch-logging-v1', 'kube-system') do
          it { should be_present }
          its(:desired_replicas) { should eq 2 }
          its(:containers) { should deep_include(
            'name' => 'elasticsearch-logging',
            'image' => 'gcr.io/google_containers/elasticsearch:1.7',
            'ports' => [
              {
                'name' => 'db',
                'containerPort' => 9200,
                'protocol' => 'TCP'
              },
              {
                'name' => 'transport',
                'containerPort' => 9300,
                'protocol' => 'TCP'
              }
            ],
            'volumeMounts' => [{
              'name' => 'es-persistent-storage',
              'mountPath' => '/data'
            }]
          ) }
          its(:pod_count) { should eq 2 }
          its(:pods) { should deep_include(
            'status' => {
              'phase' => 'Running'
            }
          ) }
          its(:volumes) { should deep_include(
            'name' => 'es-persistent-storage',
            'emptyDir' => {}
          ) }
          its(:labels) { should include 'k8s-app' => 'elasticsearch-logging' }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'version' => 'v1' }
          its(:selector) { should include 'k8s-app' => 'elasticsearch-logging' }
          its(:selector) { should include 'version' => 'v1' }
        end
      end

      describe 'Service |' do
        describe file('/etc/kubernetes/manifests/es-svc.yaml') do
          it { should exist }
          it { should be_file }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'es-svc.yaml')) }
        end

        describe k8s_service('elasticsearch-logging', 'kube-system') do
          it { should be_present }
          its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
          its(:ports) { should deep_include(
            'port' => 9200,
            'targetPort' => 'db',
            'protocol' => 'TCP'
          ) }
          its(:labels) { should include 'k8s-app' => 'elasticsearch-logging' }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'kubernetes.io/name' => 'Elasticsearch' }
          its(:selector) { should include 'k8s-app' => 'elasticsearch-logging' }
        end
      end
    end
  end
end
