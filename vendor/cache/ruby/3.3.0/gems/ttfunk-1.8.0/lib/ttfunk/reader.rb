# frozen_string_literal: true

module TTFunk
  # Helper methods to read form file content.
  # @api rpivate
  module Reader
    private

    def io
      @file.contents
    end

    def read(bytes, format)
      io.read(bytes).unpack(format)
    end

    def read_signed(count)
      read(count * 2, 'n*').map { |i| to_signed(i) }
    end

    def to_signed(number)
      number >= 0x8000 ? -((number ^ 0xFFFF) + 1) : number
    end

    def parse_from(position)
      saved = io.pos
      io.pos = position
      result = yield(position)
      io.pos = saved
      result
    end

    # For debugging purposes
    def hexdump(string)
      bytes = string.unpack('C*')
      bytes.each_with_index do |c, i|
        printf('%02X', c)
        if ((i + 1) % 16).zero?
          puts
        elsif ((i + 1) % 8).zero?
          print('  ')
        else
          print(' ')
        end
      end
      puts if (bytes.length % 16) != 0
    end
  end
end
