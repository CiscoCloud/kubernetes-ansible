module Serverspec
  module Type
    class K8sNamespace < K8sBase
      def initialize(name)
        @k8s_type = 'namespace'

        super name
      end

      def status
        @k8s_resource['status']
      end

      def to_s
        "Kubernates namespace \"#{@name}\""
      end
    end

    def k8s_namespace(name)
      K8sNamespace.new(name)
    end
  end
end

include Serverspec::Type
