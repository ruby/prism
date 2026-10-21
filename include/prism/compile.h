/**
 * @file compile.h
 *
 * Compile the Prism AST to a CFG.
 */
#ifndef PRISM_COMPILE_H
#define PRISM_COMPILE_H

#include "prism/compiler/exported.h"

#include "prism/node.h"

#ifdef __cplusplus
extern "C" {
#endif

PRISM_EXPORTED_FUNCTION void pm_compile(pm_node_t *node);

#ifdef __cplusplus
}
#endif

#endif
