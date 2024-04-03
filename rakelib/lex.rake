# frozen_string_literal: true
# typed: ignore

module Prism
  # This class is responsible for lexing files with both lex_compat and
  # lex_ripper and ensuring they match up. It keeps track of the files which
  # failed to match up, and the files which passed.
  class LexTask
    attr_reader :failing_files, :passing_file_count

    def initialize
      @passing_file_count = 0
      @failing_files = []
    end

    def compare(filepath)
      # If we can't read the file, then ignore it.
      return true if !File.file?(filepath) || !File.readable?(filepath)

      # Read the file into memory.
      source = File.read(filepath)

      # If the filepath contains invalid Ruby code, then ignore it.
      begin
        RubyVM::AbstractSyntaxTree.parse(source)
      rescue ArgumentError, SyntaxError
        return true
      end

      result = Prism.lex_compat(source)
      if result.errors.empty? && Prism.lex_ripper(source) == result.value
        @passing_file_count += 1
        true
      else
        @failing_files << filepath
        false
      end
    end

    def failing_file_count
      failing_files.length
    end

    def failed?
      failing_files.any?
    end

    def summary
      <<~RESULTS
        PASSING=#{passing_file_count}
        FAILING=#{failing_file_count}
        PERCENT=#{(passing_file_count.to_f / (passing_file_count + failing_file_count) * 100).round(2)}%
      RESULTS
    end
  end

  class << self
    # This method is responsible for iterating through a list of items and running
    # each item in a separate thread. It will block until all items have been
    # processed. This is particularly useful for tasks that are IO-bound like
    # downloading files or reading files from disk.
    def parallelize(items, &block)
      Thread.abort_on_exception = true

      queue = Queue.new
      items.each { |item| queue << item }

      workers =
        ENV.fetch("WORKERS") { 16 }.to_i.times.map do
          parallelize_thread(queue, &block)
        end

      workers.map(&:join)
    end

    private

    # Create a new thread with a minimal number of locals that it can access.
    def parallelize_thread(queue, &block)
      Thread.new { block.call(queue.shift) until queue.empty? }
    end
  end
end

TARGETS = {
  ruby: {
    repo: "https://github.com/ruby/ruby",
    sha: "52837fcec2340048f9bdc2169cde17243c5e9d6d",
    excludes: [
      # Contains an invalid break
      "sample/trick2018/01-kinaba/entry.rb",

      # Contains invalid syntax
      "spec/ruby/command_line/fixtures/bad_syntax.rb",

      # Requires an implicit -x, which ripper does not respect
      "tool/merger.rb",
    ]
  },
  discourse: {
    repo: "https://github.com/discourse/discourse",
    sha: "a5542eeab07ec43deb3bcd391e2e56ad30ebd676"
  }
}

# For each of the targets, we're going to define a task that will clone the repo
# into tmp/targets/TARGET at the specified SHA.
TARGETS.each do |name, target|
  repo = target.fetch(:repo)
  dirpath = File.join("tmp", "targets", name.to_s)

  desc "Clone #{repo} into #{dirpath}"
  file dirpath do
    mkdir_p dirpath
    chdir dirpath do
      sh "git init"
      sh "git remote add origin #{repo}"
      sh "git fetch --depth=1 origin #{target.fetch(:sha)}"
      sh "git reset --hard FETCH_HEAD"
    end
  end

  desc "Lex #{repo} and compare with lex_compat"
  task "lex:#{name}" => [dirpath, :compile] do
    $:.unshift(File.expand_path("../lib", __dir__))
    require "ripper"
    require "prism"

    plain_text = ENV.fetch("CI", false)
    warn_failing = ENV.fetch("VERBOSE", false)

    lex_task = Prism::LexTask.new
    filepaths = Dir[File.join(dirpath, "**", "*.rb")]

    if excludes = target[:excludes]
      filepaths -= excludes.map { |exclude| File.join(dirpath, exclude) }
    end

    filepaths.each do |filepath|
      print("#{filepath} ") if plain_text

      if lex_task.compare(filepath)
        print(plain_text ? "." : "\033[32m.\033[0m")
      else
        warn(filepath) if warn_failing
        print(plain_text ? "E" : "\033[31mE\033[0m")
      end

      puts if plain_text
    end

    puts("\n\n")

    if lex_task.failing_files.any?
      puts("Uh oh, there are some files which were previously passing but are now failing. Here are the files:")
      puts("    - #{lex_task.failing_files.map { _1.gsub(/tmp\/targets\/[a-zA-Z0-9_]*\//, "") }.join("\n    - ")}")
    else
      puts("The todos list in lex.rake is up to date")
    end

    puts(lex_task.summary)
    exit(1) if lex_task.failed?
  end
end

desc "Lex files and compare with lex_compat"
task lex: :compile do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "ripper"
  require "prism"

  plain_text = ENV.fetch("CI", false)
  warn_failing = ENV.fetch("VERBOSE", false)

  lex_task = Prism::LexTask.new
  filepaths = Dir[ENV.fetch("FILEPATHS")]

  filepaths.each do |filepath|
    print("#{filepath} ") if plain_text

    if lex_task.compare(filepath)
      print(plain_text ? "." : "\033[32m.\033[0m")
    else
      warn(filepath) if warn_failing
      print(plain_text ? "E" : "\033[31mE\033[0m")
    end

    puts if plain_text
  end

  puts("\n\n#{lex_task.summary}")
  exit(1) if lex_task.failed?
end

directory "tmp/failing"

desc "Lex against the most recent version of various rubygems"
task "lex:rubygems": [:compile, "tmp/failing"] do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "net/http"
  require "ripper"
  require "rubygems/package"
  require "tmpdir"
  require "prism"

  items = []
  Gem::SpecFetcher.new.available_specs(:latest).first.each do |source, gems|
    gems.each do |tuple|
      gem_name = File.basename(tuple.spec_name, ".gemspec")
      gem_uri = source.uri.merge("/gems/#{gem_name}.gem")
      items << [gem_name, gem_uri]
    end
  end

  warn_failing = ENV.fetch("VERBOSE", false)
  passing_gem_count = 0
  failing_gem_count = 0

  Prism.parallelize(items) do |(gem_name, gem_uri)|
  # items.each do |(gem_name, gem_uri)|
    response = Net::HTTP.get_response(gem_uri)
    next unless response.is_a?(Net::HTTPSuccess)

    Dir.mktmpdir do |directory|
      filepath = File.join(directory, "#{gem_name}.gem")
      File.write(filepath, response.body)

      begin
        Gem::Package.new(filepath).extract_files(directory, "[!~]*")
      rescue
        # If the gem fails to extract, we'll just skip it
        next
      end

      lex_task = Prism::LexTask.new
      Dir[File.join(directory, "**", "*.rb")].each do |filepath|
        unless lex_task.compare(filepath)
          cp filepath, "tmp/failing/#{SecureRandom.hex}-#{File.basename(filepath)}"
        end
      end

      if lex_task.failed?
        failing_gem_count += 1
        print("\033[31mE\033[0m")
      else
        passing_gem_count += 1
        warn(gem_name) if warn_failing
        print("\033[32m.\033[0m")
      end
    end
  end

  puts(<<~RESULTS)
    PASSING=#{passing_gem_count}
    FAILING=#{failing_gem_count}
    PERCENT=#{(passing_gem_count.to_f / (passing_gem_count + failing_gem_count) * 100).round(2)}%
  RESULTS
end

TOP_100_GEM_FILENAME = "rakelib/top-100-gems.yml"
TOP_100_GEMS_DIR = "top-100-gems"
TOP_100_GEMS_INVALID_SYNTAX_PREFIXES = %w[
  top-100-gems/brakeman-5.4.1/bundle/ruby/3.1.0/gems/erubis-2.7.0/lib/erubis/helpers/rails_form_helper.rb
  top-100-gems/devise-4.9.2/lib/generators/active_record/templates/
  top-100-gems/devise-4.9.2/lib/generators/templates/controllers/
  top-100-gems/fastlane-2.212.1/fastlane/lib/assets/custom_action_template.rb
]

namespace :download do
  directory TOP_100_GEMS_DIR

  desc "Download the top 100 rubygems under #{TOP_100_GEMS_DIR}/"
  task topgems: TOP_100_GEMS_DIR do
    $:.unshift(File.expand_path("../lib", __dir__))
    require "net/http"
    require "rubygems/package"
    require "tmpdir"

    Prism.parallelize(YAML.safe_load_file(TOP_100_GEM_FILENAME)) do |gem_name|
      directory = File.expand_path("#{TOP_100_GEMS_DIR}/#{gem_name}")
      next if File.directory?(directory)

      puts "Downloading #{gem_name}"

      uri = URI.parse("https://rubygems.org/gems/#{gem_name}.gem")
      response = Net::HTTP.get_response(uri)
      raise gem_name unless response.is_a?(Net::HTTPSuccess)

      Dir.mktmpdir do |tmpdir|
        filepath = File.join(tmpdir, "#{gem_name}.gem")
        File.write(filepath, response.body)
        Gem::Package.new(filepath).extract_files(directory, "**/*.rb")
      end
    end
  end
end

# This task parses each .rb file of the top 100 gems with prism and ensures they
# parse successfully (unless they are invalid syntax as confirmed by "ruby -c").
desc "Parse the top 100 rubygems"
task "parse:topgems": ["download:topgems", :compile] do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "prism"

  incorrect = []
  Prism.parallelize(Dir["#{TOP_100_GEMS_DIR}/**/*.rb"]) do |filepath|
    result = Prism.parse_file(filepath)

    if TOP_100_GEMS_INVALID_SYNTAX_PREFIXES.any? { |prefix| filepath.start_with?(prefix) }
      # Check that the file failed to parse and that it actually contains
      # invalid syntax.
      incorrect << filepath if result.success? || system(RbConfig.ruby, "-c", filepath, out: File::NULL, err: File::NULL)
    else
      incorrect << filepath unless result.success?
    end
  end

  if incorrect.any?
    warn("The following files failed to parse:")
    warn("  - #{incorrect.join("\n  - ")}")
    exit(1)
  else
    puts("All files parsed successfully.")
  end
end

# This task lexes against the top 100 gems, and will exit(1) if any files fail
# to lex properly.
desc "Lex against the top 100 rubygems"
task "lex:topgems": ["download:topgems", :compile] do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "net/http"
  require "ripper"
  require "rubygems/package"
  require "tmpdir"
  require "prism"

  gem_names = YAML.safe_load_file(TOP_100_GEM_FILENAME)
  failing_files = {}

  Prism.parallelize(gem_names) do |gem_name|
    puts "Lexing #{gem_name}"
    directory = File.expand_path("#{TOP_100_GEMS_DIR}/#{gem_name}")

    lex_task = Prism::LexTask.new
    Dir[File.join(directory, "**", "*.rb")].each do |filepath|
      lex_task.compare(filepath)
    end

    gem_failing_files = lex_task.failing_files.map { |todo| todo.delete_prefix("#{directory}/") }
    failing_files[gem_name] = gem_failing_files if gem_failing_files.any?
  end

  failing = failing_files.length
  passing = gem_names.length - failing

  puts(<<~RESULTS)
    PASSING=#{passing}
    FAILING=#{failing}
    PERCENT=#{(passing.to_f / gem_names.length * 100).round(2)}%
  RESULTS

  if failing > 0
    warn("The following files failed to lex:")
    warn(failing_files.to_yaml)
    exit(1)
  end
end

task "serialized_size:topgems": ["download:topgems"] do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "prism"

  files = Dir["#{TOP_100_GEMS_DIR}/**/*.rb"]
  total_source_size = 0
  total_serialized_size = 0
  ratios = []
  files.each do |file|
    source_size = File.size(file)
    next if source_size == 0
    total_source_size += source_size

    serialized = Prism.dump_file(file)
    serialized_size = serialized.bytesize
    total_serialized_size += serialized_size

    ratios << Rational(serialized_size, source_size)
  end
  f = '%.3f'
  puts "Total sizes for top 100 gems:"
  puts "total source size:     #{'%9d' % total_source_size}"
  puts "total serialized size: #{'%9d' % total_serialized_size}"
  puts "total serialized/total source: #{f % (total_serialized_size.to_f / total_source_size)}"
  puts
  puts "Stats of ratio serialized/source per file:"
  puts "average: #{f % (ratios.sum / ratios.size)}"
  puts "median:  #{f % ratios.sort[ratios.size/2]}"
  puts "1st quartile: #{f % ratios.sort[ratios.size/4]}"
  puts "3rd quartile: #{f % ratios.sort[ratios.size*3/4]}"
  puts "min - max: #{"#{f} - #{f}" % ratios.minmax}"
end
