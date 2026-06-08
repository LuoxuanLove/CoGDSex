# Codex Screenshot Reference Index

This index tracks Codex desktop screenshots used as visual and interaction references for Godex. New screenshots placed in this folder should be moved into `screenshots/`, renamed with a `codex-<topic>.png` pattern, and summarized here.

## Current Screenshots

| File | Reference Topic | Godex Usage |
|---|---|---|
| `screenshots/codex-empty-chat-composer.png` | Empty chat state, left rail, centered prompt, composer controls, suggestion rows | Main workbench default state, composer density, left navigation spacing |
| `screenshots/codex-add-context-menu.png` | Add context menu with file/photo, IDE background, planning mode, goal, plugin entry | Future add-context popup and composer state toggles |
| `screenshots/codex-approval-mode-menu.png` | Approval mode menu and checked active item | Approval policy selector and risk-mode copy |
| `screenshots/codex-model-reasoning-menu.png` | Combined reasoning and model menu | Model selector and reasoning effort menu behavior |
| `screenshots/codex-composer-goal-diff-bar.png` | Goal pill, changed-file review bar, composer footer | Goal tracking and diff review surface |
| `screenshots/codex-conversation-menu-progress.png` | Conversation overflow menu, changed-file list, right progress panel | Conversation actions, progress rail, output card grouping |
| `screenshots/codex-progress-panel-detail.png` | Compact floating progress panel with outputs, sub-agents, sources | Right rail and floating progress panel density |
| `screenshots/codex-floating-progress-borderless-chat.png` | Borderless main conversation with a floating right progress panel, artifact list, sub-agents, and sources | Godex default chat transcript should avoid assistant/tool card borders and render progress as a floating overlay |
| `screenshots/codex-split-editor-reference-docs.png` | Codex chat beside an editor/reference document pane | IDE context pane and split-view layout |
| `screenshots/codex-bottom-panel-file-browser-terminal.png` | Bottom terminal panel plus right file/browser launcher pane | Bottom panel toggle and terminal/file browser integration |
| `screenshots/codex-terminal-pane.png` | Right terminal pane beside chat | Command capability and terminal output view |
| `screenshots/codex-side-chat-pane.png` | Side chat pane beside main conversation | Side chat/forked conversation UX |
| `screenshots/codex-header-panel-toggle-icons.png` | Header icons for expanded, bottom, and split panels | Top-right layout toggle buttons |
| `screenshots/codex-settings-general.png` | Settings navigation and general settings content | Settings page hierarchy, rows, switches, dropdowns |
| `screenshots/codex-plugin-system.png` | Plugin/skill management page | Later-stage plugin system reference only |
| `screenshots/codex-plugin-system-full.png` | Full plugin marketplace page with left nav `插件` selected | Top navigation label separation: Plugins is distinct from MCP and remains a later-stage surface |
| `screenshots/codex-settings-mcp-servers.png` | Settings page showing MCP server list and toggles | MCP belongs under settings/integrations, not the top-left plugin navigation item |
| `screenshots/codex-settings-custom-mcp.png` | Settings form for connecting a custom MCP server | Future MCP settings form layout, transport tabs, env vars, and workspace fields |
| `screenshots/codex-reference-screenshot-management-thread.png` | Conversation containing embedded screenshot references and review cards | Screenshot ingestion workflow and reference-management traceability |
| `screenshots/codex-sidebar-toggle-hover.png` | Left sidebar with hover tooltip for the sidebar toggle | Sidebar collapse affordance and tooltip placement |
| `screenshots/codex-about-dialog.png` | Codex about dialog with version and release date | Future about/version dialog reference |
| `screenshots/codex-goal-thread-terminal-progress.png` | Active goal thread with progress panel, bottom terminal, and composer review strip | Goal persistence, terminal integration, and changed-file review density |
| `screenshots/codex-right-launcher-cards.png` | Right-side launcher cards for file browser, side chat, browser, and terminal | Future right launcher pane and compact tool entry card layout |
| `screenshots/codex-bottom-terminal-progress-thread.png` | Bottom terminal open while a goal thread shows progress and review controls | Bottom panel coexistence with active conversation and review strip |
| `screenshots/codex-composer-add-menu-expanded.png` | Composer add menu with file, side chat, browser, and terminal entries | Add-context menu grouping and right-aligned shortcuts |
| `screenshots/codex-side-chat-active-pane.png` | Side chat pane opened beside the primary conversation | Side-chat/forked thread layout and dual composer placement |
| `screenshots/codex-composer-queue-guide-menu.png` | Historical composer queue/guide affordance reference | Current target uses direct send plus queued rows with guide/delete actions, not a send-method popup |
| `screenshots/codex-slash-command-menu.png` | Slash command menu with IDE context, MCP, personality, code review, side chat, compression, feedback, approval, reasoning, and model rows | Slash command palette density, icon-led command rows, and composer bottom control order |
| `screenshots/codex-mcp-skill-command-menu.png` | `/m` filtered command menu showing MCP row and skill entries with personal/system scope labels | MCP/Skill management menu grouping and command search behavior |
| `screenshots/codex-mcp-goal-collapsed.png` | MCP status popup over a collapsed paused goal strip and composer controls | MCP status popup, paused goal strip, and stop button state |
| `screenshots/codex-mcp-goal-expanded-tooltip.png` | Expanded paused goal card with hover tooltip on the collapse control | Goal card expansion, icon-only action row, and tooltip placement |
| `screenshots/codex-split-review-workbench.png` | Full split workbench with left project rail, main chat, side review pane, attached files, and edited-file review card | Split review layout, document attachment cards, changed-file review density, and dual composer placement |
| `screenshots/codex-edited-files-review-card.png` | Expanded edited-file review card with total file count, line deltas, undo, review action, and file rows | Godex review summary card, file-level diff list, and review action states |
| `screenshots/codex-approval-mode-pill-detail.png` | Close-up approval mode pill with blue shield icon and dropdown affordance | Approval pill icon color, hover/tooltip affordance, and compact control styling |
| `screenshots/codex-project-picker-reference.png` | Project/context picker menu with search, selected project check, and add/disable project actions | Future add-context and project context picker reference only |

## Maintenance Rules

- Keep raw screenshots out of the reference root once classified; store them under `screenshots/`.
- Prefer descriptive filenames over copy-style names so design discussions can cite stable paths.
- When a screenshot covers a feature that should not be implemented yet, mark that explicitly in the usage column.
- Update `codex-desktop-ux.md` when a screenshot changes an established layout rule.
