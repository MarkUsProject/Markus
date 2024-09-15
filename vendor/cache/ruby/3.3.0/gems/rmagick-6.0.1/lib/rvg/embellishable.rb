#--
# $Id: embellishable.rb,v 1.9 2009/02/28 23:52:13 rmagick Exp $
# Copyright (C) 2009 Timothy P. Hunter
#++
module Magick
  class RVG
    # Parent class of Circle, Ellipse, Text, etc.
    # @private
    class Shape
      include Stylable
      include Transformable
      include Duplicatable

      # Each shape can have its own set of transforms and styles.
      def add_primitives(gc)
        gc.push
        add_transform_primitives(gc)
        add_style_primitives(gc)
        gc.__send__(@primitive, *@args)
        gc.pop
      end
    end # class Shape

    class Circle < Shape
      # Define a circle with radius +r+ and centered at [<tt>cx</tt>, <tt>cy</tt>].
      # Use the RVG::ShapeConstructors#circle method to create Circle objects in a container.
      def initialize(r, cx = 0, cy = 0)
        super()
        r, cx, cy = Magick::RVG.convert_to_float(r, cx, cy)
        raise ArgumentError, "radius must be >= 0 (#{r} given)" if r < 0

        @primitive = :circle
        @args = [cx, cy, cx + r, cy]
      end
    end # class Circle

    class Ellipse < Shape
      # Define an ellipse with a center at [<tt>cx</tt>, <tt>cy</tt>], a horizontal radius +rx+
      # and a vertical radius +ry+.
      # Use the RVG::ShapeConstructors#ellipse method to create Ellipse objects in a container.
      def initialize(rx, ry, cx = 0, cy = 0)
        super()
        rx, ry, cx, cy = Magick::RVG.convert_to_float(rx, ry, cx, cy)
        raise ArgumentError, "radii must be >= 0 (#{rx}, #{ry} given)" if rx < 0 || ry < 0

        @primitive = :ellipse
        # Ellipses are always complete.
        @args = [cx, cy, rx, ry, 0, 360]
      end
    end # class Ellipse

    class Line < Shape
      # Define a line from [<tt>x1</tt>, <tt>y1</tt>] to [<tt>x2</tt>, <tt>y2</tt>].
      # Use the RVG::ShapeConstructors#line method to create Line objects in a container.
      def initialize(x1 = 0, y1 = 0, x2 = 0, y2 = 0)
        super()
        @primitive = :line
        @args = [x1, y1, x2, y2]
      end
    end # class Line

    class Path < Shape
      # Define an SVG path. The argument can be either a path string
      # or a PathData object.
      # Use the RVG::ShapeConstructors#path method to create Path objects in a container.
      def initialize(path)
        super()
        @primitive = :path
        @args = [path.to_s]
      end
    end # class Path

    class Rect < Shape
      # Define a width x height rectangle. The upper-left corner is at [<tt>x</tt>, <tt>y</tt>].
      # If either <tt>width</tt> or <tt>height</tt> is 0, the rectangle is not rendered.
      # Use the RVG::ShapeConstructors#rect method to create Rect objects in a container.
      def initialize(width, height, x = 0, y = 0)
        super()
        width, height, x, y = Magick::RVG.convert_to_float(width, height, x, y)
        raise ArgumentError, "width, height must be >= 0 (#{width}, #{height} given)" if width < 0 || height < 0

        @args = [x, y, x + width, y + height]
        @primitive = :rectangle
      end

      # Specify optional rounded corners for a rectangle. The arguments
      # are the x- and y-axis radii. If y is omitted it defaults to x.
      def round(rx, ry = nil)
        rx, ry = Magick::RVG.convert_to_float(rx, ry || rx)
        raise ArgumentError, "rx, ry must be >= 0 (#{rx}, #{ry} given)" if rx < 0 || ry < 0

        @args << rx << ry
        @primitive = :roundrectangle
        self
      end
    end  # class Rect

    class PolyShape < Shape
      def polypoints(points)
        case points.length
        when 1
          points = Array(points[0])
        when 2
          x_coords = Array(points[0])
          y_coords = Array(points[1])
          raise ArgumentError, 'array arguments must contain at least one point' unless !x_coords.empty? && !y_coords.empty?

          n = x_coords.length - y_coords.length
          short = n > 0 ? y_coords : x_coords
          olen = short.length
          n.abs.times { |x| short << short[x % olen] }
          points = x_coords.zip(y_coords).flatten!
        end
        n = points.length
        raise ArgumentError, "insufficient/odd number of points specified: #{n}" if n < 4 || n.odd?

        Magick::RVG.convert_to_float(*points)
      end
    end  # class PolyShape

    class Polygon < PolyShape
      # Draws a polygon. The arguments are [<tt>x</tt>, <tt>y</tt>] pairs that
      # define the points that make up the polygon. At least two
      # points must be specified. If the last point is not the
      # same as the first, adds an additional point to close
      # the polygon.
      # Use the RVG::ShapeConstructors#polygon method to create Polygon objects in a container.
      def initialize(*points)
        super()
        @primitive = :polygon
        @args = polypoints(points)
      end
    end # class Polygon

    class Polyline < PolyShape
      # Draws a polyline. The arguments are [<tt>x</tt>, <tt>y</tt>] pairs that
      # define the points that make up the polyline. At least two
      # points must be specified.
      # Use the RVG::ShapeConstructors#polyline method to create Polyline objects in a container.
      def initialize(*points)
        super()
        points = polypoints(points)
        @primitive = :polyline
        @args = Magick::RVG.convert_to_float(*points)
      end
    end # class Polyline

    class Image
      include Stylable
      include Transformable
      include Describable
      include PreserveAspectRatio
      include Duplicatable

      private

      def align_to_viewport(scale)
        tx = case @align
             when 'none', /\AxMin/
               0
             when NilClass, /\AxMid/
               (@width - @image.columns * scale) / 2.0
             when /\AxMax/
               @width - @image.columns * scale
             else
               0
             end

        ty = case @align
             when 'none', /YMin\z/
               0
             when NilClass, /YMid\z/
               (@height - @image.rows * scale) / 2.0
             when /YMax\z/
               @height - @image.rows * scale
             else
               0
             end
        [tx, ty]
      end

      def add_composite_primitive(gc)
        if @align == 'none'
          # Let RMagick do the scaling
          scale = 1.0
          width = @width
          height = @height
        elsif @meet_or_slice == 'meet'
          scale = [@width / @image.columns, @height / @image.rows].min || 1.0
          width = @image.columns
          height = @image.rows
        else
          # Establish clipping path around the current viewport
          name = __id__.to_s
          gc.define_clip_path(name) do
            gc.path("M#{@x},#{@y} l#{@width},0 l0,#{@height} l-#{@width},0 l0,-#{@height}z")
          end

          gc.clip_path(name)
          scale = [@width / @image.columns, @height / @image.rows].max || 1.0
          width = @image.columns
          height = @image.rows
        end
        tx, ty = align_to_viewport(scale)
        gc.composite(@x + tx, @y + ty, width * scale, height * scale, @image)
      end

      def init_viewbox
        @align = nil
        @vbx_width = @image.columns
        @vbx_height = @image.rows
        @meet_or_slice = 'meet'
      end

      public

      # Composite a raster image in the viewport defined by [x,y] and
      # +width+ and +height+.
      # Use the RVG::ImageConstructors#image method to create Text objects in a container.
      def initialize(image, width = nil, height = nil, x = 0, y = 0)
        super()             # run module initializers
        @image = image.copy # use a copy of the image in case app. re-uses the argument
        @x, @y, @width, @height = Magick::RVG.convert_to_float(x, y, width || @image.columns, height || @image.rows)
        raise ArgumentError, 'width, height must be >= 0' if @width < 0 || @height < 0

        init_viewbox
      end

      # @private
      def add_primitives(gc)
        # Do not render if width or height is 0
        return if @width.zero? || @height.zero?

        gc.push
        add_transform_primitives(gc)
        add_style_primitives(gc)
        add_composite_primitive(gc)
        gc.pop
      end
    end # class Image

    # Methods that construct basic shapes within a container
    module ShapeConstructors
      # Draws a circle whose center is [<tt>cx</tt>, <tt>cy</tt>] and radius is +r+.
      def circle(r, cx = 0, cy = 0)
        circle = Circle.new(r, cx, cy)
        @content << circle
        circle
      end

      # Draws an ellipse whose center is [<tt>cx</tt>, <tt>cy</tt>] and having
      # a horizontal radius +rx+ and vertical radius +ry+.
      def ellipse(rx, ry, cx = 0, cy = 0)
        ellipse = Ellipse.new(rx, ry, cx, cy)
        @content << ellipse
        ellipse
      end

      # Draws a line from [<tt>x1</tt>, <tt>y1</tt>] to  [<tt>x2</tt>, <tt>y2</tt>].
      def line(x1 = 0, y1 = 0, x2 = 0, y2 = 0)
        line = Line.new(x1, y1, x2, y2)
        @content << line
        line
      end

      # Draws a path defined by an SVG path string or a PathData
      # object.
      def path(path)
        path = Path.new(path)
        @content << path
        path
      end

      # Draws a rectangle whose upper-left corner is [<tt>x</tt>, <tt>y</tt>] and
      # with the specified +width+ and +height+. Unless otherwise
      # specified the rectangle has square corners. Returns a
      # Rectangle object.
      #
      # Draw a rectangle with rounded corners by calling the #round
      # method on the Rectangle object. <tt>rx</tt> and <tt>ry</tt> are
      # the corner radii in the x- and y-directions. For example:
      #   canvas.rect(width, height, x, y).round(8, 6)
      # If <tt>ry</tt> is omitted it defaults to <tt>rx</tt>.
      def rect(width, height, x = 0, y = 0)
        rect = Rect.new(width, height, x, y)
        @content << rect
        rect
      end

      # Draws a polygon. The arguments are [<tt>x</tt>, <tt>y</tt>] pairs that
      # define the points that make up the polygon. At least two
      # points must be specified. If the last point is not the
      # same as the first, adds an additional point to close
      # the polygon.
      def polygon(*points)
        polygon = Polygon.new(*points)
        @content << polygon
        polygon
      end

      # Draws a polyline. The arguments are [<tt>x</tt>, <tt>y</tt>] pairs that
      # define the points that make up the polyline. At least two
      # points must be specified.
      def polyline(*points)
        polyline = Polyline.new(*points)
        @content << polyline
        polyline
      end
    end # module ShapeContent

    # Methods that reference ("use") other drawable objects within a container
    module UseConstructors
      # Reference an object to be inserted into the container's
      # content. [<tt>x</tt>,<tt>y</tt>] is the offset from the upper-left
      # corner. If the argument is an RVG or Image object and +width+ and +height+
      # are specified, these values will override the +width+ and +height+
      # attributes on the argument.
      def use(obj, x = 0, y = 0, width = nil, height = nil)
        use = Use.new(obj, x, y, width, height)
        @content << use
        use
      end
    end # module UseConstructors

    # Methods that construct container objects within a container
    module StructureConstructors
      # Establishes a new viewport. [<tt>x</tt>, <tt>y</tt>] is the coordinate of the
      # upper-left corner within the containing viewport. This is a
      # _container_ method. Styles and
      # transforms specified on this object will be used by objects
      # contained within, unless overridden by an inner container or
      # the contained object itself.
      def rvg(cols, rows, x = 0, y = 0, &block)
        rvg = Magick::RVG.new(cols, rows, &block)
        begin
          x = Float(x)
          y = Float(y)
        rescue ArgumentError
          args = [cols, rows, x, y]
          raise ArgumentError, "at least one argument is not convertable to Float (got #{args.map(&:class).join(', ')})"
        end
        rvg.corner(x, y)
        @content << rvg
        rvg
      end

      # Defines a group.
      #
      # This method constructs a new
      # Group _container_ object. The styles and
      # transforms specified on this object will be used by objects
      # contained within, unless overridden by an inner container or
      # the contained object itself.
      # Define grouped elements by calling RVG::Embellishable
      # methods within the associated block.
      def g(&block)
        group = Group.new(&block)
        @content << group
        group
      end
    end # module StructureConstructors

    # Methods that construct raster image objects within a container
    module ImageConstructors
      # Composite a raster image at [<tt>x</tt>,<tt>y</tt>]
      # in a viewport of the specified <tt>width</tt> and <tt>height</tt>.
      # If not specified, the width and height are the width and height
      # of the image. Use the RVG::PreserveAspectRatio#preserve_aspect_ratio method to
      # control the placement and scaling of the image within the
      # viewport. By default, the image is scaled to fit inside the
      # viewport and centered within the viewport.
      def image(image, width = nil, height = nil, x = 0, y = 0)
        img = Image.new(image, width, height, x, y)
        @content << img
        img
      end
    end # module ImageConstructors

    # Methods that create shapes, text, and other drawable objects
    # within container objects such as ::Magick::RVG and
    # ::Magick::RVG::Group
    module Embellishable
      include StructureConstructors
      include ShapeConstructors
      include TextConstructors
      include UseConstructors
      include ImageConstructors
    end # module Embellishable
  end # class RVG
end # module Magick
