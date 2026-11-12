#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (argc != 3) return 2;
    long expected = strtol(argv[2], NULL, 10);
    if (expected <= 0 || expected > 16 * 1024 * 1024) return 2;
    struct termios previous, raw;
    if (tcgetattr(STDIN_FILENO, &previous)) return 3;
    FILE *output = fopen(argv[1], "wb");
    if (!output) return 4;
    raw = previous;
    raw.c_lflag &= ~(ICANON | ECHO | ISIG);
    raw.c_iflag &= ~(ICRNL | INLCR | IGNCR | IXON | IXOFF);
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 20;
    if (tcsetattr(STDIN_FILENO, TCSANOW, &raw)) { fclose(output); return 5; }
    setvbuf(stdout, NULL, _IONBF, 0);
    puts("RAW_READY");
    long received = 0;
    int status = 0;
    while (received < expected) {
        char buffer[512];
        size_t block = (expected - received > 512) ? 512 : expected - received;
        size_t filled = 0;
        while (filled < block) {
            ssize_t count = read(STDIN_FILENO, buffer + filled, block - filled);
            if (count < 0 && errno == EINTR) continue;
            if (count <= 0) { status = 6; goto finished; }
            filled += count;
        }
        if (fwrite(buffer, 1, block, output) != block) { status = 7; goto finished; }
        received += block;
        printf("RAW_ACK %ld\n", received);
    }
finished:
    if (fclose(output) && !status) status = 8;
    tcsetattr(STDIN_FILENO, TCSANOW, &previous);
    printf("RAW_DONE %d\n", status);
    return status;
}
