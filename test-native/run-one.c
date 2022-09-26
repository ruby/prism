#include "../ext/yarp/gen_token_type.c"
#include "../ext/yarp/string.c"
#include "../ext/yarp/token.c"
#include "../ext/yarp/yarp.c"
#include "file.h"
#include "formatter.h"
#include "run-lexer.c"
#include "run-parser.c"
#include <string.h>

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
