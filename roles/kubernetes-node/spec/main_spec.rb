require 'spec_helper'

describe 'kubernetes-node : Main |' do
  describe 'k8s binaries |' do
    describe file('/usr/bin/kubelet') do
      it { should exist }
      it { should be_file }
      it { should be_mode 753 }
    end

    describe file('/usr/bin/kubectl') do
      it { should exist }
      it { should be_file }
      it { should be_mode 753 }
    end
  end

  describe 'kubelet service |' do
    describe file('/usr/lib/systemd/system/kubelet.service') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      it { should be_mode 644 }

      its(:content) { should match /[Unit]/ }
      its(:content) { should match /After=docker.service/ }
      its(:content) { should match /Requires=docker.service/ }

      its(:content) { should match /[Service]/ }
      its(:content) { should match /ExecStart=\/usr\/bin\/kubelet/ }
      # FIXME add real test here
      # its(:content) { should match /--api-servers=https:\/\/k-master-01/ }
      its(:content) { should match /--allow-privileged=true/ }
      its(:content) { should match /--config=\/etc\/kubernetes\/manifests/ }
      its(:content) { should match /--hostname-override=#{CURRENT_HOST}/ }
      its(:content) { should match /--cluster-dns=[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ }
      its(:content) { should match /--cluster-domain=#{ANSIBLE_GROUP_VARS['cluster_name']}/ }
      its(:content) { should match /--kubeconfig=\/etc\/kubernetes\/node.kubeconfig/ }
      its(:content) { should match /--tls-cert-file=\/etc\/kubernetes\/ssl\/kubelet.crt/ }
      its(:content) { should match /--tls-private-key-file=\/etc\/kubernetes\/ssl\/kubelet.key/ }
      its(:content) { should match /--v=2/ }
      its(:content) { should match /Restart=always/ }
      its(:content) { should match /RestartSec=10/ }

      its(:content) { should match /[Install]/ }
      its(:content) { should match /WantedBy=multi-user.target/ }
    end

    describe file('/etc/kubernetes/node.kubeconfig') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      it { should be_mode 644 }

      # TODO add better file structure checks
      its(:content) { should match /kind: Config/ }
      its(:content) { should match /name: local/ }
      its(:content) { should match /certificate-authority: \/etc\/kubernetes\/ssl\/ca.crt/ }
      its(:content) { should match /name: kubelet/ }
      its(:content) { should match /client-certificate: \/etc\/kubernetes\/ssl\/kubelet.crt/ }
      its(:content) { should match /client-key: \/etc\/kubernetes\/ssl\/kubelet.key/ }
    end

    describe service('kubelet') do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe 'kube-proxy pod |' do
    describe file('/etc/kubernetes/manifests/kube-proxy.yml') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      # it { should be_mode 644 }
    end

    # describe k8s_pod("kube-proxy-#{CURRENT_HOST}", 'kube-system') do
    #   it { should be_present }
    #   its(:containers) { should deep_include(
    #     'name' => 'kube-proxy',
    #     'image' => "gcr.io/google_containers/hyperkube:#{ANSIBLE_GROUP_VARS['kube_version']}",
    #     'command' => [
    #       '/hyperkube',
    #       'proxy',
    #       "--master=https://#{INVENTORY['master']['hosts'].first}:443",
    #       '--kubeconfig=/etc/kubernetes/node.kubeconfig'
    #     ]
    #   ) }
    #   its(:volumes) { should deep_include(
    #     'name' => 'etc-kubernetes',
    #     'hostPath' => {
    #       'path' => '/etc/kubernetes'
    #     }
    #   ) }
    #   its(:status) { should include 'phase' => 'Running' }
    # end
  end

  describe 'fluentd pod |' do
    describe file('/etc/kubernetes/manifests/fluentd-es.yaml') do
      it { should exist }
      it { should be_file }
      its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'fluentd-es.yaml')) }
    end

    # describe k8s_pod("fluentd-elasticsearch-#{CURRENT_HOST}", 'kube-system') do
    #   it { should be_present }
    #   its(:containers) { should deep_include(
    #     'name' => 'fluentd-elasticsearch',
    #     'image' => 'gcr.io/google_containers/fluentd-elasticsearch:1.11',
    #     'args' => [
    #       '-qq'
    #     ]
    #   ) }
    #   its(:volumes) { should deep_include(
    #     'name' => 'varlog',
    #     'hostPath' => {
    #       'path' => '/var/log'
    #     }
    #   ) }
    #   its(:volumes) { should deep_include(
    #     'name' => 'varlibdockercontainers',
    #     'hostPath' => {
    #       'path' => '/var/lib/docker/containers'
    #     }
    #   ) }
    #   its(:status) { should include 'phase' => 'Running' }
    # end
  end
end
