# frozen_string_literal: true

require "rdoc/task"

if RDoc::VERSION <= "6.5.0"
  # RDoc 6.5.0 and earlier did not create an rdoc:coverage task. This patches it
  # in in the same way newer versions do.
  RDoc::Task.prepend(
    Module.new {
      def define
        super.tap do
          namespace rdoc_task_name do
            desc "Print RDoc coverage report"
            task :coverage do
              @before_running_rdoc.call if @before_running_rdoc
              opts = option_list << "-C"
              args = opts + @rdoc_files

              $stderr.puts "rdoc #{args.join(" ")}" if Rake.application.options.trace
              RDoc::RDoc.new.document(args)
            end
          end
        end
      end
    }
  )
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.markup = "markdown"

  rdoc.rdoc_dir = "doc/rb"
  rdoc.options << "--all"

  rdoc.rdoc_files.include(
    "docs/*.md",
    "ext/**/*.c",
    "lib/**/*.rb",
    "src/**/*.c",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "LICENSE.md",
    "README.md",
  )
end
