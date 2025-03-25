package org.prism;

import com.dylibso.chicory.runtime.ByteArrayMemory;
import com.dylibso.chicory.runtime.ExportFunction;
import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.wasi.WasiOptions;
import com.dylibso.chicory.wasi.WasiPreview1;

import java.nio.charset.StandardCharsets;

public class Prism implements AutoCloseable {
    private final ExportFunction calloc;
    private final ExportFunction pmSerializeParse;
    private final ExportFunction pmBufferInit;
    private final ExportFunction pmBufferSizeof;
    private final ExportFunction pmBufferValue;
    private final ExportFunction pmBufferLength;

    private final WasiPreview1 wasi;
    private final Instance instance;

    public Prism() {
        this(WasiOptions.builder().build());
    }
    public Prism(WasiOptions wasiOpts) {
        wasi = WasiPreview1.builder().withOptions(wasiOpts).build();
        instance = Instance.builder(PrismModule.load())
            .withMemoryFactory(ByteArrayMemory::new)
            .withMachineFactory(PrismModule::create)
            .withImportValues(ImportValues.builder().addFunction(wasi.toHostFunctions()).build())
            .build();

        calloc = instance.exports().function("calloc");
        pmSerializeParse = instance.exports().function("pm_serialize_parse");
        pmBufferInit = instance.exports().function("pm_buffer_init");
        pmBufferSizeof = instance.exports().function("pm_buffer_sizeof");
        pmBufferValue = instance.exports().function("pm_buffer_value");
        pmBufferLength = instance.exports().function("pm_buffer_length");
    }

    public ParseResult serializeParse(byte[] packedOptions, String source) {
        var sourceBytes = source.getBytes(StandardCharsets.US_ASCII);

        var sourcePointer = calloc.apply(1, source.length());
        instance.memory().writeString((int) sourcePointer[0], source);

        var optionsPointer = calloc.apply(1, packedOptions.length);
        instance.memory().write((int) optionsPointer[0], packedOptions);

        var bufferPointer = calloc.apply(pmBufferSizeof.apply()[0], 1);
        pmBufferInit.apply(bufferPointer);

        pmSerializeParse.apply(
            bufferPointer[0], sourcePointer[0], source.length(), optionsPointer[0]);

        var result = instance.memory().readBytes(
            (int) pmBufferValue.apply(bufferPointer[0])[0],
            (int) pmBufferLength.apply(bufferPointer[0])[0]);

        return Loader.load(result, sourceBytes);
    }

    @Override
    public void close() {
        if (wasi != null) {
            wasi.close();
        }
    }
}
