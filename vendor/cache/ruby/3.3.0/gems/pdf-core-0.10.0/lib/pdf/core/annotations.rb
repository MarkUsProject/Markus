# frozen_string_literal: true

# annotations.rb : Implements low-level annotation support for PDF
#
# Copyright November 2008, Jamis Buck. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
module PDF
  module Core
    # Provides very low-level support for annotations.
    #
    # @api private
    module Annotations
      # Adds a new annotation (section *8.4 Annotations* in PDF 1.7 spec) to the
      # current page.
      #
      # @param options [Hash] Annotation options. This is basically an `Annot`
      #   dict as decribed in the PDF spec.
      # @option options [Symbol<:Text, :Link, :FreeText, :Line, :Square,
      #   :Circle, :Polygon, :PolyLine, :Highlight, :Underline, :Squiggly,
      #   :StrikeOut, :Stamp, :Caret, :Ink, :Popup, :FileAttachment, :Sound,
      #   :Movie, :Widget, :Screen, :PrinterMark, :TrapNet, :Watermark, :3D>]
      #   :Subtype The type of annotation
      # @option options [Array<Numeric, 4>] :Rect The annotation rectangle
      # @option options [String] :Contents Text to be displayed for the
      #   annotation or, if this type of annotation does not display text, an
      #   alternate description of the annotation's contents in human-readable
      #   form.
      # @option options [PDF::Core::Reference] :P An indirect reference to the
      #   page object with which this annotation is associated.
      # @option options [String] :NM The annotation name, a text string uniquely
      #   identifying it among all the annotations on its page.
      # @option options [Date, Time, String] :M The date and time when the
      #   annotation was most recently modified
      # @option options [Integer] :F A set of flags specifying various
      #   characteristics of the annotation
      # @option options [Hash] :AP An appearance dictionary specifying how the
      #   annotation is presented visually on the page
      # @option options [Symbol] :AS The annotation's appearance state
      # @option options [Array<(Numeric, Array<Numeric>)>] :Border the
      #   characteristics of the annotation's border
      # @option options [Array<Float>] :C Color
      # @option options [Integer] :StructParent The integer key of the
      #   annotation's entry in the structural parent tree
      # @option options [Hash] :OC An optional content group or optional content
      #   membership dictionary
      #
      # @return [options]
      def annotate(options)
        state.page.dictionary.data[:Annots] ||= []
        options = sanitize_annotation_hash(options)
        state.page.dictionary.data[:Annots] << ref!(options)
        options
      end

      # A convenience method for creating `Text` annotations.
      #
      # @param rect [Array<Numeric>] An array of four numbers,
      #   describing the bounds of the annotation.
      # @param contents [String] Contents of the annotation
      #
      # @return [Hash] Annotation dictionary
      def text_annotation(rect, contents, options = {})
        options = options.merge(Subtype: :Text, Rect: rect, Contents: contents)
        annotate(options)
      end

      # A convenience method for creating `Link` annotations.
      #
      # @param rect [Array<Numeric>] An array of four numbers,
      #   describing the bounds of the annotation.
      # @param options [Hash] Should include either `:Dest` (describing the target
      #   destination, usually as a string that has been recorded in the
      #   document's `Dests` tree), or `:A` (describing an action to perform on
      #   clicking the link), or `:PA` (for describing a URL to link to).
      #
      # @return [Hash] Annotation dictionary
      def link_annotation(rect, options = {})
        options = options.merge(Subtype: :Link, Rect: rect)
        annotate(options)
      end

      private

      def sanitize_annotation_hash(options)
        options = options.merge(Type: :Annot)

        if options[:Dest].is_a?(String)
          options[:Dest] = PDF::Core::LiteralString.new(options[:Dest])
        end

        options
      end
    end
  end
end
