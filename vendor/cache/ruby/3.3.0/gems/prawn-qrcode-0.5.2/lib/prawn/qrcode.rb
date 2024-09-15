#--
# Copyright 2010 - 2019 Jens Hausherr
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#++
require 'prawn'
require 'rqrcode'

# :title: Prawn/QRCode
#
# :main: This is an extension for Prawn::Document to simplify rendering QR Codes.
# The module registers itself as Prawn extension upon loading.
#
# @author Jens Hausherr  <jabbrwcky@gmail.com>
# @copyright Copyright (c) 2011 -2019 Jens Hausherr
# @license Apache License, Version 2.0
#
module Prawn
  module QRCode
    # DEFAULT_DOTSIZE defines the default size for QR Code modules in multiples of 1/72 in
    DEFAULT_DOTSIZE = 1.to_f

    # Creates a QRCode with a minimal size to fit the data with the requested error correction level.
    # @since 0.5.0
    #
    # @param [string] content The string to render as content of the QR Code
    # @param [Integer] qr_version Optional number of modules to use initially. Will use more if input overflows module size (Default: 0)
    # @param [symbol] level Optional Error correction level to use. One of: (:l, :m, :h, :q), Defaults to :m
    # @param [symbol] mode Optional mode. One of (:number, :alphanumeric, :byte_8bit, :kanji), Defaults to :alphanumeric or :byte_8bit
    #
    # @return [RQRCode::QRCode] QR code that can hold the specified data with the desired error correction level
    #
    # @raise [RQRCodeCore::QRCodeRunTimeError] if the data specified will not fit in the largest QR code (QR version 40) with the given error correction level
    #
    def self.min_qrcode(content, qr_version = 0, level: :m, mode: nil, **)
      qr_version += 1
      RQRCode::QRCode.new(content, size: qr_version, level: level, mode: mode)
    rescue RQRCodeCore::QRCodeRunTimeError
      retry if qr_version < 40
      raise
    end

    # dotsize calculates the required dotsize for a QR code to be rendered with the given extent and the module size
    # @since 0.5.0
    #
    # @param [RQRCode::QRCode] qr_code QR code to render
    # @param [Integer/Float] extent Size of QR code given in pt (1 pt == 1/72 in)
    # @param [Integer] margin Width of margin as number of modules (defaults to 4 modules)
    #
    # @return [Float] size of dot in pt (1/72 in)
    def self.dotsize(qr_code, extent, margin = 4)
      extent.to_f / (2 * margin + qr_code.modules.length).to_f
    end

    # Prints a QR Code to the PDF document. The QR Code creation happens on the fly.
    #
    # @param [string] content The string to render as content of the QR Code
    # @param [symbol] level Error correction level to use. One of: (:l, :m, :h, :q), Defaults to :m
    # @param [symbol] mode Optional mode. One of (:number, :alphanumeric, :byte_8bit, :kanji), Defaults to :alphanumeric or :byte_8bit
    # @param [Array] pos  Two-element array containing the position at which the QR-Code should be rendered. Defaults to [0,cursor]
    # @param [Hash] options additional options that are passed on to Prawn::QRCode::Renderer
    #
    # @see Renderer
    #
    def print_qr_code(content, level: :m, mode: nil, pos: [0, cursor], **options)
      qr_code = Prawn::QRCode.min_qrcode(content, level: level, mode: mode)
      render_qr_code(qr_code, pos: pos, **options)
    end

    # Renders a prepared QR code (RQRCode::QRCode) int the pdf.
    # @since 0.5.0
    #
    # @param [RQRCode::QRCode] qr_code The QR code (an RQRCode::QRCode) to render
    # @param [Hash] options additional options that are passed on to Prawn::QRCode::Renderer
    #
    # @see Renderer
    #
    def render_qr_code(qr_code, **options)
      renderer = Renderer.new(qr_code, **options)
      renderer.render(self)
    end

    # QRCodeError is raised on errors specific to Prawn::QRCode
    # @since 0.5.0
    class QRCodeError < StandardError; end

    # Renderer is responsible for actually rendering a QR code to pdf
    # @since 0.5.0
    class Renderer
      attr_accessor :qr_code

      RENDER_OPTS = %I[dot pos stroke foreground_color background_color stroke_color margin align debug extent].freeze
      RENDER_OPTS.each { |attr| attr_writer attr }

      # creates a new renderer for the given QR code
      #
      # @param qr_code [RQRCode::QRCode] QR code to render
      # @param [Hash] options additional options
      # @option options [Float] :dot size of a dot in pt (1/72 in)
      # @option options [Array] :pos Two-element array containing the position at which the QR-Code should be rendered. Defaults to [0,cursor]
      # @option options [bool] :stroke whether to draw bounds around the QR Code. Defaults to true.
      # @option options [string] :foreground_color 6-digit hex string specifying foreground color; default: '000000'
      # @option options [string] :background_color 6-digit hex string specifying background color; default: 'FFFFFF'
      # @option options [string] :stroke_color 6-digit hex string specifying stroke color; default: '000000'
      # @option options [integer] :margin number of modules as margin around QRcode (default: 4)
      # @option options [float] :extent overall width/height of QR code in pt (1/72 in)
      # @option options [bool] :debug render a coordinate grid around the QRCode if true (uses Prawn#stroke_axis)
      # @option options [symbol] :align alignment within the current bounding box. Valid values are :left, :right, and :center. If set
      #                          this option overrides the horizontal positioning specified in :pos. Defaults to nil.
      #
      # Options :dot and :extent are mutually exclusive.
      #
      # @raise [QRCodeError] if both extent and dot are specified.
      def initialize(qr_code, **options)
        raise QRCodeError, 'Specify either :dot or :extent, not both' if options.key?(:dot) && options.key?(:extent)

        @stroke = true
        @qr_code = qr_code
        options.select { |k, _v| RENDER_OPTS.include?(k) }.each { |k, v| send("#{k}=", v) }
      end

      def dot
        @dot ||= Prawn::QRCode.dotsize(qr_code, @extent, margin) if defined?(@extent)
        @dot ||= DEFAULT_DOTSIZE unless defined?(@extent)
        @dot
      end

      attr_reader :stroke

      def foreground_color
        @foreground_color ||= '000000'
      end

      def background_color
        @background_color ||= 'FFFFFF'
      end

      def stroke_color
        @stroke_color ||= '000000'
      end

      def margin
        @margin ||= 4
      end

      def extent
        @extent ||= (2 * margin + qr_code.modules.length) * dot
        @extent
      end

      def margin_size
        margin * dot
      end

      def align(bounding_box)
        rlim = bounding_box.right
        case @align
        when :center
          @pos[0] = (rlim / 2) - (extent / 2)
        when :right
          @pos[0] = rlim - extent
        when :left
          @pos[0] = 0
        end
      end

      # rubocop:disable Metrics/AbcSize
      def render(pdf)
        pdf.fill_color background_color

        pos(pdf) # make sure the @pos attribute is set before calling align
        align(pdf.bounds)
        
        pdf.bounding_box(pos(pdf), width: extent, height: extent) do |_box|
          pdf.fill_color foreground_color
          margin_dist = margin * dot

          m = qr_code.modules

          pos_y = margin_dist + m.length * dot

          m.each_with_index do |row, index|
            pos_x = margin_dist
            dark_col = 0

            row.each_index do |col|
              pdf.move_to [pos_x, pos_y]
              if qr_code.qrcode.checked?(index, col)
                dark_col += 1
              else
                if dark_col > 0
                  dark_col_extent = dark_col * dot
                  pdf.fill { pdf.rectangle([pos_x - dark_col_extent, pos_y], dark_col_extent, dot) }
                  dark_col = 0
                end
              end
              pos_x += dot
            end

            pdf.fill { pdf.rectangle([pos_x - dark_col * dot, pos_y], dot * dark_col, dot) } if dark_col > 0

            pos_y -= dot
          end

          if stroke
            pdf.fill_color stroke_color
            pdf.stroke_bounds
          end
          pdf.stroke_axis(at: [-1, -1], negative_axes_length: 0, color: '0C0C0C', step_length: 50) if debug
        end
      end

      private

      attr_reader :debug

      def pos(pdf)
        @pos ||= [0, pdf.cursor]
      end
    end
  end
end

Prawn::Document.extensions << Prawn::QRCode
