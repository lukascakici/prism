/*
 * Prism C sample.
 *
 * Exercises:
 *   - line and block comments
 *   - preprocessor directives
 *   - char literals ('x', '\n', '\xFF')
 *   - numeric literals (int, hex, oct, bin via gcc ext, float, scientific)
 *   - typedef / struct / union / enum
 *   - function definitions and pointers
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MAX_BUFFER 4096
#define SQUARE(x) ((x) * (x))

#ifdef DEBUG
    #define LOG(...) fprintf(stderr, __VA_ARGS__)
#else
    #define LOG(...) ((void) 0)
#endif

/* Constants */
static const double PI         = 3.14159265358979;
static const unsigned MASK     = 0xDEADBEEFu;
static const unsigned PERMS    = 0755;
static const double SCIENTIFIC = 6.022e23;
static const char NEWLINE      = '\n';
static const char ESC          = '\x1B';

/* Types */
typedef enum {
    LANG_C,
    LANG_CPP,
    LANG_OBJC,
    LANG_UNKNOWN,
} Language;

typedef struct {
    const char *name;
    Language    kind;
    int         year;
} Lang;

typedef union {
    int    as_int;
    float  as_float;
    char   as_bytes[4];
} Variant;

/* Forward declarations */
static const char *lang_name(Language kind);
static int compare_langs(const void *a, const void *b);

int main(int argc, char *argv[])
{
    Lang langs[] = {
        { .name = "C",   .kind = LANG_C,   .year = 1972 },
        { .name = "C++", .kind = LANG_CPP, .year = 1985 },
        { .name = "Obj-C", .kind = LANG_OBJC, .year = 1984 },
    };

    const size_t n = sizeof(langs) / sizeof(langs[0]);
    qsort(langs, n, sizeof(Lang), compare_langs);

    for (size_t i = 0; i < n; ++i) {
        const Lang *l = &langs[i];
        printf("%-6s (%s) — released %d%c", l->name, lang_name(l->kind), l->year, NEWLINE);
    }

    Variant v;
    v.as_int = 0x12345678;
    LOG("first byte = 0x%02x\n", (unsigned char) v.as_bytes[0]);

    bool ok = (argc > 1) ? strcmp(argv[1], "--verbose") == 0 : false;
    return ok ? EXIT_SUCCESS : EXIT_FAILURE;
}

static const char *lang_name(Language kind)
{
    switch (kind) {
        case LANG_C:    return "C";
        case LANG_CPP:  return "C++";
        case LANG_OBJC: return "Objective-C";
        default:        return "unknown";
    }
}

static int compare_langs(const void *a, const void *b)
{
    const Lang *la = (const Lang *) a;
    const Lang *lb = (const Lang *) b;
    return la->year - lb->year;
}
