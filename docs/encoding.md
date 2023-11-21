# Encoding

When parsing a Ruby file, there are times when the parser must parse identifiers. Identifiers are names of variables, methods, classes, etc. To determine the start of an identifier, the parser must be able to tell if the subsequent bytes form an alphabetic character. To determine the rest of the identifier, the parser must look forward through all alphanumeric characters.

Determining if a set of bytes comprise an alphabetic or alphanumeric character is encoding-dependent. By default, the parser assumes that all source files are encoded UTF-8. If the file is not encoded in UTF-8, it must be encoded using an encoding that is "ASCII compatible" (i.e., all of the codepoints below 128 match the corresponding codepoints in ASCII and the minimum number of bytes required to represent a codepoint is 1 byte).

If the file is not encoded in UTF-8, the user must specify the encoding in a "magic" comment at the top of the file. The comment looks like:

```ruby
# encoding: iso-8859-9
```

The key of the comment can be either "encoding" or "coding". The value of the comment must be a string that is a valid encoding name. The encodings that prism supports by default are:

* `ASCII-8BIT`
* `Big5`
* `Big5-HKSCS`
* `Big5-UAO`
* `CP51932`
* `CP850`
* `CP852`
* `CP855`
* `EUC-JP`
* `GB1988`
* `GBK`
* `IBM437`
* `IBM720`
* `IBM737`
* `IBM775`
* `IBM852`
* `IBM855`
* `IBM857`
* `IBM860`
* `IBM861`
* `IBM862`
* `IBM864`
* `IBM865`
* `IBM866`
* `IBM869`
* `ISO-8859-1`
* `ISO-8859-2`
* `ISO-8859-3`
* `ISO-8859-4`
* `ISO-8859-5`
* `ISO-8859-6`
* `ISO-8859-7`
* `ISO-8859-8`
* `ISO-8859-9`
* `ISO-8859-10`
* `ISO-8859-11`
* `ISO-8859-13`
* `ISO-8859-14`
* `ISO-8859-15`
* `ISO-8859-16`
* `KOI8-R`
* `macCentEuro`
* `macCroatian`
* `macCyrillic`
* `macGreek`
* `macIceland`
* `macRoman`
* `macRomania`
* `macThai`
* `macTurkish`
* `macUkraine`
* `Shift_JIS`
* `TIS-620`
* `US-ASCII`
* `UTF-8`
* `UTF8-MAC`
* `Windows-1250`
* `Windows-1251`
* `Windows-1252`
* `Windows-1253`
* `Windows-1254`
* `Windows-1255`
* `Windows-1256`
* `Windows-1257`
* `Windows-1258`
* `Windows-31J`
* `Windows-874`

For each of these encodings, prism provides a function for checking if the subsequent bytes form an alphabetic or alphanumeric character.

## Support for other encodings

If an encoding is encountered that is not supported by prism, prism will call a user-provided callback function with the name of the encoding if one is provided. That function can be registered with `pm_parser_register_encoding_decode_callback`. The user-provided callback function can then provide a pointer to an encoding struct that contains the requisite functions that prism will use to parse identifiers going forward.

If the user-provided callback function returns `NULL` (the value also provided by the default implementation in case a callback was not registered), an error will be added to the parser's error list and parsing will continue on using the default UTF-8 encoding.

```c
// This struct defines the functions necessary to implement the encoding
// interface so we can determine how many bytes the subsequent character takes.
// Each callback should return the number of bytes, or 0 if the next bytes are
// invalid for the encoding and type.
typedef struct {
    // Return the number of bytes that the next character takes if it is valid
    // in the encoding. Does not read more than n bytes. It is assumed that n is
    // at least 1.
    size_t (*char_width)(const uint8_t *b, ptrdiff_t n);

    // Return the number of bytes that the next character takes if it is valid
    // in the encoding and is alphabetical. Does not read more than n bytes. It
    // is assumed that n is at least 1.
    size_t (*alpha_char)(const uint8_t *b, ptrdiff_t n);

    // Return the number of bytes that the next character takes if it is valid
    // in the encoding and is alphanumeric. Does not read more than n bytes. It
    // is assumed that n is at least 1.
    size_t (*alnum_char)(const uint8_t *b, ptrdiff_t n);

    // Return true if the next character is valid in the encoding and is an
    // uppercase character. Does not read more than n bytes. It is assumed that
    // n is at least 1.
    bool (*isupper_char)(const uint8_t *b, ptrdiff_t n);

    // The name of the encoding. This should correspond to a value that can be
    // passed to Encoding.find in Ruby.
    const char *name;

    // Return true if the encoding is a multibyte encoding.
    bool multibyte;
} pm_encoding_t;

// When an encoding is encountered that isn't understood by prism, we provide
// the ability here to call out to a user-defined function to get an encoding
// struct. If the function returns something that isn't NULL, we set that to
// our encoding and use it to parse identifiers.
typedef pm_encoding_t *(*pm_encoding_decode_callback_t)(pm_parser_t *parser, const uint8_t *name, size_t width);

// Register a callback that will be called when prism encounters a magic comment
// with an encoding referenced that it doesn't understand. The callback should
// return NULL if it also doesn't understand the encoding or it should return a
// pointer to a pm_encoding_t struct that contains the functions necessary to
// parse identifiers.
PRISM_EXPORTED_FUNCTION void
pm_parser_register_encoding_decode_callback(pm_parser_t *parser, pm_encoding_decode_callback_t callback);
```

## Getting notified when the encoding changes

You may want to get notified when the encoding changes based on the result of parsing an encoding comment. We use this internally for our `lex` function in order to provide the correct encodings for the tokens that are returned. For that you can register a callback with `pm_parser_register_encoding_changed_callback`. The callback will be called with a pointer to the parser. The encoding can be accessed through `parser->encoding`.

```c
// When the encoding that is being used to parse the source is changed by prism,
// we provide the ability here to call out to a user-defined function.
typedef void (*pm_encoding_changed_callback_t)(pm_parser_t *parser);

// Register a callback that will be called whenever prism changes the encoding
// it is using to parse based on the magic comment.
PRISM_EXPORTED_FUNCTION void
pm_parser_register_encoding_changed_callback(pm_parser_t *parser, pm_encoding_changed_callback_t callback);
```
