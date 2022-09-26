#include "token.h"

yp_string_t
token_to_string(yp_token_t token) {
  return new_string_shared(token.start, token.end);
}
