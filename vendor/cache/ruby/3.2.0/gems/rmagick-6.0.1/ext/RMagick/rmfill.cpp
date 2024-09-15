/**************************************************************************//**
 * GradientFill, TextureFill class definitions for RMagick.
 *
 * Copyright &copy; 2002 - 2009 by Timothy P. Hunter
 *
 * Changes since Nov. 2009 copyright &copy; by Benjamin Thomas and Omer Bar-or
 *
 * @file     rmfill.cpp
 * @version  $Id: rmfill.cpp,v 1.33 2009/12/20 02:33:33 baror Exp $
 * @author   Tim Hunter
 ******************************************************************************/

#include "rmagick.h"

static void GradientFill_free(void *fill);
static size_t GradientFill_memsize(const void *ptr);
static void TextureFill_free(void *fill_obj);
static size_t TextureFill_memsize(const void *ptr);

/** Data associated with a GradientFill */
typedef struct
{
    double x1; /**< x position of first point */
    double y1; /**< y position of first point */
    double x2; /**< x position of second point */
    double y2; /**< y position of second point */
    PixelColor start_color; /**< the start color */
    PixelColor stop_color; /**< the stop color */
} rm_GradientFill;

/** Data associated with a TextureFill */
typedef struct
{
    Image *texture; /**< the texture */
} rm_TextureFill;

const rb_data_type_t rm_gradient_fill_data_type = {
    "Magick::GradientFill",
    { NULL, GradientFill_free, GradientFill_memsize, },
    0, 0,
    RUBY_TYPED_FROZEN_SHAREABLE,
};

const rb_data_type_t rm_texture_fill_data_type = {
    "Magick::TextureFill",
    { NULL, TextureFill_free, TextureFill_memsize, },
    0, 0,
    RUBY_TYPED_FROZEN_SHAREABLE,
};


DEFINE_GVL_STUB2(SyncAuthenticPixels, Image *, ExceptionInfo *);


/**
 * Free GradientFill or GradientFill subclass object (except for TextureFill).
 *
 * No Ruby usage (internal function)
 *
 * @param fill the fill
 */
static void
GradientFill_free(void *fill)
{
    xfree(fill);
}


/**
  * Get GradientFill object size.
  *
  * No Ruby usage (internal function)
  *
  * @param ptr pointer to the GradientFill object
  */
static size_t
GradientFill_memsize(const void *ptr)
{
    return sizeof(rm_GradientFill);
}


/**
 * Create new GradientFill object.
 *
 * @return [Magick::GradientFill] a new GradientFill object
 */
VALUE
GradientFill_alloc(VALUE klass)
{
    rm_GradientFill *fill;

    return TypedData_Make_Struct(klass, rm_GradientFill, &rm_gradient_fill_data_type, fill);
}


/**
 * Initialize GradientFill object.
 *
 * @param x1 [Float] x position of first point
 * @param y1 [Float] y position of first point
 * @param x2 [Float] x position of second point
 * @param y2 [Float] y position of second point
 * @param start_color [Magick::Pixel, String] the start color
 * @param stop_color [Magick::Pixel, String] the stop color
 * @return [Magick::GradientFill] self
 */
VALUE
GradientFill_initialize(
                       VALUE self,
                       VALUE x1,
                       VALUE y1,
                       VALUE x2,
                       VALUE y2,
                       VALUE start_color,
                       VALUE stop_color)
{
    rm_GradientFill *fill;

    TypedData_Get_Struct(self, rm_GradientFill, &rm_gradient_fill_data_type, fill);

    fill->x1 = NUM2DBL(x1);
    fill->y1 = NUM2DBL(y1);
    fill->x2 = NUM2DBL(x2);
    fill->y2 = NUM2DBL(y2);
    Color_to_PixelColor(&fill->start_color, start_color);
    Color_to_PixelColor(&fill->stop_color, stop_color);

    return self;
}

/**
 * Do a gradient that radiates from a point.
 *
 * No Ruby usage (internal function)
 *
 * @param image the image on which to do the gradient
 * @param x0 x position of the point
 * @param y0 y position of the point
 * @param start_color the start color
 * @param stop_color the stop color
 */
static void
point_fill(
          Image *image,
          double x0,
          double y0,
          PixelColor *start_color,
          PixelColor *stop_color)
{
    double steps, distance;
    ssize_t x, y;
    MagickRealType red_step, green_step, blue_step;
    ExceptionInfo *exception;

    exception = AcquireExceptionInfo();

    steps = sqrt((double)((image->columns-x0)*(image->columns-x0)
                          + (image->rows-y0)*(image->rows-y0)));

    red_step   = ((MagickRealType)stop_color->red   - (MagickRealType)start_color->red)   / steps;
    green_step = ((MagickRealType)stop_color->green - (MagickRealType)start_color->green) / steps;
    blue_step  = ((MagickRealType)stop_color->blue  - (MagickRealType)start_color->blue)  / steps;

    for (y = 0; y < (ssize_t) image->rows; y++)
    {
#if defined(IMAGEMAGICK_7)
        Quantum *row_pixels;
#else
        PixelPacket *row_pixels;
#endif

        row_pixels = QueueAuthenticPixels(image, 0, y, image->columns, 1, exception);
        CHECK_EXCEPTION();

        for (x = 0; x < (ssize_t) image->columns; x++)
        {
            distance = sqrt((double)((x-x0)*(x-x0)+(y-y0)*(y-y0)));

#if defined(IMAGEMAGICK_7)
            SetPixelRed(image,   ROUND_TO_QUANTUM(start_color->red   + (distance * red_step)), row_pixels);
            SetPixelGreen(image, ROUND_TO_QUANTUM(start_color->green + (distance * green_step)), row_pixels);
            SetPixelBlue(image,  ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step)), row_pixels);
            SetPixelAlpha(image, OpaqueAlpha, row_pixels);

            row_pixels += GetPixelChannels(image);
#else
            row_pixels[x].red     = ROUND_TO_QUANTUM(start_color->red   + (distance * red_step));
            row_pixels[x].green   = ROUND_TO_QUANTUM(start_color->green + (distance * green_step));
            row_pixels[x].blue    = ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step));
            row_pixels[x].opacity = OpaqueOpacity;
#endif
        }

        GVL_STRUCT_TYPE(SyncAuthenticPixels) args = { image, exception };
        CALL_FUNC_WITHOUT_GVL(GVL_FUNC(SyncAuthenticPixels), &args);
        CHECK_EXCEPTION();
    }

    DestroyExceptionInfo(exception);
}

/**
 * Do a gradient fill that proceeds from a vertical line to the right and left
 * sides of the image.
 *
 * No Ruby usage (internal function)
 *
 * @param image the image on which to do the gradient
 * @param x1 x position of the vertical line
 * @param start_color the start color
 * @param stop_color the stop color
 */
static void
vertical_fill(
             Image *image,
             double x1,
             PixelColor *start_color,
             PixelColor *stop_color)
{
    double steps;
    ssize_t x, y;
    MagickRealType red_step, green_step, blue_step;
    ExceptionInfo *exception;
#if defined(IMAGEMAGICK_6)
    PixelPacket *master;
#endif

    exception = AcquireExceptionInfo();

    steps = FMAX(x1, ((long)image->columns)-x1);

    // If x is to the left of the x-axis, add that many steps so that
    // the color at the right side will be that many steps away from
    // the stop color.
    if (x1 < 0)
    {
        steps -= x1;
    }

    red_step   = ((MagickRealType)stop_color->red   - (MagickRealType)start_color->red)   / steps;
    green_step = ((MagickRealType)stop_color->green - (MagickRealType)start_color->green) / steps;
    blue_step  = ((MagickRealType)stop_color->blue  - (MagickRealType)start_color->blue)  / steps;


#if defined(IMAGEMAGICK_7)
    for (y = 0; y < (ssize_t) image->rows; y++)
    {
        Quantum *row_pixels;

        row_pixels = QueueAuthenticPixels(image, 0, y, image->columns, 1, exception);
        CHECK_EXCEPTION();

        for (x = 0; x < (ssize_t) image->columns; x++)
        {
            double distance = fabs(x1 - x);
            SetPixelRed(image,   ROUND_TO_QUANTUM(start_color->red   + (distance * red_step)), row_pixels);
            SetPixelGreen(image, ROUND_TO_QUANTUM(start_color->green + (distance * green_step)), row_pixels);
            SetPixelBlue(image,  ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step)), row_pixels);
            SetPixelAlpha(image, OpaqueAlpha, row_pixels);

            row_pixels += GetPixelChannels(image);
        }

        GVL_STRUCT_TYPE(SyncAuthenticPixels) args = { image, exception };
        CALL_FUNC_WITHOUT_GVL(GVL_FUNC(SyncAuthenticPixels), &args);
        CHECK_EXCEPTION();
    }

    DestroyExceptionInfo(exception);
#else
    // All the rows are the same. Make a "master row" and simply copy
    // it to each actual row.
    master = ALLOC_N(PixelPacket, image->columns);

    for (x = 0; x < (ssize_t) image->columns; x++)
    {
        double distance   = fabs(x1 - x);
        master[x].red     = ROUND_TO_QUANTUM(start_color->red   + (red_step * distance));
        master[x].green   = ROUND_TO_QUANTUM(start_color->green + (green_step * distance));
        master[x].blue    = ROUND_TO_QUANTUM(start_color->blue  + (blue_step * distance));
        master[x].opacity = OpaqueOpacity;
    }

    // Now copy the master row to each actual row.
    for (y = 0; y < (ssize_t) image->rows; y++)
    {
        PixelPacket *row_pixels;

        row_pixels = QueueAuthenticPixels(image, 0, y, image->columns, 1, exception);
        if (rm_should_raise_exception(exception, RetainExceptionRetention))
        {
            xfree((void *)master);
            rm_raise_exception(exception);
        }

        memcpy(row_pixels, master, image->columns * sizeof(PixelPacket));

        GVL_STRUCT_TYPE(SyncAuthenticPixels) args = { image, exception };
        CALL_FUNC_WITHOUT_GVL(GVL_FUNC(SyncAuthenticPixels), &args);
        if (rm_should_raise_exception(exception, RetainExceptionRetention))
        {
            xfree((void *)master);
            rm_raise_exception(exception);
        }
    }

    DestroyExceptionInfo(exception);

    xfree((void *) master);
#endif
}

/**
 * Do a gradient fill that starts from a horizontal line.
 *
 * No Ruby usage (internal function)
 *
 * @param image the image on which to do the gradient
 * @param y1 y position of the horizontal line
 * @param start_color the start color
 * @param stop_color the stop color
 */
static void
horizontal_fill(
               Image *image,
               double y1,
               PixelColor *start_color,
               PixelColor *stop_color)
{
    double steps;
    ssize_t x, y;
    MagickRealType red_step, green_step, blue_step;
    ExceptionInfo *exception;
#if defined(IMAGEMAGICK_6)
    PixelPacket *master;
#endif

    exception = AcquireExceptionInfo();

    steps = FMAX(y1, ((long)image->rows)-y1);

    // If the line is below the y-axis, add that many steps so the color
    // at the bottom of the image is that many steps away from the stop color
    if (y1 < 0)
    {
        steps -= y1;
    }

    red_step   = ((MagickRealType)stop_color->red   - (MagickRealType)start_color->red)   / steps;
    green_step = ((MagickRealType)stop_color->green - (MagickRealType)start_color->green) / steps;
    blue_step  = ((MagickRealType)stop_color->blue  - (MagickRealType)start_color->blue)  / steps;

#if defined(IMAGEMAGICK_7)
    for (y = 0; y < (ssize_t) image->rows; y++)
    {
        Quantum *row_pixels;

        row_pixels = QueueAuthenticPixels(image, 0, y, image->columns, 1, exception);
        CHECK_EXCEPTION();

        double distance = fabs(y1 - y);
        for (x = 0; x < (ssize_t) image->columns; x++)
        {
            SetPixelRed(image,   ROUND_TO_QUANTUM(start_color->red   + (distance * red_step)), row_pixels);
            SetPixelGreen(image, ROUND_TO_QUANTUM(start_color->green + (distance * green_step)), row_pixels);
            SetPixelBlue(image,  ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step)), row_pixels);
            SetPixelAlpha(image, OpaqueAlpha, row_pixels);

            row_pixels += GetPixelChannels(image);
        }

        GVL_STRUCT_TYPE(SyncAuthenticPixels) args = { image, exception };
        CALL_FUNC_WITHOUT_GVL(GVL_FUNC(SyncAuthenticPixels), &args);
        CHECK_EXCEPTION();
    }

    DestroyExceptionInfo(exception);
#else
    // All the columns are the same, so make a master column and copy it to
    // each of the "real" columns.
    master = ALLOC_N(PixelPacket, image->rows);

    for (y = 0; y < (ssize_t) image->rows; y++)
    {
        double distance   = fabs(y1 - y);
        master[y].red     = ROUND_TO_QUANTUM(start_color->red   + (distance * red_step));
        master[y].green   = ROUND_TO_QUANTUM(start_color->green + (distance * green_step));
        master[y].blue    = ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step));
        master[y].opacity = OpaqueOpacity;
    }

    for (x = 0; x < (ssize_t) image->columns; x++)
    {
        PixelPacket *col_pixels;

        col_pixels = QueueAuthenticPixels(image, x, 0, 1, image->rows, exception);
        if (rm_should_raise_exception(exception, RetainExceptionRetention))
        {
            xfree((void *)master);
            rm_raise_exception(exception);
        }

        memcpy(col_pixels, master, image->rows * sizeof(PixelPacket));

        GVL_STRUCT_TYPE(SyncAuthenticPixels) args = { image, exception };
        CALL_FUNC_WITHOUT_GVL(GVL_FUNC(SyncAuthenticPixels), &args);
        if (rm_should_raise_exception(exception, RetainExceptionRetention))
        {
            xfree((void *)master);
            rm_raise_exception(exception);
        }
    }

    DestroyExceptionInfo(exception);

    xfree((void *) master);
#endif
}

/**
 * Do a gradient fill that starts from a diagonal line and ends at the top and
 * bottom of the image.
 *
 * No Ruby usage (internal function)
 *
 * @param image the image on which to do the gradient
 * @param x1 x position of the start of the diagonal line
 * @param y1 y position of the start of the diagonal line
 * @param x2 x position of the end of the diagonal line
 * @param y2 y position of the end of the diagonal line
 * @param start_color the start color
 * @param stop_color the stop color
 */
static void
v_diagonal_fill(
               Image *image,
               double x1,
               double y1,
               double x2,
               double y2,
               PixelColor *start_color,
               PixelColor *stop_color)
{
    ssize_t x, y;
    MagickRealType red_step, green_step, blue_step;
    double m, b, steps = 0.0;
    double d1, d2;
    ExceptionInfo *exception;

    exception = AcquireExceptionInfo();

    // Compute the equation of the line: y=mx+b
    m = ((double)(y2 - y1))/((double)(x2 - x1));
    b = y1 - (m * x1);

    // The number of steps is the greatest distance between the line and
    // the top or bottom of the image between x=0 and x=image->columns
    // When x=0, y=b. When x=image->columns, y = m*image->columns+b
    d1 = b;
    d2 = m * image->columns + b;

    if (d1 < 0 && d2 < 0)
    {
        steps += FMAX(fabs(d1), fabs(d2));
    }
    else if (d1 > (double)image->rows && d2 > (double)image->rows)
    {
        steps += FMAX(d1-image->rows, d2-image->rows);
    }

    d1 = FMAX(b, image->rows-b);
    d2 = FMAX(d2, image->rows-d2);
    steps += FMAX(d1, d2);

    // If the line is entirely > image->rows, swap the start & end color
    if (steps < 0)
    {
        PixelColor t = *stop_color;
        *stop_color = *start_color;
        *start_color = t;
        steps = -steps;
    }

    red_step =   ((MagickRealType)stop_color->red   - (MagickRealType)start_color->red)   / steps;
    green_step = ((MagickRealType)stop_color->green - (MagickRealType)start_color->green) / steps;
    blue_step =  ((MagickRealType)stop_color->blue  - (MagickRealType)start_color->blue)  / steps;

    for (y = 0; y < (ssize_t) image->rows; y++)
    {
#if defined(IMAGEMAGICK_7)
        Quantum *row_pixels;
#else
        PixelPacket *row_pixels;
#endif

        row_pixels = QueueAuthenticPixels(image, 0, y, image->columns, 1, exception);
        CHECK_EXCEPTION();

        for (x = 0; x < (ssize_t) image->columns; x++)
        {
            double distance = (double) abs((int)(y-(m * x + b)));
#if defined(IMAGEMAGICK_7)
            SetPixelRed(image,   ROUND_TO_QUANTUM(start_color->red   + (distance * red_step)), row_pixels);
            SetPixelGreen(image, ROUND_TO_QUANTUM(start_color->green + (distance * green_step)), row_pixels);
            SetPixelBlue(image,  ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step)), row_pixels);
            SetPixelAlpha(image, OpaqueAlpha, row_pixels);

            row_pixels += GetPixelChannels(image);
#else
            row_pixels[x].red     = ROUND_TO_QUANTUM(start_color->red   + (distance * red_step));
            row_pixels[x].green   = ROUND_TO_QUANTUM(start_color->green + (distance * green_step));
            row_pixels[x].blue    = ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step));
            row_pixels[x].opacity = OpaqueOpacity;
#endif
        }

        GVL_STRUCT_TYPE(SyncAuthenticPixels) args = { image, exception };
        CALL_FUNC_WITHOUT_GVL(GVL_FUNC(SyncAuthenticPixels), &args);
        CHECK_EXCEPTION();
    }

    DestroyExceptionInfo(exception);
}

/**
 * Do a gradient fill that starts from a diagonal line and ends at the sides of
 * the image.
 *
 * No Ruby usage (internal function)
 *
 * @param image the image on which to do the gradient
 * @param x1 x position of the start of the diagonal line
 * @param y1 y position of the start of the diagonal line
 * @param x2 x position of the end of the diagonal line
 * @param y2 y position of the end of the diagonal line
 * @param start_color the start color
 * @param stop_color the stop color
 */
static void
h_diagonal_fill(
               Image *image,
               double x1,
               double y1,
               double x2,
               double y2,
               PixelColor *start_color,
               PixelColor *stop_color)
{
    ssize_t x, y;
    double m, b, steps = 0.0;
    MagickRealType red_step, green_step, blue_step;
    double d1, d2;
    ExceptionInfo *exception;

    exception = AcquireExceptionInfo();

    // Compute the equation of the line: y=mx+b
    m = ((double)(y2 - y1))/((double)(x2 - x1));
    b = y1 - (m * x1);

    // The number of steps is the greatest distance between the line and
    // the left or right side of the image between y=0 and y=image->rows.
    // When y=0, x=-b/m. When y=image->rows, x = (image->rows-b)/m.
    d1 = -b/m;
    d2 = (double) ((image->rows-b) / m);

    // If the line is entirely to the right or left of the image, increase
    // the number of steps.
    if (d1 < 0 && d2 < 0)
    {
        steps += FMAX(fabs(d1), fabs(d2));
    }
    else if (d1 > (double)image->columns && d2 > (double)image->columns)
    {
        steps += FMAX(abs((int)(image->columns-d1)), abs((int)(image->columns-d2)));
    }

    d1 = FMAX(d1, image->columns-d1);
    d2 = FMAX(d2, image->columns-d2);
    steps += FMAX(d1, d2);

    // If the line is entirely > image->columns, swap the start & end color
    if (steps < 0)
    {
        PixelColor t = *stop_color;
        *stop_color = *start_color;
        *start_color = t;
        steps = -steps;
    }

    red_step =   ((MagickRealType)stop_color->red   - (MagickRealType)start_color->red)   / steps;
    green_step = ((MagickRealType)stop_color->green - (MagickRealType)start_color->green) / steps;
    blue_step =  ((MagickRealType)stop_color->blue  - (MagickRealType)start_color->blue)  / steps;

    for (y = 0; y < (ssize_t) image->rows; y++)
    {
#if defined(IMAGEMAGICK_7)
        Quantum *row_pixels;
#else
        PixelPacket *row_pixels;
#endif

        row_pixels = QueueAuthenticPixels(image, 0, y, image->columns, 1, exception);
        CHECK_EXCEPTION();

        for (x = 0; x < (ssize_t) image->columns; x++)
        {
            double distance = (double) abs((int)(x-((y-b)/m)));
#if defined(IMAGEMAGICK_7)
            SetPixelRed(image,   ROUND_TO_QUANTUM(start_color->red   + (distance * red_step)), row_pixels);
            SetPixelGreen(image, ROUND_TO_QUANTUM(start_color->green + (distance * green_step)), row_pixels);
            SetPixelBlue(image,  ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step)), row_pixels);
            SetPixelAlpha(image, OpaqueAlpha, row_pixels);

            row_pixels += GetPixelChannels(image);
#else
            row_pixels[x].red     = ROUND_TO_QUANTUM(start_color->red   + (distance * red_step));
            row_pixels[x].green   = ROUND_TO_QUANTUM(start_color->green + (distance * green_step));
            row_pixels[x].blue    = ROUND_TO_QUANTUM(start_color->blue  + (distance * blue_step));
            row_pixels[x].opacity = OpaqueOpacity;
#endif
        }

        GVL_STRUCT_TYPE(SyncAuthenticPixels) args = { image, exception };
        CALL_FUNC_WITHOUT_GVL(GVL_FUNC(SyncAuthenticPixels), &args);
        CHECK_EXCEPTION();
    }

    DestroyExceptionInfo(exception);
}

/**
 * Call GradientFill with the start and stop colors specified when this fill
 * object was created.
 *
 * @param image_obj [Magick::Image, Magick::ImageList] the image to fill
 * @return [Magick::GradientFill] self
 */
VALUE
GradientFill_fill(VALUE self, VALUE image_obj)
{
    rm_GradientFill *fill;
    Image *image;
    PixelColor start_color, stop_color;
    double x1, y1, x2, y2;          // points on the line

    TypedData_Get_Struct(self, rm_GradientFill, &rm_gradient_fill_data_type, fill);
    image = rm_check_destroyed(rm_cur_image(image_obj));

    x1 = fill->x1;
    y1 = fill->y1;
    x2 = fill->x2;
    y2 = fill->y2;
    start_color = fill->start_color;
    stop_color  = fill->stop_color;

    if (fabs(x2-x1) < 0.5)       // vertical?
    {
        // If the x1,y1 and x2,y2 points are essentially the same
        if (fabs(y2-y1) < 0.5)
        {
            point_fill(image, x1, y1, &start_color, &stop_color);
        }

        // A vertical line is a special case.
        else
        {
            vertical_fill(image, x1, &start_color, &stop_color);
        }
    }

    // A horizontal line is a special case.
    else if (fabs(y2-y1) < 0.5)
    {
        horizontal_fill(image, y1, &start_color, &stop_color);
    }

    // This is the general case - a diagonal line. If the line is more horizontal
    // than vertical, use the top and bottom of the image as the ends of the
    // gradient, otherwise use the sides of the image.
    else
    {
        double m = ((double)(y2 - y1))/((double)(x2 - x1));
        double diagonal = ((double)image->rows)/image->columns;
        if (fabs(m) <= diagonal)
        {
            v_diagonal_fill(image, x1, y1, x2, y2, &start_color, &stop_color);
        }
        else
        {
            h_diagonal_fill(image, x1, y1, x2, y2, &start_color, &stop_color);
        }
    }

    return self;
}


/**
 * Free the TextureFill struct and the texture image it points to.
 *
 * No Ruby usage (internal function)
 *
 * Notes:
 *   - Called from GC
 *
 * @param fill_obj the TextureFill
 */
static void
TextureFill_free(void *fill_obj)
{
    rm_TextureFill *fill = (rm_TextureFill *)fill_obj;

    // Do not trace destruction
    if (fill->texture)
    {
        DestroyImage(fill->texture);
    }
    xfree(fill);
}


/**
  * Get TextureFill object size.
  *
  * No Ruby usage (internal function)
  *
  * @param ptr pointer to the TextureFill object
  */
static size_t
TextureFill_memsize(const void *ptr)
{
    return sizeof(rm_TextureFill);
}


/**
 * Create new TextureFill object.
 *
 * @return [Magick::TextureFill] a new TextureFill object
 */
VALUE
TextureFill_alloc(VALUE klass)
{
    rm_TextureFill *fill;
    return TypedData_Make_Struct(klass, rm_TextureFill, &rm_texture_fill_data_type, fill);
}

/**
 * Initialize TextureFill object.
 *
 * @param texture_arg [Magick::Image, Magick::ImageList] Either an imagelist or an image. If an
 *   imagelist, uses the current image.
 * @return [Magick::TextureFill] self
 */
VALUE
TextureFill_initialize(VALUE self, VALUE texture_arg)
{
    rm_TextureFill *fill;
    Image *texture;
    VALUE texture_image;

    TypedData_Get_Struct(self, rm_TextureFill, &rm_texture_fill_data_type, fill);

    texture_image = rm_cur_image(texture_arg);

    // Bump the reference count on the texture image.
    texture = rm_check_destroyed(texture_image);
    ReferenceImage(texture);

    fill->texture = texture;

    RB_GC_GUARD(texture_image);

    return self;
}

/**
 * Call TextureFill with the texture specified when this fill object was
 * created.
 *
 * @param image_obj [Magick::Image, Magick::ImageList] the image to fill
 * @return [Magick::TextureFill] self
 */
VALUE
TextureFill_fill(VALUE self, VALUE image_obj)
{
    rm_TextureFill *fill;
    Image *image;
#if defined(IMAGEMAGICK_7)
    ExceptionInfo *exception;
#endif

    image = rm_check_destroyed(rm_cur_image(image_obj));
    TypedData_Get_Struct(self, rm_TextureFill, &rm_texture_fill_data_type, fill);

#if defined(IMAGEMAGICK_7)
    exception = AcquireExceptionInfo();
    TextureImage(image, fill->texture, exception);
    CHECK_EXCEPTION();
    DestroyExceptionInfo(exception);
#else
    TextureImage(image, fill->texture);
    rm_check_image_exception(image, RetainOnError);
#endif

    return self;
}

