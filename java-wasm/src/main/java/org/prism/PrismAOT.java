package org.prism;

import com.dylibso.chicory.annotations.WasmModuleInterface;
import com.dylibso.chicory.runtime.ByteArrayMemory;
import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.wasm.WasmModule;
import com.dylibso.chicory.wasm.types.MemoryLimits;

import java.nio.charset.StandardCharsets;

public class PrismAOT extends Prism {
    private final Prism_ModuleExports exports;
    private final Instance instance;

    public PrismAOT() {
        super();
        instance = Instance.builder(PrismParser.load())
            .withMemoryFactory(ByteArrayMemory::new)
            .withMachineFactory(PrismParser::create)
            .withImportValues(ImportValues.builder().addFunction(wasi.toHostFunctions()).build())
            .build();
        exports = new Prism_ModuleExports(instance);
    }

    @Override
    public byte[] serialize(byte[] packedOptions, byte[] sourceBytes, int sourceLength) {
        int sourcePointer = 0;
        int optionsPointer = 0;
        int bufferPointer = 0;
        byte[] result;
        try {
            sourcePointer = exports.calloc(1, sourceLength + 1);
            instance.memory().write(sourcePointer, sourceBytes, 0, sourceLength);
            instance.memory().writeByte(sourcePointer + sourceLength, (byte) 0);

            optionsPointer = exports.calloc(1, packedOptions.length);
            instance.memory().write(optionsPointer, packedOptions);

            bufferPointer = exports.calloc(exports.pmBufferSizeof(), 1);
            exports.pmBufferInit(bufferPointer);

            exports.pmSerializeParse(
                bufferPointer, sourcePointer, sourceLength, optionsPointer);

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

    // DEBUG CHECK
    public int memorySize() {
        return instance.memory().pages();
    }
}
