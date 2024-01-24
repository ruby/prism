package org.prism;

// @formatter:off
public final class ParseResult {

    public static final class MagicComment {
        public final Nodes.Location keyLocation;
        public final Nodes.Location valueLocation;

        public MagicComment(Nodes.Location keyLocation, Nodes.Location valueLocation) {
            this.keyLocation = keyLocation;
            this.valueLocation = valueLocation;
        }
    }

    public enum DiagnosticLevel {
        /** The default level for errors. */
        ERROR_DEFAULT,
        /** For warnings which should be emitted if $VERBOSE != nil. */
        WARNING_VERBOSE_NOT_NIL,
        /** For warnings which should be emitted if $VERBOSE == true. */
        WARNING_VERBOSE_TRUE
    }

    public static DiagnosticLevel[] DIAGNOSTIC_LEVELS = DiagnosticLevel.values();

    public static final class Error {
        public final String message;
        public final Nodes.Location location;
        public final DiagnosticLevel level;

        public Error(String message, Nodes.Location location, DiagnosticLevel level) {
            this.message = message;
            this.location = location;
            this.level = level;
        }
    }

    public static final class Warning {
        public final String message;
        public final Nodes.Location location;
        public final DiagnosticLevel level;

        public Warning(String message, Nodes.Location location, DiagnosticLevel level) {
            this.message = message;
            this.location = location;
            this.level = level;
        }
    }

    public final Nodes.Node value;
    public final MagicComment[] magicComments;
    public final Nodes.Location dataLocation;
    public final Error[] errors;
    public final Warning[] warnings;

    public ParseResult(Nodes.Node value, MagicComment[] magicComments, Nodes.Location dataLocation, Error[] errors, Warning[] warnings) {
        this.value = value;
        this.magicComments = magicComments;
        this.dataLocation = dataLocation;
        this.errors = errors;
        this.warnings = warnings;
    }
}
// @formatter:on
