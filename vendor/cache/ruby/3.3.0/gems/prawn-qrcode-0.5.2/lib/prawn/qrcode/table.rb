require_relative 'table/cell'

module Prawn
  module QRCode
    module Table
      # create a Prawn::Table::Cell instacne that renders QR codes as table cell
      # @since 0.5.0
      #
      # @param [Hash] options for creating table cell
      # @option [String] :content string content to render as QR code
      # @option [RQRCode::QRCode] :qr_code qr_code object to render
      # @option [Prawn::QRCode::Renderer] :renderer initialized renderer (contains qr_code)
      #
      # The table cell will create a QRCode and Renderer on demand, all necessary options will be passed through
      #
      # @see Prawn::QRCode.min_qrcode
      # @see Prawn::QRCode::Renderer
      # @see Prawn::Table::Cell
      #
      # @return [Prawn::QRCode::Table::Cell] table cell instance for Prawn::Table
      def make_qrcode_cell(**options)
        Prawn::QRCode::Table::Cell.new(self, [0, cursor], options)
      end
    end
  end
end

Prawn::Document.extensions << Prawn::QRCode::Table
