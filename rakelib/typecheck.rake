# frozen_string_literal: true

namespace :typecheck do
  task tapioca: :templates do
    # Yard crashes parsing steep, which is all run because of tapioca. So to
    # avoid this, we're going to monkey patch yard to ignore these kinds of
    # crashes so tapioca can keep running.
    require "yard"
    YARD.singleton_class.prepend(
      Module.new do
        def parse(*args, **kwargs)
          super
        rescue RangeError
          []
        end
      end
    )

    require "tapioca/internal"
    Tapioca::Cli.start(["configure"])
    Tapioca::Cli.start(["gems", "--exclude", "prism"])
    Tapioca::Cli.start(["todo"])
  end

  desc "Typecheck with Sorbet"
  task sorbet: :templates do
    Process.wait(fork { exec Gem.bin_path("sorbet", "srb"), "typecheck" })
  end

  desc "Typecheck with Steep"
  task steep: :templates do
    Process.wait(fork { exec Gem.bin_path("steep", "steep"), "check" })
  end
end
