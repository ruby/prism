//! Comment handling for the prism parser.

use std::marker::PhantomData;

use ruby_prism_sys::{pm_comment_location, pm_comment_t, pm_comment_type, pm_comment_type_t, pm_magic_comment_key, pm_magic_comment_t, pm_magic_comment_value, pm_node_comment, pm_node_t, pm_parser_start, pm_parser_t};

use super::Location;

/// The type of the comment
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CommentType {
    /// `InlineComment` corresponds to comments that start with #.
    InlineComment,
    /// `EmbDocComment` corresponds to comments that are surrounded by =begin and =end.
    EmbDocComment,
}

/// A comment that was found during parsing.
#[derive(Debug)]
pub struct Comment<'pr> {
    raw: *const pm_comment_t,
    parser: *const pm_parser_t,
    marker: PhantomData<&'pr pm_comment_t>,
}

impl<'pr> Comment<'pr> {
    /// Returns the text of the comment.
    #[must_use]
    pub fn text(&self) -> &[u8] {
        self.location().as_slice()
    }

    /// Returns the type of the comment.
    #[must_use]
    pub fn type_(&self) -> CommentType {
        let type_ = unsafe { pm_comment_type(self.raw) };
        if type_ == pm_comment_type_t::PM_COMMENT_EMBDOC {
            CommentType::EmbDocComment
        } else {
            CommentType::InlineComment
        }
    }

    /// The location of the comment in the source.
    #[must_use]
    pub fn location(&self) -> Location<'pr> {
        let loc = unsafe { pm_comment_location(self.raw) };
        Location {
            parser: self.parser,
            start: loc.start,
            length: loc.length,
            marker: PhantomData,
        }
    }
}

enum CommentsSource {
    Slice(Vec<*const pm_comment_t>),
    Node { node: *const pm_node_t, count: u32 },
}

/// An iterator over comments collected from the parse result or attached to a node.
pub struct Comments<'pr> {
    source: CommentsSource,
    index: usize,
    parser: *const pm_parser_t,
    marker: PhantomData<&'pr pm_comment_t>,
}

impl Comments<'_> {
    pub(crate) const fn new(ptrs: Vec<*const pm_comment_t>, parser: *const pm_parser_t) -> Self {
        Comments {
            source: CommentsSource::Slice(ptrs),
            index: 0,
            parser,
            marker: PhantomData,
        }
    }

    pub(crate) const fn for_node(parser: *const pm_parser_t, node: *const pm_node_t, count: u32) -> Self {
        Comments {
            source: CommentsSource::Node { node, count },
            index: 0,
            parser,
            marker: PhantomData,
        }
    }

    const fn remaining(&self) -> usize {
        match &self.source {
            CommentsSource::Slice(ptrs) => ptrs.len().saturating_sub(self.index),
            CommentsSource::Node { count, .. } => (*count as usize).saturating_sub(self.index),
        }
    }
}

impl<'pr> Iterator for Comments<'pr> {
    type Item = Comment<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        let comment = match &self.source {
            CommentsSource::Slice(ptrs) => *ptrs.get(self.index)?,
            CommentsSource::Node { node, count } => {
                if self.index >= *count as usize {
                    return None;
                }

                unsafe { pm_node_comment(self.parser, *node, u32::try_from(self.index).ok()?) }
            },
        };

        self.index += 1;
        Some(Comment { raw: comment, parser: self.parser, marker: PhantomData })
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        let remaining = self.remaining();
        (remaining, Some(remaining))
    }
}

impl ExactSizeIterator for Comments<'_> {}

/// A magic comment that was found during parsing.
#[derive(Debug)]
pub struct MagicComment<'pr> {
    parser: *const pm_parser_t,
    raw: *const pm_magic_comment_t,
    marker: PhantomData<&'pr pm_magic_comment_t>,
}

impl MagicComment<'_> {
    /// Returns the text of the comment's key.
    #[must_use]
    pub fn key(&self) -> &[u8] {
        unsafe {
            let loc = pm_magic_comment_key(self.raw);
            let start = pm_parser_start(self.parser).add(loc.start as usize);
            std::slice::from_raw_parts(start, loc.length as usize)
        }
    }

    /// Returns the text of the comment's value.
    #[must_use]
    pub fn value(&self) -> &[u8] {
        unsafe {
            let loc = pm_magic_comment_value(self.raw);
            let start = pm_parser_start(self.parser).add(loc.start as usize);
            std::slice::from_raw_parts(start, loc.length as usize)
        }
    }
}

/// An iterator over magic comments collected from the parse result.
pub struct MagicComments<'pr> {
    ptrs: Vec<*const pm_magic_comment_t>,
    index: usize,
    parser: *const pm_parser_t,
    marker: PhantomData<&'pr pm_magic_comment_t>,
}

impl MagicComments<'_> {
    pub(crate) const fn new(ptrs: Vec<*const pm_magic_comment_t>, parser: *const pm_parser_t) -> Self {
        MagicComments { ptrs, index: 0, parser, marker: PhantomData }
    }
}

impl<'pr> Iterator for MagicComments<'pr> {
    type Item = MagicComment<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.index < self.ptrs.len() {
            let comment = self.ptrs[self.index];
            self.index += 1;
            Some(MagicComment { parser: self.parser, raw: comment, marker: PhantomData })
        } else {
            None
        }
    }
}
