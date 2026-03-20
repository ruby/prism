//! Diagnostic handling for parse errors and warnings.

use std::ffi::CStr;
use std::marker::PhantomData;

use ruby_prism_sys::{pm_diagnostic_location, pm_diagnostic_message, pm_diagnostic_t, pm_parser_t};

use super::Location;

/// A diagnostic message that came back from the parser.
#[derive(Debug)]
pub struct Diagnostic<'pr> {
    raw: *const pm_diagnostic_t,
    parser: *const pm_parser_t,
    marker: PhantomData<&'pr pm_diagnostic_t>,
}

impl<'pr> Diagnostic<'pr> {
    /// Returns the message associated with the diagnostic.
    ///
    /// # Panics
    ///
    /// Panics if the message is not valid UTF-8.
    #[must_use]
    pub fn message(&self) -> &str {
        unsafe {
            let message = pm_diagnostic_message(self.raw);
            CStr::from_ptr(message).to_str().expect("prism allows only UTF-8 for diagnostics.")
        }
    }

    /// The location of the diagnostic in the source.
    #[must_use]
    pub fn location(&self) -> Location<'pr> {
        let loc = unsafe { pm_diagnostic_location(self.raw) };
        Location {
            parser: self.parser,
            start: loc.start,
            length: loc.length,
            marker: PhantomData,
        }
    }
}

/// An iterator over diagnostics collected from the parse result.
pub struct Diagnostics<'pr> {
    ptrs: Vec<*const pm_diagnostic_t>,
    index: usize,
    parser: *const pm_parser_t,
    marker: PhantomData<&'pr pm_diagnostic_t>,
}

impl Diagnostics<'_> {
    pub(crate) const fn new(ptrs: Vec<*const pm_diagnostic_t>, parser: *const pm_parser_t) -> Self {
        Diagnostics { ptrs, index: 0, parser, marker: PhantomData }
    }
}

impl<'pr> Iterator for Diagnostics<'pr> {
    type Item = Diagnostic<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.index < self.ptrs.len() {
            let diagnostic = self.ptrs[self.index];
            self.index += 1;
            Some(Diagnostic {
                raw: diagnostic,
                parser: self.parser,
                marker: PhantomData,
            })
        } else {
            None
        }
    }
}
