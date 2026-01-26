package org.prism;

import com.dylibso.chicory.annotations.WasmModuleInterface;
import com.dylibso.chicory.wasi.WasiOptions;
import com.dylibso.chicory.wasi.WasiPreview1;

import java.nio.charset.StandardCharsets;

@WasmModuleInterface(WasmResource.absoluteFile)
public abstract class Prism implements AutoCloseable {
    protected final WasiPreview1 wasi;

    Prism() {
        this(WasiOptions.builder().build());
    }

    Prism(WasiOptions wasiOpts) {
        wasi = WasiPreview1.builder().withOptions(wasiOpts).build();
    }

    public static Prism newInstance(boolean aot) {
        if (aot) return new PrismAOT();

        return new PrismWASM();
    }

    public abstract byte[] serialize(byte[] packedOptions, byte[] source, int sourceLength);

    public ParseResult serializeParse(byte[] packedOptions, String source) {
        var sourceBytes = source.getBytes(StandardCharsets.ISO_8859_1);
        byte[] result = serialize(packedOptions, sourceBytes, sourceBytes.length);
        return Loader.load(result, sourceBytes);
    }

    @Override
    public abstract void close();
}
