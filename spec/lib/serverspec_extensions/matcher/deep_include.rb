RSpec::Matchers.define :deep_include do |expected|
  match do |actual|
    found = false
    actual.each do |h|
      found = h.deep_include? expected
      break if found
    end

    found
  end

  description do
    "deep include #{expected}"
  end
end
