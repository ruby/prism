//! Node-related types for the prism parser.
//!
//! This module contains types for working with AST nodes, including node lists,
//! constant IDs, and integer values.

use std::marker::PhantomData;
use std::ptr::NonNull;

use ruby_prism_sys::{pm_constant_id_list_t, pm_constant_id_t, pm_integer_t, pm_node_list, pm_node_t, pm_parser_t};

// Note: The `Node` enum is defined in the generated `bindings.rs` file.
// We import it here via `crate::Node` to avoid circular dependencies.
use crate::Node;

// ============================================================================
// NodeList
// ============================================================================

/// An iterator over the nodes in a list.
pub struct NodeListIter<'pr> {
    pub(crate) parser: NonNull<pm_parser_t>,
    pub(crate) pointer: NonNull<pm_node_list>,
    pub(crate) index: usize,
    pub(crate) marker: PhantomData<&'pr mut pm_node_list>,
}

impl<'pr> Iterator for NodeListIter<'pr> {
    type Item = Node<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.index >= unsafe { self.pointer.as_ref().size } {
            None
        } else {
            let node: *mut pm_node_t = unsafe { *(self.pointer.as_ref().nodes.add(self.index)) };
            self.index += 1;
            Some(Node::new(self.parser, node))
        }
    }
}

/// A list of nodes.
pub struct NodeList<'pr> {
    pub(crate) parser: NonNull<pm_parser_t>,
    pub(crate) pointer: NonNull<pm_node_list>,
    pub(crate) marker: PhantomData<&'pr mut pm_node_list>,
}

impl<'pr> NodeList<'pr> {
    unsafe fn at(&self, index: usize) -> Node<'pr> {
        let node: *mut pm_node_t = *(self.pointer.as_ref().nodes.add(index));
        Node::new(self.parser, node)
    }

    /// Returns an iterator over the nodes.
    #[must_use]
    pub const fn iter(&self) -> NodeListIter<'pr> {
        NodeListIter {
            parser: self.parser,
            pointer: self.pointer,
            index: 0,
            marker: PhantomData,
        }
    }

    /// Returns the length of the list.
    #[must_use]
    pub const fn len(&self) -> usize {
        unsafe { self.pointer.as_ref().size }
    }

    /// Returns whether the list is empty.
    #[must_use]
    pub const fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Returns the first element of the list, or `None` if it is empty.
    #[must_use]
    pub fn first(&self) -> Option<Node<'pr>> {
        if self.is_empty() {
            None
        } else {
            Some(unsafe { self.at(0) })
        }
    }

    /// Returns the last element of the list, or `None` if it is empty.
    #[must_use]
    pub fn last(&self) -> Option<Node<'pr>> {
        if self.is_empty() {
            None
        } else {
            Some(unsafe { self.at(self.len() - 1) })
        }
    }
}

impl<'pr> IntoIterator for &NodeList<'pr> {
    type Item = Node<'pr>;
    type IntoIter = NodeListIter<'pr>;
    fn into_iter(self) -> Self::IntoIter {
        self.iter()
    }
}

impl std::fmt::Debug for NodeList<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self.iter().collect::<Vec<_>>())
    }
}

// ============================================================================
// ConstantId / ConstantList
// ============================================================================

/// A handle for a constant ID.
pub struct ConstantId<'pr> {
    pub(crate) parser: NonNull<pm_parser_t>,
    pub(crate) id: pm_constant_id_t,
    pub(crate) marker: PhantomData<&'pr mut pm_constant_id_t>,
}

impl<'pr> ConstantId<'pr> {
    pub(crate) const fn new(parser: NonNull<pm_parser_t>, id: pm_constant_id_t) -> Self {
        ConstantId { parser, id, marker: PhantomData }
    }

    /// Returns a byte slice for the constant ID.
    ///
    /// # Panics
    ///
    /// Panics if the constant ID is not found in the constant pool.
    #[must_use]
    pub fn as_slice(&self) -> &'pr [u8] {
        unsafe {
            let pool = &(*self.parser.as_ptr()).constant_pool;
            let constant = &(*pool.constants.add((self.id - 1).try_into().unwrap()));
            std::slice::from_raw_parts(constant.start, constant.length)
        }
    }
}

impl std::fmt::Debug for ConstantId<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self.id)
    }
}

/// An iterator over the constants in a list.
pub struct ConstantListIter<'pr> {
    pub(crate) parser: NonNull<pm_parser_t>,
    pub(crate) pointer: NonNull<pm_constant_id_list_t>,
    pub(crate) index: usize,
    pub(crate) marker: PhantomData<&'pr mut pm_constant_id_list_t>,
}

impl<'pr> Iterator for ConstantListIter<'pr> {
    type Item = ConstantId<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.index >= unsafe { self.pointer.as_ref().size } {
            None
        } else {
            let constant_id: pm_constant_id_t = unsafe { *(self.pointer.as_ref().ids.add(self.index)) };
            self.index += 1;
            Some(ConstantId::new(self.parser, constant_id))
        }
    }
}

/// A list of constants.
pub struct ConstantList<'pr> {
    /// The raw pointer to the parser where this list came from.
    pub(crate) parser: NonNull<pm_parser_t>,

    /// The raw pointer to the list allocated by prism.
    pub(crate) pointer: NonNull<pm_constant_id_list_t>,

    /// The marker to indicate the lifetime of the pointer.
    pub(crate) marker: PhantomData<&'pr mut pm_constant_id_list_t>,
}

impl<'pr> ConstantList<'pr> {
    const unsafe fn at(&self, index: usize) -> ConstantId<'pr> {
        let constant_id: pm_constant_id_t = *(self.pointer.as_ref().ids.add(index));
        ConstantId::new(self.parser, constant_id)
    }

    /// Returns an iterator over the constants in the list.
    #[must_use]
    pub const fn iter(&self) -> ConstantListIter<'pr> {
        ConstantListIter {
            parser: self.parser,
            pointer: self.pointer,
            index: 0,
            marker: PhantomData,
        }
    }

    /// Returns the length of the list.
    #[must_use]
    pub const fn len(&self) -> usize {
        unsafe { self.pointer.as_ref().size }
    }

    /// Returns whether the list is empty.
    #[must_use]
    pub const fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Returns the first element of the list, or `None` if it is empty.
    #[must_use]
    pub const fn first(&self) -> Option<ConstantId<'pr>> {
        if self.is_empty() {
            None
        } else {
            Some(unsafe { self.at(0) })
        }
    }

    /// Returns the last element of the list, or `None` if it is empty.
    #[must_use]
    pub const fn last(&self) -> Option<ConstantId<'pr>> {
        if self.is_empty() {
            None
        } else {
            Some(unsafe { self.at(self.len() - 1) })
        }
    }
}

impl<'pr> IntoIterator for &ConstantList<'pr> {
    type Item = ConstantId<'pr>;
    type IntoIter = ConstantListIter<'pr>;
    fn into_iter(self) -> Self::IntoIter {
        self.iter()
    }
}

impl std::fmt::Debug for ConstantList<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self.iter().collect::<Vec<_>>())
    }
}

// ============================================================================
// Integer
// ============================================================================

/// A handle for an arbitrarily-sized integer.
pub struct Integer<'pr> {
    /// The raw pointer to the integer allocated by prism.
    pub(crate) pointer: *const pm_integer_t,

    /// The marker to indicate the lifetime of the pointer.
    pub(crate) marker: PhantomData<&'pr mut pm_constant_id_t>,
}

impl Integer<'_> {
    pub(crate) const fn new(pointer: *const pm_integer_t) -> Self {
        Integer { pointer, marker: PhantomData }
    }

    /// Returns the sign and the u32 digits representation of the integer,
    /// ordered least significant digit first.
    #[must_use]
    pub const fn to_u32_digits(&self) -> (bool, &[u32]) {
        let negative = unsafe { (*self.pointer).negative };
        let length = unsafe { (*self.pointer).length };
        let values = unsafe { (*self.pointer).values };

        if values.is_null() {
            let value_ptr = unsafe { std::ptr::addr_of!((*self.pointer).value) };
            let slice = unsafe { std::slice::from_raw_parts(value_ptr, 1) };
            (negative, slice)
        } else {
            let slice = unsafe { std::slice::from_raw_parts(values, length) };
            (negative, slice)
        }
    }
}

impl std::fmt::Debug for Integer<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self.pointer)
    }
}

impl TryInto<i32> for Integer<'_> {
    type Error = ();

    fn try_into(self) -> Result<i32, Self::Error> {
        let negative = unsafe { (*self.pointer).negative };
        let length = unsafe { (*self.pointer).length };

        if length == 0 {
            i32::try_from(unsafe { (*self.pointer).value }).map_or(Err(()), |value| if negative { Ok(-value) } else { Ok(value) })
        } else {
            Err(())
        }
    }
}
