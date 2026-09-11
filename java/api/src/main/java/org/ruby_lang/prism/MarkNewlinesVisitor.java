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
            child.setNewLineFlag(this.source, this.newlineMarked);
        }
        return super.visitStatementsNode(node);
    }

    @Override
    protected Void defaultVisit(Nodes.Node node) {
        node.visitChildNodes(this);
        return null;
    }

}
