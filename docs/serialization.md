# Serialization

YARP ships with the ability to serialize a syntax tree to a single string.
The string can then be deserialized back into a syntax tree using a language other than C.
This is useful for using the parsing logic in other tools without having to write a parser in that language.
The syntax tree still requires a copy of the original source, as for the most part it just contains byte offsets into the source string.

## Types

Let us define some simple types for readability.

### varint

A variable-length integer with the value fitting in `uint32_t` using between 1 and 5 bytes, using the [LEB128](https://en.wikipedia.org/wiki/LEB128) encoding.
This drastically cuts down on the size of the serialized string, especially when the source file is large.

### string

| # bytes | field |
| --- | --- |
| varint | the length of the string in bytes |
| ... | the string bytes |

### location

| # bytes | field |
| --- | --- |
| varint | byte offset into the source string where this location begins |
| varint | length of the location in bytes in the source string |

### comment

The comment type is one of:
* 0=`INLINE` (`# comment`)
* 1=`EMBEDDED_DOCUMENT` (`=begin`/`=end`)
* 2=`__END__` (after `__END__`)

| # bytes | field |
| --- | --- |
| `1` | comment type |
| location | the location in the source of this comment |

### diagnostic

| # bytes | field |
| --- | --- |
| string | diagnostic message (ASCII-only characters) |
| location | the location in the source this diagnostic applies to |

## Structure

The serialized string representing the syntax tree is composed of three parts: the header, the body, and the constant pool.
The header contains information like the version of YARP that serialized the tree.
The body contains the actual nodes in the tree.
The constant pool contains constants that were interned while parsing.

The header is structured like the following table:

| # bytes | field |
| --- | --- |
| `4` | "YARP" |
| `1` | major version number |
| `1` | minor version number |
| `1` | patch version number |
| string | the encoding name |
| varint | number of comments |
| comment* | comments |
| varint | number of errors |
| diagnostic* | errors |
| varint | number of warnings |
| diagnostic* | warnings |
| `4` | content pool offset |
| varint | content pool size |

After the header comes the body of the serialized string.
The body consists of a sequence of nodes that is built using a prefix traversal order of the syntax tree.
Each node is structured like the following table:

| # bytes | field |
| --- | --- |
| `1` | node type |
| location | node location |

Every field on the node is then appended to the serialized string. The fields can be determined by referencing `config.yml`. Depending on the type of field, it could take a couple of different forms, described below:

* `node` - A field that is a node. This is structured just as like parent node.
* `node?` - A field that is a node that is optionally present. If the node is not present, then a single `0` byte will be written in its place. If it is present, then it will be structured just as like parent node.
* `node[]` - A field that is an array of nodes. This is structured as a variable-length integer length, followed by the child nodes themselves.
* `string` - A field that is a string. For example, this is used as the name of the method in a call node, since it cannot directly reference the source string (as in `@-` or `foo=`). This is structured as a variable-length integer byte length, followed by the string itself (_without_ a trailing null byte).
* `constant` - A variable-length integer that represents an index in the constant pool.
* `constant?` - An optional variable-length integer that represents an index in the constant pool. If it's not present, then a single `0` byte will be written in its place.
* `location` - A field that is a location. This is structured as a variable-length integer start followed by a variable-length integer length.
* `location?` - A field that is a location that is optionally present. If the location is not present, then a single `0` byte will be written in its place. If it is present, then it will be structured just like the `location` child node.
* `uint32` - A field that is a 32-bit unsigned integer. This is structured as a variable-length integer.

After the syntax tree, the content pool is serialized. This is a list of constants that were referenced from within the tree. The content pool begins at the offset specified in the header. Constants can be either "owned" (in which case their contents are embedded in the serialization) or "shared" (in which case their contents represent a slice of the source string). The most significant bit of the constant indicates whether it is owned or shared.

In the case that it is owned, the constant is structured as follows:

| # bytes | field |
| --- | --- |
| `4` | the byte offset in the serialization for the contents of the constant |
| `4` | the byte length in the serialization |

Note that you will need to mask off the most significant bit for the byte offset in the serialization. In the case that it is shared, the constant is structured as follows:

| # bytes | field |
| --- | --- |
| `4` | the byte offset in the source string for the contents of the constant |
| `4` | the byte length in the source string |

After the constant pool, the contents of the owned constants are serialized. This is just a sequence of bytes that represent the contents of the constants. At the end of the serialization, the buffer is null terminated.

## APIs

The relevant APIs and struct definitions are listed below:

```c
// A yp_buffer_t is a simple memory buffer that stores data in a contiguous
// block of memory. It is used to store the serialized representation of a
// YARP tree.
typedef struct {
  char *value;
  size_t length;
  size_t capacity;
} yp_buffer_t;

// Initialize a yp_buffer_t with its default values.
bool yp_buffer_init(yp_buffer_t *);

// Free the memory associated with the buffer.
void yp_buffer_free(yp_buffer_t *);

// Parse and serialize the AST represented by the given source to the given
// buffer.
void yp_parse_serialize(const uint8_t *source, size_t length, yp_buffer_t *buffer, const char *metadata);
```

Typically you would use a stack-allocated `yp_buffer_t` and call `yp_parse_serialize`, as in:

```c
void
serialize(const uint8_t *source, size_t length) {
  yp_buffer_t buffer;
  if (!yp_buffer_init(&buffer)) return;

  yp_parse_serialize(source, length, &buffer, NULL);
  // Do something with the serialized string.

  yp_buffer_free(&buffer);
}
```

The final argument to `yp_parse_serialize` controls the metadata of the source.
This includes the filepath that the source is associated with, and any nested local variables scopes that are necessary to properly parse the file (in the case of parsing an `eval`).
Note that no `varint` are used here to make it easier to produce the metadata for the caller, and also serialized size is less important here.
The metadata is a serialized format itself, and is structured as follows:

| # bytes | field |
| --- | --- |
| `4` | the size of the filepath string |
| | the filepath string |
| `4` | the number of local variable scopes |

Then, each local variable scope is encoded as:

| # bytes | field |
| --- | --- |
| `4` | the number of local variables in the scope |
| | the local variables |

Each local variable within each scope is encoded as:

| # bytes | field |
| --- | --- |
| `4` | the size of the local variable name |
| | the local variable name |

The metadata can be `NULL` (as seen in the example above).
If it is not null, then a minimal metadata string would be `"\0\0\0\0\0\0\0\0"` which would use 4 bytes to indicate an empty filepath string and 4 bytes to indicate that there were no local variable scopes.
