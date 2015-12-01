require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_metrics']
  describe 'addons : Sensu Client |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/sensu-client-rc.yaml') do
        it { should exist }
        it { should be_file }
        # its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'sensu-client-rc.yaml')) }
      end

      describe k8s_replication_controller('sensu-client-v1', 'kube-system') do
        it { should be_present }
        its(:desired_replicas) { should eq 1 }
        its(:containers) { should deep_include(
          'name' => 'sensu-client',
          'image' => 'oslobod/sensu',
          'env' => [
            {
              'name' => 'RABBITMQ_HOST',
              'value' => 'rabbitmq-master'
            },
            {
              'name' => 'RABBITMQ_PORT',
              'value' => '5672'
            },
            {
              'name' => 'CLIENT_ADDRESS',
              'value' => CURRENT_HOST
            },
            {
              'name' => 'CLIENT_NAME',
              'value' => CURRENT_HOST
            },
            {
              'name' => 'CLIENT_SUBSCRIPTIONS',
              'value' => 'all,default,metrics'
            },
            {
              'name' => 'HOST_DEV_DIR',
              'value' => '/host_dev'
            },
            {
              'name' => 'HOST_PROC_DIR',
              'value' => '/host_proc'
            },
            {
              'name' => 'HOST_SYS_DIR',
              'value' => '/host_sys'
            }
          ]
        ) }
        its(:pod_count) { should eq 1 }
        its(:pods) { should deep_include(
          'status' => {
            'phase' => 'Running'
          }
        ) }
        its(:volumes) { should deep_include(
          'name' => 'host-dev',
          'hostPath' => {
            'path' => '/dev'
          }
        ) }
        its(:volumes) { should deep_include(
          'name' => 'host-proc',
          'hostPath' => {
            'path' => '/proc'
          }
        ) }
        its(:volumes) { should deep_include(
          'name' => 'host-sys',
          'hostPath' => {
            'path' => '/sys'
          }
        ) }
        its(:labels) { should include 'name' => 'sensu-client' }
        its(:labels) { should include 'version' => 'v1' }
        its(:selector) { should include 'name' => 'sensu-client' }
        its(:selector) { should include 'version' => 'v1' }
      end
    end
  end
end
