#include <yarp.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#define eprintf(...) fprintf(stderr, __VA_ARGS__)

#define red(...) \
  eprintf("\033[0;31m"); \
  eprintf(__VA_ARGS__); \
  eprintf("\033[0m");

#define green(...) \
  eprintf("\033[0;32m"); \
  eprintf(__VA_ARGS__); \
  eprintf("\033[0m");

typedef struct {
  const char *filepath;
  char *contents;
  size_t length;
} file_t;

static file_t
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

static void
free_file(file_t f) {
  free(f.contents);
}

typedef struct {
  const char *filepath;
  const file_t *file;
  char *input;
  char *token;
  yp_token_type_t token_type;
} yp_lexer_fixture_t;

typedef enum {
  YP_LEXER_FIXTURE_INITIAL,
  YP_LEXER_FIXTURE_READING_INPUT,
  YP_LEXER_FIXTURE_READING_TOKEN,
} yp_lexer_fixture_state_t;

static yp_lexer_fixture_t
parse_lexer_fixture(const char *filepath, const file_t *file) {
  yp_lexer_fixture_state_t state = YP_LEXER_FIXTURE_INITIAL;
  yp_lexer_fixture_t fixture = (yp_lexer_fixture_t) {
    .filepath = filepath,
    .file = file,
    .input = NULL,
    .token = NULL,
    .token_type = YP_TOKEN_INVALID,
  };

  char *ptr = file->contents;
  char *start;

  while (ptr < file->contents + file->length && *ptr) {
    switch (state) {
      case YP_LEXER_FIXTURE_INITIAL: {
        if (strncmp(ptr, "INPUT:\n", 7) == 0) {
          ptr += 7;
          start = ptr;
          state = YP_LEXER_FIXTURE_READING_INPUT;
        } else {
          red("Fixture parse error \"%s\":\nExpected INPUT on line 0", filepath);
          exit(1);
        }
        break;
      }
      case YP_LEXER_FIXTURE_READING_INPUT: {
        if (strncmp(ptr, "TOKEN:\n", 7) == 0) {
          fixture.input = (char *) malloc(ptr - start);
          strncpy(fixture.input, start, ptr - start - 1);
          fixture.input[ptr - start - 1] = 0;
          ptr += 7;
          state = YP_LEXER_FIXTURE_READING_TOKEN;
          start = ptr;
        } else {
          ptr++;
        }
        break;
      }

      case YP_LEXER_FIXTURE_READING_TOKEN: {
        if (*ptr == '\n') {
          fixture.token = (char *) malloc(ptr - start + 1);
          strncpy(fixture.token, start, ptr - start);
          fixture.token[ptr - start] = 0;
          fixture.token_type = yp_token_type_from_str(fixture.token);

          return fixture;
        } else {
          ptr++;
        }
        break;
      }
    }
  }

  return fixture;
}

static void
free_lexer_fixture(yp_lexer_fixture_t *fixture) {
  free(fixture->input);
  free(fixture->token);
}

static int
run_lexer_fixture(yp_lexer_fixture_t *fixture) {
  printf("Input: '%s'\n", fixture->input);
  printf("Expected token: '%s'\n", fixture->token);

  if (fixture->token_type == YP_TOKEN_INVALID) {
    red("Fixture parse error \"%s\":\n"
        "Unrecognized expected token name\n",
        fixture->filepath);
    return 1;
  }

  yp_parser_t parser;
  yp_parser_init(&parser, fixture->input, strlen(fixture->input));
  yp_lex_token(&parser);

  yp_token_t actual = parser.current;

  if (actual.type != fixture->token_type) {
    red("Error:\n"
        "Expected token: %s\n"
        "Actual token: %s (value = ",
        fixture->token, yp_token_type_to_str(actual.type));
    const char *ptr = actual.start;
    while (ptr != actual.end) {
      red("%c", *ptr);
      ptr++;
    }
    red(", length = %lu)\n", actual.end - actual.start);
    return 1;
  }

  return 0;
}

static int
run_lexer(const char *filepath) {
  file_t file = read_file(filepath);

  yp_lexer_fixture_t fixture = parse_lexer_fixture(filepath, &file);
  int success = run_lexer_fixture(&fixture);

  free_lexer_fixture(&fixture);
  free_file(file);

  return success;
}

static int
run_parser(const char *filepath, const char *contents, size_t length) {
  printf("Running in parser mode: %s\n", filepath);
  return 0;
}

int
main(int argc, char **argv) {
  if (argc != 3) {
    fprintf(stderr, "Usage:\n\n"
                    "./run-one --lexer path/to/lexer/test\n"
                    "./run-one --parser path/to/parser/test\n");
    return 1;
  }

  file_t f = read_file(argv[2]);
  int exitcode = 1;

  if (strcmp(argv[1], "--lexer") == 0) {
    exitcode = run_lexer(f.filepath);
  } else if (strcmp(argv[1], "--parser") == 0) {
    exitcode = run_parser(f.filepath, f.contents, f.length);
  } else {
    fprintf(stderr, "--lexer or --parser mode must be provided, given: %s\n", argv[1]);
    exitcode = 1;
  }

  free_file(f);
  if (exitcode == 0) {
    green("%s ... passed\n", argv[2]);
  } else {
    red("%s ... failed, re-run with %s %s %s\n", argv[2], argv[0], argv[1], argv[2]);
  }
  return exitcode;
}
