use std::{
    borrow::Cow,
    cell::RefCell,
    fs::File,
    process::{Command, Stdio},
};

use bindgen::callbacks::ParseCallbacks;

fn main() {
    use std::io::Write;

    let code = generate_bindings().expect("Failed to generate bindings");
    let code = code.replace("#[test]", "#[test]\n#[allow(non_snake_case)]");
    let clippy = "#![allow(clippy::missing_safety_doc)]";

    let mut output_file = File::create("rust/yarp-sys/src/bindings.rs").unwrap();
    write!(output_file, "{clippy}\n\n{code}").unwrap();

    show_git_diff();
}

/// Cleans up the generated bindings to look more like idiomatic Rust.
#[derive(Debug, Default)]
pub struct Prettier {
    do_not_rename: RefCell<Vec<String>>,
}

impl ParseCallbacks for Prettier {
    fn process_comment(&self, comment: &str) -> Option<String> {
        Some(comment.trim().to_string())
    }

    fn enum_variant_name(
        &self,
        enum_name: Option<&str>,
        original_variant_name: &str,
        _variant_value: bindgen::callbacks::EnumVariantValue,
    ) -> Option<String> {
        if !is_yp_like(original_variant_name) {
            return None;
        }

        let enum_name_parts: Vec<String> = enum_name
            .map(|s| s.trim_start_matches("enum "))
            .map(trim_item)
            .map(|name| name.split('_').map(titlecase).collect::<Vec<_>>())
            .unwrap_or_default();
        let enum_name_prefix = enum_name_parts.join("");

        let name = trim_item(original_variant_name);
        let parts = name.split('_').map(titlecase).collect::<Vec<_>>();

        // Something like YP_SOME_ENUM_SOME_VARIANT for the YP_SOME_ENUM enum.
        // We remove the redundant part in the variant name, so it becomes
        // SomeEnumVariant
        let basic_trimmed_name = parts.join("");
        let enum_name_prefix = enum_name_prefix.trim_end_matches("Type");
        let fully_trimmed_name = basic_trimmed_name.trim_start_matches(enum_name_prefix);

        if fully_trimmed_name.starts_with(|c: char| c.is_alphabetic()) {
            Some(fully_trimmed_name.to_string())
        } else {
            Some(basic_trimmed_name.to_string())
        }
    }

    // Allows us to filter out functions, since we dont want to rename those.
    fn generated_name_override(
        &self,
        item_info: bindgen::callbacks::ItemInfo<'_>,
    ) -> Option<String> {
        if !is_yp_like(item_info.name) {
            return None;
        }

        if let bindgen::callbacks::ItemKind::Function = item_info.kind {
            self.do_not_rename
                .borrow_mut()
                .push(item_info.name.to_string());
            None
        } else {
            Some(trim_item(item_info.name).to_string())
        }
    }

    fn item_name(&self, original_item_name: &str) -> Option<String> {
        if !is_yp_like(original_item_name) {
            return None;
        }

        // We dont want to rename functions, keep them as is.
        if self
            .do_not_rename
            .borrow()
            .contains(&original_item_name.to_string())
        {
            return None;
        }

        let item_name = trim_item(original_item_name);
        let parts = item_name.split('_').filter(|s| !s.is_empty());
        let mut name = String::new();

        for part in parts {
            let part = part.trim_matches('_');
            let mut chars = part.chars();

            if chars.all(|c: char| c.is_ascii_uppercase()) {
                if !name.is_empty() {
                    name.push('_');
                }
                name.push_str(part);
            } else {
                name.push_str(&titlecase(part));
            }
        }

        Some(name)
    }
}

fn new_bindgen_builder(proceessor: Prettier) -> Result<String, bindgen::BindgenError> {
    const YP_PREFIX: &str = "^(YP_|yp_).*";

    let bindings = bindgen::builder()
        .clang_arg("-I./include")
        .clang_arg("-fparse-all-comments")
        .disable_header_comment()
        .sort_semantically(true)
        .header("./include/yarp.h")
        .size_t_is_usize(true)
        .layout_tests(true)
        .impl_debug(true)
        .merge_extern_blocks(true)
        .prepend_enum_name(false)
        .generate_cstr(true)
        .generate_block(true)
        .derive_copy(false)
        .derive_default(false)
        .parse_callbacks(Box::new(proceessor))
        .rustified_enum(".*")
        .allowlist_function(YP_PREFIX)
        .allowlist_type(YP_PREFIX)
        .allowlist_var(YP_PREFIX)
        .generate_comments(true);

    bindings.generate().map(|b| b.to_string())
}

fn rustfmt(code: String) -> Result<String, Box<dyn std::error::Error>> {
    use std::io::Write;

    let mut child = Command::new("rustfmt")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()?;

    {
        let stdin = child.stdin.as_mut().expect("Failed to open stdin");
        stdin.write_all(code.as_bytes())?;
    }

    let output = child.wait_with_output()?;
    let stdout = String::from_utf8(output.stdout)?;

    Ok(stdout)
}

fn filter_unneccesary(code: String) -> String {
    use std::fmt::Write;
    let mut output = String::with_capacity(code.len());

    code.lines()
        .filter(|line| !line.starts_with("pub const String_"))
        .filter(|line| !line.starts_with("pub const LexMode_"))
        .for_each(|line| writeln!(&mut output, "{}", line).unwrap());

    output
}

fn generate_bindings() -> Result<String, Box<dyn std::error::Error>> {
    let code = new_bindgen_builder(Prettier::default())?;
    let code = filter_unneccesary(code);

    rustfmt(code)
}

fn show_git_diff() {
    Command::new("git")
        .args(["diff", "rust/yarp-sys/src/bindings.rs"])
        .stderr(Stdio::inherit())
        .stdout(Stdio::inherit())
        .output()
        .expect("Failed to run git diff");
}

// The yp_ and _t stuff is just noise in rust
fn trim_item(name: &str) -> Cow<str> {
    let new_name = name
        .trim_start_matches("YP_")
        .trim_start_matches("yp_")
        .trim_end_matches("_t");

    let new_name: Cow<str> = if new_name.contains("_t_") {
        new_name.replace("_t_", "_").into()
    } else {
        new_name.into()
    };

    if new_name.contains("bindgen") {
        new_name.replace("bindgen", "unknown").into()
    } else {
        new_name
    }
}

fn is_yp_like(name: &str) -> bool {
    name.starts_with("YP_") || name.starts_with("yp_")
}

fn titlecase(input: &str) -> String {
    let mut chars = input.chars();
    let mut output = String::new();

    if let Some(first_char) = chars.next() {
        output.push_str(&first_char.to_uppercase().to_string());
        output.extend(chars.map(|c| c.to_ascii_lowercase()));
    }

    output
}
