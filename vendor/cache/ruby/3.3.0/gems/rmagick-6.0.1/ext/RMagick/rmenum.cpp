/**************************************************************************//**
 * Enumeration methods.
 *
 * Copyright &copy; 2002 - 2009 by Timothy P. Hunter
 *
 * Changes since Nov. 2009 copyright &copy; by Benjamin Thomas and Omer Bar-or
 *
 * @file     rmenum.cpp
 * @version  $Id: rmenum.cpp,v 1.9 2009/12/20 02:33:33 baror Exp $
 * @author   Tim Hunter
 ******************************************************************************/

#include "rmagick.h"


#define ENUMERATORS_CLASS_VAR "@@enumerators"


static VALUE Enum_type_values(VALUE);
static VALUE Enum_type_inspect(VALUE);
static void rm_enum_free(void *magick_enum);
static size_t rm_enum_memsize(const void *magick_enum);

const rb_data_type_t rm_enum_data_type = {
    "Magick::Enum",
    { NULL, rm_enum_free, rm_enum_memsize, },
    0, 0,
    RUBY_TYPED_FROZEN_SHAREABLE,
};


/**
 * Set up a subclass of Enum.
 *
 * No Ruby usage (internal function)
 *
 * @param tag the name of the subclass
 * @return the subclass
 */
VALUE
rm_define_enum_type(const char *tag)
{
    VALUE klass;

    klass = rb_define_class_under(Module_Magick, tag, Class_Enum);\

    rb_define_singleton_method(klass, "values", RUBY_METHOD_FUNC(Enum_type_values), 0);
    rb_define_method(klass, "initialize", RUBY_METHOD_FUNC(Enum_type_initialize), 2);
    rb_define_method(klass, "inspect", RUBY_METHOD_FUNC(Enum_type_inspect), 0);
    return klass;
}


/**
 * Construct a new Enum subclass instance.
 *
 * No Ruby usage (internal function)
 *
 * @param klass the subclass
 * @param sym the symbol
 * @param val the value for the symbol
 * @return a new instance of class
 */
VALUE
rm_enum_new(VALUE klass, VALUE sym, VALUE val)
{
    VALUE argv[2];

    argv[0] = sym;
    argv[1] = val;
    return rb_obj_freeze(rb_class_new_instance(2, argv, klass));
}

/**
 * Retrieve C string value of Enum.
 *
 * No Ruby usage (internal function)
 *
 * @param enum_type the Enum object
 * @return the C string value of Enum object
 */
static const char *
rm_enum_to_cstr(VALUE enum_type)
{
    MagickEnum *magick_enum;

    TypedData_Get_Struct(enum_type, MagickEnum, &rm_enum_data_type, magick_enum);
    return rb_id2name(magick_enum->id);
}

/**
 * Free Enum or Enum subclass object
 *
 * No Ruby usage (internal function)
 *
 * @param magick_enum the enum
 */
static void rm_enum_free(void *magick_enum)
{
    xfree(magick_enum);
}

/**
  * Get Enum object size.
  *
  * No Ruby usage (internal function)
  *
  * @param magick_enum the enum
  */
 static size_t rm_enum_memsize(const void *magick_enum)
 {
     return sizeof(MagickEnum);
 }

/**
 * Enum class alloc function.
 *
 * @return [Magick::Enum] a new enumerator
 */
VALUE
Enum_alloc(VALUE klass)
{
    MagickEnum *magick_enum;
    VALUE enumr;

    enumr = TypedData_Make_Struct(klass, MagickEnum, &rm_enum_data_type, magick_enum);
    rb_obj_freeze(enumr);

    return enumr;
}


/**
 * "Case equal" operator for Enum.
 *
 * @param other [Object] the other object
 * @return [Boolean] true or false
 */
VALUE
Enum_case_eq(VALUE self, VALUE other)
{
    if (CLASS_OF(self) == CLASS_OF(other))
    {
        MagickEnum *self_enum, *other_enum;

        TypedData_Get_Struct(self, MagickEnum, &rm_enum_data_type, self_enum);
        TypedData_Get_Struct(other, MagickEnum, &rm_enum_data_type, other_enum);
        return self_enum->val == other_enum->val ? Qtrue : Qfalse;
    }

    return Qfalse;
}


/**
 * Initialize a new Enum instance.
 *
 * @param sym [Symbol] the symbol as enum name
 * @param val [Numeric] the value for enum
 * @return [Magick::Enum] self
 */
VALUE
Enum_initialize(VALUE self, VALUE sym, VALUE val)
{
    MagickEnum *magick_enum;

    TypedData_Get_Struct(self, MagickEnum, &rm_enum_data_type, magick_enum);
    magick_enum->id = rb_to_id(sym); /* convert symbol to ID */
    magick_enum->val = NUM2INT(val);

    return self;
}


/**
 * Return the value of an enum.
 *
 * @return [Numeric] this object's value
 */
VALUE
Enum_to_i(VALUE self)
{
    MagickEnum *magick_enum;

    TypedData_Get_Struct(self, MagickEnum, &rm_enum_data_type, magick_enum);
    return INT2NUM(magick_enum->val);
}


/**
 * Support Comparable module in Enum.
 *
 * @param other [Object] the other object
 * @return [-1, 0, 1, nil] the result of compare
 */
VALUE
Enum_spaceship(VALUE self, VALUE other)
{
    MagickEnum *self_enum, *other_enum;

    if(CLASS_OF(self) != CLASS_OF(other)) {
        return Qnil;
    }

    TypedData_Get_Struct(self, MagickEnum, &rm_enum_data_type, self_enum);
    TypedData_Get_Struct(other, MagickEnum, &rm_enum_data_type, other_enum);

    if (self_enum->val > other_enum->val)
    {
        return INT2FIX(1);
    }
    else if (self_enum->val < other_enum->val)
    {
        return INT2FIX(-1);
    }

    return INT2FIX(0);
}

/**
 * Bitwise OR for enums
 *
 * @param another [Magick::Enum] the another enum
 * @return [Magick::Enum] new Enum instance
 */
VALUE
Enum_bitwise_or(VALUE self, VALUE other)
{
    VALUE new_enum, klass;
    MagickEnum *self_enum, *other_enum, *new_enum_data;

    klass = CLASS_OF(self);
    if (CLASS_OF(other) != klass)
    {
        rb_raise(rb_eArgError, "Expected class %s but got %s", rb_class2name(klass), rb_class2name(CLASS_OF(other)));
    }

    new_enum = Enum_alloc(klass);

    TypedData_Get_Struct(self, MagickEnum, &rm_enum_data_type, self_enum);
    TypedData_Get_Struct(other, MagickEnum, &rm_enum_data_type, other_enum);
    TypedData_Get_Struct(new_enum, MagickEnum, &rm_enum_data_type, new_enum_data);

    new_enum_data->id = rb_to_id(rb_sprintf("%s|%s", rb_id2name(self_enum->id), rb_id2name(other_enum->id)));
    new_enum_data->val = self_enum->val | other_enum->val;

    return new_enum;
}

/**
 * Return the name of an enum.
 *
 * @return [String] the name of an enum
 */
VALUE
Enum_to_s(VALUE self)
{
    return rb_str_new2(rm_enum_to_cstr(self));
}


/**
 * Initialize method for all Enum subclasses.
 *
 * @param sym [Symbol] the symbol as enum name
 * @param val [Numeric] the value for enum
 * @return [Magick::Enum] self
 */
VALUE
Enum_type_initialize(VALUE self, VALUE sym, VALUE val)
{
    VALUE super_argv[2];
    VALUE enumerators;

    super_argv[0] = sym;
    super_argv[1] = val;
    rb_call_super(2, (const VALUE *)super_argv);

    if (rb_cvar_defined(CLASS_OF(self), rb_intern(ENUMERATORS_CLASS_VAR)) != Qtrue)
    {
        rb_cv_set(CLASS_OF(self), ENUMERATORS_CLASS_VAR, rb_ary_new());
    }

    enumerators = rb_cv_get(CLASS_OF(self), ENUMERATORS_CLASS_VAR);
    rb_ary_push(enumerators, self);

    RB_GC_GUARD(enumerators);

    return self;
}


/**
 * Enum subclass #inspect.
 *
 * @return [String] representation of self
 */
static VALUE
Enum_type_inspect(VALUE self)
{
    char str[100];
    MagickEnum *magick_enum;

    TypedData_Get_Struct(self, MagickEnum, &rm_enum_data_type, magick_enum);
    snprintf(str, sizeof(str), "%.48s=%d", rb_id2name(magick_enum->id), magick_enum->val);

    return rb_str_new2(str);
}


/**
 * Behaves like #each if a block is present, otherwise like #to_a.
 *
 * @overload values
 *   @return [Array<Magick::Enum>] the enum values
 *
 * @overload values
 *   iterator over values if given block
 *   @yield [val]
 *   @yieldparam val [Magick::Enum] an enum
 *   @return [Magick::Enum] self
 */
static VALUE
Enum_type_values(VALUE klass)
{
    VALUE enumerators, copy;
    VALUE rv;
    int x;

    enumerators = rb_cv_get(klass, ENUMERATORS_CLASS_VAR);

    if (rb_block_given_p())
    {
        for (x = 0; x < RARRAY_LEN(enumerators); x++)
        {
            rb_yield(rb_ary_entry(enumerators, x));
        }
        rv = klass;
    }
    else
    {
        copy = rb_ary_new2(RARRAY_LEN(enumerators));
        for (x = 0; x < RARRAY_LEN(enumerators); x++)
        {
            rb_ary_push(copy, rb_ary_entry(enumerators, x));
        }
        rb_obj_freeze(copy);
        rv = copy;
    }

    RB_GC_GUARD(enumerators);
    RB_GC_GUARD(copy);
    RB_GC_GUARD(rv);

    return rv;
}

/**
 * Find enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param klass the class type
 * @param value the value for enum
 * @return a enumerator
 */

VALUE
Enum_find(VALUE klass, int val)
{
    VALUE enumerators;
    MagickEnum *magick_enum;
    int x;

    enumerators = rb_cv_get(klass, ENUMERATORS_CLASS_VAR);
    enumerators = rm_check_ary_type(enumerators);

    for (x = 0; x < RARRAY_LEN(enumerators); x++)
    {
        VALUE enumerator = rb_ary_entry(enumerators, x);
        TypedData_Get_Struct(enumerator, MagickEnum, &rm_enum_data_type, magick_enum);
        if (magick_enum->val == val)
        {
            return enumerator;
        }
    }

    return Qnil;
}


/**
 * Returns a ClassType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param cls the class type
 * @return a new enumerator
 */
VALUE
ClassType_find(ClassType klass)
{
    return Enum_find(Class_ClassType, klass);
}


/**
 * Returns a ColorspaceType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param cs the ColorspaceType
 * @return a new ColorspaceType enumerator
 */
VALUE
ColorspaceType_find(ColorspaceType cs)
{
    return Enum_find(Class_ColorspaceType, cs);
}


/**
 * Return the string representation of a ComplianceType value.
 *
 * No Ruby usage (internal function)
 *
 * Notes:
 *   - xMagick will OR multiple compliance types so we have to arbitrarily pick
 *     one name.
 *   - Set the compliance argument to the selected value.
 *
 * @param c the ComplianceType value
 * @return the string
 */
const char *
ComplianceType_name(ComplianceType *c)
{
    if ((*c & (SVGCompliance|X11Compliance|XPMCompliance))
        == (SVGCompliance|X11Compliance|XPMCompliance))
    {
        return "AllCompliance";
    }
    else if (*c & SVGCompliance)
    {
        *c = SVGCompliance;
        return "SVGCompliance";
    }
    else if (*c & X11Compliance)
    {
        *c = X11Compliance;
        return "X11Compliance";
    }
    else if (*c & XPMCompliance)
    {
        *c = XPMCompliance;
        return "XPMCompliance";
    }
    else if (*c == NoCompliance)
    {
        *c = NoCompliance;
        return "NoCompliance";
    }
    else
    {
        *c = UndefinedCompliance;
        return "UndefinedCompliance";
    }
}


/**
 * Returns a ComplianceType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param compliance the C ComplianceType value
 * @return the Ruby ComplianceType enum object
 */
VALUE
ComplianceType_find(ComplianceType compliance)
{
    ComplianceType c;

    // Turn off undefined bits
    if ((compliance & (SVGCompliance|X11Compliance|XPMCompliance))
        == (SVGCompliance|X11Compliance|XPMCompliance))
    {
        c = (ComplianceType)(SVGCompliance|X11Compliance|XPMCompliance);
    }
    else if (compliance & SVGCompliance)
    {
        c = SVGCompliance;
    }
    else if (compliance & X11Compliance)
    {
        c = X11Compliance;
    }
    else if (compliance & XPMCompliance)
    {
        c = XPMCompliance;
    }
    else if (compliance == NoCompliance)
    {
        c = NoCompliance;
    }
    else
    {
        c = UndefinedCompliance;
    }
    return Enum_find(Class_ComplianceType, c);
}


/**
 * Returns a CompositeOperator enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param op the CompositeOperator
 * @return a new CompositeOperator enumerator
 */
VALUE
CompositeOperator_find(CompositeOperator op)
{
    return Enum_find(Class_CompositeOperator, op);
}


/**
 * Returns a CompressionType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param ct the CompressionType
 * @return a new CompressionType enumerator
 */
VALUE
CompressionType_find(CompressionType ct)
{
    return Enum_find(Class_CompressionType, ct);
}


/**
 * Returns a DisposeType enum object for the specified value..new.
 *
 * No Ruby usage (internal function)
 *
 * @param type the DisposeType
 * @return a new DisposeType enumerator
 */
VALUE
DisposeType_find(DisposeType type)
{
    return Enum_find(Class_DisposeType, type);
}


/**
 * Returns an EndianType enum object.
 *
 * No Ruby usage (internal function)
 *
 * @param type the EndianType
 * @return a new EndianType enumerator
 */
VALUE
EndianType_find(EndianType type)
{
    return Enum_find(Class_EndianType, type);
}


/**
 * Returns a FilterType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param type the FilterType
 * @return a new FilterType enumerator
 */
VALUE
FilterType_find(FilterType type)
{
    return Enum_find(Class_FilterType, type);
}


/**
 * Returns a GravityType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param type the GravityType
 * @return a new GravityType enumerator
 */
VALUE
GravityType_find(GravityType type)
{
    return Enum_find(Class_GravityType, type);
}


/**
 * Returns an ImageType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param type the ImageType
 * @return a new ImageType enumerator
 */
VALUE
ImageType_find(ImageType type)
{
    return Enum_find(Class_ImageType, type);
}


/**
 * Returns an InterlaceType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param interlace the InterlaceType
 * @return a new InterlaceType enumerator
 */
VALUE
InterlaceType_find(InterlaceType interlace)
{
    return Enum_find(Class_InterlaceType, interlace);
}


/**
 * Returns an OrientationType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param type the OrientationType
 * @return a new OrientationType enumerator
 */
VALUE
OrientationType_find(OrientationType type)
{
    return Enum_find(Class_OrientationType, type);
}


/**
 * Returns a PixelInterpolateMethod enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param interpolate the PixelInterpolateMethod
 * @return a new PixelInterpolateMethod enumerator
 */
VALUE
PixelInterpolateMethod_find(PixelInterpolateMethod interpolate)
{
    return Enum_find(Class_PixelInterpolateMethod, interpolate);
}


/**
 * Construct an RenderingIntent enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param intent the RenderingIntent
 * @return a new RenderingIntent enumerator
 */
VALUE
RenderingIntent_find(RenderingIntent intent)
{
    return Enum_find(Class_RenderingIntent, intent);
}


/**
 * Returns a ResolutionType enum object for the specified value.
 *
 * No Ruby usage (internal function)
 *
 * @param type the ResolutionType
 * @return a new ResolutionType enumerator
 */
VALUE
ResolutionType_find(ResolutionType type)
{
    return Enum_find(Class_ResolutionType, type);
}


/**
 * Return the string representation of a StorageType value.
 *
 * No Ruby usage (internal function)
 *
 * @param type the StorageType
 * @return the name
 */
const char *
StorageType_name(StorageType type)
{
    VALUE storage = Enum_find(Class_StorageType, type);
    if (NIL_P(storage))
    {
        return "UndefinedPixel";
    }
    return rm_enum_to_cstr(storage);
}


/**
 * Return the string representation of a StretchType value.
 *
 * No Ruby usage (internal function)
 *
 * @param stretch the StretchType value
 * @return the string
 */
const char *
StretchType_name(StretchType type)
{
    VALUE stretch = Enum_find(Class_StretchType, type);
    if (NIL_P(stretch))
    {
        return "UndefinedStretch";
    }
    return rm_enum_to_cstr(stretch);
}


/**
 * Returns a StretchType enum for a specified StretchType value.
 *
 * No Ruby usage (internal function)
 *
 * @param stretch the C StretchType value
 * @return a Ruby StretchType enum
 */
VALUE
StretchType_find(StretchType stretch)
{
    return Enum_find(Class_StretchType, stretch);
}


/**
 * Return the string representation of a StyleType value.
 *
 * No Ruby usage (internal function)
 *
 * @param style the StyleType value
 * @return the string
 */
const char *
StyleType_name(StyleType type)
{
    VALUE style = Enum_find(Class_StyleType, type);
    if (NIL_P(style))
    {
        return "UndefinedStyle";
    }
    return rm_enum_to_cstr(style);
}


/**
 * Returns a StyleType enum for a specified StyleType value.
 *
 * No Ruby usage (internal function)
 *
 * @param style the C StyleType value
 * @return a Ruby StyleType enum
 */
VALUE
StyleType_find(StyleType style)
{
    return Enum_find(Class_StyleType, style);
}


/**
 * Returns a VirtualPixelMethod enum for a specified VirtualPixelMethod value.
 *
 * No Ruby usage (internal function)
 *
 * @param style theVirtualPixelMethod
 * @return a new VirtualPixelMethod enumerator
 */
VALUE
VirtualPixelMethod_find(VirtualPixelMethod style)
{
    return Enum_find(Class_VirtualPixelMethod, style);
}
