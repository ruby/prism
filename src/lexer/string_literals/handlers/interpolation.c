#include "interpolation.h"
#include "emit_captured.h"
#include "try.h"

// Handles regular "#{42}" interpolation
static yp_string_literal_extend_action_t
yp_string_literal_extend_regular_interpolation(yp_parser_t *parser, interpolation_t *interpolation) {
  if (parser->current.end + 1 < parser->end && *parser->current.end == '#' && *(parser->current.end + 1) == '{') {
    try_handler(yp_string_literal_emit_captured(parser));

    parser->current.type = YP_TOKEN_EMBEXPR_BEGIN;
    // Consue "#{"
    parser->current.end += 2;
    // Start interpolation
    interpolation->active = true;

    return EXTEND_ACTION_EMIT_TOKEN;
  }

  return EXTEND_ACTION_NONE;
}

// Handles "#@foo" / "#@@foo" interpolation
static yp_string_literal_extend_action_t
yp_string_literal_extend_raw_ivar_or_cvar_interpolation(yp_parser_t *parser, interpolation_t *interpolation) {
  // TODO: requires a shared read_identifier method
  return EXTEND_ACTION_NONE;
}

// Handles "#$foo" interpolation
static yp_string_literal_extend_action_t
yp_string_literal_extend_raw_gvar_interpolation(yp_parser_t *parser, interpolation_t *interpolation) {
  // TODO: requires a shared read_identifier method
  return EXTEND_ACTION_NONE;
}

// Handles generic interpolation
// Internally is just a combination of 3 small parser.
yp_string_literal_extend_action_t
yp_string_literal_extend_interpolation(yp_parser_t *parser, interpolation_t *interpolation) {
  try_handler(yp_string_literal_extend_regular_interpolation(parser, interpolation));
  try_handler(yp_string_literal_extend_raw_ivar_or_cvar_interpolation(parser, interpolation));
  try_handler(yp_string_literal_extend_raw_gvar_interpolation(parser, interpolation));

  return EXTEND_ACTION_NONE;
}
