package org.prism;

import com.dylibso.chicory.annotations.WasmModuleInterface;
import com.dylibso.chicory.runtime.ByteArrayMemory;
import com.dylibso.chicory.runtime.ExportFunction;
import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.runtime.WasmRuntimeException;
import com.dylibso.chicory.wasi.WasiOptions;
import com.dylibso.chicory.wasi.WasiPreview1;
import com.dylibso.chicory.wasm.WasmModule;
import com.dylibso.chicory.wasm.types.MemoryLimits;

import java.nio.charset.StandardCharsets;

@WasmModuleInterface(WasmResource.absoluteFile)
public class PrismWASM extends Prism {
    private final ExportFunction calloc;
    private final ExportFunction pmSerializeParse;
    private final ExportFunction pmBufferInit;
    private final ExportFunction pmBufferSizeof;
    private final ExportFunction pmBufferValue;
    private final ExportFunction pmBufferLength;

    private final Instance instance;

    public PrismWASM() {
        super();
        instance = Instance.builder(PrismParser.load())
            .withMemoryFactory(ByteArrayMemory::new)
            .withMachineFactory(PrismParser::create)
            .withImportValues(ImportValues.builder().addFunction(wasi.toHostFunctions()).build())
            .build();

        calloc = instance.exports().function("calloc");
        pmSerializeParse = instance.exports().function("pm_serialize_parse");
        pmBufferInit = instance.exports().function("pm_buffer_init");
        pmBufferSizeof = instance.exports().function("pm_buffer_sizeof");
        pmBufferValue = instance.exports().function("pm_buffer_value");
        pmBufferLength = instance.exports().function("pm_buffer_length");
    }

    @Override
    public byte[] serialize(byte[] packedOptions, byte[] sourceBytes, int sourceLength) {
        var sourcePointer = calloc.apply(1, sourceLength);
        instance.memory().write((int) sourcePointer[0], sourceBytes, 0, sourceLength);

        var optionsPointer = calloc.apply(1, packedOptions.length);
        instance.memory().write((int) optionsPointer[0], packedOptions);

        var bufferPointer = calloc.apply(pmBufferSizeof.apply()[0], 1);
        pmBufferInit.apply(bufferPointer);

        pmSerializeParse.apply(
            bufferPointer[0], sourcePointer[0], sourceLength, optionsPointer[0]);

        var result = instance.memory().readBytes(
            (int) pmBufferValue.apply(bufferPointer[0])[0],
            (int) pmBufferLength.apply(bufferPointer[0])[0]);

        return result;
    }

    @Override
    public void close() {
        if (wasi != null) {
            wasi.close();
        }
    }
}
