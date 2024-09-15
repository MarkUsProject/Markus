# frozen_string_literal: true

module PDF
  module Core
    module_function

    # Serializes floating number into a string
    #
    # @param num [Numeric]
    # @return [String]
    def real(num)
      result = format('%.5f', num)
      result.sub!(/((?<!\.)0)+\z/, '')
      result
    end

    # Serializes a n array of numbers. This is specifically for use in PDF
    # content streams.
    #
    # @param array [Array<Numeric>]
    # @return [String]
    def real_params(array)
      array.map { |e| real(e) }.join(' ')
    end

    # Converts string to UTF-16BE encoding as expected by PDF.
    #
    # @param str [String]
    # @return [String]
    # @api private
    def utf8_to_utf16(str)
      (+"\xFE\xFF").force_encoding(::Encoding::UTF_16BE) <<
        str.encode(::Encoding::UTF_16BE)
    end

    # Encodes any string into a hex representation. The result is a string
    # with only 0-9 and a-f characters. That result is valid ASCII so tag
    # it as such to account for behaviour of different ruby VMs.
    #
    # @param str [String]
    # @return [String]
    def string_to_hex(str)
      str.unpack1('H*').force_encoding(::Encoding::US_ASCII)
    end

    # Characters to escape in name objects
    # @api private
    ESCAPED_NAME_CHARACTERS = (1..32).to_a + [35, 40, 41, 47, 60, 62] + (127..255).to_a

    # How to escape special characters in literal strings
    # @api private
    STRING_ESCAPE_MAP = { '(' => '\(', ')' => '\)', '\\' => '\\\\', "\r" => '\r' }.freeze

    # Serializes Ruby objects to their PDF equivalents.  Most primitive objects
    # will work as expected, but please note that Name objects are represented
    # by Ruby Symbol objects and Dictionary objects are represented by Ruby
    # hashes (keyed by symbols)
    #
    # Examples:
    #
    #     pdf_object(true)      #=> "true"
    #     pdf_object(false)     #=> "false"
    #     pdf_object(1.2124)    #=> "1.2124"
    #     pdf_object('foo bar') #=> "(foo bar)"
    #     pdf_object(:Symbol)   #=> "/Symbol"
    #     pdf_object(['foo',:bar, [1,2]]) #=> "[foo /bar [1 2]]"
    #
    # @param obj [nil, Boolean, Numeric, Array, Hash, Time, Symbol, String,
    #   PDF::Core::ByteString, PDF::Core::LiteralString,
    #   PDF::Core::NameTree::Node, PDF::Core::NameTree::Value,
    #   PDF::Core::OutlineRoot, PDF::Core::OutlineItem, PDF::Core::Reference]
    #   Object to serialise
    # @param in_content_stream [Boolean] Specifies whther to use content stream
    #   format or object format
    # @return [String]
    # @raise [PDF::Core::Errors::FailedObjectConversion]
    def pdf_object(obj, in_content_stream = false)
      case obj
      when NilClass then 'null'
      when TrueClass then 'true'
      when FalseClass then 'false'
      when Numeric
        num_string = obj.is_a?(Integer) ? String(obj) : real(obj)

        # Truncate trailing fraction zeroes
        num_string.sub!(/(\d*)((\.0*$)|(\.0*[1-9]*)0*$)/, '\1\4')
        num_string
      when Array
        "[#{obj.map { |e| pdf_object(e, in_content_stream) }.join(' ')}]"
      when PDF::Core::LiteralString
        obj = obj.gsub(/[\\\r()]/, STRING_ESCAPE_MAP)
        "(#{obj})"
      when Time
        obj = "#{obj.strftime('D:%Y%m%d%H%M%S%z').chop.chop}'00'"
        obj = obj.gsub(/[\\\r()]/, STRING_ESCAPE_MAP)
        "(#{obj})"
      when PDF::Core::ByteString
        "<#{obj.unpack1('H*')}>"
      when String
        obj = utf8_to_utf16(obj) unless in_content_stream
        "<#{string_to_hex(obj)}>"
      when Symbol
        (@symbol_str_cache ||= {})[obj] ||= (+'/') << obj.to_s.unpack('C*').map { |n|
          if ESCAPED_NAME_CHARACTERS.include?(n)
            "##{n.to_s(16).upcase}"
          else
            n.chr
          end
        }.join
      when ::Hash
        output = +'<< '
        obj
          .sort_by { |k, _v| k.to_s }
          .each do |(k, v)|
          unless k.is_a?(String) || k.is_a?(Symbol)
            raise PDF::Core::Errors::FailedObjectConversion,
              'A PDF Dictionary must be keyed by names'
          end
          output << pdf_object(k.to_sym, in_content_stream) << ' ' <<
            pdf_object(v, in_content_stream) << "\n"
        end
        output << '>>'
      when PDF::Core::Reference
        obj.to_s
      when PDF::Core::NameTree::Node, PDF::Core::OutlineRoot, PDF::Core::OutlineItem
        pdf_object(obj.to_hash)
      when PDF::Core::NameTree::Value
        "#{pdf_object(obj.name)} #{pdf_object(obj.value)}"
      else
        raise PDF::Core::Errors::FailedObjectConversion,
          "This object cannot be serialized to PDF (#{obj.inspect})"
      end
    end
  end
end
