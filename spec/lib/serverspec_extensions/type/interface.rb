module Serverspec::Type
  class Interface
    def ipv4_address
      @runner.get_interface_ipv4_address_of(@name).stdout
    end
  end
end

class Specinfra::Command::Linux::Base::Interface
  class << self
    # see https://github.com/mizzy/specinfra/blob/master/lib/specinfra/command/linux/base/interface.rb#L11
    def get_ipv4_address_of(name)
      "ip -4 addr show #{name} | grep 'inet' | awk '{ print $2}'"
    end
  end
end
