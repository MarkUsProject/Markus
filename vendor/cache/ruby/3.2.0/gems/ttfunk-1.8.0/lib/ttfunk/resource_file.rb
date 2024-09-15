# frozen_string_literal: true

module TTFunk
  # Data-fork suitcases resource file
  class ResourceFile
    # Resource map
    #
    # @return [Hash]
    attr_reader :map

    # Open a resource file
    #
    # @param path [String, Pathname]
    # @yieldparam resource_file [TTFunk::ResourceFile]
    # @return [any] result of the block
    def self.open(path)
      ::File.open(path, 'rb') { |io|
        file = new(io)
        yield(file)
      }
    end

    # @param io [IO]
    def initialize(io)
      @io = io

      data_offset, map_offset, map_length = @io.read(16).unpack('NNx4N')

      @map = {}
      # skip header copy, next map handle, file reference, and attrs
      @io.pos = map_offset + 24
      type_list_offset, name_list_offset = @io.read(4).unpack('n*')

      type_list_offset += map_offset
      name_list_offset += map_offset

      @io.pos = type_list_offset
      max_index = @io.read(2).unpack1('n')
      0.upto(max_index) do
        type, max_type_index, ref_list_offset = @io.read(8).unpack('A4nn')
        @map[type] = { list: [], named: {} }

        parse_from(type_list_offset + ref_list_offset) do
          0.upto(max_type_index) do
            id, name_ofs, attr = @io.read(5).unpack('nnC')
            data_ofs = @io.read(3)
            data_ofs = data_offset + [0, data_ofs].pack('CA*').unpack1('N')
            handle = @io.read(4).unpack1('N')

            entry = {
              id: id,
              attributes: attr,
              offset: data_ofs,
              handle: handle,
            }

            if name_list_offset + name_ofs < map_offset + map_length
              parse_from(name_ofs + name_list_offset) do
                len = @io.read(1).unpack1('C')
                entry[:name] = @io.read(len)
              end
            end

            @map[type][:list] << entry
            @map[type][:named][entry[:name]] = entry if entry[:name]
          end
        end
      end
    end

    # Get resource
    #
    # @overload [](type, index = 0)
    #   @param type [String]
    #   @param inxed [Integer]
    #   @return [String]
    # @overload [](type, name)
    #   @param type [String]
    #   @param name [String]
    #   @return [String]
    def [](type, index = 0)
      if @map[type]
        collection = index.is_a?(Integer) ? :list : :named
        if @map[type][collection][index]
          parse_from(@map[type][collection][index][:offset]) do
            length = @io.read(4).unpack1('N')
            return @io.read(length)
          end
        end
      end
    end

    # Get resource names
    #
    # @param type [String]
    # @return [Array<String>]
    def resources_for(type)
      ((@map[type] && @map[type][:named]) || {}).keys
    end

    private

    def parse_from(offset)
      saved = @io.pos
      @io.pos = offset
      yield
    ensure
      @io.pos = saved
    end
  end
end
