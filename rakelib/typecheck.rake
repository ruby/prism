# frozen_string_literal: true

namespace :typecheck do
  def with_gemfile
    Bundler.with_original_env do
      ENV['BUNDLE_GEMFILE'] = "gemfiles/typecheck/Gemfile"
      yield
    end
  end

  task tapioca: :templates do
    Rake::Task["compile:prism"].invoke

    with_gemfile do
      sh "bundle", "exec", "tapioca", "configure"
      sh "bundle", "exec", "tapioca", "gems", "--exclude", "prism"
      sh "bundle", "exec", "tapioca", "todo"
    end
  end

  desc "Typecheck with Sorbet"
  task sorbet: :templates do
    locals = {
      polyfills: Dir["lib/prism/polyfill/**/*.rb"],
      gem_rbis: Dir["sorbet/rbi/**/*.rbi"]
    }

    File.write("sorbet/typed_overrides.yml", ERB.new(<<~YAML, trim_mode: "-").result_with_hash(locals))
      false:
        - ./lib/prism/lex_compat.rb
        - ./lib/prism/node_ext.rb
        - ./lib/prism/parse_result.rb
        - ./lib/prism/visitor.rb
        - ./lib/prism/translation/parser/lexer.rb
        - ./lib/prism/translation/ripper.rb
        - ./lib/prism/translation/ripper/filter.rb
        - ./lib/prism/translation/ripper/lexer.rb
        - ./lib/prism/translation/ripper/sexp.rb
        - ./lib/prism/translation/ruby_parser.rb
        - ./lib/prism/inspect_visitor.rb
        - ./lib/prism/serialize.rb
        - ./sample/prism/multiplex_constants.rb
        # We want to treat all polyfill files as "typed: false"
      <% polyfills.each do |file| -%>
        - ./<%= file %>
      <% end -%>
        # We want to treat all RBI files as "typed: false"
      <% gem_rbis.each do |file| -%>
        - ./<%= file %>
      <% end -%>
    YAML

    File.write("sorbet/config", <<~CONFIG)
      --dir=.
      --ignore=tmp/
      --ignore=vendor/
      --ignore=ext/
      --ignore=test/
      --ignore=rakelib/
      --ignore=Rakefile
      --ignore=top-100-gems/
      #{Dir.glob("*.rb").map { |f| "--ignore=/#{f}" }.join("\n")}
      # Treat all files as "typed: true" by default
      --typed=true
      # Use the typed-override file to revert some files to "typed: false"
      --typed-override=sorbet/typed_overrides.yml
      # We want to permit initializing a class by constant assignment
      --suppress-error-code=4022
      # We want to permit redefining the existing method as a method alias
      --suppress-error-code=5037
      # We want to permit changing the type of a variable in a loop
      --suppress-error-code=7001
    CONFIG

    with_gemfile do
      sh "bundle", "exec", "srb"
    end
  end

  desc "Generate RBS with rbs-inline"
  task rbs_inline: :templates do
    with_gemfile do
      sh "bundle", "exec", "rbs-inline", "lib", "--output", "lib"
    end
  end

  desc "Typecheck with Steep"
  task steep: :templates do
    with_gemfile do
      sh "bundle", "exec", "steep", "check"
    end
  end
end
