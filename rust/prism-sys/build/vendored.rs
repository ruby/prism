use std::{
    fs,
    path::{Path, PathBuf},
};

/// Builds libprism.a from source, and configures the build script to use it.
pub fn build() -> Result<(), Box<dyn std::error::Error>> {
    assert!(
        vendor_dir().exists(),
        "Prism source directory does not exist, expected: {}",
        vendor_dir().display(),
    );

    println!("cargo:rerun-if-changed={}", vendor_dir().display());

    let out_dir = PathBuf::from(std::env::var_os("OUT_DIR").expect("OUT_DIR is not set"));
    let mut build = cc::Build::new();

    let mut defines = vec![("PRISM_EXPORT_SYMBOLS", "1")];
    let mut includes = vec![include_dir()];
    let mut flags = vec![];

    if let Ok(target) = std::env::var("TARGET") {
        if target.contains("wasm32") && target.contains("wasi") {
            println!("cargo:rerun-if-env-changed=WASI_SDK_PATH");

            if let Ok(wasi_sdk_path) = std::env::var("WASI_SDK_PATH").map(PathBuf::from) {
                let wasi_sdk_clang = wasi_sdk_path.join("bin").join("clang");
                build.compiler(wasi_sdk_clang);

                let wasi_sysroot = wasi_sdk_path.join("share").join("wasi-sysroot");
                flags.push(format!("--sysroot={}", wasi_sysroot.display()));

                let wasi_libc_include = wasi_sysroot.join("include");
                includes.push(wasi_libc_include.clone());

                let wasi_lib_dir = wasi_sysroot.join("lib/wasm32-wasi");
                println!("cargo:rustc-link-search=native={}", wasi_lib_dir.display());

                defines.push(("_WASI_EMULATED_MMAN", "1"));
                println!("cargo:rustc-link-lib=wasi-emulated-mman");
            } else {
                panic!("WASI_SDK_PATH is not set, cannot build for {target}");
            }
        }
    }

    for (key, value) in defines {
        build.define(key, value);
        push_bindgen_extra_clang_args(format!("-D{key}={value}"));
    }

    for include in includes {
        build.include(&include);
        push_bindgen_extra_clang_args(format!("-I{}", include.display()));
    }

    for flag in flags {
        build.flag(&flag);
        push_bindgen_extra_clang_args(flag);
    }

    build.files(source_files(src_dir()));
    build.out_dir(&out_dir);
    build.try_compile("rubyparser")?;

    std::env::set_var("PRISM_INCLUDE_DIR", include_dir());
    std::env::set_var("PRISM_LIB_DIR", out_dir);

    Ok(())
}

fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}

fn vendor_dir() -> PathBuf {
    let prism_dir = format!("prism-{}", version());
    Path::new(env!("CARGO_MANIFEST_DIR")).join("vendor").join(prism_dir)
}

fn src_dir() -> PathBuf {
    vendor_dir().join("src")
}

fn include_dir() -> PathBuf {
    vendor_dir().join("include")
}

fn push_bindgen_extra_clang_args<T: AsRef<str>>(arg: T) {
    let env_var_name = format!("BINDGEN_EXTRA_CLANG_ARGS_{}", std::env::var("TARGET").unwrap());

    if let Ok(preexisting_arg) = std::env::var(&env_var_name) {
        std::env::set_var(env_var_name, format!("{} {}", preexisting_arg, arg.as_ref()));
    } else {
        std::env::set_var(env_var_name, arg.as_ref());
    }
}

fn source_files<P: AsRef<Path>>(root_dir: P) -> Vec<String> {
    let mut files = Vec::new();

    for entry in fs::read_dir(root_dir.as_ref()).unwrap() {
        let entry = entry.unwrap();
        let path = entry.path();

        if path.is_file() {
            let path = path.to_str().unwrap().to_string();

            if Path::new(&path)
                .extension()
                .map_or(false, |ext| ext.eq_ignore_ascii_case("c"))
            {
                files.push(path);
            }
        } else if path.is_dir() {
            files.extend(source_files(path));
        }
    }

    files
}
