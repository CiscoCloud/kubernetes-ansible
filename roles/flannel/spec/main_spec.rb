require 'spec_helper'

describe 'flannel : Main | 'do
  describe 'Service |' do
    describe package('flannel') do
      it { should be_installed }
    end

    describe file('/etc/sysconfig/flanneld') do
      it { should exist }
      it { should be_file }

      its(:content) { should match /FLANNEL_ETCD="http:\/\/#{INVENTORY['master']['hosts'].first}:2379"/ }
      its(:content) { should match /FLANNEL_ETCD_KEY="\/#{ANSIBLE_GROUP_VARS['cluster_name']}\/network"/ }
      its(:content) { should match /FLANNEL_OPTIONS="-iface=eth0"/ }
    end

    describe service('flanneld') do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe 'Interface |' do
    describe interface('flannel.1') do
      it { should exist }
      its(:ipv4_address) { should be_in_subnet("#{ANSIBLE_GROUP_VARS['overlay_network_subnet']}/#{ANSIBLE_GROUP_VARS['overlay_network_prefix']}") }
    end
  end
end
