# frozen_string_literal: true

desc "Generate compilation database"
task bear: :templates do
  sh "which bear" do |ok, _|
    abort("Installing bear is required to generate the compilation database") unless ok
  end

  # bear records only the commands that run, so every object is compiled
  # whether or not it is up to date.
  sh "bear -- make -B"
end
