#include "../ext/yarp/token_type_gen.h"
#include "../ext/yarp/yarp.h"
#include "file.h"
#include "formatter.h"
#include <string.h>

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

yp_lexer_fixture_t
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
          red("Fixture parse error \"%s\":\n"
              "Expected INPUT on line 0",
              filepath);
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
          fixture.token_type = token_type_from_str(fixture.token);

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

void
free_lexer_fixture(yp_lexer_fixture_t *fixture) {
  free(fixture->input);
  free(fixture->token);
}

int
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
        fixture->token, token_type_to_str(actual.type));
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

int
run_lexer(const char *filepath) {
  file_t file = read_file(filepath);

  yp_lexer_fixture_t fixture = parse_lexer_fixture(filepath, &file);
  int success = run_lexer_fixture(&fixture);

  free_lexer_fixture(&fixture);
  free_file(file);

  return success;
}
