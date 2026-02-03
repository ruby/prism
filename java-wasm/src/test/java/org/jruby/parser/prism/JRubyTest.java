package org.jruby.parser.prism;

import org.jruby.Ruby;
import org.jruby.parser.prism.wasm.Prism;
import org.junit.jupiter.api.Test;
import org.prism.ParsingOptions;

import java.io.DataInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.EnumSet;

import static org.junit.jupiter.api.Assertions.assertEquals;

public class JRubyTest {
    final static String[] JRUBY_BOOT_FILES = {
        "jruby/java.rb",
        "jruby/java/core_ext.rb",
        "jruby/java/core_ext/object.rb",
        "jruby/java/java_ext.rb",
        "jruby/kernel.rb",
        "jruby/kernel/signal.rb",
        "jruby/kernel/kernel.rb",
        "jruby/kernel/proc.rb",
        "jruby/kernel/process.rb",
        "jruby/kernel/enumerator.rb",
        "jruby/kernel/enumerable.rb",
        "jruby/kernel/io.rb",
        "jruby/kernel/gc.rb",
        "jruby/kernel/range.rb",
        "jruby/kernel/file.rb",
        "jruby/kernel/method.rb",
        "jruby/kernel/thread.rb",
        "jruby/kernel/integer.rb",
        "jruby/kernel/time.rb",
        "jruby/preludes.rb",
        "jruby/kernel/prelude.rb",
        "jruby/kernel/enc_prelude.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/unicode_normalize.rb",
        "jruby/kernel/gem_prelude.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rbconfig.rb",
        "jruby/kernel/rbconfig.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/compatibility.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/defaults.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/deprecate.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/errors.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/target_rbconfig.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/exceptions.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/unknown_command_spell_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/specification.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/basic_specification.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/stub_specification.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/platform.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/specification_record.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/util/list.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/requirement.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/version.rb",
    };

    private class TestingPrism extends Prism {
        TestingPrism() {
            super();
        }

        public int memPages() {
            return exports.memory().pages();
        }
    }

    @Test
    public void jrubyReproducer() throws Exception {
        var prism = new TestingPrism();

        for (int i = 0; i < 3; i++) {
            basicJRubyTest(prism);
        }
        var memoryPagesBefore = prism.memPages();
        for (int i = 0; i < 100; i++) {
            var before = System.currentTimeMillis();

            basicJRubyTest(prism);

            var after = System.currentTimeMillis();
            System.out.println("Elapsed: " + (after - before));
        }
        var memoryPagesAfter = prism.memPages();
        assertEquals(memoryPagesBefore, memoryPagesAfter);
    }

    private static void basicJRubyTest(Prism prism) throws Exception {
        byte[] src = new byte[1024 * 1024];

        for (var file : JRUBY_BOOT_FILES) {
            byte[] options = ParsingOptions.serialize(
                file.getBytes(StandardCharsets.UTF_8),
                1,
                "UTF-8".getBytes(StandardCharsets.UTF_8),
                false,
                EnumSet.noneOf(ParsingOptions.CommandLine.class),
                ParsingOptions.SyntaxVersion.LATEST,
                false,
                false,
                false,
                new byte[][][]{}
            );

            try (InputStream fileIn = Ruby.getClassLoader().getResourceAsStream(file)) {
                DataInputStream dis = new DataInputStream(fileIn);
                int read = dis.read(src);
                prism.serialize(options, src, read);
            }
        }
    }
}
