module Serverspec
  module Type
    class K8sService < K8sResource
      def initialize(name, namespace)
        @k8s_type = 'service'

        super name, namespace
      end

      def ip
        @k8s_resource['spec']['clusterIP']
      end

      def ports
        @k8s_resource['spec']['ports']
      end

      def to_s
        "Kubernates service \"#{@name}\" at \"#{@namespace}\""
      end
    end

    def k8s_service(name, namespace)
      K8sService.new(name, namespace)
    end
  end
end

include Serverspec::Type
