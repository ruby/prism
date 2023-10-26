use std::io::{stdin, Read};

fn main() {
    let mut source = String::new();
    stdin().read_to_string(&mut source).unwrap();
    let result = prism::parse(source.as_ref());
    let comments_count = result.comments().count();
    let warnings_count = result.warnings().count();
    let errors_count = result.errors().count();
    println!("  comments: {}", comments_count);
    println!("  warnings: {}", warnings_count);
    println!("  errors: {}", errors_count);
}
