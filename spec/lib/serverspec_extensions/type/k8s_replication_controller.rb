require 'json'

module Serverspec
  module Type
    class K8sReplicationController < K8sResource
      def initialize(name, namespace)
        @k8s_type = 'replicationController'

        super name, namespace
      end

      def containers
        @k8s_resource['spec']['template']['spec']['containers']
      end

      def desired_replicas
        @k8s_resource['spec']['replicas']
      end

      def pod_count
        pods.length
      end

      def pods
        return @pods if @pods

        selector_query = selector.map{|k,v| "#{k}=#{v}"}.join(',')
        get_pods_command = @runner.call_k8s_base_api("pods", @namespace, '', "--selector='#{selector_query}'")

        pods = {}
        pods = JSON.parse get_pods_command.stdout if get_pods_command.success?

        @pods = pods['items']
      end

      def to_s
        "Kubernates replication controller \"#{@name}\" at \"#{@namespace}\""
      end

      def volumes
        @k8s_resource['spec']['template']['spec']['volumes']
      end
    end

    def k8s_replication_controller(name, namespace)
      K8sReplicationController.new(name, namespace)
    end
  end
end

include Serverspec::Type
