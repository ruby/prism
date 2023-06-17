#include "yarp/diagnostic.h"

// Append an error to the given list of diagnostic with formatting
bool
yp_vdiagnostic_list_append(yp_parser_t *parser, const char *start, const char *end, const char *message, ...) {
    yp_diagnostic_t *diagnostic = (yp_diagnostic_t *) malloc(sizeof(yp_diagnostic_t));
    if (diagnostic == NULL) return false;

    yp_list_t *list = &parser->error_list;
    const char *line_start = (parser->newline_list.start + parser->newline_list.offsets[parser->newline_list.size-1]);

    char *line_end = strchr((char*)line_start, '\n');
    if (line_end == line_start) {
      line_start++;
      line_end = strchr((char*)line_start, '\n');
    }
    
    unsigned long line_size = (unsigned long)((line_end - line_start));
    char * line = malloc(sizeof(char) * (line_size+1));
    memcpy(line, line_start, line_size);
    line[line_size+1] = '\0';
    
    va_list vargs;
    va_start(vargs, message);
    
    int size = vsnprintf(NULL, 0, message, vargs) + 1;
    char * message_buf = malloc(sizeof(char) * (unsigned long)size);

    va_start(vargs, message);
    vsprintf(message_buf, message, vargs);

    *diagnostic = (yp_diagnostic_t) {
      .start = start,
      .end = end,
      .message = message_buf,
      .line = line,
      .line_start = line_start,
      .lineno = parser->newline_list.size
    };
    
    yp_list_append(list, (yp_list_node_t *) diagnostic);
    return true;
}

// Append an error to the given list of diagnostic.
bool
yp_diagnostic_list_append(yp_list_t *list, const char *start, const char *end, const char *message) {
    yp_diagnostic_t *diagnostic = (yp_diagnostic_t *) malloc(sizeof(yp_diagnostic_t));
    if (diagnostic == NULL) return false;

    *diagnostic = (yp_diagnostic_t) { .start = start, .end = end, .message = message };
    yp_list_append(list, (yp_list_node_t *) diagnostic);
    return true;
}

// Deallocate the internal state of the given diagnostic list.
void
yp_diagnostic_list_free(yp_list_t *list) {
    yp_list_node_t *node, *next;

    for (node = list->head; node != NULL; node = next) {
        next = node->next;

        yp_diagnostic_t *diagnostic = (yp_diagnostic_t *) node;
        free(diagnostic);
    }
}
