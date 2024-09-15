#ifndef INCLUDE_features_h__
#define INCLUDE_features_h__

/* #undef GIT_DEBUG_POOL */
/* #undef GIT_DEBUG_STRICT_ALLOC */
/* #undef GIT_DEBUG_STRICT_OPEN */

#define GIT_THREADS 1
/* #undef GIT_WIN32_LEAKCHECK */

#define GIT_ARCH_64 1
/* #undef GIT_ARCH_32 */

#define GIT_USE_ICONV 1
#define GIT_USE_NSEC 1
/* #undef GIT_USE_STAT_MTIM */
#define GIT_USE_STAT_MTIMESPEC 1
/* #undef GIT_USE_STAT_MTIME_NSEC */
#define GIT_USE_FUTIMENS 1

/* #undef GIT_REGEX_REGCOMP_L */
/* #undef GIT_REGEX_REGCOMP */
/* #undef GIT_REGEX_PCRE */
/* #undef GIT_REGEX_PCRE2 */
#define GIT_REGEX_BUILTIN 1

#define GIT_QSORT_BSD
/* #undef GIT_QSORT_GNU */
/* #undef GIT_QSORT_C11 */
/* #undef GIT_QSORT_MSC */

/* #undef GIT_SSH */
/* #undef GIT_SSH_MEMORY_CREDENTIALS */

#define GIT_NTLM 1
/* #undef GIT_GSSAPI */
/* #undef GIT_GSSFRAMEWORK */

/* #undef GIT_WINHTTP */
#define GIT_HTTPS 1
/* #undef GIT_OPENSSL */
/* #undef GIT_OPENSSL_DYNAMIC */
#define GIT_SECURE_TRANSPORT 1
/* #undef GIT_MBEDTLS */
/* #undef GIT_SCHANNEL */

#define GIT_SHA1_COLLISIONDETECT 1
/* #undef GIT_SHA1_WIN32 */
/* #undef GIT_SHA1_COMMON_CRYPTO */
/* #undef GIT_SHA1_OPENSSL */
/* #undef GIT_SHA1_OPENSSL_DYNAMIC */
/* #undef GIT_SHA1_MBEDTLS */

/* #undef GIT_SHA256_BUILTIN */
/* #undef GIT_SHA256_WIN32 */
#define GIT_SHA256_COMMON_CRYPTO 1
/* #undef GIT_SHA256_OPENSSL */
/* #undef GIT_SHA256_OPENSSL_DYNAMIC */
/* #undef GIT_SHA256_MBEDTLS */

/* #undef GIT_RAND_GETENTROPY */
#define GIT_RAND_GETLOADAVG 1

#define GIT_IO_POLL 1
/* #undef GIT_IO_WSAPOLL */
#define GIT_IO_SELECT 1

#endif
