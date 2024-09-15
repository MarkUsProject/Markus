require 'prawn/table/cell'

module Prawn
  module QRCode
    module Table

      # QRCode is a table cell that renders a QR code inside a table.
      # Most users will create a table via the PDF DSL method make_qr_code_cell.
      class Cell < Prawn::Table::Cell
        QR_OPTIONS = %I[content qr_code renderer level mode extent pos dot stroke margin align].freeze
        CELL_OPTS = %I[padding borders border_widths border_colors border_lines colspan rowspan at].freeze

        QR_OPTIONS.each { |attr| attr_writer attr }

        def initialize(pdf, pos, **options)
          super(pdf, pos, options.select { |k, _| CELL_OPTS.include?(k) })
          @margin = 4
          @options = options.reject { |k, _| CELL_OPTS.include?(k) }
          @options.each { |k, v| send("#{k}=", v) }
        end

        def natural_content_width
          renderer.extent
        end

        def natural_content_height
          renderer.extent
        end

        def draw_content
          renderer.render(@pdf)
        end

        def renderer
          @renderer ||= Prawn::QRCode::Renderer.new(qr_code, **@options)
        end

        def qr_code
          @qr_code = Prawn::QRCode.min_qrcode(content, **@options) unless defined?(@qr_code)
          @qr_code
        end
      end
    end
  end
end
