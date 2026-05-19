/* test.h: minimal C89 unit-test assertion macros for hed.
 * No external dependencies; include once per test binary's main source file.
 *
 * Usage:
 *   #include "tests/test.h"
 *   int main(void) {
 *       TEST_INIT("test_name");
 *       OED_ASSERT(1 == 1, "sanity");
 *       OED_EQ_INT(2, 1+1);
 *       OED_EQ_STR("ab", "ab");
 *       return TEST_DONE();
 *   }
 */

#ifndef OED_TEST_H
#define OED_TEST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int _t_passes = 0;
static int _t_failures = 0;
static const char *_t_suite = "unknown";

#define TEST_INIT(name) \
    do { _t_suite = (name); _t_passes = 0; _t_failures = 0; } while (0)

#define OED_ASSERT(cond, msg) \
    do { \
        if (cond) { \
            _t_passes++; \
            printf("PASS  %s: %s\n", _t_suite, (msg)); \
        } else { \
            _t_failures++; \
            printf("FAIL  %s: %s  (%s:%d)\n", _t_suite, (msg), __FILE__, __LINE__); \
        } \
    } while (0)

#define OED_EQ_INT(expected, got) \
    do { \
        int _e = (expected), _g = (got); \
        if (_e == _g) { \
            _t_passes++; \
            printf("PASS  %s: %s == %s (%d)\n", _t_suite, #expected, #got, _e); \
        } else { \
            _t_failures++; \
            printf("FAIL  %s: %s == %s: expected %d, got %d  (%s:%d)\n", \
                   _t_suite, #expected, #got, _e, _g, __FILE__, __LINE__); \
        } \
    } while (0)

#define OED_EQ_STR(expected, got) \
    do { \
        const char *_e = (expected), *_g = (got); \
        if (_e && _g && strcmp(_e, _g) == 0) { \
            _t_passes++; \
            printf("PASS  %s: \"%s\" == \"%s\"\n", _t_suite, _e, _e); \
        } else { \
            _t_failures++; \
            printf("FAIL  %s: expected \"%s\", got \"%s\"  (%s:%d)\n", \
                   _t_suite, _e ? _e : "(null)", _g ? _g : "(null)", \
                   __FILE__, __LINE__); \
        } \
    } while (0)

/* TEST_DONE: print summary line and return exit code (0=all pass, 1=failures) */
#define TEST_DONE() \
    ( \
        printf("--- %s: %d passed, %d failed\n", \
               _t_suite, _t_passes, _t_failures), \
        (_t_failures > 0) ? 1 : 0 \
    )

#endif /* OED_TEST_H */
