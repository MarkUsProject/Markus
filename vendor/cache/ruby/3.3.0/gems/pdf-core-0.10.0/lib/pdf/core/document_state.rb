# frozen_string_literal: true

module PDF
  module Core
    # Low-level PDF document representation mostly for keeping intermediate
    # state while document is being constructed.
    #
    # @api private
    class DocumentState
      # @param options [Hash<Symbol, any>]
      # @option options :info [Hash] Document's information dictionary
      # @option options :print_scaling [:none, nil] Viewr preference for
      #   printing scaling
      # @option options :trailer [Hash] ({}) File trailer
      # @option options :compress [Boolean] (false) Whether to compress streams
      # @option options :encrypt [Boolean] (false) Whether to encrypt the
      #   document
      # @option options :encryption_key [String] (nil) Encryption key. Must be
      #   provided if `:encrypt` is `true`
      def initialize(options)
        normalize_metadata(options)

        @store =
          if options[:print_scaling]
            PDF::Core::ObjectStore.new(
              info: options[:info],
              print_scaling: options[:print_scaling],
            )
          else
            PDF::Core::ObjectStore.new(info: options[:info])
          end

        @version = 1.3
        @pages = []
        @page = nil
        @trailer = options.fetch(:trailer, {})
        @compress = options.fetch(:compress, false)
        @encrypt = options.fetch(:encrypt, false)
        @encryption_key = options[:encryption_key]
        @skip_encoding = options.fetch(:skip_encoding, false)
        @before_render_callbacks = []
        @on_page_create_callback = nil
      end

      # Object store
      # @return [PDF::Core::ObjectStore]
      attr_accessor :store

      # PDF version used in this document
      # @return [Float]
      attr_accessor :version

      # Document pages
      # @return [Array<PDF::Core::Page>]
      attr_accessor :pages

      # Current page
      # @return [PDF::Core::Page]
      attr_accessor :page

      # Document trailer dict
      # @return [Hash]
      attr_accessor :trailer

      # Whether to compress streams
      # @return [Boolean]
      attr_accessor :compress

      # Whether to encrypt document
      # @return [Boolean]
      attr_accessor :encrypt

      # Encryption key
      # @return [String, nil]
      attr_accessor :encryption_key

      # @deprecated Unused
      attr_accessor :skip_encoding

      # Before render callbacks
      # @return [Array<Proc>]
      attr_accessor :before_render_callbacks

      # A block to call when a new page is created
      # @return [Proc, nil]
      attr_accessor :on_page_create_callback

      # Loads pages from object store. Only does it when there are no pages
      # loaded and there are some pages in the store.
      #
      # @return [0] if no pages were loaded
      # @return [Array<PDF::Core::Page>] if pages were laded
      def populate_pages_from_store(document)
        return 0 if @store.page_count <= 0 || !@pages.empty?

        count = (1..@store.page_count)
        @pages =
          count.map { |index|
            orig_dict_id = @store.object_id_for_page(index)
            PDF::Core::Page.new(document, object_id: orig_dict_id)
          }
      end

      # Adds Prawn metadata to document info
      #
      # @param options [Hash]
      # @return [Hash] Document `info` hash
      def normalize_metadata(options)
        options[:info] ||= {}
        options[:info][:Creator] ||= 'Prawn'
        options[:info][:Producer] ||= 'Prawn'

        options[:info]
      end

      # Insert a page at the specified position.
      #
      # @param page [PDF::Core::Page]
      # @param page_number [Integer]
      # @return [void]
      def insert_page(page, page_number)
        pages.insert(page_number, page)
        store.pages.data[:Kids].insert(page_number, page.dictionary)
        store.pages.data[:Count] += 1
      end

      # Execute page creation callback if one is defined
      #
      # @param doc [Prawn::Document]
      # @return [void]
      def on_page_create_action(doc)
        on_page_create_callback[doc] if on_page_create_callback
      end

      # Executes before render callbacks
      #
      # @param _doc [Prawn::Document] Unused
      # @return [void]
      def before_render_actions(_doc)
        before_render_callbacks.each { |c| c.call(self) }
      end

      # Number of pages in the document
      #
      # @return [Integer]
      def page_count
        pages.length
      end

      # Renders document body to the output
      #
      # @param output [#<<]
      # @return [void]
      def render_body(output)
        store.each do |ref|
          ref.offset = output.size
          output <<
            if @encrypt
              ref.encrypted_object(@encryption_key)
            else
              ref.object
            end
        end
      end
    end
  end
end
