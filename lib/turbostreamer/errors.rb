

class TurboStreamer
  module Errors
    class MergeError < ::StandardError
      def self.build(updates)
        message = "Can't merge #{updates.inspect} which isn't Hash or Array"
        new(message)
      end
    end
  end
end
