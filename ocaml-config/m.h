#ifndef __PIC__
#  define ARCH_CODE32
#endif
#undef ARCH_SIXTYFOUR
#define SIZEOF_INT 4
#define SIZEOF_LONG 4
#define SIZEOF_PTR 4
#define SIZEOF_SHORT 2
#define ARCH_INT64_TYPE long long
#define ARCH_UINT64_TYPE unsigned long long
#define ARCH_INT64_PRINTF_FORMAT "ll"
#undef ARCH_BIG_ENDIAN
#define ARCH_ALIGN_DOUBLE
#define ARCH_ALIGN_INT64
#undef NONSTANDARD_DIV_MOD
