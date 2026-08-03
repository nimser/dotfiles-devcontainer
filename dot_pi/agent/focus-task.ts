/**
 * focus-task — worker side of pi-focus
 * (spec: ~/.pi/artifacts/pi-focus/prd-03-focus-task-extension.md).
 *
 * Loaded only by `pi-focus spawn` (`-e ~/.pi/agent/focus-task.ts`), never
 * auto-discovered: it lives outside ~/.pi/agent/extensions/ on purpose, so an
 * interactive session is untouched by it.
 *
 * It reports lifecycle events through `pi-focus _report`, which updates the task
 * manifest and asks the host broker to retitle the tmux window and push ntfy.
 * The extension itself never touches tmux or ntfy: a container cannot, and the
 * host must not grow a second code path.
 *
 * Env (set by `pi-focus spawn`): PI_FOCUS_TASK_ID, PI_FOCUS_MODE=oneshot|persistent.
 */
import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Event = "working" | "settled" | "completed" | "failed";

function report(taskId: string, event: Event): void {
	const result = spawnSync(process.env.PI_FOCUS_BIN ?? "pi-focus", ["_report", taskId, "--event", event, "--json"], {
		encoding: "utf8",
		timeout: 30_000,
	});
	if (result.status !== 0) {
		console.error(`[focus-task] _report ${event} failed: ${(result.stderr ?? "").trim() || result.error?.message || "unknown"}`);
	}
}

export default function focusTask(pi: ExtensionAPI) {
	const taskId = process.env.PI_FOCUS_TASK_ID;
	if (!taskId) return; // not a spawned task: stay out of the way
	const oneShot = (process.env.PI_FOCUS_MODE ?? "oneshot") !== "persistent";
	let working = false;
	let done = false;

	pi.on("agent_start", async () => {
		if (done || working) return;
		working = true;
		report(taskId, "working");
	});

	pi.on("agent_settled", async (_event, ctx) => {
		if (done) return;
		working = false;
		if (oneShot) {
			done = true;
			report(taskId, "completed");
			ctx.shutdown();
			return;
		}
		report(taskId, "settled");
	});

	// A crash must still leave a truthful manifest; a forever-`running` ghost is the failure mode this layer removes.
	const bail = (code: number | null) => {
		if (done) return;
		done = true;
		report(taskId, code === 0 ? "completed" : "failed");
	};
	process.on("exit", (code) => bail(code));
	process.on("uncaughtException", (error) => {
		console.error(`[focus-task] uncaught: ${error?.stack || error}`);
		bail(1);
	});
}
