# frozen_string_literal: true

namespace :typecheck do
  desc "Typecheck with Steep"
  task steep: :compile do
    require 'steep'
    require 'steep/cli'

    begin
      exit Steep::CLI.new(argv: %w[check], stdout: STDOUT, stderr: STDERR, stdin: STDIN).run
    rescue => exn
      STDERR.puts exn.inspect
      exn.backtrace.each do |t|
        STDERR.puts "  #{t}"
      end
      exit 2
    end
  end
end
