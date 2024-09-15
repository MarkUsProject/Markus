# frozen_string_literal: true

module PDF
  module Core
    # Graphics state saving and restoring
    class GraphicStateStack
      # Graphic state stack
      attr_accessor :stack

      # @param previous_state [GraphicState, nil]
      def initialize(previous_state = nil)
        self.stack = [GraphicState.new(previous_state)]
      end

      # Pushes graphic state onto stack
      #
      # @param graphic_state [GraphicState, nil]
      # @return [void]
      def save_graphic_state(graphic_state = nil)
        stack.push(GraphicState.new(graphic_state || current_state))
      end

      # Restores previous graphic state
      #
      # @return [void]
      def restore_graphic_state
        if stack.empty?
          raise PDF::Core::Errors::EmptyGraphicStateStack,
            "\n You have reached the end of the graphic state stack"
        end
        stack.pop
      end

      # Current graphic state
      #
      # @return [GraphicState]
      def current_state
        stack.last
      end

      # Tells whether there are any saved graphic states
      #
      # @return [Boolean]
      # @see #empty?
      def present?
        !stack.empty?
      end

      # Tells whether there are no saved graphic states
      #
      # @return [Boolean]
      # @see #present?
      def empty?
        stack.empty?
      end
    end

    # Graphics state.
    # It's a *partial* represenation of PDF graphics state. Only the parts
    # implemented in Prawn are present here.
    #
    # NOTE: This class may be a good candidate for a copy-on-write hash.
    class GraphicState
      # Color space
      # @return [Hash]
      attr_accessor :color_space

      # Dash
      # @return [Hash<[:dash, :space, :phase], [nil, Numeric]>]
      attr_accessor :dash

      # Line cap
      # @return [Symbol]
      attr_accessor :cap_style

      # Line Join
      # @return [Symbol]
      attr_accessor :join_style

      # Line width
      # @return [Numberic]
      attr_accessor :line_width

      # Fill color
      # @return [String]
      attr_accessor :fill_color

      # Stroke color
      attr_accessor :stroke_color

      # @param previous_state [GraphicState, nil]
      def initialize(previous_state = nil)
        if previous_state
          initialize_copy(previous_state)
        else
          @color_space = {}
          @fill_color = '000000'
          @stroke_color = '000000'
          @dash = { dash: nil, space: nil, phase: 0 }
          @cap_style = :butt
          @join_style = :miter
          @line_width = 1
        end
      end

      # PDF representation of dash settings
      #
      # @return [String]
      def dash_setting
        return '[] 0 d' unless @dash[:dash]

        array =
          if @dash[:dash].is_a?(Array)
            @dash[:dash]
          else
            [@dash[:dash], @dash[:space]]
          end

        "[#{PDF::Core.real_params(array)}] #{PDF::Core.real(@dash[:phase])} d"
      end

      private

      def initialize_copy(other)
        # mutable state
        @color_space = other.color_space.dup
        @fill_color = other.fill_color.dup
        @stroke_color = other.stroke_color.dup
        @dash = other.dash.dup

        # immutable state that doesn't need to be duped
        @cap_style = other.cap_style
        @join_style = other.join_style
        @line_width = other.line_width
      end
    end
  end
end
