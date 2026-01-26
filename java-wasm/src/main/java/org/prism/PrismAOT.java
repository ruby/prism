package org.prism;

import com.dylibso.chicory.annotations.WasmModuleInterface;
import com.dylibso.chicory.runtime.ByteArrayMemory;
import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.wasm.WasmModule;
import com.dylibso.chicory.wasm.types.MemoryLimits;

import java.nio.charset.StandardCharsets;

@WasmModuleInterface(WasmResource.absoluteFile)
public class PrismAOT extends Prism {
    private final Instance instance;
    private final Prism_ModuleExports exports;

    public PrismAOT() {
        super();
        WasmModule module = PrismParser.load();
        PrismParser parser = new PrismParser();
        instance = Instance.builder(module)
            .withMemoryFactory(limits -> new ByteArrayMemory(new MemoryLimits(10, MemoryLimits.MAX_PAGES)))
            .withMachineFactory(parser.machineFactory())
            .withImportValues(ImportValues.builder().addFunction(wasi.toHostFunctions()).build())
            .build();
        exports = new Prism_ModuleExports(instance);
    }

    public byte[] serialize(byte[] packedOptions, byte[] source, int sourceLength) {
        int sourcePointer = 0;
        int optionsPointer = 0;
        int bufferPointer = 0;
        byte[] result;
        try {
            sourcePointer = exports.calloc(sourceLength, 1);
            exports.memory().write(sourcePointer, source);

            optionsPointer = exports.calloc(1, packedOptions.length);
            exports.memory().write(optionsPointer, packedOptions);

            bufferPointer = exports.calloc(exports.pmBufferSizeof(), 1);
            exports.pmBufferInit(bufferPointer);

            exports.pmSerializeParse(bufferPointer, sourcePointer, sourceLength, optionsPointer);

            result = instance.memory().readBytes(
                exports.pmBufferValue(bufferPointer),
                exports.pmBufferLength(bufferPointer));
        } finally {
            if (sourcePointer != 0) {
                exports.free(sourcePointer);
            }
            if (optionsPointer != 0) {
                exports.free(optionsPointer);
            }
            if (bufferPointer != 0) {
                exports.pmBufferFree(bufferPointer);
                exports.free(bufferPointer);
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
