package org.jruby.parser.prism;

import org.junit.jupiter.api.Test;
import org.ruby_lang.prism.ParsingOptions;
import org.ruby_lang.prism.wasm.Prism;

import java.io.DataInputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.EnumSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class JRubyTest {
    // TODO: This list is hardcoded from JRuby 10.0.4.0 and should be made dynamic
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
        "jruby/kernel/string.rb",
        "jruby/preludes.rb",
        "jruby/kernel/prelude.rb",
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
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/defaults/operating_system.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/defaults/jruby.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/util.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/dependency.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/core_ext/kernel_gem.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/core_ext/kernel_warn.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/monitor.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/bundled_gems.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/rubygems/path_support.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/version.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/core_ext/name_error.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/levenshtein.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/jaro_winkler.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checkers/name_error_checkers.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checkers/name_error_checkers/class_name_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checkers/name_error_checkers/variable_name_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checkers/method_name_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checkers/key_error_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checkers/null_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checkers/require_path_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/tree_spell_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/spell_checkers/pattern_key_name_checker.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/did_you_mean/formatter.rb",
        "META-INF/jruby.home/lib/ruby/stdlib/syntax_suggest/core_ext.rb",
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

            try (InputStream fileIn = JRubyTest.class.getClassLoader().getResourceAsStream(file)) {
                assertNotNull(fileIn, "Could not find file: " + file);
                DataInputStream dis = new DataInputStream(fileIn);
                int read = dis.read(src);
                prism.parse(src, 0, read, options);
            }
        }
    }
}
