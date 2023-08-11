package org.yarp;

public final class ParseResult {

    public static final class Error {
        public final String message;
        public final Nodes.Location location;

        public Error(String message, Nodes.Location location) {
            this.message = message;
            this.location = location;
        }
    }

    public static final class Warning {
        public final String message;
        public final Nodes.Location location;

        public Warning(String message, Nodes.Location location) {
            this.message = message;
            this.location = location;
        }
    }

    private final Nodes.Node value;
    private final Error[] errors;
    private final Warning[] warnings;

    public ParseResult(Nodes.Node value, Error[] errors, Warning[] warnings) {
        this.value = value;
        this.errors = errors;
        this.warnings = warnings;
    }

    public Nodes.Node getValue() {
        return value;
    }

    public Error[] getErrors() {
        return errors;
    }

    public Warning[] getWarnings() {
        return warnings;
    }
}
