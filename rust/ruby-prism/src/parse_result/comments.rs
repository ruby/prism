//! Comment handling for the prism parser.

use std::marker::PhantomData;
use std::ptr::NonNull;

use ruby_prism_sys::{pm_comment_t, pm_comment_type_t, pm_magic_comment_t, pm_parser_t};

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
    content: NonNull<pm_comment_t>,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_comment_t>,
}

impl<'pr> Comment<'pr> {
    /// Returns the text of the comment.
    ///
    /// # Panics
    /// Panics if the end offset is not greater than the start offset.
    #[must_use]
    pub fn text(&self) -> &[u8] {
        self.location().as_slice()
    }

    /// Returns the type of the comment.
    #[must_use]
    pub fn type_(&self) -> CommentType {
        let type_ = unsafe { self.content.as_ref().type_ };
        if type_ == pm_comment_type_t::PM_COMMENT_EMBDOC {
            CommentType::EmbDocComment
        } else {
            CommentType::InlineComment
        }
    }

    /// The location of the comment in the source.
    #[must_use]
    pub const fn location(&self) -> Location<'pr> {
        Location::new(self.parser, unsafe { &self.content.as_ref().location })
    }
}

/// A struct created by the `comments` method on `ParseResult`. It can be used
/// to iterate over the comments in the parse result.
pub struct Comments<'pr> {
    comment: *mut pm_comment_t,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_comment_t>,
}

impl Comments<'_> {
    pub(crate) const fn new(comment: *mut pm_comment_t, parser: NonNull<pm_parser_t>) -> Self {
        Comments { comment, parser, marker: PhantomData }
    }
}

impl<'pr> Iterator for Comments<'pr> {
    type Item = Comment<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(comment) = NonNull::new(self.comment) {
            let current = Comment {
                content: comment,
                parser: self.parser,
                marker: PhantomData,
            };
            self.comment = unsafe { comment.as_ref().node.next.cast::<pm_comment_t>() };
            Some(current)
        } else {
            None
        }
    }
}

/// A magic comment that was found during parsing.
#[derive(Debug)]
pub struct MagicComment<'pr> {
    parser: NonNull<pm_parser_t>,
    comment: NonNull<pm_magic_comment_t>,
    marker: PhantomData<&'pr pm_magic_comment_t>,
}

impl MagicComment<'_> {
    /// Returns the text of the comment's key.
    #[must_use]
    pub const fn key(&self) -> &[u8] {
        unsafe {
            let start = self.parser.as_ref().start.add(self.comment.as_ref().key.start as usize);
            let len = self.comment.as_ref().key.length as usize;
            std::slice::from_raw_parts(start, len)
        }
    }

    /// Returns the text of the comment's value.
    #[must_use]
    pub const fn value(&self) -> &[u8] {
        unsafe {
            let start = self.parser.as_ref().start.add(self.comment.as_ref().value.start as usize);
            let len = self.comment.as_ref().value.length as usize;
            std::slice::from_raw_parts(start, len)
        }
    }
}

/// A struct created by the `magic_comments` method on `ParseResult`. It can be used
/// to iterate over the magic comments in the parse result.
pub struct MagicComments<'pr> {
    parser: NonNull<pm_parser_t>,
    comment: *mut pm_magic_comment_t,
    marker: PhantomData<&'pr pm_magic_comment_t>,
}

impl MagicComments<'_> {
    pub(crate) const fn new(parser: NonNull<pm_parser_t>, comment: *mut pm_magic_comment_t) -> Self {
        MagicComments { parser, comment, marker: PhantomData }
    }
}

impl<'pr> Iterator for MagicComments<'pr> {
    type Item = MagicComment<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(comment) = NonNull::new(self.comment) {
            let current = MagicComment { parser: self.parser, comment, marker: PhantomData };
            self.comment = unsafe { comment.as_ref().node.next.cast::<pm_magic_comment_t>() };
            Some(current)
        } else {
            None
        }
    }
}
