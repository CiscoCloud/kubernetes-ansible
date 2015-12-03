require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_monitoring'] and INVENTORY['master']['hosts'].first == CURRENT_HOST
  describe 'addons : Monitoring |' do
    describe 'Influxdb |' do
      describe 'ReplicationController |' do
        describe file('/etc/kubernetes/manifests/influxdb-grafana-controller.yaml') do
          it { should exist }
          it { should be_file }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'influxdb-grafana-controller.yaml')) }
        end

        describe k8s_replication_controller('monitoring-influxdb-grafana-v2', 'kube-system') do
          it { should be_present }
          its(:desired_replicas) { should eq 1 }
          its(:containers) { should deep_include(
            'name' => 'influxdb',
            'image' => 'gcr.io/google_containers/heapster_influxdb:v0.4',
            'ports' => [
              {
                'hostPort' => 8083,
                'containerPort' => 8083,
                'protocol' => 'TCP'
              },
              {
                'hostPort' => 8086,
                'containerPort' => 8086,
                'protocol' => 'TCP'
              }
            ]
          ) }
          its(:containers) { should deep_include(
            'name' => 'grafana',
            'image' => 'gcr.io/google_containers/heapster_grafana:v2.1.1'
          ) }
          its(:pod_count) { should eq 1 }
          its(:pods) { should deep_include(
            'status' => {
              'phase' => 'Running'
            }
          ) }
          its(:volumes) { should deep_include(
            'name' => 'influxdb-persistent-storage',
            'emptyDir' => {}
          ) }
          its(:labels) { should include 'k8s-app' => 'influxGrafana' }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'version' => 'v2' }
          its(:selector) { should include 'k8s-app' => 'influxGrafana' }
          its(:selector) { should include 'version' => 'v2' }
        end
      end

      describe 'Service |' do
        describe file('/etc/kubernetes/manifests/influxdb-service.yaml') do
          it { should exist }
          it { should be_file }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'influxdb-service.yaml')) }
        end

        describe k8s_service('monitoring-influxdb', 'kube-system') do
          it { should be_present }
          its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
          its(:ports) { should deep_include(
            'name' => 'http',
            'port' => 8083,
            'targetPort' => 8083,
            'protocol' => 'TCP'
          ) }
          its(:ports) { should deep_include(
            'name' => 'api',
            'port' => 8086,
            'targetPort' => 8086,
            'protocol' => 'TCP'
          ) }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'kubernetes.io/name' => 'InfluxDB' }
          its(:selector) { should include 'k8s-app' => 'influxGrafana' }
        end
      end
    end

    describe 'Grafana |' do
      describe 'Service |' do
        describe file('/etc/kubernetes/manifests/grafana-service.yaml') do
          it { should exist }
          it { should be_file }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'grafana-service.yaml')) }
        end

        describe k8s_service('monitoring-grafana', 'kube-system') do
          it { should be_present }
          its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
          its(:ports) { should deep_include(
            'port' => 80,
            'targetPort' => 3000,
            'protocol' => 'TCP'
          ) }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'kubernetes.io/name' => 'Grafana' }
          its(:selector) { should include 'k8s-app' => 'influxGrafana' }
        end
      end
    end

    describe 'Heapster |' do
      describe 'ReplicationController |' do
        describe file('/etc/kubernetes/manifests/heapster-controller.yaml') do
          it { should exist }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'heapster-controller.yaml')) }
        end

        describe k8s_replication_controller('heapster-v10', 'kube-system') do
          it { should be_present }
          its(:desired_replicas) { should eq 1 }
          its(:containers) { should deep_include(
            'name' => 'heapster',
            'image' => 'gcr.io/google_containers/heapster:v0.18.2'
          ) }
          its(:pod_count) { should eq 1 }
          its(:pods) { should deep_include(
            'status' => {
              'phase' => 'Running'
            }
          ) }
          its(:labels) { should include 'k8s-app' => 'heapster' }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'version' => 'v10' }
          its(:selector) { should include 'k8s-app' => 'heapster' }
          its(:selector) { should include 'version' => 'v10' }
        end
      end

      describe 'Service |' do
        describe file('/etc/kubernetes/manifests/heapster-service.yaml') do
          it { should exist }
          its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'heapster-service.yaml')) }
        end

        describe k8s_service('heapster', 'kube-system') do
          it { should be_present }
          its(:ip) { should be_in_subnet(ANSIBLE_GROUP_VARS['kube_service_addresses']) }
          its(:ports) { should deep_include(
            'port' => 80,
            'targetPort' => 8082,
            'protocol' => 'TCP'
          ) }
          its(:labels) { should include 'kubernetes.io/cluster-service' => 'true' }
          its(:labels) { should include 'kubernetes.io/name' => 'Heapster' }
          its(:selector) { should include 'k8s-app' => 'heapster' }
        end
      end
    end
  end
end
