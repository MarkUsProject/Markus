# frozen_string_literal: true

require 'pdf/core/utils'

module PDF
  module Core
    # Name Tree for PDF
    #
    # @api private
    module NameTree
      # Name Tree node
      #
      # @api private
      class Node
        # Child nodes
        # @return [Array<Node>]
        attr_reader :children

        # Children number limit
        # @return [Integer]
        attr_reader :limit

        # @return [Prawn::Document]
        attr_reader :document

        # Parent node
        # @return [Node]
        attr_accessor :parent

        # @return [Reference]
        attr_accessor :ref

        # @param document [Prawn::Document] owning document
        # @param limit [Integer] Children limit
        # @param parent [Node] Parent node
        def initialize(document, limit, parent = nil)
          @document = document
          @children = []
          @limit = limit
          @parent = parent
          @ref = nil
        end

        # Tells whether there are any children nodes
        #
        # @return [Boolean]
        def empty?
          children.empty?
        end

        # Number of all (including nested) children nodes
        #
        # @return [Integer]
        def size
          leaf? ? children.size : children.sum(&:size)
        end

        # Tells whether this is a leaf node. A leaf node is the one that has no
        # children or only {Value} children.
        #
        # @return [Boolean]
        def leaf?
          children.empty? || children.first.is_a?(Value)
        end

        # Adds a value
        #
        # @param name [String]
        # @param value [any]
        def add(name, value)
          self << Value.new(name, value)
        end

        # @return [Hash] a hash representation of this node
        def to_hash
          hash = {}

          hash[:Limits] = [least, greatest] if parent
          if leaf?
            hash[:Names] = children if leaf?
          else
            hash[:Kids] = children.map(&:ref)
          end

          hash
        end

        # @return [String] the least (in lexicographic order) value name
        def least
          if leaf?
            children.first.name
          else
            children.first.least
          end
        end

        # @return [String] the greatest (in lexicographic order) value name
        def greatest
          if leaf?
            children.last.name
          else
            children.last.greatest
          end
        end

        # Insert value maintaining order and rebalancing tree if needed.
        #
        # @param value [Value]
        # @return [value]
        def <<(value)
          if children.empty?
            children << value
          elsif leaf?
            children.insert(insertion_point(value), value)
            split! if children.length > limit
          else
            fit = children.find { |child| child >= value }
            fit ||= children.last
            fit << value
          end

          value
        end

        # This is a compatibility method to allow uniform comparison between
        # nodes and values.
        #
        # @api private
        # @return [Boolean]
        # @see Value#<=>
        def >=(other)
          children.empty? || children.last >= other
        end

        # Split the tree at the node.
        #
        # @return [void]
        def split!
          if parent
            parent.split(self)
          else
            left = new_node(self)
            right = new_node(self)
            split_children(self, left, right)
            children.replace([left, right])
          end
        end

        # Returns a deep copy of this node, without copying expensive things
        # like the `ref` to `document`.
        #
        # @return [Node]
        def deep_copy
          node = dup
          node.instance_variable_set(:@children, Utils.deep_clone(children))
          node.instance_variable_set(:@ref, node.ref ? node.ref.deep_copy : nil)
          node
        end

        protected

        def split(node)
          new_child = new_node(self)
          split_children(node, node, new_child)
          index = children.index(node)
          children.insert(index + 1, new_child)
          split! if children.length > limit
        end

        private

        def new_node(parent = nil)
          node = Node.new(document, limit, parent)
          node.ref = document.ref!(node)
          node
        end

        def split_children(node, left, right)
          half = (node.limit + 1) / 2

          left_children = node.children[0...half]
          right_children = node.children[half..]

          left.children.replace(left_children)
          right.children.replace(right_children)

          unless node.leaf?
            left_children.each { |child| child.parent = left }
            right_children.each { |child| child.parent = right }
          end
        end

        def insertion_point(value)
          children.each_with_index do |child, index|
            return index if child >= value
          end
          children.length
        end
      end

      # # Name Tree value
      #
      # @api private
      class Value
        include Comparable

        # @return [String]
        attr_reader :name

        # @return [any]
        attr_reader :value

        # @param name [String]
        # @param value [any]
        def initialize(name, value)
          @name = PDF::Core::LiteralString.new(name)
          @value = value
        end

        # @param other [Value]
        # @return [-1, 0, 1]
        # @see Object#<=>
        # @see Enumerable
        def <=>(other)
          name <=> other.name
        end

        # @return [String] a string containing a human-readable representation
        #   of this value object
        def inspect
          "#<Value: #{name.inspect} : #{value.inspect}>"
        end

        # @return [String] a string representation of this value
        def to_s
          "#{name} : #{value}"
        end
      end
    end
  end
end
