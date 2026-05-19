/* test_utils.c: C89 unit tests for hed utility functions.
 * Tests: has_trailing_escape, strip_escapes, translit_text
 * Link against all editor object files except main.o.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ed.h"
#include "tests/test.h"

/* Forward declarations for functions under test that are not in ed.h */
int has_trailing_escape(char *s, char *t);
char *strip_escapes(char *s);

/* ------------------------------------------------------------------ */
/* has_trailing_escape tests                                           */
/* ------------------------------------------------------------------ */
static void test_has_trailing_escape(void)
{
    char s1[] = "abc";         /* no escape */
    char s2[] = "ab\\";       /* single trailing backslash */
    char s3[] = "ab\\\\";     /* double backslash (even parity = no escape) */
    char s4[] = "ab\\\\\\";   /* triple backslash (odd = escape) */
    char s5[] = "\\";         /* single backslash, len=1 */
    char s6[] = "a";          /* single non-backslash */

    OED_ASSERT(has_trailing_escape(s1, s1 + strlen(s1)) == 0,
               "no backslash: not a trailing escape");

    OED_ASSERT(has_trailing_escape(s2, s2 + strlen(s2)) != 0,
               "single trailing backslash is a trailing escape");

    OED_ASSERT(has_trailing_escape(s3, s3 + strlen(s3)) == 0,
               "double trailing backslash is not a trailing escape");

    OED_ASSERT(has_trailing_escape(s4, s4 + strlen(s4)) != 0,
               "triple trailing backslash is a trailing escape");

    OED_ASSERT(has_trailing_escape(s5, s5 + strlen(s5)) != 0,
               "lone backslash is a trailing escape");

    OED_ASSERT(has_trailing_escape(s6, s6 + strlen(s6)) == 0,
               "lone non-backslash is not a trailing escape");

    /* Empty string: s == t means no preceding char; return 0 */
    OED_ASSERT(has_trailing_escape(s1, s1) == 0,
               "empty range (s==t) is never a trailing escape");
}

/* ------------------------------------------------------------------ */
/* strip_escapes tests                                                 */
/* ------------------------------------------------------------------ */
static void test_strip_escapes(void)
{
    /* strip_escapes removes one level of backslash escaping */
    OED_EQ_STR("abc",      strip_escapes("abc"));
    OED_EQ_STR("a b",      strip_escapes("a b"));
    OED_EQ_STR("a/b",      strip_escapes("a\\/b"));
    OED_EQ_STR("a\\b",     strip_escapes("a\\\\b")); /* \\\\ -> \\ -> \ */
    OED_EQ_STR("",         strip_escapes(""));
    OED_EQ_STR("path/to",  strip_escapes("path\\/to"));
}

/* ------------------------------------------------------------------ */
/* translit_text tests                                                 */
/* ------------------------------------------------------------------ */
static void test_translit_text(void)
{
    char buf[32];

    /* translate NUL to newline */
    memcpy(buf, "a\0b", 3);
    translit_text(buf, 3, '\0', '\n');
    OED_ASSERT(buf[0] == 'a' && buf[1] == '\n' && buf[2] == 'b',
               "translit NUL to newline");

    /* translate newline to NUL */
    memcpy(buf, "a\nb", 3);
    translit_text(buf, 3, '\n', '\0');
    OED_ASSERT(buf[0] == 'a' && buf[1] == '\0' && buf[2] == 'b',
               "translit newline to NUL");

    /* identity translation (same from and to) */
    memcpy(buf, "hello", 5);
    translit_text(buf, 5, 'x', 'x');
    OED_ASSERT(memcmp(buf, "hello", 5) == 0,
               "identity translit leaves string unchanged");

    /* translate 'a' to 'z' */
    memcpy(buf, "banana", 6);
    translit_text(buf, 6, 'a', 'z');
    OED_EQ_STR("bznznz", buf);

    /* length 0 affects nothing */
    memcpy(buf, "abc", 3);
    translit_text(buf, 0, 'a', 'z');
    OED_ASSERT(buf[0] == 'a', "zero-length translit does nothing");

    /* consecutive translits: ctab is restored between calls */
    strcpy(buf, "aaa");
    translit_text(buf, 3, 'a', 'b');
    OED_EQ_STR("bbb", buf);

    strcpy(buf, "aaa");
    translit_text(buf, 3, 'b', 'c'); /* NOT affect 'a' since ctab restored */
    OED_EQ_STR("aaa", buf);
}

/* ------------------------------------------------------------------ */
/* main                                                                */
/* ------------------------------------------------------------------ */
int
main(void)
{
    TEST_INIT("test_utils");

    /* Initialise editor buffers (opens scratch file, sets up ctab) */
    init_buffers();

    test_has_trailing_escape();
    test_strip_escapes();
    test_translit_text();

    close_sbuf();

    return TEST_DONE();
}
