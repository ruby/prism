# frozen_string_literal: true

desc "Check that RBS and RBI generated files are valid"
task check_annotations: :compile do
  require "prism"
  require "rbs"
  require "rbs/cli"

  # Run `rbs` against the generated file, which checks for valid syntax and any missing constants
  puts "Checking RBS annotations"
  cli = RBS::CLI.new(stdout: STDOUT, stderr: STDERR)
  cli.run(["-I", "sig", "validate"])

  # For RBI files, we just use Prism itself to check for valid syntax since they use Ruby compliant syntax
  puts "Checking RBI annotations"
  result = Prism.parse_file("rbi/prism.rbi")
  abort(result.errors.map(&:inspect).join("\n")) unless result.success?

  result = Prism.parse_file("rbi/prism_static.rbi")
  abort(result.errors.map(&:inspect).join("\n")) unless result.success?
end
