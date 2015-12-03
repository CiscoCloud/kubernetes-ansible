module Serverspec
  module Type
    class K8sPod < K8sResource
      def initialize(name, namespace)
        @k8s_type = 'pod'

        super name, namespace
      end

      def containers
        @k8s_resource['spec']['containers']
      end

      def to_s
        "Kubernates pod \"#{@name}\" at \"#{@namespace}\""
      end

      def status
        @k8s_resource['status']
      end

      def volumes
        @k8s_resource['spec']['volumes']
      end
    end

    def k8s_pod(name, namespace)
      K8sPod.new(name, namespace)
    end
  end
end

include Serverspec::Type
