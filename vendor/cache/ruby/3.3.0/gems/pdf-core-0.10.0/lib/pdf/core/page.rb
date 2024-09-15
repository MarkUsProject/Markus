# frozen_string_literal: true

require_relative 'graphics_state'

module PDF
  module Core
    # Low-level representation of a PDF page
    #
    # @api private
    class Page
      # Page art box indents relative to page edges.
      #
      # @return [Hash<[:left, :right, :top, :bottom], Numeric>
      attr_accessor :art_indents

      # Page bleed box indents.
      #
      # @return [Hash<[:left, :right, :top, :bottom], Numeric>
      attr_accessor :bleeds

      # Page crop box indents.
      #
      # @return [Hash<[:left, :right, :top, :bottom], Numeric>
      attr_accessor :crops

      # Page trim box indents.
      #
      # @return [Hash<[:left, :right, :top, :bottom], Numeric>
      attr_accessor :trims

      # Page margins.
      #
      # @return [Hash<[:left, :right, :top, :bottom], Numeric>
      attr_accessor :margins

      # Owning document.
      #
      # @return [Prawn::Document]
      attr_accessor :document

      # Graphic state stack.
      #
      # @return [GraphicStateStack]
      attr_accessor :stack

      # Page content stream reference.
      #
      # @return [PDF::Core::Reference<Hash>]
      attr_writer :content

      # Page dictionary reference.
      #
      # @return [PDF::Core::Reference<Hash>]
      attr_writer :dictionary

      # A convenince constant of no indents.
      ZERO_INDENTS = {
        left: 0,
        bottom: 0,
        right: 0,
        top: 0,
      }.freeze

      # @param document [Prawn::Document]
      # @param options [Hash]
      # @option options :margins [Hash{:left, :right, :top, :bottom => Number}, nil]
      #   ({ left: 0, right: 0, top: 0, bottom: 0 }) Page margins
      # @option options :crop [Hash{:left, :right, :top, :bottom => Number}, nil] (ZERO_INDENTS)
      #   Page crop box
      # @option options :bleed [Hash{:left, :right, :top, :bottom => Number},  nil] (ZERO_INDENTS)
      #   Page bleed box
      # @option options :trims [Hash{:left, :right, :top, :bottom => Number}, nil] (ZERO_INDENTS)
      #   Page trim box
      # @option options :art_indents [Hash{:left, :right, :top, :bottom => Number}, Numeric>, nil] (ZERO_INDENTS)
      #   Page art box indents.
      # @option options :graphic_state [PDF::Core::GraphicState, nil] (nil)
      #   Initial graphic state
      # @option options :size [String, Array<Numeric>, nil] ('LETTER')
      #   Page size. A string identifies a named page size defined in
      #   {PageGeometry}. An array must be a two element array specifying width
      #   and height in points.
      # @option options :layout [:portrait, :landscape, nil] (:portrait)
      #   Page orientation.
      def initialize(document, options = {})
        @document = document
        @margins = options[:margins] || {
          left: 36,
          right: 36,
          top: 36,
          bottom: 36,
        }
        @crops = options[:crops] || ZERO_INDENTS
        @bleeds = options[:bleeds] || ZERO_INDENTS
        @trims = options[:trims] || ZERO_INDENTS
        @art_indents = options[:art_indents] || ZERO_INDENTS
        @stack = GraphicStateStack.new(options[:graphic_state])
        @size = options[:size] || 'LETTER'
        @layout = options[:layout] || :portrait

        @stamp_stream = nil
        @stamp_dictionary = nil

        @content = document.ref({})
        content << 'q' << "\n"
        @dictionary = document.ref(
          Type: :Page,
          Parent: document.state.store.pages,
          MediaBox: dimensions,
          CropBox: crop_box,
          BleedBox: bleed_box,
          TrimBox: trim_box,
          ArtBox: art_box,
          Contents: content,
        )

        resources[:ProcSet] = %i[PDF Text ImageB ImageC ImageI]
      end

      # Current graphic state.
      #
      # @return [PDF::Core::GraphicState]
      def graphic_state
        stack.current_state
      end

      # Page layout.
      #
      # @return [:portrait] if page is talled than wider
      # @return [:landscape] otherwise
      def layout
        return @layout if defined?(@layout) && @layout

        mb = dictionary.data[:MediaBox]
        if mb[3] > mb[2]
          :portrait
        else
          :landscape
        end
      end

      # Page size.
      #
      # @return [Array<Numeric>] a two-element array containing width and height
      #   of the page.
      def size
        (defined?(@size) && @size) || dimensions[2, 2]
      end

      # Are we drawing to a stamp right now?
      #
      # @return [Boolean]
      def in_stamp_stream?
        !@stamp_stream.nil?
      end

      # Draw to stamp.
      #
      # @param dictionary [PDF::Core::Reference<Hash>] stamp dictionary
      # @yield outputs to the stamp
      # @return [void]
      def stamp_stream(dictionary)
        @stamp_dictionary = dictionary
        @stamp_stream = @stamp_dictionary.stream
        graphic_stack_size = stack.stack.size

        document.save_graphics_state
        document.__send__(:freeze_stamp_graphics)
        yield if block_given?

        until graphic_stack_size == stack.stack.size
          document.restore_graphics_state
        end

        @stamp_stream = nil
        @stamp_dictionary = nil
      end

      # Current content stream. Can be either the page content stream or a stamp
      # content stream.
      #
      # @return [PDF::Core::Reference<Hash>]
      def content
        @stamp_stream || document.state.store[@content]
      end

      # Current content dictionary. Can be either the page dictionary or a stamp
      # dictionary.
      #
      # @return [PDF::Core::Reference<Hash>]
      def dictionary
        (defined?(@stamp_dictionary) && @stamp_dictionary) ||
          document.state.store[@dictionary]
      end

      # Page resources dictionary.
      #
      # @return [Hash]
      def resources
        if dictionary.data[:Resources]
          document.deref(dictionary.data[:Resources])
        else
          dictionary.data[:Resources] = {}
        end
      end

      # Fonts dictionary.
      #
      # @return [Hash]
      def fonts
        if resources[:Font]
          document.deref(resources[:Font])
        else
          resources[:Font] = {}
        end
      end

      # External objects dictionary.
      #
      # @return [Hash]
      def xobjects
        if resources[:XObject]
          document.deref(resources[:XObject])
        else
          resources[:XObject] = {}
        end
      end

      # Graphic state parameter dictionary.
      #
      # @return [Hash]
      def ext_gstates
        if resources[:ExtGState]
          document.deref(resources[:ExtGState])
        else
          resources[:ExtGState] = {}
        end
      end

      # Finalize page.
      #
      # @return [void]
      def finalize
        if dictionary.data[:Contents].is_a?(Array)
          dictionary.data[:Contents].each do |stream|
            stream.stream.compress! if document.compression_enabled?
          end
        elsif document.compression_enabled?
          content.stream.compress!
        end
      end

      # Page dimensions.
      #
      # @return [Array<Numeric>]
      def dimensions
        coords = PDF::Core::PageGeometry::SIZES[size] || size
        coords =
          case layout
          when :portrait
            coords
          when :landscape
            coords.reverse
          else
            raise PDF::Core::Errors::InvalidPageLayout,
              'Layout must be either :portrait or :landscape'
          end
        [0, 0].concat(coords)
      end

      # A rectangle, expressed in default user space units, defining the extent
      # of the page's meaningful content (including potential white space) as
      # intended by the page's creator.
      #
      # @return [Array<Numeric>]
      def art_box
        left, bottom, right, top = dimensions
        [
          left + art_indents[:left],
          bottom + art_indents[:bottom],
          right - art_indents[:right],
          top - art_indents[:top],
        ]
      end

      # Page bleed box. A rectangle, expressed in default user space units,
      # defining the region to which the contents of the page should be clipped
      # when output in a production environment.
      #
      # @return [Array<Numeric>]
      def bleed_box
        left, bottom, right, top = dimensions
        [
          left + bleeds[:left],
          bottom + bleeds[:bottom],
          right - bleeds[:right],
          top - bleeds[:top],
        ]
      end

      # A rectangle, expressed in default user space units, defining the visible
      # region of default user space. When the page is displayed or printed, its
      # contents are to be clipped (cropped) to this rectangle and then imposed
      # on the output medium in some implementation-defined manner.
      #
      # @return [Array<Numeric>]
      def crop_box
        left, bottom, right, top = dimensions
        [
          left + crops[:left],
          bottom + crops[:bottom],
          right - crops[:right],
          top - crops[:top],
        ]
      end

      # A rectangle, expressed in default user space units, defining the
      # intended dimensions of the finished page after trimming.
      #
      # @return [Array<Numeric>]
      def trim_box
        left, bottom, right, top = dimensions
        [
          left + trims[:left],
          bottom + trims[:bottom],
          right - trims[:right],
          top - trims[:top],
        ]
      end

      private

      # some entries in the Page dict can be inherited from parent Pages dicts.
      #
      # Starting with the current page dict, this method will walk up the
      # inheritance chain return the first value that is found for key
      #
      #     inherited_dictionary_value(:MediaBox)
      #     => [ 0, 0, 595, 842 ]
      #
      def inherited_dictionary_value(key, local_dict = nil)
        local_dict ||= dictionary.data

        if local_dict.key?(key)
          local_dict[key]
        elsif local_dict.key?(:Parent)
          inherited_dictionary_value(key, local_dict[:Parent].data)
        end
      end
    end
  end
end
