module Serverspec
  module Type
    class K8sResource < K8sBase
      def initialize(name, namespace)
        @name = name
        @namespace = namespace

        super name
      end

      def labels
        @k8s_resource['metadata']['labels']
      end

      def selector
        @k8s_resource['spec']['selector']
      end
    end
  end
end

include Serverspec::Type
