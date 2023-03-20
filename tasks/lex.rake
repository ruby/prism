# frozen_string_literal: true

module YARP
  class LexTask
    attr_reader :previous_todos, :todos, :passing, :failing

    def initialize(previous_todos)
      @previous_todos = previous_todos
      @passing = 0
      @failing = 0
      @todos = []
    end

    def compare(filepath)
      if lex(filepath)
        @passing += 1
        true
      else
        @todos << filepath
        false
      end
    end

    def failing
      @todos.length if ENV["TODOS"]
    end

    def failed?
      failing > 0
    end

    def summary
      <<~RESULTS
        PASSING=#{passing}
        FAILING=#{failing}
        PERCENT=#{(passing.to_f / (passing + failing) * 100).round(2)}%
      RESULTS
    end

    private

    # For the given filepath, read it and lex it with both lex_compat and
    # lex_ripper. Compare the output of both and ensure they match.
    def lex(filepath)
      source = File.read(filepath)
      lexed = YARP.lex_compat(source)
      lexed.errors.empty? && YARP.lex_ripper(source) == lexed.value
    rescue
      false
    end
  end
end

# For each of the targets in targets.yml, we're going to define a task that will
# clone the repo into tmp/targets/TARGET at the specified SHA.
require "yaml"
YAML.safe_load_file("targets.yml").each do |name, target|
  repo = target.fetch("repo")
  dirpath = File.join("tmp", "targets", name)

  desc "Clone #{repo} into #{dirpath}"
  file dirpath do
    mkdir_p dirpath
    chdir dirpath do
      sh "git init"
      sh "git remote add origin #{repo}"
      sh "git fetch --depth=1 origin #{target.fetch("sha")}"
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

    lex_task = YARP::LexTask.new(target.fetch("todos", []).map { |todo| File.join(dirpath, todo) })
    filepaths = Dir[File.join(dirpath, "**", "*.rb")]

    if excludes = target["excludes"]
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

      puts("This is the new list which can be copied into targets.yml:")
      puts("    - #{current_todos.join("\n    - ")}")
    else
      puts("The todos list in targets.yml is up to date")
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
  passing = 0
  failing = 0

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
                    failing += 1
                    print("\033[31mE\033[0m")
                  else
                    passing += 1
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
    PASSING=#{passing}
    FAILING=#{failing}
    PERCENT=#{(passing.to_f / (passing + failing) * 100).round(2)}%
  RESULTS
end
