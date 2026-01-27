package org.prism;

import com.dylibso.chicory.runtime.ByteArrayMemory;
import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.runtime.InterpreterMachine;
import com.dylibso.chicory.wasm.Parser;
import com.dylibso.chicory.wasm.WasmModule;

public class PrismWASM extends Prism {
    private final Prism_ModuleExports exports;
    private final Instance instance;

    public PrismWASM() {
        super();
        WasmModule module = Parser.parse(
            PrismWASM.class.getResourceAsStream("/prism.wasm"));
        instance = Instance.builder(module)
            .withMemoryFactory(ByteArrayMemory::new)
            .withMachineFactory(InterpreterMachine::new)
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
                exports.pmStringFree(sourcePointer);
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

    // DEBUG
    public int memorySize() {
        return instance.memory().pages();
    }
}
