# frozen_string_literal: true

module YARP
  class LexTask
    attr_reader :todos, :passing, :failing

    def initialize(todos)
      @todos = todos
      @passing = 0
      @failing = 0
    end

    def compare(filepath)
      if lex(filepath)
        todos.delete(filepath) if todos.include?(filepath)
        @passing += 1
        true
      else
        @failing += 1 if ENV["TODOS"] || !todos.include?(filepath)
        false
      end
    end

    def failed?
      failing > 0
    end

    def summary
      <<~RESULTS
        PASSING=#{passing}
        FAILING=#{failing + todos.length}
        PERCENT=#{(passing.to_f / (passing + failing + todos.length) * 100).round(2)}%
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

    if lex_task.todos.length != target.fetch("todos", []).length
      puts("Some files listed as todo are passing. This is the new list:")
      puts("    - #{lex_task.todos.join("\n    - ")}")
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
