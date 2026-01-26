package org.prism;

import org.junit.jupiter.api.Test;

import java.util.EnumSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class DummyTest {

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
        try (Prism prism = new PrismWASM()) {
            pr = prism.serializeParse(packedOptions, source);
        }

        assertEquals(1, pr.value.childNodes().length);
        System.out.println("Nodes:");
        System.out.println(pr.value.childNodes()[0]);
        assertTrue(pr.value.childNodes()[0].toString().contains("IntegerNode"));
    }

    @Test
    public void test1Aot() {
        // The Ruby source code to be processed
        var source = "1 + 1";

        ParseResult pr = null;
        try (Prism prism = new PrismAOT()) {
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
        try (Prism prism = new PrismWASM()) {
            pr = prism.serializeParse(packedOptions, source);
        }

        assertEquals(1, pr.value.childNodes().length);
        System.out.println("Nodes:");
        System.out.println(pr.value.childNodes()[0]);
        assertTrue(pr.value.childNodes()[0].toString().contains("CallNode"));
    }

    @Test
    public void test2Aot() {
        // The Ruby source code to be processed
        var source = "puts \"h\ne\nl\nl\no\n\"";

        ParseResult pr = null;
        try (Prism prism = new PrismAOT()) {
            pr = prism.serializeParse(packedOptions, source);
        }

        assertEquals(1, pr.value.childNodes().length);
        System.out.println("Nodes:");
        System.out.println(pr.value.childNodes()[0]);
        assertTrue(pr.value.childNodes()[0].toString().contains("CallNode"));
    }
}
