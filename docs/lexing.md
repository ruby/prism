# Lexing

## Identifiers

This section documents the lexing rules for identifer tokens. In this section,
the exact definition of terms like "lower-case", "upper-case", "alphabetical"
and "alphanumeric" are encoding-dependent.

### Local variables

Local variable names begin with an underscore or lower-case letter, followed
by arbitrarily many underscores, alphanumeric or non-ASCII characters. 

### Instance & class variables

Instance & class variable identifiers begin with an underscore, alphabetical, or 
non-ASCII character, followed by arbitrarily many underscores, alphanumeric or
non-ASCII characters.

### Global variables

Global variable identifiers begin with an underscore, hyphen, alphabetical or 
non-ASCII character, followed by arbitrarily many underscores, alphanumeric or
non-ASCII characters.

The following are also valid global variable identiifers: `~`, `*`, `$`, `?`, 
`!`, `@`, `/`, `\`, `;`, `,`, `.`, `=`, `:`, `<`, `>`, `"`, `0`.

### Constants

Constant names begin with an upper-case letter, followed by arbitrarily many
underscores, alphanumeric or non-ASCII characters.

### Back-referenced variables

Back-referenced variable identifiers are one of `&`, `` ` ``, `'` or `+`.

