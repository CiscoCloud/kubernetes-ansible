require 'spec_helper'

if ANSIBLE_GROUP_VARS['enable_metrics']
  describe 'sensu-client : Sensu Client |' do
    describe 'ReplicationController |' do
      describe file('/etc/kubernetes/manifests/sensu-client.yaml') do
        it { should exist }
        it { should be_file }
        # its(:content) { should eq File.read(File.join(__dir__, '..', 'files', 'sensu-client.yaml')) }
      end

      # describe k8s_pod("sensu-client-#{CURRENT_HOST}", 'kube-system') do
      #   it { should be_present }
      #   its(:containers) { should deep_include(
      #     'name' => 'sensu-client',
      #     'image' => 'oslobod/sensu',
      #     'env' => [
      #       {
      #         'name' => 'RABBITMQ_HOST',
      #         'value' => 'rabbitmq-master'
      #       },
      #       {
      #         'name' => 'RABBITMQ_PORT',
      #         'value' => '5672'
      #       },
      #       {
      #         'name' => 'CLIENT_ADDRESS',
      #         'value' => CURRENT_HOST
      #       },
      #       {
      #         'name' => 'CLIENT_NAME',
      #         'value' => CURRENT_HOST
      #       },
      #       {
      #         'name' => 'CLIENT_SUBSCRIPTIONS',
      #         'value' => 'all,default,metrics'
      #       },
      #       {
      #         'name' => 'HOST_DEV_DIR',
      #         'value' => '/host_dev'
      #       },
      #       {
      #         'name' => 'HOST_PROC_DIR',
      #         'value' => '/host_proc'
      #       },
      #       {
      #         'name' => 'HOST_SYS_DIR',
      #         'value' => '/host_sys'
      #       }
      #     ]
      #   ) }
      #   its(:volumes) { should deep_include(
      #     'name' => 'host-dev',
      #     'hostPath' => {
      #       'path' => '/dev'
      #     }
      #   ) }
      #   its(:volumes) { should deep_include(
      #     'name' => 'host-proc',
      #     'hostPath' => {
      #       'path' => '/proc'
      #     }
      #   ) }
      #   its(:volumes) { should deep_include(
      #     'name' => 'host-sys',
      #     'hostPath' => {
      #       'path' => '/sys'
      #     }
      #   ) }
      #   its(:status) { should include 'phase' => 'Running' }
      # end
    end
  end
end
