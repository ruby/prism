//! Node extension methods for the prism parser.
//!
//! This module provides convenience methods on AST nodes that aren't generated
//! from the config, mirroring Ruby's `node_ext.rb`.

use std::fmt;

use crate::{ConstantPathNode, ConstantPathTargetNode, ConstantReadNode, ConstantTargetNode, ConstantWriteNode, Node};

/// Errors for constant path name computation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ConstantPathError {
    /// The constant path contains dynamic parts (e.g., `var::Bar::Baz`).
    DynamicParts,
    /// The constant path contains error recovery nodes (e.g., `Foo::`).
    ErrorRecoveryNodes,
}

impl fmt::Display for ConstantPathError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::DynamicParts => {
                write!(f, "Constant path contains dynamic parts. Cannot compute full name")
            },
            Self::ErrorRecoveryNodes => {
                write!(f, "Constant path contains error recovery nodes. Cannot compute full name")
            },
        }
    }
}

impl std::error::Error for ConstantPathError {}

/// Trait for nodes that can compute their full constant name.
///
/// Implemented by constant-related nodes (`ConstantReadNode`,
/// `ConstantWriteNode`, `ConstantTargetNode`, `ConstantPathNode`, and
/// `ConstantPathTargetNode`).
pub trait FullName<'pr> {
    /// Returns the list of parts for the full name of this constant.
    ///
    /// # Errors
    ///
    /// Returns [`ConstantPathError`] if the path contains dynamic parts or
    /// error recovery nodes.
    fn full_name_parts(&self) -> Result<Vec<&'pr [u8]>, ConstantPathError>;

    /// Returns the full name of this constant.
    ///
    /// # Errors
    ///
    /// Returns [`ConstantPathError`] if the path contains dynamic parts or
    /// error recovery nodes.
    fn full_name(&self) -> Result<Vec<u8>, ConstantPathError> {
        let parts = self.full_name_parts()?;
        let mut result = Vec::new();
        for (index, part) in parts.iter().enumerate() {
            if index > 0 {
                result.extend_from_slice(b"::");
            }
            result.extend_from_slice(part);
        }
        Ok(result)
    }
}

/// Computes `full_name_parts` for a `Node` by dispatching to the appropriate
/// `FullName` implementation.
#[allow(clippy::option_if_let_else)]
fn full_name_parts_for_node<'pr>(node: &Node<'pr>) -> Result<Vec<&'pr [u8]>, ConstantPathError> {
    if let Some(path_node) = node.as_constant_path_node() {
        path_node.full_name_parts()
    } else if let Some(read_node) = node.as_constant_read_node() {
        read_node.full_name_parts()
    } else {
        Err(ConstantPathError::DynamicParts)
    }
}

/// Computes `full_name_parts` for a constant path node given its name and
/// parent.
fn constant_path_full_name_parts<'pr>(name: Option<crate::ConstantId<'pr>>, parent: Option<Node<'pr>>) -> Result<Vec<&'pr [u8]>, ConstantPathError> {
    let name = name.ok_or(ConstantPathError::ErrorRecoveryNodes)?;

    let mut parts = match parent {
        Some(parent) => full_name_parts_for_node(&parent)?,
        None => vec![b"".as_slice()],
    };

    parts.push(name.as_slice());
    Ok(parts)
}

/// Implements `FullName` for simple constant nodes that have a `name()` method
/// returning a single constant identifier.
macro_rules! impl_simple_full_name {
    ($node_type:ident) => {
        impl<'pr> FullName<'pr> for $node_type<'pr> {
            fn full_name_parts(&self) -> Result<Vec<&'pr [u8]>, ConstantPathError> {
                Ok(vec![self.name().as_slice()])
            }
        }
    };
}

impl_simple_full_name!(ConstantReadNode);
impl_simple_full_name!(ConstantWriteNode);
impl_simple_full_name!(ConstantTargetNode);

impl<'pr> FullName<'pr> for ConstantPathNode<'pr> {
    fn full_name_parts(&self) -> Result<Vec<&'pr [u8]>, ConstantPathError> {
        constant_path_full_name_parts(self.name(), self.parent())
    }
}

impl<'pr> FullName<'pr> for ConstantPathTargetNode<'pr> {
    fn full_name_parts(&self) -> Result<Vec<&'pr [u8]>, ConstantPathError> {
        constant_path_full_name_parts(self.name(), self.parent())
    }
}

#[cfg(test)]
mod tests {
    use super::{ConstantPathError, FullName};
    use crate::parse;

    #[test]
    fn test_full_name_for_constant_read_node() {
        let result = parse(b"Foo");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant = node.as_constant_read_node().unwrap();

        assert_eq!(constant.full_name_parts().unwrap(), vec![b"Foo".as_slice()]);
        assert_eq!(constant.full_name().unwrap(), b"Foo");
    }

    #[test]
    fn test_full_name_for_constant_write_node() {
        let result = parse(b"Foo = 1");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant = node.as_constant_write_node().unwrap();

        assert_eq!(constant.full_name_parts().unwrap(), vec![b"Foo".as_slice()]);
        assert_eq!(constant.full_name().unwrap(), b"Foo");
    }

    #[test]
    fn test_full_name_for_constant_target_node() {
        let result = parse(b"Foo, Bar = [1, 2]");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let multi_write = node.as_multi_write_node().unwrap();
        let target = multi_write.lefts().iter().next().unwrap();
        let constant = target.as_constant_target_node().unwrap();

        assert_eq!(constant.full_name_parts().unwrap(), vec![b"Foo".as_slice()]);
        assert_eq!(constant.full_name().unwrap(), b"Foo");
    }

    #[test]
    fn test_full_name_for_constant_path() {
        let result = parse(b"Foo::Bar");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant_path = node.as_constant_path_node().unwrap();

        assert_eq!(constant_path.full_name_parts().unwrap(), vec![b"Foo".as_slice(), b"Bar".as_slice()]);
        assert_eq!(constant_path.full_name().unwrap(), b"Foo::Bar");
    }

    #[test]
    fn test_full_name_for_constant_path_with_stovetop() {
        let result = parse(b"::Foo::Bar");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant_path = node.as_constant_path_node().unwrap();

        assert_eq!(constant_path.full_name_parts().unwrap(), vec![b"".as_slice(), b"Foo".as_slice(), b"Bar".as_slice()]);
        assert_eq!(constant_path.full_name().unwrap(), b"::Foo::Bar");
    }

    #[test]
    fn test_full_name_for_constant_path_with_self() {
        let source = r"
self::
  Bar::Baz::
    Qux
";
        let result = parse(source.as_bytes());
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant_path = node.as_constant_path_node().unwrap();

        assert_eq!(constant_path.full_name().unwrap_err(), ConstantPathError::DynamicParts);
    }

    #[test]
    fn test_full_name_for_constant_path_with_variable() {
        let source = r"
foo::
  Bar::Baz::
    Qux
";
        let result = parse(source.as_bytes());
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant_path = node.as_constant_path_node().unwrap();

        assert_eq!(constant_path.full_name().unwrap_err(), ConstantPathError::DynamicParts);
    }

    #[test]
    fn test_full_name_for_constant_path_with_missing_name() {
        let result = parse(b"Foo::");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant_path = node.as_constant_path_node().unwrap();

        assert_eq!(constant_path.full_name().unwrap_err(), ConstantPathError::ErrorRecoveryNodes);
    }

    #[test]
    fn test_full_name_for_constant_path_target() {
        let result = parse(b"Foo::Bar, Baz = [1, 2]");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let multi_write = node.as_multi_write_node().unwrap();
        let target = multi_write.lefts().iter().next().unwrap();
        let constant_path = target.as_constant_path_target_node().unwrap();

        assert_eq!(constant_path.full_name_parts().unwrap(), vec![b"Foo".as_slice(), b"Bar".as_slice()]);
        assert_eq!(constant_path.full_name().unwrap(), b"Foo::Bar");
    }

    #[test]
    fn test_full_name_for_constant_path_target_with_stovetop() {
        let result = parse(b"::Foo, Bar = [1, 2]");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let multi_write = node.as_multi_write_node().unwrap();
        let target = multi_write.lefts().iter().next().unwrap();
        let constant_path = target.as_constant_path_target_node().unwrap();

        assert_eq!(constant_path.full_name_parts().unwrap(), vec![b"".as_slice(), b"Foo".as_slice()]);
        assert_eq!(constant_path.full_name().unwrap(), b"::Foo");
    }

    #[test]
    fn test_full_name_for_constant_path_target_with_self() {
        let result = parse(b"self::Foo, Bar = [1, 2]");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let multi_write = node.as_multi_write_node().unwrap();
        let target = multi_write.lefts().iter().next().unwrap();
        let constant_path = target.as_constant_path_target_node().unwrap();

        assert_eq!(constant_path.full_name().unwrap_err(), ConstantPathError::DynamicParts);
    }
}
