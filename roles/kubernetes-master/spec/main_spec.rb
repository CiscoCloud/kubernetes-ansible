require 'spec_helper'

describe 'kubernetes-master : Main |' do
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
      its(:content) { should match /--api-servers=http:\/\/localhost:8080/ }
      its(:content) { should match /--register-node=false/ }
      its(:content) { should match /--allow-privileged=true/ }
      its(:content) { should match /--cluster-dns=[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/ }
      its(:content) { should match /--cluster-domain=#{ANSIBLE_GROUP_VARS['cluster_name']}/ }
      its(:content) { should match /--config=\/etc\/kubernetes\/manifests/ }
      its(:content) { should match /Restart=always/ }
      its(:content) { should match /RestartSec=10/ }

      its(:content) { should match /[Install]/ }
      its(:content) { should match /WantedBy=multi-user.target/ }
    end

    describe service('kubelet') do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe 'kube-apiserver pod |' do
    describe file('/etc/kubernetes/manifests/kube-apiserver.yml') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      # it { should be_mode 644 }
    end

    describe k8s_pod("kube-apiserver-#{CURRENT_HOST}", 'kube-system') do
      it { should be_present }
      its(:containers) { should deep_include(
        'name' => 'kube-apiserver',
        'image' => "gcr.io/google_containers/hyperkube:#{ANSIBLE_GROUP_VARS['kube_version']}",
        # 'command' => [
        #   '/hyperkube',
        #   'apiserver',
        #   '--bind-address=0.0.0.0',
        #   # FIXME add real check here
        #   '--etcd-servers=http://k-master-01:2379',
        #   '--allow-privileged=true',
        #   "--service-cluster-ip-range=#{ANSIBLE_GROUP_VARS['kube_service_addresses']}",
        #   '--secure_port=443',
        #   # TODO add real check here
        #   '--advertise-address=10.1.12.4',
        #   '--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota',
        #   '--tls-cert-file=/etc/kubernetes/ssl/server.crt',
        #   '--tls-private-key-file=/etc/kubernetes/ssl/server.key',
        #   '--client-ca-file=/etc/kubernetes/ssl/ca.crt',
        #   '--service-account-key-file=/etc/kubernetes/ssl/server.key',
        #   '--basic-auth-file=/etc/kubernetes/users/known_users.csv',
        #   '--v=3'
        # ],
        'ports' => [
          {
            'name' => 'https',
            'hostPort' => 443,
            'containerPort' => 443,
            'protocol' => 'TCP'
          },
          {
            'name' => 'local',
            'hostPort' => 8080,
            'containerPort' => 8080,
            'protocol' => 'TCP'
          }
        ]
      ) }
      its(:volumes) { should deep_include(
        'name' => 'etc-kubernetes',
        'hostPath' => {
          'path' => '/etc/kubernetes'
        }
      ) }
      its(:status) { should include 'phase' => 'Running' }
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

    describe k8s_pod("kube-proxy-#{CURRENT_HOST}", 'kube-system') do
      it { should be_present }
      its(:containers) { should deep_include(
        'name' => 'kube-proxy',
        'image' => "gcr.io/google_containers/hyperkube:#{ANSIBLE_GROUP_VARS['kube_version']}",
        'command' => [
          '/hyperkube',
          'proxy',
          '--master=http://127.0.0.1:8080'
        ]
      ) }
      its(:status) { should include 'phase' => 'Running' }
    end
  end

  describe 'kube-podmaster pod |' do
    describe file('/etc/kubernetes/manifests/kube-podmaster.yml') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      # it { should be_mode 644 }
    end

    describe k8s_pod("kube-podmaster-#{CURRENT_HOST}", 'kube-system') do
      it { should be_present }
      its(:containers) { should deep_include(
        'name' => 'scheduler-elector',
        'image' => 'gcr.io/google_containers/podmaster:1.1'
        # 'command' => [
        #   '/podmaster',
        #   # FIXME add real check here
        #   '--etcd-servers=http://k-master-01:2379',
        #   '--key=scheduler',
        #   # FIXME add real check here
        #   '--whoami=10.1.12.4',
        #   '--source-file=/src/manifests/kube-scheduler.yml',
        #   '--dest-file=/dst/manifests/kube-scheduler.yml'
        # ]
      ) }
      its(:containers) { should deep_include(
        'name' => 'controller-manager-elector',
        'image' => 'gcr.io/google_containers/podmaster:1.1'
        # 'command' => [
        #   '/podmaster',
        #   # FIXME add real check here
        #   '--etcd-servers=http://k-master-01:2379',
        #   '--key=controller',
        #   # FIXME add real check here
        #   '--whoami=10.1.12.4',
        #   '--source-file=/src/manifests/kube-controller-manager.yml',
        #   '--dest-file=/dst/manifests/kube-controller-manager.yml'
        # ]
      ) }
      its(:volumes) { should deep_include(
        'name' => 'manifest-src',
        'hostPath' => {
          'path' => '/srv/kubernetes/manifests'
        }
      ) }
      its(:volumes) { should deep_include(
        'name' => 'manifest-dst',
        'hostPath' => {
          'path' => '/etc/kubernetes/manifests'
        }
      ) }
      its(:status) { should include 'phase' => 'Running' }
    end
  end

  # describe 'kube-scheduler pod |' do
  #   describe file('/etc/kubernetes/manifests/kube-scheduler.yml') do
  #     it { should exist }
  #     it { should be_file }
  #     it { should be_owned_by 'root' }
  #     it { should be_grouped_into 'root' }
  #     # it { should be_mode 644 }
  #   end

  #   describe k8s_pod("kube-scheduler-#{CURRENT_HOST}", 'kube-system') do
  #     it { should be_present }
  #     its(:containers) { should deep_include(
  #       'name' => 'kube-scheduler',
  #       'image' => "gcr.io/google_containers/hyperkube:#{ANSIBLE_GROUP_VARS['kube_version']}",
  #       'command' => [
  #         '/hyperkube',
  #         'scheduler',
  #         '--master=http://127.0.0.1:8080'
  #       ]
  #     ) }
  #     its(:status) { should include 'phase' => 'Running' }
  #   end
  # end

  # describe 'kube-controller-manager pod |' do
  #   describe file('/etc/kubernetes/manifests/kube-controller-manager.yml') do
  #     it { should exist }
  #     it { should be_file }
  #     it { should be_owned_by 'root' }
  #     it { should be_grouped_into 'root' }
  #     # it { should be_mode 644 }
  #   end

  #   describe k8s_pod("kube-controller-manager-#{CURRENT_HOST}", 'kube-system') do
  #     it { should be_present }
  #     its(:containers) { should deep_include(
  #       'name' => 'kube-controller-manager',
  #       'image' => "gcr.io/google_containers/hyperkube:#{ANSIBLE_GROUP_VARS['kube_version']}",
  #       'command' => [
  #         '/hyperkube',
  #         'controller-manager',
  #         '--master=http://127.0.0.1:8080',
  #         '--service-account-private-key-file=/etc/kubernetes/ssl/server.key',
  #         '--root-ca-file=/etc/kubernetes/ssl/ca.crt'
  #       ]
  #     ) }
  #     its(:volumes) { should deep_include(
  #       'name' => 'etc-kubernetes',
  #       'hostPath' => {
  #         'path' => '/etc/kubernetes'
  #       }
  #     ) }
  #     its(:status) { should include 'phase' => 'Running' }
  #   end
  # end

  describe 'kube-system namespace |' do
    describe file('/etc/kubernetes/manifests/kube-system.yml') do
      it { should exist }
      it { should be_file }
      its(:content) { should eq File.read(File.join(__dir__, '..', 'templates', 'kube-system.yml')) }
    end

    describe k8s_namespace('kube-system') do
      it { should be_present }
      its(:status) { should include 'phase' => 'Active' }
    end
  end

  describe 'fluentd pod |' do
    describe file('/etc/kubernetes/manifests/fluentd-es.yaml') do
      it { should exist }
      it { should be_file }
      its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'fluentd-es.yaml')) }
    end

    describe k8s_pod("fluentd-elasticsearch-#{CURRENT_HOST}", 'kube-system') do
      it { should be_present }
      its(:containers) { should deep_include(
        'name' => 'fluentd-elasticsearch',
        'image' => 'gcr.io/google_containers/fluentd-elasticsearch:1.11',
        'args' => [
          '-qq'
        ]
      ) }
      its(:volumes) { should deep_include(
        'name' => 'varlog',
        'hostPath' => {
          'path' => '/var/log'
        }
      ) }
      its(:volumes) { should deep_include(
        'name' => 'varlibdockercontainers',
        'hostPath' => {
          'path' => '/var/lib/docker/containers'
        }
      ) }
      its(:status) { should include 'phase' => 'Running' }
    end
  end
end
