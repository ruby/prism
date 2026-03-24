package org.jruby.parser.prism;

import org.junit.jupiter.api.Test;
import org.ruby_lang.prism.ParseResult;
import org.ruby_lang.prism.ParsingOptions;
import org.ruby_lang.prism.wasm.Prism;

import java.nio.charset.StandardCharsets;
import java.util.EnumSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class WASMTest {

    private static final byte[] packedOptions = ParsingOptions.serialize(
        new byte[] {},
        1,
        new byte[] {},
        false,
        EnumSet.noneOf(ParsingOptions.CommandLine.class),
        ParsingOptions.SyntaxVersion.LATEST,
        false,
        false,
        false,
        new byte[][][] {}
    );

    @Test
    public void test1() {
        // The Ruby source code to be processed
        var source = "1 + 1";

        ParseResult pr = null;
        try (Prism prism = new Prism()) {
            pr = prism.serializeParse(packedOptions, source);
        }

        assertEquals(1, pr.value.childNodes().length);
        System.out.println("Nodes:");
        System.out.println(pr.value.childNodes()[0]);
        assertTrue(pr.value.childNodes()[0].toString().contains("IntegerNode"));
    }

    @Test
    public void test2() {
        // The Ruby source code to be processed
        var source = "puts \"h\ne\nl\nl\no\n\"";

        ParseResult pr = null;
        try (Prism prism = new Prism()) {
            pr = prism.serializeParse(packedOptions, source);
        }

        assertEquals(1, pr.value.childNodes().length);
        System.out.println("Nodes:");
        System.out.println(pr.value.childNodes()[0]);
        assertTrue(pr.value.childNodes()[0].toString().contains("CallNode"));
    }

    @Test
    public void testMBCIdentifier() {
        // The Ruby source code to be processed
        var source = new String("hellø = \"hello\"".getBytes(StandardCharsets.UTF_8), StandardCharsets.ISO_8859_1);

        ParseResult pr = null;
        try (Prism prism = new Prism()) {
            pr = prism.serializeParse(packedOptions, source);
        }

        System.out.println("Nodes:");
        System.out.println(pr);
        System.out.println(pr.value.childNodes()[0]);
        assertTrue(pr.value.childNodes()[0].toString().contains("hell\\xc3\\xb8"));
    }

    @Test
    public void testVersion() {
        try (Prism prism = new Prism()) {
            assertEquals("1.9.0", prism.version());
        }
    }
}
