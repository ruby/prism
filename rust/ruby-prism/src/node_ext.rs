//! Node extension methods for the prism parser.
//!
//! This module provides convenience methods on AST nodes that aren't generated
//! from the config, mirroring Ruby's `node_ext.rb`.

use std::borrow::Cow;
use std::fmt;

use crate::{ConstantPathNode, ConstantPathTargetNode, ConstantReadNode, ConstantTargetNode, ConstantWriteNode, Node};

/// Errors for constant path name computation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ConstantPathError {
    /// An error returned when dynamic parts are found while computing a
    /// constant path's full name. For example:
    /// `Foo::Bar::Baz` -> succeeds because all parts of the constant
    /// path are simple constants.
    /// `var::Bar::Baz` -> fails because the first part of the constant path
    /// is a local variable.
    DynamicParts,
    /// An error returned when missing nodes are found while computing a
    /// constant path's full name. For example:
    /// `Foo::` -> fails because the constant path is missing the last part.
    MissingNodes,
}

impl fmt::Display for ConstantPathError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::DynamicParts => {
                write!(f, "Constant path contains dynamic parts. Cannot compute full name")
            },
            Self::MissingNodes => {
                write!(f, "Constant path contains missing nodes. Cannot compute full name")
            },
        }
    }
}

impl std::error::Error for ConstantPathError {}

impl<'pr> ConstantReadNode<'pr> {
    /// Returns the list of parts for the full name of this constant.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let constant = stmt.as_constant_read_node().unwrap();
    /// assert_eq!(constant.full_name_parts(), vec!["Foo"]);
    /// ```
    #[must_use]
    pub fn full_name_parts(&self) -> Vec<Cow<'pr, str>> {
        vec![String::from_utf8_lossy(self.name().as_slice())]
    }

    /// Returns the full name of this constant.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let constant = stmt.as_constant_read_node().unwrap();
    /// assert_eq!(constant.full_name(), "Foo");
    /// ```
    #[must_use]
    pub fn full_name(&self) -> Cow<'pr, str> {
        String::from_utf8_lossy(self.name().as_slice())
    }
}

impl<'pr> ConstantWriteNode<'pr> {
    /// Returns the list of parts for the full name of this constant.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo = 1");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let constant = stmt.as_constant_write_node().unwrap();
    /// assert_eq!(constant.full_name_parts(), vec!["Foo"]);
    /// ```
    #[must_use]
    pub fn full_name_parts(&self) -> Vec<Cow<'pr, str>> {
        vec![String::from_utf8_lossy(self.name().as_slice())]
    }

    /// Returns the full name of this constant.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo = 1");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let constant = stmt.as_constant_write_node().unwrap();
    /// assert_eq!(constant.full_name(), "Foo");
    /// ```
    #[must_use]
    pub fn full_name(&self) -> Cow<'pr, str> {
        String::from_utf8_lossy(self.name().as_slice())
    }
}

impl<'pr> ConstantTargetNode<'pr> {
    /// Returns the list of parts for the full name of this constant.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo, Bar = [1, 2]");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let target = stmt.as_multi_write_node().unwrap()
    ///     .lefts().iter().next().unwrap();
    /// let constant = target.as_constant_target_node().unwrap();
    /// assert_eq!(constant.full_name_parts(), vec!["Foo"]);
    /// ```
    #[must_use]
    pub fn full_name_parts(&self) -> Vec<Cow<'pr, str>> {
        vec![String::from_utf8_lossy(self.name().as_slice())]
    }

    /// Returns the full name of this constant.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo, Bar = [1, 2]");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let target = stmt.as_multi_write_node().unwrap()
    ///     .lefts().iter().next().unwrap();
    /// let constant = target.as_constant_target_node().unwrap();
    /// assert_eq!(constant.full_name(), "Foo");
    /// ```
    #[must_use]
    pub fn full_name(&self) -> Cow<'pr, str> {
        String::from_utf8_lossy(self.name().as_slice())
    }
}

impl<'pr> ConstantPathNode<'pr> {
    /// Returns the list of parts for the full name of this constant path.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo::Bar");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let constant_path = stmt.as_constant_path_node().unwrap();
    /// assert_eq!(constant_path.full_name_parts().unwrap(), vec!["Foo", "Bar"]);
    /// ```
    ///
    /// # Errors
    ///
    /// Returns [`ConstantPathError::DynamicParts`] if the path contains
    /// dynamic parts, or [`ConstantPathError::MissingNodes`] if the path
    /// contains missing nodes.
    pub fn full_name_parts(&self) -> Result<Vec<Cow<'pr, str>>, ConstantPathError> {
        let mut parts = Vec::new();
        let mut current: Option<Node<'pr>> = Some(self.as_node());

        while let Some(ref node) = current {
            if let Some(path_node) = node.as_constant_path_node() {
                let name = path_node.name().ok_or(ConstantPathError::MissingNodes)?;
                parts.push(String::from_utf8_lossy(name.as_slice()));
                current = path_node.parent();
            } else if let Some(read_node) = node.as_constant_read_node() {
                parts.push(String::from_utf8_lossy(read_node.name().as_slice()));
                current = None;
            } else {
                return Err(ConstantPathError::DynamicParts);
            }
        }

        parts.reverse();

        if self.is_stovetop() {
            parts.insert(0, Cow::Borrowed(""));
        }

        Ok(parts)
    }

    /// Returns the full name of this constant path.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo::Bar");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let constant_path = stmt.as_constant_path_node().unwrap();
    /// assert_eq!(constant_path.full_name().unwrap(), "Foo::Bar");
    /// ```
    ///
    /// # Errors
    ///
    /// Returns [`ConstantPathError::DynamicParts`] if the path contains
    /// dynamic parts, or [`ConstantPathError::MissingNodes`] if the path
    /// contains missing nodes.
    pub fn full_name(&self) -> Result<String, ConstantPathError> {
        Ok(self.full_name_parts()?.join("::"))
    }

    fn is_stovetop(&self) -> bool {
        let mut current: Option<Node<'pr>> = Some(self.as_node());

        while let Some(ref node) = current {
            if let Some(path_node) = node.as_constant_path_node() {
                current = path_node.parent();
            } else {
                return false;
            }
        }

        true
    }
}

impl<'pr> ConstantPathTargetNode<'pr> {
    /// Returns the list of parts for the full name of this constant path.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo::Bar, Baz = [1, 2]");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let target = stmt.as_multi_write_node().unwrap()
    ///     .lefts().iter().next().unwrap();
    /// let constant_path = target.as_constant_path_target_node().unwrap();
    /// assert_eq!(constant_path.full_name_parts().unwrap(), vec!["Foo", "Bar"]);
    /// ```
    ///
    /// # Errors
    ///
    /// Returns [`ConstantPathError::DynamicParts`] if the path contains
    /// dynamic parts, or [`ConstantPathError::MissingNodes`] if the path
    /// contains missing nodes.
    pub fn full_name_parts(&self) -> Result<Vec<Cow<'pr, str>>, ConstantPathError> {
        let name = self.name().ok_or(ConstantPathError::MissingNodes)?;

        let mut parts = if let Some(parent) = self.parent() {
            if let Some(path_node) = parent.as_constant_path_node() {
                path_node.full_name_parts()?
            } else if let Some(read_node) = parent.as_constant_read_node() {
                read_node.full_name_parts()
            } else {
                return Err(ConstantPathError::DynamicParts);
            }
        } else {
            vec![Cow::Borrowed("")]
        };

        parts.push(String::from_utf8_lossy(name.as_slice()));
        Ok(parts)
    }

    /// Returns the full name of this constant path.
    ///
    /// # Examples
    ///
    /// ```
    /// # use ruby_prism::parse;
    /// let result = parse(b"Foo::Bar, Baz = [1, 2]");
    /// let stmt = result.node().as_program_node().unwrap()
    ///     .statements().body().iter().next().unwrap();
    /// let target = stmt.as_multi_write_node().unwrap()
    ///     .lefts().iter().next().unwrap();
    /// let constant_path = target.as_constant_path_target_node().unwrap();
    /// assert_eq!(constant_path.full_name().unwrap(), "Foo::Bar");
    /// ```
    ///
    /// # Errors
    ///
    /// Returns [`ConstantPathError::DynamicParts`] if the path contains
    /// dynamic parts, or [`ConstantPathError::MissingNodes`] if the path
    /// contains missing nodes.
    pub fn full_name(&self) -> Result<String, ConstantPathError> {
        Ok(self.full_name_parts()?.join("::"))
    }
}

#[cfg(test)]
mod tests {
    use super::ConstantPathError;
    use crate::parse;

    #[test]
    fn test_full_name_for_constant_read_node() {
        let result = parse(b"Foo");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant = node.as_constant_read_node().unwrap();

        assert_eq!(constant.full_name_parts(), vec!["Foo"]);
        assert_eq!(constant.full_name(), "Foo");
    }

    #[test]
    fn test_full_name_for_constant_write_node() {
        let result = parse(b"Foo = 1");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant = node.as_constant_write_node().unwrap();

        assert_eq!(constant.full_name_parts(), vec!["Foo"]);
        assert_eq!(constant.full_name(), "Foo");
    }

    #[test]
    fn test_full_name_for_constant_target_node() {
        let result = parse(b"Foo, Bar = [1, 2]");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let multi_write = node.as_multi_write_node().unwrap();
        let target = multi_write.lefts().iter().next().unwrap();
        let constant = target.as_constant_target_node().unwrap();

        assert_eq!(constant.full_name_parts(), vec!["Foo"]);
        assert_eq!(constant.full_name(), "Foo");
    }

    #[test]
    fn test_full_name_for_constant_path() {
        let result = parse(b"Foo::Bar");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant_path = node.as_constant_path_node().unwrap();

        assert_eq!(constant_path.full_name_parts().unwrap(), vec!["Foo", "Bar"]);
        assert_eq!(constant_path.full_name().unwrap(), "Foo::Bar");
    }

    #[test]
    fn test_full_name_for_constant_path_with_stovetop() {
        let result = parse(b"::Foo::Bar");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let constant_path = node.as_constant_path_node().unwrap();

        assert_eq!(constant_path.full_name_parts().unwrap(), vec!["", "Foo", "Bar"]);
        assert_eq!(constant_path.full_name().unwrap(), "::Foo::Bar");
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

        assert_eq!(constant_path.full_name().unwrap_err(), ConstantPathError::MissingNodes);
    }

    #[test]
    fn test_full_name_for_constant_path_target() {
        let result = parse(b"Foo::Bar, Baz = [1, 2]");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let multi_write = node.as_multi_write_node().unwrap();
        let target = multi_write.lefts().iter().next().unwrap();
        let constant_path = target.as_constant_path_target_node().unwrap();

        assert_eq!(constant_path.full_name_parts().unwrap(), vec!["Foo", "Bar"]);
        assert_eq!(constant_path.full_name().unwrap(), "Foo::Bar");
    }

    #[test]
    fn test_full_name_for_constant_path_target_with_stovetop() {
        let result = parse(b"::Foo, Bar = [1, 2]");
        let node = result.node().as_program_node().unwrap().statements().body().iter().next().unwrap();
        let multi_write = node.as_multi_write_node().unwrap();
        let target = multi_write.lefts().iter().next().unwrap();
        let constant_path = target.as_constant_path_target_node().unwrap();

        assert_eq!(constant_path.full_name_parts().unwrap(), vec!["", "Foo"]);
        assert_eq!(constant_path.full_name().unwrap(), "::Foo");
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
