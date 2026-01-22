package org.prism;

import com.dylibso.chicory.annotations.WasmModuleInterface;
import com.dylibso.chicory.runtime.ByteArrayMemory;
import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.wasi.WasiOptions;
import com.dylibso.chicory.wasi.WasiPreview1;
import com.dylibso.chicory.wasm.WasmModule;
import com.dylibso.chicory.wasm.types.MemoryLimits;

import java.nio.charset.StandardCharsets;

@WasmModuleInterface(WasmResource.absoluteFile)
public class Prism implements AutoCloseable {
    private final WasiPreview1 wasi;
    private final Instance instance;
    private final Prism_ModuleExports exports;

    public Prism() {
        this(WasiOptions.builder().build());
    }
    public Prism(WasiOptions wasiOpts) {
        wasi = WasiPreview1.builder().withOptions(wasiOpts).build();
        WasmModule module = PrismParser.load();
        PrismParser parser = new PrismParser();
        instance = Instance.builder(module)
            .withMemoryFactory(limits -> new ByteArrayMemory(new MemoryLimits(10, MemoryLimits.MAX_PAGES)))
            .withMachineFactory(parser.machineFactory())
            .withImportValues(ImportValues.builder().addFunction(wasi.toHostFunctions()).build())
            .build();
        exports = new Prism_ModuleExports(instance);
    }

    public Prism_ModuleExports exports() {
        return exports;
    }

    public byte[] serialize(byte[] packedOptions, byte[] source, int sourceLength) {
        int sourcePointer = 0;
        int optionsPointer = 0;
        int bufferPointer = 0;
        int resultPointer = 0;
        byte[] result;
        try {
            sourcePointer = exports.calloc(1, sourceLength);
            exports.memory().write(sourcePointer, source);

            optionsPointer = exports.calloc(1, packedOptions.length);
            exports.memory().write(optionsPointer, packedOptions);

            bufferPointer = exports.calloc(exports.pmBufferSizeof(), 1);
            exports.pmBufferInit(bufferPointer);

            exports.pmSerializeParse(bufferPointer, sourcePointer, sourceLength, optionsPointer);

            resultPointer = exports.pmBufferValue(bufferPointer);

            result = instance.memory().readBytes(
                resultPointer,
                exports.pmBufferLength(bufferPointer));
        } finally {
            if (sourcePointer != 0) {
                exports.free(sourcePointer);
            }
            if (optionsPointer != 0) {
                exports.free(optionsPointer);
            }
            if (bufferPointer != 0) {
                exports.free(bufferPointer);
            }
            if (resultPointer != 0) {
                exports.free(resultPointer);
            }
        }

        return result;
    }

    public ParseResult serializeParse(byte[] packedOptions, String source) {
        var sourceBytes = source.getBytes(StandardCharsets.US_ASCII);

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
