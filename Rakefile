# frozen_string_literal: true

require "rake/extensiontask"
require "rake/testtask"
require "rake/clean"
require "ruby_memcheck"

RubyMemcheck.config(binary_name: "yarp")

task compile: :make

Rake::ExtensionTask.new(:compile) do |ext|
  ext.name = "yarp"
  ext.ext_dir = "ext/yarp"
  ext.lib_dir = "lib/yarp"
  ext.gem_spec = Gem::Specification.load("yarp.gemspec")
end

test_config = lambda do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

Rake::TestTask.new(test: :compile, &test_config)

namespace :test do
  RubyMemcheck::TestTask.new(valgrind: :compile, &test_config)
end

task default: :test

TEMPLATES = [
  "ext/yarp/node.c",
  "lib/yarp/node.rb",
  "lib/yarp/serialize.rb",
  "java/org/yarp/Loader.java",
  "java/org/yarp/Nodes.java",
  "java/org/yarp/AbstractNodeVisitor.java",
  "src/ast.h",
  "src/node.c",
  "src/node.h",
  "src/prettyprint.c",
  "src/serialize.c",
  "src/token_type.c",
]

desc "Generate all ERB template based files"
task templates: TEMPLATES

task make: :templates do
  sh "make"
end

task generate_compilation_database: [:clobber, :templates] do
  sh "which bear" do |ok, _|
    abort("Installing bear is required to generate the compilation database") unless ok
  end

  sh "bear -- make"
end

# So `rake clobber` will delete generated files
CLOBBER.concat(TEMPLATES)

dylib_extension = RbConfig::CONFIG["host_os"].match?(/darwin/) ? "dylib" : "so"
CLOBBER << "build/librubyparser.#{dylib_extension}"
CLOBBER << "lib/yarp.#{dylib_extension}"

TEMPLATES.each do |filepath|
  desc "Template #{filepath}"
  file filepath => ["bin/templates/#{filepath}.erb", "config.yml"] do |t|
    require_relative "bin/template"
    template(t.name, locals)
  end
end

desc "Lex ruby/spec files and compare with lex_compat"
task lex: :compile do
  $:.unshift(File.expand_path("lib", __dir__))
  require "yarp"
  require "ripper"
  require "timeout"
  require "yaml"

  passing = 0
  failing = 0
  todo = 0

  if ENV["FILEPATHS"]
    filepaths = Dir[ENV["FILEPATHS"]]
    todos = []
  else
    target = YAML.safe_load_file("targets.yml").fetch(ENV["TARGET"])
    dirpath = File.join("tmp", "targets", ENV["TARGET"])

    unless File.directory?(dirpath)
      FileUtils.mkdir_p(dirpath)
      Dir.chdir(dirpath) do
        sh "git init"
        sh "git remote add origin #{target.fetch("repo")}"
        sh "git fetch --depth=1 origin #{target.fetch("sha")}"
        sh "git reset --hard FETCH_HEAD"
      end
    end

    filepaths = Dir[File.join(dirpath, "**", "*.rb")]

    if excludes = target["excludes"]
      filepaths -= excludes.map { |exclude| File.join(dirpath, exclude) }
    end

    todos = target.fetch("todos", []).map { |todo| File.join(dirpath, todo) }
    todo = todos.length
  end

  filepaths.each.with_index(1) do |filepath, index|
    print("#{filepath} ") if ENV["CI"]

    source = File.read(filepath)
    passed =
      begin
        Timeout.timeout(5) do
          lexed = YARP.lex_compat(source)
          lexed.errors.empty? && YARP.lex_ripper(source) == lexed.value
        rescue
          false
        end
      rescue Timeout::Error
        false
      end

    if passed
      print(ENV["CI"] ? "." : "\033[32m.\033[0m")
      passing += 1
    else
      todos.delete(filepath) if todos.include?(filepath)
      next if !ENV["TODOS"]

      warn(filepath) if ENV["VERBOSE"]
      print(ENV["CI"] ? "E" : "\033[31mE\033[0m")
      failing += 1
    end

    puts if ENV["CI"]
  end

  puts("\n\n")
  warn("Some files listed as todo are passing:\n  #{todos.join("\n  ")}") if todos.any?
  puts(<<~RESULTS)
    PASSING=#{passing}
    FAILING=#{failing + todo}
    PERCENT=#{(passing.to_f / (passing + failing + todo) * 100).round(2)}%
  RESULTS

  exit(1) if failing > 0
end

desc "Lint config.yml"
task :lint do
  require "yaml"
  config = YAML.safe_load_file("config.yml")

  tokens = config.fetch("tokens")[4..].map { |token| token.fetch("name") }
  if tokens.sort != tokens
    warn("Tokens are not sorted alphabetically")

    tokens.sort.zip(tokens).each do |(sorted, unsorted)|
      warn("Expected #{sorted} got #{unsorted}") if sorted != unsorted
    end

    exit(1)
  end

  nodes = config.fetch("nodes").map { |node| node.fetch("name") }
  if nodes.sort != nodes
    warn("Nodes are not sorted alphabetically")

    nodes.sort.zip(nodes).each do |(sorted, unsorted)|
      warn("Expected #{sorted} got #{unsorted}") if sorted != unsorted
    end

    exit(1)
  end
end
