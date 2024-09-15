# :enddoc:
module Shoulda
  module Callback
    module Matchers
      module RailsVersionHelper
        class RailsVersion
          %w(< <= > >= ==).each do |operand|
            define_method operand do |version_string|
              version_int = convert_str_to_int(version_string)
              rails_version_int.send(operand, version_int)
            end
          end

          private

          def rails_version_int
            calculate_version_int(rails_major_version, rails_minor_version)
          end

          def convert_str_to_int(version_string)
            major, minor = version_string.split('.').map(&:to_i)
            calculate_version_int(major, minor)
          end

          def calculate_version_int(major, minor)
            major * 100 + minor
          end

          def rails_major_version
            version_module::MAJOR
          end

          def rails_minor_version
            version_module::MINOR
          end

          def version_module
            (defined?(::ActiveRecord) ? ::ActiveRecord : ::ActiveModel)::VERSION
          end
        end

        def rails_version
          @rails_version ||= RailsVersion.new
        end
      end
    end
  end
end
