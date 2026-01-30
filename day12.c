#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>
#include "lil.h"

struct grid_t {
    char *data;
    size_t width;
    size_t height;
};

static LILCALLBACK
lil_value_t fnc_writechar(lil_t lil, size_t argc, lil_value_t *argv) {
    if (!argc) return NULL;
    putchar(lil_to_integer(argv[0]));
    return NULL;
}

lil_value_t fnc_gridmake(lil_t lil, size_t argc, lil_value_t *argv) {
    /* returns pointer to grid struct, as integer   *
     * usage: set grid [grid-make [read input.txt]] */
    if (!argc) return NULL;
    assert(sizeof(lilint_t) >= sizeof(void *));
    struct grid_t *grid = calloc(1, sizeof(struct grid_t));
    const char *s = lil_to_string(argv[0]);
    size_t len = strlen(s);

    grid->data = calloc(len + 1, sizeof(char));
    if (argc >= 2) {
        memset(grid->data, (char) lil_to_integer(argv[1]), len + 1);
    } else {
        strncpy(grid->data, s, len + 1);
    }
    grid->width = strchr(s, '\n') - s;
    grid->height = (len + 1) / (grid->width + 1);

    return lil_alloc_integer((lilint_t) grid);
}

lil_value_t fnc_gridfree(lil_t lil, size_t argc, lil_value_t *argv) {
    if (!argc) return NULL;
    struct grid_t *tmp = (struct grid_t *) lil_to_integer(argv[0]);
    free(tmp->data);
    free(tmp);
    return NULL;
}

lil_value_t fnc_gridset(lil_t lil, size_t argc, lil_value_t *argv) {
    /* usage: set-grid $grid $row $col [$val] */
    if (argc != 3 && argc != 4) return NULL;
    struct grid_t *grid = (struct grid_t *) lil_to_integer(argv[0]);
    size_t row = (size_t) lil_to_integer(argv[1]);
    size_t col = (size_t) lil_to_integer(argv[2]);
    /* check if out of bounds */
    if (row >= grid->height || col >= grid->width) return NULL;
    size_t index = ((grid->width + 1) * row) + col;
    char res = (grid->data)[index];
    if (res == '\n') return NULL;

    if (argc == 3) { /* get */
        char buf[2] = {res, '\0'};
        return lil_alloc_string(buf);
    }
    if (argc == 4) { /* set */
        (grid->data)[index] = (char) lil_to_integer(argv[3]);
        return NULL;
    }
}

lil_value_t fnc_gridwidth(lil_t lil, size_t argc, lil_value_t *argv) {
    if (!argc) return NULL;
    struct grid_t *grid = (struct grid_t *) lil_to_integer(argv[0]);
    return lil_alloc_integer(grid->width);
}
lil_value_t fnc_gridheight(lil_t lil, size_t argc, lil_value_t *argv) {
    if (!argc) return NULL;
    struct grid_t *grid = (struct grid_t *) lil_to_integer(argv[0]);
    return lil_alloc_integer(grid->height);
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
    lil_register(vm, "writechar",   fnc_writechar);
    lil_register(vm, "grid-make",   fnc_gridmake);
    lil_register(vm, "grid-free",   fnc_gridfree);
    lil_register(vm, "grid-set",    fnc_gridset);
    lil_register(vm, "grid-width",  fnc_gridwidth);
    lil_register(vm, "grid-height", fnc_gridheight);

    lil_value_t result = lil_parse(vm, tmpcode, 0, 1);

    lil_free_value(result);
    free(tmpcode);
    lil_free(vm);

    return 0;
}
