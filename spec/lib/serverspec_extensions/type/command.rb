module Serverspec::Type
  class Command
    def stdout_line_count
      stdout.lines.count
    end
  end
end
