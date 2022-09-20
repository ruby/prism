#ifndef YARP_TEST_FILE_H
#define YARP_TEST_FILE_H

#include <stdio.h>
#include <stdlib.h>

typedef struct {
  const char *filepath;
  char *contents;
  size_t length;
} file_t;

file_t
read_file(const char *filepath) {
  FILE *f = fopen(filepath, "rb");
  if (f == NULL) {
    fprintf(stderr, "Unable to read %s\n", filepath);
  }
  fseek(f, 0, SEEK_END);
  size_t length = (size_t) ftell(f);
  fseek(f, 0, SEEK_SET);

  char *contents = (char *) malloc(length + 1);
  fread(contents, 1, length, f);
  fclose(f);
  contents[length] = 0;

  return (file_t) { .filepath = filepath, .contents = contents, .length = length };
}

void
free_file(file_t f) {
  free(f.contents);
}

#endif // YARP_TEST_FILE_H
