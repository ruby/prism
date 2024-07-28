#![allow(clippy::too_many_lines, clippy::uninlined_format_args)]

use serde::Deserialize;
use std::fs::File;
use std::io::Write;
use std::path::Path;

#[derive(Debug, Deserialize)]
enum NodeFieldType {
    #[serde(rename = "node")]
    Node,

    #[serde(rename = "node?")]
    OptionalNode,

    #[serde(rename = "node[]")]
    NodeList,

    #[serde(rename = "string")]
    String,

    #[serde(rename = "constant")]
    Constant,

    #[serde(rename = "constant?")]
    OptionalConstant,

    #[serde(rename = "constant[]")]
    ConstantList,

    #[serde(rename = "location")]
    Location,

    #[serde(rename = "location?")]
    OptionalLocation,

    #[serde(rename = "uint8")]
    UInt8,

    #[serde(rename = "uint32")]
    UInt32,

    #[serde(rename = "flags")]
    Flags,

    #[serde(rename = "integer")]
    Integer,

    #[serde(rename = "double")]
    Double,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
enum NodeFieldKind {
    Concrete(String),
    Union(Vec<String>),
}

#[derive(Debug, Deserialize)]
struct NodeField {
    name: String,

    #[serde(rename = "type")]
    field_type: NodeFieldType,

    kind: Option<NodeFieldKind>,
}

#[derive(Debug, Deserialize)]
struct FlagValue {
    name: String,
    comment: String,
}

#[derive(Debug, Deserialize)]
struct Flags {
    name: String,

    #[serde(default)]
    values: Vec<FlagValue>,
}

#[derive(Debug, Deserialize)]
struct Node {
    name: String,

    #[serde(default)]
    fields: Vec<NodeField>,

    comment: String,
}

#[derive(Debug, Deserialize)]
struct Config {
    nodes: Vec<Node>,
    flags: Vec<Flags>,
}

/// The main function for the build script. This will be run by Cargo when
/// building the library.
///
fn main() -> Result<(), Box<dyn std::error::Error>> {
    let prism_dir = format!("prism-{}", env!("CARGO_PKG_VERSION"));
    let config_path = Path::new(env!("CARGO_MANIFEST_DIR")).join("vendor").join(prism_dir).join("config.yml");

    let config_file = std::fs::File::open(&config_path)?;
    println!("cargo:rerun-if-changed={}", config_path.to_str().unwrap());

    let config: Config = serde_yaml::from_reader(config_file)?;
    write_bindings(&config)?;

    Ok(())
}

/// Returns the name of a C struct from the given node name.
fn struct_name(name: &str) -> String {
    let mut result = String::with_capacity(1 + name.len());

    for char in name.chars() {
        if char.is_uppercase() {
            result.push('_');
        }
        result.push(char.to_lowercase().next().unwrap());
    }

    result
}

/// Returns the name of the C type from the given node name.
fn type_name(name: &str) -> String {
    let mut result = String::with_capacity(8 + name.len());
    result.push_str("PM");

    for char in name.chars() {
        if char.is_uppercase() {
            result.push('_');
        }
        result.push(char.to_uppercase().next().unwrap());
    }

    result
}

/// Returns the name of the C enum constant from the given flag name and value.
fn enum_const_name(name: &str, value: &str) -> String {
    let mut result = String::with_capacity(8 + name.len() + value.len());
    result.push_str("PM");

    for char in name.chars() {
        if char.is_uppercase() {
            result.push('_');
        }
        result.extend(char.to_uppercase());
    }

    result.push('_');
    result.push_str(value);

    result
}

/// Returns the name of the C enum type from the given flag name.
fn enum_type_name(name: &str) -> String {
    let mut result = String::with_capacity(8 + name.len());
    result.push_str("pm");

    for char in name.chars() {
        if char.is_uppercase() {
            result.push('_');
        }
        result.extend(char.to_lowercase());
    }

    result
}

/// Returns the accessor function name from the given flag value.
fn accessor_func_name(value: &str) -> String {
    let mut result = String::with_capacity(8 + value.len());
    result.push_str("is_");

    for char in value.chars() {
        result.extend(char.to_lowercase());
    }

    result
}

/// Write the generated struct for the node to the file.
fn write_node(file: &mut File, flags: &[Flags], node: &Node) -> Result<(), Box<dyn std::error::Error>> {
    let mut example = false;

    for line in node.comment.lines() {
        if let Some(stripped) = line.strip_prefix("    ") {
            if !example {
                writeln!(file, "/// ```ruby")?;
                example = true;
            }
            writeln!(file, "/// {}", stripped)?;
        } else {
            if example {
                writeln!(file, "/// ```")?;
                example = false;
            }
            writeln!(file, "/// {}", line)?;
        }
    }

    if example {
        writeln!(file, "/// ```")?;
    }

    writeln!(file, "pub struct {}<'pr> {{", node.name)?;
    writeln!(file, "    /// The pointer to the parser this node came from.")?;
    writeln!(file, "    parser: NonNull<pm_parser_t>,")?;
    writeln!(file)?;
    writeln!(file, "    /// The raw pointer to the node allocated by prism.")?;
    writeln!(file, "    pointer: *mut pm{}_t,", struct_name(&node.name))?;
    writeln!(file)?;
    writeln!(file, "    /// The marker to indicate the lifetime of the pointer.")?;
    writeln!(file, "    marker: PhantomData<&'pr mut pm{}_t>", struct_name(&node.name))?;
    writeln!(file, "}}")?;
    writeln!(file)?;
    writeln!(file, "impl<'pr> {}<'pr> {{", node.name)?;
    writeln!(file, "    /// Converts this node to a generic node.")?;
    writeln!(file, "    #[must_use]")?;
    writeln!(file, "    pub fn as_node(&self) -> Node<'pr> {{")?;
    writeln!(file, "        Node::{} {{ parser: self.parser, pointer: self.pointer, marker: PhantomData }}", node.name)?;
    writeln!(file, "    }}")?;
    writeln!(file)?;
    writeln!(file, "    /// Returns the location of this node.")?;
    writeln!(file, "    #[must_use]")?;
    writeln!(file, "    pub fn location(&self) -> Location<'pr> {{")?;
    writeln!(file, "        let pointer: *mut pm_location_t = unsafe {{ &mut (*self.pointer).base.location }};")?;
    writeln!(file, "        Location::new(self.parser, unsafe {{ &(*pointer) }})")?;
    writeln!(file, "    }}")?;

    for field in &node.fields {
        writeln!(file)?;
        writeln!(file, "    /// Returns the `{}` param", field.name)?;
        writeln!(file, "    #[must_use]")?;

        match field.field_type {
            NodeFieldType::Node => {
                if let Some(NodeFieldKind::Concrete(kind)) = &field.kind {
                    writeln!(file, "    pub fn {}(&self) -> {}<'pr> {{", field.name, kind)?;
                    writeln!(file, "        let node: *mut pm{}_t = unsafe {{ (*self.pointer).{} }};", struct_name(kind), field.name)?;
                    writeln!(file, "        {} {{ parser: self.parser, pointer: node, marker: PhantomData }}", kind)?;
                    writeln!(file, "    }}")?;
                } else {
                    writeln!(file, "    pub fn {}(&self) -> Node<'pr> {{", field.name)?;
                    writeln!(file, "        let node: *mut pm_node_t = unsafe {{ (*self.pointer).{} }};", field.name)?;
                    writeln!(file, "        Node::new(self.parser, node)")?;
                    writeln!(file, "    }}")?;
                }
            },
            NodeFieldType::OptionalNode => {
                if let Some(NodeFieldKind::Concrete(kind)) = &field.kind {
                    writeln!(file, "    pub fn {}(&self) -> Option<{}<'pr>> {{", field.name, kind)?;
                    writeln!(file, "        let node: *mut pm{}_t = unsafe {{ (*self.pointer).{} }};", struct_name(kind), field.name)?;
                    writeln!(file, "        if node.is_null() {{")?;
                    writeln!(file, "            None")?;
                    writeln!(file, "        }} else {{")?;
                    writeln!(file, "            Some({} {{ parser: self.parser, pointer: node, marker: PhantomData }})", kind)?;
                    writeln!(file, "        }}")?;
                    writeln!(file, "    }}")?;
                } else {
                    writeln!(file, "    pub fn {}(&self) -> Option<Node<'pr>> {{", field.name)?;
                    writeln!(file, "        let node: *mut pm_node_t = unsafe {{ (*self.pointer).{} }};", field.name)?;
                    writeln!(file, "        if node.is_null() {{")?;
                    writeln!(file, "            None")?;
                    writeln!(file, "        }} else {{")?;
                    writeln!(file, "            Some(Node::new(self.parser, node))")?;
                    writeln!(file, "        }}")?;
                    writeln!(file, "    }}")?;
                }
            },
            NodeFieldType::NodeList => {
                writeln!(file, "    pub fn {}(&self) -> NodeList<'pr> {{", field.name)?;
                writeln!(file, "        let pointer: *mut pm_node_list = unsafe {{ &mut (*self.pointer).{} }};", field.name)?;
                writeln!(file, "        NodeList {{ parser: self.parser, pointer: unsafe {{ NonNull::new_unchecked(pointer) }}, marker: PhantomData }}")?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::String => {
                writeln!(file, "    pub const fn {}(&self) -> &str {{", field.name)?;
                writeln!(file, "        \"\"")?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::Constant => {
                writeln!(file, "    pub fn {}(&self) -> ConstantId<'pr> {{", field.name)?;
                writeln!(file, "        ConstantId::new(self.parser, unsafe {{ (*self.pointer).{} }})", field.name)?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::OptionalConstant => {
                writeln!(file, "    pub fn {}(&self) -> Option<ConstantId<'pr>> {{", field.name)?;
                writeln!(file, "        let id = unsafe {{ (*self.pointer).{} }};", field.name)?;
                writeln!(file, "        if id == 0 {{")?;
                writeln!(file, "            None")?;
                writeln!(file, "        }} else {{")?;
                writeln!(file, "            Some(ConstantId::new(self.parser, id))")?;
                writeln!(file, "        }}")?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::ConstantList => {
                writeln!(file, "    pub fn {}(&self) -> ConstantList<'pr> {{", field.name)?;
                writeln!(file, "        let pointer: *mut pm_constant_id_list_t = unsafe {{ &mut (*self.pointer).{} }};", field.name)?;
                writeln!(file, "        ConstantList {{ parser: self.parser, pointer: unsafe {{ NonNull::new_unchecked(pointer) }}, marker: PhantomData }}")?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::Location => {
                writeln!(file, "    pub fn {}(&self) -> Location<'pr> {{", field.name)?;
                writeln!(file, "        let pointer: *mut pm_location_t = unsafe {{ &mut (*self.pointer).{} }};", field.name)?;
                writeln!(file, "        Location::new(self.parser, unsafe {{ &(*pointer) }})")?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::OptionalLocation => {
                writeln!(file, "    pub fn {}(&self) -> Option<Location<'pr>> {{", field.name)?;
                writeln!(file, "        let pointer: *mut pm_location_t = unsafe {{ &mut (*self.pointer).{} }};", field.name)?;
                writeln!(file, "        let start = unsafe {{ (*pointer).start }};")?;
                writeln!(file, "        if start.is_null() {{")?;
                writeln!(file, "            None")?;
                writeln!(file, "        }} else {{")?;
                writeln!(file, "            Some(Location::new(self.parser, unsafe {{ &(*pointer) }}))")?;
                writeln!(file, "        }}")?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::UInt8 => {
                writeln!(file, "    pub fn {}(&self) -> u8 {{", field.name)?;
                writeln!(file, "        unsafe {{ (*self.pointer).{} }}", field.name)?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::UInt32 => {
                writeln!(file, "    pub fn {}(&self) -> u32 {{", field.name)?;
                writeln!(file, "        unsafe {{ (*self.pointer).{} }}", field.name)?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::Flags => {
                let Some(NodeFieldKind::Concrete(kind)) = &field.kind else {
                    panic!("Flag fields must have a concrete kind");
                };
                let our_flags = flags.iter().filter(|f| &f.name == kind).collect::<Vec<_>>();
                assert!(our_flags.len() == 1);

                writeln!(file, "    fn {}(&self) -> pm_node_flags_t {{", field.name)?;
                writeln!(file, "        unsafe {{ (*self.pointer).base.flags }}")?;
                writeln!(file, "    }}")?;

                for flag in our_flags {
                    for value in &flag.values {
                        writeln!(file, "    /// {}", value.comment)?;
                        writeln!(file, "    #[must_use]")?;
                        writeln!(file, "    pub fn {}(&self) -> bool {{", accessor_func_name(&value.name))?;
                        writeln!(file, "        (self.{}() & {}) != 0", field.name, enum_const_name(&flag.name, &value.name))?;
                        writeln!(file, "    }}")?;
                    }
                }
            },
            NodeFieldType::Integer => {
                writeln!(file, "    pub fn {}(&self) -> Integer<'pr> {{", field.name)?;
                writeln!(file, "        Integer::new(unsafe {{ &(*self.pointer).{} }})", field.name)?;
                writeln!(file, "    }}")?;
            },
            NodeFieldType::Double => {
                writeln!(file, "    pub fn {}(&self) -> f64 {{", field.name)?;
                writeln!(file, "        unsafe {{ (*self.pointer).{} }}", field.name)?;
                writeln!(file, "    }}")?;
            },
        }
    }

    writeln!(file, "}}")?;
    writeln!(file)?;

    writeln!(file, "impl std::fmt::Debug for {}<'_> {{", node.name)?;
    writeln!(file, "    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {{")?;

    write!(file, "        write!(f, \"{}(", node.name)?;
    if node.fields.is_empty() {
        write!(file, ")\"")?;
    } else {
        let mut padding = false;
        for _ in &node.fields {
            if padding {
                write!(file, ", ")?;
            }
            write!(file, "{{:?}}")?;
            padding = true;
        }

        write!(file, ")\", ")?;
        padding = false;

        for field in &node.fields {
            if padding {
                write!(file, ", ")?;
            }
            write!(file, "self.{}()", field.name)?;
            padding = true;
        }
    }

    writeln!(file, ")")?;
    writeln!(file, "    }}")?;
    writeln!(file, "}}")?;

    Ok(())
}

/// Write the visit trait to the file.
fn write_visit(file: &mut File, config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    writeln!(file, "/// A trait for visiting the AST.")?;
    writeln!(file, "pub trait Visit<'pr> {{")?;
    writeln!(file, "   /// Called prior to visiting a node with potential child nodes.")?;
    writeln!(file, "   fn visit_branch_node_enter(&mut self, _node: Node<'pr>) {{")?;
    writeln!(file, "   }}")?;
    writeln!(file)?;
    writeln!(file, "   /// Called after visiting a node with potential child nodes.")?;
    writeln!(file, "   fn visit_branch_node_leave(&mut self) {{")?;
    writeln!(file, "   }}")?;
    writeln!(file)?;
    writeln!(file, "   /// Called prior to visiting a node that cannot have child nodes.")?;
    writeln!(file, "   fn visit_leaf_node_enter(&mut self, _node: Node<'pr>) {{")?;
    writeln!(file, "   }}")?;
    writeln!(file)?;
    writeln!(file, "   /// Called after visiting a node that cannot have child nodes.")?;
    writeln!(file, "   fn visit_leaf_node_leave(&mut self) {{")?;
    writeln!(file, "   }}")?;
    writeln!(file)?;
    writeln!(file, "   /// Visits a node.")?;
    writeln!(file, "   fn visit(&mut self, node: &Node<'pr>) {{")?;
    writeln!(file, "       match node {{")?;

    for node in &config.nodes {
        let has_child_nodes = node.fields.iter().any(|f| matches!(f.field_type, NodeFieldType::Node | NodeFieldType::OptionalNode | NodeFieldType::NodeList));
        let (pre_func, post_func) = if has_child_nodes { ("visit_branch_node_enter", "visit_branch_node_leave") } else { ("visit_leaf_node_enter", "visit_leaf_node_leave") };
        writeln!(file, "           Node::{} {{ parser, pointer, marker }} => {{", node.name)?;
        writeln!(file, "               let concrete = {} {{ parser: *parser, pointer: *pointer, marker: *marker }};", node.name)?;
        writeln!(file, "               self.{}(concrete.as_node());", pre_func)?;
        writeln!(file, "               self.visit{}(&concrete);", struct_name(&node.name))?;
        writeln!(file, "               self.{}();", post_func)?;
        writeln!(file, "           }}")?;
    }

    writeln!(file, "       }}")?;
    writeln!(file, "   }}")?;

    for node in &config.nodes {
        writeln!(file)?;
        writeln!(file, "    /// Visits a `{}` node.", node.name)?;
        writeln!(file, "    fn visit{}(&mut self, node: &{}<'pr>) {{", struct_name(&node.name), node.name)?;
        writeln!(file, "        visit{}(self, node);", struct_name(&node.name))?;
        writeln!(file, "    }}")?;
    }
    writeln!(file, "}}")?;

    for node in &config.nodes {
        writeln!(file)?;
        writeln!(file, "/// The default visitor implementation for a `{}` node.", node.name)?;

        let children = node.fields.iter().any(|f| matches!(f.field_type, NodeFieldType::Node | NodeFieldType::OptionalNode | NodeFieldType::NodeList));

        if children {
            writeln!(file, "pub fn visit{}<'pr, V>(visitor: &mut V, node: &{}<'pr>)", struct_name(&node.name), node.name)?;
            writeln!(file, "where")?;
            writeln!(file, "    V: Visit<'pr> + ?Sized,")?;
            writeln!(file, "{{")?;

            for field in &node.fields {
                match field.field_type {
                    NodeFieldType::Node => {
                        if let Some(NodeFieldKind::Concrete(kind)) = &field.kind {
                            writeln!(file, "    visitor.visit{}(&node.{}());", struct_name(kind), field.name)?;
                        } else {
                            writeln!(file, "    visitor.visit(&node.{}());", field.name)?;
                        }
                    },
                    NodeFieldType::OptionalNode => {
                        if let Some(NodeFieldKind::Concrete(kind)) = &field.kind {
                            writeln!(file, "    if let Some(node) = node.{}() {{", field.name)?;
                            writeln!(file, "        visitor.visit{}(&node);", struct_name(kind))?;
                            writeln!(file, "    }}")?;
                        } else {
                            writeln!(file, "    if let Some(node) = node.{}() {{", field.name)?;
                            writeln!(file, "        visitor.visit(&node);")?;
                            writeln!(file, "    }}")?;
                        }
                    },
                    NodeFieldType::NodeList => {
                        writeln!(file, "    for node in node.{}().iter() {{", field.name)?;
                        writeln!(file, "        visitor.visit(&node);")?;
                        writeln!(file, "    }}")?;
                    },
                    _ => {},
                }
            }

            writeln!(file, "}}")?;
        } else {
            writeln!(file, "pub fn visit{}<'pr, V>(_visitor: &mut V, _node: &{}<'pr>)", struct_name(&node.name), node.name)?;
            writeln!(file, "where")?;
            writeln!(file, "    V: Visit<'pr> + ?Sized,")?;
            writeln!(file, "{{}}")?;
        }
    }

    Ok(())
}

/// Write the bindings to the `$OUT_DIR/bindings.rs` file. We'll pull these into
/// the actual library in `src/lib.rs`.
fn write_bindings(config: &Config) -> Result<(), Box<dyn std::error::Error>> {
    let out_dir = std::env::var_os("OUT_DIR").unwrap();
    let dest_path = Path::new(&out_dir).join("bindings.rs");
    let mut file = std::fs::File::create(&dest_path).expect("Unable to create file");

    write!(
        file,
        r#"
use std::marker::PhantomData;
use std::ptr::NonNull;

#[allow(clippy::wildcard_imports)]
use ruby_prism_sys::*;

/// A range in the source file.
pub struct Location<'pr> {{
    parser: NonNull<pm_parser_t>,
    pub(crate) start: *const u8,
    pub(crate) end: *const u8,
    marker: PhantomData<&'pr [u8]>
}}

impl<'pr> Location<'pr> {{
    /// Returns a byte slice for the range.
    #[must_use]
    pub fn as_slice(&self) -> &'pr [u8] {{
        unsafe {{
          let len = usize::try_from(self.end.offset_from(self.start)).expect("end should point to memory after start");
          std::slice::from_raw_parts(self.start, len)
        }}
    }}

    /// Return a Location from the given `pm_location_t`.
    #[must_use]
    pub(crate) const fn new(parser: NonNull<pm_parser_t>, loc: &'pr pm_location_t) -> Location<'pr> {{
        Location {{ parser, start: loc.start, end: loc.end, marker: PhantomData }}
    }}

    /// Return a Location starting at self and ending at the end of other.
    /// Returns None if both locations did not originate from the same parser,
    /// or if self starts after other.
    #[must_use]
    pub fn join(&self, other: &Location<'pr>) -> Option<Location<'pr>> {{
        if self.parser != other.parser || self.start > other.start {{
            None
        }} else {{
            Some(Location {{ parser: self.parser, start: self.start, end: other.end, marker: PhantomData }})
        }}
    }}

    /// Return the start offset from the beginning of the parsed source.
    #[must_use]
    pub fn start_offset(&self) -> usize {{
        unsafe {{
            let parser_start = (*self.parser.as_ptr()).start;
            usize::try_from(self.start.offset_from(parser_start)).expect("start should point to memory after the parser's start")
        }}
    }}

    /// Return the end offset from the beginning of the parsed source.
    #[must_use]
    pub fn end_offset(&self) -> usize {{
        unsafe {{
            let parser_start = (*self.parser.as_ptr()).start;
            usize::try_from(self.end.offset_from(parser_start)).expect("end should point to memory after the parser's start")
        }}
    }}
}}

impl std::fmt::Debug for Location<'_> {{
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {{
        let slice: &[u8] = self.as_slice();

        let mut visible = String::new();
        visible.push('"');

        for &byte in slice {{
            let part: Vec<u8> = std::ascii::escape_default(byte).collect();
            visible.push_str(std::str::from_utf8(&part).unwrap());
        }}

        visible.push('"');
        write!(f, "{{visible}}")
    }}
}}

/// An iterator over the nodes in a list.
pub struct NodeListIter<'pr> {{
    parser: NonNull<pm_parser_t>,
    pointer: NonNull<pm_node_list>,
    index: usize,
    marker: PhantomData<&'pr mut pm_node_list>
}}

impl<'pr> Iterator for NodeListIter<'pr> {{
    type Item = Node<'pr>;

    fn next(&mut self) -> Option<Self::Item> {{
        if self.index >= unsafe {{ self.pointer.as_ref().size }} {{
            None
        }} else {{
            let node: *mut pm_node_t = unsafe {{ *(self.pointer.as_ref().nodes.add(self.index)) }};
            self.index += 1;
            Some(Node::new(self.parser, node))
        }}
    }}
}}

/// A list of nodes.
pub struct NodeList<'pr> {{
    parser: NonNull<pm_parser_t>,
    pointer: NonNull<pm_node_list>,
    marker: PhantomData<&'pr mut pm_node_list>
}}

impl<'pr> NodeList<'pr> {{
    /// Returns an iterator over the nodes.
    #[must_use]
    pub fn iter(&self) -> NodeListIter<'pr> {{
        NodeListIter {{
            parser: self.parser,
            pointer: self.pointer,
            index: 0,
            marker: PhantomData
        }}
    }}
}}

impl std::fmt::Debug for NodeList<'_> {{
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {{
        write!(f, "{{:?}}", self.iter().collect::<Vec<_>>())
    }}
}}

/// A handle for a constant ID.
pub struct ConstantId<'pr> {{
    parser: NonNull<pm_parser_t>,
    id: pm_constant_id_t,
    marker: PhantomData<&'pr mut pm_constant_id_t>
}}

impl<'pr> ConstantId<'pr> {{
    fn new(parser: NonNull<pm_parser_t>, id: pm_constant_id_t) -> Self {{
        ConstantId {{ parser, id, marker: PhantomData }}
    }}

    /// Returns a byte slice for the constant ID.
    ///
    /// # Panics
    ///
    /// Panics if the constant ID is not found in the constant pool.
    #[must_use]
    pub fn as_slice(&self) -> &'pr [u8] {{
        unsafe {{
            let pool = &(*self.parser.as_ptr()).constant_pool;
            let constant = &(*pool.constants.add((self.id - 1).try_into().unwrap()));
            std::slice::from_raw_parts(constant.start, constant.length)
        }}
    }}
}}

impl std::fmt::Debug for ConstantId<'_> {{
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {{
        write!(f, "{{:?}}", self.id)
    }}
}}

/// An iterator over the constants in a list.
pub struct ConstantListIter<'pr> {{
    parser: NonNull<pm_parser_t>,
    pointer: NonNull<pm_constant_id_list_t>,
    index: usize,
    marker: PhantomData<&'pr mut pm_constant_id_list_t>
}}

impl<'pr> Iterator for ConstantListIter<'pr> {{
    type Item = ConstantId<'pr>;

    fn next(&mut self) -> Option<Self::Item> {{
        if self.index >= unsafe {{ self.pointer.as_ref().size }} {{
            None
        }} else {{
            let constant_id: pm_constant_id_t = unsafe {{ *(self.pointer.as_ref().ids.add(self.index)) }};
            self.index += 1;
            Some(ConstantId::new(self.parser, constant_id))
        }}
    }}
}}

/// A list of constants.
pub struct ConstantList<'pr> {{
    /// The raw pointer to the parser where this list came from.
    parser: NonNull<pm_parser_t>,

    /// The raw pointer to the list allocated by prism.
    pointer: NonNull<pm_constant_id_list_t>,

    /// The marker to indicate the lifetime of the pointer.
    marker: PhantomData<&'pr mut pm_constant_id_list_t>
}}

impl<'pr> ConstantList<'pr> {{
    /// Returns an iterator over the constants in the list.
    #[must_use]
    pub fn iter(&self) -> ConstantListIter<'pr> {{
        ConstantListIter {{
            parser: self.parser,
            pointer: self.pointer,
            index: 0,
            marker: PhantomData
        }}
    }}
}}

impl std::fmt::Debug for ConstantList<'_> {{
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {{
        write!(f, "{{:?}}", self.iter().collect::<Vec<_>>())
    }}
}}

/// A handle for an arbitarily-sized integer.
pub struct Integer<'pr> {{
    /// The raw pointer to the integer allocated by prism.
    pointer: *const pm_integer_t,

    /// The marker to indicate the lifetime of the pointer.
    marker: PhantomData<&'pr mut pm_constant_id_t>
}}

impl<'pr> Integer<'pr> {{
    fn new(pointer: *const pm_integer_t) -> Self {{
        Integer {{ pointer, marker: PhantomData }}
    }}
}}

impl std::fmt::Debug for Integer<'_> {{
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {{
        write!(f, "{{:?}}", self.pointer)
    }}
}}

impl TryInto<i32> for Integer<'_> {{
    type Error = ();

    fn try_into(self) -> Result<i32, Self::Error> {{
        let negative = unsafe {{ (*self.pointer).negative }};
        let length = unsafe {{ (*self.pointer).length }};

        if length == 0 {{
            i32::try_from(unsafe {{ (*self.pointer).value }}).map_or(Err(()), |value| 
                if negative {{
                    Ok(-value)
                }} else {{
                    Ok(value)
                }}
            )
        }} else {{
            Err(())
        }}
    }}
}}
"#
    )?;

    for node in &config.nodes {
        writeln!(file, "const {}: u16 = pm_node_type::{} as u16;", type_name(&node.name), type_name(&node.name))?;
    }
    writeln!(file)?;
    for flag in &config.flags {
        for value in &flag.values {
            let const_name = enum_const_name(&flag.name, &value.name);
            writeln!(file, "const {}: u16 = {}::{} as u16;", &const_name, enum_type_name(&flag.name), &const_name)?;
        }
    }
    writeln!(file)?;

    writeln!(file, "/// An enum representing the different kinds of nodes that can be parsed.")?;
    writeln!(file, "pub enum Node<'pr> {{")?;

    for node in &config.nodes {
        writeln!(file, "    /// The {} node", node.name)?;
        writeln!(file, "    {} {{", node.name)?;
        writeln!(file, "        /// The pointer to the associated parser this node came from.")?;
        writeln!(file, "        parser: NonNull<pm_parser_t>,")?;
        writeln!(file)?;
        writeln!(file, "        /// The raw pointer to the node allocated by prism.")?;
        writeln!(file, "        pointer: *mut pm{}_t,", struct_name(&node.name))?;
        writeln!(file)?;
        writeln!(file, "        /// The marker to indicate the lifetime of the pointer.")?;
        writeln!(file, "        marker: PhantomData<&'pr mut pm{}_t>", struct_name(&node.name))?;
        writeln!(file, "    }},")?;
    }

    writeln!(file, "}}")?;
    writeln!(file)?;

    writeln!(
        file,
        r#"
impl<'pr> Node<'pr> {{
    /// Creates a new node from the given pointer.
    ///
    /// # Panics
    ///
    /// Panics if the node type cannot be read.
    ///
    #[allow(clippy::not_unsafe_ptr_arg_deref)]
    pub(crate) fn new(parser: NonNull<pm_parser_t>, node: *mut pm_node_t) -> Self {{
        match unsafe {{ (*node).type_ }} {{
"#
    )?;

    for node in &config.nodes {
        writeln!(file, "            {} => Self::{} {{ parser, pointer: node.cast::<pm{}_t>(), marker: PhantomData }},", type_name(&node.name), node.name, struct_name(&node.name))?;
    }

    writeln!(file, "            _ => panic!(\"Unknown node type: {{}}\", unsafe {{ (*node).type_ }})")?;
    writeln!(file, "        }}")?;
    writeln!(file, "    }}")?;
    writeln!(file)?;

    writeln!(file, "    /// Returns the location of this node.")?;
    writeln!(file, "    #[must_use]")?;
    writeln!(file, "    pub fn location(&self) -> Location<'pr> {{")?;
    writeln!(file, "        match *self {{")?;
    for node in &config.nodes {
        writeln!(file, "            Self::{} {{ pointer, parser, .. }} => Location::new(parser, unsafe {{ &((*pointer.cast::<pm_node_t>()).location) }}),", node.name)?;
    }
    writeln!(file, "        }}")?;
    writeln!(file, "    }}")?;
    writeln!(file)?;

    for node in &config.nodes {
        writeln!(file, "    /// Returns the node as a `{}`.", node.name)?;
        writeln!(file, "    #[must_use]")?;
        writeln!(file, "    pub fn as{}(&self) -> Option<{}<'pr>> {{", struct_name(&node.name), node.name)?;
        writeln!(file, "        match *self {{")?;
        writeln!(file, "            Self::{} {{ parser, pointer, marker }} => Some({} {{ parser, pointer, marker }}),", node.name, node.name)?;
        writeln!(file, "            _ => None")?;
        writeln!(file, "        }}")?;
        writeln!(file, "    }}")?;
    }

    writeln!(file, "}}")?;
    writeln!(file)?;

    writeln!(file, "impl std::fmt::Debug for Node<'_> {{")?;
    writeln!(file, "    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {{")?;
    writeln!(file, "        match *self {{")?;

    for node in &config.nodes {
        writeln!(file, "            Self::{} {{ parser, pointer, marker }} => write!(f, \"{{:?}}\", {} {{ parser, pointer, marker }}),", node.name, node.name)?;
    }

    writeln!(file, "        }}")?;
    writeln!(file, "    }}")?;
    writeln!(file, "}}")?;
    writeln!(file)?;

    for node in &config.nodes {
        write_node(&mut file, &config.flags, node)?;
        writeln!(file)?;
    }

    write_visit(&mut file, config)?;

    Ok(())
}
