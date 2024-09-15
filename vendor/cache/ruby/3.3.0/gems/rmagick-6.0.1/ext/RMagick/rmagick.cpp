/**************************************************************************//**
 * Contains Magick module methods.
 *
 * Copyright &copy; 2002 - 2009 by Timothy P. Hunter
 *
 * Changes since Nov. 2009 copyright &copy; by Benjamin Thomas and Omer Bar-or
 *
 * @file     rmagick.cpp
 * @version  $Id: rmagick.cpp,v 1.4 2009/12/20 02:33:32 baror Exp $
 * @author   Tim Hunter
 ******************************************************************************/

#include "rmagick.h"



static VALUE
rm_yield_body(VALUE object)
{
    return rb_yield(object);
}

static VALUE
rm_yield_handle_exception(VALUE allocated_area, VALUE exc)
{
    magick_free((void *)allocated_area);
    rb_exc_raise(exc);
}

/**
 * If called with the optional block, iterates over the colors, otherwise
 * returns an array of {Magick::Color} objects.
 *
 * @overload colors
 *   @return [Array<Magick::Color>] the array of {Magick::Color}
 *
 * @overload colors
 *   @yield [colorinfo]
 *   @yieldparam colorinfo [Magick::Color] the color
 *
 */
VALUE
Magick_colors(VALUE klass)
{
    const ColorInfo **color_info_list;
    size_t number_colors, x;
    VALUE ary;
    ExceptionInfo *exception;

    exception = AcquireExceptionInfo();

    color_info_list = GetColorInfoList("*", &number_colors, exception);
    CHECK_EXCEPTION();
    DestroyExceptionInfo(exception);


    if (rb_block_given_p())
    {
        for (x = 0; x < number_colors; x++)
        {
            rb_rescue(RESCUE_FUNC(rm_yield_body), Import_ColorInfo(color_info_list[x]), RESCUE_EXCEPTION_HANDLER_FUNC(rm_yield_handle_exception), (VALUE)color_info_list);
        }
        magick_free((void *)color_info_list);
        return klass;
    }
    else
    {
        ary = rb_ary_new2((long) number_colors);
        for (x = 0; x < number_colors; x++)
        {
            rb_ary_push(ary, Import_ColorInfo(color_info_list[x]));
        }

        magick_free((void *)color_info_list);
        RB_GC_GUARD(ary);
        return ary;
    }
}


/**
 * If called with the optional block, iterates over the fonts, otherwise returns
 * an array of {Magick::Font} objects.
 *
 * @overload fonts
 *   @return [Array<Magick::Font>] the array of {Magick::Font}
 *
 * @overload fonts
 *   @yield [fontinfo]
 *   @yieldparam fontinfo [Magick::Font] the font
 *
 */
VALUE
Magick_fonts(VALUE klass)
{
    const TypeInfo **type_info;
    size_t number_types, x;
    VALUE ary;
    ExceptionInfo *exception;

    exception = AcquireExceptionInfo();
    type_info = GetTypeInfoList("*", &number_types, exception);
    CHECK_EXCEPTION();
    DestroyExceptionInfo(exception);

    if (rb_block_given_p())
    {
        for (x = 0; x < number_types; x++)
        {
            rb_rescue(RESCUE_FUNC(rm_yield_body), Import_TypeInfo((const TypeInfo *)type_info[x]), RESCUE_EXCEPTION_HANDLER_FUNC(rm_yield_handle_exception), (VALUE)type_info);
        }
        magick_free((void *)type_info);
        return klass;
    }
    else
    {
        ary = rb_ary_new2((long)number_types);
        for (x = 0; x < number_types; x++)
        {
            rb_ary_push(ary, Import_TypeInfo((const TypeInfo *)type_info[x]));
        }
        magick_free((void *)type_info);
        RB_GC_GUARD(ary);
        return ary;
    }

}


/**
 * Build the @@formats hash. The hash keys are image formats. The hash values
 * specify the format "mode string", i.e. a description of what ImageMagick can
 * do with that format. The mode string is in the form "BRWA", where
 *   - "B" is "*" if the format has native blob support, or " " otherwise.
 *   - "R" is "r" if ImageMagick can read that format, or "-" otherwise.
 *   - "W" is "w" if ImageMagick can write that format, or "-" otherwise.
 *   - "A" is "+" if the format supports multi-image files, or "-" otherwise.
 *
 * No Ruby usage (internal function)
 *
 * @param magick_info a MagickInfo object.
 * @return the formats hash.
 */
static VALUE
MagickInfo_to_format(const MagickInfo *magick_info)
{
    char mode[4];

    mode[0] = GetMagickBlobSupport(magick_info) ? '*': ' ';
    mode[1] = GetImageDecoder(magick_info) ? 'r' : '-';
    mode[2] = GetImageEncoder(magick_info) ? 'w' : '-';
    mode[3] = GetMagickAdjoin(magick_info) ? '+' : '-';

    return rb_str_new(mode, sizeof(mode));
}


/**
 * Build the @@formats hash. The hash keys are image formats. The hash values
 * specify the format "mode string", i.e. a description of what ImageMagick can
 * do with that format. The mode string is in the form "BRWA", where
 *
 * - "B" is "*" if the format has native blob support, or " " otherwise.
 * - "R" is "r" if ImageMagick can read that format, or "-" otherwise.
 * - "W" is "w" if ImageMagick can write that format, or "-" otherwise.
 * - "A" is "+" if the format supports multi-image files, or "-" otherwise.
 *
 * @return [Hash] the formats hash.
 */
VALUE
Magick_init_formats(VALUE klass ATTRIBUTE_UNUSED)
{
    const MagickInfo **magick_info;
    size_t number_formats, x;
    VALUE formats;
    ExceptionInfo *exception;

    formats = rb_hash_new();

    // IM 6.1.3 added an exception argument to GetMagickInfoList
    exception = AcquireExceptionInfo();
    magick_info = GetMagickInfoList("*", &number_formats, exception);
    CHECK_EXCEPTION();
    DestroyExceptionInfo(exception);


    for (x = 0; x < number_formats; x++)
    {
        rb_hash_aset(formats,
                     rb_str_new2(magick_info[x]->name),
                     MagickInfo_to_format((const MagickInfo *)magick_info[x]));
    }
    magick_free((void *)magick_info);
    RB_GC_GUARD(formats);
    return formats;
}


/**
 * Get/set resource limits. If a limit is specified the old limit is set to the
 * new value. Either way the current/old limit is returned.
 *
 * @overload limit_resource(resource)
 *   Get resource limits.
 *   @param resource [String, Symbol] the type of resource
 *
 * @overload limit_resource(resource, limit)
 *   Set resource limits.
 *   @param resource [String, Symbol] the type of resource
 *   @param limit [Numeric] the new limit number
 *
 * @return [Numeric] the old limit.
 */
VALUE
Magick_limit_resource(int argc, VALUE *argv, VALUE klass)
{
    VALUE resource, limit;
    ResourceType res = UndefinedResource;
    char *str;
    ID id;
    unsigned long cur_limit;

    rb_scan_args(argc, argv, "11", &resource, &limit);

    switch (TYPE(resource))
    {
        case T_NIL:
            return klass;

        case T_SYMBOL:
            id = (ID)SYM2ID(resource);
            if (id == rb_intern("area"))
            {
                res = AreaResource;
            }
            else if (id == rb_intern("memory"))
            {
                res = MemoryResource;
            }
            else if (id == rb_intern("map"))
            {
                res = MapResource;
            }
            else if (id == rb_intern("disk"))
            {
                res = DiskResource;
            }
            else if (id == rb_intern("file"))
            {
                res = FileResource;
            }
            else if (id == rb_intern("time"))
            {
                res = TimeResource;
            }
            else
            {
                rb_raise(rb_eArgError, "unknown resource: `:%s'", rb_id2name(id));
            }
            break;

        default:
            str = StringValueCStr(resource);
            if (*str == '\0')
            {
                return klass;
            }
            else if (rm_strcasecmp("area", str) == 0)
            {
                res = AreaResource;
            }
            else if (rm_strcasecmp("memory", str) == 0)
            {
                res = MemoryResource;
            }
            else if (rm_strcasecmp("map", str) == 0)
            {
                res = MapResource;
            }
            else if (rm_strcasecmp("disk", str) == 0)
            {
                res = DiskResource;
            }
            else if (rm_strcasecmp("file", str) == 0)
            {
                res = FileResource;
            }
            else if (rm_strcasecmp("time", str) == 0)
            {
                res = TimeResource;
            }
            else
            {
                rb_raise(rb_eArgError, "unknown resource: `%s'", str);
            }
            break;
    }

    RB_GC_GUARD(resource);

    cur_limit = GetMagickResourceLimit(res);

    if (argc > 1)
    {
        SetMagickResourceLimit(res, (MagickSizeType)NUM2ULONG(limit));
    }

    RB_GC_GUARD(limit);

    return ULONG2NUM(cur_limit);
}


/**
 * Set the amount of free memory allocated for the pixel cache.  Once this
 * threshold is exceeded, all subsequent pixels cache operations are to/from
 * disk.
 *
 * @param threshold [Numeric] the number of megabytes to set.
 */
VALUE
Magick_set_cache_threshold(VALUE klass, VALUE threshold)
{
    unsigned long thrshld = NUM2ULONG(threshold);
    SetMagickResourceLimit(MemoryResource, (MagickSizeType)thrshld);
    SetMagickResourceLimit(MapResource, (MagickSizeType)(2*thrshld));
    return klass;
}


/**
 * Set the log event mask.
 *
 * The arguments are one of:
 *
 * - "all"
 * - "annotate"
 * - "blob"
 * - "cache"
 * - "coder"
 * - "configure"
 * - "deprecate"
 * - "locale"
 * - "none"
 * - "render"
 * - "transform"
 * - "user"
 * - "x11"
 *
 * Multiple events can be specified as the aruments. Event names may be capitalized.
 *
 * @param args [String] the mask of log event.
 */
VALUE
Magick_set_log_event_mask(int argc, VALUE *argv, VALUE klass)
{
    int x;

    if (argc == 0)
    {
        rb_raise(rb_eArgError, "wrong number of arguments (at least 1 required)");
    }
    for (x = 0; x < argc; x++)
    {
        SetLogEventMask(StringValueCStr(argv[x]));
    }
    return klass;
}

/**
 * Set the format for log messages.
 *
 * Format is a string containing one or more of:
 *
 * - %t  - current time
 * - %r  - elapsed time
 * - %u  - user time
 * - %p  - pid
 * - %m  - module (source file name)
 * - %f  - function name
 * - %l  - line number
 * - %d  - event domain (one of the events listed above)
 * - %e  - event name
 * - Plus other characters, including \\n, etc.
 *
 * @param format [String] the format to set.
 */
VALUE
Magick_set_log_format(VALUE klass, VALUE format)
{
    SetLogFormat(StringValueCStr(format));
    return klass;
}
