/* mkiso.c - generate a test ISO (with directories) for GUI testing */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../bk/bk.h"

static void write_file(const char* path, const char* content) {
    FILE* f = fopen(path, "w");
    if (f == NULL) { printf("cannot create %s\n", path); exit(1); }
    fprintf(f, "%s", content);
    fclose(f);
}

int main(void) {
    VolInfo v;
    int rc;

    write_file("testdata/content.txt", "hello iso master\n");
    write_file("testdata/file1.txt", "file one in dir1\n");
    write_file("testdata/file2.txt", "file two in sub\n");

    rc = bk_init_vol_info(&v, false);
    if (rc < 0) { printf("init failed %d\n", rc); return 1; }

    rc = bk_add(&v, "testdata/content.txt", "/", NULL);
    if (rc < 0) { printf("add content.txt failed %d\n", rc); return 1; }

    rc = bk_create_dir(&v, "/", "dir1");
    if (rc < 0) { printf("create dir1 failed %d\n", rc); return 1; }

    rc = bk_create_dir(&v, "/dir1/", "sub");
    if (rc < 0) { printf("create sub failed %d\n", rc); return 1; }

    rc = bk_add(&v, "testdata/file1.txt", "/dir1/", NULL);
    if (rc < 0) { printf("add file1 failed %d\n", rc); return 1; }

    rc = bk_add(&v, "testdata/file2.txt", "/dir1/sub/", NULL);
    if (rc < 0) { printf("add file2 failed %d\n", rc); return 1; }

    rc = bk_write_image("testdata/test.iso", &v, 0, FNTYPE_JOLIET, NULL);
    printf("write rc=%d\n", rc);

    bk_destroy_vol_info(&v);
    return rc < 0;
}
