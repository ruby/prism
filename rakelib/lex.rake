# frozen_string_literal: true

module YARP
  class LexTask
    attr_reader :previous_todos, :todos, :passing_file_count

    def initialize(previous_todos)
      @previous_todos = previous_todos
      @passing_file_count = 0
      @todos = []
    end

    def compare(filepath)
      if lex(filepath)
        @passing_file_count += 1
        true
      else
        @todos << filepath
        false
      end
    end

    def failing_file_count
      @todos.length
    end

    # ENV["TODOS"] was toggled and there are failing files
    # or new failures were introduced
    def failed?
      (ENV["TODOS"] && failing_file_count > 0) ||
        (@todos - @previous_todos).any?
    end

    def summary
      <<~RESULTS
        PASSING=#{passing_file_count}
        FAILING=#{failing_file_count}
        PERCENT=#{(passing_file_count.to_f / (passing_file_count + failing_file_count) * 100).round(2)}%
      RESULTS
    end

    private

    # For the given filepath, read it and lex it with both lex_compat and
    # lex_ripper. Compare the output of both and ensure they match.
    def lex(filepath)
      source = File.read(filepath)
      lexed = YARP.lex_compat(source)
      begin
        lexed_ripper = YARP.lex_ripper(source)
      rescue SyntaxError
        return true # If the file is invalid, we say the output is equivalent for comparison purposes
      end
      lexed.errors.empty? && lexed_ripper == lexed.value
    rescue
      false
    end
  end
end

TARGETS = {
  ruby: {
    repo: "https://github.com/ruby/ruby",
    sha: "52837fcec2340048f9bdc2169cde17243c5e9d6d",
    excludes: ["spec/ruby/command_line/fixtures/bad_syntax.rb"]
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
  dirpath = File.join("tmp", "targets", name.name)

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
    require "yarp"

    plain_text = ENV.fetch("CI", false)
    warn_failing = ENV.fetch("VERBOSE", false)

    lex_task = YARP::LexTask.new(target.fetch(:todos, []).map { |todo| File.join(dirpath, todo) })
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

    previous_todos = lex_task.previous_todos.map { _1.gsub(/tmp\/targets\/[a-zA-Z0-9_]*\//, "") }
    current_todos = lex_task.todos.map { _1.gsub(/tmp\/targets\/[a-zA-Z0-9_]*\//, "") }
    current_minus_previous = current_todos - previous_todos
    previous_minus_current = previous_todos - current_todos

    if current_minus_previous.any?
      puts("Uh oh, there are some files which were previously passing but are now failing. Here are the files:")
      puts("    - #{current_minus_previous.join("\n    - ")}")
    elsif (previous_minus_current).any?
      puts("Some files listed as todo are now passing:")
      puts("    - #{previous_minus_current.join("\n    - ")}")

      puts("This is the new list which can be copied into lex.rake:")
      puts("    - #{current_todos.join("\n    - ")}")
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
  require "yarp"

  plain_text = ENV.fetch("CI", false)
  warn_failing = ENV.fetch("VERBOSE", false)

  lex_task = YARP::LexTask.new([])
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

desc "Lex against the most recent version of various rubygems"
task "lex:rubygems": :compile do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "net/http"
  require "ripper"
  require "rubygems/package"
  require "tmpdir"
  require "yarp"

  queue = Queue.new
  Gem::SpecFetcher.new.available_specs(:latest).first.each do |source, gems|
    gems.each do |tuple|
      gem_name = File.basename(tuple.spec_name, ".gemspec")
      gem_url = source.uri.merge("/gems/#{gem_name}.gem")
      queue << [gem_name, gem_url]
    end
  end

  warn_failing = ENV.fetch("VERBOSE", false)
  passing_gem_count = 0
  failing_gem_count = 0

  workers =
    ENV.fetch("WORKERS", 16).times.map do
      Thread.new do
        Net::HTTP.start("rubygems.org", 443, use_ssl: true) do |http|
          until queue.empty?
            (gem_name, gem_url) = queue.shift

            http.request(Net::HTTP::Get.new(gem_url)) do |response|
              # Skip unexpected responses
              next unless response.is_a?(Net::HTTPSuccess)

              Dir.mktmpdir do |directory|
                filepath = File.join(directory, "#{gem_name}.gem")
                File.write(filepath, response.body)

                begin
                  Gem::Package.new(filepath).extract_files(directory, "[!~]*")

                  lex_task = YARP::LexTask.new([])
                  Dir[File.join(directory, "**", "*.rb")].each do |filepath|
                    lex_task.compare(filepath)
                  end

                  if lex_task.failed?
                    failing_gem_count += 1
                    print("\033[31mE\033[0m")
                  else
                    passing_gem_count += 1
                    warn(gem_name) if warn_failing
                    print("\033[32m.\033[0m")
                  end
                rescue
                  # If the gem fails to extract, we'll just skip it
                end
              end
            end
          end
        end
      end
    end

  workers.each(&:join)
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

desc "Download the top 100 rubygems under #{TOP_100_GEMS_DIR}/"
task "download:topgems" do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "net/http"
  require "rubygems/package"
  require "tmpdir"

  queue = Queue.new
  YAML.safe_load_file(TOP_100_GEM_FILENAME).each do |gem_name|
    gem_url = "https://rubygems.org/gems/#{gem_name}.gem"
    queue << [gem_name, gem_url]
  end

  Dir.mkdir TOP_100_GEMS_DIR unless File.directory? TOP_100_GEMS_DIR

  workers =
    ENV.fetch("WORKERS", 16).times.map do
      Thread.new do
        Net::HTTP.start("rubygems.org", 443, use_ssl: true) do |http|
          until queue.empty?
            (gem_name, gem_url) = queue.shift
            directory = File.expand_path("#{TOP_100_GEMS_DIR}/#{gem_name}")
            unless File.directory? directory
              puts "Downloading #{gem_name}"

              http.request(Net::HTTP::Get.new(gem_url)) do |response|
                # Skip unexpected responses
                raise gem_url unless response.is_a?(Net::HTTPSuccess)

                Dir.mktmpdir do |tmpdir|
                  filepath = File.join(tmpdir, "#{gem_name}.gem")
                  File.write(filepath, response.body)

                  Gem::Package.new(filepath).extract_files(directory, "**/*.rb")
                end
              end
            end
          end
        end
      end
    end

  workers.each(&:join)
end

# This task parses each .rb file of the top 100 gems with YARP and ensures they parse
# successfully (unless they are invalid syntax as confirmed by "ruby -c").
# It also does some sanity check for every location recorded in the AST.
desc "Parse the top 100 rubygems"
task "parse:topgems": ["download:topgems", :compile] do
  require "yarp"
  require_relative "../test/yarp/test_helper"

  module YARP
    class ParseTop100GemsTest < TestCase
      Dir["#{TOP_100_GEMS_DIR}/**/*.rb"].each do |filepath|
        test filepath do
          result = YARP.parse_file(filepath)

          if TOP_100_GEMS_INVALID_SYNTAX_PREFIXES.any? { |prefix| filepath.start_with?(prefix) }
            assert_false result.success?
            # ensure it is actually invalid syntax
            assert_false system(RbConfig.ruby, "-c", filepath, out: File::NULL, err: File::NULL)
            next
          end

          assert result.success?, "failed to parse #{filepath}"
          value = result.value
          assert_valid_locations(value)
        end
      end
    end
  end
end

# This task lexes against the top 100 gems, and will exit(1)
# if the existing failures in rakelib/top-100-gems.yml are no
# longer correct.
desc "Lex against the top 100 rubygems"
task "lex:topgems": ["download:topgems", :compile] do
  $:.unshift(File.expand_path("../lib", __dir__))
  require "net/http"
  require "ripper"
  require "rubygems/package"
  require "tmpdir"
  require "yarp"

  previous_todos_by_gem_name = {}

  YAML.safe_load_file(TOP_100_GEM_FILENAME).each do |gem_info|
    if gem_info.class == Hash
      previous_todos_by_gem_name.merge!(gem_info)
    else
      previous_todos_by_gem_name[gem_info] = []
    end
  end

  warn_failing = ENV.fetch("VERBOSE", false)

  # An array of hashes with gem_name => [new_failing_files] for any new
  # failures that we didn't previously have. If there is anything in
  # this list, the task will report it and exit(1)
  new_failing_files_by_gem = []

  # An array of hashes with gem_name => [all_failing_files] for all failures
  # (including pre-existing ones). If there are fewer failures than before,
  # this list will be used to generate the new yml file before exit(1)
  updated_todos_by_gem_name = {}

  previous_todos_by_gem_name.keys.each do |gem_name|
    puts "Lexing #{gem_name}"
    directory = "#{TOP_100_GEMS_DIR}/#{gem_name}"

    todos = previous_todos_by_gem_name[gem_name].map do |todo_filepath|
      File.join(directory, todo_filepath)
    end
    lex_task = YARP::LexTask.new(todos)
    Dir[File.join(directory, "**", "*.rb")].each do |filepath|
      lex_task.compare(filepath)
    end

    todos = lex_task.todos.map { _1.gsub("#{directory}/", "") }

    updated_todos_by_gem_name.merge!({ gem_name => todos })

    if lex_task.failed?
      new_failing_files_by_gem << { gem_name => todos }
    end
  end

  failing_gem_count, passing_gem_count = updated_todos_by_gem_name.partition { |_, todos| todos.any? }.map(&:size)

  puts(<<~RESULTS)
    PASSING=#{passing_gem_count}
    FAILING=#{failing_gem_count}
    PERCENT=#{(passing_gem_count.to_f / (passing_gem_count + failing_gem_count) * 100).round(2)}%
  RESULTS

  if new_failing_files_by_gem.any?
    puts "Oh no! There were new failures:"
    puts new_failing_files_by_gem.to_yaml
    exit(1)
  elsif (updated_todos_by_gem_name != previous_todos_by_gem_name)
    puts "There are files that were previously failing but are no longer failing:"
    puts "Please update #{TOP_100_GEM_FILENAME} with the following"
    puts (updated_todos_by_gem_name.sort_by(&:first).map do |k, v|
      v.any? ? { k => v } : k
    end).to_yaml
    exit(1)
  end
end
