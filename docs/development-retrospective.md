# Development Retrospective

## 2026-06-08 Composer Responsive Width and Send Button Closeout

### What Happened

- Visual validation against the supplied Codex desktop screenshots showed that the bottom composer is not a single fixed-width widget. It behaves as a responsive capped surface: it widens with the active conversation lane, but remains constrained enough that the transcript still reads as a centered Codex-style column.
- The earlier Godex implementation over-corrected in both directions: a narrow fallback could squeeze the composer into an obviously undersized panel, while a hard fixed width did not survive split or narrow editor layouts.
- The send/stop action also looked broken in the editor because a themed Godot `Button` with `flat=true` could hide the intended light circular background, leaving only a low-contrast dark icon on the dark composer.
- The local open-source Codex reference is most useful for Agent, tool, turn, command, and thread-history semantics. It does not replace the desktop screenshots for exact composer geometry, so UI work must cite screenshots and then encode the observed behavior as Godot layout constraints.

### Changes Made

- Updated the shared conversation-column layout contract so `Messages`, `ComposerPanel`, bottom drawers, guide queues, and change-review surfaces share one responsive capped width.
- Derived the composer width from the actual center-lane/container/viewport sizes before falling back to the Codex-style maximum, so wide layouts expand while split or narrow layouts no longer collapse to an unrelated minimum.
- Kept the send/stop action as a visible light circular button with dark icon contrast by allowing the button stylebox background to render normally.
- Added headless layout assertions covering both wide and narrow composer widths, then validated the installed Mechoes copy with the Godot 4.6.2 console validator and a live editor screenshot.

### Follow-up Guidelines

- Treat Codex screenshots as the source of truth for desktop-only UI geometry when the local open-source Codex tree has no corresponding app-shell implementation.
- Do not use a single magic composer width. The contract is responsive with a maximum, a narrow minimum, and a real container/viewport-derived available width.
- When a Godot icon button must appear as a filled circular action, verify both the icon color and the rendered stylebox background; setting `flat=true` can remove the surface even if custom colors exist.
- Godot .NET MCP would make this class of issue easier to close if it exposed semantic geometry/style probes for named editor controls, such as composer rect, transcript column rect, send-button rect, resolved stylebox background, and visible icon contrast.

## 2026-06-08 Codex Agent Loop Blocking Review

### What Happened

- Live Mechoes validation showed repeated `Agent 循环已达到最大步数` messages while tool calls and guide actions were still expected to continue.
- The previous Godex state model used `agent_loop_max_steps = 12` as a default execution boundary, which incorrectly turned a diagnostic guard into product behavior.
- The local Codex reference in `codex-rs/core/src/session/turn.rs` shows the real loop contract: sample, execute tool calls, record outputs, and continue while `needs_follow_up` or pending input exists. Codex relies on approval blocking, cancellation, errors, stop hooks, and automatic compaction for control; it does not stop normal tool work after a fixed small step count.
- A related local tool boundary appeared with `godex_update_progress`: the model-visible tool auto-completed in state, but the controller still treated the model response as having tool calls and then found no MCP call to dispatch.
- Validation briefly became noisy on Windows: direct Godot headless invocation without an explicit log file could crash while opening `user://logs`, PowerShell pipeline redirection converted Godot exit leak warnings into native command failures, and `Start-Process` hit the host's duplicate `Path`/`PATH` environment keys.

### Changes Made

- Changed `GodexState.agent_loop_max_steps` to default to `0`, meaning unbounded Codex-style follow-up.
- Kept positive `agent_loop_max_steps` values as an explicit diagnostic safety guard for tests or recovery only.
- Allowed auto-completed progress tool calls to become valid tool-result continuation boundaries so internal model-controlled progress updates do not leave the loop stuck in `running`.
- Documented the Codex reference loop contract in `docs/architecture.md` so future loop work does not reintroduce a fixed product-level step limit.
- Reworked `tools/validate-godex.ps1` to launch Godot through a bounded `cmd.exe` file-redirection child process, preserving strict exit-code/script-error checks while keeping known Godot headless shutdown leak warnings from aborting PowerShell before the validator can inspect results.

### Follow-up Guidelines

- Treat `needs_follow_up`, pending user input, approval state, cancellation, errors, and context compaction as the Agent loop control surfaces.
- Do not display a default maximum-step limit in user-facing UI unless it is explicitly configured as a diagnostic guard.
- Before live validation, clean the installed Mechoes addon copy: the current audit found a nested `addons/godex/addons/godex` stale copy and a source/install mismatch, so editor behavior may otherwise reflect an old partial sync.
- Godot .NET MCP would help this recovery if it exposed a safe addon-copy integrity audit: expected plugin root, nested duplicate detection, file hash comparison against a source path, and a non-destructive cleanup preview.
- Prefer explicit `--log-file` headless runs or the repository validator over raw Godot console calls in this workspace, because the editor's user log directory can conflict with parallel validation.

## 2026-06-08 Skill Registry, References, and Validation Closeout

### What Happened

- Current Godex code now has a local Skill registry/manager foundation, but the docs still described Skills mostly as a settings toggle or later workflow-template gap.
- Composer references moved from a pure future gap into a first-stage implementation: assistant text selection can become reference chips, sent user messages carry those references, and URL/data image references can be serialized by the request builders.
- The right rail had been tightened to explicit `progress_items`, so the docs needed to keep that semantic line separate from OpenAI transport, MCP execution, queued input, and command lifecycle bookkeeping.
- Integration evidence also needed to name the existing Mechoes addon sync/live-editor reload screenshots and the headless validation script path without claiming a fresh validation run during documentation-only work.

### Changes Made

- Documented `GodexSkillRegistry` as a local-only scanner for `SKILL.md` roots with optional `agents/openai.yaml` metadata, searchable Settings rows, path-level enable/disable persistence, enabled Skill prompt hints, and explicit `$skill` turn injection.
- Recorded the composer reference contract: selected assistant text actions create removable chips, reference-only sends are valid, references attach to the next user message and clear after send, and image support is currently limited to URL or `data:image/` payload strings.
- Updated the feature-gap boundary so Skill install/create/marketplace support and complete local image input remain Codex parity gaps rather than implied completed work.
- Added the current integration-validation note: Mechoes sync/reload screenshots live under `docs/references/validation/`, while `tools/validate-godex.ps1` with the Godot 4.6.2 console binary remains the headless smoke gate.

### Follow-up Guidelines

- Keep local Skill management separate from future Skill lifecycle work: install, create/scaffold, package update, and marketplace browsing need their own implementation and docs.
- Do not infer right-rail `progress_items` from implementation lifecycle events; only explicit model/state plan items should render as progress.
- Treat local image input as incomplete until Godex can accept files/clipboard/screenshots, normalize them into model-ready payloads, and show durable thumbnails.

## 2026-06-07 Archive Flow and Transcript Hygiene

### What Happened

- Visual comparison against Codex showed that session-management actions were leaking into the chat transcript as assistant messages, including new-chat readiness and archive/restore status text.
- The archived-conversation entry was also living as a persistent bottom-left sidebar button, while the target UX keeps archive management inside Settings.
- Sidebar rows needed Codex-like hover affordances: default age-only display, hover pin/archive actions, red second-click archive confirmation, and reset on hover exit.

### Changes Made

- Kept local session actions as model events instead of chat messages for thread selection, slash commands, fork, archive, add-context, and compaction bookkeeping.
- Added hover-only sidebar pin/archive buttons, archive confirmation state, and a top overlay notice with a blue Settings link after archive.
- Moved archived conversations into the Settings rail with search, delete, and `取消归档` restore actions.
- Added state support for deleting archived sessions and smoke coverage for empty transcripts, hidden session-management status text, archive search/restore/delete, and hover confirmation behavior.

### Follow-up Guidelines

- Session management, navigation, and local bookkeeping should live in state events, sidebars, toasts, settings pages, or Automation summaries, not in the main chat transcript.
- Chat rows should represent user prompts, assistant responses, failures that need user attention, and meaningful tool/command/file actions.
- Future history work should extend the Settings archive page rather than reintroducing a bottom-left archived-chat shortcut.

## 2026-06-07 User Message Bubbles and Child Session Foundation

### What Happened

- A Codex desktop comparison showed user prompts as right-aligned bubbles, while Godex still rendered user messages in the same left-side transcript flow as assistant text.
- The existing sub-agent work had durable task records, notifications, and edges, but it still lacked a small session-owned child-thread boundary that future real workers can attach to.
- A read-only Codex source pass also confirmed that Godex should track missing Codex-native base tools separately from the UI parity work.

### Changes Made

- Rendered user chat messages as right-aligned `UserMessageBubble` rows with a leading expanding spacer, while assistant messages keep the transparent continuous transcript flow.
- Kept streaming assistant updates compatible with the new row structure by resolving the message content box by node name instead of assuming the first child is the content container.
- Added `start_subagent_child_session()`, `complete_subagent_child_session()`, and `fail_subagent_child_session()` so local child conversations can be created, linked to parent tasks, and resolved through worker notifications.
- Added smoke coverage for user-bubble alignment, assistant row separation, child-session creation, prompt persistence, parent task updates, and closed child edges.

### Follow-up Guidelines

- Keep user messages visually distinct, but do not turn assistant/tool/command rows into stacked cards; the main transcript should still read as one continuous Codex-style conversation.
- Treat the child-session helpers as a state foundation only. Real external workers still need isolated execution, streaming status, cancellation propagation, and recovery before this can be called a full sub-agent runner.
- The next base-tool milestone should add a preview-first Codex-style patch or command protocol with approval and audit records before attempting real filesystem writes.
- Godot .NET MCP validation would be stronger with focused scene-subtree text extraction and control geometry assertions, because screenshot review catches the layout but not the exact spacer/bubble contract.

## 2026-06-07 Subagent Worker Notifications and Edges

### What Happened

- The previous sub-agent slice made task cards cancellable and handoff-ready, but worker completion still had no durable notification channel.
- A reference pass showed that Codex keeps parent-child thread topology separate from task display state, while worker-style coordinators send compact completion/failure/killed notices.
- The next safe slice was to persist notifications and edges before launching any external worker process.

### Changes Made

- Added session-owned sub-agent worker notifications that update matching task status, result, error, child-thread metadata, and transcript evidence.
- Added session-owned parent-child edge records with open/closed status, direct-child queries, filtered descendant traversal, Automation summaries, and restore coverage.
- Rendered notification and edge lifecycle rows in the conversation information stream so topology changes remain visible after a UI rebuild.
- Extended smoke coverage for completed, running, and killed worker notices, edge traversal, persistence, and Automation rows.

### Follow-up Guidelines

- Future external worker launch code should report lifecycle through `record_subagent_notification()` and `upsert_subagent_edge()` instead of writing UI rows directly.
- Keep edge status coarse until real workers exist; open/closed is enough for traversal and prevents task-status vocabulary from leaking into topology logic.
- The next milestone can focus on isolated execution contexts, worker cancellation propagation, and recovery after failed or killed workers.

## 2026-06-07 Subagent Lifecycle Actions

### What Happened

- Godex already recorded sub-agent task cards in session state, but they were still mostly static audit rows.
- Codex reference material models child agents as lifecycle records with status and close/open transitions, while Claude-style coordinator flows return worker notifications with completed/failed/killed outcomes.
- The safest next step was not to launch real external workers yet, but to make cancellation and result handoff visible, persistent, and testable through the same state boundary a future runner will update.

### Changes Made

- Added state-owned sub-agent cancellation and result-handoff helpers on top of the existing session task records.
- Added next-action selectors for the newest cancellable and handoff-ready sub-agent tasks.
- Exposed first-stage Automation buttons for cancelling a sub-agent task and handing off the newest finished result.
- Extended right-inspector, transcript, Automation, and restore smoke coverage so cancellation source and handoff summary remain visible after session reload.

### Follow-up Guidelines

- Keep `GodexState` as the authority for sub-agent lifecycle metadata; a future runner should update these records instead of adding a second task store.
- Real parallel execution still needs isolated worker sessions or worktrees, parent/child edges, notifications, and recovery after failed or killed workers.
- Godot .NET MCP validation would be stronger with focused live-editor button activation evidence for Automation action rows, especially once those actions control real external workers.

## 2026-06-07 Approved Short Command Runner

### What Happened

- Godex already had the command request state machine, approval checkpoints, command fingerprints, blocked-command filtering, transcript rows, and fake-runner smoke coverage, but the Automation execute action still stopped at `runner unavailable`.
- A parallel read-only reference pass found Codex-rs keeps approval policy and process execution as separate layers: `ExecPolicyManager` decides skip/approval/forbidden, while `UnifiedExecProcessManager` owns process lifecycle, output collection, and termination. Claude Code follows a similar split between Bash permissions and shell execution.
- Godot 4.6 does not expose a GDScript `OS.set_process_working_dir()` API, so changing the editor process cwd was the wrong approach for a local runner.

### Changes Made

- Kept `GodexState.execute_command_run_with_runner()` as the execution boundary and changed `execute_next_approved_command_run()` to accept an optional supplied runner.
- Added a first-stage controller runner that executes approved short PowerShell, pwsh, or cmd commands through Godot `OS.execute` after existing approval, fingerprint, safety, and project-local cwd checks pass.
- Wrapped project-local working directories inside shell commands (`Set-Location -LiteralPath ...; ...` or `cd /d ... && ...`) instead of mutating the Godot editor process cwd.
- Added smoke coverage for optional runner execution, PowerShell/cmd argv construction, unsupported-shell rejection, and `res://` cwd wrapping.

### Follow-up Guidelines

- Treat this runner as a short-command bridge, not a full Codex terminal. `OS.execute` is synchronous, merges stderr into captured output with `read_stderr=true`, and cannot kill a running process tree.
- The next command milestone should introduce a dedicated process manager: process IDs, hard timeout enforcement, cancel/terminate, separated stdout/stderr streaming, output caps, and background session polling.
- Godot .NET MCP could help future validation by exposing safer editor-process command-run probes or long-running process telemetry, but Godex should still preserve its own approval and audit state.

## 2026-06-07 Right Inspector Source Semantics

### What Happened

- The right inspector had already separated `输出` from logs and assistant prose, but `来源` still mixed several non-source records: file/context attachments, project-summary context, OpenAI transport audits, and local replay fixtures.
- The Codex progress reference shows sources as a compact row of actual external tool/service origins, while model request lifecycle belongs in the conversation information stream or progress status.

### Changes Made

- Narrowed right-inspector source chips to invoked external sources: MCP context/tool execution events and future web/search events.
- Kept OpenAI request/transport/response diagnostics in transcript and progress rows, not source chips.
- Added smoke coverage so project-summary context, file-context events, OpenAI transport audits, and local replay fixtures cannot repopulate the source row.

### Follow-up Guidelines

- Keep generated artifacts and changed files in `输出`; keep request lifecycle state in progress/transcript; keep actual external tool/service sources in `来源`.
- When adding attachments or provider diagnostics, add a dedicated context/progress surface instead of reusing source chips unless a real external tool was invoked.

## 2026-06-07 Direct OpenAI-Compatible Chat Closure

### What Happened

- Manual and user-provided evidence showed the Yuren OpenAI-compatible base URLs and `YUREN_API_KEY` can return valid Chat Completions responses, but the live Godex conversation could still stop at a visible provider failure instead of a final assistant answer.
- The remaining weak boundary was the editor-side streaming lifecycle. Godex was still trying the stream client first for explicit OpenAI-compatible Chat Completions providers, even though a direct non-stream editor request is simpler and closer to the successful probe shape.
- The first direct HTTP implementation started the request, but the completion callback still only treated stream fallback and plain compatibility fallback as placeholder-updating paths. That meant a direct response could fail to share the same final-message and audit closure contract.

### Changes Made

- Explicit non-OpenAI Chat Completions providers now prefer a direct non-stream `HTTPRequest` on the first send. The request body removes `stream=true` but keeps model, messages, tool schemas, and reasoning effort.
- OpenAI request snapshots now carry their provider ID, so approval, retry, and continuation dispatch use the queued request's provider instead of whatever provider is currently selected in the settings UI.
- The completion callback now recognizes `stage=non_stream_direct`, updates the existing streaming assistant placeholder, stops the Agent loop with `final_model_response`, and records `openai_transport.stream=false`.
- Progress and transcript labels now expose direct non-stream request stages instead of folding them into a generic request row.
- Added headless smoke coverage for payload stripping, OpenAI-vs-compatible routing, final placeholder replacement, Agent loop stop state, transport cleanup, response events, and `non_stream_direct` audit metadata.

### Follow-up Guidelines

- For future compatible-provider failures, compare `provider_probe`, `non_stream_direct`, `stream_fallback`, and `compatibility_fallback` stages before changing provider defaults or model names.
- Keep Yuren as an explicit non-default provider. The recommended `https://yurenapi.cn/v1` and valid alternate `https://yurenapi.com/v1` should remain user-local settings backed by `YUREN_API_KEY`, not repository defaults.
- Godot .NET MCP visual verification still needs better popover/window capture coverage; until that is improved, pair semantic status checks with user-provided screenshots for floating UI issues.

## 2026-06-07 OpenAI-Compatible Endpoint Triage

### What Happened

- Real user testing still showed a failed conversation loop after a prompt reached the provider request boundary.
- The user-provided Yuren settings are valid OpenAI-compatible settings, but Godex could still carry an older `responses` API mode in persisted state, which resolved the request to `/v1/responses`.
- A manual Windows PowerShell probe confirmed `YUREN_API_KEY` existed, but `Invoke-WebRequest` threw `NullReferenceException` for both Yuren base URLs before returning a usable HTTP status. That tool result is not reliable enough to judge provider health.

### Changes Made

- Added provider-level API mode defaults to the catalog: the built-in OpenAI provider stays on `responses`, while OpenAI-compatible providers, including Yuren, default to `chat_completions`.
- Migrated explicit Yuren settings to `chat_completions` even when old persisted settings stored `responses`, preserving `.cn` as the recommended base URL and `.com` as an accepted alternate.
- Added smoke coverage for Yuren API mode defaults, endpoint resolution to `/v1/chat/completions`, legacy setting migration, and alternate base URL preservation.

### Follow-up Guidelines

- For OpenAI-compatible providers, first verify `api_config_snapshot().endpoint` before debugging stream parsing or model response handling.
- Do not use PowerShell `Invoke-WebRequest` failures alone as provider evidence on this Windows host; if it fails before HTTP status capture, treat it as a local transport probe failure and use Godex/Godot HTTP diagnostics or another approved HTTP client.
- Keep real API keys in environment variables or `user://godex/settings.json`; docs and tests must use placeholders only.

## 2026-06-06 Responses Previous Response Continuation

### What Happened

- The local loop closure audit showed that Godex could parse tool calls and build a continuation, but the Responses continuation payload still replayed the full input history even when the provider had returned a stored response ID.
- The Codex reference loop keeps function-call outputs tied to the original call and can continue from the previous provider response boundary; Godex needed the same response-id handoff before deeper real-chat debugging would be trustworthy.
- Without preserving the response ID, provider-compatible endpoints may receive duplicated context or fail to associate `function_call_output` with the stored function call.

### Changes Made

- Preserved Responses `id` values from full responses and `response.completed` stream payloads, then attached them to parsed tool-call records.
- Stored `response_id` on pending tool-call model events and propagated it into `previous_response_id` for ready tool-result continuation requests.
- Changed Responses continuation payloads to send only `function_call_output` when `previous_response_id` is available, while retaining the older full compatibility payload when no provider response ID exists.
- Cached streaming response IDs from `response.created` and other response-bearing stream events, then backfilled already accumulated tool-call fragments before final recording.
- Added safe transport audit metadata for sent continuation requests, including source, tool-call ID, previous response ID, input count, and payload fingerprint without storing raw request bodies in visible events.
- Added headless smoke coverage for builder payload shape, parser response-id retention, streamed completed/created payload IDs, late stream response-id backfill, pending continuation storage, and Agent-level continuation payload construction.

### Follow-up Guidelines

- For future live "tool called but no answer" bugs, inspect the recorded `openai_response.response_id`, the tool-call event `response_id`, and the continuation payload `previous_response_id` before blaming MCP execution.
- After a pending continuation is sent and cleared, inspect `openai_transport.source=tool_result_continuation`, `tool_call_id`, `previous_response_id`, `payload_input_count`, and `payload_fingerprint` to correlate the request with the originating tool call.
- If a provider returns function calls without a response ID, keep the compatibility replay path visible in audit records instead of assuming provider-side storage exists.
- The next live validation should compare the actual Yuren/OpenAI-compatible continuation request body against the same smoke contract, with API keys masked and persisted settings kept outside git.

## 2026-06-06 Assisted Tool Continuation Loop Closure

### What Happened

- User testing showed a real chat could reach the tool-call phase but still appear to have no returned result, meaning the Agent loop did not visibly close after the external tool result.
- The continuation boundary built a ready OpenAI tool-result request, but auto-send was limited to `完全访问权限`. This contradicted the first-turn send behavior where `替我审批` already allows assisted automatic sending, so the loop could silently wait for manual continuation in the common assisted mode.
- Streaming parser review found two provider-compatibility risks in the same area: Responses `response.completed` can carry the final `response.output`, and Responses `response.output_item.added` is only partial metadata that should not become an executable pending tool call.
- Controller busy checks still looked at the legacy `HTTPRequest` member while the live OpenAI path now uses the `HTTPClient` stream client and timer, so continuation retry/advance logic could misread the current transport state.

### Changes Made

- Changed tool-result continuation gating so `替我审批` and `完全访问权限` can auto-send ready continuations, while only `请求批准` stops for explicit OpenAI send review.
- Changed stream and continuation busy checks to use `_is_openai_busy()` so the controller reads the real active transport surface.
- Extended Responses stream parsing so `response.completed.response.output` can provide final assistant text and completed function calls.
- Changed `response.output_item.added` handling into partial tool metadata for live preview only; final pending tool records still come from completed item or completed response payloads.
- Added headless smoke coverage for assisted-mode continuation auto-send, request-approval blocking, completed response payload extraction, and partial tool metadata handling.

### Follow-up Guidelines

- For future "no return" reports after MCP tool execution, inspect the continuation status first: ready continuation, approval mode, active OpenAI busy state, and whether the right progress row says blocked, pending, or retryable.
- Keep approval semantics consistent across first-turn sends, retries, and tool-result continuations. `请求批准` is the explicit review gate; assisted modes should not strand safe continuation work without a visible approval checkpoint.
- Continue tightening Responses continuation fidelity next: preserve provider response IDs where available, and compare the generated continuation payload with Codex's function-call-output loop contract before adding more tools.
- When validating Godot editor UI flows through MCP, prefer semantic lifecycle/status tools first. Coordinate clicks into Project Settings are acceptable only as a last-resort probe and must be followed by semantic status checks.

## 2026-06-06 Yuren Provider Local Setting Verification

### What Happened

- The preserved Yuren provider preset already preferred `https://yurenapi.cn/v1`, but the Mechoes local `user://godex/settings.json` still used the valid alternate `https://yurenapi.com/v1`.
- The user clarified that both `.cn` and `.com` base URLs are correct, with `.cn` preferred.
- Reload testing showed that the UI needed to distinguish a recommended default from a valid persisted alternate endpoint instead of treating the alternate as a stale setting.

### Changes Made

- Updated the preserved reference JSON so future development sees `.cn` as the primary URL and `.com` as an alternate valid URL.
- Changed Yuren settings normalization so `.com` remains compatible and stays persisted when explicitly selected, while invalid or empty Yuren base URLs fall back to the preferred `.cn` endpoint.

### Follow-up Guidelines

- Keep Yuren as a non-default provider preset; selecting it for development must remain an explicit local/user setting.
- When inspecting `user://godex/settings.json`, print only masked or boolean key status, never raw `api_key` values.
- Treat `.cn` as the recommended default and `.com` as accepted compatibility that may remain in persisted user settings. Do not rewrite a valid alternate URL merely to make screenshots show the preferred endpoint.

## 2026-06-06 OpenAI No-Return Visibility

### What Happened

- User testing showed that "no returned result" needs a more visible first diagnostic point than checking Automation rows or raw stream trace names.
- `输出` must remain generated artifacts and changed files, while `来源` must remain invoked external tools. Request lifecycle state therefore should not be mixed into either section.
- The existing stream trace already had enough data to explain residual JSON recovery and salvaged disconnects, but the transcript surfaced raw event identifiers.

### Changes Made

- Added explicit OpenAI transport diagnostics in model events while keeping the right-inspector `进度` section reserved for model-controlled short-term plan/memory items.
- Kept idle chats clean: no OpenAI status row is created when there is no live or recoverable request state.
- Translated residual stream trace events such as `non_stream_response` and `stream.salvaged_disconnect` into readable conversation information-stream labels.

### Follow-up Guidelines

- For future "no return" reports, first inspect the right progress row: it should say whether the turn is actively requesting, waiting for approval, waiting for continuation, blocked, or retryable.
- Keep request lifecycle status out of `输出` and `来源`; those sections have narrower Codex-compatible meanings.
- Prefer user-readable stream trace labels in chat while preserving raw event data in state for tests and audits.

## 2026-06-06 OpenAI Stream Residual Finalization

### What Happened

- User testing reported that a real conversation could send but produce no visible return result.
- The current transport always requested streaming and waited for a normal completion sentinel. That was too strict for OpenAI-compatible providers that may close the socket with a trailing SSE fragment, or return a complete non-stream JSON response even when the request includes `stream=true`.
- Treating every disconnect as success would hide real network failures, while treating every missing completion sentinel as failure could strand a valid assistant response in the buffer.

### Changes Made

- Added `GodexOpenAIExecutionService.parse_stream_residual()` so trailing SSE lines and complete Responses/Chat JSON bodies are parsed through the same OpenAI execution boundary used by normal responses.
- Added controller fallback finalization before `stream_timeout` or `stream_disconnected` becomes an error. The fallback only succeeds when the residual buffer parses cleanly or when the stream already accumulated visible text/tool-call state.
- Routed non-stream residual JSON through `GodexAgentService.handle_model_response()` so assistant text, tool-call records, OpenAI response events, transcript rows, and Agent-loop advancement remain consistent with normal provider responses.

### Follow-up Guidelines

- When a live chat appears to have no result, inspect stream trace rows first: `non_stream_response`, trailing SSE events, `stream.salvaged_disconnect`, or a hard `stream_disconnected` failure should identify the boundary.
- Do not weaken disconnect handling into blanket success. Only parseable residual data or already accumulated text/tool calls may close a turn; empty buffers should stay retryable failures.
- Keep provider compatibility fixes in `GodexOpenAIExecutionService` where possible, then let the UI apply the normalized result.

## 2026-06-06 Local Tool-Result Continuation Replay

### What Happened

- User testing still needed a sharper way to distinguish "the model did not return" from "the tool result did not build a continuation" or "the continuation result did not render back into chat."
- Read-only Codex reference review found the matching loop contract in `codex-rs/core/src/session/turn.rs`: a turn continues when the model requests function calls, executes tools, and sends tool outputs back to the model; the turn completes only after a final assistant message.
- The same reference path normalizes MCP tool output into `FunctionCallOutput` tied to the original call ID, and Codex thread history rebuilds MCP tool begin/end events as replayable items with status, arguments, result, error, and duration.

### Changes Made

- Added `GodexAgentService.replay_pending_tool_result_continuation()` as a local diagnostic boundary that requires a ready pending continuation, replays a deterministic final Responses-compatible assistant message through the existing parser, and clears the pending continuation slot.
- Added a Codex-style Automation action `本地续跑回放` next to `发送续跑请求`; it is enabled only for ready continuation requests and its tooltip states that it does not send an external OpenAI request.
- Tagged replay audit events with `source=local_tool_result_continuation_replay`, recorded an Agent loop step, persisted the final assistant message with the active turn ID, and stopped the loop with `local_continuation_replay_final`.
- Updated the Yuren provider preset to prefer `https://yurenapi.cn/v1` while retaining `https://yurenapi.com/v1` as an explicitly accepted alternate base URL; the provider remains non-default.

### Follow-up Guidelines

- For "no returned result" reports, first check whether the tool result reached `openai_continuation_request`, then whether a ready pending continuation exists, then whether local continuation replay can produce a final assistant message, and only then focus on provider/network behavior.
- Keep local replay actions clearly labeled as local diagnostics. They prove parser, state, transcript, and loop closure behavior; they must not be presented as real provider responses.
- Continue aligning loop semantics with Codex's function-call-output contract instead of inventing Godex-specific response formats.

## 2026-06-06 Project Settings Control and Floating Window Capture

### What Happened

- User asked to verify the updated Godot .NET MCP editor-control path by opening the Godot Project Settings window, switching to the Plugins tab, disabling Godex, then enabling Godex again.
- The high-level plugin lifecycle tool was reliable: `system_editor_plugin_control` could disable and enable `godex`, and `user_godex_plugin_control.activate_main_screen` made the Godex main screen visible again.
- The menu path was less reliable. `system_editor_control.list_menus` returned no top menus and `open_menu("项目")` / `open_menu("Project")` could not find the menu. A low-level `click_control` on the editor `MenuBar` plus `select_popup_menu_item("Project Settings...")` opened Project Settings, but this depended on a local coordinate inside the menu bar.
- `capture_editor` did not include the floating Project Settings window even while the window was visible. Capturing specific controls inside the window worked for the tab container and Plugins tab, while the floating window root itself did not expose a usable global rect.

### Changes Made

- Recorded the verified lifecycle route: use `system_editor_plugin_control` for plugin enable/disable state and `user_godex_plugin_control.activate_main_screen` for Godex main-screen visibility checks.
- Treated coordinate clicks as a last-resort fallback instead of a preferred automation path.
- Added a root `SUGGESTION.md` entry asking Godot .NET MCP to provide semantic top-menu activation, robust floating editor-window capture, and Project Settings / Plugins helpers.

### Follow-up Guidelines

- Prefer semantic MCP tools over coordinate clicks whenever the target is a known editor concept such as plugin lifecycle, main screen activation, Project Settings tabs, or popup menu items.
- If a coordinate click is unavoidable, immediately verify the resulting editor state through a semantic read, such as visible popup items, active tab path, plugin status, editor logs, or a control-specific capture.
- Do not rely on `capture_editor` as proof for floating dialog state until Godot .NET MCP explicitly supports floating window capture; use `capture_control` on visible child controls and record the limitation.

## 2026-06-06 OpenAI Stream Trace and Completion Semantics

### What Happened

- User testing still saw a real chat turn produce no useful returned result after the transport crash was fixed.
- Read-only review found two closure hazards: a disconnected HTTP stream could be treated as success before a completion sentinel, and Responses `response.output_item.done` was being treated as full response completion even though it can be only one output item.
- The hand-written `HTTPClient` streaming path also lacked idle/total timeout guards, so a stalled provider could keep the composer in a running state indefinitely.

### Changes Made

- Changed Responses stream parsing so only `response.completed` and `[DONE]` complete the whole stream; `response.output_item.done` now only contributes completed tool-call data.
- Changed stream disconnect handling so a connection that closes before a completion sentinel becomes a retryable `stream_disconnected` failure instead of a false success.
- Added idle and total timeout guards, non-2xx stream HTTP failure handling, and readable error hints for timeout, HTTP status, and provider compatibility failures.
- Added redacted `stream_trace` model events plus transport counters for event count, text delta length, tool delta count, last event type, completion sentinel state, and poll ticks.
- Added OpenAI and local model replay source chips so the right inspector shows actual external request sources without mixing local replay into network sources.

### Follow-up Guidelines

- Never use item-level Responses events as whole-turn completion unless the API event explicitly says the response is complete.
- Treat a stream disconnect without completion as a provider/network failure and preserve retry state.
- Keep stream traces metadata-only: event type, lengths, tool names, and status are useful; raw SSE bodies and raw tool arguments should stay out of visible audit rows.

## 2026-06-06 OpenAI Streaming Closure Guard

### What Happened

- User testing showed that a real chat turn could start but never produce a returned assistant result, so the Agent loop did not close visibly.
- Godot .NET MCP editor logs exposed the actual failure: the streaming transport called `HTTPClient.get_available_bytes()`, which does not exist on Godot 4.6's `HTTPClient`.
- Because the runtime exception happened inside the stream poll loop, the request could not reach either the final response handler or the normalized error handler.

### Changes Made

- Reworked the SSE body reader to consume `read_response_body_chunk()` directly while the client is in `STATUS_BODY`.
- Added a small per-poll chunk guard and null/completion checks so a temporary empty chunk waits for the next poll while completed streams can still exit cleanly.
- Added readable stream-poll error messages so connection failures keep the raw code for audit while telling the user to check API Base URL, network/proxy, or provider reachability.
- Added headless smoke coverage that rejects the unavailable `get_available_bytes` API in the controller source.

### Follow-up Guidelines

- Treat "no response" reports as transport-state problems until logs prove otherwise; first check editor output and runtime diagnostics before redesigning UI state.
- Keep Godot API compatibility checks near the smoke test contracts for live transport code, because plugin startup can pass while runtime-only stream paths still fail.
- The next streaming iteration should add a redacted trace panel for event types, final completion, and normalized errors so users can distinguish pending network, API failure, and parser failure states.

## 2026-06-06 Sidebar Hover and Settings Entry Guard

### What Happened

- User review showed that multiple sidebar conversation rows could remain visually highlighted after the pointer moved away, which made hover state look like persistent selection.
- The settings view had direct-method smoke coverage, but not coverage for the real sidebar settings button signal, so a broken entry path could slip past local validation.

### Changes Made

- Added centralized thread-hover clearing so entering a new conversation row clears stale hover backgrounds from other rows, and leaving the thread list clears every non-selected hover affordance.
- Kept the active conversation highlight independent from transient hover state.
- Hardened `_show_settings()` to address the actual `SettingsPanel` node directly and added smoke coverage for the real sidebar settings button signal after binding controller events.

### Follow-up Guidelines

- Treat sidebar hover as a single-list state, not as independent row memory; selected rows may stay highlighted, hovered rows must clear on list exit.
- Keep Codex-style navigation tests on real button signals when possible, not only private controller methods, so scene path drift and disconnected signals are caught early.
- Continue avoiding extra left-nav items or fake right-inspector sections; archived conversations, outputs, and sources should stay within their already defined Codex-aligned surfaces.

## 2026-06-05 Settings Rail Polish and Empty Search

### What Happened

- After category filtering landed, the settings view still risked feeling under-specified because category rows were plain text and a search miss could leave the main column visually empty.
- Disabled categories also needed their icon state to read as unavailable rather than broken or unstyled.

### Changes Made

- Added editor-theme icons to settings rail categories and painted selected, hover, pressed, and disabled icon colors through the same button styling path as the text.
- Added a dedicated `SettingsNoResults` node so search misses show an explicit empty state instead of a blank settings workspace.
- Extended smoke coverage for no-result search behavior and for the icon/disabled styling contract.

### Follow-up Guidelines

- Keep settings search feedback visible and state-owned; do not replace empty results with an assistant message or a transient toast.
- Future settings categories should ship with icon candidates, disabled styling, section registry terms, and a no-results test update in the same change.

## 2026-06-05 Settings Category and Search Interaction

### What Happened

- User review showed that the settings page still had Codex-like visual categories without category behavior, which made the page feel like a formatted form rather than a real settings workspace.
- The `外观` category was especially risky because it looked clickable even though theme preferences are not implemented yet.
- Search existed as a field but did not filter any settings, so it could not support the Codex desktop settings workflow.

### Changes Made

- Wired the settings rail categories to real section filtering for general, configuration, MCP, Skills, and command-line settings.
- Added settings search filtering across setting labels and help terms, with clearing search restoring the active category.
- Disabled the unimplemented appearance category in both the scene and controller styling so it no longer presents a fake entry point.
- Extended smoke coverage for category navigation, search filtering, disabled appearance state, and return-to-chat restoration.

### Follow-up Guidelines

- Do not add a settings rail entry unless it either opens real settings or is clearly disabled with hover help.
- When adding future sections, update the controller section registry and smoke tests together so category/search behavior stays explicit.
- Appearance settings should become enabled only after there is a real theme preference model and persistence contract.

## 2026-06-05 MCP Server Row Settings Contract

### What Happened

- After the settings workspace format was corrected, the MCP settings still looked like a loose endpoint form plus a separate permission checkbox.
- Codex desktop presents external integrations as manageable rows with status and row actions, while Godex needs to keep Godot .NET MCP as a normal external tool source rather than inventing a separate editor-tool UI.
- Multi-server management is not ready yet, so the implementation needed a real row contract without pretending that add-server flows already exist.

### Changes Made

- Added `GodexState.mcp_server_row()` and exposed both `mcp_server_row` and `mcp_server_rows` in `to_model()` as a derived view of the existing endpoint, enabled flag, discovery status, error text, timestamp, and discovered tool count.
- Rebuilt the settings MCP area as a single `Godot .NET MCP` server row with status dot, endpoint field, enable switch, refresh-tools action, edit affordance, and a disabled add-server placeholder.
- Connected the refresh action to the existing `tools/list` discovery path, so settings shows the same real discovery status as `/mcp`.
- Extended smoke coverage for the server-row scene nodes, hover help, disabled add-server placeholder, and state-model synchronization.

### Follow-up Guidelines

- Keep endpoint persistence single-source until multi-server state is intentionally designed; `mcp_server_rows` is currently a UI/model projection, not a separate persisted list.
- `来源` should continue to mean invoked external tools/providers, while the MCP settings row configures those sources.
- When multi-server support starts, first introduce durable IDs and persistence migration, then enable the add-server row.

## 2026-06-05 Settings Workspace Format

### What Happened

- User screenshot review showed that Godex settings still rendered as a long stacked form inside the chat workbench, while Codex desktop uses a dedicated settings mode with its own category rail and centered content column.
- The old implementation also left chat chrome visually active around settings, making the page feel like another conversation panel instead of an application-level settings workspace.
- Existing controller and smoke tests had hard-coded the old `SettingsBox/ProviderSettings/*` paths, so a layout correction needed to update the scene, controller bindings, and validation together.

### Changes Made

- Rebuilt `SettingsPanel` into a Codex-style settings shell with a left settings rail, `返回应用` action, category rows, centered `SettingsScroll`, grouped cards, and row-aligned setting controls.
- Kept the existing provider/API/MCP/Skill/compression/command state wiring while moving controls into card rows.
- Hid composer, right inspector, bottom drawer, and change-review chrome while settings mode is active.
- Extended headless smoke coverage for the dedicated settings rail, constrained content column, row-style provider controls, and settings-mode chrome isolation.
- Mechoes screenshot validation caught two visual issues after the first headless pass: the settings page still shared the chat sidebar/header, and the content column was left-biased inside the remaining space. The layout now hides chat chrome in settings mode and centers the settings content with explicit spacer controls.

### Follow-up Guidelines

- Continue treating settings as a workspace with navigation categories, not as a chat message or loose form.
- The MCP setting now has a Codex-style server row, but multi-server persistence and transport-specific forms are still future work.
- Godot .NET MCP validation should include both static scene paths and live screenshots for settings, because layout regressions are easy to miss in pure state tests.
- When visually validating Godex inside Mechoes, first activate the Godex main screen with the dedicated helper and prefer `activate_control` for Godex scene buttons; a raw click can leave the editor focused on nearby Godot/MCP UI and produce a misleading screenshot.

## 2026-06-05 Output Artifact State Contract

### What Happened

- User review clarified that `输出` should not mean stdout, model logs, or MCP response text. It should represent artifacts that the Agent produced or changed.
- The UI already projected changed-file summaries into the right inspector, but that behavior lived mostly in controller rendering. That made it too easy for future work to bypass persistence or accidentally mix logs into the artifact list.
- The next diff-review workbench needs a stable state boundary before it can grow real diff panes, undo flows, or patch application.

### Changes Made

- Added `GodexState.record_output_artifact()` and persisted `outputs` through session save/restore.
- Made `set_change_review_summary()` publish each changed file as a `source=change_review` file artifact, and made clearing the review remove only those artifacts while preserving unrelated manual artifacts.
- Added controller-side artifact deduplication by source/path so state-owned artifacts and legacy change-review projections do not render duplicate rows.
- Extended headless smoke coverage for artifact persistence, cleanup boundaries, and output-row deduplication.

### Follow-up Guidelines

- Treat `outputs` as the durable artifact contract for the right inspector and bottom drawer. Do not infer output rows from assistant text, command output, raw MCP payloads, or internal model events.
- Future diff panes should consume the same artifact/review state boundary instead of adding another parallel file list.
- A useful Godot .NET MCP improvement would be a first-class custom main-screen activation action; visual validation currently still needs a local helper for reliable Godex main-screen screenshots.

## 2026-06-05 Project Rail and Conversation Hover Polish

### What Happened

- User screenshot review clarified that the left rail should show the actual Godot project name in both the `项目` group and the empty-chat prompt, not a generic `Godot Project` placeholder.
- The same screenshots showed that the currently open conversation should read as a full rounded highlighted row, and hover should lift the corresponding row with the same capsule background.
- The previous row implementation painted only the title button, so the highlight did not cover the whole conversation row and row actions could affect spacing.

### Changes Made

- Added `GodexState` project-name synchronization from Godot `ProjectSettings` and successful MCP project-state/tool result payloads, including a `project_path` folder-name fallback.
- Reworked sidebar thread rows into full-width `PanelContainer` capsules with active and hover backgrounds, stable row node names, separate age labels, and reserved trailing action affordance width.
- Updated headless smoke coverage for MCP project-name sync, fallback path parsing, active row rounded highlighting, hover row highlighting, and non-jittering hidden action affordances.

### Follow-up Guidelines

- Keep `active_project` as state-owned data; UI should render it rather than guessing from hard-coded scene text.
- Preserve row width stability when adding future pin/archive/fork hover icons. Hidden affordances should reserve space or otherwise avoid shifting conversation titles.
- Godot .NET MCP was sufficient for local script validation here. Richer editor hover simulation would still help future visual QA for Codex-like sidebar interactions.

## 2026-06-05 Right Inspector Semantics Correction

### What Happened

- The right inspector was incorrectly extended with a separate recent-activity section even though the Codex reference side panel groups progress, generated artifacts, sub-agents, and sources.
- `输出` was also mis-modeled as tool/model/command output. The Codex app documentation describes the task sidebar as surfacing plan, sources, generated artifacts, and task summary, which means `输出` should represent produced artifacts rather than logs.
- User screenshot review clarified that `来源` refers to invoked external tools or context providers such as MCP and web search.
- A follow-up pass also clarified that local probe bookkeeping is not itself a source. It can create a tool call, but the source chip should come from the invoked external tool/provider record.

### Changes Made

- Removed `TimelineSection` / `TimelineList` from the Godex right inspector and deleted the related controller projection code.
- Changed right-inspector `输出` so it lists generated artifacts or changed files from `change_review_summary`, while keeping assistant prose, tool events, command stdout/stderr, and model events out of that section.
- Changed right-inspector `来源` so it emits deduplicated external tool/provider chips such as `godot-dotnet-mcp` instead of internal event sources, local probe bookkeeping, local replay labels, or file-context rows.
- Updated smoke coverage to reject the separate recent-activity section and to verify artifact/source semantics.

### Follow-up Guidelines

- Keep raw execution history in transcript disclosures, command details, or a future dedicated trace view, not in the Codex-style right inspector.
- Do not add a new right-inspector section from model events unless there is a matching Codex reference concept and user-visible semantics are clear.
- Treat official Codex docs plus user screenshots as the product boundary before adding UI concepts that only sound plausible.

## 2026-06-05 Local Model Replay

### What Happened

- The local MCP probe could validate the Godot MCP execution leg, but Godex still needed an API-key-free way to prove that OpenAI-compatible response parsing produces normal pending tool calls.
- Live OpenAI sends already carry transport risk, credential requirements, retry state, and approval gates, so a deterministic fixture was the safest next step for parser, transcript, and inspector validation.
- Product review also flagged that UI rows should not expose internal fixture IDs such as `mcp_context_tool_call`.

### Changes Made

- Added `GodexAgentService.inject_model_response_replay()` to feed a deterministic Responses API-compatible fixture through the existing OpenAI execution parser.
- Recorded replayed transport and response events with `source=local_model_replay`, `status=replayed`, and fixture metadata while keeping headers and live request bodies out of transcript and right-inspector projections.
- Added an Automation action labeled `本地模型回放` that returns to chat, appends a visible assistant status message, and leaves a normal pending `godex_mcp_context` tool call for the MCP approval/execution path.
- Labeled replay rows as local replay in the conversation information stream, using user-facing fixture labels instead of implementation IDs.
- Extended headless smoke coverage for the scene node, controller binding, replay parser path, pending tool-call state, transcript metadata, source/output boundaries, and no-network/no-header leakage.

### Follow-up Guidelines

- Keep local replay explicit and deterministic; do not auto-run it when new conversations open or when the main screen refreshes.
- Treat replay as proof of the model parser/tool-call handoff, not as proof of live SSE transport, Chat Completions deltas, or tool-result continuation.
- Godot .NET MCP was sufficient for this validation pass. A future MCP-side improvement would be an editor-safe way to invoke custom main-screen toolbar actions directly by name, which would reduce the need for coordinate-style UI activation during visual checks.

## 2026-06-05 Local MCP Probe Trace

### What Happened

- The Automation probe could already create a pending `godex_mcp_context` tool call, but the surrounding `local_tool_probe` event was not projected into the Codex-style conversation information stream.
- The Automation button still used test-oriented copy, which made the probe feel like fake demo data even though it exercises the real MCP tool-call state boundary.
- Read-only review also highlighted that transcript tool rows could expose more raw argument text than a compact right-inspector source chip should ever reveal.

### Changes Made

- Promoted `local_tool_probe` into a rebuildable transcript item, while keeping source chips tied to the invoked MCP tool/provider records.
- Renamed the visible Automation action to `本地 MCP 探针`, kept it explicit/user-triggered, and returned to chat after creating the probe so MCP screenshots can verify the event flow in the main conversation surface.
- Added right-inspector source chips for the MCP tool call created by the local probe, without treating probe bookkeeping as a source.
- Began a bounded local Agent loop slice when the probe is created so probe, tool-call, dispatch, and result events share a coherent turn.
- Replaced raw tool argument transcript details with safe-key summaries and redaction, including partial streamed tool-call previews.
- Live MCP validation caught a real view-switch bug: setting `_active_view = "chat"` was not enough to hide the Automation panel, so the probe action now uses `_show_view("chat")` before rebuilding the model.
- A follow-up live execution through `执行下个工具` reached the expected tool-result continuation boundary and stopped at `missing_api_key`, confirming the Godot MCP leg can feed the next OpenAI request without pretending an external model response occurred.

### Follow-up Guidelines

- Keep probes explicit; do not generate them from `_ready`, `setup`, main-screen activation, `_apply_model`, or ordinary new conversations.
- Treat the local MCP probe as proof of the Godot MCP execution leg, not as proof of the external OpenAI streaming leg.
- Continue keeping right-inspector source chips white-listed and compact; raw payloads, headers, MCP bodies, tool arguments, and command output should stay out of labels and tooltips.

## 2026-06-05 Event-Driven Right Inspector

### What Happened

- The right progress surface still carried static demo progress/output/tool rows, which made new conversations look busy before any real Agent events existed.
- The transcript could rebuild messages, stream steps, tools, and commands, but not the surrounding Agent/MCP/sub-agent/OpenAI lifecycle events that Codex surfaces as compact conversation information rows.
- Headless validation exposed a fragile UI traversal issue: repeated stream-step rows rendered correctly, but duplicate Godot node names were not stable enough for reliable MCP/test inspection.

### Changes Made

- Moved Agent preparation progress, MCP inspection, sub-agent creation, OpenAI transport, and OpenAI response summaries into model-event-backed transcript items.
- Rebuilt the right inspector from real progress, output, sub-agent, and source events, with empty states for outputs/sources and hidden progress/sub-agent sections until events exist.
- Changed the side-panel header toggle to control the floating right inspector without hiding the app navigation sidebar or resizing the transcript column.
- Added stable generated names for repeated `StreamStepRow` controls and validation coverage that rejects legacy right-rail cards or fake initial progress rows.
- Updated the validation script to capture Godot headless stdout/stderr through files so successful runs are not derailed by PowerShell native-command stderr handling.

### Follow-up Guidelines

- Keep the right inspector event-driven; do not repopulate static demo `progress_items`, `outputs`, or tool cards for empty conversations.
- Add future inspector sections through state/model-event projections first, then render them as rebuildable UI rows.
- Prefer stable node names for repeated runtime controls that MCP screenshots, UI traversal, or headless smoke tests need to inspect.

## 2026-06-05 Recommended File Context

### What Happened

- The composer `+` menu intentionally kept file attachments disabled because Godex does not yet have a full attachment model or safe file picker flow.
- The changed-file review strip already contains auditable file paths, so it can provide a narrower first step without reading file contents.

### Changes Made

- Added `GodexState.recommended_context_files()` to derive recommended file rows from `change_review_summary.files`.
- Added `record_file_context(path)` so selecting a file records a `file_context` model event and appends a visible transcript message.
- Enabled the `添加文件` row only when recommended changed files exist, and added per-file rows under the menu.
- Added smoke coverage for disabled file rows with no recommendation, enabled changed-file rows, model-event recording, and visible transcript output.

### Follow-up Guidelines

- Keep this path metadata-only until Godex has explicit file content ingestion, size limits, and approval boundaries.
- Do not use OS file pickers or read arbitrary files from this menu without adding a real attachment/context item model first.

## 2026-06-05 Sidebar Pinned Grouping

### What Happened

- The sidebar could pin sessions, but pinned rows were only marked with a star and still lived in one undifferentiated list.
- Codex-style sidebars use subtle sectioning to make fixed conversations feel intentional without turning group labels into fake sessions.

### Changes Made

- Added render-only `已置顶` and `最近` group labels when both pinned and regular sessions are visible.
- Extracted thread row construction into `_build_thread_row(item)` and kept group labels non-interactive.
- Added smoke coverage for pinned ordering, group labels, archived-session exclusion, and stable row-specific menu targeting.

### Follow-up Guidelines

- Keep grouping out of `GodexState.to_model()` and session persistence; group labels are UI chrome, not data.
- Future grouping variants should avoid adding menu actions to headers.

## 2026-06-05 Archived Conversation Browsing

### What Happened

- Godex could mark sessions as archived, but there was no first-class view to inspect or restore them.
- Reusing normal search would have broken the existing active-history boundary and made archived sessions appear in everyday results.
- After the first restore view landed, the archived list still needed its own filter so long hidden histories remain navigable.

### Changes Made

- Added `GodexState.archived_records()` and `restore_archived_session(thread_id)` so restore first clears `archived` and then selects the session.
- Added a dedicated `ArchivedPanel` and sidebar entry for archived conversations.
- Added `ArchivedResult_<thread_id>` restore rows that return the session to chat and the active sidebar.
- Added an archived-only search field with separate empty-state copy for no archived sessions vs no filter matches.
- Added smoke coverage for archived records, restore semantics, ordinary search isolation, UI restore rows, and filtered empty states.
- Hardened rename, pin, archive, and restore write paths to update stored thread records by index, and made generated thread IDs unique even when multiple sessions are created in the same tick.

### Follow-up Guidelines

- Keep normal search and `/resume` scoped to non-archived sessions unless the user explicitly enters the archived view.
- Future archived actions should use restore-by-ID and avoid selecting an archived session before clearing its archived flag.

## 2026-06-05 Sidebar Thread More Menu

### What Happened

- Godex already supported session rename through `/rename`, but Codex-style thread rows need direct row actions for repeated session management.
- A read-only sub-agent review flagged the main risk: row actions naturally target a specific thread, while several existing state methods operate on the active session.
- The first direct-button pass made fork, rename, and archive discoverable, but it visibly crowded each sidebar row instead of matching Codex's compact row action behavior.

### Changes Made

- Added `rename_session(thread_id, title)` so UI row actions can target a session by ID.
- Replaced separate fork/rename/archive row buttons with one compact `ThreadActionMenu` more button and added pin/unpin as an ID-targeted row action.
- Added a floating `ThreadRenamePanel` with a single title field that commits through the state boundary and closes after save.
- Added smoke coverage for non-active session rename, row menu discovery, action-menu rename behavior, floating input behavior, empty-title no-op behavior, and commit state updates.

### Follow-up Guidelines

- Keep future row actions ID-based unless they intentionally select the row first.
- Extend the thread more menu with duplicate metadata and archived-state variants before adding more naked row buttons.

## 2026-06-05 Openable Session Search Results

### What Happened

- Search already returned matching session records, but the UI rendered them as static summary cards.
- Codex-style history search should be navigational: clicking a matching conversation should restore that thread rather than asking the user to retype `/resume`.

### Changes Made

- Added `SearchResult_<thread_id>` button rows for session search matches while leaving project, MCP, and model reference rows static.
- Added `_open_search_result_thread(thread_id)` so search rows select the target session, save the active selection, and return to chat.
- Made `_show_view()` tolerate partial test/controller setups by checking optional panels before toggling visibility.
- Added smoke coverage for rendering an openable search result and switching the active thread by clicking it.

### Follow-up Guidelines

- Keep archived sessions out of normal search until an explicit archived-history view exists.
- Future search result actions should reuse `select_thread(thread_id)` rather than mutating active session labels directly.

## 2026-06-05 Automation Command Cancel Action

### What Happened

- The command state machine could cancel commands, but Automation still only exposed request-approval and execute-approved actions.
- This left the UI contract incomplete: users could create or attempt command work from Automation, but could not cancel a queued, approval-required, approved, or running command from the same command-specific area.

### Changes Made

- Added a dedicated `CancelCommandRun` button beside the other Automation command actions.
- Bound the button to `next_cancellable_command_run()` and `cancel_command_run()` instead of sharing MCP or OpenAI stop controls.
- Added smoke coverage for the scene node, enabled/disabled state, command-target tooltip, and controller cancellation behavior.

### Follow-up Guidelines

- Keep command cancellation visually and behaviorally separate from OpenAI request cancellation and MCP tool execution.
- When real process control is added, the button should call the runner cancellation path through state, not directly terminate anything from the controller.

## 2026-06-05 Command Cancellation and Concurrency Contract

### What Happened

- Command output chunking made the running-command state more useful, but the state machine still lacked explicit cancellation and a single-running-command contract.
- Without that contract, a future shell runner could accidentally start multiple approved commands at once or leave an approval checkpoint active after a command is cancelled.

### Changes Made

- Added `cancel_command_run()` for queued, approval-required, approved, and running commands.
- Cleared pending command approvals when their command is cancelled.
- Added a guard that blocks starting a second command while another command is already `running`.
- Added smoke coverage for cancellation, approval cleanup, and concurrency blocking without invoking the fake runner.

### Follow-up Guidelines

- Real process termination should be added as a runner responsibility later; the current function only records the audited cancelled state.
- Keep concurrency enforcement in `GodexState`, not the UI, so Automation buttons and any future transport share the same boundary.

## 2026-06-05 Command Output Chunk Buffer

### What Happened

- Command transcript rows could show final stdout/stderr summaries, but they still could not represent Codex-style incremental output during a running command.
- A read-only sub-agent review found two risks before implementation: chunk appenders must not advance approval or runner state, and command-output redaction only covered inline API keys, not keys resolved from the configured environment variable.

### Changes Made

- Added `append_command_run_chunk()` as a state-only output buffer for already-running commands.
- Stored bounded stdout/stderr chunks separately from command status timelines and final result summaries.
- Kept terminal `update_command_run_status()` calls from dropping previously streamed chunks.
- Rendered chunk rows inside the existing command transcript disclosure body without introducing nested cards.
- Extended command-output redaction to cover both inline API keys and environment-variable API keys.

### Follow-up Guidelines

- Real shell runners should append chunks through the state API only after approval and after entering `running`.
- Avoid rebuilding huge command logs indefinitely; the current state buffer is intentionally bounded and should remain so even after a real transport lands.

## 2026-06-05 Command Run Timeline Rows

### What Happened

- Command transcript rows had final stdout/stderr sections, but they still lacked a Codex-like execution timeline that explains how a command moved through approval, running, blocked, or terminal states.
- A read-only sub-agent review confirmed the safest boundary: timeline data belongs on the `command_run` model event, while UI only renders it. It must not connect to shell execution or bypass existing approval fingerprints.

### Changes Made

- Added timeline events to command-run creation and status updates.
- Projected command timelines through `active_transcript_items()` as structured transcript result data.
- Rendered timeline rows inside the existing borderless `CommandTranscriptBody`, separate from exit-code/stdout/stderr sections.
- Added smoke coverage for running-to-terminal timeline persistence and UI timeline rendering.

### Follow-up Guidelines

- Keep timeline rows as auditable state transitions; live stdout/stderr appenders should use the same command-run model and bounded output buffers.
- Do not route shell execution through the controller. Real runner integration must enter through the existing approval-bound state boundary.

## 2026-06-05 Streaming Elapsed-Time Status

### What Happened

- Codex desktop gives long-running turns a stronger sense of time with live duration text, while Godex only animated `正在思考` dots.
- The timer needed to be UI-only so elapsed seconds would not dirty persisted chat messages or session history.

### Changes Made

- Added a stream start timestamp and elapsed-duration formatter for seconds, minutes, and hours.
- At the time, updated the streaming status label to show `正在思考 · 已处理 Ns` while the request was running.
- At the time, stream completion, cancellation, or failure froze the status label to `已处理`, `已取消`, or `已停止` with the final elapsed time.
- Added headless coverage for duration formatting and the live status label contract.
- This status design was later superseded by the 2026-06-07 chat transcript signal correction, which keeps only the lightweight `正在思考` shimmer in chat and hides successful transport bookkeeping.

### Follow-up Guidelines

- Keep run timers as view state unless a future replay timeline explicitly needs persisted duration events.
- Use fixed-width or non-layout-shifting counters when adding richer per-step timing badges.

## 2026-06-05 Streamed Tool-Call Preview Rows

### What Happened

- Streamed tool-call parsing could accumulate final tool calls, but Codex desktop makes in-progress tool work visible before completion.
- A read-only sub-agent review called out the safety boundary: partial arguments may be displayed, but must never become executable pending tool calls or approval targets.
- The main edge case was Chat Completions-style streams where early fragments can be keyed by `index` and later fragments add the final tool-call `id`.

### Changes Made

- Added transient `partial_tool_calls` state that is projected through `active_transcript_items()` as `partial_tool_call` rows with `正在解析` status.
- Rendered partial rows through the same borderless tool transcript control while keeping them out of `pending_tool_calls()` and persisted model events.
- Merged streamed deltas by stable index when needed, then replaced the partial row with the final tool row once `record_tool_calls()` creates the auditable event.
- Added smoke coverage for partial-state non-executability, partial-row cleanup, localized streaming status, and index/id merge behavior.

### Follow-up Guidelines

- Keep partial tool-call previews as display-only state; execution, approval, and continuation must start only from final `tool_call` model events.
- Add richer argument panes only after there is a stable truncation, copy, and inspection design that cannot accidentally dispatch partial JSON.
- Use the same transient-state pattern for future live stdout/stderr previews, then commit final output through the command-run state model.

## 2026-06-05 Floating Progress And Borderless Transcript

### What Happened

- User visual review showed the Godex right-side UI still looked like a Godot dashboard: three fixed cards inside the main layout rather than Codex's compact floating progress panel.
- The main transcript also rendered assistant/tool/command rows as bordered cards, which conflicted with the Codex desktop borderless conversation flow.
- A parallel read-only sub-agent audit confirmed the same structural mismatch and recommended moving the rail into an overlay while removing message-row borders.

### Changes Made

- Moved the progress rail into `ProgressOverlayLayer/RightRail`, making it a floating single-surface overlay instead of a `Body` layout column.
- Kept progress, output, and agent capability sections inside one rounded surface and changed capability rows from two-column large cards to compact single-column rows.
- Removed visible borders from assistant messages, stream-step rows, MCP tool rows, and command transcript rows while preserving a subtle user bubble.
- Added headless smoke assertions that reject the old `Body/RightRail` path and verify transcript rows stay borderless.
- Classified `codex-floating-progress-borderless-chat.png` as the reference screenshot for this UI rule.

### Follow-up Guidelines

- Add real sub-agent and source sections to the floating progress panel before widening or adding more cards.
- Keep the overlay behind composer popovers so model, approval, and add-context menus remain visually dominant.
- Visual validation in Mechoes remains necessary because headless checks cannot judge exact spacing against the screenshot.

## 2026-06-05 Command Transcript And Plugin/MCP Navigation Boundary

### What Happened

- The transcript state model had rebuildable MCP tool rows, but command requests still appeared only as audit data. Codex desktop shows command execution as compact disclosure rows with running/completed status and expandable details.
- The left navigation incorrectly reused the `Plugins` node as an MCP page. User review clarified that MCP is configured in settings or opened via `/mcp`, while `插件` is a separate later-stage plugin/skill surface.
- A new sub-agent spawn attempt failed because the existing sub-agent pool was already full. I reused completed read-only audit outputs and continued locally instead of blocking the slice.

### Changes Made

- Added state-backed `command_run` transcript events with queued/running/completed/failed status, command/shell/working-directory metadata, exit-code/stdout/stderr summaries, and persisted expand/collapse state.
- Added `CommandTranscriptRow` rendering so command requests rebuild from `GodexState.active_transcript_items()` beside message, stream-step, and MCP tool rows.
- Added a dedicated `插件` navigation view and moved MCP quick access to the `/mcp` local command; MCP endpoint and enablement remain in settings.
- Classified the new plugin-system and MCP-settings reference screenshots into `docs/references/screenshots/` and updated the screenshot index.

### Follow-up Guidelines

- Add live stdout/stderr streaming and animated file-change counters after command execution has a real transport, keeping the current state-backed row model as the projection boundary.
- Keep `插件` reserved for the later Codex-compatible plugin/skill system. Do not route it to MCP discovery or server configuration.
- Close or reuse completed sub-agents before spawning new parallel work so the main thread can keep using aggressive delegation when it materially helps.
- No Godot .NET MCP capability gap blocked this slice; live visual validation is still needed after installation.

## 2026-06-05 Streamed Tool-Call Parsing

### What Happened

- The new state-backed transcript rows made tool calls rebuildable, but the SSE path still treated streaming as text-only. If a streamed response produced tool-call fragments, Godex could finish with text state but no pending tool-call events.
- The smallest safe improvement was to normalize streamed tool-call fragments at the OpenAI execution boundary and let the controller accumulate them until stream completion, avoiding duplicate tool-call records for every argument delta.

### Changes Made

- Added first-stage Responses stream parsing for `function_call` output items and function-call argument delta/done events.
- Added Chat Completions stream parsing for `delta.tool_calls` fragments.
- Added controller-side streamed tool-call accumulation and completion-time recording into state-backed transcript tool rows.
- Added headless coverage for streamed function-call items, streamed argument deltas, Chat tool-call fragments, and controller accumulation hooks.

### Follow-up Guidelines

- Add live partial tool-call UI once streamed argument panes have stable sizing and truncation rules.
- Preserve source response event IDs more precisely when streamed calls are recorded after `openai_transport` completion.
- Extend the same parser path to any additional official Responses event names encountered during live API testing.

## 2026-06-05 Transcript State Items

### What Happened

- The first tool-row pass improved the visible transcript, but rows were still mostly transient UI controls. A full chat rebuild could not reliably reconstruct tool rows, stream steps, or collapse state from session data.
- A parallel read-only review confirmed the next sustainable step: keep `GodexDockController` as the projection layer, but let `GodexState` expose a rebuildable transcript item list that merges messages with model events by Agent turn.

### Changes Made

- Added turn IDs for Agent loops and attached them to new chat messages, stream-step events, and tool-call model events.
- Added `GodexState.active_transcript_items()` so the controller can rebuild message rows, stream step rows, and MCP tool transcript rows from state.
- Persisted tool transcript expanded state back into the underlying tool-call event so an expanded row can survive a UI rebuild.
- Added headless coverage for transcript item grouping, stream-step reconstruction, tool-row reconstruction, and expanded-state restoration.

### Follow-up Guidelines

- Add streamed tool-call delta parsing in `GodexOpenAIExecutionService` so Responses and Chat Completions tool-call fragments become transcript events during streaming, not only after full responses.
- Extend transcript items to command execution with bounded stdout/stderr panes and explicit exit-code status rows.
- Store a stable display sequence if future multi-message turns need exact interleaving beyond the current turn-grouped ordering.
- Godot .NET MCP remains sufficient for reload, log, script, and screenshot validation; hover and fine-grained click simulation are still useful candidates for future MCP/User-tool improvement.

## 2026-06-05 Transcript Tool Rows

### What Happened

- After the first streaming slice, the conversation surface still lacked Codex desktop's compact tool/command disclosure rows. MCP tool completion was still summarized as a normal assistant message, which made the transcript feel noisy and made tool execution harder to scan.
- A read-only subagent review confirmed the longer-term direction: `messages` and `model_events` should eventually be merged into a transcript view model with stable turn IDs. For the current slice, a UI-layer tool row was the smallest safe step that improves the visible behavior without reshaping the whole state model.

### Changes Made

- Added `ToolTranscriptRow` controls inside the chat transcript for MCP tool calls.
- Tool rows are scene-owned Godot controls with a header button, default-collapsed detail body, and status text for `正在运行`, `已运行`, or `失败`.
- MCP tool execution now creates a row when transport starts and updates that same row when the result arrives instead of appending a separate assistant summary message.
- Added headless coverage for the row structure, default collapsed state, expand toggle, and the guard that prevents MCP completion from regressing into plain assistant-summary transcript pollution.

### Follow-up Guidelines

- Move transcript grouping into a state-level view model once turn IDs and message/event parentage are added.
- Add persisted collapse state keyed by tool/model event ID so rows survive full UI rebuilds.
- Extend the same row system to command execution, stdout/stderr panes, and streamed tool-call delta reconstruction.
- Godot .NET MCP was sufficient for reload/log/script validation; a future tool that can trigger click/expand interactions and capture a focused transcript region would speed up visual regression checks.

## 2026-06-04 Streaming Conversation Surface

### What Happened

- The user pointed out that the current Godex conversation surface was still too static compared with Codex desktop: model output appeared after completion, tool/run rows were not grouped near the answer, and `正在思考` had no live feedback.
- The existing OpenAI path used Godot `HTTPRequest`, which only delivers a completed body. That made true token/delta streaming impossible without adding a dedicated transport path.
- A separate UI issue surfaced at the same time: settings-save status text was rendered into the chat transcript, even though it belongs in settings/status UI.

### Changes Made

- Added stream-enabled OpenAI payloads for Responses API and Chat Completions compatible requests.
- Added SSE delta parsing in `GodexOpenAIExecutionService` and exposed it through `GodexAgentService`.
- Added a `HTTPClient` streaming transport in `GodexDockController` that polls chunks, parses SSE `data:` events, and updates one assistant message in place instead of appending a message per delta.
- Added a lightweight `正在思考` animation and inline running-step rows near the streamed assistant response so the conversation surface starts to resemble Codex's live execution transcript.
- Updated cancellation/retry handling so a stream can be stopped, marked in the same assistant message, and retained as a retryable request.
- Moved settings-save feedback into the settings API status label instead of adding it to chat.
- Added headless coverage for streaming payload flags, SSE parser behavior, message in-place updates, and the settings-save transcript guard.

### Follow-up Guidelines

- Tool-call delta reconstruction is not complete yet. The next streaming slice should parse streamed function-call fragments and transition inline rows from `正在运行` to expandable completed tool groups.
- Stream event replay should be stored as compact model events, not one event per token, to avoid growing session JSON too quickly.
- Visual validation should compare the assistant bubble against Codex desktop: live thought text, run-command grouping, collapse chevrons, and completed-step density.
- Godot .NET MCP was sufficient for basic reload/log validation, but richer hover/keyboard/mouse simulation remains useful for validating Codex-like transcript interactions without manual screenshots.

## 2026-06-04 Composer Add-Context Menu

### What Happened

- The composer `+` affordance was still a disabled placeholder even though Codex desktop exposes it as a compact context-source menu.
- Read-only review showed Godex already has safe local context boundaries for IDE context, goal tracking, manual compaction, and MCP project-summary probe creation, but it does not yet have a durable attachment model for files, images, screenshots, terminal/browser context, or plugin-provided sources.
- The implementation needed to improve the Codex-like interaction without pretending unsupported attachment ingestion already exists.

### Changes Made

- Added a scene-owned `AddContextPanel` under `ComposerPopoverLayer`, matching the existing non-resizing composer popover architecture.
- Turned the composer `+` button into an enabled menu opener with compact action rows.
- Wired enabled rows to existing safe behavior: MCP project summary creates a pending `godex_mcp_context` tool call through the Agent service, IDE context toggles `GodexState.ide_context_enabled`, goal toggles `GodexState.goal_tracking_enabled`, and compaction uses the existing active-session compaction path.
- Kept file upload, image/screenshot, terminal/browser, side-chat, and future plugin context rows disabled with explicit copy so the UI does not imply unsupported attachment transport.
- Extended headless smoke coverage for scene ownership, non-resizing layout, disabled attachment rows, and the MCP project-summary action creating a pending context tool call.

### Follow-up Guidelines

- The next deeper add-context slice should introduce a lightweight `context_items` session structure with summaries and artifact references, avoiding inline base64 screenshots or large raw MCP payloads in session JSON.
- Attachment sources should become enabled only after their data lifecycle, OpenAI payload mapping, audit events, and UI chips/cards are implemented together.
- Godot .NET MCP was sufficient for this slice because the menu is scene-owned and the project-summary action reuses existing MCP tool-call boundaries.

## 2026-06-04 Composer Model and Reasoning Pickers

### What Happened

- The composer already stored model and reasoning effort correctly, and the OpenAI request pipeline preserved reasoning effort in first-turn, retry, and tool-result continuation requests.
- The visible composer controls still used native Godot `OptionButton` widgets, which did not match Codex desktop's compact checked-list menus and were not scene-owned popovers that Godot .NET MCP could inspect consistently.
- Read-only review confirmed the safe scope: replace only the composer interaction surface while keeping provider settings, persistence, and request construction unchanged.

### Changes Made

- Replaced the composer model and reasoning `OptionButton` controls with a single compact model/reasoning button that opens a Codex-style combined `ComposerPopoverLayer` menu.
- Added fixed-rect `ReasoningPickerPanel` and right-side `ModelPickerPanel` nodes with themed inner surfaces, clipped content, compact single-line rows, submenu chevron, and trailing selected check marks.
- Tightened the right-side model submenu to Codex desktop's hover behavior: hovering the current-model row opens it, clicking that row no longer toggles it, and a lightweight hover watcher closes it after the pointer leaves both the row and submenu panel.
- Removed outer picker clipping so the themed inner surfaces keep intact rounded corners while still clipping their own row content.
- Kept model selection wired to `GodexState.set_model()` and reasoning selection wired to `GodexState.reasoning_effort`, preserving the existing OpenAI payload, retry, continuation, and audit paths.
- Preserved catalog-external custom model visibility by rendering the active custom model as a checked row when it is not present in the provider catalog.
- Added headless smoke coverage for picker node ownership, non-resizing popover layout, row structure, mutual exclusivity, hover-only submenu behavior, rounded-corner clipping guards, model selection, and reasoning selection.
- Moved the project/context picker reference image into `docs/references/screenshots/` and indexed it for future add-context work.

### Follow-up Guidelines

- Provider/model-aware reasoning availability is still a gap; future work should use provider metadata to disable or hide unsupported effort levels rather than changing the request pipeline ad hoc.
- Keep future composer menus scene-owned under `ComposerPopoverLayer` so MCP screenshots and control enumeration can verify them.
- Godot .NET MCP can screenshot and enumerate these scene-owned controls, but this slice still relied on headless/source tests for hover semantics because the current editor-control layer does not provide a stable hover/leave simulation action.

## 2026-06-04 Composer Popover Height Correction

### What Happened

- Visual comparison with Codex desktop showed that Godex still treated composer menus as part of the input layout.
- Opening the approval mode menu or slash-command menu could increase the composer height because both panels lived as normal children of the `ComposerBox` `VBoxContainer`.
- Codex desktop treats these controls as overlays anchored above the composer, so the input surface remains the same height while a menu is open.
- A live Mechoes screenshot later showed a second issue: even after overlay positioning, a themed `PanelContainer` approval menu could be pushed to a 489px visible rect by child minimum sizes and still overlap the composer row.

### Changes Made

- Converted the approval and slash-command panels into inspectable runtime popovers under `ComposerPopoverLayer`, positioned from the prompt or approval pill global rect.
- Added shared popover positioning helpers that clamp menus inside the Godex root while keeping them above the composer controls.
- Updated the approval menu rows to use Codex-like structured content: left icon, title, muted description, and right check mark, instead of concatenated multiline button text.
- Constrained the approval popover to a Codex desktop-like short fixed content height instead of inheriting a 525px container rect, removing the blank lower band and bottom-edge overflow seen in the live editor layout.
- Split the approval menu into a fixed-rect outer `Control` and an inner themed `ApprovalModeSurface`, preventing Godot `PanelContainer` minimum-size calculation from expanding the visible popup downward.
- Added headless smoke coverage that opens both composer popovers, asserts the panels live under `ComposerPopoverLayer`, checks that the `ComposerBox` layout height does not increase, and verifies the approval outer rect matches the themed surface height.
- Kept slash keyboard navigation and approval selection behavior unchanged while ensuring the two popovers hide each other.

### Follow-up Guidelines

- Future composer menus, including add-context, MCP, Skill, and retry-preview menus, must use floating popovers rather than visible children inside the composer layout flow.
- Keep popover contents as runtime `Control` nodes rather than native transient popups so Godot .NET MCP screenshots and control enumeration can still verify them.
- Visual validation should check both normal and narrow widths because popovers now clamp to the Godex root and may need tighter row copy at small sizes.
- Treat headless layout smoke as necessary but incomplete for composer popovers: it can verify `ComposerBox` height invariants, while live editor MCP screenshots are still needed to catch container rect, surface minimum-size, and viewport clamping differences.

## 2026-06-04 Slash Command Keyboard Navigation

### What Happened

- The slash-command menu already matched the Codex action-list look and supported click-to-insert, but keyboard use still behaved like a plain `TextEdit`.
- In Codex, command palettes are expected to keep the current row highlighted, move selection with Up/Down, insert the selected action with Enter, and close with Esc.
- The implementation needed to stay in the UI layer: keyboard selection should choose an existing `insert_text`, while command execution remains owned by `GodexState.execute_slash_command()`.

### Changes Made

- Added controller-owned slash menu state for the current query, suggestion array, and selected index.
- Connected `TextEdit.gui_input` so Up/Down cycles selection, Enter inserts the selected suggestion, and Esc hides the menu while preserving composer text.
- Kept focus on the composer instead of moving focus into row buttons, preserving normal typing behavior.
- Added headless smoke coverage that instantiates the real scene, opens slash suggestions, simulates key events, checks selection wrapping, verifies Enter insertion, and checks Esc close behavior.
- Guarded `_insert_slash_command()` focus restoration with `is_inside_tree()` so headless controller tests do not fail on Godot's focus timing before a Control is fully inside the tree.

### Follow-up Guidelines

- Keep slash command execution semantics in `GodexState`; future MCP or Skill command palette entries should provide metadata and insert text, not run directly from row rendering.
- Add visual validation for narrow composer widths once the action list starts mixing local commands, MCP entries, and Skill entries.
- The temporary headless `grab_focus()` failure was a test-harness timing issue. Known MCP validation limit: `system_editor_control.set_control_text` can update a `TextEdit` value, but it does not simulate real keyboard input or emit the same `text_changed` / `gui_input` flow as typing. Slash menu opening still needs headless key-event coverage, live keyboard-like validation, or a future editor-control text-entry path that emits user-like input signals.

## 2026-06-04 Composer Input Surface Polish

### What Happened

- The user provided focused Codex desktop composer references showing a compact rounded input surface, a dark multiline prompt box, an icon-sized `+` control, blue approval shield pill, and nearby goal state.
- Godex already had a functional composer and action row, but the input surface still felt like a generic Godot panel. At that point, the `+` button also implied that attachment/context insertion already existed even though the real add-context menu had not been implemented.
- The safest implementation target for this slice was therefore visual alignment plus honest affordance state. A later add-context slice replaced the temporary disabled affordance with a safe menu for existing local actions.

### Changes Made

- Repainted the composer panel and prompt field with compact Codex-like rounded surfaces while staying inside Godot-native `PanelContainer`, `TextEdit`, and container controls.
- Tightened the bottom action row spacing, added a small divider after approval mode, and kept the existing model, reasoning, IDE context, stop, retry, and send controls in the same row.
- Changed the composer `+` into a disabled icon-sized affordance with explicit tooltip copy that said add-context was temporarily unavailable. A later add-context slice replaced this placeholder with a safe scene-owned menu while keeping unsupported attachment rows disabled.
- Added smoke coverage so the compact input and the temporary unavailable copy did not regress silently before the add-context menu existed.
- Updated architecture, UX reference, feature gap, and changelog entries to separate the future full Codex add-context ingestion target from the temporary Godex placeholder.

### Follow-up Guidelines

- Keep unsupported file/photo rows disabled until Godex can actually attach those sources into the Agent turn.
- The add-context menu should remain scene-owned and MCP-inspectable, not a native popup that disappears from screenshots or control enumeration.
- Visual validation should check the composer at normal and narrow editor widths because the action row is dense and can easily crowd model/reasoning controls.
- No Godot .NET MCP issue was found while implementing this slice; MCP visual validation remains necessary after installation.

## 2026-06-04 Slash Command Menu Row Polish

### What Happened

- The corrected Codex reference menu for slash commands is a rounded popup above the composer input, with single-line action rows, left icons, strong action names, muted descriptions, selected-row highlight, and scrollable overflow.
- Godex already showed slash-command suggestions, but each row was a single text button that concatenated command and summary below the input. This made the menu less scannable, placed it in the wrong composer region, and made it easier to drift from Codex.
- The command execution boundary was already correct in `GodexState.execute_slash_command()`, so the improvement needed to stay presentation-focused and avoid moving command semantics into the UI controller.

### Changes Made

- Added action titles, dynamic descriptions, and icon candidates to `GodexState.slash_commands()` and returned them from `slash_command_suggestions()`.
- Rebuilt slash suggestion rows in the controller as Godot-native single-line action rows with editor-theme icon slots, title/description copy, selected-row highlighting, and a scrollable popup above the input.
- Kept click-to-insert behavior, alias matching, unknown-command passthrough, and local execution semantics unchanged.
- Extended smoke coverage so future refactors keep the action-list row contract and state-level metadata.

### Follow-up Guidelines

- Keep command execution owned by `GodexState`; the controller should remain a renderer and click-forwarder for slash rows.
- Future MCP/Skill command palette entries should reuse the same icon/title/description action-list row pattern rather than creating a second menu style.
- Narrow-width visual checks should confirm long descriptions truncate gracefully without pushing action titles out of the composer popup.
- No Godot .NET MCP issue was found in this slice; the existing scene-owned panel remains inspectable by MCP screenshots.
- The first Mechoes-side MCP verification attempt for this slice was interrupted before reload/log/screenshot collection because the approval reviewer returned `503 Service Unavailable` from `https://yurenapi.com/v1/responses`. The reviewer service later recovered, and the slice was verified with plugin reload, clean editor logs, and an editor screenshot of the corrected action-list popup.

## 2026-06-04 Approval Mode Pill Polish

### What Happened

- The latest Codex reference screenshot isolated the approval mode pill and showed a blue shield, compact dropdown affordance, and a hover-oriented control style.
- Godex already had an approval mode button, but it used a generic tooltip and did not preserve the Codex blue approval cue requested by the objective.

### Changes Made

- Updated the composer approval button to show a compact dropdown hint, mode-specific hover tooltips for `请求批准`, `替我审批`, and `完全访问权限`, and a blue permission-style icon.
- Kept the styling in the controller using existing `GodexTheme.paint_button()` plus local color overrides so live plugin reloads do not depend on a newly added theme method being present in a cached script instance.
- Extended the headless smoke test to guard the approval tooltip and blue icon styling contract.

### Follow-up Guidelines

- Future approval menu work should replace the current cycling behavior with a popup menu that mirrors the Codex checked-item menu.
- The approval pill should be visually rechecked in Mechoes after each composer layout change because text, icon, and model controls share a tight row.
- No Godot .NET MCP feature gap blocked this slice.

## 2026-06-04 Reference Screenshot Inbox Cleanup

### What Happened

- The user added another batch of Codex desktop screenshots directly under `docs/references/` with generic `image copy` names.
- The new screenshots focused on slash command discovery, MCP/Skill menus, paused goal cards, approval-mode pill details, split review panes, and edited-file review cards.
- The updated objective explicitly called out hover tooltip design and the blue approval shield cue, so the screenshot notes needed to preserve those details before further UI implementation.

### Changes Made

- Moved all new root-level screenshots into `docs/references/screenshots/` with stable descriptive `codex-*.png` filenames.
- Updated `docs/references/screenshot-index.md` with the new reference topics and intended Godex usage.
- Extended `docs/references/codex-desktop-ux.md` with slash-command menu, MCP/Skill grouping, approval pill tooltip/color guidance, paused goal overlays, split review panes, attachment cards, and edited-file review card rules.

### Follow-up Guidelines

- Keep `docs/references/` as an inbox: classify new images before using them for implementation.
- The edited-file review card is now a strong reference for a future Godex review summary component, but this pass only organized references and did not implement the component.
- No Godot .NET MCP issue blocked this documentation pass; image inspection and local file organization were sufficient.

## 2026-06-04 Slash Command Suggestions

### What Happened

- Godex already handled local slash commands, but users had to remember exact command names or run `/help`.
- Codex-style composer behavior should make commands discoverable where the user is typing, without turning unknown slash input into an unwanted OpenAI request.
- The existing command execution lived in `GodexState`, so command discovery needed to share the same state boundary instead of duplicating command metadata in the UI controller.

### Changes Made

- Added `slash_commands` metadata and `slash_command_suggestions()` to `GodexState`, including aliases, argument hints, summaries, and insert text.
- Added a hidden-by-default `SlashCommandPanel` inside the composer, between the prompt box and control row.
- The controller now watches composer text, shows filtered slash-command rows for `/` input, supports alias matching, and inserts the selected command text back into the composer.
- Extended smoke coverage for scene nodes, controller suggestion hooks, prefix filtering, and alias matching.

### Follow-up Guidelines

- Add keyboard navigation for suggestion rows before treating the command palette as complete.
- Consider grouping commands by session, goal, and context once the command list grows.
- No Godot .NET MCP feature gap blocked this work; standalone smoke coverage is enough for the local command metadata, and live validation should focus on visual layout.

## 2026-06-04 OpenAI Send Approval Gate

### What Happened

- Godex had approval checkpoints for MCP tool dispatch and a visible pending OpenAI continuation preview.
- The first-turn composer send path could pause in `请求批准` mode, but manual tool-result continuation sends still had a direct path to `_start_openai_transport()`.
- Because both paths create outbound OpenAI HTTP requests, the approval policy needed one consistent network-send boundary rather than separate behavior for initial prompts and continuation requests.

### Changes Made

- Added a pending OpenAI approval request slot that stores redacted preview metadata plus in-memory transport data for approved dispatch.
- Routed first-turn OpenAI sends, retry sends, and manual tool-result continuation sends through the same `network:openai_request` approval checkpoint when `approval_mode` is `请求批准`.
- Stored request source metadata (`user_prompt` or `tool_result_continuation`) and the related tool-call ID so approvals remain auditable.
- On approval, continuation requests now clear the matching pending continuation, record an Agent loop step, and then dispatch; on rejection, the OpenAI approval slot is cleared without starting transport.
- Extended smoke coverage for controller approval-gate source strings and state preview metadata while keeping API keys out of summaries.

### Follow-up Guidelines

- Add a deterministic controller UI harness that can click `发送续跑请求`, inspect the pending approval row, approve it, and verify the button/preview state changes without a real OpenAI server.
- Continue treating raw OpenAI transport data as in-memory only; persisted model events and chat messages should keep redacted endpoint/model/body-size summaries.
- After syncing into the live project, direct Godot console execution of the installed smoke script crashed the separate headless process with signal 11 while opening `user://logs/godot2026-06-04T12.52.03.log`. The live editor and MCP session stayed healthy, script analysis reported no parse errors, editor logs stayed clean, and the Godex main screen screenshot captured successfully.
- Prefer the standalone Godex validation script plus MCP script analysis, editor logs, project state, and screenshots for integration checks. Avoid running the installed smoke script directly inside the large host project unless a separate crash-safe harness or isolated user data path is prepared.
- No Godot .NET MCP capability gap blocked this work. The MCP editor state, script analysis, log, plugin status, and screenshot tools were sufficient for the live validation portion.

## 2026-06-04 Session Commands and Reference Screenshots

### What Happened

- New Codex desktop screenshots were added under `docs/references` with copy-style filenames.
- The next high-value Agent workbench gap was session management and command entry: state already supported basic sessions, but users had no Codex-like local commands or quick thread actions.
- The objective also clarified that Godex should keep functional and architecture documentation current while developing.
- During Mechoes integration validation, the MCP endpoint became unavailable after attempting to interact with the live Godex refresh path. Subsequent local checks showed no Godot process with a Godot/Mechoes window title and `127.0.0.1:3000` was no longer accepting connections.

### Changes Made

- Classified the new screenshots into stable filenames under `docs/references/screenshots/` and updated the screenshot index.
- Extended the Codex UX reference with right launcher, side chat, composer menu, queue/guide, and review-strip layout rules.
- Added local slash commands for `/new`, `/resume`, `/fork`, `/archive`, `/rename`, `/pin`, `/goal`, `/compact`, and `/help`.
- Added compact sidebar thread buttons for fork and archive.
- Updated architecture, feature-gap, changelog, and smoke coverage for the new session-command boundary.

### Follow-up Guidelines

- Implement a visible slash-command completion menu so users do not need to memorize commands.
- Add archived-thread browsing and richer conversation menus before considering the session-management gap fully closed.
- Real interactive streaming conversation is still a high-priority gap; this round only keeps local commands from triggering unnecessary OpenAI requests.
- Integration validation should avoid repeated live refresh clicks until the MCP/editor lifecycle has a safer third-party plugin refresh diagnostic.
- The local Godex headless smoke test still passed after the environment issue, but live Mechoes UI validation for this slice remains incomplete until the editor/MCP endpoint is restored.

## 2026-06-04 Bounded Agent Loop Advancement

### What Happened

- Godex already had live OpenAI requests, parsed tool calls, MCP tool execution, and explicit tool-result continuation.
- The missing Codex-like behavior was a repeated loop that automatically advances safe tool calls instead of leaving every step as a manual Automation click.
- The first local headless validation passed, but Mechoes MCP/LSP validation caught a GDScript type inference parse error in the live installed copy.
- Visual Automation-page validation then exposed a runtime string-formatting error in the new loop summary row.

### Root Causes

- `Dictionary.get(...).size()` did not give Godot enough static type information for `:=` inference in the controller.
- GDScript `%d` formatting is strict about numeric variants; untyped RefCounted fields should be cast before formatting.
- The existing smoke test covered source strings and state behavior, but did not instantiate the controller and navigate the Automation page after installation.

### Changes Made

- Added bounded Agent loop state to `GodexState`: status, step count, max-step guard, stop reason, update time, and a compact Automation summary.
- The controller now begins a loop on user prompt or manual tool execution, advances parsed model tool calls through MCP dispatch, then continues with existing tool-result OpenAI continuation rules.
- Automatic advancement stops on approval requirements, busy/canceled requests, missing API keys, unresolved tool calls, manual continuation review, request failure, or the max-step guard.
- Fixed live GDScript parse/runtime issues by adding explicit `int()` casts for parsed tool-call counts and loop summary formatting.
- Extended smoke coverage for loop start, step counting, max-step stopping, stop reason summaries, and controller loop helper presence.

### Follow-up Guidelines

- Add a controller-level UI smoke harness that instantiates `godex_main.tscn`, switches to Automation, and catches formatting/runtime errors without needing a live editor click.
- MCP validation should remain mandatory after local smoke tests, because it caught script parse behavior that standalone validation missed.
- No Godot .NET MCP feature gap blocked this work; the MCP editor screenshot and log tools were sufficient and directly useful.

## 2026-06-04 Main Screen Integration

### What Happened

- The first Godex editor entry used `CONTAINER_EDITOR_MAIN_SCREEN`, then `EditorPlugin.CONTAINER_EDITOR_MAIN_SCREEN`.
- Godot 4.6 rejected both forms when Mechoes loaded `res://addons/godex/plugin.gd`.
- A later headless smoke test initially returned exit code `0` even while printing script errors, which could have hidden the regression.
- The controller also used strongly typed external script references in a way that produced `Could not resolve external class member` during plugin script loading.

### Root Causes

- Godot main-screen plugins should add their root control to `get_editor_interface().get_editor_main_screen()` and expose `_has_main_screen()`, `_get_plugin_name()`, and `_make_visible()`.
- The first validation only checked scene/service contracts and did not load `plugin.gd`.
- The validation wrapper trusted the Godot process exit code instead of scanning emitted script errors.
- Cross-script `class_name` types are convenient but brittle during editor plugin hot-load and headless compilation.

### Changes Made

- Switched main-screen registration to `EditorInterface.get_editor_main_screen().add_child(...)`.
- Added plugin script loading to the headless smoke test.
- Updated `tools/validate-godex.ps1` to fail on `SCRIPT ERROR`, `Parse Error`, `Compile Error`, and `Failed to load script`.
- Relaxed service references to `RefCounted` plus `call()` at plugin boundaries.

### Follow-up Guidelines

- Any new plugin entry script change must be validated in both the standalone Godex project and the installed Mechoes copy.
- MCP `runtime_diagnose`, `script_analyze`, `editor_log`, and editor screenshots should be collected after each Mechoes install/reload loop.
- Keep integration errors in this document with root cause and prevention notes.

## 2026-06-04 Current Editor Hot-load Limit

### What Happened

- Godex was copied into `res://addons/godex` and added to `editor_plugins/enabled`.
- Standalone and installed headless smoke tests passed.
- MCP `script_analyze` and `scene_validate` found no parse errors.
- The current Mechoes editor session still reported available main screens as `2D`, `3D`, `Script`, and `AssetLib`, without `Godex`.

### Root Cause Analysis

The current MCP setting write updates `project.godot`, but it does not force Godot to instantiate a newly added third-party `EditorPlugin` main screen in the already-open editor session. Restarting the editor would likely load the plugin, but that was intentionally avoided because the current task forbids risky actions that might close or destabilize Mechoes.

### Prevention

- Continue validating plugin scripts, scenes, and settings through headless smoke and MCP diagnostics.
- Use a safe editor restart only when explicitly acceptable or when a stable plugin reload mechanism for newly added plugins exists.
- Track the lack of safe third-party plugin hot-load in the workspace suggestion log.

## 2026-06-04 MCP User Tool Plugin Enable Loop

### What Happened

- The Mechoes Project Settings plugin list showed Godex installed but not enabled, even though `editor_plugins/enabled` already contained `res://addons/godex/plugin.cfg`.
- Direct OS-level coordinate clicking was rejected as unsafe because it could affect the wrong window or setting.
- A small MCP User Tool was added under `res://addons/godot_dotnet_mcp/custom_tools/godex_plugin_control.gd` to call Godot editor APIs from inside the editor session.
- The first User Tool draft failed hot-load with GDScript parse errors because strict inference could not infer untyped `EditorInterface` values.
- After switching to non-inferred local variables and using the documented plugin name `godex` for `EditorInterface.set_plugin_enabled()`, the tool hot-loaded as `user_godex_plugin_control`.

### Result

- `user_godex_plugin_control(action="enable")` returned `editor_reports_enabled=true`.
- The top editor main-screen bar showed `Godex` to the right of `AssetLib`.
- Activating the Godex button rendered `GodexMain` in the editor main screen.
- Visual verification captured the Godex workbench UI with sidebar navigation, central composer, progress/artifact cards, and agent capability cards.
- The Output panel was cleared after noisy error collection to avoid log growth.

### Prevention

- Prefer editor-native API tools over blind OS coordinate input for plugin enablement.
- When writing hot-loaded GDScript tools, avoid `:=` inference for values returned by loosely typed helper methods.
- For Godot editor plugin APIs, pass the plugin directory name such as `godex`, not the `plugin.cfg` resource path.
- Keep a reusable high-level plugin enable/readiness tool on the MCP roadmap so future plugin integration does not require ad hoc User Tools.

## 2026-06-04 Capability Preview And Turn Audit

### What Happened

- The settings view already exposed provider, endpoint, Skill, MCP, and compression toggles, but it did not explain what an Agent turn would actually enable.
- Read-only sub-agent review found that `prepare_turn()` had a useful payload skeleton but no structured dry-run audit, and that compression summaries were generated then discarded.
- User-provided Codex desktop screenshots clarified that Godex should preserve Godot theme colors while copying Codex's relative layout, icon button density, rounded panels, hover tooltips, and progress feedback.

### Changes Made

- Added state-level capability summaries for MCP context, Skill triggering, command-line capability, and context compression.
- Added command capability controls and a live capability preview to the settings panel.
- Added a structured `audit` return from `AgentService.prepare_turn()` containing payload mode, endpoint, MCP request draft, approval checkpoint, sub-agent queue item, command request, and compression result.
- Preserved compression summaries as a synthetic system message instead of dropping old context entirely.
- Added `docs/references/codex-desktop-ux.md` as a standing Codex desktop UX reference for future Godex UI work.
- Added Codex-style composer state controls for model selection, reasoning effort, approval mode, IDE context, and goal tracking.

### Follow-up Guidelines

- Turn Search, MCP, Automation, and Settings into real view switches rather than chat-only explanatory messages.
- Avoid persisting raw API keys long term; prefer environment variables now and a secure storage path later.
- Add real MCP streamable HTTP calls only behind explicit timeouts and visible failure states.
- Implement the add-context menu as a real popup with file/photo, IDE background, planning mode, goal tracking, and plugin entries.

## 2026-06-04 Godex Main Screen Distraction-Free Mode

### What Happened

- Visual verification showed Godex rendering inside the normal Godot editor layout with left scene dock, right MCP dock, and bottom Output panel still visible.
- The user pointed to Godot's top-right distraction-free toggle and requested that Godex use it automatically when entering the Godex page, then restore the prior layout when leaving.

### Changes Made

- `plugin.gd` now records the previous editor distraction-free state when Godex becomes visible.
- If the editor was not already distraction-free, Godex enables distraction-free mode on entry.
- When Godex is hidden or the plugin exits, it restores the previous state.

### Follow-up Guidelines

- Validate this behavior visually after every installed plugin reload because the exact Godot chrome restoration depends on editor lifecycle callbacks.
- If Godot exposes a more granular panel visibility API in future, prefer explicit left/right/bottom panel restore state over only using distraction-free mode.

## 2026-06-04 Plugin System Screenshot Preservation

### What Happened

- The user supplied a Codex desktop plugin-system screenshot and explicitly said not to rush into developing the plugin system.
- The screenshot shows the Codex plugin management surface with left rail navigation, `插件` / `技能` tabs, centered search and filters, featured plugin banner, grouped plugin rows, and top-right management actions.
- The first chat attachment was visible in the conversation, but the local workspace did not expose a readable image file for direct copying.
- A Windows screen capture attempt wrote `docs/references/codex-plugin-system-2026-06-04.png`, but the capture API returned an invalid handle and the resulting image was black. The invalid file was deleted.
- The user later added multiple screenshot files directly under `docs/references/`, making real image preservation possible.

### Changes Made

- Preserved the actionable screenshot observations in `docs/references/codex-desktop-ux.md`.
- Added a later-stage feature gap for a Codex-compatible plugin system without starting implementation.
- Moved the new screenshots into `docs/references/screenshots/` with descriptive `codex-*.png` filenames.
- Added `docs/references/screenshot-index.md` to classify screenshot topics and explain how to maintain future incoming screenshots.

### Follow-up Guidelines

- Do not build plugin-system functionality until the core Agent loop, MCP execution, approvals, sessions, and model/provider flows are mature.
- When new screenshots are added, classify them under `docs/references/screenshots/`, update `screenshot-index.md`, and only update implementation plans when the screenshot supports a current core feature.

## 2026-06-04 App View Switching And Screenshot Library

### What Happened

- Search, MCP, and Automation navigation items still behaved like chat prompts and appended explanatory assistant messages.
- The user added multiple Codex desktop screenshots under `docs/references/` and clarified that screenshots should be continuously discovered, organized, and reused as Godex UI references.
- The user also clarified that Godex is its own Godot project and Git repository, so project state and commits should be managed from the `Godex/` repository root.

### Changes Made

- Added real Search, MCP, and Automation center panels to `ui/godex_main.tscn`.
- Updated `godex_dock_controller.gd` to switch between Chat, Search, MCP, Automation, and Settings views, with navigation highlight state instead of chat-only explanatory messages.
- Classified screenshot files into `docs/references/screenshots/` using descriptive filenames and added `docs/references/screenshot-index.md`.
- Documented the standalone Godex repository boundary in `docs/architecture.md`.

### Follow-up Guidelines

- Replace placeholder view rows with live data from sessions, MCP tool discovery, approval state, and command/action history.
- Continue treating `docs/references/` as an inbox: new unclassified screenshots should be renamed, moved under `screenshots/`, and added to the index before being used for UI work.
- Keep Git operations scoped to the Godex repository unless explicitly working on another project.

## 2026-06-04 Persistent Session Foundation

### What Happened

- Godex had a Codex-like thread list and message area, but the active conversation existed only in memory.
- Search view had a real panel but only showed static summary rows, so it could not search conversation history.
- The high-priority gap tracker still listed persistent sessions with resume, fork, archive, and search as entirely missing.

### Changes Made

- Added `core/session_store.gd` to persist sessions as JSON under `user://godex/sessions.json`.
- Extended `GodexState` with active-thread selection, session messages, new-session creation, archive metadata, fork metadata, and conversation search records.
- Updated the controller to load sessions on startup, render active messages, save sessions after sends and built-in thread actions, and feed the Search view from session search results.
- Added headless smoke coverage for session defaults, new messages, search, fork, archive metadata, and the new view nodes.

### Follow-up Guidelines

- Add explicit UI actions for rename, pin, archive, fork, and resume instead of exposing only the state methods.
- Keep persisted session data auditable and migration-friendly while the schema is still growing.
- Avoid coupling session storage to OpenAI request execution; request streaming, cancellation, and tool-call history should layer on top of the session model.

## 2026-06-04 Mechoes Headless Console Crash During Integration Smoke

### What Happened

- Standalone Godex validation passed with Godot 4.6.2 console and `GODEX_HEADLESS_SMOKE_OK`.
- After copying Godex into Mechoes, MCP `scene_validate`, `script_analyze`, project state, and editor logs were clean.
- Running the same Godex smoke script directly against the Mechoes project with a separate Godot console process timed out after 120 seconds and crashed with signal 11.
- The console output repeatedly started with `Failed to open 'user://logs/godot2026-06-04T04.xx.xx.log'` before the crash backtrace.
- Retrying with an isolated `--user-data-dir` produced the same log-open error and crash.
- The already-open Mechoes editor and MCP endpoint remained alive after both crashes.

### Root Cause Analysis

The failure appears to be in the external Godot console validation process rather than in Godex script parsing: the standalone Godex project smoke passed, MCP file-level checks passed inside Mechoes, and the editor session reported no Godex errors. The crash may be related to Godot console log initialization, Mechoes project startup, or concurrent editor/headless access on Windows, but current evidence is not strong enough to isolate it further.

### Prevention

- Do not repeatedly run the Mechoes project headless smoke through a separate Godot console process until a safer isolated validation path exists.
- Prefer standalone Godex smoke plus MCP `scene_validate`, `script_analyze`, `project_state`, and editor log inspection for current integration verification.
- Record this as a validation tooling gap so a future MCP-side runner can isolate user data, collect crash output, and avoid destabilizing the open editor workflow.

## 2026-06-04 Approval Checkpoint And Decision Trail

### What Happened

- Godex already classified risky actions through `approval_policy.gd`, and the composer could cycle approval modes.
- The Automation view did not show pending approvals, and there was no user-facing approve/reject decision record.
- Agent turns prepared an MCP context approval checkpoint, but the checkpoint was only returned in the audit object and was not persisted.

### Changes Made

- Added `approval_records` to `GodexState`, with pending checkpoint lookup, summary rows, and latest approve/reject decision handling.
- Agent turn preparation now records the MCP context checkpoint into state.
- Session persistence now stores approval records alongside conversation sessions.
- The Automation view now shows pending approval detail, recent approval records, and compact buttons to approve or reject the latest pending checkpoint.
- Headless smoke tests now cover approval checkpoint creation, decision status, and persistence snapshot inclusion.

### Follow-up Guidelines

- Execution layers for real commands, file writes, network calls, runtime control, and MCP tool dispatch must consult approval records before running.
- Add richer approval UI later: per-record decision buttons, risk badges, reason text, and immutable audit IDs.
- Keep rejection behavior conservative: rejected checkpoints should never be silently retried as approved actions.

## 2026-06-04 API Authentication Snapshot

### What Happened

- Godex already persisted provider, base URL, API mode, model, and key fields.
- The Agent turn preview could build request payloads, but runtime execution would still have needed to duplicate endpoint and authentication handling.
- The settings UI showed raw key fields but did not surface whether the effective key came from an environment variable, manual input, or was missing.

### Changes Made

- Added OpenAI-compatible request header construction and API key masking to the request builder.
- Added `api_config_snapshot()` to `GodexState` so the active provider, model, endpoint, key source, masked key, and headers are derived in one auditable place.
- Added settings-panel authentication status feedback while keeping the displayed value masked.
- Extended headless smoke coverage for scene nodes, headers, masking, missing-key detection, and inline-key snapshots.

### Follow-up Guidelines

- Real HTTP execution should consume `api_config_snapshot()` directly instead of rebuilding endpoint or header rules.
- Inline API keys remain a temporary convenience; a safer secret backend is still needed before broader use.
- Request execution should record only masked key state in UI messages, logs, sessions, and retrospectives.

## 2026-06-04 OpenAI Execution Service Boundary

### What Happened

- Godex could build OpenAI-compatible payloads and authentication snapshots, but the Agent service still treated the request as a loose preview.
- Real transport should not be added before response parsing, tool-call extraction, missing-key handling, and API error normalization are independently testable.
- UI code should not parse OpenAI responses or duplicate header and endpoint rules.

### Changes Made

- Added `GodexOpenAIExecutionService` as a service boundary for request readiness snapshots, response parsing, tool-call extraction, and normalized errors.
- Agent turn audits now include masked API readiness metadata and the OpenAI request snapshot.
- Agent previews now explicitly distinguish missing-key dry runs from API-ready turns.
- Headless smoke tests now cover request readiness, Responses API parsing, Chat Completions parsing, tool-call extraction, and HTTP error normalization.

### Follow-up Guidelines

- Add HTTP transport on top of this service, with streaming events, cancellation, retry policy, and clear timeout handling.
- Store model events separately from chat messages so tool calls, partial text, and final assistant messages stay auditable.
- Never log raw Authorization headers; audits should keep only key source and masked key state.

## 2026-06-04 Session Model Events

### What Happened

- Godex had a request readiness snapshot and parser, but session persistence still only had chat messages and approval records.
- Future streaming output, tool calls, retries, and errors need an event trail that is not rendered as ordinary assistant prose.
- Model events must be safe to persist, because session JSON is intentionally inspectable.

### Changes Made

- Added `model_events` to active sessions and default persisted sessions.
- Added `append_model_event()`, `active_model_events()`, and summary rows on `GodexState`.
- Agent turn preparation now records an `openai_request` model event with request readiness, endpoint, model, and masked authentication metadata.
- Model event storage redacts Authorization headers and drops raw payload fields before persistence.
- The Automation view now includes recent model event summaries alongside approval records.

### Follow-up Guidelines

- Streaming transport should append incremental text, tool-call, tool-result, retry, cancel, and final-response events through the same model event API.
- Chat messages should be derived from final assistant content, not from every transport event.
- Keep model event payloads compact; large raw OpenAI responses should stay out of persistent session JSON.

## 2026-06-04 MCP Tool Dispatch Readiness

### What Happened

- Parser output could already create pending tool-call events, but those events had no execution boundary.
- The MCP client only built a fixed context request, so future tool execution would have needed to special-case requests in the UI.
- Automation view summaries showed model events, but tool calls were still hard to distinguish from request/response audit entries.

### Changes Made

- Added generic MCP tool-call request construction and kept the existing summary context helper as a mapping layer.
- Added Agent dispatch readiness for pending tool calls, including approval gating, assisted-mode auto approval for low-risk calls, and `mcp_tool_dispatch` model events.
- Added state-level tool-call status updates so dispatched calls move from `pending` to `dispatch_ready` with request metadata.
- Added Automation view rows for recent tool calls, making pending and dispatch-ready state visible without mixing them into chat prose.
- Extended headless smoke coverage for context mapping, generic MCP request construction, approval-required dispatch, assisted dispatch, and pending-state clearing.

### Follow-up Guidelines

- Real HTTP transport should consume dispatch-ready MCP requests and append tool-result events through `append_model_event()`.
- High-risk MCP tools should stay blocked until per-call approval UI exists; assisted auto approval should remain limited to low-risk actions.
- Godot .NET MCP was sufficient for this validation pass. A future improvement would be a compact mock MCP tool endpoint helper for plugin tests, so Godex can validate request/response transport without relying on the live editor.

## 2026-06-04 MCP Tool Discovery Boundary

### What Happened

- Godex had dispatch-ready MCP requests, but no structured way to discover the tools exposed by the configured MCP server.
- The MCP page still mixed static capability rows with no discovery status, so available server tools could not be audited from the UI.
- Real HTTP transport is not in place yet, so discovery needed a testable request/parser/state boundary rather than UI-specific parsing.

### Changes Made

- Added `tools/list` request modeling and JSON-RPC compatible response parsing to `GodexMcpClient`.
- Added discovery cache fields to `GodexState`, including status, error text, timestamp, discovered tools, schema summaries, and a `mcp_tools_discovery` model event.
- Added Agent service helpers for discovery request preparation and discovery response handling.
- Updated the MCP view to show discovery status, tool count, error text, and compact discovered-tool rows.
- Extended headless smoke tests for tools/list request shape, parser normalization, discovery cache rows, and Agent discovery handling.

### Follow-up Guidelines

- The next transport feature should execute the prepared `tools/list` request against the configured endpoint and feed the response through `handle_mcp_tools_list_response()`.
- The MCP page should eventually gain search, server grouping, allowlists, and expandable schema details, but keep the default rows compact.
- No Godot .NET MCP blocker appeared in this pass; live editor validation should still clear Output after AssetLib/screenshot-related rendering noise.

### Validation Incident

- During live MCP-page validation, the connected editor endpoint stopped responding: two MCP calls failed with HTTP send errors, `Test-NetConnection 127.0.0.1:3000` returned false, and no Godot process was visible.
- The failure happened after prior editor screenshots and UI activation attempts, not during local Godex smoke tests. The immediate recovery path was to avoid terminating anything further, record the state, and relaunch the Mechoes editor to restore the MCP endpoint.
- Future validation should check the MCP port before repeated UI-control calls and keep Output clearing separate from screenshot capture, because AssetLib/screenshot rendering noise can obscure whether the editor is still healthy.

## 2026-06-04 MCP Discovery Transport Scaffolding

### What Happened

- A local PowerShell POST confirmed that the live MCP endpoint responds to `tools/list`, but the response shape uses `toolGroups` instead of a flat `tools` array.
- Godex's parser originally only accepted flat `tools`, and the UI could only show `request_ready`, making it hard to tell whether the transport had started, failed, or returned an unsupported payload.
- Live UI validation also showed that plugin source copies do not automatically reload an already-running Godex instance; explicit disable/enable is needed before judging runtime behavior.

### Changes Made

- Added JSON-RPC request body construction for `tools/list`.
- Extended `parse_tools_list_response()` to normalize both flat `tools` and grouped `toolGroups[].tools` responses, preserving the group label.
- Added a dedicated `HTTPRequest` node in the dock controller for MCP tool discovery and status events for request start, send, transport failure, HTTP failure, and parsed discovery results.
- Updated MCP summary rows to include group names in compact tool details.

### Follow-up Guidelines

- If live UI still remains at `request_ready`, validate whether the Godex instance was reloaded and whether `_show_mcp()` was actually invoked by the editor control path.
- Keep MCP transport small until OpenAI transport lands; the next durable step is a reusable HTTP transport helper shared by MCP discovery and future tool-call execution.
- Real discovery should be considered verified only when the MCP page shows a nonzero tool count from the live endpoint and Output remains clean.

### Live Validation

- After reinstalling the addon into the active Godot editor project and reloading the Godex plugin, the Godex main-screen tab was visible in the top editor bar.
- Opening the MCP page triggered the live `tools/list` request and the MCP summary showed `工具发现: ready · 28 项`.
- The discovered-tool rows included `system_project_state`, and the editor Output panel reported zero errors or warnings after the validation pass.

## 2026-06-04 MCP Tool Call Execution Transport

### What Happened

- Godex could parse model tool calls and produce dispatch-ready MCP requests, but execution still stopped before sending `tools/call` to the configured endpoint.
- The live MCP endpoint returns tool results as JSON-RPC `result.content[].text`, where the text can itself be a serialized JSON payload.
- The Automation view needed a small explicit execution action so pending or dispatch-ready calls can be advanced without pretending that OpenAI streaming is already complete.

### Changes Made

- Added JSON-RPC `tools/call` bodies to MCP tool-call requests.
- Added `parse_tool_call_response()` to normalize successful and failed MCP tool results, including serialized JSON text payloads.
- Added Agent service transitions from dispatch-ready to executing, then to succeeded or failed with model-event records.
- Added an Automation action button that executes the next available MCP tool call through an `HTTPRequest` node and refreshes the visible audit rows.
- Extended headless smoke tests for tool-call request bodies, response parsing, execution state transitions, and the new Automation scene node.

### Follow-up Guidelines

- The next high-value step is to create a deterministic UI test hook that injects a mock model tool call into the active session, so live validation can click through the entire Automation path without requiring a real OpenAI response first.
- OpenAI transport should reuse this tool-call execution boundary instead of creating a separate path for function-call results.
- Godot .NET MCP handled the live `tools/call` shape cleanly; no MCP plugin blocker was found in this pass.

## 2026-06-04 Automation Probe Tool Call

### What Happened

- The MCP execution layer was testable in headless logic, but live UI validation still depended on a real model response to create pending tool calls.
- Waiting for OpenAI transport before validating Automation execution would hide UI and session-state issues that can already be exercised through a local probe.
- The probe needed to use the same state and execution path as real tool calls so it would not become a disconnected demo action.

### Changes Made

- Added `inject_mcp_context_probe()` to create a local `godex_mcp_context` tool call tied to a model event.
- Added an Automation action button for injecting the probe call, next to the existing approval and execution controls.
- Extended headless smoke tests for the new scene node and isolated probe injection behavior.
- Changed the editor plugin entrypoint to load the controller script with cache-busting, after live validation showed that the scene could update while a preloaded controller kept old button behavior.

### Follow-up Guidelines

- Keep the probe visible while the Agent loop is still under construction; it is useful for validating tool execution after reloads and endpoint changes.
- Once OpenAI transport can reliably create tool calls from model responses, consider moving the probe behind a diagnostics toggle instead of leaving it as a primary action.
- No MCP capability gap was found; the current Godot .NET MCP endpoint is sufficient for this validation path.

### Live Validation

- Live validation first exposed that the updated scene could appear while a preloaded controller or service dependency still used old script code; this caused probe clicks to miss new methods even though the button was visible.
- After cache-busting the plugin controller, controller services, and Agent service dependencies, the Godex Automation page could inject `godex_mcp_context`, show the pending tool call, execute it through the live MCP endpoint, and show `工具调用 · succeeded` plus `mcp_tool_result · succeeded`.
- The final validation screenshot was saved to `user://godot_mcp/captures/editor/godex-probe-tool-call-succeeded.png`, and the editor Output panel reported zero errors.

## 2026-06-04 OpenAI HTTP Transport

### What Happened

- The composer could build an auditable OpenAI request and preview missing-key state, but it did not actually send an API request when authentication was ready.
- Read-only review confirmed this was the largest gap in the real Agent loop because MCP discovery and MCP tool execution already had HTTP transport.
- The next durable step was to wire the existing request snapshot and response parser into the controller instead of parsing OpenAI responses inside UI code.

### Changes Made

- Added a dedicated OpenAI `HTTPRequest` node to the Godex controller.
- The composer now keeps the previous dry-run preview when no API key is available, and sends the prepared transport request when authentication is ready.
- OpenAI request start, send, completion, and failure are recorded as session model events.
- HTTP and API responses are normalized through `GodexOpenAIExecutionService.parse_http_result()` and `GodexAgentService.handle_model_http_result()`.
- Successful model text is persisted as an assistant message; returned function calls are recorded as pending tool-call events for the Automation/MCP execution path.

### Follow-up Guidelines

- The next Agent-loop feature should feed MCP tool results back into OpenAI as tool result messages and continue the model loop until no tool calls remain or approval blocks execution.
- Add cancellation and retry controls before treating long-running OpenAI requests as production-ready.
- Keep raw Authorization headers out of model events and persisted session JSON; only masked request snapshots should be displayed.

## 2026-06-04 Tool Result Continuation

### What Happened

- MCP tool calls could execute and store normalized results, but the loop stopped there instead of returning tool output to OpenAI.
- The implementation needed to support both Responses API and Chat Completions-compatible payload shapes without duplicating transport code in the controller.
- A first validation pass caught a test fixture issue: a missing-key assertion reused state that still had another pending tool call, so the correct unresolved-tool guard fired first.

### Changes Made

- Added tool-result payload builders for Responses API `function_call_output` input and Chat Completions `tool` role messages.
- Added Agent continuation preparation that converts stored MCP results into OpenAI transport requests, while blocking safely when API credentials are absent or sibling tool calls remain unresolved.
- Updated the Godex controller so a completed MCP tool call prepares an OpenAI continuation request, but only auto-sends it in full-access approval mode.
- Extended headless smoke coverage for tool-result payload shapes, missing-key continuation blocking, ready continuation requests, auto-send approval gating, audit redaction, and unresolved sibling tool-call blocking.
- During live validation, the MCP editor-control layer rejected a tool execution click because the first implementation could have auto-sent an external OpenAI request after a local tool result. The design was tightened so assisted mode prepares and audits continuation requests without sending them.

### Follow-up Guidelines

- The next loop step should add automatic repeated execution: after a continuation response returns more tool calls, Godex should advance them until approval, cancellation, or final assistant text stops the loop.
- Add explicit cancel/retry UI before long-running OpenAI continuation requests are considered production-ready.
- Godot .NET MCP's risk rejection was helpful here; no plugin capability gap needs to be recorded, but Godex should keep external network sends behind explicit approval semantics.

## 2026-06-04 Explicit Continuation Queue

### What Happened

- The previous continuation implementation prepared tool-result OpenAI requests, but the only visible action path was still tied to the MCP tool completion callback.
- Live editor validation showed that implicit post-tool network behavior is hard for external automation to reason about, even after auto-send was limited to full-access mode.
- The Automation page needed a Codex-like review surface where prepared continuation requests are visible and sent through a separate user action.

### Changes Made

- Added a session-scoped pending OpenAI continuation slot with compact status, endpoint, model, API mode, key source, and transport metadata.
- The Agent service now records every continuation preparation into that slot, including blocked states for missing credentials or unresolved sibling tool calls.
- Added a `发送续跑请求` action to the Automation page and controller; it sends only a ready pending continuation request and clears it after dispatch starts.
- Automation summaries now show the latest continuation state before approval records, tool calls, and model events.
- Extended headless smoke tests for the new scene node, pending continuation summary, clearing behavior, and ready continuation retention.

### Follow-up Guidelines

- The send button should eventually open a compact preview popover showing endpoint, model, tool output summary, and estimated risk before dispatch.
- The next high-value Agent loop step is automatic repeated advancement after a continuation response returns additional tool calls, still stopping at explicit approval or cancellation.
- No Godot .NET MCP change was needed; the main improvement was making Godex's own network side effects explicit and reviewable.

## 2026-06-04 Godex UI Refresh Action

### What Happened

- Installing updated addon files into the active editor project did not update the already-instantiated Godex main screen.
- The plugin entrypoint already loaded the scene and controller with `CACHE_MODE_IGNORE`, but only during `_enter_tree()`, so the live Control tree stayed on the previous scene instance.
- This made visual validation ambiguous: the file copy was current, but the editor UI could still show old buttons until the plugin was disabled/enabled or the editor restarted.

### Changes Made

- Added `rebuild_main_screen()` to the editor plugin entrypoint, which removes the current Godex main screen, drops the controller, reloads the scene/controller, and restores visibility/distraction-free state.
- Added a compact `刷新` button in the Godex header and bound it to the new rebuild method.
- Extended headless smoke coverage so the plugin exposes `rebuild_main_screen()` and the main scene contains the refresh button.
- Documented the refresh action as an implemented capability in the feature-gap tracker.

### Follow-up Guidelines

- Future live validation should use the header refresh action immediately after installing a new Godex addon copy into the active editor project.
- If the refresh action itself disappears because the live instance predates it, use a plugin disable/enable or editor restart only with explicit user approval, since that is a wider editor-state action.
- No Godot .NET MCP issue was found; this was a Godex lifecycle gap.

## 2026-06-04 Continuation Preview Panel

### What Happened

- The Automation page had a pending continuation row and a send button, but the request details were still compressed into a single summary line.
- For external OpenAI requests, Godex needs a stronger review surface before transmission: endpoint, model, API mode, key source, status, and risk should be visible without opening logs.
- The implementation needed to stay compact and use Godot containers rather than adding a modal flow before the core Agent loop is mature.

### Changes Made

- Added a dedicated `ContinuationPreview` panel under the Automation action row.
- The controller now renders pending continuation metadata with status-aware title color and a concise multiline detail block.
- The preview reports blocked state and error text when credentials or unresolved tool calls prevent sending.
- Headless smoke coverage now asserts the preview node exists and that pending continuation metadata is retained for rendering.

### Follow-up Guidelines

- A later iteration should add an expandable payload preview with redacted tool output and a one-click copy action.
- The send button should eventually be disabled unless the pending continuation status is `ready`; for now the click handler blocks and explains non-ready states.
- No Godot .NET MCP capability gap appeared; this was a Godex UI review-surface improvement.

## 2026-06-04 Continuation Send Button Gating

### What Happened

- The continuation preview made request metadata visible, but the send button still looked available when no ready continuation existed.
- The click handler already blocked empty or non-ready states, yet Codex-style UI should communicate availability before the user clicks.
- Because the button can trigger an external OpenAI request, the safe default should be disabled until a ready request is present.

### Changes Made

- The Automation controller now derives the send button label, disabled state, and tooltip from the pending continuation status.
- Empty state shows `无续跑请求`; blocked state shows `续跑不可发送`; ready state restores `发送续跑请求`.
- Starting a continuation request immediately disables the button and changes the label to `续跑发送中`.
- Headless smoke coverage now checks that controller source still contains the continuation send-button gating path.

### Follow-up Guidelines

- The next refinement should make the preview panel visually expose why a blocked continuation is blocked, using a compact status marker rather than only tooltip/detail text.
- Once live reload is exercised in the active editor, visual verification should confirm the disabled state and text fit in the Automation action row.
- No Godot .NET MCP change was needed; the safety improvement is local to Godex.

## 2026-06-04 OpenAI Request Cancellation

### What Happened

- Godex could start real OpenAI HTTP requests but had no user-facing cancellation path.
- In an editor-embedded agent, long or stalled model requests must be interruptible without closing the editor or corrupting session history.
- The implementation also needed to avoid duplicate assistant messages if Godot still emits a completion callback after `HTTPRequest.cancel_request()`.

### Changes Made

- Added a disabled-by-default `停止` button beside the composer send button.
- The button is enabled while `is_running` is true and disabled when requests complete, fail, or are canceled.
- Canceling calls `HTTPRequest.cancel_request()`, records an `openai_transport` event with `status: canceled`, clears the active API mode, and appends a concise assistant audit message.
- Added `_openai_cancel_requested` suppression so a canceled request callback does not create a second failure/response message.
- Headless smoke coverage now checks that the cancel button exists and the controller keeps a cancellation path.

### Follow-up Guidelines

- Add a retry action next to canceled or failed request events, reusing the last redacted transport snapshot where safe.
- Streaming output should use the same cancellation state so partial assistant text can be finalized as interrupted.
- No Godot .NET MCP capability gap appeared; this is a Godex transport lifecycle feature.

## 2026-06-04 OpenAI Request Retry

### What Happened

- The stop action made stalled OpenAI requests interruptible, but a canceled or failed request still forced the user to reconstruct the prompt manually.
- Retrying cannot persist raw request headers to session JSON, because transport requests contain the Authorization header.
- The safest shape was a Codex-like explicit `重试` action that keeps raw transport data only in memory while exposing redacted retry metadata in the UI model and Automation summaries.

### Changes Made

- Added a retry slot to `GodexState` with redacted preview, summary, clear, and in-memory transport accessors.
- The controller now records failed start attempts, HTTP/API failures, and user cancellations as retryable requests.
- Successful OpenAI responses clear retry state, and retry sends are blocked while another OpenAI request is running.
- Added a disabled-by-default `重试` composer button next to `停止` and covered it in the headless scene smoke test.
- Extended smoke coverage to prove retry summaries do not expose raw API keys while the in-memory transport request still keeps raw headers for replay.

### Follow-up Guidelines

- Add a compact retry preview popover before replaying a large request, with endpoint/model/body-size and failure reason.
- Streaming should reuse the same retry state and mark partial responses as interrupted or failed without duplicating assistant messages.
- Live integration confirmed the updated files were installed into the active editor project and editor logs remained clean, but the currently instantiated Godex UI did not hot-refresh to show `重试`. Future work should make the header refresh action easier for automation to discover or expose a stable MCP-callable Godex refresh hook.
- No Godot .NET MCP capability gap was found; the remaining live-refresh friction is local to Godex's editor lifecycle.

## 2026-06-04 Composer Reasoning Propagation

### What Happened

- Godex already had Codex-style composer controls for model and reasoning effort, and model selection already changed the request model.
- Read-only audit showed that reasoning effort was persisted in `GodexState` and displayed in UI, but the real OpenAI payload and request audit did not receive it.
- A separate operator error briefly implemented the same idea in a different plugin repository. That local branch was not pushed, and the mistaken commit was immediately neutralized with a revert before continuing in Godex.

### Changes Made

- `GodexOpenAIRequestBuilder` now accepts request options for normal requests and tool-result continuation requests.
- Responses API payloads now include `reasoning.effort`; Chat Completions-compatible payloads include `reasoning_effort`.
- `GodexAgentService` passes `GodexState.reasoning_effort` into both first-turn and continuation payload builders.
- `GodexOpenAIExecutionService` extracts reasoning effort from payloads into request snapshots, and `GodexState.api_config_snapshot()` exposes the current selected effort.
- The composer controller now reads reasoning values through a helper instead of indexing the menu array directly.
- Headless smoke coverage now checks builder-level payloads, Agent turn payloads, audits, model events, selected model propagation, and continuation reasoning propagation.

### Follow-up Guidelines

- Provider/model metadata already contains reasoning variants for Yuren presets, but UI still offers the same four values for every provider. A later pass should filter or label reasoning choices from provider metadata while keeping custom providers editable.
- Visual validation should confirm the model and reasoning menus fit within the composer controls at narrow editor widths.
- No Godot .NET MCP capability gap appeared in this slice. The main development process lesson is to verify the active repository before committing when multiple similar plugin projects are present.

## 2026-06-04 Long Audit Text Collapse

### What Happened

- Live MCP screenshot validation showed the chat column rendering a full project-state payload with hundreds of script paths as one assistant bubble.
- The raw content was useful for audit and debugging, but it broke Codex-style chat ergonomics by turning the conversation into a wall of diagnostic text.
- Opening the standalone Godex project also generated `.uid` and `.import` files, making the repository look dirty even when feature source files were clean.

### Changes Made

- Added `.gitignore` rules for Godot-generated `.uid` and `.import` artifacts.
- Added chat rendering guards in `GodexDockController`: assistant messages above the configured length or line-count threshold now render as a compact preview with an explicit folded-content note.
- The full message content is still persisted in session data; only the chat display is folded, so auditability is preserved.
- Headless smoke coverage now checks that the controller keeps a long-message collapse path.

### Follow-up Guidelines

- A later UI pass should add an explicit expand/copy action or route large structured payloads into the Automation view as first-class model-event detail cards.
- The current fold is intentionally display-only. If persisted sessions grow too large, add a separate compaction policy rather than truncating messages at render time.
- No Godot .NET MCP issue was found; the MCP screenshot was the evidence that revealed the UI problem.

## 2026-06-04 Composer Micro-Interaction Regression Notes

### What Happened

- User reference screenshots exposed several small but important Codex desktop interaction mismatches in the composer.
- The approval mode pill changed state immediately when clicked, but Codex opens a permission menu and only changes mode after the user selects an item.
- The composer panel reserved a large blank area below the input controls, making the Godot UI feel heavier than the reference.
- `IDE 上下文` and `目标` controls should behave as active context pills: hidden when disabled, icon-led when enabled, and showing the close affordance only while hovered.

### Changes Made

- Replaced direct approval-mode cycling with a checked `PopupMenu` opened from the approval pill.
- A live validation attempt showed native `MenuButton` / `PopupMenu` was not reliably visible or enumerable through the current editor automation path, so the approval selector was changed to a Godex-owned compact panel inside the scene tree.
- Kept the blue approval icon emphasis and mode-specific tooltips while making the click action explicitly open options.
- Reduced the composer panel minimum height to remove the empty lower band under the controls.
- Added shared context-pill rendering for IDE context and goal tracking, including hover-only close icons and hidden disabled state.
- Added `/ide [on|off]` as a local slash command so IDE context can be restored even when the pill is hidden.
- Extended headless smoke coverage for the menu contract, compact composer height, hidden context pills, hover affordance copy, and `/ide` command behavior.

### Follow-up Guidelines

- Treat small screenshot-driven interaction notes as real regressions: fix them in code, pin them in smoke tests, and record the reason here.
- Avoid reintroducing direct click-to-cycle behavior for controls that visually advertise a dropdown or menu.
- Prefer scene-owned compact panels for composer popovers that must be verified by MCP screenshots and control enumeration.
- Any future composer redesign should keep disabled context pills out of the layout, while preserving slash-command or menu paths to restore them.
- No Godot .NET MCP issue needs project-level escalation from this slice; the native popup visibility limit was avoided by using scene-owned UI that MCP can inspect directly.

## 2026-06-05 Top-Right Layout Controls

### What Happened

- User screenshots showed that the Codex desktop top-right layout buttons were missing from Godex.
- The old Godex header only showed MCP endpoint text, connection status, and a `刷新` action, which made the header feel like diagnostics instead of Codex layout chrome.
- A related UX correction clarified that MCP and Plugins are not the same concept: MCP belongs in settings or `/mcp`, while `插件` remains a separate later-stage surface.

### Changes Made

- Added `HeaderLayoutControls` with three icon-only toggle buttons in the main header.
- The controls now toggle real layout state: floating progress panel visibility, a bottom output drawer, and the project/thread sidebar.
- Added `BottomDrawer` so the bottom-panel button is not a placeholder; it mirrors output summaries and hides outside chat views.
- Headless smoke coverage now checks the controls exist, have hover help, stay separate from MCP/Plugins/Automation navigation, and change layout visibility without moving the right rail back into `Body`.
- Documented the screenshot-guided icon workflow: use Codex screenshots as visual reference, generate flat chroma-key backgrounds when needed, remove the solid background locally, normalize resolution, and validate alpha before committing assets.

### Follow-up Guidelines

- Add richer side-pane modes once Godex has side chat, review/reference panes, terminal/browser launchers, and persisted panel widths.
- Keep right-header controls as layout chrome only. Do not bind them to `_show_mcp()`, `_show_plugins()`, `_show_automation()`, or tool discovery side effects.
- The image-generation experiment was blocked by `TooManyRequests`; no Godot .NET MCP limitation was involved. Future icon work should retry the same chroma-key workflow or fall back to Godot editor icons when the generated asset path is unavailable.

## 2026-06-05 Header Launcher and Transcript Width Regression

### What Happened

- User screenshots clarified that the left top-right Codex button is a launcher/menu entry, not a progress-panel toggle.
- The previous header still exposed MCP endpoint/status diagnostics as visible chrome, which conflicted with the Codex layout: MCP belongs in settings or `/mcp`, while Plugins remains a separate later-stage navigation surface.
- The main conversation had drifted into an edge-to-edge transcript: text could touch visual boundaries, and the restored borderless rows made the missing rounded outer panel more obvious.

### Changes Made

- Replaced the old progress toggle behavior with a momentary `LayoutMenuPanel` containing Codex-style entries for files, side chat, terminal, and recommended context sources.
- Kept the bottom output and sidebar buttons as the only true header toggles, and hid visible MCP endpoint/status/refresh diagnostics from the top-right header.
- Restored a rounded outer `MainPanel` frame while keeping transcript rows themselves transparent and borderless.
- Added a fixed-width centered transcript column with a short tween on width changes so side-panel changes produce a subtle horizontal slide instead of edge-to-edge snapping.
- Updated smoke coverage to verify the launcher is not a toggle, opening it does not hide the right progress rail, bottom/sidebar controls close it, and non-chat views do not show stale progress or bottom drawer overlays.

### Follow-up Guidelines

- Treat the three top-right controls as separate Codex concepts: launcher menu, bottom panel, and side panel. Do not route them to MCP, Plugins, Automation, or progress rail toggles.
- The launcher menu currently records recommended context candidates but does not yet implement a full file picker or terminal transport. Build those as separate complete features rather than stuffing them into this menu pass.
- No new Godot .NET MCP issue was found in this slice; headless smoke was enough to catch the stale function-name assertion and validate the scene-owned menu nodes.

## 2026-06-05 Command Run Approval State Machine

### What Happened

- Command transcript rows were visible and rebuildable, but command requests still had no execution-state boundary beyond `queued`, `running`, and manual status updates.
- A parallel read-only safety review highlighted the main risk: enabling command capability must not mean automatically running shell commands.
- Codex-style command rows need to be auditable before they become executable: the exact command, shell, working directory, approval checkpoint, and output status must all survive UI refreshes.

### Changes Made

- Added a command-run approval state machine in `GodexState`: command requests can create explicit approval checkpoints, record approval/rejection decisions, and execute only through a supplied runner after approval.
- Bound approvals to a command fingerprint containing command, shell, and working directory, so a changed command is blocked even after approval.
- Hardened `GodexCommandCapability` blocked patterns for destructive commands, shell proxying, encoded commands, pipes, redirects, and network download helpers.
- Added pre-run safety contracts for normalized shell names, project-local working directories, persisted timeout seconds, timeout-aware command fingerprints, and command-aware approval decisions routed through `decide_command_run_approval()`.
- Added Automation command approval and command-run summary rows so users can review command ID, command text, shell, cwd, timeout, fingerprint, and status without reading raw model events.
- Added separate Automation command action buttons: one creates a command approval checkpoint without executing anything, and the other attempts an approved command through the runner boundary while safely recording runner unavailable until a real transport exists.
- Added structured command transcript output sections for exit code, stdout, and stderr while keeping rows borderless and default-collapsed.
- Added transcript-projection redaction for command stdout/stderr so direct state updates receive the same API-key protection as normalized runner results.
- Added runner result normalization with bounded stdout/stderr and API-key redaction before transcript storage.
- Refined command transcript status labels so approval-required, approved, rejected, timed-out, cancelled, and blocked states render as readable Codex-style Chinese row text.
- Added headless smoke coverage for disabled command requests, dangerous command variants, unapproved runner blocking, approved fake-runner execution, and mutated-command rejection.

### Follow-up Guidelines

- Do not connect a real shell runner until shell enumeration, working-directory bounds, timeout/cancel handling, concurrency limits, and output redaction are all covered by tests.
- Treat the current cwd policy as project-local. Empty paths and `res://...` are supported; arbitrary OS paths should require a separate, explicit design before being allowed.
- Keep command execution semantics in state/core services. The UI should only display and toggle transcript rows.
- Automation buttons may route approval decisions, but they must not become hidden shell execution buttons until a separate runner transport is fully bounded and tested.
- Keep MCP action buttons and command action buttons visually close but semantically separate; `执行下个工具` must remain MCP-only.
- Treat transcript projection as a second safety boundary. Runner normalization is not enough because tests and future tools can still update command results directly.
- Live stdout/stderr panes and command groups should reuse the current `command_run` model instead of introducing transient UI-only logs.
- No Godot .NET MCP limitation blocked this slice; the current validation path was enough because the new work is state-machine and smoke-test driven.

## 2026-06-05 Changed-File Review Strip

### What Happened

- Codex desktop screenshots showed a compact changed-file review strip above the composer with a stable file count, green/red line deltas, and an expandable review surface.
- Godex already had a fixed-width centered transcript/composer column, so the main risk was adding the review strip inside `ComposerBox` or letting animated `+/-` values shift the prompt layout.
- A read-only subagent review confirmed that this slice should stay a state-backed summary surface first, not a direct git scanner or full diff/patch engine.

### Changes Made

- Added `GodexState.change_review_summary` with persisted file count, addition/removal totals, cropped file rows, expanded state, and session restore support.
- Added `ChangeReviewSurface` between `BottomDrawer` and `ComposerPanel`, outside `ComposerBox`, so it appears above the composer without changing composer height.
- Rendered fixed-width right-aligned addition/removal counters so values such as `+9`, `+93`, and `+1000` do not move adjacent controls.
- Added short numeric tweening for changed-file counters after stabilizing their width, matching the Codex feel without introducing layout jitter.
- Added expandable file rows with clipped paths and a hidden-file count, keeping the first implementation compact and auditable.
- Added a review action placeholder that records an assistant message instead of pretending a real diff pane or patch workflow exists.
- Added smoke coverage for state projection, session restore, scene placement, fixed delta widths, expanded file rows, and shared conversation-column width.

### Follow-up Guidelines

- Keep changed-file data in state or a future repository service. The UI controller must not read git status or scan the filesystem directly.
- Build the next pass as a real diff/review pane with undo/review actions, then wire it to audited patch application separately.
- Preserve the review strip as a sibling of `ComposerPanel`; do not put it inside `ComposerBox` or any input-control layout that changes composer height.
- Treat animated line deltas as layout-sensitive UI. Counters need stable width before and during numeric tweening.
- No Godot .NET MCP limitation blocked this slice; headless smoke and scene validation are sufficient until the future diff pane needs screenshot-heavy visual checks.

## 2026-06-05 Read-Only Git Change Summary Parser

### What Happened

- The review strip could render persisted state, but no safe data path existed to publish changed-file summaries into that state.
- A parallel read-only review warned that directly running `git` from the UI or controller would bypass the current command-run approval boundary.
- The right first step is a parser and local model-tool publication entry, not a real process runner or patch workflow.

### Changes Made

- Added `GodexGitChangeSummaryService` under `core/` to parse supplied porcelain/numstat text and structured file rows into `change_review_summary`.
- Added `godex_change_review_summary` to the model tool schema as a local state-publication tool that never starts a process and never applies patches.
- Routed that tool through `GodexState.record_tool_calls()` so it completes immediately, stores aggregate file/delta counts, and feeds the review strip.
- Added smoke coverage for modified, added, renamed, untracked, binary, and Chinese-path rows, plus explicit checks that no command-run event or approval checkpoint is created.

### Follow-up Guidelines

- Keep real git process execution behind a separate bounded transport. This parser accepts text/rows only.
- If a future provider invokes git, use fixed read-only verbs and fixed argument arrays; do not accept model-supplied shell commands or arbitrary working directories.
- Treat binary and unknown line counts conservatively as zero deltas while still counting the file.
- Do not reuse the command-run approval path for passive parser publication, but also do not let this parser become a hidden process-launch entry.

## 2026-06-05 Conversation Column Stability Fix

### What Happened

- Visual review showed the conversation shell had lost its Codex-like rounded boundary, and transcript text could sit too close to the left/right visual edges.
- The previous layout pass tried to account for the floating right rail by subtracting rail width from the transcript column and tweening `custom_minimum_size.x` on layout changes.
- That made right-rail, bottom-drawer, and sidebar toggles visibly squeeze or slide the conversation column, which is the wrong layer for Codex-style motion.

### Changes Made

- Removed right-rail width reservation from `_apply_conversation_column_layout()`. The right rail remains a floating overlay and no longer changes transcript/composer width.
- Removed width tweening from the shared conversation column; `Messages`, `ComposerPanel`, `BottomDrawer`, and `ChangeReviewSurface` now receive the same stable target width directly.
- Restored a visible rounded `MainPanel` style while keeping assistant, stream-step, tool, and command rows transparent and borderless.
- Added explicit transparent side padding to transcript rows so text keeps a Codex-like reading margin without narrowing the composer or bottom drawer.
- Updated the scene default so `BottomDrawer` starts with the same fixed column width as the composer and changed-file review strip.
- Added smoke coverage for rounded main chrome, stable widths across bottom/sidebar/right-rail visibility changes, and transcript row side padding.

### Follow-up Guidelines

- Do not use shared-column width tweens for pane toggles. Future Codex-like slide animation should live on the active center-view surface or scroll/transition wrapper.
- Keep `RightRail` under `ProgressOverlayLayer`; it should never return to the `Body` HBox or reserve layout width.
- If transcript content needs more or less breathing room, tune row padding rather than reducing the shared composer/review column width.
- No new Godot .NET MCP limitation blocked this slice; local headless validation caught the initial `BottomDrawer` scene-default mismatch before integration.

## 2026-06-05 Main-Screen Activation and Event Projection Hardening

### What Happened

- Live editor validation could enumerate the top `Godex` main-screen button, but clicking it through editor automation left `GodexMain.visible` false and the editor focus stayed on the script editor.
- Read-only review showed that the plugin had the normal main-screen callbacks, but no explicit activation fallback for automation or refresh flows.
- A parallel event-stream review found that `openai_request` events were stored but not projected into transcript items, and `openai_response.text` was dropped from the rebuildable conversation stream.

### Changes Made

- Added `activate_main_screen()` to `plugin.gd`, using Godot's `set_main_screen_editor("Godex")` before forcing the Godex root visible and deferring distraction-free entry.
- Kept the normal `_make_visible()` path but moved distraction-free entry to a deferred call so visibility can settle before layout changes.
- Added transcript projection for `openai_request` events, including API mode, model, reasoning effort, endpoint, key source, status, and error metadata.
- Preserved `openai_response.text` in transcript items and rendered text summaries when a response has no tool calls.
- Strengthened smoke coverage for plugin activation source contracts, OpenAI request/response event projection, and a real `_apply_model(state.to_model())` path that refreshes right-inspector artifact, sub-agent, and source rows.
- Fixed the right-inspector source empty state after live screenshot review showed `暂无来源` wrapping vertically inside the compact source `HBoxContainer`.

### Follow-up Guidelines

- Prefer explicit plugin activation helpers for editor automation when Godot's top main-screen buttons are visible but custom screen callbacks are not observably firing.
- Keep response/request details in model events and transcript projections, not ad hoc assistant messages, so UI refreshes remain rebuildable.
- Always inspect editor screenshots after right-rail layout changes; narrow `HBoxContainer` rows can make short Chinese empty-state text wrap vertically even when headless logic tests pass.
- Godot .NET MCP currently exposes only built-in main screens through `system_editor_control.set_main_screen`; custom main-screen activation should either use plugin-side fallbacks or a future MCP helper.

## 2026-06-05 Sidebar Codex Parity Correction

### What Happened

- Visual review showed that the Godex sidebar had drifted from Codex desktop: `已归档对话` was treated as a fifth primary top-nav item, several launcher recommendations were static placeholders, and thread hover rows could remain highlighted after the pointer left.
- The Codex reference should be treated as an interaction contract, not as permission to fill empty areas with plausible project files.

### Changes Made

- Kept the primary sidebar navigation limited to `新对话`, `搜索`, `插件`, and `自动化`.
- Moved `已归档对话` into the sidebar conversation/history area and kept its active highlight separate from the four primary app sections.
- Forced thread hover state to reconcile immediately and through the existing timer when pointer exit events fire, preventing stale rounded capsules after hover.
- Removed static recommended-file rows from the launcher menu until Godex has a real source/recommendation pipeline.
- Added smoke coverage for the four-item top-nav contract, archived placement, no fake launcher recommendations, and hover-state clearing.

### Follow-up Guidelines

- Treat Codex screenshots as strict constraints for visible navigation count, row grouping, and empty states.
- Do not add placeholder activity, source, output, or recommendation rows just because an area would otherwise be empty.
- Use generated artifacts for `输出`, invoked external tools/providers for `来源`, and keep history/navigation concepts out of the right inspector.

## 2026-06-05 Yuren Provider Settings Correction

### What Happened

- Live editor validation showed a mixed provider state: settings could still show `openai` and the OpenAI base URL while development expected an explicitly configured Yuren OpenAI-compatible endpoint.
- An older environment variable spelling, `YURENAPI_API_KEY`, was not normalized to the supplied `YUREN_API_KEY` contract.

### Changes Made

- Preserved the supplied Yuren OpenAI-compatible provider config in `docs/references/yuren-openai-provider.json`.
- Kept the same metadata in `GodexProviderCatalog`, including npm package, base URL, env-key reference, model limits, modalities, and reasoning variants.
- Added startup migration so explicit Yuren settings or legacy Yuren hints normalize to `yurenapi` and `YUREN_API_KEY`; invalid or empty Yuren base URLs fall back to the recommended `https://yurenapi.cn/v1`, while existing `https://yurenapi.com/v1` settings remain a valid persisted alternate.
- Kept Yuren as a non-default provider preset and added `.gitignore` safeguards for project-local settings snapshots.
- Added smoke coverage for provider identity, model order, attachment/reasoning support, token limits, modalities, `xhigh`, and settings migration.

### Follow-up Guidelines

- Provider changes need both catalog coverage and persisted-settings migration; otherwise the live editor can keep rendering stale `user://godex/settings.json` values.
- Treat environment variable names as API contracts and test typo migrations explicitly when a bad spelling has appeared in validation.

## 2026-06-06 Real Chat Loop Closure

### What Happened

- A live Godex chat attempt could send a request but fail to produce an observable final answer or tool loop closure.
- Read-only chain review showed three separate close-loop risks: non-standard providers can return a complete JSON response body while the stream connection remains open, review-mode approval stopped the Agent loop before approved user-prompt/retry requests could process returned tool calls, and Chat Completions-compatible payloads reused the Responses tool schema without the required `function` wrapper.
- The issue was not a settings default problem; Yuren remains a non-default provider preset, and the recommended `https://yurenapi.cn/v1` endpoint is only applied when explicit Yuren settings are selected or migrated.

### Changes Made

- Added early complete-JSON detection in the OpenAI `HTTPClient` body loop so a compatible provider that answers with JSON despite `stream=true` can close the assistant response before idle timeout.
- Kept partial JSON chunks and SSE `data:` events out of that early path to avoid falsely completing normal streams.
- Resumed the Agent loop when an approved `user_prompt`, `retry_request`, or `tool_result_continuation` OpenAI request is sent after review-mode approval.
- Converted Responses-style tool definitions into Chat Completions `{"type":"function","function":...}` entries at the request-builder boundary.
- Added smoke coverage for complete/partial/SSE body detection, approval-loop recovery, and Chat Completions tool schema conversion.
- Synced the changed addon files into the live Mechoes editor copy and verified with Godot .NET MCP project state, scene validation, script analysis, and editor logs.
- Added a parser follow-up for compatible Responses payloads that expose final text through top-level `output_text`, `text`, `refusal`, `response.output_text.done`, `response.refusal.done`, nested `response.completed.response.output_text`, or residual non-stream JSON convenience fields, preventing valid provider text from collapsing into the placeholder "model completed" message.
- Added controller-level headless coverage that runs a complete JSON body through `_try_finalize_openai_json_body_from_buffer()`, verifies the final assistant message, confirms stream/transport cleanup, and asserts the Agent loop stops with `final_model_response`.

### Follow-up Guidelines

- Treat "sent but no return" as a transport-state problem first: inspect stream buffer handling, approval state, and retry/continuation state before changing visible UI.
- Keep provider compatibility code in `openai_request_builder.gd` and `openai_execution_service.gd`; the UI controller should orchestrate lifecycle, not duplicate payload schema rules.
- When a turn ends with a placeholder completion message, inspect final-text extraction before changing prompt wording or right-inspector UI. Some compatible providers surface final text outside the canonical `output[].content[]` path.
- For controller-level no-return tests, instantiate the real Godex scene and run `_assign_nodes()` before finalization; the success path calls `_apply_model()` and needs real UI nodes, so hand-built minimal controls are too fragile.
- Future timeout work should split connection/requesting/body idle windows so high-reasoning models get a longer first-token window without hiding real dead connections.
- Godot .NET MCP validation was sufficient for editor-side reload and log checks here. For actual provider behavior, add a local fake HTTP server harness or a controlled live provider test so the stream state machine can be exercised without relying on manual chat attempts.

## 2026-06-06 Provider Secret Persistence Guard

### What Happened

- The Yuren provider configuration is useful for development and validation, but it must remain an explicit user/provider choice rather than becoming Godex's default configuration.
- Because Godex settings can include API base URLs, environment variable names, and optional inline API keys, persisted user settings must stay under Godot `user://` storage and must not be accidentally committed as project files.

### Changes Made

- Kept Yuren as a non-default provider preset while documenting both valid base URLs and recommending `https://yurenapi.cn/v1`.
- Added validation-time checks that reject tracked local/secret settings JSON filenames and obvious raw API key or bearer token literals.
- Left provider reference data in `docs/references/yuren-openai-provider.json` as environment-variable placeholders only.

### Follow-up Guidelines

- Never use a real provider key in docs, tests, screenshots, or tracked settings fixtures; use environment variable placeholders or short fake test tokens.
- Treat `https://yurenapi.cn/v1` as the recommended Yuren base URL, but keep `https://yurenapi.com/v1` as a valid persisted alternate; migration code must not rewrite an already valid user-selected alternate just because it is not the recommended endpoint.
- If a future settings export/import feature is added, validate redaction before writing the exported file and include an automated leak test in the same change.

## 2026-06-06 Sidebar and Settings Surface Parity

### What Happened

- Codex reference screenshots showed that sidebar top navigation and conversation rows share one selected surface: only one top app item or one active conversation should own the rounded selected capsule.
- Live Godex screenshots also showed two different failure modes to avoid: moving the settings rail into the conversation content makes settings feel nested, while removing the outer rounded frame makes settings feel like a hard-cut different surface.
- A later live settings screenshot exposed a state leak: the chat composer reasoning/model picker could remain visible after switching into the settings workspace.
- Another live composer screenshot showed the `+` menu still using an overlong context-source list, with rounded corners clipped against the composer and switch controls misdrawn by container layout offsets.

### Changes Made

- Added bordered hover/selected styling for top sidebar nav rows and smoke coverage that verifies search/plugins/automation selections clear active thread-row selection.
- Kept chat mode restoring the active conversation capsule while clearing top-nav ownership.
- Kept `MainPanel`'s rounded outer frame shared between chat and settings, while moving the settings rail into the shared app sidebar instead of nesting it inside the main content.
- Recentered the settings content with a fill-size `CenterContainer` inside the scroll area and widened the constrained content column, instead of relying on left/right spacer nodes.
- Closed composer popovers and thread action popovers whenever the active view leaves chat, with smoke coverage that opens the reasoning picker before entering settings.
- Reworked the composer `+` menu into a short Codex-style attachment/plan/goal/plugin surface, removed outer clipping from the popover shell, and rebuilt switches with explicit track/knob controls instead of relying on container-managed offsets.

### Follow-up Guidelines

- Treat sidebar state as a single active surface, not independent booleans on nav rows and thread rows.
- Settings should replace the central app workspace while preserving the same outer window shape as chat; do not solve settings layout drift by nesting more panels inside the chat surface or by dropping the shared rounded shell.
- For settings pages, keep the scroll container as the movement boundary and use a real centering container for the constrained content column; spacer-dependent centering is too easy to break when the settings rail is reparented.
- Treat scene-owned popovers as part of the view contract: every transition away from chat should close composer and thread popovers, not only hide the composer panel itself.
- For compact popovers, let only the rounded surface clip content. The outer positioning control should not clip, and switch-like widgets should use explicit child rects rather than offsets inside a container that may relayout them.
- When validating editor clicks through Godot .NET MCP, do not assume `click_control` or `activate_control` is equivalent to a Godot `Button.pressed` signal. Add a headless signal-connection test for critical composer controls, then use visual capture as a separate renderer check.
- For Codex-style switch controls, assert the intended footprint in tests. A switch that is built from stretchable containers can pass behavior tests while rendering as a thick square in the live editor.
- Godot .NET MCP's current `capture_editor` path captures `EditorInterface.get_base_control().get_viewport().get_texture().get_image()` and only attaches metadata from `editor_popup.list_visible`. It is not an OS/window compositor capture, and it has no `include_floating_windows`, `include_popovers`, or layer-diagnosis parameters.
- Godot .NET MCP's visible popup listing is class-based (`Window`, `Popup`, `PopupMenu`, `PopupPanel`, dialogs) under the editor base control. It does not identify scene-owned popovers implemented as ordinary `Control`/`PanelContainer` nodes, so Godex composer menus need separate control-tree visibility checks or a future MCP scene-popover diagnostic.

## 2026-06-06 Godot MCP Scene-Owned Popover Audit

### What Happened

- The user observed that Godex popover screenshots still needed manual confirmation, and asked whether this reflected a real Godot .NET MCP capability gap.
- Source review showed that `system_editor_control.capture_editor` delegates to the editor viewport texture screenshot path and only attaches `editor_popup.list_visible` metadata.
- The visible popup helper only treats native Godot popup roots such as `Window`, `Popup`, `PopupMenu`, `PopupPanel`, and dialogs as popups.
- Live MCP validation confirmed the boundary: `system_editor_control.list_popups` returned `count=0`, while `list_controls(include_hidden=true, text_query="计划模式")` could find the Godex `AddContextPanel` label with `visible=false` and an off-screen rect.
- A later live check in the same Mechoes editor session confirmed that the MCP transport itself was healthy: `system_editor_state` reported the active editor process, `list_controls` found the top `Godex` main-screen button, and visible editor controls were enumerable. The missing popup evidence was therefore not a disconnected-MCP problem.
- The same check still reported `list_popups` as `count=0` for Godex's scene-owned surfaces, because they are ordinary `Control` / `PanelContainer` nodes rather than native `Popup` or `Window` roots.
- This means Godex scene-owned popovers are inspectable as ordinary controls, but MCP cannot currently answer the more important visual question: whether the popover is open, inside the capture region, unclipped, and composited in the screenshot.

### Changes Made

- Recorded a root `SUGGESTION.md` follow-up for scene-owned popover screenshot and visibility diagnostics.
- Kept Godex composer popovers as scene-owned controls because they remain testable in headless scene logic and can be queried by control-tree tools.
- Separated validation responsibilities: headless tests should prove signal wiring, state changes, and layout invariants; live screenshots should be treated as renderer evidence only after a visible-state check.
- Added the working rule that `capture_editor` is editor viewport evidence, not an OS compositor screenshot. Floating editor windows and scene-owned overlays need separate window/layer diagnostics before a missing screenshot can be interpreted as a UI failure.

### Follow-up Guidelines

- Do not rely on `list_popups` for Godex composer menus, right-inspector overlays, or other ordinary `PanelContainer`/`Control` floating surfaces.
- For every critical scene-owned popover, add a headless test that directly emits the triggering signal and asserts the panel is visible, has the expected rect, and is not clipped by its immediate shell.
- When using MCP screenshots for these popovers, first query a known label or panel path with `include_hidden=true`, then verify `visible=true` and a plausible screen rect before interpreting the screenshot.
- If MCP click tools report success but the target popover remains hidden, treat it as an input semantics problem until a signal-level test proves otherwise.
- Keep the MCP improvement request focused on layer diagnostics and visible scene-owned control enumeration, not only on broader OS-level screenshots.
- When checking a suspected MCP limitation, first capture a small evidence bundle: `system_editor_state`, `list_popups`, a scoped `list_controls` query, and a screenshot path. This distinguishes transport health, popup classification, control visibility, and compositor coverage.

## 2026-06-06 Add Context Audit Events

### What Happened

- Codex reference screenshots show the composer `+` menu as a compact context surface rather than a generic long source list.
- Godex already had a scene-owned `AddContextPanel`, but the first row still behaved like a recommended-file shortcut and did not make project-summary context the primary action.
- Context actions also needed to appear in the same auditable information stream and right-inspector source model as external tool calls, otherwise the user could not tell which context sources had been explicitly attached.

### Changes Made

- Recentered the first-stage `+` menu around `当前项目摘要`, optional `添加推荐文件`, `计划模式`, `追求目标`, and `插件`.
- Recorded project-summary actions as `context_menu_action` events that create a local MCP context probe and render as compact transcript rows.
- Kept recommended-file rows conditional on the changed-file review summary and recorded both `file_context` and `context_menu_action` events when selected.
- Project-summary and file-context events now contribute explicit rows to the right-inspector `来源` section without treating them as generated output artifacts.
- Extended headless smoke coverage so the menu signal path, event projection, optional recommended-file row, switch footprint, and transcript items are validated together.

### Follow-up Guidelines

- Do not claim full attachment support until Godex can read selected file contents, handle photos/screenshots, and store context-item metadata separately from raw transcript text.
- Keep `context_menu_action` as the small auditable record for user-triggered context choices; large context payloads should live behind future context item/artifact references.
- Plan mode is still UI state only after this slice. Its next implementation should affect request planning/tool policy rather than only repainting the switch.
- Godot .NET MCP was sufficient for logic validation through headless tests, but visual verification of the scene-owned menu still needs the layer-diagnostics improvement recorded in root `SUGGESTION.md`.

## 2026-06-06 Plan Mode Request Boundary

### What Happened

- The composer `+` menu already exposed `计划模式`, but it only repainted a switch and did not affect Agent behavior.
- Local Codex reference `codex-rs/collaboration-mode-templates/templates/plan.md` defines Plan Mode as conversational planning: non-mutating exploration is allowed, execution requests should be treated as planning requests, and the actual plan should be decision-complete before execution.
- Godex needed a first implementation that changed request semantics without pretending to have the full Codex proposed-plan UI.

### Changes Made

- Promoted Plan Mode into `GodexState.plan_mode_enabled` and persisted it with the other agent settings.
- Toggling `计划模式` now records a `plan_mode` model event that appears as a compact transcript information row.
- `GodexAgentService` now injects a Codex Plan Mode instruction contract and omits OpenAI tool schemas for the next initial request when Plan Mode is active.
- OpenAI request audit rows expose `plan_mode=true` and `tool_count=0`, so screenshots and tests can distinguish planning turns from tool-enabled execution turns.
- Headless smoke coverage now verifies menu state, transcript projection, payload tool suppression, instruction injection, and settings persistence.

### Follow-up Guidelines

- Do not call this a full Plan Mode implementation yet. Godex still needs proposed-plan rendering, confirmation/exit behavior, and clearer UI affordances for plan-only turns.
- Keep Plan Mode enforcement at the Agent/request boundary. UI toggles should change state; request builders and orchestration should consume that state.
- Future tool-result continuation behavior should be reviewed separately. This slice only suppresses tools on the initial request and does not rewrite established continuation payloads.

## 2026-06-06 OpenAI-Compatible Conversation Loop Triage

### What Happened

- Live Godex testing reached the OpenAI request boundary but stopped on an HTTP 502 response, leaving the user with no final assistant answer.
- The provider URL and `YUREN_API_KEY` environment variable were confirmed by the user as real and usable, so the failure should not be framed as a likely user configuration mistake.
- The Yuren provider preset was missing the supported `gpt-5.4` model and the settings page still allowed free-form model text, making model compatibility harder to audit.

### Changes Made

- Added `gpt-5.4` to the Yuren provider capability metadata while keeping `gpt-5.4-mini` and `gpt-5.5`.
- Changed the settings page default-model field to a provider-catalog selector, so supported catalog models are offered for the selected provider.
- Normalized invalid persisted model names through `GodexState.set_model()` instead of letting unsupported model text reach the request builder.
- Captured bounded HTTP error bodies from manual stream transport and preserved provider error type/message in model events.
- Added a one-shot non-stream fallback after stream-compatible HTTP failures so providers that reject or fail SSE can still complete the same conversation turn.

### Follow-up Guidelines

- Treat provider presets as capability catalogs, not personal defaults. Never commit a real key, and keep user-selected provider settings in `user://godex/settings.json`.
- When a provider returns 5xx at the stream boundary, preserve the provider body before making assumptions. Prefer evidence in the transcript/right inspector over generic configuration blame.
- Keep OpenAI compatibility work focused on OpenAI-style endpoints, headers, payloads, model IDs, and response parsing; do not add provider-specific agent behavior unless the catalog metadata proves it is needed.
- Add live connectivity checks as separate diagnostics that redact keys and print only endpoint/model/status summaries.

## 2026-06-07 Provider Probe Boundary

### What Happened

- Manual external probes showed the configured Yuren endpoint and environment-variable key could return normal OpenAI-compatible responses, while the Godex editor UI still did not reliably close a real conversation with assistant output.
- That left an important gap between "the provider works outside Godot" and "the Godot editor process can send, receive, parse, and render a minimal response."
- The existing local model replay was intentionally offline, so it could prove parser/tool-call logic but not the Godot `HTTPRequest` transport path.

### Changes Made

- Added a `Provider 探针` Automation action backed by a separate editor-process `HTTPRequest` node.
- The probe sends a minimal non-stream request for the current API mode and model, using `/v1/chat/completions` for OpenAI-compatible chat providers and Responses payloads for Responses mode.
- Probe HTTP results now reuse `GodexAgentService.handle_model_http_result()` with `source=provider_probe` metadata, so diagnostics appear in model events without being treated as generated output artifacts or invoked external-tool sources.
- Added smoke coverage for the scene button, non-stream payload shape, reasoning-effort propagation, HTTP result parsing, source metadata preservation, and right-inspector boundary semantics.

### Follow-up Guidelines

- Use the Provider probe before debugging the full streaming Agent loop when a user reports "sent but no answer." If the probe fails, inspect endpoint path, Godot process networking, HTTP status/body, model ID, and key source first.
- If the probe succeeds but normal chat fails, focus on streaming `HTTPClient`, fallback finalization, approval/continuation state, and Agent loop stop reasons.
- Do not promote provider probe success to "conversation loop complete." It proves the smallest live request path only.
- Keep raw provider credentials out of docs, changelogs, screenshots, and model events. Persisted provider settings remain user-local under `user://godex`.

## 2026-06-07 Plain Chat Compatibility Fallback

### What Happened

- Live user testing still showed no successful assistant answer after a normal Godex prompt, even after Yuren provider settings, model choices, and stream-to-non-stream fallback had been tightened.
- The failure visible in the UI was an HTTP 502 after the real request was sent. Because the user confirmed the Base URL and `YUREN_API_KEY` are valid, the next likely risk was request-shape compatibility: streaming, tool schemas, or reasoning-only fields can fail on an OpenAI-compatible provider even when a minimal text request would work.
- A missing assistant answer is worse than a degraded answer for the core chat surface, but silently pretending tool-capable Agent execution succeeded would be misleading.

### Changes Made

- Added a one-shot plain Chat Completions compatibility fallback after a compatible-provider non-stream failure.
- The fallback reuses the same message payload but strips `stream`, `tools`, `tool_choice`, `parallel_tool_calls`, and `reasoning_effort`.
- The fallback now explicitly pins `api_mode=chat_completions` and recomputes the `/v1/chat/completions` endpoint if a stale request snapshot still points elsewhere.
- Credential-class failures such as 401/403 still do not trigger the fallback.
- The fallback is audited as `compatibility_fallback` and updates the same in-progress assistant message instead of appending a separate fake result.
- Added headless smoke coverage for payload stripping, status gating, credential exclusion, Chat-Completions-only scope, and Yuren-style Chat Completions SSE closure.

### Follow-up Guidelines

- Treat this as a text-conversation closure path, not a full Agent loop success path. If the fallback produces text, Godex should still record that richer tool/reasoning transport degraded.
- If the plain fallback succeeds repeatedly for a provider, add provider-capability metadata rather than leaving every turn to discover the same incompatibility at runtime.
- If the fallback also fails, keep the bounded provider body and retry summary visible; do not replace it with generic "check API key" text unless the status/body actually indicates credentials.
- Future live verification should compare Provider probe, stream request, non-stream request, and plain fallback statuses in the same conversation so the user can see exactly which layer failed.

## 2026-06-07 Yuren API Mode State Sync

### What Happened

- A read-only review of the provider/settings path found a more direct root-cause risk than provider reachability: selecting Yuren could call `set_provider()` and correctly apply `chat_completions`, then `_apply_provider_fields_to_state()` could immediately overwrite it from a stale API-mode `OptionButton` still showing Responses API.
- This risk also affected Provider Probe because the probe starts by applying current settings fields to state.
- Manual PowerShell HTTP probes with the local `YUREN_API_KEY` confirmed minimal non-stream, reasoning-enabled non-stream, stream, tool, and stream-with-tool Chat Completions requests can return HTTP 200 against `https://yurenapi.cn/v1/chat/completions`. `/v1/responses` also returned HTTP 200 for a minimal request. That evidence points away from "the URL/key/model are simply invalid" and back toward Godex state synchronization or request-shape handling.
- Separate MCP/system-tool attempts in the host session were rejected by an outer approval/service path returning `502 Bad Gateway` at `https://yurenapi.cn/v1/responses`. That is a verification-channel failure and must not be mixed up with Godex's own editor-process OpenAI request results.

### Changes Made

- Settings synchronization now blocks base URL, key, model, and API-mode control signals while applying provider preset fields.
- Yuren is forced back to Chat Completions during settings-state application if a stale UI control still reports Responses API.
- The settings API-mode widget is synchronized to "Chat Completions Compatible" when Yuren is active, so subsequent saves and probes resolve to `/v1/chat/completions`.
- Added smoke coverage that simulates the stale-Responses selector case and asserts the resulting snapshot endpoint stays on the Yuren Chat Completions path.

### Follow-up Guidelines

- When a live conversation shows HTTP 502, first separate three channels: host-side approval/tooling failures, Godot editor-process provider probe failures, and full Agent streaming-loop failures.
- Do not treat a stale settings widget as harmless. In Godot UI, signal order and programmatic field updates can mutate state before the user sees the final controls.
- Keep provider presets non-default and user-local, but once the user explicitly selects a preset, the catalog API mode should win over stale UI state.
- After each provider-state fix, rerun both `validate-godex.ps1` and a Mechoes reload/live chat attempt so local smoke coverage and editor-process behavior stay aligned.

## 2026-06-07 OpenAI Failure Stage Visibility

### What Happened

- After the Yuren API-mode and compatibility fallback fixes, the next risk was not another request-shape tweak but poor observability: a user could still see "no returned result" or a generic retry row without knowing whether the failing layer was Provider Probe, stream transport, non-stream fallback, or plain compatibility fallback.
- The existing model events already carried enough endpoint/model/status information, but the right progress row and compact transcript title collapsed several stages into generic OpenAI wording.
- This made screenshots hard to interpret and encouraged over-debugging credentials even when the actual issue was stream compatibility or fallback behavior.

### Changes Made

- Added stage labels for `provider_probe`, `stream`, `stream_fallback`, and `compatibility_fallback` without changing request payloads or transport behavior.
- Retry previews now preserve the stage so the right inspector can show labels such as `流式请求失败 · 可重试` instead of only `可重试`.
- OpenAI transport transcript rows now use the same stage vocabulary, including `Provider 探针失败`, `非流式回退`, and `纯文本降级`.
- Added smoke coverage for stage-aware right-inspector progress text and transcript titles.

### Follow-up Guidelines

- Keep fallback additions separate from observability additions. If a user reports another failed conversation, first read the stage label and tooltip before changing request logic.
- The stage label is diagnostic evidence, not a success claim. A plain fallback result can close a text answer while still indicating that the richer Agent/tool path degraded.
- Live-chat diagnostics now keep status code and bounded provider body previews in state-backed transcript items; future panels should reuse those fields while still avoiding provider payloads as `输出` artifacts.

## 2026-06-07 Runtime Provider Normalization and Empty Chat Fallback

### What Happened

- Manual probes showed the Yuren OpenAI-compatible endpoint and environment-variable key could return valid Chat Completions responses, but live Godex sessions still showed stale `/v1/responses` traffic and HTTP 502 failures.
- That meant the remaining risk was inside Godex state flow: settings could be correct on disk while an active Agent request, tool-result continuation, or retry snapshot still carried an older API mode.
- Another failure mode was semantic rather than network-related: a Chat Completions stream could complete with no text and no tool calls, and the old path would write `模型响应已完成。`, hiding a broken conversation loop behind a placeholder answer.

### Changes Made

- Added `GodexState.normalize_runtime_provider()` and call it at first-turn, tool-result continuation, and retry boundaries.
- Preserved the startup `settings_migrated` flag while normalizing runtime requests so a conversation send does not accidentally behave like a settings migration.
- Extended Chat Completions fallback triggers to stream timeout, disconnect, poll/request errors, empty HTTP responses, and empty Chat completions.
- Empty Chat completions now start the plain Chat fallback when possible; otherwise they become visible `empty_chat_completion` failures with retry state instead of placeholder success.
- Chat Completions parsing now accepts structured content part arrays for both non-stream messages and stream deltas.
- Added smoke coverage for stale Yuren runtime state, Yuren first-turn payload normalization, retryable stream errors, empty SSE completion, and content-part parsing.

### Follow-up Guidelines

- Treat Provider Probe success as a transport baseline only. A full conversation still needs request-shape, fallback, Agent loop, continuation, retry, and UI rendering coverage.
- When persisted settings look correct but live traffic hits the wrong endpoint, inspect the active transport snapshot and retry/continuation records before changing provider metadata.
- Do not allow empty model output to close the Agent loop as a successful answer. It should either degrade to a simpler compatible request or become a clear retryable failure.
- If future provider work adds more OpenAI-compatible services, prefer catalog capability metadata and request-boundary normalization over provider-specific Agent branches.

## 2026-06-07 Tool Continuation Plain Fallback Sanitization

### What Happened

- A read-only follow-up review found that the plain Chat fallback only removed top-level request fields.
- That was enough for first-turn text requests, but a tool-result continuation payload can contain Chat Completions protocol messages: an `assistant` message with `tool_calls`, followed by a `role=tool` message carrying the tool result.
- Resending those messages during a "plain text" compatibility fallback would contradict the fallback's purpose and could keep failing on the same provider capability boundary.

### Changes Made

- Added a fallback message sanitizer that keeps normal `system`, `user`, and `assistant` content while converting Chat tool-call requests and tool-result messages into readable plain text.
- The normal Chat Completions tool-result continuation path still uses proper `tool_calls` and `role=tool` messages; only the degraded plain fallback rewrites them.
- Added smoke coverage for the sanitized fallback payload and for stale Yuren runtime state building a ready Chat Completions tool-result continuation to `/v1/chat/completions`.
- Synced the updated addon scripts to the live editor project and reloaded Godex through Godot .NET MCP after local validation.

### Follow-up Guidelines

- Keep "standard Chat tool continuation" and "plain compatibility fallback" as separate contracts. A successful plain fallback is a degraded text answer, not proof that the provider accepted the full tool protocol.
- If live conversation still fails after this path, inspect whether the failing stage is first-turn streaming, non-stream fallback, plain fallback, or second-hop continuation before changing provider defaults again.
- Future Godot .NET MCP screenshot improvements would help here: floating popovers and transient menus still need better capture/targeting evidence so UI state bugs can be verified without relying on manual screenshots.

## 2026-06-07 Plain Fallback Stream Timer Boundary

### What Happened

- The normal composer send path uses a hand-polled `HTTPClient` stream, while Provider Probe uses a simple non-stream `HTTPRequest`.
- Plain Chat compatibility fallback switches from the stream client to an `HTTPRequest` retry, but it previously left the original stream timer/connection lifecycle implicit.
- That could let the old stream poll path keep updating "thinking" state or race with the fallback completion path, making a degraded-but-valid response look like another stalled conversation.

### Changes Made

- Plain Chat compatibility fallback now explicitly stops the previous stream timer and closes the stream client before starting the fallback `HTTPRequest`.
- Added smoke coverage that injects a running stream timer, starts the compatibility fallback, and asserts that the timer has stopped.
- Revalidated locally and reloaded the synced addon through Godot .NET MCP in the live editor project.

### Follow-up Guidelines

- Treat every transport handoff as a lifecycle boundary: stream-to-non-stream and stream-to-plain fallback should both stop the old poller before starting a new request.
- When a UI conversation appears to hang after fallback, inspect whether the old stream timer, active transport snapshot, and new HTTPRequest fallback agree on the current stage.
- Future live tests should exercise the full composer send button with a tiny response fixture or controllable provider stub, not only service-level parser fixtures.

## 2026-06-07 Short Command Runner Audit Metadata

### What Happened

- Codex and Claude Code command references both keep command execution as a structured event instead of a plain text blob: command, cwd, process or item ID, approval/policy state, stdout/stderr or aggregated output, exit code, duration, timeout/cancel state, and streaming output deltas.
- Godex already had approval-bound command runs and a first-stage `OS.execute` short-command runner, but the result shape still looked too close to a full terminal result while hiding important runner boundaries.
- The current Godot runner cannot expose a process ID, hard-timeout a process tree, stream stdout/stderr separately, or terminate a running `OS.execute` call. It also captures stderr merged into stdout when `read_stderr=true`.

### Changes Made

- Added state-level result normalization for `combined_output`, `runner_kind`, `duration_ms`, `stderr_merged`, `stderr_notice`, and `timeout_enforced`.
- Updated the local short-command runner to report `runner_kind=godot_os_execute_sync`, elapsed duration, merged output, and `timeout_enforced=false` for every completed attempt.
- Extended command transcript rows and Automation command summaries to show runner, duration, combined output, stderr merge handling, and timeout-enforcement boundaries without turning command output into right-inspector artifacts.
- Added smoke coverage for state storage, transcript projection, UI output sections, duration-bearing timelines, and custom fake-runner metadata.

### Follow-up Guidelines

- Treat the current runner as a short-command audit bridge. It is useful for bounded diagnostics, but it is not a Codex terminal or background process manager.
- The next command milestone should replace the synchronous runner behind the existing state boundary with a process manager that records process IDs, hard timeout enforcement, separated stdout/stderr streaming, output caps, cancellation, and background polling.
- Godot .NET MCP could help future validation by exposing a safe editor-side process/terminal probe that returns separated stdout/stderr and process lifecycle evidence without requiring Godex to risk blocking the editor during experiments.

## 2026-06-07 Session-Backed Goal State

### What Happened

- Godex had a composer `目标` pill and `/goal` command, but both were effectively a global boolean plus an optional system message.
- The Codex reference keeps goals as thread-level state with objective, status, usage, and lifecycle metadata, so Godex needed a session contract before richer goal cards or auto-resume behavior could be credible.

### Changes Made

- Added an `active_goal` record on the active session with objective, status, created/updated timestamps, elapsed/token placeholders, source, visibility, and enabled state.
- Upgraded `/goal` to set, pause, resume, complete, or clear the session goal without starting an OpenAI request.
- Projected goal changes into transcript `goal_state` rows, Automation summaries, capability previews, and the composer goal tooltip.
- Injected enabled goals into Agent instructions and turn audit so model behavior is aligned with the active thread objective.
- Added smoke coverage for slash command behavior, session restore, transcript projection, Automation rows, and Agent request injection.

### Follow-up Guidelines

- Keep goal state session-scoped. Do not reintroduce a global-only toggle when adding richer goal cards.
- Budget and token accounting fields are placeholders until Godex has durable request usage statistics; future work should update those fields through the same state API.
- Paused and completed goals should remain recoverable as thread state, while only active or blocked goals should inject model context.

## 2026-06-07 Session-Backed Sub-Agent Task Records

### What Happened

- The right progress inspector had a sub-agent section, and `GodexSubagentManager` could create local queue metadata, but the record was still too close to a one-turn event.
- Codex desktop references treat sub-agents as thread/session entities with lifecycle state, prompt/model context, and inspectable results.
- Without a session-level task record, Godex could not restore sub-agent cards after UI refresh or distinguish durable work state from a transient progress row.

### Changes Made

- Added session-owned `subagent_tasks` records with stable IDs, session/parent-thread IDs, name, role, branch, read-only flag, prompt, model, reasoning effort, status, timestamps, summary, result, and error fields.
- Added `record_subagent_task()`, `update_subagent_task()`, and `active_subagent_tasks()` state APIs, while still projecting task changes into model events for the conversation information stream.
- Updated the right progress inspector to prefer session-backed sub-agent records and fall back to legacy `subagent` model events for older sessions.
- Added Automation summary rows for sub-agent tasks and smoke coverage for record updates, restore behavior, right-inspector rendering, and Automation exposure.

### Follow-up Guidelines

- Keep the task-card record separate from a real runner. Future parallel execution should update these state records instead of inventing a second UI source.
- The next sub-agent milestone should define isolated execution/session ownership, cancellation, failure recovery, and result handoff before launching real external workers.
- Godot .NET MCP validation remains useful for checking the editor-visible task surface, but richer sub-agent work will need fixtures that simulate concurrent lifecycle transitions without mutating project files.

## 2026-06-07 Bottom Terminal Command Audit Drawer

### What Happened

- Codex screenshots show a bottom terminal panel coexisting with the active chat, progress rail, and edited-file strip.
- Godex already had a bottom-panel toggle, but the drawer only mirrored artifact rows from the right inspector.
- That blurred two contracts: generated artifacts belong in `输出`, while terminal/command state should show command execution audit, runner boundaries, and output history.

### Changes Made

- Converted `BottomDrawer` into a fixed-width scrollable terminal audit surface with a command-run empty state.
- Rebuilt the bottom panel from recent session `command_run` events instead of from `outputs`.
- Added compact rows for command status, command text, shell, working directory, timeout, runner kind, exit code, duration, timeout-enforcement limitations, stderr merge handling, bounded output preview, and recent timeline transitions.
- Added smoke coverage that opens the bottom panel, checks the empty terminal state, records a completed command event, and verifies the drawer renders command, runner, output, and timeline evidence without resizing the conversation column.

### Follow-up Guidelines

- Keep command output out of the right-inspector artifact list. The bottom terminal is the place for stdout/stderr and command lifecycle evidence.
- This remains a command audit drawer, not a full long-running terminal. The next terminal milestone still needs process IDs, separated live streams, hard timeout enforcement, cancellation, and background sessions.
- Godot .NET MCP would make future validation stronger if it exposed editor-side screenshot targeting for scrollable bottom panels and safe process lifecycle probes with separated stdout/stderr.

## 2026-06-07 Composer Send Action Queue and Guide Menu

### What Happened

- The Codex desktop screenshot `codex-composer-queue-guide-menu.png` shows the send button exposing alternate actions, including queueing a message and guide/instruction-style submission.
- Local Codex source review showed that `queued_user_messages` are not the same thing as live steers, and that running-turn steers, rejected steers, and review-mode steer rejection have distinct state transitions.
- Godex only had a direct send button, so the first credible step was to add a visible and auditable menu without pretending to implement the complete Codex runtime queue/steer protocol.

### Changes Made

- Added `SendActionPanel` under `ComposerPopoverLayer` with immediate send, `加入队列`, and `作为指南指令` rows that do not resize the composer.
- Added session-backed `queued_user_messages` and `pending_steers` records, transcript projections, Automation summary rows, and send-button tooltip counts.
- Added next-turn guide instruction injection in `GodexAgentService`: the pending guide is included once in request instructions, then marked `submitted` so it does not become a permanent system instruction.
- Added smoke coverage for scene nodes, menu signal wiring, popover layout, queued-message recording, guide recording, transcript projection, Automation summaries, and Agent guide-instruction submission.

### Follow-up Guidelines

- Keep queued user messages, pending guide instructions, and future live steers as separate state records. Do not collapse them into ordinary chat messages or permanent system prompts.
- The next queue milestone should drain queued messages only after the current Agent loop reaches a safe terminal state and should preserve rejected steers ahead of normal queued user messages.
- The next steer milestone needs an explicit running-turn interruption/steer boundary, including review-mode rejection behavior, before the UI claims to support live steering.
- Godot .NET MCP validation can visually confirm the scene-owned send menu, but future MCP diagnostics would be stronger if they could set editor TextEdit content and read scene-owned popover rows directly without relying on broad control listings.

## 2026-06-07 Composer Queued User Message Drain

### What Happened

- The send action menu could persist queued user messages, but those records stayed as audit-only entries instead of entering the next turn.
- Local Codex source review showed the queue boundary as a single-message drain that only starts when the user turn is no longer pending or running.
- Godex needed a conservative first implementation that would not consume queued messages when credentials are missing, a draft is still in the composer, or a request is already in flight.

### Changes Made

- Added `next_queued_user_message()` and `mark_queued_user_message_submitted()` to `GodexState`, including `submitted_turn_id` transcript projection.
- Split the controller send path into `_send_prompt_text()` so a queued message can reuse normal slash-command, approval, OpenAI request, and audit behavior.
- Added `_maybe_send_next_queued_user_message()` to drain exactly one queued message when the Agent loop is idle, OpenAI is not busy, API credentials are available, and the composer is empty.
- Deferred queue drain after successful final model responses and preserved `queued_user_message` source metadata through OpenAI approval requests.
- Added smoke coverage for FIFO queue selection, submitted-turn attribution, missing-credential protection, draft protection, approval-source preservation, and idle queue drain.

### Follow-up Guidelines

- Keep queue drain single-step until rejected-steer priority and review-mode semantics exist; do not silently drain the whole queue after one completion.
- Missing credentials, busy OpenAI transport, and unsent composer drafts must continue to block automatic drain without mutating queued record status.
- Godot .NET MCP validation would be stronger if control activation could report whether a Godot `Button.pressed` signal actually emitted, because queue-menu validation currently still needs headless signal assertions plus visual/control-tree checks.

## 2026-06-07 Queued Shell Prompt Approval Handoff

### What Happened

- Local Codex source review showed queued input supports separate actions: plain user messages, queued slash parsing, and queued shell prompts.
- Godex already had a guarded command-run state machine, so the safe parity move was to hand queued `!` prompts into that approval boundary instead of adding a second shell path.
- A parallel read-only review confirmed the key constraints: keep `CommandCapability` safety checks, command approval checkpoints, approval fingerprints, and single-running-command gating intact.

### Changes Made

- Added `queue_user_message_with_action()` so queued records can carry `plain`, `parse_slash`, or `run_shell` action metadata while preserving the existing plain helper.
- Updated the send-action queue path to record composer text beginning with `!` as `run_shell`.
- Added a queued shell handoff in the controller: `!echo hi` becomes a `command_run` record for `echo hi`, immediately requests command approval, and stops there until the existing approved-command runner path is used.
- Allowed queued shell prompts to drain without an OpenAI API key, while ordinary queued messages still require credentials before they are consumed.
- Added smoke coverage proving queued shell prompts become submitted queued records, command-run approval records, pending command approvals, and do not execute before approval.

### Follow-up Guidelines

- Do not route queued shell prompts directly to `_run_local_command()`; approval, fingerprint checks, concurrency checks, and output sanitization must remain centralized in `GodexState`.
- Non-empty queued shell prompts should not automatically drain later normal queued messages until command approval/execution state has advanced.
- Godot .NET MCP could improve future validation by exposing a focused command-approval control snapshot and by reporting whether a command action button is disabled because of queued, approval-required, approved, or running command state.

## 2026-06-07 Queued Slash Command Drain

### What Happened

- The Codex queue research already identified three queued input actions: plain user messages, queued slash parsing, and queued shell prompts.
- Godex had a partial slash path because `_send_prompt_text()` already reuses `_handle_slash_command()` for any `/` prompt, but the send menu still recorded `/...` drafts as plain queued messages and the queue drain gate still required an OpenAI API key.
- This made queued local commands less useful than direct slash commands even though they should remain local workflow operations.

### Changes Made

- Updated the send action queue path so `/...` composer drafts are recorded with `action=parse_slash`.
- Allowed `parse_slash` queued records to drain without an OpenAI API key, matching the existing `run_shell` exception while keeping ordinary queued messages credential-gated.
- Kept execution inside `_handle_slash_command()` and `GodexState.execute_slash_command()` so queued slash commands reuse the same local command semantics, transcript messages, view switching, and state effects.
- Added smoke coverage for queued `/goal` drain: the record stays queued until drain, drains without API credentials, marks `submitted_turn_id=queued_slash_command`, and updates the active goal.

### Follow-up Guidelines

- Keep queued slash commands as local workflow commands, not OpenAI prompts. Unknown slash commands should still remain unhandled instead of silently becoming model input.
- Do not add a second slash execution path for queued records; `_handle_slash_command()` is the UI boundary and `GodexState.execute_slash_command()` is the state boundary.
- Godot .NET MCP visual validation could use a more reliable scene-owned popover click/pressed confirmation; screenshots showed the Godex main screen after reload, but headless signal assertions remain the stronger evidence for send-menu row activation.

## 2026-06-07 Pending Guide Instruction Cancellation

### What Happened

- The Codex reference screenshot and local research support separate queue actions for normal queued messages and guide/instruction-style input.
- A parallel read-only review confirmed that `pending_steers` should remain separate from `queued_user_messages`, and that future rejected/running steers need their own state transitions instead of being collapsed into chat messages.
- Godex could already record and inject a pending guide once, but users had no way to withdraw that pending guide before the next Agent request was built.

### Changes Made

- Added `cancel_pending_steer()` to `GodexState`, preserving a `cancelled` audit record with source and timestamp metadata.
- Extended the send action menu so an active pending guide instruction displays a previewable `取消指南指令` row beside the queued-message cancellation affordance.
- The cancellation action clears the active guide path, persists the session, and prevents cancelled guidance from being injected into `GodexAgentService.prepare_turn()`.
- Added smoke coverage for menu-row visibility, preview text, cancellation audit records, inactive-guide selection, and cancelled-guide non-injection.

### Follow-up Guidelines

- Continue keeping guide instructions, future rejected steers, and normal queued user messages as distinct session records.
- Do not claim live steer support until there is an explicit running-turn interruption boundary and review-mode rejection behavior.
- Godot .NET MCP would make this easier to validate visually if scene-owned popover controls could be activated and reported with explicit signal-emission results instead of relying mainly on broad control enumeration plus headless signal tests.

## 2026-06-07 Durable Context Compaction Evidence

### What Happened

- Codex reference material exposes explicit thread compaction and context-compaction event concepts, while Godex only had a manual `/compact` path plus an automatic in-memory message rewrite inside request preparation.
- That meant an automatically compacted turn could build a smaller payload, but the session, transcript rebuild, Automation page, and capability preview did not all share one durable compaction record.
- A read-only parallel review confirmed the smallest useful next step was not remote/model-generated compaction, but a single session-scoped compaction state boundary that both manual and automatic paths can publish.

### Changes Made

- Added `last_compaction` state with source, automatic flag, removed/kept counts, before/after token estimates, timestamp, and summary preview.
- Routed `/compact`, composer-menu compaction, and threshold-triggered Agent turn compaction through the same state boundary.
- Updated Agent turn preparation so automatic compaction writes the compacted message history back to the active session before building the OpenAI payload.
- Added transcript and Automation rendering for `session_compaction`, plus smoke coverage for manual compaction, automatic compaction, payload reuse, and Automation visibility.

### Follow-up Guidelines

- Keep estimated token counts clearly separate from real OpenAI usage until transport usage metadata is available.
- The next compaction milestone should add a richer compaction history list or remote/model-generated summary, not another separate compaction path.
- Godot .NET MCP would be stronger here with a targeted control-text snapshot helper for a specific scene subtree, so Automation row contents can be visually asserted without scraping broad editor screenshots.

## 2026-06-07 Context Window Warning And Compaction History

### What Happened

- After compaction became durable, the UI still showed only current token estimates and the latest compaction result.
- Codex and Claude references both treat context-window pressure as a first-class user-facing signal: users should know they are approaching automatic compaction before it happens, and compaction events should remain inspectable after the transcript rebuilds.
- Godex needed a state-owned warning projection so future real usage statistics can replace the current estimates without duplicating threshold logic in UI code.

### Changes Made

- Added `context_window_warning()` to centralize context percentage, auto-compaction threshold, tokens remaining, and user-facing warning text.
- Added bounded compaction history previews and Automation summary rows so recent manual/menu/automatic compaction events stay visible beyond the latest record.
- Updated capability details and Automation rows to show low-context warnings and recent history without hard-coding thresholds in `GodexDockController`.
- Moved the composer affordance closer to Codex/Claude behavior: the add-context button now warns when the thread is close to compaction, the menu exposes current-session compaction, and send-button tooltip copy previews automatic compaction.
- Passed the state-owned auto-compaction threshold into `GodexContextCompressor.should_compress()` so warning UI and actual trigger logic stay aligned.
- Extended smoke coverage for warning status, tokens-until-auto-compaction, history entries, and Automation rendering.

### Follow-up Guidelines

- Keep context-warning thresholds in `GodexState`; UI code should only render state projections.
- When real model usage arrives, replace the estimated `context_used` source while preserving the warning/history contract.
- Godot .NET MCP could improve this workflow with a small scene-subtree text extraction tool for a named control, making Automation UI assertions possible against the live editor surface instead of only headless controller scaffolds.

## 2026-06-07 Chat Transcript Signal Correction

### What Happened

- Visual comparison against Codex showed that Godex had over-corrected toward an audit log: successful OpenAI request/build/send/response events appeared as checkmarked chat rows.
- Short CJK user prompts were right-aligned but too narrow, causing the bubble to feel cramped instead of matching Codex's comfortable right-side prompt shape.
- The useful distinction is not "everything successful gets a checkmark"; it is "human-readable conversation and real actions stay visible, successful transport bookkeeping hides, failures remain readable."

### Changes Made

- Added content-aware user bubble widths with a Codex-like minimum and maximum so short prompts stay on one line when possible and long prompts wrap inside the transcript column.
- Changed the streaming status from elapsed-time text to a lightweight `正在思考` row with a left-to-right shimmer, and clear it automatically on successful completion.
- Kept OpenAI request, transport, response, and raw stream-trace diagnostics in model events/progress surfaces while filtering them out of `active_transcript_items()` and the transcript renderer.
- Left failures visible through the assistant error path so retryable provider/network problems still have chat-level evidence.
- Added semantic icons for tool and command transcript rows so real editor/file/tool/terminal actions are distinct from hidden OpenAI transport bookkeeping.
- Added full-width hover-highlight disclosure headers for tool and command rows so each individual use can be clicked open for its own details without expanding unrelated rows.

### Follow-up Guidelines

- Do not reintroduce successful OpenAI transport events as chat rows. Put those details in Automation, model-event audit, progress, or a future explicit trace inspector.
- Keep the chat transcript optimized for user messages, assistant text, failures, and user-meaningful actions such as tool calls, file edits, and command runs.
- When adding richer action rows, prefer semantic icons and grouped disclosures over status checkmarks for every lifecycle step.
- Keep tool and command rows independently expandable. Group summaries may sit above them later, but each concrete use still needs its own inspectable disclosure row.

## 2026-06-07 Direct Composer Send And Queue Rows

### What Happened

- Visual comparison against current Codex showed that the send button should not open a floating send-method menu.
- The expected shape is simpler: idle composer clicks send immediately; running composer clicks queue the typed user message; queued messages appear above the composer with `引导` and delete actions.
- The input surface also should not show hover instructions, and queue/guide bookkeeping should stay outside the chat transcript.

### Changes Made

- Rewired the composer send button to `_on_send_button_pressed()` so idle sends still use the normal prompt path while running turns record queued user messages.
- Added a compact `ComposerQueueSurface` above the composer, with per-row preview text, `引导`, delete, and overflow affordances.
- Routed queue-row guide actions through the existing pending-guide instruction boundary, then direct-send when idle or preserve a queued direct-send record while a turn is still running.
- Removed the legacy `SendActionPanel` scene node and controller path so the send button cannot open the old send-method popup.
- Removed hover tooltip text from the composer input and from tool/command disclosure headers.
- Updated smoke coverage to assert direct-send wiring, running queue rows, guide/delete actions, and no legacy send-menu popup from the send button.

### Follow-up Guidelines

- Keep the send button as a primary action; do not reintroduce a send-method popup unless a future design explicitly makes it a secondary overflow control.
- Keep queued messages visible as composer-adjacent pending user intent, not chat transcript messages.
- Continue routing guide behavior through pending steer records until a real running-turn steer protocol exists.

## 2026-06-07 Tool Transcript Status Normalization

### What Happened

- A follow-up audit of the Codex-style transcript showed that OpenAI request/build/send diagnostics were already correctly hidden from chat and preserved as model-event audits.
- The remaining mismatch was smaller but user-visible: real MCP tool execution can finish with `succeeded`, while the UI only localized `completed`, so successful tool rows could leak an internal status token.
- This matters because tool/command rows should read like intentional editor actions, not raw transport records.

### Changes Made

- Normalized `succeeded` tool-call transcript status to the same localized `已运行` label used for completed tool rows.
- Updated smoke coverage to replay the real `succeeded` path and assert that both streaming and successful tool rows localize correctly.

### Follow-up Guidelines

- Keep OpenAI transport diagnostics out of the chat transcript unless they fail and need user-visible retry evidence.
- Continue treating tool and command transcript rows as action disclosures: semantic icon, hover highlight, per-use expansion, and localized status text.
- Godot .NET MCP would help future UI audits if it could expose a compact semantic tree of visible transcript row names, texts, and expansion state after plugin reload.

## 2026-06-07 Composer And Inspector Contract Tightening

### What Happened

- A batch of Codex visual references exposed several coupled regressions: assistant replies were being treated like foldable audit text, right-side progress was leaking transport/tool lifecycle rows, the composer still had separate stop/retry controls, and the sidebar needed a real resizable rail shared with settings.
- The user also clarified a new quote/input pipeline: transcript output must be selectable and copyable, selected snippets should offer floating actions, and selected text/images/materials should become composer references above the prompt.

### Changes Made

- Reframed the right-side `进度` surface as a model-controlled short-term plan/memory checklist backed only by explicit `progress_items`.
- Kept assistant replies fully visible while preserving collapsible disclosure only for real tool and command details.
- Consolidated composer send/stop into the single primary button and removed the scene-level stop/retry controls.
- Added a sidebar resize handle and persisted `sidebar_width` setting so chat and settings share the same rail width.
- Recorded selected-text quote and image/reference input as a high-priority attachment-model gap instead of losing it behind the active layout fixes.

### Follow-up Guidelines

- Do not infer `progress_items` from OpenAI events, tool calls, command runs, or retries; the model or explicit state transition must publish plan items intentionally.
- Treat transcript text selection as a real input feature: selection toolbar actions should create composer reference chips, not hidden model-event notes.
- Image input should share the same reference-item model as selected text and files so future request builders can serialize multimodal parts consistently.

## 2026-06-08 Codex Turn Loop And UI Blocking Fix

### What Happened

- Live Mechoes screenshots showed a severe Agent-loop mismatch: repeated MCP tool calls rendered as separate `已运行/失败` rows, while the same logical call should update one disclosure row from running to terminal state.
- The UI also drifted away from the Codex reference: sidebar section headings such as `项目` and `对话` were redundant, the right inspector was too narrow and text too small, the `正在思考` and tool-call rows were hard to read, and the send/stop icon lacked the white circular affordance visible in Codex.
- The user clarified several Codex semantics that Godex must preserve: no fixed 12-step Agent loop cap, no new tool batch without a model continuation opportunity, guide messages wait for the next safe turn boundary, and subagents are autonomous child Agents/threads rather than normal chat rows.
- Attempting to fetch current official OpenAI Codex docs from the local `openai-docs` skill failed because the environment could not connect to `developers.openai.com`, so this pass used the local Codex source tree as the primary implementation evidence.

### Changes Made

- Changed the Agent-loop contract to ignore stale max-step values during normal execution; Godex now treats follow-up as Codex does, continuing while the loop is running and stopping only on final model output, approval/input blocks, cancellation, errors, or context/transport boundaries.
- Added state-level event upsert behavior for tool calls and pending guide lifecycle records so running, succeeded, failed, submitted, and cancelled states update one hidden/auditable record instead of adding duplicate transcript rows.
- Changed transcript projection so a final recorded tool call suppresses the matching partial streamed preview, preventing `正在运行` plus `失败` from appearing as two independent entries.
- Reworked visible tool transcript projection to match the Codex command execution surface: a turn now renders one expandable tool batch row, while the expanded body lists each command/tool invocation with its own localized state.
- Adjusted the controller continuation boundary: tools from the same model response can finish as one batch, but after that Godex returns through the OpenAI tool-result continuation path instead of blindly chaining another model-generated batch.
- Changed running-turn queue-guide handling so guiding a queued draft records only a pending guide instruction; it no longer requeues the same text as a normal user prompt.
- Updated the Codex-style UI pass: sidebar section headings are hidden, the right inspector is wider and uses larger section/row fonts, progress/tool disclosure rows are more readable, and the send/stop button uses a visible light circular surface with dark icon contrast.
- Removed stale visible `Agent 循环已达到最大步数` assistant messages from transcript projection, widened the composer input to fill the available main column, and limited hover copy buttons to user bubbles so ordinary assistant replies do not show the user-message copy affordance.
- Hardened delegated sub-agent lifecycle records so worker notifications and cancellation actions preserve the task's child-Agent source identity while storing notification/cancel sources separately; this keeps the right inspector from showing old context-probe rows without breaking handoff and automation summaries.
- Extended slash-command handling and documentation around `/status`, `/side`, `/personality`, `/review`, `/feedback`, `/model`, and `/reasoning` so the composer palette can move toward the Codex screenshot contract.
- Live Mechoes validation after reload confirmed no visible `最大步数` control text, no visible `项目上下文调查` pseudo-subagent rows, no visible assistant `复制` button, a Codex-column composer prompt rect of 1016px rather than a full-window input, and no new editor log errors after clearing stale output. Screenshot evidence was saved to `docs/references/validation/mechoes-godex-loop-composer-copy-20260608.png` and `docs/references/validation/mechoes-godex-composer-width-after-fix-20260608.png`.

### Codex Evidence

- `codex/codex-rs/core/src/session/turn.rs` keeps turn follow-up alive while model output or pending input requires another request, and drains pending input only at a safe boundary.
- `codex/codex-rs/core/src/session/input_queue.rs` separates queued/pending input from visible transcript messages.
- `codex/codex-rs/core/src/tools/parallel.rs` treats tool failures as tool outputs for continuation, not as separate chat messages.
- `codex/codex-rs/app-server-protocol/src/protocol/thread_history.rs` maps command and MCP tool begin/end events through `upsert_item_in_turn_id`, so lifecycle changes update one existing thread item rather than appending duplicate rows. Godex now mirrors this at the transcript projection layer with a single batch row per turn.
- `codex/codex-rs/core/src/codex_delegate.rs` and the app protocol `Thread.ts` / `ThreadSource.ts` model subagents as child threads with parent-thread metadata and `subagent` source.

### Follow-up Guidelines

- Do not reintroduce arbitrary loop limits as product behavior. If a diagnostic watchdog is needed, keep it outside the normal Codex-style turn loop and do not expose it as a chat transcript stop reason.
- Keep `正在思考 -> tool batch -> assistant continuation` as the atomic unit. Tool rows may update in place during the batch, but the next model request should own the next assistant paragraph or next tool batch.
- Keep guide messages pending until a request boundary; multiple guides should update hidden state and not generate repeated visible `已引导会话` rows.
- Treat right-inspector `子智能体` rows as delegated child Agent status. Future work should wire real child-agent execution into the existing subagent edge/task model instead of rendering ordinary conversations there.
- During live validation, `system_plugin_reload.full_reload_plugin` reloads the Godot .NET MCP plugin itself, not the Godex plugin under test. Its name is easy to misread when developing a different editor plugin, and using it accidentally can create a temporary MCP maintenance/reconnect window. Prefer `user_godex_plugin_control` or Godex's own refresh path for Godex reload/activation.
- Godot .NET MCP would help this workflow if editor-control snapshots could return semantic text/rect/style summaries for visible Godex controls, making font-size, right-rail width, button-background, composer-width, and stale-message regressions easier to assert after plugin reload.

## 2026-06-08 Codex Exec Tool Naming And CI Layering

### What Happened

- A follow-up Codex source audit corrected an implementation risk: Codex's model-visible base tools center on `exec_command`, `write_stdin`, `shell_command`, and freeform `apply_patch`; file read/write is primarily an internal exec-server filesystem backend, not a primary model-visible `read_file/write_file` tool pair.
- Godex still exposed only the Godex-specific `godex_command_request` name, so model-visible command capability was drifting away from Codex's protocol vocabulary.
- The Codex workflow audit also showed that GitHub validation is layered: PRs run core CI/Bazel/SDK/Rust checks, while heavier jobs can be post-merge, manual, scheduled, or release-specific rather than every merge running every possible test.

### Changes Made

- Added a first-stage `exec_command` schema that accepts Codex-shaped command fields and bridges them into the existing approval-bound `command_run` state machine.
- Kept `godex_command_request` as a compatibility alias while making `write_stdin` fail explicitly with `interactive_command_sessions_not_available` until Godex has a real interactive process manager.
- Removed automatic Skill-enabled pseudo-subagent creation from `prepare_turn()` so `项目上下文调查` no longer pollutes state as if it were a true delegated child Agent.
- Updated the gap tracker and architecture docs to distinguish model-visible command/patch tools from Codex's internal sandboxed filesystem backend, and documented the layered CI strategy Godex should follow.
- Added headless coverage for `exec_command` command-run creation, timeout normalization, and explicit `write_stdin` unsupported reporting.

### Follow-up Guidelines

- Do not invent `godex_read_file` or `godex_write_file` as Codex base-tool equivalents. If file operations are needed, first decide whether they belong under command/process tooling, `apply_patch`, MCP project files, or a later sandboxed filesystem backend.
- The next execution-layer increment should either make `exec_command` execute through the existing runner from the model tool path or add a real process/session manager before enabling live `write_stdin`.
- Keep PR validation focused on fast, deterministic smoke/protocol/state contracts. Treat live Mechoes screenshots, provider probes, and long-running visual checks as layered evidence until they can run cheaply and reliably in CI.
- Godot .NET MCP could improve this workflow with a safe "reload target plugin and rebuild editor cache" helper that distinguishes the MCP plugin lifecycle from the plugin under test and returns freshness evidence without requiring manual cache interpretation.

### Follow-up Fix: Transcript Rebuild Fallback

- A live Mechoes screenshot after the first pass still showed repeated `godex_mcp_context` rows. The empty-chat validation missed it because the regression lived in historical transcript rebuild/projection, not in the fresh-session surface.
- The controller now treats naked `tool_call` and `partial_tool_call` transcript items as a fallback batch row during rendering, so even legacy or imperfectly grouped state records still collapse into one Codex-style disclosure.
- Future UI validation for tool rows must include a replayed or restored session with existing failed MCP events. Empty-session screenshots are not enough to prove Codex-style upsert projection.
