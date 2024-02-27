package org.prism;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

// @formatter:off
public abstract class ParsingOptions {
    /** The version of Ruby syntax that we should be parsing with.
     * See pm_options_version_t in c/yarp/include/prism/options.h */
    public enum SyntaxVersion {
        LATEST(0),
        V3_3_0(1);

        private final int value;

        SyntaxVersion(int value) {
            this.value = value;
        }

        public byte getValue() {
            return (byte) value;
        }
    }

    /** Serialize parsing options into byte array.
     *
     * @param filepath the name of the file that is currently being parsed
     * @param line the line within the file that the parser starts on. This value is 1-indexed
     * @param encoding the name of the encoding that the source file is in
     * @param frozenStringLiteral whether the frozen string literal option has been set
     * @param commandLineP whether the -p command line option has been set
     * @param commandLineN whether the -n command line option has been set
     * @param commandLineL whether the -l command line option has been set
     * @param commandLineA whether the -a command line option has been set
     * @param version code of Ruby version which syntax will be used to parse
     * @param scopes scopes surrounding the code that is being parsed with local variable names defined in every scope
     *            ordered from the outermost scope to the innermost one */
    public static byte[] serialize(byte[] filepath, int line, byte[] encoding, boolean frozenStringLiteral, boolean commandLineP, boolean commandLineN, boolean commandLineL, boolean commandLineA, SyntaxVersion version, byte[][][] scopes) {
        final ByteArrayOutputStream output = new ByteArrayOutputStream();

        // filepath
        write(output, serializeInt(filepath.length));
        write(output, filepath);

        // line
        write(output, serializeInt(line));

        // encoding
        write(output, serializeInt(encoding.length));
        write(output, encoding);

        // frozenStringLiteral
        output.write(frozenStringLiteral ? 1 : 0);

        // command line flags
        output.write(commandLineP ? 1 : 0);
        output.write(commandLineN ? 1 : 0);
        output.write(commandLineL ? 1 : 0);
        output.write(commandLineA ? 1 : 0);

        // version
        output.write(version.getValue());

        // scopes

        // number of scopes
        write(output, serializeInt(scopes.length));
        // local variables in each scope
        for (byte[][] scope : scopes) {
            // number of locals
            write(output, serializeInt(scope.length));

            // locals
            for (byte[] local : scope) {
                write(output, serializeInt(local.length));
                write(output, local);
            }
        }

        return output.toByteArray();
    }

    private static void write(ByteArrayOutputStream output, byte[] bytes) {
        // Note: we cannot use output.writeBytes(local) because that's Java 11
        output.write(bytes, 0, bytes.length);
    }

    private static byte[] serializeInt(int n) {
        ByteBuffer buffer = ByteBuffer.allocate(4).order(ByteOrder.nativeOrder());
        buffer.putInt(n);
        return buffer.array();
    }
}
// @formatter:on
