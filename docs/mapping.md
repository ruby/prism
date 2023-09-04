# Mapping

When considering the previous CRuby parser versus YARP, this document should be helpful to understand how various concepts are mapped.

## Nodes

The following table shows how the various CRuby nodes are mapped to YARP nodes.

| CRuby | YARP |
| --- | --- |
| `NODE_SCOPE` | |
| `NODE_BLOCK` | |
| `NODE_IF` | `YP_IF_NODE` |
| `NODE_UNLESS` | `YP_UNLESS_NODE` |
| `NODE_CASE` | `YP_CASE_NODE` |
| `NODE_CASE2` | `YP_CASE_NODE` (with a null predicate) |
| `NODE_CASE3` | |
| `NODE_WHEN` | `YP_WHEN_NODE` |
| `NODE_IN` | `YP_IN_NODE` |
| `NODE_WHILE` | `YP_WHILE_NODE` |
| `NODE_UNTIL` | `YP_UNTIL_NODE` |
| `NODE_ITER` | `YP_CALL_NODE` (with a non-null block) |
| `NODE_FOR` | `YP_FOR_NODE` |
| `NODE_FOR_MASGN` | `YP_FOR_NODE` (with a multi-write node as the index) |
| `NODE_BREAK` | `YP_BREAK_NODE` |
| `NODE_NEXT` | `YP_NEXT_NODE` |
| `NODE_REDO` | `YP_REDO_NODE` |
| `NODE_RETRY` | `YP_RETRY_NODE` |
| `NODE_BEGIN` | `YP_BEGIN_NODE` |
| `NODE_RESCUE` | `YP_RESCUE_NODE` |
| `NODE_RESBODY` | |
| `NODE_ENSURE` | `YP_ENSURE_NODE` |
| `NODE_AND` | `YP_AND_NODE` |
| `NODE_OR` | `YP_OR_NODE` |
| `NODE_MASGN` | `YP_MULTI_WRITE_NODE` |
| `NODE_LASGN` | `YP_LOCAL_VARIABLE_WRITE_NODE` |
| `NODE_DASGN` | `YP_LOCAL_VARIABLE_WRITE_NODE` |
| `NODE_GASGN` | `YP_GLOBAL_VARIABLE_WRITE_NODE` |
| `NODE_IASGN` | `YP_INSTANCE_VARIABLE_WRITE_NODE` |
| `NODE_CDECL` | `YP_CONSTANT_PATH_WRITE_NODE` |
| `NODE_CVASGN` | `YP_CLASS_VARIABLE_WRITE_NODE` |
| `NODE_OP_ASGN1` | |
| `NODE_OP_ASGN2` | |
| `NODE_OP_ASGN_AND` | `YP_OPERATOR_AND_ASSIGNMENT_NODE` |
| `NODE_OP_ASGN_OR` | `YP_OPERATOR_OR_ASSIGNMENT_NODE` |
| `NODE_OP_CDECL` | |
| `NODE_CALL` | `YP_CALL_NODE` |
| `NODE_OPCALL` | `YP_CALL_NODE` (with an operator as the method) |
| `NODE_FCALL` | `YP_CALL_NODE` (with a null receiver and parentheses) |
| `NODE_VCALL` | `YP_CALL_NODE` (with a null receiver and parentheses or arguments) |
| `NODE_QCALL` | `YP_CALL_NODE` (with a &. operator) |
| `NODE_SUPER` | `YP_SUPER_NODE` |
| `NODE_ZSUPER` | `YP_FORWARDING_SUPER_NODE` |
| `NODE_LIST` | `YP_ARRAY_NODE` |
| `NODE_ZLIST` | `YP_ARRAY_NODE` (with no child elements) |
| `NODE_VALUES` | `YP_ARGUMENTS_NODE` |
| `NODE_HASH` | `YP_HASH_NODE` |
| `NODE_RETURN` | `YP_RETURN_NODE` |
| `NODE_YIELD` | `YP_YIELD_NODE` |
| `NODE_LVAR` | `YP_LOCAL_VARIABLE_READ_NODE` |
| `NODE_DVAR` | `YP_LOCAL_VARIABLE_READ_NODE` |
| `NODE_GVAR` | `YP_GLOBAL_VARIABLE_READ_NODE` |
| `NODE_IVAR` | `YP_INSTANCE_VARIABLE_READ_NODE` |
| `NODE_CONST` | `YP_CONSTANT_PATH_READ_NODE` |
| `NODE_CVAR` | `YP_CLASS_VARIABLE_READ_NODE` |
| `NODE_NTH_REF` | `YP_NUMBERED_REFERENCE_READ_NODE` |
| `NODE_BACK_REF` | `YP_BACK_REFERENCE_READ_NODE` |
| `NODE_MATCH` | |
| `NODE_MATCH2` | `YP_CALL_NODE` (with regular expression as receiver) |
| `NODE_MATCH3` | `YP_CALL_NODE` (with regular expression as only argument) |
| `NODE_LIT` | |
| `NODE_STR` | `YP_STRING_NODE` |
| `NODE_DSTR` | `YP_INTERPOLATED_STRING_NODE` |
| `NODE_XSTR` | `YP_X_STRING_NODE` |
| `NODE_DXSTR` | `YP_INTERPOLATED_X_STRING_NODE` |
| `NODE_EVSTR` | `YP_STRING_INTERPOLATED_NODE` |
| `NODE_DREGX` | `YP_INTERPOLATED_REGULAR_EXPRESSION_NODE` |
| `NODE_ONCE` | |
| `NODE_ARGS` | `YP_PARAMETERS_NODE` |
| `NODE_ARGS_AUX` | |
| `NODE_OPT_ARG` | `YP_OPTIONAL_PARAMETER_NODE` |
| `NODE_KW_ARG` | `YP_KEYWORD_PARAMETER_NODE` |
| `NODE_POSTARG` | `YP_REQUIRED_PARAMETER_NODE` |
| `NODE_ARGSCAT` | |
| `NODE_ARGSPUSH` | |
| `NODE_SPLAT` | `YP_SPLAT_NODE` |
| `NODE_BLOCK_PASS` | `YP_BLOCK_ARGUMENT_NODE` |
| `NODE_DEFN` | `YP_DEF_NODE` (with a null receiver) |
| `NODE_DEFS` | `YP_DEF_NODE` (with a non-null receiver) |
| `NODE_ALIAS` | `YP_ALIAS_NODE` |
| `NODE_VALIAS` | `YP_ALIAS_NODE` (with a global variable first argument) |
| `NODE_UNDEF` | `YP_UNDEF_NODE` |
| `NODE_CLASS` | `YP_CLASS_NODE` |
| `NODE_MODULE` | `YP_MODULE_NODE` |
| `NODE_SCLASS` | `YP_S_CLASS_NODE` |
| `NODE_COLON2` | `YP_CONSTANT_PATH_NODE` |
| `NODE_COLON3` | `YP_CONSTANT_PATH_NODE` (with a null receiver) |
| `NODE_DOT2` | `YP_RANGE_NODE` (with a .. operator) |
| `NODE_DOT3` | `YP_RANGE_NODE` (with a ... operator) |
| `NODE_FLIP2` | `YP_RANGE_NODE` (with a .. operator) |
| `NODE_FLIP3` | `YP_RANGE_NODE` (with a ... operator) |
| `NODE_SELF` | `YP_SELF_NODE` |
| `NODE_NIL` | `YP_NIL_NODE` |
| `NODE_TRUE` | `YP_TRUE_NODE` |
| `NODE_FALSE` | `YP_FALSE_NODE` |
| `NODE_ERRINFO` | |
| `NODE_DEFINED` | `YP_DEFINED_NODE` |
| `NODE_POSTEXE` | `YP_POST_EXECUTION_NODE` |
| `NODE_DSYM` | `YP_INTERPOLATED_SYMBOL_NODE` |
| `NODE_ATTRASGN` | `YP_CALL_NODE` (with a message that ends with =) |
| `NODE_LAMBDA` | `YP_LAMBDA_NODE` |
| `NODE_ARYPTN` | `YP_ARRAY_PATTERN_NODE` |
| `NODE_HSHPTN` | `YP_HASH_PATTERN_NODE` |
| `NODE_FNDPTN` | `YP_FIND_PATTERN_NODE` |
| `NODE_ERROR` | `YP_MISSING_NODE` |
| `NODE_LAST` | |
```
