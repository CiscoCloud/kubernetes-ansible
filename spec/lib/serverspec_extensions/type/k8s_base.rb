require 'json'


# see http://arlimus.github.io/articles/custom.resource.types.in.serverspec/
# see https://ghost.ponpokopon.me/add-custom-matcher-of-serverspec/
# see http://stackoverflow.com/q/32973384
module Serverspec
  module Type
    class K8sBase < Base
      def initialize(name)
        @name = name

        super name

        @k8s_resource = {}
        @k8s_resource = JSON.parse get_k8s_resource.stdout if get_k8s_resource.success?
      end

      def present?
        get_k8s_resource.success?
      end

      protected
        def get_k8s_resource
          return @get_k8s_resource if @get_k8s_resource
          @get_k8s_resource = @runner.call_k8s_base_api(@k8s_type, @namespace, @name)
        end
    end
  end
end

include Serverspec::Type

class Specinfra::Command::Base::K8sBase < Specinfra::Command::Base
  class << self
    def call_api(type, namespace, name, *options)
      cmd = "kubectl get #{type}"
      cmd.concat " #{name}" if name
      cmd.concat " --namespace=#{namespace}" if namespace
      cmd.concat " #{options.join(' ')}" if options
      cmd.concat " --output=json"
    end
  end
end
