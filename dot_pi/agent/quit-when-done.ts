/**
 * Quit When Done
 *
 * Runs pi in normal interactive mode (full TUI output: reasoning, tool
 * calls, diffs) but gracefully shuts down as soon as the agent settles
 * (no more retries, compaction, or queued follow-ups). Useful for
 * one-shot CLI invocations that should show everything and then return
 * control to the shell.
 *
 * Deliberately kept OUTSIDE ~/.pi/agent/extensions/ so it is never
 * auto-discovered. Load it explicitly:
 *   pi -e ~/.pi/agent/quit-when-done.ts "your prompt"
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("agent_settled", async (_event, ctx) => {
		ctx.shutdown();
	});
}
