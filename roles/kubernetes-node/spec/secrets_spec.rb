require 'spec_helper'

describe 'kubernetes-node : Secrets |' do
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

  describe 'kubelet.crt |' do
    describe file('/etc/kubernetes/ssl/kubelet.crt') do
      it { should exist }
      it { should be_file }
      it { should be_grouped_into 'kube' }
      it { should be_mode 440 }
    end

    describe x509_certificate('/etc/kubernetes/ssl/kubelet.crt') do
      it { should be_certificate }
      it { should be_valid }
      its(:validity_in_days) { should be >= 100 }
    end
  end

  describe 'kubelet.key |' do
    describe file('/etc/kubernetes/ssl/kubelet.key') do
      it { should exist }
      it { should be_file }
      it { should be_grouped_into 'kube' }
      it { should be_mode 440 }
    end

    describe x509_private_key('/etc/kubernetes/ssl/kubelet.key') do
      it { should be_valid }
      it { should have_matching_certificate('/etc/kubernetes/ssl/kubelet.crt') }
    end
  end
end
