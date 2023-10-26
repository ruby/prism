namespace :cargo do
  CRATES = ["prism-sys", "prism"]

  desc "Build and test the Rust packages"
  task build: [:templates] do
    gemspec = Gem::Specification.load("prism.gemspec")
    prism_sys_dir = Pathname(File.expand_path(File.join(__dir__, "../rust", "prism-sys")))
    prism_sys_vendor_dir = prism_sys_dir.join("vendor/prism-#{gemspec.version}")

    rm_rf(prism_sys_vendor_dir)
    mkdir_p(prism_sys_vendor_dir)
    cp_r("./include", prism_sys_vendor_dir.join("include"))
    cp_r("./src", prism_sys_vendor_dir.join("src"))

    # Align the Cargo.toml version with the gemspec version
    ["prism-sys", "prism"].each do |dir|
      cargo_toml_path = Pathname.new("rust/#{dir}/Cargo.toml")
      old_cargo_toml = cargo_toml_path.read
      new_cargo_toml = old_cargo_toml.gsub(/^version = ".*"/, %(version = "#{gemspec.version}"))
      File.write(cargo_toml_path, new_cargo_toml)
    end
  end

  desc "Run all cargo tests"
  task test: [:build] do
    Dir["rust/*/Cargo.toml"].each do |cargo_toml|
      Dir.chdir(File.dirname(cargo_toml)) do
        sh "cargo test -- --nocapture"
      end
    end
  end

  desc "Run all examples"
  task examples: [:build] do
    Dir.chdir("rust/prism") do
      Dir.glob("examples/*").each do |example|
        puts "Running #{example}"

        script = File.join(example, "run.sh")
        if File.exist?(script)
          sh script
        else
          sh "cargo run --example #{example}"
        end
      end
    end
  end

  desc "Run clippy the Rust code"
  task lint: [:build] do
    CRATES.each do |dir|
      Dir.chdir("rust/#{dir}") do
        sh "cargo clippy --tests -- -W 'clippy::pedantic'"
        sh "cargo fmt --all -- --check"
      end
    end
  end

  desc "Run rustfmt on the Rust code"
  task fmt: [:build] do
    ["prism-sys", "prism"].each do |dir|
      Dir.chdir("rust/#{dir}") do
        sh "cargo fmt --all"
      end
    end
  end

  namespace :sanitize do
    [:leak, :address].each do |sanitizer|
      desc "Test with #{sanitizer} sanitizer"
      task sanitizer => :build do
        require "json"
        require "net/http"

        old_env = ENV.to_h
        ENV['RUSTFLAGS'] = "-Zsanitizer=#{sanitizer}"
        ENV['RUSTDOCFLAGS'] = "-Zsanitizer=#{sanitizer}"
        ENV['ASAN_OPTIONS'] = 'detect_stack_use_after_return=1'
        ENV['RUST_BACKTRACE'] = '0'

        target_info_url = "https://raw.githubusercontent.com/oxidize-rb/rb-sys/main/data/derived/ruby-to-rust.json"
        toolchain_data = Net::HTTP.get(URI.parse(target_info_url))
        toolchain_data = JSON.parse(toolchain_data)
        gem_platform = Gem::Platform.local
        current_target = toolchain_data.fetch("#{gem_platform.cpu}-#{gem_platform.os}")

        CRATES.each do |crate|
          Dir.chdir("rust/#{crate}") do
            sh("cargo +nightly-2023-10-24 test -Zbuild-std --target=#{current_target} -- --nocapture")
          end
        end
      ensure
        ENV.replace(old_env)
      end
    end

    desc "Test with all sanitizers"
    task all: [:leak, :address]
  end

  namespace :publish do
    desc "Publish the Rust crates"
    task :real do
      print "🚢 Publishing to crates.io in 5 seconds (use ctrl-c to cancel)"

      10.times do |i|
        sleep 0.5
        print "."
      end

      Rake::Task["cargo:build"].invoke

      CRATES.each do |crate|
        Dir.chdir("rust/#{crate}") do
          puts "🚢 Publishing #{crate} to crates.io"
          sh "cargo publish --dry-run"
        end
      end
    end

    desc "Dry run the publish of the Rust crates"
    task :dry do
      print "🌵 Running publish with --dry-run, use `rake cargo:publish:real` to actually publish"

      6.times do |i|
        sleep 0.5
        print "."
      end

      Rake::Task["cargo:build"].invoke

      CRATES.each do |crate|
        Dir.chdir("rust/#{crate}") do
          puts "🌵 [dry-run] Checking publish of #{crate} to crates.io"
          sh "cargo publish --dry-run"
        end
      end
    end
  end

  task publish: ["cargo:publish:dry"]
end
