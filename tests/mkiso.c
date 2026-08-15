/* mkiso.c - generate a small test ISO for GUI testing */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../bk/bk.h"

int main(void) {
    VolInfo v;
    int rc;

    FILE* f = fopen("/tmp/iso-content.txt", "w");
    if (f == NULL) { printf("cannot create content file\n"); return 1; }
    fprintf(f, "hello iso master\n");
    fclose(f);

    rc = bk_init_vol_info(&v, false);
    if (rc < 0) { printf("init failed %d\n", rc); return 1; }

    rc = bk_add(&v, "/tmp/iso-content.txt", "/", NULL);
    if (rc < 0) { printf("add failed %d\n", rc); return 1; }

    rc = bk_write_image("/tmp/test-edit.iso", &v, 0, FNTYPE_JOLIET, NULL);
    printf("write rc=%d\n", rc);

    bk_destroy_vol_info(&v);
    return rc < 0;
}
