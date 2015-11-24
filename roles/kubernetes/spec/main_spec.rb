require 'spec_helper'

describe 'kubernates : Main |' do
  describe file('/etc/kubernetes') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/usr/libexec/kubernetes') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/etc/kubernetes/manifests') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/etc/kubernetes/config') do
    it { should exist }
    it { should be_file }
    its(:content) { should match /KUBE_ETCD_SERVERS=\"--etcd_servers=http:\/\/#{INVENTORY['master']['hosts'].first}:2379\"/ }
    its(:content) { should match /KUBE_LOGTOSTDERR="--logtostderr=true"/ }
    its(:content) { should match /KUBE_LOG_LEVEL="--v=0"/ }
    its(:content) { should match /KUBE_ALLOW_PRIV="--allow_privileged=true"/ }
    its(:content) { should match /KUBE_MASTER=\"--master=https:\/\/#{INVENTORY['master']['hosts'].first}:443\"/ }
  end
end
