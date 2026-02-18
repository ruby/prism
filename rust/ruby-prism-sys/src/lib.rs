//! # ruby-prism-sys
//!
//! FFI-bindings for `prism`.
//!
#![deny(unused_extern_crates)]
#![warn(
    clippy::all,
    clippy::nursery,
    clippy::pedantic,
    future_incompatible,
    missing_copy_implementations,
    missing_docs,
    nonstandard_style,
    rust_2018_idioms,
    trivial_casts,
    trivial_numeric_casts,
    unreachable_pub,
    unused_qualifications
)]

#[allow(clippy::all, clippy::pedantic, clippy::cognitive_complexity)]
#[allow(missing_copy_implementations)]
#[allow(missing_docs)]
#[allow(non_camel_case_types)]
#[allow(non_snake_case)]
#[allow(non_upper_case_globals)]
#[allow(unused_qualifications)]
#[allow(clippy::missing_const_for_fn)]
#[allow(clippy::use_self)]
mod bindings {
    // In `build.rs`, we use `bindgen` to generate bindings based on C headers
    // and `libprism`. Here is where we pull in those bindings and make
    // them part of our library.
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

pub use self::bindings::*;

/// Line and column information for a given byte offset relative to the
/// beginning of the source.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct pm_line_column_t {
    /// The 1-indexed line number relative to the start line configured on the
    /// parser.
    pub line: i32,
    /// The 0-indexed column number in bytes.
    pub column: u32,
}

extern "C" {
    /// Return the line and column number for the given byte offset relative to
    /// the beginning of the source.
    pub fn pm_newline_list_line_column(
        list: *const pm_newline_list_t,
        cursor: u32,
        start_line: i32,
    ) -> pm_line_column_t;
}
