# Serialization

YARP ships with the ability to serialize a syntax tree to a single string. The string can then be deserialized back into a syntax tree using a language other than C. This is useful for using the parsing logic in other tools without having to write a parser in that language. The syntax tree still requires a copy of the original source, as for the most part it just contains byte offsets into the source string.

The serialized string representing the syntax tree is composed of two parts: the header and the body. The header contains information like the version of YARP that serialized the tree, whereas the body contains the actual nodes in the tree. The header is structured like the following table:

| # bytes | field |
| --- | --- |
| `4` | "YARP" |
| `1` | major version number |
| `1` | minor version number |
| `1` | patch version number |

After the header comes the body of the serialized string. The body consistents of a sequence of nodes that is built using a prefix traversal order of the syntax tree. Each node is structured like the following table:

| # bytes | field |
| --- | --- |
| `1` | node type |
| `4` | byte offset into the serialized string where this node ends |
| `4` | byte offset into the source string where this node begins |
| `4` | length of the node in bytes in the source string |

Each node's child is then appended to the serialized string. The child node types can be determined by referencing `config.yml`. Depending on the type of child node, it could take a couple of different forms, described below:

* `node` - A child node that is a node itself. This is structured just as like parent node.
* `node?` - A child node that is optionally present. If the node is not present, then a single `0` byte will be written in its place. If it is present, then it will be structured just as like parent node.
* `node[]` - A child node that is an array of nodes. This is structured as a `4` byte length, followed by the child nodes themselves.
* `string` - A child node that is a string. For example, this is used as the name of the method in a call node, since it cannot directly reference the source string (as in `@-` or `foo=`). This is structured as a `4` byte length, followed by the string itself (_without_ a trailing null byte).
* `token` - A child node that is a token. This is structured as a single byte type, followed by two `4`-byte byte offsets into the source string.
* `token?` - A child node that is a token that is optionally present. If the token is not present, then a single `0` byte will be written in its place. If it is present, then it will be structured just like the `token` child node.
* `token[]` - A child node that is an array of tokens. This is structured as a `4` byte length, followed by the child tokens themselves.

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

// Allocate a new yp_buffer_t.
yp_buffer_t *
yp_buffer_alloc(void);

// Initialize a yp_buffer_t with its default values.
void
yp_buffer_init(yp_buffer_t *buffer);

// Free the memory associated with the buffer.
void
yp_buffer_free(yp_buffer_t *buffer);

// Parse and serialize the AST represented by the given source to the given
// buffer.
void
yp_parse_serialize(const char *, size_t, yp_buffer_t *);
```

Typically you would use a stack-allocated `yp_buffer_t` and call `yp_parse_serialize`, as in:

```c
void
serialize(const char *source, size_t length) {
  yp_buffer_t buffer;
  yp_buffer_init(&buffer);

  yp_parse_serialize(source, length, &buffer);
  // Do something with the serialized string.

  yp_buffer_free(&buffer);
}
```
