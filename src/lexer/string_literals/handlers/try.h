#ifndef YARP_STRING_LITERALS_HANDLERS_TRY_H
#define YARP_STRING_LITERALS_HANDLERS_TRY_H

#define try_handler(call)                                                                                              \
  {                                                                                                                    \
    yp_string_literal_extend_action_t action = call;                                                                   \
    if (action != EXTEND_ACTION_NONE) {                                                                                \
      return action;                                                                                                   \
    }                                                                                                                  \
  }

#endif // YARP_STRING_LITERALS_HANDLERS_TRY_H
