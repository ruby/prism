# frozen_string_literal: true

namespace :unparser do
  desc "Ensure there's a local copy of mbj/unparser"
  file "tmp/unparser" do
    sh "git clone --depth=1 https://github.com/mbj/unparser tmp/unparser"
  end

  desc "Ensure we have a fixtures directory for the unparser tests"
  file "test/fixtures/unparser" do
    mkdir_p "test/fixtures/unparser"
  end

  desc "Import the unparser tests"
  task import: ["tmp/unparser", "test/fixtures/unparser"] do
    cp_r "tmp/unparser/test/corpus/", "test/fixtures/unparser"

    # There's an issue with one of the test files in unparser. We'll correct it
    # until https://github.com/mbj/unparser/issues/340 is closed.
    filepath = "test/fixtures/unparser/corpus/literal/pattern.rb"
    File.write(filepath, File.read(filepath).gsub("\"\#{\"a\"}\"", "\"a\""))
  end

  desc "Clean up tmp files related to unparser"
  task :clean do
    rm_rf "tmp/unparser"
  end
end
