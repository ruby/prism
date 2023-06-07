#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>

#include "yarp.h"

static int
parse(const char *filepath) {
    int fd = open(filepath, O_RDONLY);
    if (fd == -1) {
        perror("open");
        return 1;
    }

    struct stat sb;
    if (fstat(fd, &sb) == -1) {
        close(fd);
        perror("fstat");
        return 1;
    }

    size_t size = sb.st_size;
    const char *source = mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);

    close(fd);
    if (source == MAP_FAILED) {
        perror("mmap");
        return 1;
    }

    yp_parser_t parser;
    yp_parser_init(&parser, source, size, filepath);

    yp_node_t *node = yp_parse(&parser);
    yp_node_destroy(&parser, node);
    yp_parser_free(&parser);

    return 0;
}

struct node {
    char *path;
    struct node *next;
};

int
main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <path>\n", argv[0]);
        return 1;
    }

    struct node *head = malloc(sizeof(struct node));
    struct node *tail = head;

    char *path = malloc(strlen(argv[1]) + 1);
    strcpy(path, argv[1]);

    *head = (struct node) { .path = path, .next = NULL };

    while (head != NULL) {
        DIR *handle = opendir(head->path);
        if (!handle) {
            perror("opendir");
            return 1;
        }

        struct dirent *dirent;
        while ((dirent = readdir(handle)) != NULL) {
            size_t length = strlen(dirent->d_name);

            char *joined = malloc(strlen(head->path) + length + 2);
            sprintf(joined, "%s/%s", head->path, dirent->d_name);

            if (dirent->d_type == DT_DIR && dirent->d_name[0] != '.') {
                struct node *next = malloc(sizeof(struct node));
                *next = (struct node) { .path = joined, .next = NULL };

                tail->next = next;
                tail = next;
            } else if (length > 3 && strcmp(dirent->d_name + length - 3, ".rb") == 0) {
                parse(joined);
                free(joined);
            }
        }

        closedir(handle);
        struct node *next = head->next;

        free(head->path);
        free(head);
        head = next;
    }

    return 0;
}
