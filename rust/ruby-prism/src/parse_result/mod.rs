//! Parse result types for the prism parser.
//!
//! This module contains types related to the result of parsing, including
//! the main `ParseResult` struct, location tracking, comments, and diagnostics.

mod comments;
mod diagnostics;

use std::ptr::NonNull;

use ruby_prism_sys::{pm_comment_t, pm_diagnostic_t, pm_line_offset_list_line_column, pm_location_t, pm_magic_comment_t, pm_node_destroy, pm_node_t, pm_parser_free, pm_parser_t};

pub use self::comments::{Comment, CommentType, Comments, MagicComment, MagicComments};
pub use self::diagnostics::{Diagnostic, Diagnostics};

use crate::Node;

/// A range in the source file, represented as a start offset and length.
pub struct Location<'pr> {
    pub(crate) parser: NonNull<pm_parser_t>,
    pub(crate) start: u32,
    pub(crate) length: u32,
    marker: std::marker::PhantomData<&'pr [u8]>,
}

impl<'pr> Location<'pr> {
    /// Returns a byte slice for the range.
    #[must_use]
    pub fn as_slice(&self) -> &'pr [u8] {
        unsafe {
            let parser_start = (*self.parser.as_ptr()).start;
            std::slice::from_raw_parts(parser_start.add(self.start as usize), self.length as usize)
        }
    }

    /// Return a Location from the given `pm_location_t`.
    #[must_use]
    pub(crate) const fn new(parser: NonNull<pm_parser_t>, location: &'pr pm_location_t) -> Self {
        Location {
            parser,
            start: location.start,
            length: location.length,
            marker: std::marker::PhantomData,
        }
    }

    /// Returns the end offset from the beginning of the parsed source.
    #[must_use]
    pub const fn end(&self) -> u32 {
        self.start + self.length
    }

    /// Return a Location starting at self and ending at the end of other.
    /// Returns None if both locations did not originate from the same parser,
    /// or if self starts after other.
    #[must_use]
    pub fn join(&self, other: &Self) -> Option<Self> {
        if self.parser != other.parser || self.start > other.start {
            None
        } else {
            Some(Location {
                parser: self.parser,
                start: self.start,
                length: other.end() - self.start,
                marker: std::marker::PhantomData,
            })
        }
    }

    /// Returns the line number where this location starts.
    #[must_use]
    pub fn start_line(&self) -> i32 {
        self.line_column_at(self.start).line
    }

    /// Returns the line number where this location ends.
    #[must_use]
    pub fn end_line(&self) -> i32 {
        self.line_column_at(self.end()).line
    }

    /// Returns the column number in bytes where this location starts from the
    /// start of the line.
    #[must_use]
    pub fn start_column(&self) -> u32 {
        self.line_column_at(self.start).column
    }

    /// Returns the column number in bytes where this location ends from the
    /// start of the line.
    #[must_use]
    pub fn end_column(&self) -> u32 {
        self.line_column_at(self.end()).column
    }

    /// Returns a new location that is the result of chopping off the last byte.
    #[must_use]
    pub const fn chop(&self) -> Self {
        Location {
            parser: self.parser,
            start: self.start,
            length: if self.length == 0 { 0 } else { self.length - 1 },
            marker: std::marker::PhantomData,
        }
    }

    fn line_column_at(&self, offset: u32) -> ruby_prism_sys::pm_line_column_t {
        // SAFETY: `self.parser` is a valid pointer to a `pm_parser_t` that
        // outlives `self`, and `pm_line_offset_list_line_column` only reads
        // from the line offset list.
        unsafe {
            let parser = self.parser.as_ptr();
            let line_offsets = &(*parser).line_offsets;
            let start_line = (*parser).start_line;
            pm_line_offset_list_line_column(line_offsets, offset, start_line)
        }
    }
}

impl std::fmt::Debug for Location<'_> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let slice: &[u8] = self.as_slice();

        let mut visible = String::new();
        visible.push('"');

        for &byte in slice {
            let part: Vec<u8> = std::ascii::escape_default(byte).collect();
            visible.push_str(std::str::from_utf8(&part).unwrap());
        }

        visible.push('"');
        write!(f, "{visible}")
    }
}

/// The result of parsing a source string.
#[derive(Debug)]
pub struct ParseResult<'pr> {
    source: &'pr [u8],
    parser: NonNull<pm_parser_t>,
    node: NonNull<pm_node_t>,
}

impl<'pr> ParseResult<'pr> {
    pub(crate) const unsafe fn new(source: &'pr [u8], parser: NonNull<pm_parser_t>, node: NonNull<pm_node_t>) -> Self {
        ParseResult { source, parser, node }
    }

    /// Returns the source string that was parsed.
    #[must_use]
    pub const fn source(&self) -> &'pr [u8] {
        self.source
    }

    /// Returns whether we found a `frozen_string_literal` magic comment with a true value.
    #[must_use]
    pub fn frozen_string_literals(&self) -> bool {
        unsafe { (*self.parser.as_ptr()).frozen_string_literal == 1 }
    }

    /// Returns a slice of the source string that was parsed using the given
    /// slice range.
    #[must_use]
    pub fn as_slice(&self, location: &Location<'pr>) -> &'pr [u8] {
        let start = location.start as usize;
        let end = start + location.length as usize;
        &self.source[start..end]
    }

    /// Returns an iterator that can be used to iterate over the errors in the
    /// parse result.
    #[must_use]
    pub fn errors(&self) -> Diagnostics<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).error_list;
            Diagnostics::new(list.head.cast::<pm_diagnostic_t>(), self.parser)
        }
    }

    /// Returns an iterator that can be used to iterate over the warnings in the
    /// parse result.
    #[must_use]
    pub fn warnings(&self) -> Diagnostics<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).warning_list;
            Diagnostics::new(list.head.cast::<pm_diagnostic_t>(), self.parser)
        }
    }

    /// Returns an iterator that can be used to iterate over the comments in the
    /// parse result.
    #[must_use]
    pub fn comments(&self) -> Comments<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).comment_list;
            Comments::new(list.head.cast::<pm_comment_t>(), self.parser)
        }
    }

    /// Returns an iterator that can be used to iterate over the magic comments in the
    /// parse result.
    #[must_use]
    pub fn magic_comments(&self) -> MagicComments<'_> {
        unsafe {
            let list = &mut (*self.parser.as_ptr()).magic_comment_list;
            MagicComments::new(self.parser, list.head.cast::<pm_magic_comment_t>())
        }
    }

    /// Returns an optional location of the __END__ marker and the rest of the content of the file.
    #[must_use]
    pub fn data_loc(&self) -> Option<Location<'_>> {
        let location = unsafe { &(*self.parser.as_ptr()).data_loc };
        if location.length == 0 {
            None
        } else {
            Some(Location::new(self.parser, location))
        }
    }

    /// Returns the root node of the parse result.
    #[must_use]
    pub fn node(&self) -> Node<'_> {
        Node::new(self.parser, self.node.as_ptr())
    }
}

impl Drop for ParseResult<'_> {
    fn drop(&mut self) {
        unsafe {
            pm_node_destroy(self.parser.as_ptr(), self.node.as_ptr());
            pm_parser_free(self.parser.as_ptr());
            drop(Box::from_raw(self.parser.as_ptr()));
        }
    }
}
