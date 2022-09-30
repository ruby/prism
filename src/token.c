#include "token.h"

// Allocate a new yp_token_list_t.
yp_token_list_t *
yp_token_list_alloc() {
  yp_token_list_t *token_list = malloc(sizeof(yp_token_list_t));
  token_list->tokens = NULL;
  token_list->size = 0;
  token_list->capacity = 0;
  return token_list;
}

// Append a token to the given list.
void
yp_token_list_append(yp_token_list_t *token_list, yp_token_t *token) {
  if (token_list->size == token_list->capacity) {
    token_list->capacity = token_list->capacity == 0 ? 1 : token_list->capacity * 2;
    token_list->tokens = realloc(token_list->tokens, sizeof(yp_token_t) * token_list->capacity);
  }
  token_list->tokens[token_list->size++] = *token;
}

// Checks if the current token list includes the given token.
bool
yp_token_list_includes(yp_token_list_t *token_list, yp_token_t *token) {
  size_t length = token->end - token->start;

  for (size_t index = 0; index < token_list->size; index++) {
    yp_token_t current_token = token_list->tokens[index];

    if (current_token.type == token->type && memcmp(current_token.start, token->start, length) == 0) {
      return true;
    }
  }
  return false;
}

// Free the memory associated with the token list and the token list itself.
void
yp_token_list_dealloc(yp_token_list_t *token_list) {
  free(token_list->tokens);
  free(token_list);
}
