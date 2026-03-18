//! Parse result types for the prism parser.

mod comments;
mod diagnostics;

use std::ptr::NonNull;

use ruby_prism_sys::{
    pm_arena_free, pm_arena_t, pm_comment_t, pm_diagnostic_t, pm_line_offset_list_line_column, pm_location_t, pm_magic_comment_t, pm_node_t, pm_parser_comments_each, pm_parser_comments_size, pm_parser_data_loc, pm_parser_errors_each, pm_parser_errors_size, pm_parser_free,
    pm_parser_frozen_string_literal, pm_parser_line_offsets, pm_parser_magic_comments_each, pm_parser_magic_comments_size, pm_parser_start, pm_parser_start_line, pm_parser_t, pm_parser_warnings_each, pm_parser_warnings_size,
};

pub use self::comments::{Comment, CommentType, Comments, MagicComment, MagicComments};
pub use self::diagnostics::{Diagnostic, Diagnostics};

use crate::Node;

/// A range in the source file, represented as a start offset and length.
pub struct Location<'pr> {
    pub(crate) parser: *const pm_parser_t,
    pub(crate) start: u32,
    pub(crate) length: u32,
    marker: std::marker::PhantomData<&'pr [u8]>,
}

impl<'pr> Location<'pr> {
    /// Returns a byte slice for the range.
    #[must_use]
    pub fn as_slice(&self) -> &'pr [u8] {
        unsafe {
            let parser_start = pm_parser_start(self.parser);
            std::slice::from_raw_parts(parser_start.add(self.start as usize), self.length as usize)
        }
    }

    /// Return a Location from the given `pm_location_t`.
    #[must_use]
    pub(crate) const fn new(parser: *const pm_parser_t, location: &'pr pm_location_t) -> Self {
        Location {
            parser,
            start: location.start,
            length: location.length,
            marker: std::marker::PhantomData,
        }
    }

    /// Returns the start offset from the beginning of the parsed source.
    #[must_use]
    pub const fn start(&self) -> u32 {
        self.start
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
}

impl Location<'_> {
    /// Returns the line number where this location starts.
    #[must_use]
    pub fn start_line(&self) -> i32 {
        self.line_column(self.start).0
    }

    /// Returns the column number in bytes where this location starts from the
    /// start of the line.
    #[must_use]
    pub fn start_column(&self) -> u32 {
        self.line_column(self.start).1
    }

    /// Returns the line number where this location ends.
    #[must_use]
    pub fn end_line(&self) -> i32 {
        self.line_column(self.end()).0
    }

    /// Returns the column number in bytes where this location ends from the
    /// start of the line.
    #[must_use]
    pub fn end_column(&self) -> u32 {
        self.line_column(self.end()).1
    }

    /// Returns the line and column number for the given byte offset.
    fn line_column(&self, cursor: u32) -> (i32, u32) {
        unsafe {
            let line_offsets = pm_parser_line_offsets(self.parser);
            let start_line = pm_parser_start_line(self.parser);
            let result = pm_line_offset_list_line_column(line_offsets, cursor, start_line);
            (result.line, result.column)
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

// C callback that collects comment pointers into a Vec
unsafe extern "C" fn collect_comment(comment: *const pm_comment_t, data: *mut std::ffi::c_void) {
    let vec = &mut *(data.cast::<Vec<*const pm_comment_t>>());
    vec.push(comment);
}

// C callback that collects magic comment pointers into a Vec
unsafe extern "C" fn collect_magic_comment(comment: *const pm_magic_comment_t, data: *mut std::ffi::c_void) {
    let vec = &mut *(data.cast::<Vec<*const pm_magic_comment_t>>());
    vec.push(comment);
}

// C callback that collects diagnostic pointers into a Vec
unsafe extern "C" fn collect_diagnostic(diagnostic: *const pm_diagnostic_t, data: *mut std::ffi::c_void) {
    let vec = &mut *(data.cast::<Vec<*const pm_diagnostic_t>>());
    vec.push(diagnostic);
}

/// The result of parsing a source string.
#[derive(Debug)]
pub struct ParseResult<'pr> {
    source: &'pr [u8],
    arena: *mut pm_arena_t,
    parser: *mut pm_parser_t,
    node: NonNull<pm_node_t>,
}

impl<'pr> ParseResult<'pr> {
    pub(crate) const unsafe fn new(source: &'pr [u8], arena: *mut pm_arena_t, parser: *mut pm_parser_t, node: NonNull<pm_node_t>) -> Self {
        ParseResult { source, arena, parser, node }
    }

    /// Returns the source string that was parsed.
    #[must_use]
    pub const fn source(&self) -> &'pr [u8] {
        self.source
    }

    /// Returns whether we found a `frozen_string_literal` magic comment with a true value.
    #[must_use]
    pub fn frozen_string_literals(&self) -> bool {
        unsafe { pm_parser_frozen_string_literal(self.parser) == 1 }
    }

    /// Returns a slice of the source string that was parsed using the given
    /// slice range.
    #[must_use]
    pub fn as_slice(&self, location: &Location<'pr>) -> &'pr [u8] {
        let start = location.start as usize;
        let end = start + location.length as usize;
        &self.source[start..end]
    }

    /// Returns a slice containing the offsets of the start of each line in the source string
    /// that was parsed.
    #[must_use]
    pub fn line_offsets(&self) -> &'pr [u32] {
        unsafe {
            let list = &*pm_parser_line_offsets(self.parser);
            std::slice::from_raw_parts(list.offsets, list.size)
        }
    }

    /// Returns an iterator that can be used to iterate over the errors in the
    /// parse result.
    #[must_use]
    pub fn errors(&self) -> Diagnostics<'_> {
        let size = unsafe { pm_parser_errors_size(self.parser) };
        let mut ptrs: Vec<*const pm_diagnostic_t> = Vec::with_capacity(size);
        unsafe {
            pm_parser_errors_each(self.parser, Some(collect_diagnostic), (&raw mut ptrs).cast());
        }
        Diagnostics::new(ptrs, self.parser)
    }

    /// Returns an iterator that can be used to iterate over the warnings in the
    /// parse result.
    #[must_use]
    pub fn warnings(&self) -> Diagnostics<'_> {
        let size = unsafe { pm_parser_warnings_size(self.parser) };
        let mut ptrs: Vec<*const pm_diagnostic_t> = Vec::with_capacity(size);
        unsafe {
            pm_parser_warnings_each(self.parser, Some(collect_diagnostic), (&raw mut ptrs).cast());
        }
        Diagnostics::new(ptrs, self.parser)
    }

    /// Returns an iterator that can be used to iterate over the comments in the
    /// parse result.
    #[must_use]
    pub fn comments(&self) -> Comments<'_> {
        let size = unsafe { pm_parser_comments_size(self.parser) };
        let mut ptrs: Vec<*const pm_comment_t> = Vec::with_capacity(size);
        unsafe {
            pm_parser_comments_each(self.parser, Some(collect_comment), (&raw mut ptrs).cast());
        }
        Comments::new(ptrs, self.parser)
    }

    /// Returns an iterator that can be used to iterate over the magic comments in the
    /// parse result.
    #[must_use]
    pub fn magic_comments(&self) -> MagicComments<'_> {
        let size = unsafe { pm_parser_magic_comments_size(self.parser) };
        let mut ptrs: Vec<*const pm_magic_comment_t> = Vec::with_capacity(size);
        unsafe {
            pm_parser_magic_comments_each(self.parser, Some(collect_magic_comment), (&raw mut ptrs).cast());
        }
        MagicComments::new(ptrs, self.parser)
    }

    /// Returns an optional location of the __END__ marker and the rest of the content of the file.
    #[must_use]
    pub fn data_loc(&self) -> Option<Location<'_>> {
        let location = unsafe { &*pm_parser_data_loc(self.parser) };
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

    /// Returns true if there were no errors during parsing and false if there
    /// were.
    #[must_use]
    pub fn is_success(&self) -> bool {
        self.errors().next().is_none()
    }

    /// Returns true if there were errors during parsing and false if there were
    /// not.
    #[must_use]
    pub fn is_failure(&self) -> bool {
        !self.is_success()
    }
}

impl Drop for ParseResult<'_> {
    fn drop(&mut self) {
        unsafe {
            pm_parser_free(self.parser);
            pm_arena_free(self.arena);
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::parse;

    #[test]
    fn test_is_success() {
        let result = parse(b"1 + 1");
        assert!(result.is_success());
        assert!(!result.is_failure());
    }

    #[test]
    fn test_is_failure() {
        let result = parse(b"<>");
        assert!(result.is_failure());
        assert!(!result.is_success());
    }
}
