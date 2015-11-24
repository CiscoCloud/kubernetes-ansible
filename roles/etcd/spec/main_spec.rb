require 'spec_helper'

if INVENTORY['master']['hosts'].include? CURRENT_HOST
  describe 'etcd : Main |' do
    describe 'Service |' do
      describe package('etcd') do
        it { should be_installed }
      end

      describe file('/etc/etcd/etcd.conf') do
        it { should exist }
        it { should be_file }

        if INVENTORY['master']['hosts'].length > 1
          its(:content) { should match /ETCD_NAME=#{CURRENT_HOST}/ }
          its(:content) { should match /ETCD_INITIAL_ADVERTISE_PEER_URLS=http:\/\/#{CURRENT_HOST}:2380/ }
          # TODO add real value check here
          its(:content) { should match /ETCD_INITIAL_CLUSTER=/ }
          its(:content) { should match /ETCD_INITIAL_CLUSTER_STATE=new/ }
          its(:content) { should match /ETCD_INITIAL_CLUSTER_TOKEN=etcd-k8-cluster/ }
        else
          its(:content) { should match /ETCD_NAME=default/ }
          its(:content) { should match /ETCD_ADVERTISE_CLIENT_URLS=http:\/\/#{CURRENT_HOST}:2379/ }
        end

        its(:content) { should match /ETCD_DATA_DIR=\/var\/lib\/etcd/ }
        its(:content) { should match /ETCD_LISTEN_CLIENT_URLS=http:\/\/0.0.0.0:2379/ }
      end

      describe service('etcd') do
        it { should be_enabled }
        it { should be_running }
      end
    end

    describe 'Cluster |' do
      describe command('etcdctl member list') do
        its(:stdout) { should match /http:\/\/#{CURRENT_HOST}:2379/ }
        its(:stdout_line_count) { should eq INVENTORY['master']['hosts'].length }
      end

      describe command('etcdctl cluster-health') do
        its(:stdout) { should match /cluster is healthy/ }
      end
    end
  end
end
