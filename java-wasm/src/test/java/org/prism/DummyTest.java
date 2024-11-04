package org.prism;

import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.wasi.WasiOptions;
import com.dylibso.chicory.wasi.WasiPreview1;
import com.dylibso.chicory.wasm.Parser;
import com.dylibso.chicory.wasm.types.Value;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.EnumSet;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class DummyTest {

    @Test
    public void test1() {
        WasiOptions wasiOpts = WasiOptions.builder().build();
        WasiPreview1 wasi = WasiPreview1.builder().withOptions(wasiOpts).build();
        var wasmPrism = Instance.builder(Parser.parse(DummyTest.class.getResourceAsStream("/prism.wasm")))
            .withImportValues(ImportValues.builder().addFunction(wasi.toHostFunctions()).build())
            .build();
        var memory = wasmPrism.memory();
        var calloc = wasmPrism.export("calloc");
        var pmSerializeParse = wasmPrism.export("pm_serialize_parse");
        var pmBufferInit = wasmPrism.export("pm_buffer_init");
        var pmBufferSizeof = wasmPrism.export("pm_buffer_sizeof");
        var pmBufferValue = wasmPrism.export("pm_buffer_value");
        var pmBufferLength = wasmPrism.export("pm_buffer_length");

        // The Ruby source code to be processed
        var source = "1 + 1";
        var sourceBytes = source.getBytes(StandardCharsets.US_ASCII);

        var sourcePointer = calloc.apply(1, source.length());
        memory.writeString((int) sourcePointer[0], source);

        var packedOptions = ParsingOptions.serialize(
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

        var optionsPointer = calloc.apply(1, packedOptions.length);
        memory.write((int) optionsPointer[0], packedOptions);

        var bufferPointer = calloc.apply(pmBufferSizeof.apply()[0], 1);
        pmBufferInit.apply(bufferPointer);

        pmSerializeParse.apply(
                bufferPointer[0], sourcePointer[0], source.length(), optionsPointer[0]);

        var result = memory.readBytes(
            (int) pmBufferValue.apply(bufferPointer[0])[0],
            (int) pmBufferLength.apply(bufferPointer[0])[0]);

        System.out.println("RESULT: " + new String(result));

        ParseResult pr = Loader.load(result, sourceBytes);

        assertEquals(1, pr.value.childNodes().length);
        System.out.println("Nodes:");
        System.out.println(pr.value.childNodes()[0]);
        assertTrue(pr.value.childNodes()[0].toString().contains("IntegerNode"));
    }

    @Test
    public void test2() {
        WasiOptions wasiOpts = WasiOptions.builder().build();
        WasiPreview1 wasi = WasiPreview1.builder().withOptions(wasiOpts).build();
        var wasmPrism = Instance.builder(Parser.parse(DummyTest.class.getResourceAsStream("/prism.wasm")))
            .withImportValues(ImportValues.builder().addFunction(wasi.toHostFunctions()).build())
            .build();
        var memory = wasmPrism.memory();
        var calloc = wasmPrism.export("calloc");
        var pmSerializeParse = wasmPrism.export("pm_serialize_parse");
        var pmBufferInit = wasmPrism.export("pm_buffer_init");
        var pmBufferSizeof = wasmPrism.export("pm_buffer_sizeof");
        var pmBufferValue = wasmPrism.export("pm_buffer_value");
        var pmBufferLength = wasmPrism.export("pm_buffer_length");

        // The Ruby source code to be processed
        var source = "puts \"h\ne\nl\nl\no\n\"";
        var sourceBytes = source.getBytes(StandardCharsets.US_ASCII);

        var sourcePointer = calloc.apply(1, source.length());
        memory.writeString((int) sourcePointer[0], source);

        var packedOptions = ParsingOptions.serialize(
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

        var optionsPointer = calloc.apply(1, packedOptions.length);
        memory.write((int) optionsPointer[0], packedOptions);

        var bufferPointer = calloc.apply(pmBufferSizeof.apply()[0], 1);
        pmBufferInit.apply(bufferPointer);

        pmSerializeParse.apply(
                bufferPointer[0], sourcePointer[0], source.length(), optionsPointer[0]);

        var result = memory.readBytes(
            (int) pmBufferValue.apply(bufferPointer[0])[0],
            (int) pmBufferLength.apply(bufferPointer[0])[0]);

        System.out.println("RESULT: " + new String(result));

        ParseResult pr = Loader.load(result, sourceBytes);

        assertEquals(1, pr.value.childNodes().length);

        System.out.println("Nodes:");
        System.out.println(pr.value.childNodes()[0]);
        assertTrue(pr.value.childNodes()[0].toString().contains("CallNode"));
    }

}
