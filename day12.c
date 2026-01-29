#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "lil.h"

struct darray_t {
    lilint_t *data;
    size_t capacity;
};

static LILCALLBACK
lil_value_t fnc_writechar(lil_t lil, size_t argc, lil_value_t *argv) {
    if (!argc) return NULL;
    putchar(lil_to_integer(argv[0]));
    return NULL;
}

lil_value_t fnc_makedarray(lil_t lil, size_t argc, lil_value_t *argv) {
    /* returns pointer to darray struct, as integer */
    assert(sizeof(lilint_t) >= sizeof(void *));
    struct darray_t *array = calloc(1, sizeof(struct darray_t));
    array->capacity = 0x100;
    array->data = calloc(array->capacity, sizeof(lilint_t));
    return lil_alloc_integer((lilint_t) array);
}
lil_value_t fnc_freedarray(lil_t lil, size_t argc, lil_value_t *argv) {
    struct darray_t *array = (struct darray_t *) lil_to_integer(argv[0]);
    free(array->data);
    free(array);
    return NULL;
}

lil_value_t fnc_darray_getset(lil_t lil, size_t argc, lil_value_t *argv) {
    if (argc == 2 || argc == 3) {
        struct darray_t *array = (struct darray_t *) lil_to_integer(argv[0]);
        size_t index = (size_t) lil_to_integer(argv[1]);
        /* If "get", ensure there's enough space */
        while (argc == 3 && index >= array->capacity) {
            size_t cap = array->capacity;
            void *tmpptr = realloc(array->data, 2*cap*sizeof(lilint_t));
            if (!tmpptr) {
                fprintf(stderr, "out of memory!");
                return NULL;
            }
            array->data = (lilint_t *) tmpptr;
            /* realloc doesn't zero memory automatically */
            memset(
                (void *) ((array->data) + cap),
                0,
                cap * sizeof(lilint_t) / sizeof(char)
            );
            array->capacity = 2*cap;
        }

        if (argc == 2) { /* get */
            if (index >= array->capacity) {
                return lil_alloc_integer((lilint_t) 0);
            } else {
                return lil_alloc_integer((array->data)[index]);
            }
        }
        if (argc == 3) { /* set */
            (array->data)[index] = lil_to_integer(argv[2]);
        }
    }
    return NULL;
}

int main(void) {
    const char *filename = "day12.lil";
    char *tmpcode = calloc(strlen(filename) + 0x100, sizeof(char));
    sprintf(
        tmpcode,
        "set __lilmain:code__ [read {%s}]\n"
        "eval $__lilmain:code__\n",
        filename);

    lil_t vm = lil_new();
    lil_register(vm, "writechar", fnc_writechar);
    lil_register(vm, "make-darray", fnc_makedarray);
    lil_register(vm, "free-darray", fnc_freedarray);
    lil_register(vm, "darray", fnc_darray_getset);

    lil_value_t result = lil_parse(vm, tmpcode, 0, 1);

    lil_free_value(result);
    free(tmpcode);
    lil_free(vm);

    return 0;
}
