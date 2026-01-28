package org.prism;

import com.dylibso.chicory.annotations.WasmModuleInterface;
import com.dylibso.chicory.runtime.ByteArrayMemory;
import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.wasi.WasiOptions;
import com.dylibso.chicory.wasi.WasiPreview1;

import java.nio.charset.StandardCharsets;

@WasmModuleInterface(WasmResource.absoluteFile)
public class Prism implements AutoCloseable {
    private final WasiPreview1 wasi;
    protected final Prism_ModuleExports exports;
    private final Instance instance;

    private int bufferPointer;
    private int preSourcePointer;
    private int preOptionsPointer;

    private final int SOURCE_SIZE = 2 * 1024 * 1024; // 2 MiB
    private final int PACKED_OPTIONS_BUFFER_SIZE = 1024;

    public Prism() {
        this(WasiOptions.builder().build());
    }

    public Prism(WasiOptions wasiOpts) {
        wasi = WasiPreview1.builder().withOptions(wasiOpts).build();
        instance = Instance.builder(PrismParser.load())
            .withMemoryFactory(ByteArrayMemory::new)
            .withMachineFactory(PrismParser::create)
            .withImportValues(ImportValues.builder().addFunction(wasi.toHostFunctions()).build())
            .build();
        exports = new Prism_ModuleExports(instance);

        preOptionsPointer = exports.calloc(1, PACKED_OPTIONS_BUFFER_SIZE);
        preSourcePointer = exports.calloc(1, SOURCE_SIZE);

        bufferPointer = exports.calloc(exports.pmBufferSizeof(), 1);
        exports.pmBufferInit(bufferPointer);
    }

    public byte[] serialize(byte[] packedOptions, byte[] sourceBytes, int sourceLength) {
        int sourcePointer = 0;
        boolean useDefaultSourcePointer = sourceLength + 1 > SOURCE_SIZE;
        int optionsPointer = 0;
        boolean useDefaultOptionsPointer = packedOptions.length > PACKED_OPTIONS_BUFFER_SIZE;
        byte[] result;
        try {
            sourcePointer = (!useDefaultSourcePointer) ?
                exports.calloc(1, sourceLength + 1) : preSourcePointer;
            instance.memory().write(sourcePointer, sourceBytes, 0, sourceLength);
            instance.memory().writeByte(sourcePointer + sourceLength, (byte) 0);

            optionsPointer = (!useDefaultOptionsPointer) ?
                exports.calloc(1, packedOptions.length) : preOptionsPointer;
            instance.memory().write(optionsPointer, packedOptions);

            exports.pmBufferClear(bufferPointer);

            exports.pmSerializeParse(
                bufferPointer, sourcePointer, sourceLength, optionsPointer);

            result = instance.memory().readBytes(
                exports.pmBufferValue(bufferPointer),
                exports.pmBufferLength(bufferPointer));
        } finally {
            if (!useDefaultSourcePointer) {
                exports.free(sourcePointer);
            }
            if (!useDefaultOptionsPointer) {
                exports.free(optionsPointer);
            }
        }

        return result;
    }

    public ParseResult serializeParse(byte[] packedOptions, String source) {
        var sourceBytes = source.getBytes(StandardCharsets.ISO_8859_1);
        byte[] result = serialize(packedOptions, sourceBytes, sourceBytes.length);
        return Loader.load(result, sourceBytes);
    }

    @Override
    public void close() {
        if (wasi != null) {
            wasi.close();
        }
    }
}
