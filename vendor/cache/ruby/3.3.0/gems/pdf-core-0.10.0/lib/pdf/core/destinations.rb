# frozen_string_literal: true

module PDF
  module Core
    # Implements destination support for PDF
    #
    # @api private
    module Destinations
      # The maximum number of children to fit into a single node in the Dests
      # tree.
      #
      # @private
      NAME_TREE_CHILDREN_LIMIT = 20

      # The `:Dests` name tree in the Name dictionary. This name tree is used to
      # store named destinations (PDF 1.7 spec 8.2.1). (For more on name trees,
      # see section 3.8.5 in the PDF 1.7 spec.)
      #
      # @return [PDF::Core::Reference<PDF::Core::NameTree::Node>]
      # @see Prawn::Document::Internal#names
      def dests
        names.data[:Dests] ||= ref!(
          PDF::Core::NameTree::Node.new(self, NAME_TREE_CHILDREN_LIMIT),
        )
      end

      # Adds a new destination to the Dests name tree.
      #
      # @param name [Symbol] Destination name
      # @param reference [PDF::Core::Reference, Array, Hash] Destination
      #   definition, will be converted into a {PDF::Core::Reference} if it is
      #   not already one.
      # @return [void]
      # @see #dests
      def add_dest(name, reference)
        reference = ref!(reference) unless reference.is_a?(PDF::Core::Reference)
        dests.data.add(name, reference)
      end

      # Builds a Dest specification for a specific location (and optional zoom
      # level).
      #
      # @param left [Numeric]
      # @param top [Numeric]
      # @param zoom [Numeric]
      # @param dest_page [PDF::Core::Page]
      # @return [Array(PDF::Core::Reference, :XYZ, Numeric, Numeric, [Numeric, null])] a Dest
      #   specification for a specific location
      def dest_xyz(left, top, zoom = nil, dest_page = page)
        [dest_page.dictionary, :XYZ, left, top, zoom]
      end

      # builds a Dest specification that will fit the given page into the
      # viewport.
      #
      # @param dest_page [PDF::Core::Page]
      # @return [Array(PDF::Core::Reference, :Fit)] a Dest specification for a page fitting
      #   viewport
      def dest_fit(dest_page = page)
        [dest_page.dictionary, :Fit]
      end

      # Builds a Dest specification that will fit the given page horizontally
      # into the viewport, aligned vertically at the given top coordinate.
      #
      # @param top [Numeric]
      # @param dest_page [PDF::Core::Page]
      # @return [Array(PDF::Core::Reference, :FitH, Numeric)] a Dest specification for a page
      #   content fitting horizontally at a given top coordinate
      def dest_fit_horizontally(top, dest_page = page)
        [dest_page.dictionary, :FitH, top]
      end

      # Build a Dest specification that will fit the given page vertically
      # into the viewport, aligned horizontally at the given left coordinate.
      #
      # @param left [Numeric]
      # @param dest_page [PDF::Core::Page]
      # @return [Array(Hash, :FitV, Numeric)] a Dest specification for a page
      #   content fitting vertically at a given left coordinate
      def dest_fit_vertically(left, dest_page = page)
        [dest_page.dictionary, :FitV, left]
      end

      # Builds a Dest specification that will fit the given rectangle into the
      # viewport, for the given page.
      #
      # @param left [Numeric]
      # @param bottom [Numeric]
      # @param right [Numeric]
      # @param top [Numeric]
      # @param dest_page [PDF::Core::Page]
      # @return [Array(Hash, :FitR, Numeric, Numeric, Numeric, Numeric)]
      #   a Dest specification for a page fitting the given rectangle in the
      #   viewport
      def dest_fit_rect(left, bottom, right, top, dest_page = page)
        [dest_page.dictionary, :FitR, left, bottom, right, top]
      end

      # Builds a Dest specification that will fit the given page's bounding box
      # into the viewport.
      #
      # @param dest_page [PDF::Core::Page]
      # @return [Array(PDF::Core::Reference, :FitB)] a Dest specification for a page fitting
      #   bounding box into viewport
      def dest_fit_bounds(dest_page = page)
        [dest_page.dictionary, :FitB]
      end

      # Same as {#dest_fit_horizontally}, but works on the page's bounding box
      # instead of the entire page.
      #
      # @param top [Numeric]
      # @param dest_page [PDF::Core::Page]
      # @return [Array(PDF::Core::Reference, :FitBH, Numeric)] a Dest specification for a page
      #   bounding box fitting horizontally at a given top coordinate
      def dest_fit_bounds_horizontally(top, dest_page = page)
        [dest_page.dictionary, :FitBH, top]
      end

      # Same as {#dest_fit_vertically}, but works on the page's bounding box
      # instead of the entire page.
      #
      # @param left [Numeric]
      # @param dest_page [PDF::Core::Page]
      # @return [Array(PDF::Core::Reference, :FitBV, Numeric)] a Dest specification for a page
      #   bounding box fitting vertically at a given top coordinate
      def dest_fit_bounds_vertically(left, dest_page = page)
        [dest_page.dictionary, :FitBV, left]
      end
    end
  end
end
