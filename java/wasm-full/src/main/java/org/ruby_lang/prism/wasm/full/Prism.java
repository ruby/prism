package org.ruby_lang.prism.wasm.full;

import com.dylibso.chicory.runtime.ByteArrayMemory;
import com.dylibso.chicory.runtime.ImportValues;
import com.dylibso.chicory.runtime.Instance;
import com.dylibso.chicory.wasi.WasiOptions;
import com.dylibso.chicory.wasi.WasiPreview1;

import java.nio.charset.StandardCharsets;

public class Prism implements AutoCloseable {
    private final WasiPreview1 wasi;
    protected final Prism_ModuleExports exports;
    private final Instance instance;

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
    }

    public String version() {
        int versionPointer = exports.pmVersion();
        int length = exports.strchr(versionPointer, 0);

        return new String(instance.memory().readBytes(versionPointer, length - versionPointer));
    }

    public byte[] parse(byte[] sourceBytes, byte[] packedOptions) {
        try (
            Buffer buffer = new Buffer();
            Source source = new Source(sourceBytes, 0, sourceBytes.length);
            Options options = new Options(packedOptions)) {

            return parse(buffer, source, options);
        }
    }

    public byte[] lex(byte[] sourceBytes, byte[] packedOptions) {
        try (
            Buffer buffer = new Buffer();
            Source source = new Source(sourceBytes, 0, sourceBytes.length);
            Options options = new Options(packedOptions)) {

            return lex(buffer, source, options);
        }
    }

    public byte[] parse(byte[] sourceBytes, int sourceOffset, int sourceLength, byte[] packedOptions) {
        try (
            Buffer buffer = new Buffer();
            Source source = new Source(sourceBytes, sourceOffset, sourceLength);
            Options options = new Options(packedOptions)) {

            return parse(buffer, source, options);
        }
    }

    public byte[] parse(Buffer buffer, Source source, Options options) {
        exports.pmSerializeParse(
            buffer.pointer, source.pointer, source.length, options.pointer);

        return buffer.readBytes();
    }

    public byte[] lex(Buffer buffer, Source source, Options options) {
        exports.pmSerializeLex(
            buffer.pointer, source.pointer, source.length, options.pointer);

        return buffer.readBytes();
    }

    public byte[] parseLex(Buffer buffer, Source source, Options options) {
        exports.pmSerializeParseLex(buffer.pointer, source.pointer, source.length, options.pointer);

        return buffer.readBytes();
    }

    public boolean parseSuccess(Source source, Options options) {
        return exports.pmSerializeParseSuccessP(source.pointer, source.length, options.pointer) != 0;
    }

    public class Buffer implements AutoCloseable {
        final int pointer;

        Buffer() {
            pointer = exports.pmBufferNew();
            clear();
        }

        public void clear() {
            exports.pmBufferClear(pointer);
        }

        public void close() {
            exports.pmBufferFree(pointer);
        }

        public byte[] readBytes() {
            return instance.memory().readBytes(
                exports.pmBufferValue(pointer),
                exports.pmBufferLength(pointer));
        }
    }

    public Buffer newBuffer() {
        return new Buffer();
    }

    public class Source implements AutoCloseable{
        final int pointer;
        final int length;

        public Source(int length) {
            pointer = exports.calloc(1, length);
            this.length = length;
        }

        public Source(byte[] bytes, int offset, int length) {
            this(length + 1);
            write(bytes, offset, length);
        }

        public Source(byte[] bytes) {
            this(bytes, 0, bytes.length);
        }

        public void write(byte[] bytes, int offset, int length) {
            assert length + 1 <= this.length;
            instance.memory().write(pointer, bytes, offset, length);
            instance.memory().writeByte(pointer + length, (byte) 0);
        }

        public void close() {
            exports.free(pointer);
        }
    }

    public Source newSource(byte[] bytes) {
        return new Source(bytes);
    }

    class Options implements AutoCloseable {
        final int pointer;

        Options(byte[] packedOptions) {
            int pointer = exports.calloc(1, packedOptions.length);
            instance.memory().write(pointer, packedOptions);
            this.pointer = pointer;
        }

        public void close() {
            exports.free(pointer);
        }
    }

    public Options newOptions(byte[] packedOptions) {
        return new Options(packedOptions);
    }

    @Override
    public void close() {
        if (wasi != null) {
            wasi.close();
        }
    }
}
