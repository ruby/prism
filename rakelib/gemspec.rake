namespace :gemspec do
  # this task is used by .github/scripts/gem-build to test packaging and installing a gem
  desc "Set the gem VERSION to a unique timestamp for testing"
  task "fake-version" do
    version_re = /spec\.version = "(.*)"/

    gemspec_path = File.join(__dir__, "..", "prism.gemspec")
    gemspec_contents = File.read(gemspec_path)

    current_version_string = version_re.match(gemspec_contents)[1]
    current_version = Gem::Version.new(current_version_string)

    fake_version = Gem::Version.new(format("%s.test.%s", current_version.bump, Time.now.strftime("%Y.%m%d.%H%M")))

    unless gemspec_contents.gsub!(version_re, "spec.version = \"#{fake_version}\"")
      raise("Could not hack the VERSION constant")
    end

    File.write(gemspec_path, gemspec_contents)
    puts "NOTE: wrote version as \"#{fake_version}\""
  end
end
