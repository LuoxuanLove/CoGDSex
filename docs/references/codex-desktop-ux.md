# Codex Desktop UX Reference

This note captures reusable visual and interaction cues from the Codex desktop screenshots supplied on 2026-06-04. Godex should keep Godot-native controls and editor theming, while matching Codex's relative layout, interaction density, and feedback patterns.

See `screenshot-index.md` for the maintained list of local screenshot assets. Classified screenshots live under `screenshots/` with descriptive filenames.

## Layout

- Left navigation uses a narrow dark rail with icon + short label rows, muted section headers, and compact active row highlighting.
- The top-left primary navigation is limited to `新对话`, `搜索`, `插件`, and `自动化`. Archived conversations are history/conversation affordances, not a fifth primary app section.
- The active conversation row is a rounded capsule. Secondary row actions appear on hover near the right edge.
- Hovered conversation rows use the same rounded capsule shape as the active row and must clear immediately when the pointer leaves the row and its trailing controls.
- The project group should show the active workspace/project name, and the empty-chat title should use that same name instead of a generic placeholder.
- The main conversation area is centered and scrollable, with a compact header and a fixed composer near the bottom.
- Right-side or floating progress panels use a rounded dark surface, separated sections, and concise status rows.
- Bottom and side panels can be toggled through small icon-only buttons at the top-right of the active pane.

## Icon Buttons

- Prefer icon-only buttons for pane controls, settings, layout toggles, send, attach, and status actions.
- Use compact square targets around 28-36 px with 8-12 px radius.
- Normal state should be low contrast; hover/active state should lift to a slightly brighter surface.
- Every unfamiliar icon button needs tooltip text. Tooltip copy should be short, such as `展开面板`, `切换底部面板显示`, or `显示/隐藏右侧检查器`.

## Radius And Surfaces

- Small icon buttons: 8-12 px corner radius.
- Selected navigation rows and pills: 8-12 px corner radius.
- Floating panels and composer surfaces: 14-18 px corner radius.
- Avoid excessive pill styling on dense form controls; Godot editor input fields should remain readable and consistent.

## Feedback

- Long-running work shows a visible progress surface with circular pending markers, completed state, generated artifacts, and sub-agent rows.
- The composer should expose approval mode, goal/context controls, model selector, and send state in one compact row.
- Settings and MCP management should feel like views, not chat messages. Use direct panels for server rows, toggles, and gear actions.

## Composer Initial State

- Empty-state conversation centers a large project question above a wide composer, with lightweight suggestion rows underneath.
- Composer bottom row order should stay close to Codex: add context on the left, approval mode and goal state nearby, model/reasoning selectors toward the right, IDE context next to the send button.
- Model selection is a nested or grouped menu: reasoning choices (`低`, `中`, `高`, `超高`) live next to model choices (`GPT-5.5`, `GPT-5.4`, `GPT-5.4-Mini`, `GPT-5.3-Codex`, `GPT-5.2`).
- Approval mode offers `请求批准`, `替我审批`, and `完全访问权限`; the active mode is marked with a check and reflected as a compact composer pill.
- IDE context is a toggleable pill with a tooltip explaining that it includes selected IDE state and open files. Goal tracking is a separate compact pill.
- The add-context menu should include file/photo attachment, IDE background toggle, planning mode, goal tracking, and plugin entries.
- Godex now enables the composer `+` as a scene-owned safe-context menu; unsupported attachment and external context-source rows must stay visible but disabled until their ingestion lifecycle exists.

## Current Godex Implications

- Deepen the new Search, MCP, Automation, and Settings views with real result data, health checks, and action cards instead of returning to chat-only explanatory messages.
- Keep right-inspector progress/artifact sections tuned toward Codex's floating progress panel density.
- Replace text-only layout controls with Godot editor icons and tooltips.
- Keep top-right layout chrome separate from functional navigation: control/progress, bottom drawer, and side rail buttons should never open MCP, Plugins, or Automation pages.
- Use Codex screenshots as reference for proportions, not for exact colors; Godex should still fit inside the Godot editor.

## Conversation Menu

- The active conversation title has a compact `...` menu beside it.
- Menu entries include pin conversation, rename conversation, archive conversation, open side chat, copy, branch, add automation, and open in new window.
- The menu surface uses the same rounded dark popup style as model and approval menus, with left icons and right-aligned shortcuts.
- Disabled actions stay visible but muted, preserving menu muscle memory.

## Left Rail Project Organization

- Project rows are grouped under a muted `项目` header, with folder icons and nested conversations.
- The selected conversation uses a full-width rounded row with a subtle hover/active surface; hovered rows should show the same capsule shape without resizing the title or trailing actions.
- A compact `全部收起` affordance appears near the top when the rail is expanded.
- The rail action menu includes archive all chats, organize sidebar, and sort conditions.
- Sidebar organization submenu supports `按项目`, `近期项目`, `按时间顺序`, and moving items down; the active mode is marked with a right-aligned check.
- Project entries can show a small activity spinner on the right edge without changing row height.

## Settings Return Layout

- Settings mode keeps a left navigation rail but replaces the chat rail with settings categories.
- The top-left rail starts with a compact `返回应用` row using a left arrow icon. It must sit above the settings category groups, not inside the main content.
- Main settings content is centered with a constrained width and stacked setting cards.
- Setting rows use muted descriptions, right-aligned controls, compact pill buttons, and switch toggles.
- The main content should scroll independently while the left settings rail remains stable.
- Godex's current settings implementation now matches this top-level shell: a dedicated settings rail, `返回应用`, centered scroll content, grouped cards, row-aligned provider/API/permission controls, interactive category filtering, settings search filtering with an explicit empty state, editor-theme category icons, disabled unsupported appearance settings, and a single state-backed MCP server row. It still needs the deeper Codex MCP server manager details below.

## Floating Progress Panel

- Progress appears as a floating right-side panel rather than a full-height fixed sidebar.
- The panel groups progress, generated artifacts, sub-agents, and sources with thin separators.
- Sub-agent rows use small colored glyphs and names, with a `show more` affordance when the list is truncated.
- Godex should support both fixed right rail and floating compact progress views, but Codex-like default should favor the floating version when the main screen is in distraction-free mode.
- The latest borderless-chat reference is preserved as `docs/references/screenshots/codex-floating-progress-borderless-chat.png`. It shows the progress surface as one rounded floating panel while the main transcript remains a continuous borderless text flow.
- Godex should not render progress, output, and agent capability as three separate fixed cards in the main `Body` layout. Those sections belong inside one overlay surface.
- Assistant messages, streamed status rows, tool disclosures, and command disclosures should avoid full-card borders. User messages may keep a subtle bubble, but the main transcript must not become a stack of Godot cards.
- The floating right surface should behave as an inspector of real conversation events. New conversations should not show fake progress, project artifacts, MCP sources, or sub-agent rows before the Agent creates those records. Empty output/source sections are acceptable, while progress and sub-agent sections should hide until populated.
- Treat output rows as generated artifacts or changed files. They should come from state-owned artifact records or the change-review summary, not from stdout/stderr, MCP response bodies, local probe bookkeeping, or assistant prose.
- Treat source chips as invoked external tools or external service sources, such as MCP tool execution or future web/search providers. Do not list OpenAI model transport, provider probes, local replay fixtures, file attachments, or project-summary context in the source chip row; those belong in the conversation information stream, progress status, or attachment/context surfaces.
- The side-panel header button should toggle the floating right inspector in chat view, not the persistent app navigation sidebar, and this toggle must not reserve width or resize the transcript column.

## Right Launcher And Side Chat

- The right pane can collapse into a centered launcher surface with four compact cards: file browser, side chat, browser, and terminal.
- Launcher cards use icon + title + one-line description + muted shortcut label, with equal fixed dimensions so hover states do not shift layout.
- Side chat opens as a parallel conversation pane beside the primary thread, with its own composer and header pill.
- Godex should map these to Godot-native affordances: project/file context, forked side conversation, future web/reference context, and command/terminal capability.

## Top-Right Header Chrome

- Codex desktop uses three compact icon buttons at the top-right of the conversation workbench.
- The left button opens a launcher/start menu with file, side chat, and terminal actions. It is a momentary menu button, not a checked layout toggle, and it should not show static recommended files before a real source/recommendation pipeline exists.
- The middle button toggles the bottom panel/terminal area.
- The right button toggles the side pane/sidebar visibility.
- MCP endpoint text, connection diagnostics, and refresh actions should not occupy this visible header chrome. MCP belongs in settings or `/mcp`; Plugins belongs in the `插件` navigation surface.
- The main conversation panel keeps a fixed reading column with left/right breathing room. Floating right overlays and bottom panels should not reserve width or squeeze transcript text; any future slide animation should move view surfaces, not resize the shared conversation column.

## Screenshot-Guided Icon Asset Workflow

- For future buttons or small UI assets, first collect the closest Codex screenshot crop and describe the intended icon state, padding, and active/inactive contrast.
- Prefer Godot editor theme icons when the shape is already available, because they inherit editor contrast and scale cleanly.
- When a generated bitmap is needed, generate the icon on a perfectly flat chroma-key background such as `#00ff00` or `#ff00ff`, with no shadows, gradients, texture, or background lighting variation.
- Copy the generated source into a temporary workspace path, then run the local chroma-key removal helper with border auto-key sampling, soft matte, and despill to produce a PNG with alpha.
- Validate transparent corners, edge fringes, and subject coverage before using the asset. If the icon is too soft, downscale from a larger source to the target size and re-check at 1x and 2x.
- Save project-bound final assets under Godex only after validation; discarded source images can remain outside the repository.
- The 2026-06-05 icon experiment reached the intended workflow definition, but the built-in image generation call returned `TooManyRequests`, so this slice used Godot editor icons instead of generated bitmap assets.

## Composer Menus And Review Strip

- The composer plus button opens a menu where context sources are grouped as file, side chat, browser, and terminal entries with right-aligned shortcuts.
- Current Godex now opens a scene-owned `+` menu for safe local context actions, but file, image, screenshot, side-chat, browser, terminal, and plugin-provided sources must remain disabled until their backing ingestion and attachment lifecycle exist.
- The project/context picker reference is preserved as `docs/references/screenshots/codex-project-picker-reference.png`; it shows a centered rounded menu with search, grouped project rows, right-side selected check, and add/disable project actions for a future context-source picker.
- Composer menus are overlays, not layout-expanding content. Opening an add-context menu, approval menu, slash menu, or future context menu must not change the height of the composer surface.
- In Godex, composer popovers should be reparented to `ComposerPopoverLayer` instead of remaining inside `ComposerBox`; this keeps menus scene-owned and inspectable while preventing parent containers from reserving composer layout height.
- The slash-command menu opens as a rounded dark popup above the composer input. Rows are single-line actions with a left icon, strong action name, muted description, selected-row highlight, keyboard Up/Down selection, Enter insertion, Esc closing, and scrollable overflow.
- The model and reasoning control opens as a combined floating menu: the left menu is titled `推理`, lists `低 / 中 / 高 / 超高`, and includes a bottom current-model row with a chevron; hovering that row shows the right submenu titled `模型`, which lists provider catalog models and marks the active model with a check. Clicking the current-model row should not toggle the submenu; leaving the row/submenu hover region should close it. Godex should preserve custom-model visibility when settings contain a catalog-external value. The combined menu must use `ComposerPopoverLayer`, stay inspectable by MCP, avoid clipped rounded corners, and never resize the composer.
- MCP and Skill entries can appear in the command palette; Godex should keep MCP server status and Skill availability discoverable without turning the composer into a settings page.
- The current composer target keeps the send button as a direct primary action. When a turn is running, pressing send records a visible queued user row above the composer; that row exposes guide and delete actions without opening a send-method popup.
- Changed-file review appears as a compact strip above the composer, showing file count, line deltas, goal label, and review action without covering message text.
- Expanded changed-file review uses a rounded card with a header, undo/review actions, total line deltas, and file rows with right-aligned additions/removals. Godex should map this to a review summary card before adding full diff execution.
- Godex's first implementation keeps the review strip outside `ComposerBox` and aligns it to the same fixed conversation column as the composer. Addition and removal counters should use fixed-width right-aligned labels so animated or changing values do not shift adjacent controls; value changes can use a short cubic numeric tween, but the label width must stay stable before and during the animation.
- The approval mode pill should keep the blue shield cue from Codex while using Godot theme surfaces. Its menu opens above the pill as a floating checked list with left icons, two-line permission copy, and a right check mark. The menu should use a short fixed outer rect like Codex desktop, avoiding 525px blank space and bottom-edge overflow even when the themed inner surface has larger child minimum sizes. Its tooltip should explain what the current mode allows and what still requires approval.
- Godex should keep these controls compact and icon-led, using explicit tooltips and fixed row heights.

## Goal And MCP Overlay

- A paused goal can collapse into a single compact strip above the composer with elapsed time, edit/play/delete icons, and a chevron to expand.
- Hovering icon-only goal controls should show short tooltips such as `隐藏完整目标` or `展开完整目标`.
- Expanded goal cards remain scrollable and should not push the composer off screen; keep a fixed maximum height and a visible scrollbar.
- MCP status popups use a compact modal surface listing servers, authentication support, and enabled state. Godex should mirror this for configured MCP endpoints and connected tool providers.

## Split Review Workbench

- Codex can place a main conversation and a side review/reference pane in parallel. Both panes keep their own scroll context and composer, but share the same left project rail.
- Document attachment cards use a file icon, title, file type, and an `打开方式` action. Godex should reuse this pattern for reference docs, editor context, and generated audit attachments.
- The side review pane is useful for comments, generated review notes, and source documents; it should remain a later UI mode unless a current workflow needs side-by-side reading.

## Plugin System Reference

The user supplied Codex desktop plugin-system screenshots on 2026-06-04 and 2026-06-05 as long-term references. They are archived as `screenshots/codex-plugin-system.png` and `screenshots/codex-plugin-system-full.png`.

- Treat this as a later-stage feature reference only. Do not prioritize plugin-system implementation before the core Agent, MCP, session, approval, and model workflows are solid.
- The screen keeps the standard Codex left rail. `插件` is selected between `搜索` and `自动化`, with `新对话` above and `设置` pinned at the bottom.
- Do not reuse the `插件` top-nav entry for MCP. MCP server configuration belongs in settings/integrations, and MCP status or discovery can be opened from `/mcp`.
- The main content uses two compact top tabs, `插件` and `技能`, with the active tab rendered as a small rounded dark pill.
- The page title is centered: `让 Codex 按你的方式工作`.
- Search and filtering live in a single centered row under the title: search input, `Built by OpenAI` filter, and `全部` filter.
- A wide featured banner appears below the filters, using a real image background with a centered plugin callout and a primary `在对话中试用` button.
- Plugin entries are grouped by category headings such as `Featured` and `Productivity`, separated by thin horizontal dividers.
- Each plugin row is compact: icon on the left, bold plugin name, one-line description, and a right-aligned check state.
- Top-right page actions include compact `管理`, `创建`, and overflow controls.

## MCP Settings Reference

The 2026-06-05 MCP screenshots are archived as `screenshots/codex-settings-mcp-servers.png` and `screenshots/codex-settings-custom-mcp.png`.

- MCP servers are managed from settings/integrations, with server rows, gear actions, enabled switches, and an add-server action.
- The custom MCP form uses a centered settings panel with a name field, transport tabs, command/argument/env inputs, env passthrough, workspace directory, and a save action.
- Godex should keep its MCP endpoint and enablement settings in the settings view, with `/mcp` reserved for status, discovery, and quick inspection from the composer.
- The current Godex slice provides the settings shell and one `Godot .NET MCP` server row with status, endpoint editing, enable/disable, refresh, and edit affordances. Do not treat it as complete MCP management until multi-server persistence, transport-specific forms, per-server tool controls, and add-server flows exist.
- The layout should influence future Godex plugin management only after Godex has a mature plugin-compatible extension model.
