/**************************************************************************//**
 * RMagick declarations and definitions.
 *
 * Copyright &copy; 2002 - 2009 by Timothy P. Hunter
 *
 * Changes since Nov. 2009 copyright &copy; by Benjamin Thomas and Omer Bar-or
 *
 * @file     rmagick.h
 * @version  $Id: rmagick.h,v 1.282 2010/02/16 06:50:28 baror Exp $
 * @author   Tim Hunter
 ******************************************************************************/

#ifndef _RMAGICK_H_
#define _RMAGICK_H_

//! Suppress warnings about deprecated functions on Windows
#define _CRT_SECURE_NO_DEPRECATE 1

// ruby.h contains a C++ template, which cannot be included in extern "C".
// Therefore, it includes the header in advance.
#include "ruby/defines.h"

extern "C" {
    #include <assert.h>
    #include <stdio.h>
    #include <ctype.h>
    #include <stdlib.h>
    #include <math.h>
    #include <sys/types.h>
    #include "ruby.h"
    #include "ruby/io.h"
    #include "rmagick_gvl.h"
}

#if defined(__MINGW32__)
    // Ruby defines wrong format specifiers for MinGW. So this defines original macro in here.
    #if SIZEOF_SIZE_T == SIZEOF_LONG
        #define RMIuSIZE  "lu"
        #define RMIdSIZE  "ld"
        #define RMIsVALUE "li\v"
    #elif SIZEOF_SIZE_T == SIZEOF_LONG_LONG
        #define RMIuSIZE  "I64u"
        #define RMIdSIZE  "I64d"
        #define RMIsVALUE "I64i\v"
    #endif
#else
    // Use constants defined in Ruby
    #define RMIuSIZE  PRIuSIZE
    #define RMIdSIZE  PRIdSIZE
    #define RMIsVALUE PRIsVALUE
#endif

#if defined(__GNUC__)
    #if __GNUC__ > 6
        #pragma GCC diagnostic ignored "-Wimplicit-fallthrough"
    #endif
#endif

// Undef Ruby's versions of these symbols
#undef PACKAGE_VERSION
#undef PACKAGE_NAME
#undef PACKAGE_STRING
#undef PACKAGE_BUGREPORT
#undef PACKAGE_TARNAME
#undef WORDS_BIGENDIAN

#ifndef HAVE_RB_EXT_RACTOR_SAFE
#undef RUBY_TYPED_FROZEN_SHAREABLE
#define RUBY_TYPED_FROZEN_SHAREABLE 0
#endif

#include "extconf.h"

#if defined(IMAGEMAGICK_7)
    #include "MagickCore/MagickCore.h"
    #include "MagickCore/magick-config.h"
#else
    #include "magick/MagickCore.h"
    #include "magick/magick-config.h"
#endif

// Undef ImageMagick's versions of these symbols
#undef PACKAGE_STRING


//! For quoting preprocessor symbols
#define Q2(q) #q
//! For quoting preprocessor symbols
#define Q(q) Q2(q)

#ifdef __GNUC__
#define ATTRIBUTE_UNUSED   __attribute__((unused))
#define ATTRIBUTE_NORETURN __attribute__((__noreturn__))
#else
#define ATTRIBUTE_UNUSED
#define ATTRIBUTE_NORETURN
#endif

//! Trace new image creation in bang methods
#define UPDATE_DATA_PTR(_obj_, _new_) \
    do { \
        DATA_PTR(_obj_) = (void *)(_new_); \
    } while(0)


// Handle Quantum <-> Ruby Numeric object conversion
#if (MAGICKCORE_QUANTUM_DEPTH == 8 || MAGICKCORE_QUANTUM_DEPTH == 16)
#define QUANTUM2NUM(q) INT2FIX((q)) /**< Quantum -> Ruby Numeric conversion */
#define NUM2QUANTUM(n) (Quantum)NUM2UINT((n)) /**< Quantum <- Ruby Numeric conversion */
#elif (MAGICKCORE_QUANTUM_DEPTH == 32)
#define QUANTUM2NUM(q) UINT2NUM((q)) /**< Quantum -> Ruby Numeric conversion */
#define NUM2QUANTUM(n) (Quantum)NUM2UINT((n)) /**< Quntum <- Ruby Numeric conversion */
#elif (MAGICKCORE_QUANTUM_DEPTH == 64)
#define QUANTUM2NUM(q) ULL2NUM((q)) /**< Quantum -> Ruby Numeric conversion */
#define NUM2QUANTUM(n) (Quantum)NUM2ULL((n)) /**< Quntum <- Ruby Numeric conversion */
#else
#error Specified MAGICKCORE_QUANTUM_DEPTH is not supported.
#endif
//! Convert user-supplied objects to Quantum
#define APP2QUANTUM(n) rm_app2quantum((n))

//! degrees to radians conversion
#undef DegreesToRadians     // defined in ImageMagick.h in 6.0.2
#define DegreesToRadians(x) ((x)*3.14159265358979323846/180.0)

//! pixel intensity calculation
#define PIXEL_INTENSITY(q) ((Quantum)(0.299*(q)->red + 0.587*(q)->green + 0.114*(q)->blue + 0.5))

//! find maximum of longs
#define LMAX(a, b) ((((long)(a))>((long)(b)))?((long)(a)):((long)(b)))
//! find maximum of floats
#define FMAX(a, b) ((((double)(a))>((double)(b)))?((double)(a)):((double)(b)))
//! find minimum of floats
#define FMIN(a, b) ((((double)(a))<=((double)(b)))?((double)(a)):((double)(b)))

#define RMAGICK_PI 3.14159265358979  /**< pi */

//! round to Quantum
#define ROUND_TO_QUANTUM(value) ((Quantum) ((value) > (Quantum)QuantumRange ? QuantumRange : (value) + 0.5))

//! Convert a C string to a Ruby symbol. Used in marshal_dump/marshal_load methods
#define CSTR2SYM(s) ID2SYM(rb_intern(s))
//! Convert a C string to a Ruby String, or nil if the ptr is NULL
#define MAGICK_STRING_TO_OBJ(f) (f) ? rb_str_new2(f) : Qnil
/**
 * Copy the C string in a Ruby String object to ImageMagick memory, or set the
 * pointer to NULL if the object is nil.
 */
#define OBJ_TO_MAGICK_STRING(f, obj) \
    if ((obj) != Qnil)\
    {\
        VALUE str = rb_String(obj);\
        magick_clone_string(&f, StringValueCStr(str));\
    }\
    else\
        f = NULL;


#define MagickLibSubversion MagickLibAddendum

typedef ImageInfo Info; /**< Make type name match class name */
#if defined(IMAGEMAGICK_7)
    typedef struct _QuantumPixelPacket
    {
    Quantum
        red,
        green,
        blue,
        alpha,
        black;
    } QuantumPixelPacket;

    typedef QuantumPixelPacket Pixel;
    typedef PixelInfo MagickPixel;
    typedef PixelInfo PixelColor;
#else
    typedef struct _RMagickPixelPacket
    {
    Quantum
        red,
        green,
        blue,
        opacity,
        black;
    } RMagickPixelPacket;
    typedef RMagickPixelPacket Pixel;
    typedef MagickPixelPacket MagickPixel;
    typedef PixelPacket PixelColor;
    typedef AlphaChannelType AlphaChannelOption;
    typedef DistortImageMethod DistortMethod;
    typedef FilterTypes FilterType;
    typedef InterpolatePixelMethod PixelInterpolateMethod;
    typedef ImageLayerMethod LayerMethod;
    #define TransparentAlpha 0
    #define IMAGEMAGICK_6 1
#endif

//! Montage
typedef struct
{
    CompositeOperator compose; /**< compose operator */
    MontageInfo *info; /**< montage info */
} Montage;

// Draw
//! tmp filename linked list
struct TmpFile_Name
{
    struct TmpFile_Name *next; /**< the next tmp filename */
    char name[1]; /**< expandable char array for this filename */
};

//! Draw class.
typedef struct
{
    DrawInfo *info;             /**< the DrawInfo struct */
    VALUE primitives;           /**< the primitive string */
    struct TmpFile_Name *tmpfile_ary; /**< the tmp filenames */
    PixelColor shadow_color;   /**< PolaroidOptions#shadow_color */
} Draw;             // make the type match the class name

// Enum
//! enumerator over Magick ids
typedef struct
{
   ID id; /**< the Magick id */
   int val; /**< its value */
} MagickEnum;

#undef False    // defined in deprecate.h in 6.0.2
#undef True     // defined in deprecate.h in 6.0.2
//! generic boolean
typedef enum
{
    False = 0, /**< false */
    True = 1   /**< true */
} rm_boolean;

//! enumerator over weight types
typedef enum {
    AnyWeight,     /**< any */
    NormalWeight,  /**< normal */
    BoldWeight,    /**< bold */
    BolderWeight,  /**< bolder */
    LighterWeight  /**< lighter */
} WeightType;

//! Draw#text_anchor AnchorType argument
typedef enum {
    StartAnchor = 1,  /**< start */
    MiddleAnchor = 2, /**< midle */
    EndAnchor = 3     /**< end */
} AnchorType;


//! dumped image
typedef struct
{
    unsigned char id;   /**< Dumped image id = 0xd1 */
    unsigned char mj;   /**< Major format number = 1 */
    unsigned char mi;   /**< Minor format number = 0 */
    unsigned char len;  /**< Length of image magick string */
    char magick[MaxTextExtent]; /**< magick string */
} DumpedImage;

#define DUMPED_IMAGE_ID      0xd1 /**< ID of Dumped image id */
#define DUMPED_IMAGE_MAJOR_VERS 1 /**< Dumped image major version */
#define DUMPED_IMAGE_MINOR_VERS 0 /**< Dumped image minor version */

#define MAGICK_LOC "magick_location"     /**< instance variable name in ImageMagickError class */

#define MAX_GEOM_STR 51                 /**< max length of a geometry string */

//! Quantum expression adapter.
/**
 * ImageMagick defines an enum type for quantum-level expressions,
 * but they're different types. The QuantumExpressionOperator
 * type is an adapter type that can be mapped to either one.
 */
typedef enum _QuantumExpressionOperator
{
    UndefinedQuantumOperator, /**< undefined */
    AddQuantumOperator,       /**< add */
    AndQuantumOperator,       /**< and */
    DivideQuantumOperator,    /**< divide */
    LShiftQuantumOperator,    /**< lshift */
    MaxQuantumOperator,       /**< max */
    MinQuantumOperator,       /**< min */
    MultiplyQuantumOperator,  /**< multiply */
    OrQuantumOperator,        /**< or */
    RShiftQuantumOperator,    /**< rshift */
    SubtractQuantumOperator,  /**< subtract */
    XorQuantumOperator,       /**< xor */
    PowQuantumOperator,       /**< pow */
    LogQuantumOperator,       /**< log */
    ThresholdQuantumOperator, /**< threshold */
    ThresholdBlackQuantumOperator, /**< threshold black */
    ThresholdWhiteQuantumOperator, /**< threshold white */
    GaussianNoiseQuantumOperator, /**< gaussian noise */
    ImpulseNoiseQuantumOperator, /**< impulse noise */
    LaplacianNoiseQuantumOperator, /**< laplacian noise */
    MultiplicativeNoiseQuantumOperator, /**< multiplicative noise */
    PoissonNoiseQuantumOperator, /**< poisson noise */
    UniformNoiseQuantumOperator, /**< uniform noise */
    CosineQuantumOperator,    /**< cosine */
    SetQuantumOperator,       /**< set */
    SineQuantumOperator,      /**< sine */
    AddModulusQuantumOperator, /**< add modulus */
    MeanQuantumOperator, /**< mean */
    AbsQuantumOperator, /**< abs */
    ExponentialQuantumOperator, /**< exponential */
    MedianQuantumOperator, /**< median */
    SumQuantumOperator, /**< sum */
    RootMeanSquareQuantumOperator /** root mean square */
} QuantumExpressionOperator ;


/** This implements the "omitted storage class model" for external variables.
 * (Ref: Harbison & Steele.) The rmmain.cpp file defines MAIN, which causes
 * the single defining declarations to be generated. No other source files
 * define MAIN and therefore generate referencing declarations.
 */
#undef EXTERN
#if defined(MAIN)
#define EXTERN
#else
#define EXTERN extern
#endif

/*
*   RMagick Module and Class VALUEs
*/
EXTERN VALUE Module_Magick;
EXTERN VALUE Module_DrawAttribute;
EXTERN VALUE Class_ImageList;
EXTERN VALUE Class_Info;
EXTERN VALUE Class_KernelInfo;
EXTERN VALUE Class_Draw;
EXTERN VALUE Class_DrawOptions;
EXTERN VALUE Class_Image;
EXTERN VALUE Class_Montage;
EXTERN VALUE Class_ImageMagickError;
EXTERN VALUE Class_FatalImageMagickError;
EXTERN VALUE Class_DestroyedImageError;
EXTERN VALUE Class_GradientFill;
EXTERN VALUE Class_TextureFill;
EXTERN VALUE Class_AffineMatrix;
EXTERN VALUE Class_Chromaticity;
EXTERN VALUE Class_Color;
EXTERN VALUE Class_Font;
EXTERN VALUE Class_Geometry;
EXTERN VALUE Class_GeometryValue;   // Defined in RMagick.rb
EXTERN VALUE Class_Pixel;
EXTERN VALUE Class_Point;
EXTERN VALUE Class_PolaroidOptions;
EXTERN VALUE Class_Primary;
EXTERN VALUE Class_Rectangle;
EXTERN VALUE Class_Segment;
EXTERN VALUE Class_TypeMetric;
EXTERN VALUE Class_MetricType;
EXTERN VALUE Class_QuantumExpressionOperator;

// Enum classes
EXTERN VALUE Class_Enum;
EXTERN VALUE Class_AlignType;
EXTERN VALUE Class_AlphaChannelOption;
EXTERN VALUE Class_AnchorType;
EXTERN VALUE Class_ChannelType;
EXTERN VALUE Class_ClassType;
EXTERN VALUE Class_ColorspaceType;
EXTERN VALUE Class_ComplianceType;
EXTERN VALUE Class_CompositeOperator;
EXTERN VALUE Class_CompressionType;
EXTERN VALUE Class_DecorationType;
EXTERN VALUE Class_DisposeType;
EXTERN VALUE Class_DistortMethod;
EXTERN VALUE Class_DitherMethod;
EXTERN VALUE Class_EndianType;
EXTERN VALUE Class_FilterType;
EXTERN VALUE Class_GravityType;
EXTERN VALUE Class_ImageType;
EXTERN VALUE Class_InterlaceType;
EXTERN VALUE Class_LayerMethod;
EXTERN VALUE Class_MagickFunction;
EXTERN VALUE Class_NoiseType;
EXTERN VALUE Class_OrientationType;
EXTERN VALUE Class_PaintMethod;
EXTERN VALUE Class_PixelInterpolateMethod;
EXTERN VALUE Class_PreviewType;
EXTERN VALUE Class_RenderingIntent;
EXTERN VALUE Class_ResolutionType;
EXTERN VALUE Class_SparseColorMethod;
EXTERN VALUE Class_SpreadMethod;
EXTERN VALUE Class_StorageType;
EXTERN VALUE Class_StretchType;
EXTERN VALUE Class_StyleType;
EXTERN VALUE Class_WeightType;
EXTERN VALUE Class_VirtualPixelMethod;
EXTERN VALUE Class_GeometryFlags;
EXTERN VALUE Class_MorphologyMethod;
EXTERN VALUE Class_KernelInfoType;

/**
*   Commonly-used IDs
*/
EXTERN ID rm_ID_call;              /**< "call" */
EXTERN ID rm_ID_changed;           /**< "changed" */
EXTERN ID rm_ID_cur_image;         /**< "cur_image" */
EXTERN ID rm_ID_dup;               /**< "dup" */
EXTERN ID rm_ID_fill;              /**< "fill" */
EXTERN ID rm_ID_Geometry;          /**< "Geometry" */
EXTERN ID rm_ID_height;            /**< "height" */
EXTERN ID rm_ID_initialize_copy;   /**< "initialize_copy" */
EXTERN ID rm_ID_notify_observers;  /**< "notify_observers" */
EXTERN ID rm_ID_new;               /**< "new" */
EXTERN ID rm_ID_push;              /**< "push" */
EXTERN ID rm_ID_values;            /**< "values" */
EXTERN ID rm_ID_width;             /**< "width" */

extern const rb_data_type_t rm_enum_data_type;
extern const rb_data_type_t rm_info_data_type;
extern const rb_data_type_t rm_image_data_type;
extern const rb_data_type_t rm_draw_data_type;
extern const rb_data_type_t rm_pixel_data_type;
extern const rb_data_type_t rm_montage_data_type;
extern const rb_data_type_t rm_kernel_info_data_type;

#if !defined(min)
#define min(a, b) ((a)<(b)?(a):(b)) /**< min of two values */
#endif
#if !defined(max)
#define max(a, b) ((a)>(b)?(a):(b)) /**< max of two values */
#endif

/**
   Handle warnings & errors
*/
//! Handle warnings & errors
#define CHECK_EXCEPTION() rm_check_exception(exception, NULL, RetainOnError)


/*
    Define simple attribute accessor methods (boolean, int, string, and double types)
*/
#define C_boolean_to_R_boolean(attr) (attr) ? Qtrue : Qfalse /**< C boolean -> Ruby boolean */
#define R_boolean_to_C_boolean(attr) (MagickBooleanType)RTEST(attr) /**<  C boolean <- Ruby boolean */
#define C_int_to_R_int(attr) INT2FIX(attr) /**< C int -> Ruby int */
#define R_int_to_C_int(attr) NUM2INT(attr) /**< C int <- Ruby int */
#define C_long_to_R_long(attr) LONG2NUM(attr) /**< C long -> Ruby long */
#define R_long_to_C_long(attr) NUM2LONG(attr) /**< C long <- Ruby long */
#define C_ulong_to_R_ulong(attr) ULONG2NUM(attr) /**< C unsigned long -> Ruby unsigned long */
#define R_ulong_to_C_ulong(attr) NUM2ULONG(attr) /**< C unsigned long <- Ruby unsigned long */
#define C_str_to_R_str(attr) attr ? rb_str_new2(attr) : Qnil /**< C string -> Ruby string */
#define C_dbl_to_R_dbl(attr) rb_float_new(attr) /**< C double -> Ruby double */
#define R_dbl_to_C_dbl(attr) NUM2DBL(attr) /**< C double <- Ruby double */

//! define attribute reader
#define IMPLEMENT_TYPED_ATTR_READER(klass, attr, type, data_type) \
    {\
        klass *ptr;\
        if (rb_obj_is_kind_of(self, Class_Image) == Qtrue) {\
            rm_check_destroyed(self); \
        }\
        TypedData_Get_Struct(self, klass, data_type, ptr);\
        return C_##type##_to_R_##type(ptr->attr);\
    }

//! define attribute reader when attribute name is different from the field name
#define IMPLEMENT_TYPED_ATTR_READERF(klass, attr, field, type, data_type) \
    {\
        klass *ptr;\
        rm_check_destroyed(self); \
        TypedData_Get_Struct(self, klass, data_type, ptr);\
        return C_##type##_to_R_##type(ptr->field);\
    }

//! define attribute writer
#define IMPLEMENT_TYPED_ATTR_WRITER(klass, attr, type, data_type) \
    {\
        klass *ptr;\
        if (rb_obj_is_kind_of(self, Class_Image) == Qtrue) {\
            rm_check_destroyed(self); \
        }\
        rb_check_frozen(self);\
        TypedData_Get_Struct(self, klass, data_type, ptr);\
        ptr->attr = R_##type##_to_C_##type(val);\
        return val;\
    }

//! define attribute writer when attribute name is different from the field name
#define IMPLEMENT_TYPED_ATTR_WRITERF(klass, attr, field, type, data_type) \
    {\
        klass *ptr;\
        if (rb_obj_is_kind_of(self, Class_Image) == Qtrue) {\
            rm_check_destroyed(self); \
        }\
        rb_check_frozen(self);\
        TypedData_Get_Struct(self, klass, data_type, ptr);\
        ptr->field = R_##type##_to_C_##type(val);\
        return self;\
    }


/*
 *  Declare attribute accessors
 */
//! declare attribute reader
#define ATTR_READER(klass, attr) \
    extern VALUE klass##_##attr(VALUE);
//! declare attribute writer
#define ATTR_WRITER(klass, attr) \
    extern VALUE klass##_##attr##_eq(VALUE, VALUE);
//! declare attribute accessor
#define ATTR_ACCESSOR(klass, attr) \
    ATTR_READER(klass, attr)\
    ATTR_WRITER(klass, attr)


//!  Define a Magick module constant
#if MAGICKCORE_QUANTUM_DEPTH == 64
#define DEF_CONST(constant) rb_define_const(Module_Magick, #constant, ULL2NUM(constant))
#define DEF_CONSTV(constant, val) rb_define_const(Module_Magick, #constant, ULL2NUM(val))
#else   // MAGICKCORE_QUANTUM_DEPTH == 8, 16, 32
#define DEF_CONST(constant) rb_define_const(Module_Magick, #constant, UINT2NUM(constant))
#define DEF_CONSTV(constant, val) rb_define_const(Module_Magick, #constant, UINT2NUM(val))
#endif

//! Convert a Ruby enum constant back to a C enum member.
#define VALUE_TO_ENUM(value, e, type) \
   do {\
   MagickEnum *magick_enum;\
   if (CLASS_OF(value) != Class_##type)\
       rb_raise(rb_eTypeError, "wrong enumeration type - expected %s, got %s", \
                rb_class2name(Class_##type), rb_class2name(CLASS_OF(value)));\
   TypedData_Get_Struct(value, MagickEnum, &rm_enum_data_type, magick_enum);\
   e = (type)(magick_enum->val);\
   } while(0)


// Method, external function declarations. These declarations are
// grouped by the source file in which the methods are defined.

// We don't need any "extern/no extern" stuff here. An external function
// declaration can refer to a function defined in another source file or
// the same source file.


extern "C" {

// rmmain.cpp
extern void Init_RMagick2(void);


// rmagick.cpp
extern VALUE Magick_colors(VALUE);
extern VALUE Magick_fonts(VALUE);
extern VALUE Magick_init_formats(VALUE);
extern VALUE Magick_limit_resource(int, VALUE *, VALUE);
extern VALUE Magick_set_cache_threshold(VALUE, VALUE);
extern VALUE Magick_set_log_event_mask(int, VALUE *, VALUE);
extern VALUE Magick_set_log_format(VALUE, VALUE);

// rmdraw.cpp
ATTR_WRITER(Draw, affine)
ATTR_WRITER(Draw, align)
ATTR_WRITER(Draw, border_color)
ATTR_WRITER(Draw, decorate)
ATTR_WRITER(Draw, density)
ATTR_WRITER(Draw, encoding)
ATTR_WRITER(Draw, fill)
ATTR_WRITER(Draw, fill_pattern)
ATTR_WRITER(Draw, font)
ATTR_WRITER(Draw, font_family)
ATTR_WRITER(Draw, font_stretch)
ATTR_WRITER(Draw, font_style)
ATTR_WRITER(Draw, font_weight)
ATTR_WRITER(Draw, gravity)
ATTR_WRITER(Draw, interline_spacing)
ATTR_WRITER(Draw, interword_spacing)
ATTR_WRITER(Draw, kerning)
ATTR_WRITER(Draw, pointsize)
ATTR_WRITER(Draw, rotation)
ATTR_WRITER(Draw, stroke)
ATTR_WRITER(Draw, stroke_pattern)
ATTR_WRITER(Draw, stroke_width)
ATTR_WRITER(Draw, text_antialias)
ATTR_WRITER(Draw, tile)
ATTR_WRITER(Draw, undercolor)
extern VALUE Draw_alloc(VALUE);
extern VALUE Draw_annotate(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Draw_clone(VALUE);
extern VALUE Draw_composite(int, VALUE *, VALUE);
extern VALUE Draw_draw(VALUE, VALUE);
extern VALUE Draw_dup(VALUE);
extern VALUE Draw_get_multiline_type_metrics(int, VALUE *, VALUE);
extern VALUE Draw_get_type_metrics(int, VALUE *, VALUE);
extern VALUE Draw_init_copy(VALUE, VALUE);
extern VALUE Draw_initialize(VALUE);
extern VALUE Draw_inspect(VALUE);
extern VALUE Draw_marshal_dump(VALUE);
extern VALUE Draw_marshal_load(VALUE, VALUE);
extern VALUE Draw_primitive(VALUE, VALUE);
extern VALUE DrawOptions_alloc(VALUE);
extern VALUE DrawOptions_initialize(VALUE);


extern VALUE PolaroidOptions_alloc(VALUE);
extern VALUE PolaroidOptions_initialize(VALUE);
extern VALUE rm_polaroid_new(void);
ATTR_WRITER(PolaroidOptions, shadow_color);
ATTR_WRITER(PolaroidOptions, border_color);


// rmmontage.cpp
ATTR_WRITER(Montage, background_color)
ATTR_WRITER(Montage, border_color)
ATTR_WRITER(Montage, border_width)
ATTR_WRITER(Montage, compose)
ATTR_WRITER(Montage, filename)
ATTR_WRITER(Montage, fill)
ATTR_WRITER(Montage, font)
ATTR_WRITER(Montage, frame)
ATTR_WRITER(Montage, geometry)
ATTR_WRITER(Montage, gravity)
ATTR_WRITER(Montage, matte_color)
ATTR_WRITER(Montage, pointsize)
ATTR_WRITER(Montage, shadow)
ATTR_WRITER(Montage, stroke)
ATTR_WRITER(Montage, texture)
ATTR_WRITER(Montage, tile)
ATTR_WRITER(Montage, title)
extern VALUE Montage_initialize(VALUE);
extern VALUE Montage_alloc(VALUE);
extern VALUE rm_montage_new(void);


// rmilist.cpp
extern VALUE ImageList_animate(int, VALUE *, VALUE);
extern VALUE ImageList_append(VALUE, VALUE);
extern VALUE ImageList_average(VALUE);
extern VALUE ImageList_coalesce(VALUE);
extern VALUE ImageList_combine(int, VALUE *, VALUE);
extern VALUE ImageList_composite_layers(int, VALUE *, VALUE);
extern VALUE ImageList_deconstruct(VALUE);
extern VALUE ImageList_display(VALUE);
extern VALUE ImageList_flatten_images(VALUE);
extern VALUE ImageList_montage(VALUE);
extern VALUE ImageList_morph(VALUE, VALUE);
extern VALUE ImageList_mosaic(VALUE);
extern VALUE ImageList_optimize_layers(VALUE, VALUE);
extern VALUE ImageList_quantize(int, VALUE*, VALUE);
extern VALUE ImageList_remap(int, VALUE *, VALUE);
extern VALUE ImageList_to_blob(VALUE);
extern VALUE ImageList_write(VALUE, VALUE);

extern VALUE rm_imagelist_from_images(Image *);


// rminfo.cpp
ATTR_ACCESSOR(Info, antialias)
ATTR_ACCESSOR(Info, attenuate)
ATTR_ACCESSOR(Info, authenticate)
ATTR_ACCESSOR(Info, background_color)
ATTR_ACCESSOR(Info, border_color)
ATTR_ACCESSOR(Info, caption)
ATTR_ACCESSOR(Info, colorspace)
ATTR_ACCESSOR(Info, comment)
ATTR_ACCESSOR(Info, compression)
ATTR_ACCESSOR(Info, delay)
ATTR_ACCESSOR(Info, density)
ATTR_ACCESSOR(Info, depth)
ATTR_ACCESSOR(Info, dispose)
ATTR_ACCESSOR(Info, dither)
ATTR_ACCESSOR(Info, encoding)
ATTR_ACCESSOR(Info, endian)
ATTR_ACCESSOR(Info, extract)
ATTR_ACCESSOR(Info, filename)
ATTR_ACCESSOR(Info, fill)
ATTR_ACCESSOR(Info, font)
ATTR_ACCESSOR(Info, format)
ATTR_ACCESSOR(Info, fuzz)
ATTR_ACCESSOR(Info, gravity)
ATTR_ACCESSOR(Info, image_type)
ATTR_ACCESSOR(Info, interlace)
ATTR_ACCESSOR(Info, label)
ATTR_ACCESSOR(Info, matte_color)
ATTR_WRITER(Info, monitor)
ATTR_ACCESSOR(Info, monochrome)
ATTR_ACCESSOR(Info, number_scenes)
ATTR_ACCESSOR(Info, orientation)
ATTR_ACCESSOR(Info, origin)
ATTR_ACCESSOR(Info, page)
ATTR_ACCESSOR(Info, pen)
ATTR_ACCESSOR(Info, pointsize)
ATTR_ACCESSOR(Info, quality)
ATTR_ACCESSOR(Info, sampling_factor)
ATTR_ACCESSOR(Info, scene)
ATTR_ACCESSOR(Info, server_name)
ATTR_ACCESSOR(Info, size)
ATTR_ACCESSOR(Info, stroke)
ATTR_ACCESSOR(Info, stroke_width)
ATTR_WRITER(Info, texture)
ATTR_ACCESSOR(Info, tile_offset)
ATTR_ACCESSOR(Info, transparent_color)
ATTR_ACCESSOR(Info, undercolor)
ATTR_ACCESSOR(Info, units)
ATTR_ACCESSOR(Info, view)

extern VALUE Info_alloc(VALUE);

extern VALUE Info_define(int, VALUE *, VALUE);
extern VALUE Info_aset(int, VALUE *, VALUE);
extern VALUE Info_aref(int, VALUE *, VALUE);
extern VALUE Info_channel(int, VALUE *, VALUE);
extern VALUE Info_undefine(VALUE, VALUE, VALUE);
extern VALUE Info_initialize(VALUE);
extern VALUE rm_info_new(void);
extern DisposeType rm_dispose_to_enum(const char *);
extern GravityType rm_gravity_to_enum(const char *);

// rmkinfo.cpp

extern VALUE KernelInfo_alloc(VALUE);

extern VALUE KernelInfo_initialize(VALUE, VALUE);
extern VALUE KernelInfo_unity_add(VALUE, VALUE);
extern VALUE KernelInfo_scale(VALUE, VALUE, VALUE);
extern VALUE KernelInfo_scale_geometry(VALUE, VALUE);
extern VALUE KernelInfo_clone(VALUE);

extern VALUE KernelInfo_builtin(VALUE, VALUE, VALUE);


// rmimage.cpp
ATTR_ACCESSOR(Image, background_color)
ATTR_READER(Image, base_columns)
ATTR_READER(Image, base_filename)
ATTR_READER(Image, base_rows)
ATTR_ACCESSOR(Image, bias)
ATTR_ACCESSOR(Image, black_point_compensation)
ATTR_ACCESSOR(Image, border_color)
ATTR_READER(Image, bounding_box)
ATTR_ACCESSOR(Image, chromaticity)
ATTR_ACCESSOR(Image, class_type)
ATTR_ACCESSOR(Image, color_profile)
ATTR_READER(Image, colors)
ATTR_ACCESSOR(Image, colorspace)
ATTR_READER(Image, columns)
ATTR_ACCESSOR(Image, compose)
ATTR_ACCESSOR(Image, compression)
ATTR_ACCESSOR(Image, delay)
ATTR_ACCESSOR(Image, density)
ATTR_READER(Image, depth)
ATTR_READER(Image, directory)
ATTR_ACCESSOR(Image, dispose)
ATTR_ACCESSOR(Image, endian)
ATTR_ACCESSOR(Image, extract_info)
ATTR_READER(Image, filename)
ATTR_READER(Image, filesize)
ATTR_ACCESSOR(Image, filter)
ATTR_ACCESSOR(Image, format)
ATTR_ACCESSOR(Image, fuzz)
ATTR_ACCESSOR(Image, gamma)
ATTR_ACCESSOR(Image, geometry)
ATTR_ACCESSOR(Image, gravity)
ATTR_ACCESSOR(Image, image_type)
ATTR_ACCESSOR(Image, interlace)
ATTR_ACCESSOR(Image, iptc_profile)
ATTR_ACCESSOR(Image, iterations)
ATTR_ACCESSOR(Image, matte_color)
ATTR_READER(Image, mean_error_per_pixel)
ATTR_READER(Image, mime_type)
ATTR_WRITER(Image, monitor)
ATTR_READER(Image, montage)
ATTR_READER(Image, normalized_mean_error)
ATTR_READER(Image, normalized_maximum_error)
ATTR_READER(Image, number_colors)
ATTR_ACCESSOR(Image, offset)
ATTR_ACCESSOR(Image, orientation)
ATTR_ACCESSOR(Image, page)
ATTR_ACCESSOR(Image, pixel_interpolation_method)
ATTR_READER(Image, quality)
ATTR_READER(Image, quantum_depth)
ATTR_ACCESSOR(Image, rendering_intent)
ATTR_READER(Image, rows)
ATTR_READER(Image, scene)
ATTR_ACCESSOR(Image, start_loop)
ATTR_ACCESSOR(Image, ticks_per_second)
ATTR_READER(Image, total_colors)
ATTR_READER(Image, total_ink_density)
ATTR_ACCESSOR(Image, transparent_color)
ATTR_ACCESSOR(Image, units)
ATTR_ACCESSOR(Image, virtual_pixel_method)
ATTR_ACCESSOR(Image, x_resolution)
ATTR_ACCESSOR(Image, y_resolution)

extern ChannelType extract_channels(int *, VALUE *);
extern void raise_ChannelType_error(VALUE) ATTRIBUTE_NORETURN;
extern void add_format_prefix(Info *, VALUE);

extern VALUE Image_alloc(VALUE);
extern VALUE Image_initialize(int, VALUE *, VALUE);
extern VALUE Image_adaptive_blur(int, VALUE *, VALUE);
extern VALUE Image_adaptive_blur_channel(int, VALUE *, VALUE);
extern VALUE Image_adaptive_resize(int, VALUE *, VALUE);
extern VALUE Image_adaptive_sharpen(int, VALUE *, VALUE);
extern VALUE Image_adaptive_sharpen_channel(int, VALUE *, VALUE);
extern VALUE Image_adaptive_threshold(int, VALUE *, VALUE);
extern VALUE Image_add_compose_mask(VALUE, VALUE);
extern VALUE Image_add_noise(VALUE, VALUE);
extern VALUE Image_add_noise_channel(int, VALUE *, VALUE);
extern VALUE Image_add_profile(VALUE, VALUE);
extern VALUE Image_affine_transform(VALUE, VALUE);
extern VALUE Image_alpha(int, VALUE *, VALUE);
extern VALUE Image_alpha_q(VALUE);
extern VALUE Image_aref(VALUE, VALUE);
extern VALUE Image_aset(VALUE, VALUE, VALUE);
extern VALUE Image_auto_gamma_channel(int, VALUE *, VALUE);
extern VALUE Image_auto_level_channel(int, VALUE *, VALUE);
extern VALUE Image_auto_orient(VALUE);
extern VALUE Image_auto_orient_bang(VALUE);
extern VALUE Image_properties(VALUE);
extern VALUE Image_bilevel_channel(int, VALUE *, VALUE);
extern VALUE Image_black_threshold(int, VALUE *, VALUE);
extern VALUE Image_blend(int, VALUE *, VALUE);
extern VALUE Image_blue_shift(int, VALUE *, VALUE);
extern VALUE Image_blur_image(int, VALUE *, VALUE);
extern VALUE Image_blur_channel(int, VALUE *, VALUE);
extern VALUE Image_border(VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_border_bang(VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_capture(int, VALUE *, VALUE);
extern VALUE Image_change_geometry(VALUE, VALUE);
extern VALUE Image_changed_q(VALUE);
extern VALUE Image_channel(VALUE, VALUE);
extern VALUE Image_check_destroyed(VALUE);
extern VALUE Image_compare_channel(int, VALUE *, VALUE);
extern VALUE Image_channel_depth(int, VALUE *, VALUE);
extern VALUE Image_channel_extrema(int, VALUE *, VALUE);
extern VALUE Image_channel_mean(int, VALUE *, VALUE);
#if defined(HAVE_GETIMAGECHANNELENTROPY) || defined(IMAGEMAGICK_7)
extern VALUE Image_channel_entropy(int, VALUE *, VALUE);
#else
extern VALUE Image_channel_entropy(int, VALUE *, VALUE) ATTRIBUTE_NORETURN;
#endif
extern VALUE Image_charcoal(int, VALUE *, VALUE);
extern VALUE Image_chop(VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_clone(VALUE);
extern VALUE Image_clut_channel(int, VALUE *, VALUE);
extern VALUE Image_color_flood_fill(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_color_histogram(VALUE);
extern VALUE Image_colorize(int, VALUE *, VALUE);
extern VALUE Image_colormap(int, VALUE *, VALUE);
extern VALUE Image_composite(int, VALUE *, VALUE);
extern VALUE Image_composite_affine(VALUE, VALUE, VALUE);
extern VALUE Image_composite_bang(int, VALUE *, VALUE);
extern VALUE Image_composite_channel(int, VALUE *, VALUE);
extern VALUE Image_composite_channel_bang(int, VALUE *, VALUE);
extern VALUE Image_composite_mathematics(int, VALUE *, VALUE);
extern VALUE Image_composite_tiled(int, VALUE *, VALUE);
extern VALUE Image_composite_tiled_bang(int, VALUE *, VALUE);
extern VALUE Image_compress_colormap_bang(VALUE);
extern VALUE Image_constitute(VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_contrast(int, VALUE *, VALUE);
extern VALUE Image_contrast_stretch_channel(int, VALUE *, VALUE);
extern VALUE Image_convolve(VALUE, VALUE, VALUE);
extern VALUE Image_convolve_channel(int, VALUE *, VALUE);
extern VALUE Image_morphology(VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_morphology_channel(VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_copy(VALUE);
extern VALUE Image_crop(int, VALUE *, VALUE);
extern VALUE Image_crop_bang(int, VALUE *, VALUE);
extern VALUE Image_cycle_colormap(VALUE, VALUE);
extern VALUE Image_decipher(VALUE, VALUE);
extern VALUE Image_define(VALUE, VALUE, VALUE);
extern VALUE Image_delete_profile(VALUE, VALUE);
extern VALUE Image_delete_compose_mask(VALUE);
extern VALUE Image_deskew(int, VALUE *, VALUE);
extern VALUE Image_despeckle(VALUE);
extern VALUE Image_destroy_bang(VALUE);
extern VALUE Image_destroyed_q(VALUE);
extern VALUE Image_difference(VALUE, VALUE);
extern VALUE Image_dispatch(int, VALUE *, VALUE);
extern VALUE Image_displace(int, VALUE *, VALUE);
extern VALUE Image_display(VALUE);
extern VALUE Image_dissolve(int, VALUE *, VALUE);
extern VALUE Image_distort(int, VALUE *, VALUE);
extern VALUE Image_distortion_channel(int, VALUE *, VALUE);
extern VALUE Image__dump(VALUE, VALUE);
extern VALUE Image_dup(VALUE);
extern VALUE Image_each_profile(VALUE);
extern VALUE Image_edge(int, VALUE *, VALUE);
extern VALUE Image_emboss(int, VALUE *, VALUE);
extern VALUE Image_encipher(VALUE, VALUE);
extern VALUE Image_enhance(VALUE);
extern VALUE Image_equalize(VALUE);
extern VALUE Image_equalize_channel(int, VALUE *, VALUE);
extern VALUE Image_erase_bang(VALUE);
extern VALUE Image_excerpt(VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_excerpt_bang(VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_export_pixels(int, VALUE *, VALUE);
extern VALUE Image_export_pixels_to_str(int, VALUE *, VALUE);
extern VALUE Image_extent(int, VALUE *, VALUE);
extern VALUE Image_find_similar_region(int, VALUE *, VALUE);
extern VALUE Image_flip(VALUE);
extern VALUE Image_flip_bang(VALUE);
extern VALUE Image_flop(VALUE);
extern VALUE Image_flop_bang(VALUE);
extern VALUE Image_frame(int, VALUE *, VALUE);
extern VALUE Image_from_blob(VALUE, VALUE);
extern VALUE Image_function_channel(int, VALUE *, VALUE);
extern VALUE Image_fx(int, VALUE *, VALUE);
extern VALUE Image_gamma_channel(int, VALUE *, VALUE);
extern VALUE Image_gamma_correct(int, VALUE *, VALUE);
extern VALUE Image_gaussian_blur(int, VALUE *, VALUE);
extern VALUE Image_gaussian_blur_channel(int, VALUE *, VALUE);
extern VALUE Image_get_pixels(VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_gray_q(VALUE);
extern VALUE Image_histogram_q(VALUE);
extern VALUE Image_implode(int, VALUE *, VALUE);
extern VALUE Image_import_pixels(int, VALUE *, VALUE);
extern VALUE Image_init_copy(VALUE, VALUE);
extern VALUE Image_inspect(VALUE);
extern VALUE Image_level2(int, VALUE *, VALUE);
extern VALUE Image_level_channel(int, VALUE *, VALUE);
extern VALUE Image_level_colors(int, VALUE *, VALUE);
extern VALUE Image_levelize_channel(int, VALUE *, VALUE);
extern VALUE Image_linear_stretch(int, VALUE *, VALUE);
extern VALUE Image_liquid_rescale(int, VALUE *, VALUE);
extern VALUE Image__load(VALUE, VALUE);
extern VALUE Image_magnify(VALUE);
extern VALUE Image_magnify_bang(VALUE);
extern VALUE Image_marshal_dump(VALUE);
extern VALUE Image_marshal_load(VALUE, VALUE);
extern VALUE Image_mask(int, VALUE *, VALUE);
extern VALUE Image_matte_flood_fill(int, VALUE *, VALUE);
extern VALUE Image_median_filter(int, VALUE *, VALUE);
extern VALUE Image_minify(VALUE);
extern VALUE Image_minify_bang(VALUE);
extern VALUE Image_modulate(int, VALUE *, VALUE);
extern VALUE Image_monochrome_q(VALUE);
extern VALUE Image_motion_blur(int, VALUE *, VALUE);
extern VALUE Image_negate(int, VALUE *, VALUE);
extern VALUE Image_negate_channel(int, VALUE *, VALUE);
extern VALUE Image_normalize(VALUE);
extern VALUE Image_normalize_channel(int, VALUE *, VALUE);
extern VALUE Image_oil_paint(int, VALUE *, VALUE);
extern VALUE Image_opaque(VALUE, VALUE, VALUE);
extern VALUE Image_opaque_channel(int, VALUE *, VALUE);
extern VALUE Image_opaque_q(VALUE);
extern VALUE Image_ordered_dither(int, VALUE *, VALUE);
extern VALUE Image_paint_transparent(int, VALUE *, VALUE);
extern VALUE Image_palette_q(VALUE);
extern VALUE Image_ping(VALUE, VALUE);
extern VALUE Image_pixel_color(int, VALUE *, VALUE);
extern VALUE Image_polaroid(int, VALUE *, VALUE);
extern VALUE Image_posterize(int, VALUE *, VALUE);
extern VALUE Image_preview(VALUE, VALUE);
extern VALUE Image_profile_bang(VALUE, VALUE, VALUE);
extern VALUE Image_quantize(int, VALUE *, VALUE);
extern VALUE Image_quantization_error(VALUE);
extern VALUE Image_quantum_operator(int, VALUE *, VALUE);
extern VALUE Image_radial_blur(VALUE, VALUE);
extern VALUE Image_radial_blur_channel(int, VALUE *, VALUE);
extern VALUE Image_raise(int, VALUE *, VALUE);
extern VALUE Image_random_threshold_channel(int, VALUE *, VALUE);
extern VALUE Image_read(VALUE, VALUE);
extern VALUE Image_read_inline(VALUE, VALUE);
extern VALUE Image_recolor(VALUE, VALUE);
extern VALUE Image_reduce_noise(VALUE, VALUE);
extern VALUE Image_remap(int, VALUE *, VALUE);
extern VALUE Image_resample(int, VALUE *, VALUE);
extern VALUE Image_resample_bang(int, VALUE *, VALUE);
extern VALUE Image_resize(int, VALUE *, VALUE);
extern VALUE Image_resize_bang(int, VALUE *, VALUE);
extern VALUE Image_roll(VALUE, VALUE, VALUE);
extern VALUE Image_rotate(int, VALUE *, VALUE);
extern VALUE Image_rotate_bang(int, VALUE *, VALUE);
extern VALUE Image_sample(int, VALUE *, VALUE);
extern VALUE Image_sample_bang(int, VALUE *, VALUE);
extern VALUE Image_scale(int, VALUE *, VALUE);
extern VALUE Image_scale_bang(int, VALUE *, VALUE);
extern VALUE Image_selective_blur_channel(int, VALUE *, VALUE);
extern VALUE Image_segment(int, VALUE *, VALUE);
extern VALUE Image_separate(int, VALUE *, VALUE);
extern VALUE Image_sepiatone(int, VALUE *, VALUE);
extern VALUE Image_set_channel_depth(VALUE, VALUE, VALUE);
extern VALUE Image_shade(int, VALUE *, VALUE);
extern VALUE Image_shadow(int, VALUE *, VALUE);
extern VALUE Image_sharpen(int, VALUE *, VALUE);
extern VALUE Image_sharpen_channel(int, VALUE *, VALUE);
extern VALUE Image_shave(VALUE, VALUE, VALUE);
extern VALUE Image_shave_bang(VALUE, VALUE, VALUE);
extern VALUE Image_shear(VALUE, VALUE, VALUE);
extern VALUE Image_sigmoidal_contrast_channel(int, VALUE *, VALUE);
extern VALUE Image_signature(VALUE);
extern VALUE Image_sketch(int, VALUE *, VALUE);
extern VALUE Image_solarize(int, VALUE *, VALUE);
extern VALUE Image_spaceship(VALUE, VALUE);
extern VALUE Image_sparse_color(int, VALUE *, VALUE);
extern VALUE Image_splice(int, VALUE *, VALUE);
extern VALUE Image_spread(int, VALUE *, VALUE);
extern VALUE Image_stegano(VALUE, VALUE, VALUE);
extern VALUE Image_stereo(VALUE, VALUE);
extern VALUE Image_store_pixels(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_strip_bang(VALUE);
extern VALUE Image_swirl(VALUE, VALUE);
extern VALUE Image_texture_flood_fill(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE Image_threshold(VALUE, VALUE);
extern VALUE Image_thumbnail(int, VALUE *, VALUE);
extern VALUE Image_thumbnail_bang(int, VALUE *, VALUE);
extern VALUE Image_tint(int, VALUE *, VALUE);
extern VALUE Image_to_blob(VALUE);
extern VALUE Image_to_color(VALUE, VALUE);
extern VALUE Image_transparent(int, VALUE *, VALUE);
extern VALUE Image_transparent_chroma(int, VALUE *, VALUE);
extern VALUE Image_transpose(VALUE);
extern VALUE Image_transpose_bang(VALUE);
extern VALUE Image_transverse(VALUE);
extern VALUE Image_transverse_bang(VALUE);
extern VALUE Image_trim(int, VALUE *, VALUE);
extern VALUE Image_trim_bang(int, VALUE *, VALUE);
extern VALUE Image_undefine(VALUE, VALUE);
extern VALUE Image_unique_colors(VALUE);
extern VALUE Image_unsharp_mask(int, VALUE *, VALUE);
extern VALUE Image_unsharp_mask_channel(int, VALUE *, VALUE);
extern VALUE Image_vignette(int, VALUE *, VALUE);
extern VALUE Image_watermark(int, VALUE *, VALUE);
extern VALUE Image_wave(int, VALUE *, VALUE);
extern VALUE Image_wet_floor(int, VALUE *, VALUE);
extern VALUE Image_white_threshold(int, VALUE *, VALUE);
extern VALUE Image_write(VALUE, VALUE);

extern VALUE rm_image_new(Image *);
extern void  rm_image_destroy(void *);


// rmfill.cpp
extern VALUE  GradientFill_alloc(VALUE);
extern VALUE  GradientFill_initialize(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);
extern VALUE  GradientFill_fill(VALUE, VALUE);

extern VALUE  TextureFill_alloc(VALUE);
extern VALUE  TextureFill_initialize(VALUE, VALUE);
extern VALUE  TextureFill_fill(VALUE, VALUE);


// rmpixel.cpp


ATTR_ACCESSOR(Pixel, red)
ATTR_ACCESSOR(Pixel, green)
ATTR_ACCESSOR(Pixel, blue)
ATTR_ACCESSOR(Pixel, alpha)
ATTR_ACCESSOR(Pixel, cyan)
ATTR_ACCESSOR(Pixel, magenta)
ATTR_ACCESSOR(Pixel, yellow)
ATTR_ACCESSOR(Pixel, black)
extern VALUE  Pixel_alloc(VALUE);
extern VALUE  Pixel_case_eq(VALUE, VALUE);
extern VALUE  Pixel_clone(VALUE);
extern VALUE  Pixel_dup(VALUE);
extern VALUE  Pixel_eql_q(VALUE, VALUE);
extern VALUE  Pixel_fcmp(int, VALUE *, VALUE);
extern VALUE  Pixel_from_color(VALUE, VALUE);
extern VALUE  Pixel_from_hsla(int, VALUE *, VALUE);
extern VALUE  Pixel_hash(VALUE);
extern VALUE  Pixel_initialize(int, VALUE *, VALUE);
extern VALUE  Pixel_init_copy(VALUE, VALUE);
extern VALUE  Pixel_intensity(VALUE);
extern VALUE  Pixel_marshal_dump(VALUE);
extern VALUE  Pixel_marshal_load(VALUE, VALUE);
extern VALUE  Pixel_spaceship(VALUE, VALUE);
extern VALUE  Pixel_to_color(int, VALUE *, VALUE);
extern VALUE  Pixel_to_hsla(VALUE);
extern VALUE  Pixel_to_s(VALUE);


// rmenum.cpp
extern VALUE  Enum_alloc(VALUE);
extern VALUE  Enum_initialize(VALUE, VALUE, VALUE);
extern VALUE  Enum_to_s(VALUE);
extern VALUE  Enum_to_i(VALUE);
extern VALUE  Enum_spaceship(VALUE, VALUE);
extern VALUE  Enum_bitwise_or(VALUE, VALUE);
extern VALUE  Enum_case_eq(VALUE, VALUE);
extern VALUE  Enum_type_initialize(VALUE, VALUE, VALUE);
extern VALUE  Enum_find(VALUE, int);
extern VALUE  Enum_type_each(VALUE);
extern VALUE  rm_enum_new(VALUE, VALUE, VALUE);
extern VALUE  ClassType_find(ClassType);
extern VALUE  ColorspaceType_find(ColorspaceType);
extern const char *ComplianceType_name(ComplianceType *);
extern VALUE  ComplianceType_find(ComplianceType);
extern VALUE  CompositeOperator_find(CompositeOperator);
extern VALUE  CompressionType_find(CompressionType);
extern VALUE  DisposeType_find(DisposeType);
extern VALUE  EndianType_find(EndianType);
extern VALUE  FilterType_find(FilterType);
extern VALUE  GravityType_find(GravityType);
extern VALUE  ImageType_find(ImageType);
extern VALUE  InterlaceType_find(InterlaceType);
extern VALUE  OrientationType_find(OrientationType);
extern VALUE  PixelInterpolateMethod_find(PixelInterpolateMethod);
extern VALUE  RenderingIntent_find(RenderingIntent);
extern VALUE  ResolutionType_find(ResolutionType);
extern const char *StorageType_name(StorageType);
extern VALUE  StretchType_find(StretchType);
extern const char *StretchType_name(StretchType);
extern VALUE  StyleType_find(StyleType);
extern const char *StyleType_name(StyleType);
extern VALUE  VirtualPixelMethod_find(VirtualPixelMethod);


// rmstruct.cpp
extern VALUE  ChromaticityInfo_to_s(VALUE);
extern VALUE  ChromaticityInfo_new(ChromaticityInfo *);
extern void   Color_to_PixelColor(PixelColor *, VALUE);
extern void   Color_to_MagickPixel(Image *, MagickPixel *, VALUE);
extern void   Color_to_Pixel(Pixel *, VALUE);
extern VALUE  Color_to_s(VALUE);
extern VALUE  Import_ColorInfo(const ColorInfo *);
extern VALUE  Font_to_s(VALUE);
extern VALUE  Pixel_from_MagickPixel(const MagickPixel *);
extern VALUE  Pixel_from_PixelColor(const PixelColor *);
extern VALUE  Pixel_from_PixelPacket(const PixelPacket *);
extern void   Export_PointInfo(PointInfo *, VALUE);
extern VALUE  Import_PointInfo(PointInfo *);
extern VALUE  PrimaryInfo_to_s(VALUE);
extern VALUE  Import_PrimaryInfo(PrimaryInfo *);
extern VALUE  RectangleInfo_to_s(VALUE);
extern VALUE  Import_RectangleInfo(RectangleInfo *);
extern VALUE  SegmentInfo_to_s(VALUE);
extern VALUE  Import_SegmentInfo(SegmentInfo *);
extern void   Export_AffineMatrix(AffineMatrix *, VALUE);
extern VALUE  Import_AffineMatrix(AffineMatrix *);
extern void   Export_ChromaticityInfo(ChromaticityInfo *, VALUE);
extern void   Export_ColorInfo(ColorInfo *, VALUE);
extern void   Export_PrimaryInfo(PrimaryInfo *, VALUE);
extern void   Export_RectangleInfo(RectangleInfo *, VALUE);
extern void   Export_SegmentInfo(SegmentInfo *, VALUE);
extern void   Font_to_TypeInfo(TypeInfo *, VALUE);
extern void   Export_TypeMetric(TypeMetric *, VALUE);
extern VALUE  Import_TypeInfo(const TypeInfo *);
extern VALUE  TypeMetric_to_s(VALUE);
extern void   Export_TypeInfo(TypeInfo *, VALUE);
extern VALUE  Import_TypeMetric(TypeMetric *);


// rmutil.cpp
extern VALUE  ImageMagickError_initialize(int, VALUE *, VALUE);
extern void  *magick_malloc(const size_t);
extern void  *magick_safe_malloc(const size_t, const size_t);
extern void   magick_free(void *);
extern void  *magick_safe_realloc(void *, const size_t, const size_t);
extern void   magick_clone_string(char **, const char *);
extern Image *rm_acquire_image(ImageInfo *);
extern VALUE  rm_cur_image(VALUE);
extern VALUE  rm_pixelcolor_to_color_name(Image *, PixelColor *);
extern VALUE  rm_pixelcolor_to_color_name_info(Info *, PixelColor *);
extern void   rm_init_magickpixel(const Image *, MagickPixel *);
extern void   rm_set_magickpixel(MagickPixel *, const char *);
extern VALUE  rm_no_freeze(VALUE) ATTRIBUTE_NORETURN;
extern int    rm_strcasecmp(const char *, const char *);
extern int    rm_strncasecmp(const char *, const char *, size_t);
extern size_t rm_strnlen_s(const char *, size_t);
extern void   rm_check_ary_len(VALUE, long);
extern VALUE  rm_check_ary_type(VALUE ary);
extern Image *rm_check_destroyed(VALUE);
extern Image *rm_check_frozen(VALUE);
extern char  *rm_str2cstr(VALUE, size_t *);
extern int    rm_check_num2dbl(VALUE);
extern double rm_fuzz_to_dbl(VALUE);
extern Quantum rm_app2quantum(VALUE);
extern double rm_percentage(VALUE, double);
extern double rm_percentage2(VALUE, double, bool);
extern double rm_str_to_pct(VALUE, bool);
extern VALUE  rm_define_enum_type(const char *);
extern void   rm_write_temp_image(Image *, char *, size_t);
extern void   rm_delete_temp_image(char *);
extern void   rm_not_implemented(void) ATTRIBUTE_NORETURN;
extern void   rm_attr_write(VALUE, VALUE);
extern const char *rm_get_property(const Image *, const char *);
extern MagickBooleanType rm_set_property(Image *, const char *, const char *);
extern void   rm_set_user_artifact(Image *, Info *);
extern void   rm_sync_image_options(Image *, Info *);
extern void   rm_split(Image *);
extern void   rm_magick_error(const char *);
#if defined(IMAGEMAGICK_7)
extern void   rm_set_pixelinfo_alpha(PixelInfo *, const MagickRealType);
#endif

//! whether to retain on errors
typedef enum
{
    RetainOnError = 0, /**< retain on error */
    DestroyOnError = 1 /**< do not retain on error */
} ErrorRetention;

typedef enum
{
    RetainExceptionRetention,
    DestroyExceptionRetention
} ExceptionRetention;

extern void   rm_check_exception(ExceptionInfo *, Image *, ErrorRetention);
extern void   rm_ensure_result(Image *);
extern Image *rm_clone_image(Image *);
extern VALUE  rm_exif_by_entry(Image *);
extern VALUE  rm_exif_by_number(Image *);
extern void   rm_get_optional_arguments(VALUE);
extern void   rm_fatal_error_handler(const ExceptionType, const char *, const char *) ATTRIBUTE_NORETURN;
extern void   rm_error_handler(const ExceptionType, const char *, const char *);
extern void   rm_warning_handler(const ExceptionType, const char *, const char *);
extern MagickBooleanType rm_should_raise_exception(ExceptionInfo *, const ExceptionRetention);
extern void   rm_raise_exception(ExceptionInfo *);
extern VALUE  rm_io_path(VALUE);
#if defined(IMAGEMAGICK_6)
extern void   rm_check_image_exception(Image *, ErrorRetention);
#endif

#if !defined(IMAGEMAGICK_GREATER_THAN_EQUAL_6_9_0)
/* UnityAddKernelInfo() was private function until IM 6.9 */
MagickExport void UnityAddKernelInfo(KernelInfo *kernel, const double scale);
/* ScaleKernelInfo() was private function until IM 6.9 */
MagickExport void ScaleKernelInfo(KernelInfo *kernel, const double scaling_factor, const GeometryFlags normalize_flags);
#endif

#define RESCUE_FUNC(func)                   (VALUE(*)(VALUE))(func)
#define RESCUE_EXCEPTION_HANDLER_FUNC(func) (VALUE(*)(VALUE, VALUE))(func)

} // extern "C"

#endif
