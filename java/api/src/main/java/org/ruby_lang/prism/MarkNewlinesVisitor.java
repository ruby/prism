package org.ruby_lang.prism;

import java.util.Arrays;

// Keep in sync with Ruby MarkNewlinesVisitor
final class MarkNewlinesVisitor extends AbstractNodeVisitor<Void> {

    private final Nodes.Source source;
    private boolean[] newlineMarked;

    MarkNewlinesVisitor(Nodes.Source source) {
        this.source = source;
        this.newlineMarked = new boolean[1 + source.getLineCount()];
    }

    @Override
    public Void visitBlockNode(Nodes.BlockNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        try {
            return super.visitBlockNode(node);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }
    }

    @Override
    public Void visitLambdaNode(Nodes.LambdaNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        try {
            return super.visitLambdaNode(node);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }
    }

    @Override
    public Void visitDefNode(Nodes.DefNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        // The body of an endless method definition never emits newline events,
        // so in that case mark every line as already seen instead. There is no
        // location for the `=` operator here, but only an endless method
        // definition has a statements body which ends with the def node itself.
        if (node.body instanceof Nodes.StatementsNode && node.endOffset() == node.body.endOffset()) {
            Arrays.fill(this.newlineMarked, true);
        }
        try {
            return super.visitDefNode(node);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }
    }

    @Override
    public Void visitClassNode(Nodes.ClassNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        try {
            return super.visitClassNode(node);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }
    }

    @Override
    public Void visitModuleNode(Nodes.ModuleNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        try {
            return super.visitModuleNode(node);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }
    }

    @Override
    public Void visitSingletonClassNode(Nodes.SingletonClassNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        try {
            return super.visitSingletonClassNode(node);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }
    }

    // Statements inside string interpolation do not emit newline events, so
    // mark every line as already seen while visiting them. Nested scopes
    // (blocks, lambdas, defs, etc.) reset the lines and emit events again.
    @Override
    public Void visitEmbeddedStatementsNode(Nodes.EmbeddedStatementsNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        Arrays.fill(this.newlineMarked, true);
        try {
            return super.visitEmbeddedStatementsNode(node);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }
    }

    // The predicate of a while loop is compiled at the end of the loop,
    // after the body, so any statements it contains (from parentheses)
    // emit their line events again even if the lines were already seen.
    @Override
    public Void visitWhileNode(Nodes.WhileNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        try {
            node.predicate.accept(this);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }

        if (node.statements != null) {
            node.statements.accept(this);
        }
        return null;
    }

    // The predicate of an until loop is compiled at the end of the loop,
    // after the body, so any statements it contains (from parentheses)
    // emit their line events again even if the lines were already seen.
    @Override
    public Void visitUntilNode(Nodes.UntilNode node) {
        boolean[] oldNewlineMarked = this.newlineMarked;
        this.newlineMarked = new boolean[oldNewlineMarked.length];
        try {
            node.predicate.accept(this);
        } finally {
            this.newlineMarked = oldNewlineMarked;
        }

        if (node.statements != null) {
            node.statements.accept(this);
        }
        return null;
    }

    @Override
    public Void visitIfNode(Nodes.IfNode node) {
        node.setNewLineFlag(this.source, this.newlineMarked);
        return super.visitIfNode(node);
    }

    @Override
    public Void visitUnlessNode(Nodes.UnlessNode node) {
        node.setNewLineFlag(this.source, this.newlineMarked);
        return super.visitUnlessNode(node);
    }

    @Override
    public Void visitStatementsNode(Nodes.StatementsNode node) {
        for (Nodes.Node child : node.body) {
            setNewLineFlag(child);
        }
        return super.visitStatementsNode(node);
    }

    // Keep in sync with the newline_flag! overrides in Ruby's newlines.rb which
    // are not part of the generated setNewLineFlag() methods.
    private void setNewLineFlag(Nodes.Node node) {
        if (node instanceof Nodes.WhileNode whileNode) {
            boolean prefix = isPrefixLoop(whileNode, whileNode.isBeginModifier(), whileNode.statements);
            if (prefix && whileNode.predicate instanceof Nodes.ParenthesesNode) {
                // A parenthesized predicate emits its own line event when it is
                // compiled at the end of the loop, in addition to this one.
                markNewLineFlag(node);
            } else {
                whileNode.predicate.setNewLineFlag(this.source, this.newlineMarked);
            }
        } else if (node instanceof Nodes.UntilNode untilNode) {
            boolean prefix = isPrefixLoop(untilNode, untilNode.isBeginModifier(), untilNode.statements);
            if (prefix && untilNode.predicate instanceof Nodes.ParenthesesNode) {
                // A parenthesized predicate emits its own line event when it is
                // compiled at the end of the loop, in addition to this one.
                markNewLineFlag(node);
            } else {
                untilNode.predicate.setNewLineFlag(this.source, this.newlineMarked);
            }
        } else {
            node.setNewLineFlag(this.source, this.newlineMarked);
        }
    }

    // Mark the node itself, like Nodes.Node#setNewLineFlag(), regardless of any
    // setNewLineFlag() override of the node.
    private void markNewLineFlag(Nodes.Node node) {
        int line = this.source.findLine(node.startOffset);
        if (!this.newlineMarked[line]) {
            this.newlineMarked[line] = true;
            node.setNewLineFlag(true);
        }
    }

    // Whether a while/until loop starts with its keyword. There is no keyword
    // location in the Java nodes, but only a prefix loop starts before its
    // statements.
    private static boolean isPrefixLoop(Nodes.Node node, boolean beginModifier, Nodes.StatementsNode statements) {
        return !beginModifier && (statements == null || node.startOffset != statements.startOffset);
    }

    @Override
    protected Void defaultVisit(Nodes.Node node) {
        node.visitChildNodes(this);
        return null;
    }

}
