# frozen_string_literal: true

module Browser
  class Device
    class Unknown < Base
      def id
        :unknown_device
      end

      def name
        "Unknown"
      end

      def match?
        true
      end
    end
  end
end
