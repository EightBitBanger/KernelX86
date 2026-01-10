
#include <stdio.h>
#include <stdlib.h>

static int copy(FILE* out, FILE* in) {
    unsigned char buf[4096];
    for (;;) {
        size_t r = fread(buf, 1, sizeof(buf), in);
        if (!r) break;
        if (fwrite(buf, 1, r, out) != r) return 0;
    }
    return 1;
}

static int pad(FILE* out, long long size) {
    long long pos = ftell(out);
    while (pos < size) {
        fputc(0, out);
        pos++;
    }
    return 1;
}

int main(int argc, char** argv) {
    if (argc != 7) {
        fprintf(stderr, "usage: imgtool boot.bin stage2.bin kernel32.bin stage2_pad sectors out.img\n");
        return 1;
    }

    FILE* boot = fopen(argv[1], "rb");
    FILE* s2   = fopen(argv[2], "rb");
    FILE* k32  = fopen(argv[3], "rb");
    long long stage2_pad = atoll(argv[4]);
    int sectors = atoi(argv[5]);
    FILE* out = fopen(argv[6], "wb");

    unsigned char sec[512];
    fread(sec, 1, 512, boot);
    fwrite(sec, 1, 512, out);

    copy(out, s2);
    pad(out, 512 + stage2_pad);
    copy(out, k32);
    pad(out, 512LL * (1 + sectors));

    return 0;
}
