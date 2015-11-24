require 'spec_helper'

describe 'addons : Main |' do
  describe file('/etc/kubernetes/manifests/kube-system.yaml') do
    it { should exist }
    it { should be_file }
    its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'kube-system.yaml')) }
  end

  describe k8s_namespace('kube-system') do
    it { should be_present }
    its(:status) { should include 'phase' => 'Active' }
  end

  describe file('/etc/kubernetes/tokens/known_tokens.csv') do
    it { should exist }
    it { should be_file }
    it { should be_grouped_into 'kube-cert' }
    it { should be_owned_by 'kube' }
    it { should be_mode 440 }
  end
end
