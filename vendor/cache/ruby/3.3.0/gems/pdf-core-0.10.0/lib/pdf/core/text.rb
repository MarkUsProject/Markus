# frozen_string_literal: true

# prawn/core/text.rb : Implements low level text helpers for Prawn
#
# Copyright January 2010, Daniel Nelson.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module PDF
  module Core
    # Low-level text rendering.
    module Text
      # Valid options of text drawing.
      # These should be used as a base. Extensions may build on this list
      VALID_OPTIONS = %i[kerning size style].freeze

      # text rendering modes
      MODES = {
        fill: 0,
        stroke: 1,
        fill_stroke: 2,
        invisible: 3,
        fill_clip: 4,
        stroke_clip: 5,
        fill_stroke_clip: 6,
        clip: 7,
      }.freeze

      # Sygnals that a font doesn't have a name.
      class BadFontFamily < StandardError
        def initialize(message = 'Bad font family')
          super
        end
      end

      # @deprecated
      attr_reader :skip_encoding

      # Low level call to set the current font style and extract text options
      # from an options hash. Should be called from within a save_font block
      #
      # @param options [Hash]
      # @option options :style [Symbol, String]
      # @option options :kerning [Boolean]
      # @option options :size [Numeric]
      # @return [void]
      def process_text_options(options)
        if options[:style]
          raise BadFontFamily unless font.family

          font(font.family, style: options[:style])
        end

        # must compare against false to keep kerning on as default
        unless options[:kerning] == false
          options[:kerning] = font.has_kerning_data?
        end

        options[:size] ||= font_size
      end

      # Retrieve the current default kerning setting.
      #
      # Defaults to `true`.
      #
      # @return [Boolean]
      def default_kerning?
        return true unless defined?(@default_kerning)

        @default_kerning
      end

      # Call with a boolean to set the document-wide kerning setting. This can
      # be overridden using the :kerning text option when drawing text or a text
      # box.
      #
      # @example
      #   pdf.default_kerning = false
      #   pdf.text('hello world')                # text is not kerned
      #   pdf.text('hello world', kerning: true) # text is kerned
      #
      # @param value [Boolean]
      # @return [void]
      def default_kerning(value)
        @default_kerning = value
      end

      alias default_kerning= default_kerning

      # Call with no argument to retrieve the current default leading.
      #
      # Call with a number to set the document-wide text leading. This can be
      # overridden using the :leading text option when drawing text or a text
      # box.
      #
      # @example
      #   pdf.default_leading = 7
      #   pdf.text('hello world')             # a leading of 7 is used
      #   pdf.text('hello world', leading: 0) # a leading of 0 is used
      #
      # Defaults to 0.
      #
      # @param number [Numeric]
      # @return [Numeric]
      def default_leading(number = nil)
        if number.nil?
          (defined?(@default_leading) && @default_leading) || 0
        else
          @default_leading = number
        end
      end

      alias default_leading= default_leading

      # Call with no argument to retrieve the current text direction.
      #
      # Call with a symbol to set the document-wide text direction. This can be
      # overridden using the :direction text option when drawing text or a text
      # box.
      #
      # @example
      #   pdf.text_direction = :rtl
      #   pdf.text('hello world')                  # prints 'dlrow olleh'
      #   pdf.text('hello world', direction: :ltr) # prints 'hello world'
      #
      # Valid directions are:
      #
      # * `:ltr` -- left-to-right (default)
      # * `:rtl` -- right-to-left
      #
      # Side effects:
      #
      # * When printing left-to-right, the default text alignment is `:left`
      # * When printing right-to-left, the default text alignment is `:right`
      #
      # @param direction [:ltr, :rtl]
      # @return [:ltr]
      # @return [:rtl]
      def text_direction(direction = nil)
        if direction.nil?
          (defined?(@text_direction) && @text_direction) || :ltr
        else
          @text_direction = direction
        end
      end

      alias text_direction= text_direction

      # Call with no argument to retrieve the current fallback fonts.
      #
      # Call with an array of font names. Each name must be the name of an AFM
      # font or the name that was used to register a family of TTF fonts (see
      # Prawn::Document#font_families). If present, then each glyph will be
      # rendered using the first font that includes the glyph, starting with the
      # current font and then moving through :fallback_fonts from left to right.
      #
      # Call with an empty array to turn off fallback fonts.
      #
      # @example
      #   file = "#{Prawn::DATADIR}/fonts/gkai00mp.ttf"
      #   font_families['Kai'] = {
      #     normal: { file: file, font: 'Kai' }
      #   }
      #   file = "#{Prawn::DATADIR}/fonts/Action Man.dfont"
      #   font_families['Action Man'] = {
      #     normal: { file: file, font: 'ActionMan' },
      #   }
      #   fallback_fonts ['Times-Roman', 'Kai']
      #   font 'Action Man'
      #   text 'hello ƒ 你好'
      #   # hello prints in Action Man
      #   # ƒ prints in Times-Roman
      #   # 你好 prints in Kai
      #
      #   fallback_fonts [] # clears document-wide fallback fonts
      #
      # Side effects:
      #
      # * Increased overhead when fallback fonts are declared as each glyph is
      #   checked to see whether it exists in the current font
      #
      # @param fallback_fonts [Array<String>]
      # @return [Array<String>]
      def fallback_fonts(fallback_fonts = nil)
        if fallback_fonts.nil?
          (defined?(@fallback_fonts) && @fallback_fonts) || []
        else
          @fallback_fonts = fallback_fonts
        end
      end

      alias fallback_fonts= fallback_fonts

      # Call with no argument to retrieve the current text rendering mode.
      #
      # Call with a symbol and block to temporarily change the current
      # text rendering mode.
      #
      # Valid modes are:
      #
      # * `:fill`             - fill text (default)
      # * `:stroke`           - stroke text
      # * `:fill_stroke`      - fill, then stroke text
      # * `:invisible`        - invisible text
      # * `:fill_clip`        - fill text then add to path for clipping
      # * `:stroke_clip`      - stroke text then add to path for clipping
      # * `:fill_stroke_clip` - fill then stroke text, then add to path for
      #                         clipping
      # * `:clip`             - add text to path for clipping
      #
      # @example
      #   pdf.text_rendering_mode(:stroke) do
      #     pdf.text('Outlined Text')
      #   end
      #
      # @param mode [Symbol]
      # @yield Temporariliy set text rendering mode
      # @return [Symbol] if called withouth mode
      # @return [void] otherwise
      def text_rendering_mode(mode = nil, &block)
        if mode.nil?
          return (defined?(@text_rendering_mode) && @text_rendering_mode) || :fill
        end

        unless MODES.key?(mode)
          raise ArgumentError,
            "mode must be between one of #{MODES.keys.join(', ')} (#{mode})"
        end

        if text_rendering_mode == mode
          yield
        else
          wrap_and_restore_text_rendering_mode(mode, &block)
        end
      end

      # Forget previously set text rendering mode.
      #
      # @return [void]
      def forget_text_rendering_mode!
        @text_rendering_mode = :unknown
      end

      # Increases or decreases the space between characters.
      # For horizontal text, a positive value will increase the space.
      # For vertical text, a positive value will decrease the space.
      #
      # Call with no arguments to retrieve current character spacing.
      #
      # @param amount [Numeric]
      # @yield Temporarily set character spacing
      # @return [Numeric] if called without amount
      # @return [void] otherwise
      def character_spacing(amount = nil, &block)
        if amount.nil?
          return (defined?(@character_spacing) && @character_spacing) || 0
        end

        if character_spacing == amount
          yield
        else
          wrap_and_restore_character_spacing(amount, &block)
        end
      end

      # Increases or decreases the space between words.
      # For horizontal text, a positive value will increase the space.
      # For vertical text, a positive value will decrease the space.
      #
      # Call with no arguments to retrieve current word spacing.
      #
      # @param amount [Numeric]
      # @yield Temporarily set word spacing
      # @return [Numeric] if called without amount
      # @return [void] otherwise
      def word_spacing(amount = nil, &block)
        return (defined?(@word_spacing) && @word_spacing) || 0 if amount.nil?

        if word_spacing == amount
          yield
        else
          wrap_and_restore_word_spacing(amount, &block)
        end
      end

      # Set the horizontal scaling.
      #
      # @param amount [Numeric] the percentage of the normal width.
      # @yield Temporarili set text scaling
      # @return [Numeric] if called with no arguments
      # @return [void] otherwise
      def horizontal_text_scaling(amount = nil, &block)
        if amount.nil?
          return (defined?(@horizontal_text_scaling) && @horizontal_text_scaling) || 100
        end

        if horizontal_text_scaling == amount
          yield
        else
          wrap_and_restore_horizontal_text_scaling(amount, &block)
        end
      end

      # Move the baseline up or down from its default location.
      # Positive values move the baseline up, negative values move it down, and
      # a zero value resets the baseline to its default location.
      #
      # @param amount [Numeric]
      # @yield Temporarily set text rise
      # @return [Numeric] if called with no arguments
      # @return [void] otherwise
      def rise(amount = nil, &block)
        if amount.nil?
          return (defined?(@rise) && @rise) || 0
        end

        if rise == amount
          yield
        else
          wrap_and_restore_rise(amount, &block)
        end
      end

      # Add a text object to content stream.
      #
      # @param text [String]
      # @param x [Numeric] horizontal position of the text origin on the page
      # @param y [Numeric] vertical position of the text origin on the page
      # @param options [Hash]
      # @option options :rotate [Numeric] text rotation angle in degrees
      # @option options :kerning [Boolean]
      def add_text_content(text, x, y, options)
        chunks = font.encode_text(text, options)

        add_content("\nBT")

        if options[:rotate]
          rad = Float(options[:rotate]) * Math::PI / 180
          array = [
            Math.cos(rad),
            Math.sin(rad),
            -Math.sin(rad),
            Math.cos(rad),
            x, y,
          ]
          add_content("#{PDF::Core.real_params(array)} Tm")
        else
          add_content("#{PDF::Core.real(x)} #{PDF::Core.real(y)} Td")
        end

        chunks.each do |(subset, string)|
          font.add_to_current_page(subset)
          add_content(
            [
              PDF::Core.pdf_object(font.identifier_for(subset), true),
              PDF::Core.pdf_object(font_size, true),
              'Tf',
            ].join(' '),
          )

          operation = options[:kerning] && string.is_a?(Array) ? 'TJ' : 'Tj'
          add_content("#{PDF::Core.pdf_object(string, true)} #{operation}")
        end

        add_content("ET\n")
      end

      private

      def wrap_and_restore_text_rendering_mode(block_value)
        original_value = text_rendering_mode
        @text_rendering_mode = block_value
        update_text_rendering_mode_state
        begin
          yield
        ensure
          @text_rendering_mode = original_value
          update_text_rendering_mode_state
        end
      end

      def update_text_rendering_mode_state
        add_content("\n#{MODES[text_rendering_mode]} Tr")
      end

      def wrap_and_restore_character_spacing(block_value)
        original_value = character_spacing
        @character_spacing = block_value
        update_character_spacing_state
        begin
          yield
        ensure
          @character_spacing = original_value
          update_character_spacing_state
        end
      end

      def update_character_spacing_state
        add_content("\n#{PDF::Core.real(character_spacing)} Tc")
      end

      def wrap_and_restore_word_spacing(block_value)
        original_value = word_spacing
        @word_spacing = block_value
        update_word_spacing_state
        begin
          yield
        ensure
          @word_spacing = original_value
          update_word_spacing_state
        end
      end

      def update_word_spacing_state
        add_content("\n#{PDF::Core.real(word_spacing)} Tw")
      end

      def wrap_and_restore_horizontal_text_scaling(block_value)
        original_value = horizontal_text_scaling
        @horizontal_text_scaling = block_value
        update_horizontal_text_scaling_state
        begin
          yield
        ensure
          @horizontal_text_scaling = original_value
          update_horizontal_text_scaling_state
        end
      end

      def update_horizontal_text_scaling_state
        add_content("\n#{PDF::Core.real(horizontal_text_scaling)} Tz")
      end

      def wrap_and_restore_rise(block_value)
        original_value = rise
        @rise = block_value
        update_rise_state
        begin
          yield
        ensure
          @rise = original_value
          update_rise_state
        end
      end

      def update_rise_state
        add_content("\n#{PDF::Core.real(rise)} Ts")
      end
    end
  end
end
