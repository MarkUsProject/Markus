# frozen_string_literal: true

module PDF
  module Core
    # PDF object repository
    #
    # @api private
    class ObjectStore
      include Enumerable

      # Minimum PDF version
      # @return [Float]
      attr_reader :min_version

      # @param opts [Hash]
      # @option opts :info [Hash] Documnt info dict
      # @option opts :print_scaling [:none, nil] (nil) Print scaling viewer
      #   option
      def initialize(opts = {})
        @objects = {}
        @identifiers = []

        @info ||= ref(opts[:info] || {}).identifier
        @root ||= ref(Type: :Catalog).identifier
        if opts[:print_scaling] == :none
          root.data[:ViewerPreferences] = { PrintScaling: :None }
        end
        if pages.nil?
          root.data[:Pages] = ref(Type: :Pages, Count: 0, Kids: [])
        end
      end

      # Wrap an object into a reference.
      #
      # @param data [Hash, Array, Numeric, String, Symbol, Date, Time, nil]
      #   object data
      # @return [Reference]
      def ref(data)
        push(size + 1, data)
      end

      # Document info dict reference
      #
      # @return [Reference]
      def info
        @objects[@info]
      end

      # Document root dict reference
      #
      # @return [Reference]
      def root
        @objects[@root]
      end

      # Document pages reference
      #
      # @return [Reference]
      def pages
        root.data[:Pages]
      end

      # Number of pages in the document
      #
      # @return [Integer]
      def page_count
        pages.data[:Count]
      end

      # Adds the given reference to the store and returns the reference object.
      # If the object provided is not a PDF::Core::Reference, one is created
      # from the arguments provided.
      #
      # @overload push(reference)
      #   @param reference [Reference]
      #   @return [reference]
      # @overload push(id, data)
      #   @param id [Integer] reference identifier
      #   @param data [Hash, Array, Numeric, String, Symbol, Date, Time, nil]
      #     object data
      #   @return [Reference] - the added reference
      def push(*args)
        reference =
          if args.first.is_a?(PDF::Core::Reference)
            args.first
          else
            PDF::Core::Reference.new(*args)
          end

        @objects[reference.identifier] = reference
        @identifiers << reference.identifier
        reference
      end

      alias << push

      # Iterate over document object references.
      #
      # @yieldparam ref [Reference]
      # @return [void]
      def each
        @identifiers.each do |id|
          yield(@objects[id])
        end
      end

      # Get object reference by its identifier.
      #
      # @param id [Integer] object identifier
      # @return [Reference]
      def [](id)
        @objects[id]
      end

      # Number of object references in the document.
      #
      # @return [Integer]
      def size
        @identifiers.size
      end
      alias length size

      # Get page reference identifier by page number.Pages are indexed starting
      # at 1 (**not 0**).
      #
      # @example
      #   !!!ruby
      #   object_id_for_page(1)
      #   #=> 5
      #   object_id_for_page(10)
      #   #=> 87
      #   object_id_for_page(-11)
      #   #=> 17
      #
      # @param page [Integer] page number
      # @return [Integer] page object identifier
      def object_id_for_page(page)
        page -= 1 if page.positive?
        flat_page_ids = get_page_objects(pages).flatten
        flat_page_ids[page]
      end

      private

      # returns an array with the object IDs for all pages
      def get_page_objects(pages)
        pages.data[:Kids].map(&:identifier)
      end
    end
  end
end
