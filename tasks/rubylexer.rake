# frozen_string_literal: true
require "ripper"

namespace :rubylexer do
  desc "Ensure there's a local copy of rubylexer"
  file "tmp/rubylexer" do
    sh "git clone --depth=1 https://github.com/coatl/rubylexer.git tmp/rubylexer"
  end

  desc "Ensure we have a fixtures directory for the rubylexer tests"
  file "test/fixtures/rubylexer" do
    mkdir_p "test/fixtures/rubylexer"
  end

  desc "Import the rubylexer tests"
  task import: ["tmp/rubylexer", "test/fixtures/rubylexer"] do
    # The license is in the README
    cp "tmp/rubylexer/COPYING", "test/fixtures/rubylexer/COPYING"

    Dir.glob("tmp/rubylexer/test/data/*.rb") { |file|
      begin
        Ripper.lex(file, raise_errors: true)
        cp file, "test/fixtures/rubylexer"
      rescue SyntaxError
        # skip invalid ruby files
      end
    }
  end

  desc "Clean up tmp files related to rubylexer"
  task :clean do
    rm_rf "tmp/rubylexer"
    rm_rf "test/fixtures/rubylexer"
  end
end
