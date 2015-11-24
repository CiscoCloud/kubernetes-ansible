require 'ipaddr'

RSpec::Matchers.define :be_in_subnet do |subnet|
  match do |ip|
    subnet = IPAddr.new subnet
    subnet.include? ip
  end
end
