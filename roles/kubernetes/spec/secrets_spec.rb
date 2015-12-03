require 'spec_helper'

describe 'kubernates : Secrets |' do
  describe group('kube') do
    it { should exist }
  end

  describe user('centos') do
    it { should exist }
    it { should belong_to_group 'kube' }
  end
end
