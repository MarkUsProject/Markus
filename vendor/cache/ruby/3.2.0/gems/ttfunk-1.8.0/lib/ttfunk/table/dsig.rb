# frozen_string_literal: true

module TTFunk
  class Table
    # Digital Signature (`DSIG`) table.
    class Dsig < Table
      # Signature record.
      class SignatureRecord
        # Format of the signature.
        # @return [Integer]
        attr_reader :format

        # Length of signature in bytes.
        # @return [Integer]
        attr_reader :length

        # Offset to the signature block from the beginning of the table.
        # @return [Integer]
        attr_reader :offset

        # Signature PKCS#7 packet.
        # @return [String]
        attr_reader :signature

        # @param format [Integer]
        # @param length [Integer]
        # @param offset [Integer]
        # @param signature [String]
        def initialize(format, length, offset, signature)
          @format = format
          @length = length
          @offset = offset
          @signature = signature
        end
      end

      # Version umber of this table.
      # @return [Integer]
      attr_reader :version

      # Permission flags.
      # @return [Integer]
      attr_reader :flags

      # Signature records.
      # @return [Array<SignatureRecord>]
      attr_reader :signatures

      # Table tag.
      TAG = 'DSIG'

      # Encode table.
      #
      # **Note**: all signatures will be lost. This encodes an empty table
      # regardless whether the supplied table contains any signtaures or not.
      #
      # @param dsig [TTFunk::Table::Dsig]
      # @return [String]
      def self.encode(dsig)
        return unless dsig

        # Don't attempt to re-sign or anything - just use dummy values.
        # Since we're subsetting that should be permissible.
        [dsig.version, 0, 0].pack('Nnn')
      end

      # Table tag.
      #
      # @return [String]
      def tag
        TAG
      end

      private

      def parse!
        @version, num_signatures, @flags = read(8, 'Nnn')

        @signatures =
          Array.new(num_signatures) {
            format, length, sig_offset = read(12, 'N3')
            signature =
              parse_from(offset + sig_offset) {
                _, _, sig_length = read(8, 'nnN')
                read(sig_length, 'C*')
              }

            SignatureRecord.new(format, length, sig_offset, signature)
          }
      end
    end
  end
end
