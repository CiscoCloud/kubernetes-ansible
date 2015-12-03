require 'spec_helper'

describe 'kubernetes-master : Secrets |' do
  describe 'ca.crt |' do
    describe file('/etc/kubernetes/ssl/ca.crt') do
      it { should exist }
      it { should be_file }
      it { should be_grouped_into 'kube' }
      it { should be_mode 440 }
    end

    describe x509_certificate('/etc/kubernetes/ssl/ca.crt') do
      it { should be_certificate }
      it { should be_valid }
      its(:validity_in_days) { should be >= 100 }
    end
  end

  describe 'server.crt |' do
    describe file('/etc/kubernetes/ssl/server.crt') do
      it { should exist }
      it { should be_file }
      it { should be_grouped_into 'kube' }
      it { should be_mode 440 }
    end

    describe x509_certificate('/etc/kubernetes/ssl/server.crt') do
      it { should be_certificate }
      it { should be_valid }
      its(:validity_in_days) { should be >= 100 }
    end
  end

  describe 'server.key |' do
    describe file('/etc/kubernetes/ssl/server.key') do
      it { should exist }
      it { should be_file }
      it { should be_grouped_into 'kube' }
      it { should be_mode 440 }
    end

    describe x509_private_key('/etc/kubernetes/ssl/server.key') do
      it { should be_valid }
      it { should have_matching_certificate('/etc/kubernetes/ssl/server.crt') }
    end
  end

  describe 'kubecfg.crt |' do
    describe file('/etc/kubernetes/ssl/kubecfg.crt') do
      it { should exist }
      it { should be_file }
      it { should be_grouped_into 'kube' }
      it { should be_mode 440 }
    end

    describe x509_certificate('/etc/kubernetes/ssl/kubecfg.crt') do
      it { should be_certificate }
      it { should be_valid }
      its(:validity_in_days) { should be >= 100 }
    end
  end

  describe 'kubecfg.key |' do
    describe file('/etc/kubernetes/ssl/kubecfg.key') do
      it { should exist }
      it { should be_file }
      it { should be_grouped_into 'kube' }
      it { should be_mode 440 }
    end

    describe x509_private_key('/etc/kubernetes/ssl/kubecfg.key') do
      it { should be_valid }
      it { should have_matching_certificate('/etc/kubernetes/ssl/kubecfg.crt') }
    end
  end

  describe file('/etc/kubernetes/users/known_users.csv') do
    it { should exist }
    it { should be_file }
    its(:content) { should match /changeme,kube,admin/ }
    its(:content) { should match /changeme,root,admin/ }
  end
end
