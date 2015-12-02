require 'spec_helper'

describe 'addons : Main |' do
  # describe file('/etc/kubernetes/manifests/kube-system.yml') do
  #   it { should exist }
  #   it { should be_file }
  #   its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'kube-system.yml')) }
  # end

  describe k8s_namespace('kube-system') do
    it { should be_present }
    its(:status) { should include 'phase' => 'Active' }
  end
end
