# Encoding

When parsing a Ruby file, there are times when the parser must parse identifiers. Identifiers are names of variables, methods, classes, etc. To determine the start of an identifier, the parser must be able to tell if the subsequent bytes form an alphabetic character. To determine the rest of the identifier, the parser must look forward through all alphanumeric characters.

Determining if a set of bytes comprise an alphabetic or alphanumeric character is encoding-dependent. By default, the parser assumes that all source files are encoded UTF-8. If the file is not encoded in UTF-8, it must be encoded using an encoding that is "ASCII compatible" (i.e., all of the codepoints below 128 match the corresponding codepoints in ASCII and the minimum number of bytes required to represent a codepoint is 1 byte).

If the file is not encoded in UTF-8, the user must specify the encoding in a "magic" comment at the top of the file. The comment looks like:

```ruby
# encoding: iso-8859-9
```

The key of the comment can be either "encoding" or "coding". The value of the comment must be a string that is a valid encoding name. The encodings that YARP supports by default are:

* `ascii`
* `binary`
* `iso-8859-9`
* `us-ascii`
* `utf-8`

For each of these encodings, YARP provides a function for checking if the subsequent bytes form an alphabetic or alphanumeric character.

If an encoding is encountered that is not supported by YARP, YARP will call a user-provided callback function with the name of the encoding. The user-provided callback function can then provide a pointer to an encoding struct that contains the requisite functions that YARP will use those to parse identifiers going forward.

If the user-provided callback function returns `NULL` (the value also provided by the default implementation in case a callback was not registered), an error will be added to the parser's error list and parsing will continue on using the default UTF-8 encoding.

The relevant APIs, struct definitions, and typedefs are listed below:

```c
// This struct defines the functions necessary to implement the encoding
// interface so we can determine how many bytes the subsequent character takes.
// Each callback should return the number of bytes, or 0 if the next bytes are
// invalid for the encoding and type.
typedef struct {
  size_t (*alpha_char)(const char *);
  size_t (*alnum_char)(const char *);
} yp_encoding_t;

// When an encoding is encountered that isn't understood by YARP, we provide
// the ability here to call out to a user-defined function to get an encoding
// struct. If the function returns something that isn't NULL, we set that to
// our encoding and use it to parse identifiers.
typedef yp_encoding_t *(*yp_encoding_decode_callback_t)(const char *, size_t);

// Register a callback that will be called when YARP encounters a magic comment
// with an encoding referenced that it doesn't understand. The callback should
// return NULL if it also doesn't understand the encoding or it should return a
// pointer to a yp_encoding_t struct that contains the functions necessary to
// parse identifiers.
void
yp_parser_register_encoding_decode_callback(yp_parser_t *, yp_encoding_decode_callback_t);
```
