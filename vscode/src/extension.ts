"use strict";

import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { ExtensionContext, commands, window, workspace } from "vscode";
import { LanguageClient, Executable } from "vscode-languageclient/node";

// This object will get initialized once the language client is ready. It will
// get set back to null when the extension is deactivated. It is exported for
// easier testing.
export let languageClient: LanguageClient | null = null;

// This is the expected top-level export that is called by VSCode when the
// extension is activated.
export async function activate(context: ExtensionContext) {
  // This output channel is going to contain all of our informational messages.
  // It's not really meant for the end-user, it's more for debugging.
  const outputChannel = window.createOutputChannel("YARP");

  // This is the list of objects that implement the Disposable interface. They
  // will all get cleaned up with this extension is deactivated. It's important
  // to add them to this list so we don't leak memory.
  context.subscriptions.push(
    // The output channel itself is a disposable. When the extension is
    // deactivated it will be removed from the list.
    outputChannel,

    // Each of the commands that interacts with this extension is a disposable.
    // It's important to register them here as opposed to whenever the client
    // starts up because we don't want to register them again whenever the
    // client restarts.
    commands.registerCommand("yarp-lsp.start", startLanguageServer),
    commands.registerCommand("yarp-lsp.stop", stopLanguageServer),
    commands.registerCommand("yarp-lsp.restart", restartLanguageServer),
    commands.registerCommand("yarp-lsp.report", reportIssue)
  );

  // We're returning a Promise from this function that will start the Ruby
  // subprocess.
  await startLanguageServer();

  // There's a bit of complexity here. Basically, we try to locate
  // an YARP executable in three places, in order of preference:
  //   1. Explicit path from advanced settings, if provided
  //   2. Anywhere in $PATH
  //
  // None of these approaches is perfect. System gem might be correct if the
  // right environment variables are set, but it's a bit of a prayer. Bundled
  // gem is better, but we make the gross oversimplification that the
  // workspace only has one root and that the bundle is at root of the
  // workspace -- which is not true for large projects or monorepos.
  // Explicit path varies between machines/users and is also victim to the
  // oversimplification problem.
  async function getServerOptions(args: string[]): Promise<Executable> {
    const advancedConfig = workspace.getConfiguration("yarp-lsp.advanced");
    let value = advancedConfig.get<string>("commandPath");

    // If a value is given on the command line, attempt to use it.
    if (value) {
      // First, substitute in any variables that may have been present in the
      // given value to the configuration.
      const substitution = new RegExp("\\$\\{([^}]*)\\}");

      for (let match = substitution.exec(value); match; match = substitution.exec(value)) {
        switch (match[1]) {
          case "cwd":
            value = value.replace(match[0], process.cwd());
            break;
          case "pathSeparator":
            value = value.replace(match[0], path.sep);
            break;
          case "userHome":
            value = value.replace(match[0], os.homedir());
            break;
        }
      }

      // Next, attempt to stat the executable path. If it's a file, we're good.
      try {
        if (fs.statSync(value).isFile()) {
          return { command: value, args };
        }
      } catch {
        outputChannel.appendLine(`Ignoring bogus commandPath (${value} does not exist).`);
      }
    }

    // Otherwise, fall back to the global yarp lookup.
    return { command: "yarp-lsp", args };
  }

  // This function is called when the extension is activated or when the
  // language server is restarted.
  async function startLanguageServer() {
    if (languageClient) {
      return; // preserve idempotency
    }

    // The top-level configuration group is yarp. Broadly useful settings
    // are under that group.
    const config = workspace.getConfiguration("yarp");

    // The args are going to be passed to the yarp executable. It's important
    // that it lines up with what the CLI expects.
    const args = [];

    // Configure ignore files if any.
    const ignoreFiles = config.get<string>("ignoreFiles");
    if (ignoreFiles) {
      args.push(`--ignore-files=${ignoreFiles}`);
    }

    const run = await getServerOptions(args);
    outputChannel.appendLine(`Starting language server: ${run.command} ${run.args?.join(" ")}`);

    // Here, we instantiate the language client. This is the object that is
    // responsible for the communication and management of the Ruby subprocess.
    languageClient = new LanguageClient("YARP", { run, debug: run }, {
      documentSelector: [
        { scheme: "file", language: "haml" },
        { scheme: "file", language: "ruby" },
        { scheme: "file", pattern: "**/Gemfile" },
      ],
      outputChannel
    });

    try {
      // Here we're going to wait for the language server to start.
      await languageClient.start();
    } catch (error) {
      languageClient = null;

      const items = ["Restart"];
      let msg = "Something went wrong.";

      if (typeof error === "string") {
        if (/ENOENT/.test(error)) {
          msg = "Command not found. Is the yarp gem installed?";
          items.unshift("Install Gem");
        }
      }

      const action = await window.showErrorMessage(msg, ...items);
      switch (action) {
        case "Restart":
          startLanguageServer();
          break;
      }
    }
  }

  // This function is called as part of the shutdown or restart process. It's
  // always user-initiated either through manually executing an action or
  // changing some configuration.
  async function stopLanguageServer() {
    if (languageClient) {
      outputChannel.appendLine("Stopping language server...");
      await languageClient.stop();
      languageClient = null;
    }
  }

  // This function is called as part of the restart process. Like
  // stopLanguageServer, it's always user-initiated either through manually
  // executing an action or changing some configuration.
  async function restartLanguageServer() {
    outputChannel.appendLine("Restarting language server...");
    await stopLanguageServer();
    await startLanguageServer();
  }

  // This function is called when a user wants to report an issue they have
  // have found while writing Ruby code. If the user has selected code in the
  // editor, this will be included as a snippet on the issue.
  async function reportIssue() {
    let issueContent = `
## Expected behavior
<!-- TODO: Briefly explain what the expected behavior should be on this example. -->

## Actual behavior
<!-- TODO: Describe here what actually happened. -->

## Steps to reproduce the problem
<!-- TODO: Describe how we can reproduce the problem. -->

## Additional information
<!-- TODO: Include any additional information, such as screenshots. -->
    `;

    const selection = window.activeTextEditor?.selection;
    if (selection) {
      const text = window.activeTextEditor?.document.getText(selection);

      if (text) {
        issueContent = "### Code snippet causing error\n``` ruby\n" + text + "\n```\n" + issueContent;
      }
    }

    commands.executeCommand('vscode.open', `https://github.com/Shopify/yarp/issues/new?&labels=Bug&body=${encodeURIComponent(issueContent)}`);
  }
}

// This is the expected top-level export that is called by VSCode when the
// extension is deactivated.
export async function deactivate() {
  await languageClient?.stop();
  languageClient = null;
}
