extends SceneTree

const MAIN_SCENE := "res://addons/godex/ui/godex_main.tscn"
const PLUGIN_SCRIPT := "res://addons/godex/plugin.gd"
const CONTROLLER_SCRIPT := "res://addons/godex/ui/godex_dock_controller.gd"
const THEME_SCRIPT := "res://addons/godex/ui/godex_theme.gd"
const State = preload("res://addons/godex/core/godex_state.gd")
const AgentService = preload("res://addons/godex/core/agent_service.gd")
const DockController = preload("res://addons/godex/ui/godex_dock_controller.gd")
const RequestBuilder = preload("res://addons/godex/core/openai_request_builder.gd")
const OpenAIExecutionService = preload("res://addons/godex/core/openai_execution_service.gd")
const ProviderCatalog = preload("res://addons/godex/core/provider_catalog.gd")
const Compressor = preload("res://addons/godex/core/context_compressor.gd")
const McpClient = preload("res://addons/godex/core/mcp_client.gd")
const ApprovalPolicy = preload("res://addons/godex/core/approval_policy.gd")
const CommandCapability = preload("res://addons/godex/core/command_capability.gd")
const GitChangeSummaryService = preload("res://addons/godex/core/git_change_summary_service.gd")
const SettingsStore = preload("res://addons/godex/core/settings_store.gd")
const SessionStore = preload("res://addons/godex/core/session_store.gd")
const SubagentManager = preload("res://addons/godex/core/subagent_manager.gd")
const HEADLESS_ROOT_SIZE := Vector2(1280.0, 720.0)
const CONSTRAINED_ROOT_SIZE := Vector2(640.0, 360.0)

var _fake_command_runner_calls := 0


func _initialize() -> void:
	var failures: Array[String] = []
	_check_plugin_script(failures)
	_check_main_scene(failures)
	await _check_navigation_view_boundaries(failures)
	await _check_header_layout_controls(failures)
	_check_slash_command_row_rendering(failures)
	_check_approval_mode_row_rendering(failures)
	_check_model_reasoning_picker_row_rendering(failures)
	await _check_composer_popover_layout(failures)
	await _check_add_context_popover_behavior(failures)
	await _check_composer_send_queue_behavior(failures)
	await _check_model_reasoning_picker_behavior(failures)
	_check_slash_command_keyboard_navigation(failures)
	_check_openai_payloads(failures)
	_check_openai_execution_service(failures)
	_check_openai_streaming_contract(failures)
	_check_provider_probe_contract(failures)
	_check_provider_catalog(failures)
	_check_context_compression(failures)
	_check_mcp_and_approval(failures)
	_check_git_change_summary_service(failures)
	_check_state_capability_summary(failures)
	_check_session_state(failures)
	_check_subagent_manager(failures)
	_check_streaming_message_state(failures)
	_check_agent_mcp_inspection(failures)
	_check_agent_turn_audit(failures)
	_check_command_capability(failures)
	if failures.is_empty():
		print("GODEX_HEADLESS_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_plugin_script(failures: Array[String]) -> void:
	var script := load(PLUGIN_SCRIPT)
	if script == null:
		failures.append("plugin script failed to load")
		return
	if not script.can_instantiate():
		failures.append("plugin script cannot instantiate")
	var controller_script := load(CONTROLLER_SCRIPT)
	if controller_script == null or not controller_script.can_instantiate():
		failures.append("controller script should load and instantiate without parse errors")
	var plugin_source := FileAccess.get_file_as_string(PLUGIN_SCRIPT)
	if plugin_source.find("func rebuild_main_screen") < 0:
		failures.append("plugin script should expose rebuild_main_screen")
	if plugin_source.find("if child.name == \"GodexMain\"") < 0:
		failures.append("plugin rebuild should remove every stale GodexMain instance before instantiating the refreshed scene")
	if plugin_source.find("func activate_main_screen") < 0 or plugin_source.find("set_main_screen_editor(_get_plugin_name())") < 0:
		failures.append("plugin script should expose an explicit Godex main-screen activation fallback")
	if plugin_source.find("call_deferred(\"_enter_distraction_free\")") < 0:
		failures.append("plugin script should enter distraction-free mode after main-screen visibility settles")
	var controller_source := FileAccess.get_file_as_string(CONTROLLER_SCRIPT)
	if controller_source.find("_send_continuation.disabled") < 0 or controller_source.find("无续跑请求") < 0:
		failures.append("controller should state-gate the OpenAI continuation send button")
	if controller_source.find("_local_tool_probe_transcript_title") < 0 or controller_source.find("本地 MCP 探针") < 0:
		failures.append("controller should expose local MCP probes as first-class transcript/tool-call events")
	if controller_source.find("_replay_model_response") < 0 or controller_source.find("本地模型回放") < 0 or controller_source.find("未发送网络请求") < 0:
		failures.append("controller should expose a local model replay action that is visibly distinct from real OpenAI transport")
	if controller_source.find("_run_provider_probe") < 0 or controller_source.find("Provider 探针") < 0 or controller_source.find("provider_probe") < 0:
		failures.append("controller should expose a real provider probe for Godot-process OpenAI-compatible diagnostics")
	if controller_source.find("_replay_pending_tool_result_continuation") < 0 or controller_source.find("本地工具结果续跑回放") < 0:
		failures.append("controller should expose a local tool-result continuation replay action for closed-loop diagnosis")
	if controller_source.find("_show_view(\"chat\")\n\t_save_sessions()\n\t_apply_model(_state.call(\"to_model\"))") < 0:
		failures.append("local MCP probe action should use the normal chat view switch before rebuilding the model")
	if controller_source.find("cancel_request") < 0 or controller_source.find("_openai_cancel_requested") < 0:
		failures.append("controller should expose OpenAI request cancellation")
	if controller_source.find("_retry_openai_request") < 0 or controller_source.find("retry_openai_transport_request") < 0:
		failures.append("controller should expose explicit OpenAI request retry")
	if controller_source.find("retry_request") < 0:
		failures.append("controller should gate retry OpenAI sends behind approval in review mode")
	if controller_source.find("_advance_agent_loop_after_model_response") < 0 or controller_source.find("_try_start_next_tool_call") < 0:
		failures.append("controller should advance repeated Agent tool-call loops")
	if controller_source.find("CHAT_LONG_MESSAGE_LIMIT") >= 0 or controller_source.find("长内容已折叠") >= 0:
		failures.append("assistant replies should remain fully visible; long-message folding is only allowed for tool/command disclosure")
	if controller_source.find("_mcp_tool_chat_summary") < 0:
		failures.append("controller should summarize MCP tool results before adding chat messages")
	if controller_source.find("_toggle_layout_menu") < 0 or controller_source.find("_toggle_bottom_panel") < 0 or controller_source.find("_toggle_right_inspector") < 0:
		failures.append("controller should expose Codex-like top-right layout toggles")
	if controller_source.find("_control_panel_toggle.pressed.connect(_show_mcp)") >= 0 or controller_source.find("_control_panel_toggle.pressed.connect(_show_plugins)") >= 0 or controller_source.find("_control_panel_toggle.pressed.connect(_show_automation)") >= 0:
		failures.append("layout controls should not route to MCP, plugin, or automation pages")
	if controller_source.find("_queue_openai_approval_request") < 0 or controller_source.find("network:openai_request") < 0:
		failures.append("controller should gate first OpenAI sends behind approval in review mode")
	if controller_source.find("tool_result_continuation") < 0 or controller_source.find("_requires_openai_send_approval()") < 0:
		failures.append("controller should gate manual OpenAI continuation sends behind approval in review mode")
	if controller_source.find("_rebuild_slash_command_suggestions") < 0 or controller_source.find("_insert_slash_command") < 0:
		failures.append("controller should render discoverable slash command suggestions")
	if controller_source.find("SlashCommandRowContent") < 0 or controller_source.find("_paint_slash_command_button") < 0 or controller_source.find("_editor_icon_texture") < 0:
		failures.append("slash command rows should use Codex-style action-list rows with icons and selected-row background")
	if controller_source.find("_on_composer_gui_input") < 0 or controller_source.find("_move_slash_command_selection") < 0 or controller_source.find("_insert_selected_slash_command") < 0:
		failures.append("slash command menu should support keyboard selection, Enter insertion, and Esc closing")
	if controller_source.find("_apply_approval_button_model") < 0 or controller_source.find("低风险步骤自动继续") < 0:
		failures.append("controller should expose Codex-style approval mode tooltips")
	if controller_source.find("_approval_button.pressed.connect(_toggle_approval_mode_menu)") < 0 or controller_source.find("_cycle_approval_mode") >= 0:
		failures.append("approval mode pill should open a checked menu instead of cycling modes on click")
	if controller_source.find("_build_approval_mode_row") < 0 or controller_source.find("ApprovalModeRowContent") < 0 or controller_source.find("_on_approval_mode_selected") < 0:
		failures.append("approval mode menu should render structured selectable checked items")
	if controller_source.find("_apply_context_pill_model") < 0 or controller_source.find("button.visible = enabled") < 0:
		failures.append("IDE context and goal pills should hide when disabled")
	if controller_source.find("_on_ide_context_hover_changed") < 0 or controller_source.find("/ide 切换") < 0:
		failures.append("IDE context pill should expose hover close affordance and slash-command hint")
	if controller_source.find("_on_goal_hover_changed") < 0 or controller_source.find("/goal off 关闭") < 0:
		failures.append("goal pill should expose hover close affordance and close hint")
	if controller_source.find("\"ApprovalButton\": [\"Shield\", \"Lock\", \"StatusSuccess\"]") < 0:
		failures.append("controller should avoid yellow warning icons for the approval mode pill")
	if controller_source.find("icon_normal_color") < 0 or controller_source.find("GodexTheme.BLUE") < 0:
		failures.append("controller should paint approval button with blue shield-style icon emphasis")
	if controller_source.find("_show_add_context_menu") < 0 or controller_source.find("_build_add_context_row") < 0 or controller_source.find("_add_recommended_file_context") < 0:
		failures.append("composer plus button should open a scene-owned add-context menu with real local context actions")
	if controller_source.find("当前项目摘要") < 0 or controller_source.find("添加推荐文件") < 0 or controller_source.find("压缩当前会话") < 0 or controller_source.find("计划模式") < 0 or controller_source.find("追求目标") < 0 or controller_source.find("_build_add_context_switch") < 0 or controller_source.find("godex_menu_icon.gd") < 0 or controller_source.find("_open_plugins_from_context_menu") < 0:
		failures.append("add-context menu should match the compact Codex composer menu with project context, optional file, compaction, plan, goal, and plugin rows")
	if controller_source.find("context_window_warning") < 0 or controller_source.find("可从菜单压缩当前会话") < 0:
		failures.append("composer controls should expose context-window warnings near add-context and send actions")
	if controller_source.find("_on_send_button_pressed") < 0 or controller_source.find("_rebuild_composer_queue") < 0 or controller_source.find("_guide_queued_composer_message") < 0:
		failures.append("composer send button should send directly while exposing running-message queue and guide actions")
	if controller_source.find("_composer_input_style") < 0 or controller_source.find("_composer_panel_style") < 0:
		failures.append("composer input should keep Codex-like compact surface styling")
	if controller_source.find("_configure_composer_popovers") < 0 or controller_source.find("_position_approval_mode_panel") < 0:
		failures.append("composer menus should be positioned as floating popovers instead of resizing the composer")
	if controller_source.find("_show_model_picker") < 0 or controller_source.find("_show_reasoning_picker") < 0 or controller_source.find("_build_compact_picker_row") < 0:
		failures.append("model and reasoning controls should use Codex-style composer popovers instead of native option menus")
	if controller_source.find("row.mouse_entered.connect(_on_model_submenu_hover_changed.bind(true, row))") < 0:
		failures.append("model submenu should open from hovering the reasoning menu model row")
	if controller_source.find("row.mouse_exited.connect(_on_model_submenu_hover_changed.bind(false, row))") < 0 or controller_source.find("_close_model_submenu_if_pointer_outside") < 0 or controller_source.find("ModelSubmenuHoverWatch") < 0:
		failures.append("model submenu should close when hover leaves the model row and submenu panel")
	if controller_source.find("func _toggle_model_submenu") >= 0:
		failures.append("model submenu should not expose a click-to-toggle interaction")
	if controller_source.find("ThreadHoverWatch") < 0 or controller_source.find("_refresh_thread_hover_states") < 0:
		failures.append("thread row hover state should be reconciled from pointer position so stale hover capsules clear after the pointer leaves")
	if controller_source.find("\"archived\": _node(\"Root/Shell/SidebarPanel/Sidebar/TopNav/Archived\")") >= 0:
		failures.append("archived conversations must not be part of the four-item Codex top navigation")
	if controller_source.find("Root/Shell/SidebarPanel/Sidebar/Archived") >= 0:
		failures.append("archived conversations should not use a persistent chat-sidebar button")
	if controller_source.find("ArchiveCategory") < 0 or controller_source.find("_show_archived") < 0:
		failures.append("archived conversations should live in the settings archive page")
	if controller_source.find("func _layout_menu_recommended_rows() -> Array:\n\treturn []") < 0:
		failures.append("layout menu should not invent static recommended files before a real source is wired")
	if controller_source.find("_on_settings_category_pressed") < 0 or controller_source.find("_on_settings_search_changed") < 0:
		failures.append("settings rail categories and search should be wired to real filtering/section navigation behavior")
	if controller_source.find("SettingsNoResults") < 0 or controller_source.find("visible_section_count") < 0:
		failures.append("settings search should expose a real empty-results state instead of leaving a blank settings page")
	if controller_source.find("\"McpCategory\": [\"Network\"") < 0 or controller_source.find("icon_disabled_color") < 0:
		failures.append("settings rail categories should use editor icons and muted disabled icon colors")
	var theme_source := FileAccess.get_file_as_string(THEME_SCRIPT)
	if theme_source.find("const BLUE") < 0:
		failures.append("theme should expose the Codex-style blue accent color")


func _prepare_headless_root(root: Node, root_size: Vector2 = HEADLESS_ROOT_SIZE) -> void:
	get_root().size = Vector2i(int(root_size.x), int(root_size.y))
	if root is Control:
		var control := root as Control
		control.set_anchors_preset(Control.PRESET_TOP_LEFT)
		control.position = Vector2.ZERO
		control.size = root_size


func _check_main_scene(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	if scene == null:
		failures.append("main scene failed to load")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_prepare_headless_root(root)
	var required := [
		"Root/Shell/SidebarPanel/Sidebar/ThreadScroll/Threads",
		"Root/Shell/MainPanel/Main/Header/McpStatus",
		"Root/Shell/MainPanel/Main/Header/HeaderLayoutControls/ControlPanelToggle",
		"Root/Shell/MainPanel/Main/Header/HeaderLayoutControls/BottomPanelToggle",
		"Root/Shell/MainPanel/Main/Header/HeaderLayoutControls/SidePanelToggle",
		"Root/Shell/MainPanel/Main/Header/RefreshGodex",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsRail/ArchiveCategory",
		"ComposerPopoverLayer",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/Prompt",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ConversationScroll/TranscriptCenter/Messages",
		"ComposerPopoverLayer/SlashCommandPanel/SlashCommandBox/SlashCommandScroll/SlashCommandList",
		"ComposerPopoverLayer/AddContextPanel/AddContextSurface/AddContextBox/AddContextList",
		"ComposerPopoverLayer/ApprovalModePanel/ApprovalModeSurface/ApprovalModeBox/ApprovalModeList",
		"ComposerPopoverLayer/ModelPickerPanel/ModelPickerSurface/ModelPickerBox/ModelPickerList",
		"ComposerPopoverLayer/ReasoningPickerPanel/ReasoningPickerSurface/ReasoningPickerBox/ReasoningPickerList",
		"ProgressOverlayLayer/LayoutMenuPanel/LayoutMenuSurface/LayoutMenuBox/LayoutMenuActions",
		"ProgressOverlayLayer/LayoutMenuPanel/LayoutMenuSurface/LayoutMenuBox/LayoutMenuRecommended",
		"ProgressOverlayLayer/RightRail/RightRailBox/ProgressSection/ProgressList",
		"ProgressOverlayLayer/RightRail/RightRailBox/OutputSection/OutputList",
		"ProgressOverlayLayer/RightRail/RightRailBox/SubAgentsSection/SubAgentsList",
		"ProgressOverlayLayer/RightRail/RightRailBox/SourcesSection/SourceList",
		"Root/Shell/MainPanel/Main/Body/MainCenter/BottomDrawer/BottomDrawerBox/BottomDrawerScroll/BottomDrawerList",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewStrip/ChangeReviewToggle",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewStrip/ChangeReviewAdded",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewStrip/ChangeReviewRemoved",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewFiles",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsRail/BackToApp",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsRail/GeneralCategory",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/SettingsNoResults",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/ProviderCard/ProviderSettings/ProviderRow/Provider",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/ProviderCard/ProviderSettings/ApiStatus",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/Endpoint",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/FeatureCard/FeatureToggles/CommandEnabled",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/CodingCard/CodingSettings/CommandShellRow/CommandShell",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/CapabilityPreview",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ModelButton",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ReasoningButton",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/AddContext",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ModeDivider",
		"Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/IdeContextButton",
		"Root/Shell/MainPanel/Main/Body/MainCenter/SearchPanel/SearchBox/SearchInput",
		"Root/Shell/MainPanel/Main/Body/MainCenter/PluginsPanel/PluginsBox/PluginsSummary",
		"Root/Shell/MainPanel/Main/Body/MainCenter/McpPanel/McpBox/McpToolList",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/AutomationList",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/InjectProbeTool",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ReplayModelResponse",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ProviderProbe",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ExecuteNextTool",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/SendContinuation",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ReplayContinuation",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/CommandActions/RequestCommandApproval",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/CommandActions/ExecuteApprovedCommand",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/CommandActions/CancelCommandRun",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/SubagentActions/CancelSubagentTask",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/SubagentActions/HandoffSubagentResult",
		"Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel/AutomationBox/ContinuationPreview/ContinuationPreviewBox/ContinuationPreviewDetail",
	]
	for path in required:
		if root.get_node_or_null(path) == null:
			failures.append("missing main scene node: %s" % path)
	var review_surface: Node = root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/ChangeReviewSurface")
	var main_scene_composer_box: Node = root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox")
	if review_surface == null or review_surface.get_parent() == main_scene_composer_box:
		failures.append("changed-file review strip should be a composer sibling, not part of ComposerBox")
	var shell := root.get_node("Root/Shell") as HBoxContainer
	var sidebar_panel := root.get_node("Root/Shell/SidebarPanel") as PanelContainer
	var resize_handle := root.get_node("Root/Shell/SidebarResizeHandle") as Control
	var main_panel := root.get_node("Root/Shell/MainPanel") as PanelContainer
	if shell == null or sidebar_panel == null or resize_handle == null or main_panel == null:
		failures.append("sidebar resize handle should be present between the sidebar and main panel")
	elif sidebar_panel.get_index() >= resize_handle.get_index() or resize_handle.get_index() >= main_panel.get_index():
		failures.append("sidebar resize handle should be the divider between SidebarPanel and MainPanel")
	var header_controls := root.get_node("Root/Shell/MainPanel/Main/Header/HeaderLayoutControls") as HBoxContainer
	if header_controls == null or header_controls.get_child_count() != 3:
		failures.append("header should expose exactly three Codex-like layout control buttons")
	for path in [
		"Root/Shell/MainPanel/Main/Header/HeaderLayoutControls/ControlPanelToggle",
		"Root/Shell/MainPanel/Main/Header/HeaderLayoutControls/BottomPanelToggle",
		"Root/Shell/MainPanel/Main/Header/HeaderLayoutControls/SidePanelToggle",
	]:
		var layout_button := root.get_node(path) as Button
		if layout_button == null:
			continue
		if path.ends_with("ControlPanelToggle") and layout_button.toggle_mode:
			failures.append("launcher header control should be a momentary menu button: %s" % path)
		if not path.ends_with("ControlPanelToggle") and not layout_button.toggle_mode:
			failures.append("header layout control should be a toggle button: %s" % path)
		if str(layout_button.tooltip_text).is_empty():
			failures.append("header layout control should have hover help: %s" % path)
	if root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/CancelRequest") != null:
		failures.append("composer should not expose a separate stop button; SendButton owns send/stop")
	if root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/RetryRequest") != null:
		failures.append("composer should not expose a separate retry button; retry belongs to diagnostics/queued flow")
	var endpoint_label := root.get_node("Root/Shell/MainPanel/Main/Header/EndpointLabel") as Label
	var mcp_status := root.get_node("Root/Shell/MainPanel/Main/Header/McpStatus") as Label
	if endpoint_label.visible or mcp_status.visible:
		failures.append("MCP endpoint/status should stay out of the Codex-like top-right header chrome")
	var plugins_button := root.get_node("Root/Shell/SidebarPanel/Sidebar/TopNav/Plugins") as Button
	if plugins_button == null or plugins_button.text != "插件":
		failures.append("top navigation should expose Plugins separately from MCP")
	var top_nav := root.get_node("Root/Shell/SidebarPanel/Sidebar/TopNav") as VBoxContainer
	if top_nav == null or top_nav.get_child_count() != 4:
		failures.append("Codex top navigation should contain exactly New Chat, Search, Plugins, and Automation")
	if root.get_node_or_null("Root/Shell/SidebarPanel/Sidebar/TopNav/Archived") != null:
		failures.append("archived conversations should not appear in the top navigation")
	var plugins_summary := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/PluginsPanel/PluginsBox/PluginsSummary") as Label
	if plugins_summary == null or plugins_summary.text.find("/mcp") < 0 or plugins_summary.text.find("设置") < 0:
		failures.append("plugins view should direct MCP configuration to settings or /mcp")
	if root.get_node_or_null("Root/Shell/MainPanel/Main/Body/RightRail") != null:
		failures.append("right inspector UI should be a floating overlay, not an HBox layout column inside Body")
	var right_rail := root.get_node("ProgressOverlayLayer/RightRail") as PanelContainer
	if right_rail == null or right_rail.custom_minimum_size.x < 400 or right_rail.custom_minimum_size.x > 460:
		failures.append("floating right inspector panel should use a readable Codex-like width instead of a narrow mini rail")
	if right_rail != null and right_rail.get_parent().name != "ProgressOverlayLayer":
		failures.append("right inspector panel should live under ProgressOverlayLayer")
	if root.get_node_or_null("ProgressOverlayLayer/RightRail/RightRailBox/ProgressCard") != null or root.get_node_or_null("ProgressOverlayLayer/RightRail/RightRailBox/ToolCard") != null or root.get_node_or_null("ProgressOverlayLayer/RightRail/RightRailBox/OutputCard") != null:
		failures.append("right inspector should use one surface with sections, not legacy stacked cards")
	var progress_section := root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/ProgressSection") as Control
	var subagents_section := root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/SubAgentsSection") as Control
	if progress_section.visible:
		failures.append("new conversations should not show static progress before the agent creates progress events")
	if subagents_section.visible:
		failures.append("right inspector should hide sub-agents until a real sub-agent event exists")
	if root.get_node_or_null("ProgressOverlayLayer/RightRail/RightRailBox/TimelineSection") != null:
		failures.append("right inspector should not expose a separate recent-activity section")
	var controller_source_for_layout := FileAccess.get_file_as_string(CONTROLLER_SCRIPT)
	if controller_source_for_layout.find("ProjectLabel") < 0 or controller_source_for_layout.find("ConversationLabel") < 0 or controller_source_for_layout.find("sidebar_heading.visible = false") < 0:
		failures.append("controller should keep redundant sidebar section labels hidden even after chat chrome refreshes")
	if controller_source_for_layout.find("_paint_send_button") < 0 or controller_source_for_layout.find("Color(0.98, 0.98, 0.96)") < 0 or controller_source_for_layout.find("var icon_color := Color(0.13, 0.13, 0.13)") < 0:
		failures.append("send/stop button should use a visible white circular surface with dark icon contrast")
	var composer_panel = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel")
	if composer_panel.custom_minimum_size.y > 150:
		failures.append("composer panel should stay compact and avoid large blank space below controls")
	var settings_box := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox") as HBoxContainer
	var settings_rail := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsRail") as VBoxContainer
	var appearance_category := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsRail/AppearanceCategory") as Button
	var settings_left_spacer := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentLeftSpacer") as Control
	var settings_right_spacer := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentRightSpacer") as Control
	var settings_content_wrap := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap") as MarginContainer
	var settings_content_center := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter") as CenterContainer
	var settings_content := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent") as VBoxContainer
	var provider_row := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/ProviderCard/ProviderSettings/ProviderRow") as HBoxContainer
	var mcp_server_row := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/IntegrationCard/IntegrationSettings/McpServerRow") as PanelContainer
	var mcp_endpoint := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/Endpoint") as LineEdit
	var mcp_toggle := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/McpEnabled") as CheckBox
	var refresh_mcp := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/RefreshMcpTools") as Button
	var edit_mcp := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/McpServerSettings") as Button
	var add_mcp := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/IntegrationCard/IntegrationSettings/AddMcpServer") as Button
	if settings_box == null or settings_rail == null or settings_content == null:
		failures.append("settings view should define a reusable rail plus a central scroll content workspace")
	if appearance_category == null or not appearance_category.disabled:
		failures.append("settings rail should disable unimplemented appearance settings instead of presenting a fake category")
	if settings_left_spacer == null or settings_right_spacer == null or settings_left_spacer.visible or settings_right_spacer.visible:
		failures.append("settings content centering should not depend on legacy left/right spacer controls")
	if settings_content_wrap == null or settings_content_wrap.size_flags_horizontal != Control.SIZE_EXPAND_FILL:
		failures.append("settings content wrapper should fill the main panel and leave centering to SettingsContentCenter")
	if settings_content_center == null or settings_content_center.size_flags_horizontal != Control.SIZE_EXPAND_FILL or settings_content_center.size_flags_vertical != Control.SIZE_EXPAND_FILL:
		failures.append("settings content should use a fill-size CenterContainer to center the constrained settings column")
	if settings_content != null and int(settings_content.custom_minimum_size.x) < 860:
		failures.append("settings content should be a readable centered column wide enough for Codex-style row controls")
	if provider_row == null or provider_row.get_child_count() < 2:
		failures.append("settings fields should render as title/description plus right-aligned control rows")
	if mcp_server_row == null or mcp_endpoint == null or mcp_toggle == null:
		failures.append("settings MCP source should render as a server row with endpoint and enable toggle")
	if refresh_mcp == null or str(refresh_mcp.tooltip_text).find("重新发现") < 0:
		failures.append("settings MCP server row should expose a refresh-tools affordance with hover help")
	if edit_mcp == null or str(edit_mcp.tooltip_text).find("编辑") < 0:
		failures.append("settings MCP server row should expose an edit affordance with hover help")
	if add_mcp == null or not add_mcp.disabled:
		failures.append("settings MCP add-server affordance should be present but disabled until multi-server state exists")
	var messages = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ConversationScroll/TranscriptCenter/Messages")
	var bottom_drawer = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/BottomDrawer")
	var review_surface_for_width = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ChangeReviewSurface")
	if int(messages.custom_minimum_size.x) != 1040 or int(composer_panel.custom_minimum_size.x) != 1040 or int(bottom_drawer.custom_minimum_size.x) != 1040 or int(review_surface_for_width.custom_minimum_size.x) != 1040:
		failures.append("chat transcript, composer, bottom drawer, and review strip should start on the fixed Codex conversation column width")
	var prompt = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/Prompt")
	if prompt.custom_minimum_size.y > 80:
		failures.append("composer input should stay compact like the Codex reference")
	var add_context = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/AddContext")
	if add_context.disabled or str(add_context.tooltip_text).find("添加上下文") < 0:
		failures.append("composer plus button should open the add-context menu now that safe context actions exist")
	var model_button = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ModelButton")
	var reasoning_button = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ReasoningButton")
	if not (model_button is Button) or model_button is OptionButton:
		failures.append("composer model control should be a button that opens a scene-owned popover")
	if not (reasoning_button is Button) or reasoning_button is OptionButton:
		failures.append("composer reasoning control should be a button that opens a scene-owned popover")
	var composer_box = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox")
	if composer_box.get_node_or_null("SlashCommandPanel") != null or composer_box.get_node_or_null("ApprovalModePanel") != null or composer_box.get_node_or_null("AddContextPanel") != null:
		failures.append("main scene popover panels should live under ComposerPopoverLayer instead of ComposerBox")
	var add_context_panel = root.get_node("ComposerPopoverLayer/AddContextPanel")
	if add_context_panel.visible:
		failures.append("add-context menu panel should start hidden until the plus button is clicked")
	if add_context_panel.clip_contents:
		failures.append("add-context outer control should not clip the rounded menu corners")
	var approval_panel = root.get_node("ComposerPopoverLayer/ApprovalModePanel")
	if approval_panel.visible:
		failures.append("approval mode menu panel should start hidden until the pill is clicked")
	if not approval_panel.clip_contents:
		failures.append("approval mode popover should clip its rows when constrained by a short editor viewport")
	if approval_panel.custom_minimum_size.x > 360 or approval_panel.size_flags_vertical != Control.SIZE_SHRINK_BEGIN:
		failures.append("approval mode menu should start as a compact popover, not as a tall composer layout child")
	if approval_panel.custom_minimum_size.y >= 500.0 or approval_panel.get_combined_minimum_size().y >= 500.0:
		failures.append("approval mode menu should not declare a 500px-class minimum height in the main scene")
	var approval_surface = root.get_node("ComposerPopoverLayer/ApprovalModePanel/ApprovalModeSurface")
	var approval_box = root.get_node("ComposerPopoverLayer/ApprovalModePanel/ApprovalModeSurface/ApprovalModeBox")
	var approval_list = root.get_node("ComposerPopoverLayer/ApprovalModePanel/ApprovalModeSurface/ApprovalModeBox/ApprovalModeList")
	if not approval_surface.clip_contents:
		failures.append("approval mode popover surface should clip inside the fixed outer rect")
	if not approval_box.clip_contents or not approval_list.clip_contents:
		failures.append("approval mode popover content should be clipped inside the floating panel")
	for picker_path in ["ComposerPopoverLayer/ModelPickerPanel", "ComposerPopoverLayer/ReasoningPickerPanel"]:
		var picker = root.get_node(picker_path)
		if picker.visible:
			failures.append("%s should start hidden until its composer button is clicked" % picker_path)
		if picker.clip_contents:
			failures.append("%s outer control should not clip rounded picker corners" % picker_path)
		var surface = picker.get_child(0) if picker.get_child_count() > 0 else null
		if surface is Control and not (surface as Control).clip_contents:
			failures.append("%s themed surface should clip picker contents inside the rounded rect" % picker_path)
	root.free()


func _check_navigation_view_boundaries(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	var controller_script := load(CONTROLLER_SCRIPT)
	if scene == null or controller_script == null or not controller_script.can_instantiate():
		failures.append("navigation boundary test should load scene and controller")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_prepare_headless_root(root)
	var controller = controller_script.new()
	controller.set("_root", root)
	controller.set("_state", State.new())
	controller.set("_session_store", SessionStore.new())
	controller.call("_assign_nodes")
	controller.call("_show_plugins")
	await process_frame
	var plugins_panel: Control = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/PluginsPanel")
	var mcp_panel: Control = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/McpPanel")
	if str(controller.get("_active_view")) != "plugins" or str(controller.get("_active_sidebar_surface")) != "plugins" or not plugins_panel.visible or mcp_panel.visible:
		failures.append("plugins nav should open PluginsPanel without opening MCP discovery")
	var plugins_button := root.get_node("Root/Shell/SidebarPanel/Sidebar/TopNav/Plugins") as Button
	var thread_row := root.get_node_or_null("Root/Shell/SidebarPanel/Sidebar/ThreadScroll/Threads/ThreadRow_quick_chat") as PanelContainer
	if not _button_style_has_visible_border(plugins_button, "normal") or thread_row == null or bool(thread_row.get_meta("thread_selected", true)):
		failures.append("plugins nav selection should have its own rounded border and clear active thread selection")
	controller.call("_show_search")
	await process_frame
	var search_panel: Control = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SearchPanel")
	var search_button := root.get_node("Root/Shell/SidebarPanel/Sidebar/TopNav/Search") as Button
	thread_row = root.get_node_or_null("Root/Shell/SidebarPanel/Sidebar/ThreadScroll/Threads/ThreadRow_quick_chat") as PanelContainer
	if str(controller.get("_active_view")) != "search" or str(controller.get("_active_sidebar_surface")) != "search" or not search_panel.visible or not _button_style_has_visible_border(search_button, "normal") or thread_row == null or bool(thread_row.get_meta("thread_selected", true)):
		failures.append("search nav should be the only selected sidebar surface while thread selection is cleared")
	controller.call("_show_automation")
	await process_frame
	var automation_panel: Control = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/AutomationPanel")
	var automation_button := root.get_node("Root/Shell/SidebarPanel/Sidebar/TopNav/Automation") as Button
	thread_row = root.get_node_or_null("Root/Shell/SidebarPanel/Sidebar/ThreadScroll/Threads/ThreadRow_quick_chat") as PanelContainer
	if str(controller.get("_active_view")) != "automation" or str(controller.get("_active_sidebar_surface")) != "automation" or not automation_panel.visible or not _button_style_has_visible_border(automation_button, "normal") or thread_row == null or bool(thread_row.get_meta("thread_selected", true)):
		failures.append("automation nav should be the only selected sidebar surface while thread selection is cleared")
	controller.call("_handle_slash_command", "/mcp")
	await process_frame
	if str(controller.get("_active_view")) != "mcp" or str(controller.get("_active_sidebar_surface")) != "mcp" or not mcp_panel.visible or plugins_panel.visible:
		failures.append("slash mcp should open the MCP status view and hide PluginsPanel")
	controller.call("_show_view", "chat")
	await process_frame
	if str(controller.get("_active_sidebar_surface")) != "thread":
		failures.append("returning to chat should clear top-nav selection and restore thread selection ownership")
	thread_row = root.get_node_or_null("Root/Shell/SidebarPanel/Sidebar/ThreadScroll/Threads/ThreadRow_quick_chat") as PanelContainer
	if thread_row == null or not bool(thread_row.get_meta("thread_selected", false)) or not _panel_has_rounded_corners(thread_row):
		failures.append("returning to chat should restore the active conversation row capsule instead of a top-nav selection")
	root.free()
	await process_frame


func _check_header_layout_controls(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	var controller_script := load(CONTROLLER_SCRIPT)
	if scene == null or controller_script == null or not controller_script.can_instantiate():
		failures.append("header layout control test should load scene and controller")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_prepare_headless_root(root, Vector2(1600.0, 720.0))
	var controller = controller_script.new()
	var state := State.new()
	controller.set("_root", root)
	controller.set("_state", state)
	controller.call("_assign_nodes")
	controller.call("_bind_events")
	controller.call("_apply_static_chrome")
	controller.call("_apply_model", state.to_model())
	controller.call("_apply_layout_state")
	var right_rail: Control = root.get_node("ProgressOverlayLayer/RightRail")
	var bottom_drawer: Control = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/BottomDrawer")
	var sidebar: Control = root.get_node("Root/Shell/SidebarPanel")
	var main_panel := root.get_node("Root/Shell/MainPanel") as PanelContainer
	if not _panel_has_rounded_corners(main_panel):
		failures.append("main chat shell should keep visible rounded corners like the Codex desktop surface")
	var progress_section := root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/ProgressSection") as Control
	var output_list := root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/OutputSection/OutputList") as VBoxContainer
	var subagents_section := root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/SubAgentsSection") as Control
	var source_list := root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/SourcesSection/SourceList") as HBoxContainer
	if progress_section.visible:
		failures.append("new conversations should not show progress before agent progress events exist")
	if output_list.get_child_count() != 1 or output_list.get_child(0).name != "RightRailEmpty":
		failures.append("right inspector output should start with an empty state, not fake project artifacts")
	if subagents_section.visible:
		failures.append("right inspector should hide sub-agents until a real sub-agent event exists")
	if source_list.get_child_count() != 1 or source_list.get_child(0).name != "RightRailEmpty":
		failures.append("right inspector sources should start empty instead of showing MCP/IDE as fake sources")
	var source_empty := source_list.get_child(0) as Label
	if source_empty != null and source_empty.custom_minimum_size.x < 100.0:
		failures.append("right inspector source empty state should keep enough width to avoid vertical text wrapping")
	if root.get_node_or_null("ProgressOverlayLayer/RightRail/RightRailBox/TimelineSection") != null:
		failures.append("right inspector should not expose a separate recent-activity section")
	var messages := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ConversationScroll/TranscriptCenter/Messages") as Control
	var composer_panel := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel") as Control
	var review_surface := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ChangeReviewSurface") as Control
	var initial_message_width := int(messages.custom_minimum_size.x)
	var initial_composer_width := int(composer_panel.custom_minimum_size.x)
	var initial_review_width := int(review_surface.custom_minimum_size.x)
	if not right_rail.visible or bottom_drawer.visible or not sidebar.visible:
		failures.append("header layout controls should start with right inspector and app sidebar visible, bottom drawer hidden")
	controller.call("_toggle_layout_menu")
	var layout_menu: Control = root.get_node("ProgressOverlayLayer/LayoutMenuPanel")
	if not layout_menu.visible or not right_rail.visible:
		failures.append("launcher header button should open the Codex-style launch menu without hiding the right inspector")
	controller.call("_toggle_bottom_panel")
	if not bottom_drawer.visible:
		failures.append("bottom-panel header button should reveal the bottom output drawer in chat view")
	if layout_menu.visible:
		failures.append("bottom-panel header button should close the launch menu before changing drawers")
	if int(messages.custom_minimum_size.x) != initial_message_width or int(composer_panel.custom_minimum_size.x) != initial_composer_width or int(bottom_drawer.custom_minimum_size.x) != initial_composer_width:
		failures.append("bottom-panel toggle should not resize the fixed conversation column")
	var bottom_terminal_list := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/BottomDrawer/BottomDrawerBox/BottomDrawerScroll/BottomDrawerList") as VBoxContainer
	var bottom_empty_text := _collect_control_label_text(bottom_terminal_list)
	if bottom_empty_text.find("暂无命令运行") < 0:
		failures.append("bottom terminal should start with a command-run empty state instead of artifact rows: %s" % bottom_empty_text)
	state.record_command_run({
		"id": "command_bottom_terminal",
		"command": "Write-Output bottom-terminal",
		"shell": "PowerShell",
		"working_directory": "E:/Project/LuoxuanLove/Godex",
		"timeout_sec": 5,
	}, "completed", {
		"exit_code": 0,
		"stdout": "bottom ok",
		"runner_kind": "godot_os_execute_sync",
		"duration_ms": 12,
		"timeout_enforced": false,
		"stderr_merged": true,
		"stderr_notice": "stderr is merged into stdout",
	})
	controller.call("_apply_model", state.to_model())
	var bottom_terminal_text := _collect_control_label_text(bottom_terminal_list)
	if bottom_terminal_text.find("Write-Output bottom-terminal") < 0 or bottom_terminal_text.find("Godot OS.execute") < 0 or bottom_terminal_text.find("bottom ok") < 0 or bottom_terminal_text.find("timeline") < 0:
		failures.append("bottom terminal should render command audit status, runner, output, and timeline: %s" % bottom_terminal_text)
	var add_context_panel := root.get_node("ComposerPopoverLayer/AddContextPanel") as Control
	var approval_mode_panel := root.get_node("ComposerPopoverLayer/ApprovalModePanel") as Control
	var model_picker_panel := root.get_node("ComposerPopoverLayer/ModelPickerPanel") as Control
	var reasoning_picker_panel := root.get_node("ComposerPopoverLayer/ReasoningPickerPanel") as Control
	controller.call("_toggle_reasoning_picker")
	await process_frame
	if not reasoning_picker_panel.visible:
		failures.append("reasoning picker should open before the settings transition cleanup check")
	controller.call("_show_settings")
	var settings_panel := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel") as Control
	var header := root.get_node("Root/Shell/MainPanel/Main/Header") as Control
	var top_nav := root.get_node("Root/Shell/SidebarPanel/Sidebar/TopNav") as Control
	var project_label := root.get_node("Root/Shell/SidebarPanel/Sidebar/ProjectLabel") as Control
	var thread_scroll := root.get_node("Root/Shell/SidebarPanel/Sidebar/ThreadScroll") as Control
	var footer := root.get_node("Root/Shell/SidebarPanel/Sidebar/Footer") as Control
	var settings_rail_sidebar := root.get_node_or_null("Root/Shell/SidebarPanel/Sidebar/SettingsRail") as Control
	if not settings_panel.visible or composer_panel.visible or right_rail.visible or bottom_drawer.visible or not sidebar.visible or header.visible:
		failures.append("settings view should replace chat chrome while keeping the shared app sidebar visible")
	if add_context_panel.visible or approval_mode_panel.visible or model_picker_panel.visible or reasoning_picker_panel.visible:
		failures.append("settings view should close chat composer popovers such as reasoning/model/context/approval menus")
	if settings_rail_sidebar == null or not settings_rail_sidebar.visible or top_nav.visible or project_label.visible or thread_scroll.visible or footer.visible:
		failures.append("settings view should move the settings rail into the shared sidebar and hide chat-only sidebar chrome")
	if root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsRail") != null:
		failures.append("settings rail should not remain nested inside the main rounded settings panel while settings mode is active")
	if not _panel_has_rounded_corners(main_panel) or not _panel_has_visible_border(main_panel):
		failures.append("settings view should keep the shared rounded MainPanel frame so chat and settings switch seamlessly")
	var settings_title := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/SettingsTitle") as Label
	var provider_card := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/ProviderCard") as Control
	var integration_card := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/IntegrationCard") as Control
	var feature_card := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/FeatureCard") as Control
	var coding_card := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/CodingCard") as Control
	var capability_preview := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/CapabilityPreview") as Control
	var no_results := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/SettingsNoResults") as Label
	var settings_search := root.get_node("Root/Shell/SidebarPanel/Sidebar/SettingsRail/SettingsSearch") as LineEdit
	controller.call("_on_settings_category_pressed", "mcp")
	if settings_title.text != "MCP 服务器" or not integration_card.visible or provider_card.visible or feature_card.visible or coding_card.visible:
		failures.append("settings MCP category should show the integration section without leaving unrelated cards visible")
	controller.call("_on_settings_category_pressed", "shell")
	if settings_title.text != "命令行" or not coding_card.visible or provider_card.visible or integration_card.visible:
		failures.append("settings shell category should show command-line settings without unrelated sections")
	controller.call("_on_settings_category_pressed", "archived")
	var archived_panel := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ArchivedPanel") as Control
	if settings_title.text != "已归档对话" or not archived_panel.visible or provider_card.visible or integration_card.visible or coding_card.visible:
		failures.append("settings archive category should show the archived chats page without leaving normal settings cards visible")
	settings_search.text = "API Key"
	controller.call("_on_settings_search_changed", settings_search.text)
	if settings_title.text != "搜索设置" or not provider_card.visible or integration_card.visible or coding_card.visible:
		failures.append("settings search should filter by setting labels/help instead of only styling the search field")
	settings_search.text = "mcp"
	controller.call("_on_settings_search_changed", settings_search.text)
	if not integration_card.visible or provider_card.visible or coding_card.visible:
		failures.append("settings search should keep MCP server settings visible for MCP queries")
	if no_results.visible:
		failures.append("settings no-results message should stay hidden while at least one matching section is visible")
	settings_search.text = "zzzz-no-match"
	controller.call("_on_settings_search_changed", settings_search.text)
	if not no_results.visible or provider_card.visible or integration_card.visible or feature_card.visible or coding_card.visible or capability_preview.visible:
		failures.append("settings search should show an explicit empty state when no section matches")
	settings_search.text = ""
	controller.call("_on_settings_search_changed", settings_search.text)
	if settings_title.text != "命令行" or not coding_card.visible or integration_card.visible or provider_card.visible or not capability_preview.visible or no_results.visible:
		failures.append("clearing settings search should restore the active settings category")
	controller.call("_hide_settings")
	var restored_settings_rail := root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsRail") as Control
	if not composer_panel.visible or not sidebar.visible or not header.visible or restored_settings_rail == null or restored_settings_rail.visible:
		failures.append("returning from settings should restore the chat composer, app sidebar, header, and hidden original settings rail")
	var conversation_label := root.get_node("Root/Shell/SidebarPanel/Sidebar/ConversationLabel") as Control
	if not top_nav.visible or project_label.visible or conversation_label.visible or not thread_scroll.visible or not footer.visible:
		failures.append("returning from settings should restore chat sidebar chrome while keeping redundant headings hidden")
	if not _panel_has_rounded_corners(main_panel):
		failures.append("returning from settings should restore the rounded chat shell frame")
	var settings_button := root.get_node("Root/Shell/SidebarPanel/Sidebar/Footer/Settings") as Button
	settings_button.emit_signal("pressed")
	var settings_rail_sidebar_again := root.get_node_or_null("Root/Shell/SidebarPanel/Sidebar/SettingsRail") as Control
	if not settings_panel.visible or composer_panel.visible or not sidebar.visible or header.visible or settings_rail_sidebar_again == null or not settings_rail_sidebar_again.visible:
		failures.append("sidebar settings button should open the Codex-style settings surface in the shared sidebar")
	controller.call("_hide_settings")
	root.size = HEADLESS_ROOT_SIZE
	controller.call("_apply_layout_state")
	if right_rail.visible:
		failures.append("right inspector should auto-hide before covering the fixed transcript column")
	var conversation_scroll := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ConversationScroll") as Control
	var constrained_expected_width := int(min(1040.0, max(640.0, conversation_scroll.size.x - 112.0)))
	if int(messages.custom_minimum_size.x) != constrained_expected_width or int(composer_panel.custom_minimum_size.x) != constrained_expected_width:
		failures.append("right inspector auto-hide should keep the transcript at the viewport's natural fixed-column width")
	var constrained_message_width := int(messages.custom_minimum_size.x)
	var constrained_review_width := int(review_surface.custom_minimum_size.x)
	controller.call("_show_plugins")
	if bottom_drawer.visible:
		failures.append("bottom drawer should not overlap non-chat views")
	if right_rail.visible:
		failures.append("right inspector should not overlap non-chat views")
	if int(messages.custom_minimum_size.x) != constrained_message_width or int(review_surface.custom_minimum_size.x) != constrained_review_width:
		failures.append("right inspector visibility should not reserve width or slide the transcript column")
	root.size = Vector2(1600.0, 720.0)
	controller.call("_show_view", "chat")
	controller.call("_apply_layout_state")
	var wide_message_width := int(messages.custom_minimum_size.x)
	var wide_composer_width := int(composer_panel.custom_minimum_size.x)
	var wide_review_width := int(review_surface.custom_minimum_size.x)
	controller.call("_toggle_right_inspector")
	if right_rail.visible:
		failures.append("side-panel header button should toggle the floating right inspector")
	if not sidebar.visible:
		failures.append("side-panel header button should not hide the app navigation sidebar")
	if int(messages.custom_minimum_size.x) != wide_message_width or int(composer_panel.custom_minimum_size.x) != wide_composer_width or int(review_surface.custom_minimum_size.x) != wide_review_width:
		failures.append("right inspector toggle should keep the Codex conversation column width stable")
	if root.get_node_or_null("Root/Shell/MainPanel/Main/Body/RightRail") != null:
		failures.append("layout controls should not move the floating right rail back into Body")
	root.free()
	await process_frame


func _check_slash_command_row_rendering(failures: Array[String]) -> void:
	var controller_script := load(CONTROLLER_SCRIPT)
	if controller_script == null or not controller_script.can_instantiate():
		failures.append("controller script should instantiate before slash row rendering checks")
		return
	var controller = controller_script.new()
	var row = controller.call("_build_slash_command_row", {
		"command": "/resume",
		"args": "<关键词>",
		"title": "恢复会话",
		"summary": "恢复匹配的会话",
		"detail": "搜索并打开匹配的会话",
		"icon": ["History", "Search"],
		"insert_text": "/resume ",
	}, true)
	if not (row is Button):
		failures.append("slash command row should render as a clickable button")
		return
	if row.custom_minimum_size.y < 48:
		failures.append("slash command row should keep a stable Codex-like row height")
	if row.text != "":
		failures.append("slash command row should render structured child content instead of concatenated button text")
	if str(row.tooltip_text).find("插入 /resume <关键词>") < 0:
		failures.append("slash command row tooltip should expose the inserted slash command")
	var content = row.get_node_or_null("SlashCommandRowContent")
	if content == null:
		failures.append("slash command row should include a structured content container")
	else:
		if content.get_node_or_null("SlashCommandIcon") == null:
			failures.append("slash command row should include an icon slot")
		if content.get_node_or_null("SlashCommandCopy/SlashCommandName") == null or content.get_node_or_null("SlashCommandCopy/SlashCommandSummary") == null:
			failures.append("slash command row should include action title and muted description labels")
		else:
			var title = content.get_node("SlashCommandCopy/SlashCommandName")
			var detail = content.get_node("SlashCommandCopy/SlashCommandSummary")
			if str(title.text) != "恢复会话" or str(detail.text).find("搜索并打开") < 0:
				failures.append("slash command row should render action-list title and description copy")
	row.free()


func _check_approval_mode_row_rendering(failures: Array[String]) -> void:
	var controller_script := load(CONTROLLER_SCRIPT)
	if controller_script == null or not controller_script.can_instantiate():
		failures.append("controller script should instantiate before approval row rendering checks")
		return
	var controller = controller_script.new()
	var row = controller.call("_build_approval_mode_row", 1, "替我审批", true)
	if not (row is Button):
		failures.append("approval mode row should render as a clickable button")
		return
	if row.custom_minimum_size.y < 60 or row.custom_minimum_size.y > 70:
		failures.append("approval mode row should keep a compact Codex-like two-line height")
	if row.get_combined_minimum_size().y > 72.0:
		failures.append("approval mode row combined minimum should stay compact and not inflate the popover")
	if row.text != "":
		failures.append("approval mode row should render structured content instead of concatenated button text")
	var content = row.get_node_or_null("ApprovalModeRowContent")
	if content == null:
		failures.append("approval mode row should include a structured content container")
	else:
		if content.get_node_or_null("ApprovalModeIcon") == null:
			failures.append("approval mode row should include a left icon slot")
		if content.get_node_or_null("ApprovalModeCopy/ApprovalModeName") == null or content.get_node_or_null("ApprovalModeCopy/ApprovalModeDetail") == null:
			failures.append("approval mode row should include title and detail labels")
		var check = content.get_node_or_null("ApprovalModeCheck")
		if check == null or str(check.text) != "✓":
			failures.append("approval mode selected row should render a trailing check mark")
	row.free()


func _check_model_reasoning_picker_row_rendering(failures: Array[String]) -> void:
	var controller_script := load(CONTROLLER_SCRIPT)
	if controller_script == null or not controller_script.can_instantiate():
		failures.append("controller script should instantiate before model picker row rendering checks")
		return
	var controller = controller_script.new()
	var row = controller.call("_build_compact_picker_row", "ModelChoiceSmoke", "GPT-5.4", true, false, Callable(controller, "_hide_model_picker"))
	if not (row is Button):
		failures.append("model picker row should render as a clickable button")
		return
	if row.custom_minimum_size.y < 34 or row.custom_minimum_size.y > 38:
		failures.append("model picker row should keep a compact Codex-like height")
	if row.text != "":
		failures.append("model picker row should render structured content instead of button text")
	var content = row.get_node_or_null("PickerRowContent")
	if content == null:
		failures.append("model picker row should include structured content")
	else:
		if content.get_node_or_null("PickerTitle") == null:
			failures.append("model picker row should include a title label")
		var check = content.get_node_or_null("PickerCheck")
		if check == null or str(check.text) != "✓":
			failures.append("selected model picker row should render a trailing check mark")
	row.free()


func _check_composer_popover_layout(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	var controller_script := load(CONTROLLER_SCRIPT)
	if scene == null or controller_script == null or not controller_script.can_instantiate():
		failures.append("composer popover layout test should load scene and controller")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_prepare_headless_root(root)
	await process_frame
	var controller = controller_script.new()
	controller.set("_root", root)
	controller.set("_state", State.new())
	controller.call("_assign_nodes")
	controller.call("_configure_composer_popovers")
	var root_control := root as Control
	if root_control == null:
		failures.append("composer popover layout test root should instantiate as a Control")
		root.free()
		return
	var root_rect: Rect2 = root_control.get_global_rect()
	if root_rect.size.x < HEADLESS_ROOT_SIZE.x - 1.0 or root_rect.size.y < HEADLESS_ROOT_SIZE.y - 1.0:
		failures.append("headless smoke root should have an explicit non-zero viewport-sized rect")
	var composer_box: VBoxContainer = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox")
	var popover_layer = root.get_node_or_null("ComposerPopoverLayer")
	var slash_panel = popover_layer.get_node_or_null("SlashCommandPanel") if popover_layer != null else null
	var add_context_panel = popover_layer.get_node_or_null("AddContextPanel") if popover_layer != null else null
	var approval_panel = popover_layer.get_node_or_null("ApprovalModePanel") if popover_layer != null else null
	var model_panel = popover_layer.get_node_or_null("ModelPickerPanel") if popover_layer != null else null
	var reasoning_panel = popover_layer.get_node_or_null("ReasoningPickerPanel") if popover_layer != null else null
	if popover_layer == null or slash_panel == null or add_context_panel == null or approval_panel == null or model_panel == null or reasoning_panel == null:
		failures.append("composer popovers should be reparented into a dedicated overlay layer")
		root.free()
		return
	if composer_box.get_node_or_null("SlashCommandPanel") != null or composer_box.get_node_or_null("AddContextPanel") != null or composer_box.get_node_or_null("SendActionPanel") != null or composer_box.get_node_or_null("ApprovalModePanel") != null or composer_box.get_node_or_null("ModelPickerPanel") != null or composer_box.get_node_or_null("ReasoningPickerPanel") != null:
		failures.append("composer popover panels should be removed from ComposerBox after reparenting")
	var baseline_height := composer_box.get_combined_minimum_size().y
	controller.call("_show_approval_mode_menu")
	await process_frame
	var approval_height := composer_box.get_combined_minimum_size().y
	if approval_height > baseline_height + 1.0:
		failures.append("approval menu should float above the composer without increasing composer layout height")
	if approval_height >= 500.0:
		failures.append("approval menu should not force ComposerBox combined minimum into a 500px-class height")
	if approval_panel.get_parent() != popover_layer:
		failures.append("approval menu should live in the composer popover overlay layer")
	var expected_height := float(controller.call("_approval_mode_popover_height"))
	if expected_height < 270.0 or expected_height > 280.0:
		failures.append("approval menu target height should stay in the Codex-like short popover range")
	var approval_rect: Rect2 = approval_panel.get_global_rect()
	if absf(approval_panel.size.y - expected_height) > 1.0 or absf(approval_rect.size.y - expected_height) > 1.0:
		failures.append("approval menu should use the Codex-like fixed content height instead of expanding")
	if approval_panel.get_combined_minimum_size().y > expected_height + 8.0:
		failures.append("approval menu combined minimum height should not force a tall empty popover")
	var approval_surface = approval_panel.get_node_or_null("ApprovalModeSurface")
	if approval_surface != null and absf((approval_surface as Control).get_global_rect().size.y - approval_rect.size.y) > 1.0:
		failures.append("approval menu surface should match the fixed outer popover height")
	var approval_bottom := approval_rect.position.y + approval_rect.size.y
	var root_bottom := root_rect.position.y + root_rect.size.y
	if approval_bottom > root_bottom + 1.0:
		failures.append("approval menu global rect should not overflow below the root rect")
	var approval_button: Button = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ApprovalButton")
	var approval_button_rect: Rect2 = approval_button.get_global_rect()
	if approval_bottom > approval_button_rect.position.y - 7.0:
		failures.append("approval menu should remain above the approval pill without crossing into the composer row")
	controller.call("_rebuild_slash_command_suggestions", "/")
	var slash_height := composer_box.get_combined_minimum_size().y
	if slash_height > baseline_height + 1.0:
		failures.append("slash command menu should float above the composer without increasing composer layout height")
	if slash_panel.get_parent() != popover_layer:
		failures.append("slash command menu should live in the composer popover overlay layer")
	controller.call("_show_add_context_menu")
	var add_context_height := composer_box.get_combined_minimum_size().y
	if add_context_height > baseline_height + 1.0:
		failures.append("add-context menu should float above the composer without increasing composer layout height")
	if add_context_panel.get_parent() != popover_layer or not add_context_panel.visible:
		failures.append("add-context menu should open inside the composer popover overlay layer")
	var add_context_bottom: float = add_context_panel.get_global_rect().position.y + add_context_panel.get_global_rect().size.y
	if add_context_bottom > root_bottom + 1.0:
		failures.append("add-context menu global rect should not overflow below the root rect")
	var add_context_button: Button = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/AddContext")
	if add_context_bottom > add_context_button.get_global_rect().position.y - 7.0:
		failures.append("add-context menu should remain above the plus button without crossing into the composer row")
	var prompt: TextEdit = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/Prompt")
	if not str(prompt.tooltip_text).is_empty():
		failures.append("composer prompt should not use hover tooltip instructions")
	var send_button: Button = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/SendButton")
	if send_button.pressed.is_connected(Callable(controller, "_toggle_send_action_menu")):
		failures.append("send button should not open the legacy send action menu")
	controller.call("_show_model_picker")
	var model_height := composer_box.get_combined_minimum_size().y
	if model_height > baseline_height + 1.0:
		failures.append("model picker should float above the composer without increasing composer layout height")
	if model_panel.get_parent() != popover_layer or not model_panel.visible:
		failures.append("model picker should open inside the composer popover overlay layer")
	var model_surface = model_panel.get_node_or_null("ModelPickerSurface")
	if model_surface != null and absf((model_surface as Control).get_global_rect().size.y - model_panel.get_global_rect().size.y) > 1.0:
		failures.append("model picker surface should match the fixed outer popover height")
	controller.call("_show_reasoning_picker")
	var reasoning_height := composer_box.get_combined_minimum_size().y
	if reasoning_height > baseline_height + 1.0:
		failures.append("reasoning picker should float above the composer without increasing composer layout height")
	if reasoning_panel.get_parent() != popover_layer or not reasoning_panel.visible or model_panel.visible:
		failures.append("reasoning picker should open collapsed, with the model submenu hidden until requested")
	var model_submenu_row = _find_model_submenu_row(reasoning_panel.get_node("ReasoningPickerSurface/ReasoningPickerBox/ReasoningPickerList"))
	if model_submenu_row == null:
		failures.append("reasoning picker should render a model submenu hover row")
	else:
		controller.call("_on_model_submenu_hover_changed", true, model_submenu_row)
	if not model_panel.visible:
		failures.append("model submenu should expand from hovering the reasoning picker model row")
	if model_panel.get_global_rect().size.y > 280.0:
		failures.append("model submenu height should be based on current model choices, not queued old row nodes")
	controller.call("_on_model_submenu_hover_changed", false, model_submenu_row)
	await process_frame
	if model_panel.visible:
		failures.append("model submenu should collapse after hover leaves the model row and submenu")
	root.free()
	await _check_constrained_approval_popover_layout(failures)


func _check_model_reasoning_picker_behavior(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	var controller_script := load(CONTROLLER_SCRIPT)
	if scene == null or controller_script == null or not controller_script.can_instantiate():
		failures.append("model/reasoning picker behavior test should load scene and controller")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_prepare_headless_root(root)
	await process_frame
	var state = State.new()
	var controller = controller_script.new()
	controller.set("_root", root)
	controller.set("_state", state)
	controller.call("_assign_nodes")
	controller.call("_configure_composer_popovers")
	controller.call("_bind_events")
	controller.call("_apply_composer_model", state.call("to_model"))
	controller.call("_show_model_picker")
	await process_frame
	var model_panel = root.get_node("ComposerPopoverLayer/ModelPickerPanel")
	var reasoning_panel = root.get_node("ComposerPopoverLayer/ReasoningPickerPanel")
	if not model_panel.visible:
		failures.append("model picker should open from the composer model button")
	var model_list = root.get_node("ComposerPopoverLayer/ModelPickerPanel/ModelPickerSurface/ModelPickerBox/ModelPickerList")
	if model_list.get_child_count() < 2:
		failures.append("model picker should render provider catalog choices")
	controller.call("_on_model_picker_selected", "gpt-5.4")
	if state.model != "gpt-5.4":
		failures.append("model picker selection should update GodexState.model")
	if model_panel.visible:
		failures.append("model picker should close after selecting a model")
	controller.call("_show_reasoning_picker")
	await process_frame
	if not reasoning_panel.visible or model_panel.visible:
		failures.append("reasoning picker should initially open with the model submenu collapsed")
	var reasoning_list = root.get_node("ComposerPopoverLayer/ReasoningPickerPanel/ReasoningPickerSurface/ReasoningPickerBox/ReasoningPickerList")
	if reasoning_list.get_child_count() < 6:
		failures.append("reasoning picker should render four effort choices plus separator and model submenu row")
	var model_submenu_row = _find_model_submenu_row(reasoning_list)
	if model_submenu_row == null:
		failures.append("reasoning picker should expose the model submenu hover row")
	else:
		controller.call("_on_model_submenu_hover_changed", true, model_submenu_row)
	if not model_panel.visible:
		failures.append("model submenu should expand from hovering the reasoning picker")
	controller.call("_on_model_submenu_hover_changed", false, model_submenu_row)
	await process_frame
	if model_panel.visible:
		failures.append("model submenu should collapse after hover leaves the reasoning picker")
	controller.call("_on_model_submenu_hover_changed", true, model_submenu_row)
	await process_frame
	controller.call("_on_reasoning_picker_selected", "high")
	if state.reasoning_effort != "high":
		failures.append("reasoning picker selection should update GodexState.reasoning_effort")
	if reasoning_panel.visible:
		failures.append("reasoning picker should close after selecting an effort")
	root.free()


func _check_add_context_popover_behavior(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	var controller_script := load(CONTROLLER_SCRIPT)
	if scene == null or controller_script == null or not controller_script.can_instantiate():
		failures.append("add-context popover behavior test should load scene and controller")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_prepare_headless_root(root)
	await process_frame
	var state = State.new()
	var agent = AgentService.new()
	agent.setup(state)
	var controller = controller_script.new()
	controller.set("_root", root)
	controller.set("_state", state)
	controller.set("_agent", agent)
	controller.set("_settings_store", SettingsStore.new())
	controller.set("_session_store", SessionStore.new())
	controller.call("_assign_nodes")
	controller.call("_configure_composer_popovers")
	controller.call("_bind_events")
	controller.call("_apply_composer_model", state.call("to_model"))
	var add_context_button := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/AddContext") as Button
	if not add_context_button.pressed.is_connected(Callable(controller, "_toggle_add_context_menu")):
		failures.append("add-context button should be connected to the menu toggle handler")
	add_context_button.emit_signal("pressed")
	await process_frame
	var panel = root.get_node("ComposerPopoverLayer/AddContextPanel")
	var list = root.get_node("ComposerPopoverLayer/AddContextPanel/AddContextSurface/AddContextBox/AddContextList")
	if not panel.visible:
		failures.append("add-context menu should open from the composer plus button pressed signal")
	if panel.clip_contents:
		failures.append("add-context menu outer panel should avoid clipping rounded corners")
	var project_summary_row = _find_add_context_row_by_title(list, "当前项目摘要")
	var compact_row = _find_add_context_row_by_title(list, "压缩当前会话")
	var plan_row = _find_add_context_row_by_title(list, "计划模式")
	var goal_row = _find_add_context_row_by_title(list, "追求目标")
	var plugins_row = _find_add_context_row_by_title(list, "插件")
	if project_summary_row == null or compact_row == null or plan_row == null or goal_row == null or plugins_row == null:
		failures.append("add-context menu should match the Codex-style composer menu with project, compaction, plan, goal, and plugin rows")
	if compact_row != null and not compact_row.disabled:
		failures.append("add-context compact row should stay disabled until the session is long enough to compact")
	if project_summary_row == null or project_summary_row.get_node_or_null("AddContextRowContent/AddContextIcon") == null:
		failures.append("add-context project-summary row should render a stable Godex-owned icon")
	if compact_row == null or compact_row.get_node_or_null("AddContextRowContent/AddContextIcon") == null:
		failures.append("add-context compact row should render a stable Godex-owned icon")
	if plan_row == null or plan_row.get_node_or_null("AddContextRowContent/AddContextSwitch") == null:
		failures.append("add-context plan mode row should render a compact switch")
	else:
		var plan_switch := plan_row.get_node("AddContextRowContent/AddContextSwitch") as Control
		if plan_switch.custom_minimum_size != Vector2(46, 26):
			failures.append("add-context plan mode switch should keep a 46x26 capsule footprint")
	if goal_row == null or goal_row.get_node_or_null("AddContextRowContent/AddContextSwitch") == null:
		failures.append("add-context goal row should render a compact switch")
	else:
		var goal_switch := goal_row.get_node("AddContextRowContent/AddContextSwitch") as Control
		if goal_switch.custom_minimum_size != Vector2(46, 26):
			failures.append("add-context goal switch should keep a 46x26 capsule footprint")
	if plugins_row == null or plugins_row.get_node_or_null("AddContextRowContent/AddContextChevron") == null:
		failures.append("add-context plugins row should render a submenu chevron")
	if project_summary_row != null:
		project_summary_row.emit_signal("pressed")
		await process_frame
		var action_events := state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "context_menu_action")
		var probe_events := state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "local_tool_probe")
		if action_events.is_empty() or str(action_events[0].get("data", {}).get("kind", "")) != "project_summary":
			failures.append("add-context project-summary row should record an auditable context_menu_action event")
		if probe_events.is_empty():
			failures.append("add-context project-summary row should create a local MCP context probe")
		var context_transcript_items := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "context_menu_action")
		if not context_transcript_items.is_empty():
			failures.append("project-summary bookkeeping should stay out of chat transcript items")
		controller.call("_show_add_context_menu")
		await process_frame
	for i in range(30):
		state.append_message("user", "context warning message %d" % i)
	state.context_budget = 100
	state.context_used = 65
	controller.call("_apply_composer_model", state.call("to_model"))
	controller.call("_rebuild_add_context_menu")
	await process_frame
	if add_context_button.tooltip_text.find("接近自动压缩阈值") < 0:
		failures.append("composer add-context button should expose low-context warning text")
	compact_row = _find_add_context_row_by_title(list, "压缩当前会话")
	if compact_row == null or compact_row.disabled:
		failures.append("add-context compact row should enable when the session can be compacted")
	state.set_change_review_summary({
		"files": [
			{"path": "addons/godex/ui/godex_dock_controller.gd", "added": 7, "removed": 1},
		],
	})
	controller.call("_rebuild_add_context_menu")
	await process_frame
	var recommended_file_row = _find_add_context_row_by_title(list, "添加推荐文件")
	if recommended_file_row == null or recommended_file_row.disabled:
		failures.append("add-context recommended-file row should enable when a recommended changed-file context exists")
	else:
		recommended_file_row.emit_signal("pressed")
		var file_context_events := state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "file_context")
		if file_context_events.is_empty():
			failures.append("add-context recommended-file row should record a file context event")
		var file_transcript_items := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "file_context")
		if not file_transcript_items.is_empty():
			failures.append("file context bookkeeping should stay out of chat transcript items")
		var active_messages := state.active_messages()
		for message in active_messages:
			if str(message.get("content", "")).find("已添加文件上下文") >= 0 or str(message.get("content", "")).find("godex_dock_controller.gd") >= 0:
				failures.append("add-context recommended-file row should not append local context bookkeeping as chat text")
		controller.call("_show_add_context_menu")
		await process_frame
	plan_row = _find_add_context_row_by_title(list, "计划模式")
	if plan_row != null:
		plan_row.emit_signal("pressed")
		await process_frame
		plan_row = _find_add_context_row_by_title(list, "计划模式")
		var plan_switch := plan_row.get_node_or_null("AddContextRowContent/AddContextSwitch") if plan_row != null else null
		if plan_switch == null or not bool(plan_switch.get_meta("switch_enabled", false)):
			failures.append("add-context plan mode switch should rebuild as enabled when toggled")
		if not bool(state.plan_mode_enabled):
			failures.append("add-context plan mode row should persist the state toggle")
		var plan_events := state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "plan_mode")
		if plan_events.is_empty():
			failures.append("add-context plan mode toggle should create an auditable plan_mode event")
		var plan_transcript_items := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "plan_mode")
		if not plan_transcript_items.is_empty():
			failures.append("plan mode bookkeeping should stay out of chat transcript items")
	goal_row = _find_add_context_row_by_title(list, "追求目标")
	if goal_row != null:
		goal_row.emit_signal("pressed")
	await process_frame
	if not bool(state.goal_tracking_enabled):
		failures.append("add-context goal row should toggle goal tracking")
	root.free()


func _check_composer_send_queue_behavior(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	var controller_script := load(CONTROLLER_SCRIPT)
	if scene == null or controller_script == null or not controller_script.can_instantiate():
		failures.append("send action popover behavior test should load scene and controller")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_prepare_headless_root(root)
	await process_frame
	var state = State.new()
	var controller = controller_script.new()
	var agent := AgentService.new()
	agent.setup(state)
	controller.set("_root", root)
	controller.set("_state", state)
	controller.set("_agent", agent)
	controller.set("_settings_store", SettingsStore.new())
	controller.set("_session_store", SessionStore.new())
	controller.call("_assign_nodes")
	controller.call("_configure_composer_popovers")
	controller.call("_bind_events")
	controller.call("_apply_composer_model", state.call("to_model"))
	var user_message_panel: PanelContainer = controller.call("_add_message", "user", "right side bubble")
	var user_row := user_message_panel.get_node_or_null("MessageRowContent")
	var user_spacer := user_message_panel.get_node_or_null("MessageRowContent/UserMessageLeadingSpacer")
	var user_bubble := user_message_panel.get_node_or_null("MessageRowContent/UserMessageBubble")
	var user_content := user_message_panel.get_node_or_null("MessageRowContent/UserMessageBubble/UserMessageBubbleContent")
	var user_label := user_message_panel.get_node_or_null("MessageRowContent/UserMessageBubble/UserMessageBubbleContent/MessageText")
	var user_copy := user_message_panel.find_child("MessageCopyButton", true, false) as Button
	if user_row == null or user_spacer == null or user_bubble == null or user_content == null or user_label == null:
		failures.append("user chat messages should render as a right-aligned bubble with a leading spacer")
	else:
		if int(user_message_panel.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0 or int(user_row.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0:
			failures.append("message row containers should fill the transcript column so bubbles do not float in the center")
		if not (user_bubble is PanelContainer):
			failures.append("user chat message bubble should be a panel so the rounded bubble background is visible")
		if int(user_spacer.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0 or int(user_bubble.size_flags_horizontal) & int(Control.SIZE_SHRINK_END) == 0:
			failures.append("user chat message bubble should stay right-aligned in the transcript row")
		if int(user_label.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0:
			failures.append("message text should fill its own container while the user bubble controls the visible width")
		if user_bubble.custom_minimum_size.x < 112.0:
			failures.append("user chat message bubble should keep a Codex-like minimum width so short CJK prompts do not wrap vertically")
		if user_bubble.get_combined_minimum_size().y > 52.0:
			failures.append("short user chat bubbles should not reserve a large blank area below the text")
		if bool(user_label.scroll_active):
			failures.append("chat message text should be selectable without enabling an internal scroll area")
		if user_bubble.get_child_count() != 1:
			failures.append("message copy affordance should overlay the row instead of adding vertical bubble content")
		if user_copy == null or user_copy.visible:
			failures.append("message rows should expose a hidden hover copy icon")
		if user_copy != null and str(user_copy.tooltip_text) != "复制":
			failures.append("message hover copy icon should expose a concise copy tooltip")
		controller.call("_on_message_hover_changed", user_message_panel, true)
		if user_copy == null or not user_copy.visible:
			failures.append("message hover should reveal the copy icon")
		controller.call("_on_message_hover_changed", user_message_panel, false)
		if user_copy != null and user_copy.visible:
			failures.append("message copy icon should hide again when the pointer leaves")
		controller.call("_ensure_selection_action_panel")
		var selection_panel := root.get_node_or_null("ComposerPopoverLayer/SelectionActionPanel") as PanelContainer
		var selection_label: Node = root.get_node_or_null("ComposerPopoverLayer/SelectionActionPanel/SelectionActionBar/SelectionActionLabel")
		var add_selection_button := root.get_node_or_null("ComposerPopoverLayer/SelectionActionPanel/SelectionActionBar/SelectionAddToConversation") as Button
		var ask_selection_button := root.get_node_or_null("ComposerPopoverLayer/SelectionActionPanel/SelectionActionBar/SelectionAskSideChat") as Button
		if selection_panel == null or add_selection_button == null or ask_selection_button == null:
			failures.append("assistant selection actions should render a Codex-style floating action pill")
		else:
			if selection_label != null:
				failures.append("assistant selection action pill should not show selected text content")
			if add_selection_button.icon == null or ask_selection_button.icon == null:
				failures.append("assistant selection action buttons should include left-side icons")
			if add_selection_button.custom_minimum_size.y < 36.0 or ask_selection_button.custom_minimum_size.y < 36.0:
				failures.append("assistant selection action buttons should be large rounded pills")
	var assistant_message_panel: PanelContainer = controller.call("_add_message", "assistant", "assistant body")
	if assistant_message_panel.get_node_or_null("MessageRowContent/UserMessageBubble") != null or assistant_message_panel.get_node_or_null("MessageRowContent/AssistantMessageContent") == null:
		failures.append("assistant messages should stay in the continuous left transcript flow instead of using the user bubble")
	var assistant_row := assistant_message_panel.get_node_or_null("MessageRowContent") as Control
	var assistant_content := assistant_message_panel.get_node_or_null("MessageRowContent/AssistantMessageContent") as Control
	var assistant_label := assistant_message_panel.get_node_or_null("MessageRowContent/AssistantMessageContent/MessageText") as Control
	if assistant_row == null or assistant_content == null or assistant_label == null:
		failures.append("assistant messages should render a full-width content row")
	else:
		if int(assistant_message_panel.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0 or int(assistant_row.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0:
			failures.append("assistant message rows should fill the transcript column")
		if int(assistant_content.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0 or int(assistant_label.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0:
			failures.append("assistant message text should use the full transcript column width")
	var send_button := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/SendButton") as Button
	var prompt := root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/Prompt") as TextEdit
	var skill_search: Control = root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/SkillManagerSearch") as Control
	var skill_list: Control = root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent/SkillManagerList") as Control
	if skill_search == null or skill_list == null:
		failures.append("settings skills page should expose a searchable local Skill manager list")
	else:
		state.set_skill_registry_model({
			"skill_count": 1,
			"enabled_count": 1,
			"skills": [
				{
					"name": "planner",
					"short_description": "Plan local Godex work",
					"enabled": true,
					"policy": {"allow_implicit_invocation": false},
				},
			],
		})
		if state.enabled_skill_prompt_from_registry().find("$planner") < 0 or state.enabled_skill_prompt_from_registry().find("explicit-only") < 0:
			failures.append("enabled Skill registry records should project into the next Agent instruction prompt")
	if not send_button.pressed.is_connected(Callable(controller, "_on_send_button_pressed")):
		failures.append("send button should send directly through the composer action handler")
	if send_button.pressed.is_connected(Callable(controller, "_toggle_send_action_menu")):
		failures.append("send button should not open the legacy send action menu")
	if send_button.disabled:
		failures.append("empty idle send button should stay interactive so the Codex-style hint can explain the action")
	send_button.emit_signal("pressed")
	await process_frame
	var send_hint_panel := root.get_node_or_null("ComposerPopoverLayer/SendButtonHintPanel") as PanelContainer
	var send_hint_text := root.get_node_or_null("ComposerPopoverLayer/SendButtonHintPanel/SendButtonHintBox/SendButtonHintText") as Label
	if send_hint_panel == null or not send_hint_panel.visible or send_hint_text == null or send_hint_text.text != "输入消息，点击发送以开始使用":
		failures.append("empty idle send button should show a persistent Codex-style action hint when clicked")
	controller.call("_hide_send_button_hint")
	if not str(prompt.tooltip_text).is_empty():
		failures.append("composer input should not show hover tooltip text")
	if root.get_node_or_null("ComposerPopoverLayer/SendActionPanel") != null:
		failures.append("legacy send action menu node should be removed from the scene")
	prompt.text = "keyboard send"
	var enter_event := InputEventKey.new()
	enter_event.pressed = true
	enter_event.keycode = KEY_ENTER
	controller.call("_on_composer_gui_input", enter_event)
	await process_frame
	var keyboard_sent := state.active_messages().filter(func(message): return str(message.get("role", "")) == "user" and str(message.get("content", "")) == "keyboard send")
	if keyboard_sent.is_empty():
		failures.append("composer Enter should send the prompt while idle")
	state.is_running = false
	state.stop_agent_loop("test_idle_reset")
	prompt.text = "stop this draft"
	state.is_running = true
	state.begin_agent_loop("user_prompt")
	var esc_event := InputEventKey.new()
	esc_event.pressed = true
	esc_event.keycode = KEY_ESCAPE
	controller.call("_on_composer_gui_input", esc_event)
	await process_frame
	if bool(state.get("is_running")) or str(state.get("agent_loop_status")) == "running":
		failures.append("composer Esc should stop the current request")
	state.is_running = true
	state.begin_agent_loop("user_prompt")
	send_button.emit_signal("pressed")
	await process_frame
	var queued_messages: Array[Dictionary] = []
	queued_messages = state.active_queued_user_messages()
	if not queued_messages.is_empty():
		failures.append("running send button should stop the active request instead of queueing composer text")
	if prompt.text != "stop this draft":
		failures.append("running send button should preserve the draft while stopping")
	if bool(state.get("is_running")) or str(state.get("agent_loop_status")) == "running":
		failures.append("running send button should stop the current agent loop")
	var queue_transcript := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "queued_user_message")
	if not queue_transcript.is_empty():
		failures.append("queued user message bookkeeping should stay out of chat transcript items")
	var queue_surface := root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerQueueSurface") as PanelContainer
	var queue_list := root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerQueueSurface/ComposerQueueMargin/ComposerQueueList") as VBoxContainer
	var change_review_surface := root.get_node_or_null("Root/Shell/MainPanel/Main/Body/MainCenter/ChangeReviewSurface") as PanelContainer
	if queue_surface != null and change_review_surface != null and queue_surface.get_index() > change_review_surface.get_index():
		failures.append("queued composer messages should sit above the goal/review strip, not between the strip and input")
	var guide_transcript := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "pending_steer")
	if not guide_transcript.is_empty():
		failures.append("pending guide instruction bookkeeping should stay out of chat transcript items")
	prompt.text = "enter queued draft"
	state.is_running = true
	state.begin_agent_loop("user_prompt")
	controller.call("_on_composer_gui_input", enter_event)
	await process_frame
	var enter_queued := state.active_queued_user_messages().filter(func(record): return str(record.get("text", "")) == "enter queued draft" and str(record.get("status", "")) == "queued")
	if enter_queued.is_empty():
		failures.append("composer Enter should queue the prompt while running")
	for record in enter_queued:
		state.cancel_queued_user_message(str(record.get("id", "")), "test_cleanup")
	state.is_running = false
	state.stop_agent_loop("test_resume")
	prompt.text = "ctrl enter guide"
	var ctrl_enter_event := InputEventKey.new()
	ctrl_enter_event.pressed = true
	ctrl_enter_event.keycode = KEY_ENTER
	ctrl_enter_event.ctrl_pressed = true
	controller.call("_on_composer_gui_input", ctrl_enter_event)
	await process_frame
	var ctrl_sent := state.active_messages().filter(func(message): return str(message.get("role", "")) == "user" and str(message.get("content", "")) == "ctrl enter guide")
	if ctrl_sent.is_empty():
		failures.append("composer Ctrl+Enter should directly guide/send when idle")
	state.is_running = false
	state.stop_agent_loop("test_queue_reset")
	prompt.text = ""
	state.queue_user_message_with_action("queue this draft", "test", "plain")
	controller.call("_apply_model", state.call("to_model"))
	await process_frame
	if queue_list != null:
		if queue_list.get_child_count() != 1:
			failures.append("queued composer messages should render as rows above the composer")
		else:
			var queue_row := queue_list.get_child(0)
			if queue_row.get_node_or_null("ComposerQueueGuide") == null or queue_row.get_node_or_null("ComposerQueueDelete") == null:
				failures.append("composer queue row should expose guide and delete actions")
			var queue_text := queue_row.get_node_or_null("ComposerQueueText") as Label
			if queue_text == null or str(queue_text.text).find("queue this draft") < 0:
				failures.append("composer queue row should preview queued user text")
			var guide_button := queue_row.get_node_or_null("ComposerQueueGuide") as Button
			if guide_button != null:
				guide_button.emit_signal("pressed")
				await process_frame
				var pending_guide: Dictionary = state.active_pending_guide_instruction()
				var sent_queue_prompt := state.active_messages().filter(func(message): return str(message.get("role", "")) == "user" and str(message.get("content", "")) == "queue this draft")
				if not pending_guide.is_empty() or sent_queue_prompt.is_empty():
					failures.append("composer queue guide action should directly send queued text when the agent is idle")
	else:
		failures.append("queued composer messages should render as rows above the composer")
	state.call("cancel_pending_steer", str(state.active_pending_guide_instruction().get("id", "")), "test")
	state.queue_user_message_with_action("delete this draft", "test", "plain")
	controller.call("_apply_model", state.call("to_model"))
	await process_frame
	var delete_row: Node = null
	if queue_list != null:
		for child in queue_list.get_children():
			var text_label := child.get_node_or_null("ComposerQueueText") as Label
			if text_label != null and str(text_label.text).find("delete this draft") >= 0:
				delete_row = child
	if delete_row == null:
		failures.append("composer queue should render newly queued running draft")
	else:
		var delete_button := delete_row.get_node_or_null("ComposerQueueDelete") as Button
		if delete_button == null:
			failures.append("composer queue row should expose a delete button")
		else:
			delete_button.emit_signal("pressed")
			await process_frame
			var deleted_records := state.active_queued_user_messages().filter(func(record): return str(record.get("text", "")) == "delete this draft" and str(record.get("status", "")) == "cancelled")
			if deleted_records.is_empty():
				failures.append("composer queue delete action should cancel that queued message")
	state.is_running = false
	state.api_key = "sk-local-test-token"
	state.approval_mode = "请求批准"
	var active_guide: Dictionary = state.active_pending_guide_instruction()
	if not active_guide.is_empty():
		state.call("cancel_pending_steer", str(active_guide.get("id", "")), "test")
	prompt.text = ""
	state.queue_user_message_with_action("/goal queued slash goal", "test", "parse_slash")
	if not controller.call("_maybe_send_next_queued_user_message"):
		failures.append("queued slash prompts should drain locally from the direct send queue")
	queued_messages = state.active_queued_user_messages()
	var submitted_slash := queued_messages.filter(func(record): return str(record.get("text", "")) == "/goal queued slash goal" and str(record.get("action", "")) == "parse_slash" and str(record.get("submitted_turn_id", "")) == "queued_slash_command")
	if submitted_slash.is_empty():
		failures.append("queued slash prompts should drain locally with slash-command attribution")
	if str(state.active_goal_record().get("summary", "")).find("queued slash goal") < 0:
		failures.append("queued slash prompts should execute local slash command effects")
	state.queue_user_message_with_action("queue after cancel", "test", "plain")
	prompt.text = "unsent draft"
	if controller.call("_maybe_send_next_queued_user_message"):
		failures.append("queued user messages should not drain while the composer contains an unsent draft")
	prompt.text = ""
	if not controller.call("_maybe_send_next_queued_user_message"):
		failures.append("queued user messages should drain once the composer is idle and credentials are ready")
	queued_messages = state.active_queued_user_messages()
	var submitted_drained := queued_messages.filter(func(record): return str(record.get("text", "")) == "queue after cancel" and str(record.get("status", "")) == "submitted")
	if submitted_drained.is_empty():
		failures.append("queued user messages should be marked submitted after draining")
	if submitted_drained.is_empty() or str(submitted_drained[0].get("submitted_turn_id", "")).is_empty():
		failures.append("drained queued user messages should record the submitted turn id")
	if state.latest_pending_approval().is_empty() or str(state.latest_pending_approval().get("source", "")) != "queued_user_message":
		failures.append("drained queued user messages should preserve their OpenAI approval source")
	state.command_enabled = true
	state.command_shell = "PowerShell"
	state.command_working_directory = "res://"
	state.command_timeout_sec = 30
	prompt.text = ""
	state.queue_user_message_with_action("!echo hi", "test", "run_shell")
	controller.call("_maybe_send_next_queued_user_message")
	await process_frame
	queued_messages = state.active_queued_user_messages()
	var submitted_shell := queued_messages.filter(func(record): return str(record.get("text", "")) == "!echo hi" and str(record.get("action", "")) == "run_shell" and str(record.get("status", "")) == "submitted")
	if submitted_shell.is_empty():
		failures.append("queued bang prompts should be marked submitted after command approval handoff")
	var command_runs := state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "command_run" and str(event.get("data", {}).get("command", "")) == "echo hi")
	if command_runs.is_empty():
		failures.append("queued bang prompts should create a command_run event for the shell body")
	else:
		var command_data: Dictionary = command_runs[0].get("data", {})
		if str(command_data.get("status", "")) != "approval_required":
			failures.append("queued bang command_run should wait for command approval instead of executing immediately")
		if str(command_data.get("source", "")) != "queued_shell_prompt":
			failures.append("queued bang command_run should preserve queued shell source metadata")
		if int(command_data.get("timeout_sec", 0)) <= 0:
			failures.append("queued bang command_run should keep the configured timeout")
	var command_approval: Array = state.approval_records.filter(func(record): return str(record.get("command", "")) == "echo hi" and str(record.get("status", "")) == "pending")
	if command_approval.is_empty():
		failures.append("queued bang prompts should create a pending command approval checkpoint")
	root.free()


func _find_model_submenu_row(parent: Node) -> Button:
	if parent == null:
		return null
	for child in parent.get_children():
		if not (child is Button):
			continue
		var check = child.get_node_or_null("PickerRowContent/PickerCheck")
		if check != null and str(check.text) == "›":
			return child
	return null


func _find_add_context_row_by_title(parent: Node, title_text: String) -> Button:
	if parent == null:
		return null
	for child in parent.get_children():
		if not (child is Button):
			continue
		var title = child.get_node_or_null("AddContextRowContent/AddContextCopy/AddContextTitle")
		if title != null and str(title.text) == title_text:
			return child
	return null


func _check_constrained_approval_popover_layout(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	var controller_script := load(CONTROLLER_SCRIPT)
	if scene == null or controller_script == null or not controller_script.can_instantiate():
		failures.append("constrained approval popover test should load scene and controller")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	_prepare_headless_root(root, CONSTRAINED_ROOT_SIZE)
	await process_frame
	var controller = controller_script.new()
	controller.set("_root", root)
	controller.set("_state", State.new())
	controller.call("_assign_nodes")
	controller.call("_configure_composer_popovers")
	controller.call("_show_approval_mode_menu")
	await process_frame
	var root_control := root as Control
	if root_control == null:
		failures.append("constrained approval popover root should instantiate as a Control")
		root.free()
		return
	var popover_layer = root.get_node_or_null("ComposerPopoverLayer")
	var approval_panel = popover_layer.get_node_or_null("ApprovalModePanel") if popover_layer != null else null
	if popover_layer == null or approval_panel == null:
		failures.append("constrained approval popover should still use the overlay layer")
		root.free()
		return
	if not approval_panel.clip_contents:
		failures.append("constrained approval popover should clip content inside the panel rect")
	var approval_rect: Rect2 = approval_panel.get_global_rect()
	var approval_surface = approval_panel.get_node_or_null("ApprovalModeSurface")
	if approval_surface != null and (approval_surface as Control).get_global_rect().size.y > approval_rect.size.y + 1.0:
		failures.append("constrained approval popover surface should not grow beyond the clipped outer rect")
	var root_rect: Rect2 = root_control.get_global_rect()
	var approval_button: Button = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ApprovalButton")
	var approval_button_rect: Rect2 = approval_button.get_global_rect()
	var approval_bottom := approval_rect.position.y + approval_rect.size.y
	var root_bottom := root_rect.position.y + root_rect.size.y
	if approval_bottom > root_bottom + 1.0:
		failures.append("constrained approval popover should not overflow below the root rect")
	if approval_bottom > approval_button_rect.position.y - 7.0:
		failures.append("constrained approval popover should stay above the approval pill")
	var expected_height := float(controller.call("_approval_mode_popover_height"))
	if approval_panel.size.y > expected_height + 1.0:
		failures.append("constrained approval popover should never expand beyond the Codex-like content height")
	if approval_panel.size.y >= 500.0 or approval_panel.get_combined_minimum_size().y >= 500.0:
		failures.append("constrained approval popover should not regain a 500px-class height")
	root.free()


func _check_slash_command_keyboard_navigation(failures: Array[String]) -> void:
	var scene := load(MAIN_SCENE)
	var controller_script := load(CONTROLLER_SCRIPT)
	if scene == null or controller_script == null or not controller_script.can_instantiate():
		failures.append("slash command keyboard test should load scene and controller")
		return
	var root = scene.instantiate()
	get_root().add_child(root)
	var controller = controller_script.new()
	controller.set("_root", root)
	controller.set("_state", State.new())
	controller.call("_assign_nodes")
	controller.call("_configure_composer_popovers")
	var prompt: TextEdit = root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/Prompt")
	var panel: PanelContainer = root.get_node("ComposerPopoverLayer/SlashCommandPanel")
	controller.call("_rebuild_slash_command_suggestions", "/")
	if not panel.visible:
		failures.append("slash command keyboard menu should open for slash input")
	if int(controller.get("_slash_command_selected_index")) != 0:
		failures.append("slash command keyboard menu should select the first row by default")
	controller.call("_on_composer_gui_input", _key_event(KEY_DOWN))
	if int(controller.get("_slash_command_selected_index")) != 1:
		failures.append("slash command keyboard Down should move to the next row")
	controller.call("_on_composer_gui_input", _key_event(KEY_UP))
	if int(controller.get("_slash_command_selected_index")) != 0:
		failures.append("slash command keyboard Up should return to the previous row")
	controller.call("_on_composer_gui_input", _key_event(KEY_UP))
	var suggestions: Array = controller.get("_slash_command_suggestions")
	if int(controller.get("_slash_command_selected_index")) != suggestions.size() - 1:
		failures.append("slash command keyboard selection should wrap from first to last")
	var selected_insert := str(suggestions[int(controller.get("_slash_command_selected_index"))].get("insert_text", suggestions[int(controller.get("_slash_command_selected_index"))].get("command", "")))
	controller.call("_on_composer_gui_input", _key_event(KEY_ENTER))
	if prompt.text != selected_insert:
		failures.append("slash command keyboard Enter should insert the selected row command")
	if prompt.get_caret_column() != prompt.text.length():
		failures.append("slash command keyboard Enter should keep the caret at the inserted command end")
	if panel.visible:
		failures.append("slash command keyboard Enter should close the menu after inserting the selected command")
	root.free()

	var esc_root = scene.instantiate()
	get_root().add_child(esc_root)
	var esc_controller = controller_script.new()
	esc_controller.set("_root", esc_root)
	esc_controller.set("_state", State.new())
	esc_controller.call("_assign_nodes")
	esc_controller.call("_configure_composer_popovers")
	var esc_prompt: TextEdit = esc_root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/ComposerPanel/ComposerBox/Prompt")
	var esc_panel: PanelContainer = esc_root.get_node("ComposerPopoverLayer/SlashCommandPanel")
	esc_prompt.text = "/re"
	esc_controller.call("_rebuild_slash_command_suggestions", esc_prompt.text)
	esc_controller.call("_on_composer_gui_input", _key_event(KEY_ESCAPE))
	if esc_panel.visible:
		failures.append("slash command keyboard Esc should close the menu")
	if esc_prompt.text != "/re":
		failures.append("slash command keyboard Esc should preserve composer text")
	esc_root.free()


func _key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	return event


func _check_openai_payloads(failures: Array[String]) -> void:
	var messages := [{"role": "user", "content": "Check scene"}]
	var responses := RequestBuilder.build_responses_payload("gpt-5.5", "Inspect Godot", messages)
	if responses.get("model", "") != "gpt-5.5" or not responses.has("input"):
		failures.append("responses payload shape invalid")
	var reasoning_responses := RequestBuilder.build_responses_payload("gpt-5.5", "Inspect Godot", messages, [], {"reasoning_effort": "high"})
	if reasoning_responses.get("reasoning", {}).get("effort", "") != "high":
		failures.append("responses payload should include selected reasoning effort")
	var chat := RequestBuilder.build_chat_completions_payload("gpt-5.5", "Inspect Godot", messages)
	if chat.get("model", "") != "gpt-5.5" or not chat.has("messages"):
		failures.append("chat completions payload shape invalid")
	var chat_tools_payload := RequestBuilder.build_chat_completions_payload("gpt-5.5", "Inspect Godot", messages, [
		{
			"type": "function",
			"name": "godex_mcp_context",
			"description": "Read Godot context.",
			"parameters": {"type": "object", "properties": {"scope": {"type": "string"}}},
		},
	])
	var chat_tools: Array = chat_tools_payload.get("tools", [])
	var first_chat_tool: Dictionary = chat_tools[0] if not chat_tools.is_empty() and chat_tools[0] is Dictionary else {}
	var first_chat_function: Dictionary = first_chat_tool.get("function", {}) if first_chat_tool.get("function", {}) is Dictionary else {}
	if first_chat_tool.get("type", "") != "function" or first_chat_function.get("name", "") != "godex_mcp_context" or not (first_chat_function.get("parameters", {}) is Dictionary):
		failures.append("chat completions payload should wrap Responses-style tools in Chat function schema")
	var reasoning_chat := RequestBuilder.build_chat_completions_payload("gpt-5.5", "Inspect Godot", messages, [], {"reasoning_effort": "low"})
	if reasoning_chat.get("reasoning_effort", "") != "low":
		failures.append("chat payload should include selected reasoning effort")
	if RequestBuilder.endpoint_for("https://api.openai.com", "responses") != "https://api.openai.com/v1/responses":
		failures.append("responses endpoint invalid")
	if RequestBuilder.endpoint_for("https://yurenapi.com/v1", "responses") != "https://yurenapi.com/v1/responses":
		failures.append("responses endpoint should not duplicate v1")
	if RequestBuilder.endpoint_for("https://yurenapi.cn/v1", "responses") != "https://yurenapi.cn/v1/responses":
		failures.append("responses endpoint should support the recommended yurenapi.cn v1 base URL")
	if RequestBuilder.endpoint_for("https://yurenapi.cn/v1", "chat_completions") != "https://yurenapi.cn/v1/chat/completions":
		failures.append("chat completions endpoint should support the recommended yurenapi.cn v1 base URL")
	var headers := RequestBuilder.build_headers("sk-test-token")
	if not Array(headers).has("Authorization: Bearer sk-test-token"):
		failures.append("request headers should include bearer token")
	if RequestBuilder.mask_api_key("sk-1234567890") != "sk-1****7890":
		failures.append("api key mask should preserve only short edges")
	var tool_call := {"id": "call_1", "name": "godex_mcp_context", "arguments": {"scope": "summary"}}
	var responses_tool_result := RequestBuilder.build_responses_tool_result_payload("gpt-5.5", "Inspect Godot", messages, tool_call, "{\"ok\":true}")
	var responses_input: Array = responses_tool_result.get("input", [])
	if responses_input.size() < 3 or responses_input[-1].get("type", "") != "function_call_output" or responses_input[-1].get("call_id", "") != "call_1":
		failures.append("responses tool-result payload should append function_call_output")
	var response_bound_tool_call := tool_call.duplicate(true)
	response_bound_tool_call["response_id"] = "resp_123"
	var incremental_tool_result := RequestBuilder.build_responses_tool_result_payload("gpt-5.5", "Inspect Godot", messages, response_bound_tool_call, "{\"ok\":true}", [], {"reasoning_effort": "medium"})
	var incremental_input: Array = incremental_tool_result.get("input", [])
	if incremental_tool_result.get("previous_response_id", "") != "resp_123":
		failures.append("responses tool-result payload should retain provider response id as previous_response_id")
	if incremental_input.size() != 1 or incremental_input[0].get("type", "") != "function_call_output" or incremental_input[0].get("call_id", "") != "call_1":
		failures.append("responses tool-result payload should only send function_call_output when previous_response_id is available")
	var reasoning_tool_result := RequestBuilder.build_responses_tool_result_payload("gpt-5.5", "Inspect Godot", messages, tool_call, "{\"ok\":true}", [], {"reasoning_effort": "xhigh"})
	if reasoning_tool_result.get("reasoning", {}).get("effort", "") != "xhigh":
		failures.append("responses tool-result payload should retain selected reasoning effort")
	var streaming_payload := RequestBuilder.build_responses_payload("gpt-5.5", "Inspect Godot", messages, [], {"stream": true})
	if not bool(streaming_payload.get("stream", false)):
		failures.append("responses payload should enable streaming when requested")
	var chat_tool_result := RequestBuilder.build_chat_completions_tool_result_payload("gpt-5.5", "Inspect Godot", messages, tool_call, "{\"ok\":true}")
	var chat_messages: Array = chat_tool_result.get("messages", [])
	if chat_messages.size() < 3 or chat_messages[-1].get("role", "") != "tool" or chat_messages[-1].get("tool_call_id", "") != "call_1":
		failures.append("chat tool-result payload should append tool role output")
	var streaming_chat_payload := RequestBuilder.build_chat_completions_payload("gpt-5.5", "Inspect Godot", messages, [], {"stream": true})
	if not bool(streaming_chat_payload.get("stream", false)):
		failures.append("chat payload should enable streaming when requested")


func _check_openai_execution_service(failures: Array[String]) -> void:
	var service := OpenAIExecutionService.new()
	var missing_snapshot := service.build_request_snapshot({"endpoint": "https://api.openai.com/v1/responses", "has_api_key": false}, {"model": "gpt-5.5"})
	if bool(missing_snapshot.get("ready", true)) or missing_snapshot.get("error", "") != "missing_api_key":
		failures.append("OpenAI request snapshot should block missing API key")
	var ready_snapshot := service.build_request_snapshot({
		"endpoint": "https://api.openai.com/v1/responses",
		"has_api_key": true,
		"key_source": "inline",
		"masked_api_key": "sk-t****oken",
		"headers": RequestBuilder.build_headers("sk-test-token"),
	}, {"model": "gpt-5.5", "reasoning": {"effort": "high"}})
	if not bool(ready_snapshot.get("ready", false)) or Array(ready_snapshot.get("headers", [])).has("Authorization: Bearer sk-test-token"):
		failures.append("OpenAI request snapshot should keep audit headers masked")
	if ready_snapshot.get("reasoning_effort", "") != "high":
		failures.append("OpenAI request snapshot should expose reasoning effort")
	var transport_request := service.build_transport_request({
		"endpoint": "https://api.openai.com/v1/responses",
		"has_api_key": true,
		"key_source": "inline",
		"masked_api_key": "sk-t****oken",
		"headers": RequestBuilder.build_headers("sk-test-token"),
	}, {"model": "gpt-5.5"})
	if not Array(transport_request.get("headers", [])).has("Authorization: Bearer sk-test-token"):
		failures.append("OpenAI transport request should include raw headers")
	var responses := service.parse_response("responses", JSON.stringify({
		"id": "resp_parse_1",
		"output": [
			{"type": "message", "content": [{"type": "output_text", "text": "Done."}]},
			{"type": "function_call", "call_id": "call_1", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
		],
	}))
	if not bool(responses.get("success", false)) or responses.get("text", "") != "Done." or responses.get("tool_calls", []).size() != 1:
		failures.append("Responses parser should extract text and tool calls")
	var parsed_response_tool_calls: Array = responses.get("tool_calls", [])
	var parsed_response_tool_call: Dictionary = parsed_response_tool_calls[0] if not parsed_response_tool_calls.is_empty() and parsed_response_tool_calls[0] is Dictionary else {}
	if responses.get("response_id", "") != "resp_parse_1" or parsed_response_tool_call.get("response_id", "") != "resp_parse_1":
		failures.append("Responses parser should retain provider response ids on parsed tool calls")
	var top_level_responses := service.parse_response("responses", JSON.stringify({
		"id": "resp_top_level_text",
		"output_text": "Top-level answer.",
	}))
	if not bool(top_level_responses.get("success", false)) or top_level_responses.get("text", "") != "Top-level answer." or top_level_responses.get("response_id", "") != "resp_top_level_text":
		failures.append("Responses parser should extract top-level output_text convenience fields")
	var canonical_and_top_level_responses := service.parse_response("responses", JSON.stringify({
		"id": "resp_canonical_text",
		"output_text": "Canonical answer.",
		"output": [{"type": "message", "content": [{"type": "output_text", "text": "Canonical answer."}]}],
	}))
	if canonical_and_top_level_responses.get("text", "") != "Canonical answer.":
		failures.append("Responses parser should avoid duplicating top-level output_text when canonical output content exists")
	var chat := service.parse_response("chat_completions", JSON.stringify({
		"choices": [{"message": {"content": "Chat done.", "tool_calls": [{"id": "tool_1", "function": {"name": "godex_request_approval", "arguments": "{}"}}]}}],
	}))
	if not bool(chat.get("success", false)) or chat.get("text", "") != "Chat done." or chat.get("tool_calls", []).size() != 1:
		failures.append("Chat parser should extract message text and tool calls")
	var chat_parts := service.parse_response("chat_completions", JSON.stringify({
		"choices": [{"message": {"content": [
			{"type": "text", "text": "Chat part one."},
			{"type": "output_text", "text": "Chat part two."},
		]}}],
	}))
	if not bool(chat_parts.get("success", false)) or chat_parts.get("text", "") != "Chat part one.\nChat part two.":
		failures.append("Chat parser should extract array content parts from OpenAI-compatible responses")
	var http_error := service.parse_http_result("responses", 401, JSON.stringify({"error": {"type": "invalid_api_key", "message": "Bad key"}}))
	if bool(http_error.get("success", true)) or http_error.get("error", "") != "invalid_api_key" or int(http_error.get("status_code", 0)) != 401:
		failures.append("HTTP error parser should normalize OpenAI errors")


func _check_openai_streaming_contract(failures: Array[String]) -> void:
	var service := OpenAIExecutionService.new()
	var responses_delta := service.parse_stream_data("responses", JSON.stringify({"type": "response.output_text.delta", "delta": "Hello"}))
	if not bool(responses_delta.get("success", false)) or responses_delta.get("text_delta", "") != "Hello":
		failures.append("Responses stream parser should normalize output_text delta")
	var responses_text_done := service.parse_stream_data("responses", JSON.stringify({"type": "response.output_text.done", "text": "Done text."}))
	if not bool(responses_text_done.get("success", false)) or responses_text_done.get("final_text", "") != "Done text.":
		failures.append("Responses stream parser should retain final text from output_text.done events")
	var responses_refusal_done := service.parse_stream_data("responses", JSON.stringify({"type": "response.refusal.done", "refusal": "Refused."}))
	if not bool(responses_refusal_done.get("success", false)) or responses_refusal_done.get("final_text", "") != "Refused.":
		failures.append("Responses stream parser should retain final refusal text from refusal.done events")
	var responses_created := service.parse_stream_data("responses", JSON.stringify({
		"type": "response.created",
		"response": {"id": "resp_created_1"},
	}))
	if responses_created.get("response_id", "") != "resp_created_1":
		failures.append("Responses stream parser should retain response ids from response.created events")
	var responses_done := service.parse_stream_data("responses", JSON.stringify({"type": "response.completed"}))
	if not bool(responses_done.get("completed", false)):
		failures.append("Responses stream parser should mark response.completed as complete")
	var responses_completed_payload := service.parse_stream_data("responses", JSON.stringify({
		"type": "response.completed",
		"response": {
			"id": "resp_completed_1",
			"output": [
				{"type": "message", "content": [{"type": "output_text", "text": "Completed payload answer."}]},
				{"type": "function_call", "call_id": "call_completed", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
			],
		},
	}))
	if not bool(responses_completed_payload.get("completed", false)) or responses_completed_payload.get("final_text", "") != "Completed payload answer." or responses_completed_payload.get("tool_calls", []).size() != 1:
		failures.append("Responses stream parser should extract final response output from response.completed events")
	var completed_response_tool_calls: Array = responses_completed_payload.get("tool_calls", [])
	var completed_response_tool_call: Dictionary = completed_response_tool_calls[0] if not completed_response_tool_calls.is_empty() and completed_response_tool_calls[0] is Dictionary else {}
	if responses_completed_payload.get("response_id", "") != "resp_completed_1" or completed_response_tool_call.get("response_id", "") != "resp_completed_1":
		failures.append("Responses stream parser should retain response ids from completed payloads")
	var responses_completed_top_level := service.parse_stream_data("responses", JSON.stringify({
		"type": "response.completed",
		"output_text": "Completed top-level answer.",
	}))
	if not bool(responses_completed_top_level.get("completed", false)) or responses_completed_top_level.get("final_text", "") != "Completed top-level answer.":
		failures.append("Responses stream parser should extract top-level completed output_text")
	var responses_completed_response_text := service.parse_stream_data("responses", JSON.stringify({
		"type": "response.completed",
		"response": {"id": "resp_completed_text", "output_text": "Completed response text."},
	}))
	if responses_completed_response_text.get("response_id", "") != "resp_completed_text" or responses_completed_response_text.get("final_text", "") != "Completed response text.":
		failures.append("Responses stream parser should extract response.completed response output_text fields")
	var responses_tool_added := service.parse_stream_data("responses", JSON.stringify({
		"type": "response.output_item.added",
		"output_index": 0,
		"item": {"type": "function_call", "call_id": "call_stream", "name": "godex_mcp_context"},
	}))
	if responses_tool_added.get("tool_calls", []).size() != 0 or responses_tool_added.get("tool_call_deltas", []).size() != 1:
		failures.append("Responses stream parser should treat output_item.added as partial tool-call metadata")
	var responses_tool_done := service.parse_stream_data("responses", JSON.stringify({
		"type": "response.output_item.done",
		"output_index": 0,
		"item": {"type": "function_call", "call_id": "call_stream", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
	}))
	if responses_tool_done.get("tool_calls", []).size() != 1:
		failures.append("Responses stream parser should extract completed function_call items")
	if bool(responses_tool_done.get("completed", false)):
		failures.append("Responses stream parser should not treat response.output_item.done as full stream completion")
	var responses_tool_delta := service.parse_stream_data("responses", JSON.stringify({
		"type": "response.function_call_arguments.delta",
		"item_id": "call_stream",
		"delta": "{\"scope\"",
	}))
	if responses_tool_delta.get("tool_call_deltas", []).size() != 1:
		failures.append("Responses stream parser should expose function_call argument deltas")
	var chat_delta := service.parse_stream_data("chat_completions", JSON.stringify({"choices": [{"delta": {"content": "Hi"}}]}))
	if not bool(chat_delta.get("success", false)) or chat_delta.get("text_delta", "") != "Hi":
		failures.append("Chat stream parser should normalize delta.content")
	var chat_part_delta := service.parse_stream_data("chat_completions", JSON.stringify({
		"choices": [{"delta": {"content": [{"type": "text", "text": "Hi parts"}]}}],
	}))
	if not bool(chat_part_delta.get("success", false)) or chat_part_delta.get("text_delta", "") != "Hi parts":
		failures.append("Chat stream parser should normalize delta content parts")
	var chat_tool_delta := service.parse_stream_data("chat_completions", JSON.stringify({
		"choices": [{"delta": {"tool_calls": [{"index": 0, "id": "chat_call", "function": {"name": "godex_mcp_context", "arguments": "{\"scope\""}}]}}],
	}))
	if chat_tool_delta.get("tool_call_deltas", []).size() != 1:
		failures.append("Chat stream parser should expose delta.tool_calls fragments")
	var chat_done := service.parse_stream_data("chat_completions", "[DONE]")
	if not bool(chat_done.get("completed", false)):
		failures.append("Chat stream parser should support DONE sentinel")
	var stream_error := service.parse_stream_data("responses", JSON.stringify({"error": {"type": "rate_limit", "message": "Slow down"}}))
	if bool(stream_error.get("success", true)) or stream_error.get("error", "") != "rate_limit":
		failures.append("stream parser should normalize error events")
	var residual_sse := service.parse_stream_residual("responses", "data: %s\n\ndata: %s" % [
		JSON.stringify({"type": "response.output_text.delta", "delta": "Residual"}),
		JSON.stringify({"type": "response.completed"}),
	])
	if not bool(residual_sse.get("success", false)) or residual_sse.get("mode", "") != "sse" or residual_sse.get("events", []).size() != 2:
		failures.append("stream residual parser should salvage trailing SSE data events")
	var residual_json := service.parse_stream_residual("responses", JSON.stringify({
		"output": [
			{"type": "message", "content": [{"type": "output_text", "text": "Residual JSON done."}]},
			{"type": "function_call", "call_id": "call_residual", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
		],
	}))
	if not bool(residual_json.get("success", false)) or residual_json.get("mode", "") != "json":
		failures.append("stream residual parser should accept a complete non-stream Responses JSON body")
	var residual_response: Dictionary = residual_json.get("response", {})
	if residual_response.get("text", "") != "Residual JSON done." or residual_response.get("tool_calls", []).size() != 1:
		failures.append("stream residual JSON parser should expose final text and tool calls")
	var residual_top_level_json := service.parse_stream_residual("responses", JSON.stringify({
		"id": "resp_residual_top_level",
		"output_text": "Residual top-level JSON done.",
	}))
	var residual_top_level_response: Dictionary = residual_top_level_json.get("response", {})
	if not bool(residual_top_level_json.get("success", false)) or residual_top_level_response.get("text", "") != "Residual top-level JSON done.":
		failures.append("stream residual JSON parser should expose top-level output_text fields")
	var residual_invalid := service.parse_stream_residual("responses", "not json")
	if bool(residual_invalid.get("success", true)):
		failures.append("stream residual parser should reject invalid non-SSE residual text")


func _check_provider_probe_contract(failures: Array[String]) -> void:
	var state := State.new()
	state.reasoning_effort = "high"
	var controller := DockController.new()
	controller.set("_state", state)
	var chat_payload: Dictionary = controller.call("_provider_probe_payload", "chat_completions", "gpt-5.4-mini")
	if chat_payload.get("model", "") != "gpt-5.4-mini" or not chat_payload.has("messages"):
		failures.append("provider probe should build a chat completions payload for OpenAI-compatible providers")
	if chat_payload.has("stream") or int(chat_payload.get("max_tokens", 0)) != 16:
		failures.append("provider probe should use a minimal non-stream chat completions request")
	if chat_payload.get("reasoning_effort", "") != "high":
		failures.append("provider probe should preserve the selected chat reasoning effort")
	var responses_payload: Dictionary = controller.call("_provider_probe_payload", "responses", "gpt-5.5")
	if responses_payload.get("model", "") != "gpt-5.5" or not responses_payload.has("input"):
		failures.append("provider probe should still support Responses-compatible payloads")
	if responses_payload.has("stream") or int(responses_payload.get("max_output_tokens", 0)) != 16:
		failures.append("provider probe should use a minimal non-stream Responses request")
	var probe_state := State.new()
	probe_state.set_model("gpt-5.5")
	var probe_agent := AgentService.new()
	probe_agent.setup(probe_state)
	var parsed: Dictionary = probe_agent.handle_model_http_result("chat_completions", 200, JSON.stringify({
		"choices": [{"message": {"content": "pong"}}],
	}), {"source": "provider_probe"})
	if not bool(parsed.get("success", false)) or parsed.get("text", "") != "pong":
		failures.append("provider probe HTTP result should reuse the normal OpenAI-compatible parser")
	var response_events := probe_state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "openai_response")
	if response_events.is_empty() or str(response_events[0].get("data", {}).get("source", "")) != "provider_probe":
		failures.append("provider probe response events should retain source metadata for diagnostics")
	var source_list := HBoxContainer.new()
	var sources_section := Control.new()
	controller.set("_source_list", source_list)
	controller.set("_sources_section", sources_section)
	controller.set("_state", probe_state)
	controller.call("_rebuild_sources", probe_state.to_model())
	if not probe_state.outputs.is_empty() or source_list.find_child("RightRailSourceChip", true, false) != null:
		failures.append("provider probe should not populate output artifacts or external tool source rows")
	source_list.free()
	sources_section.free()


func _check_provider_catalog(failures: Array[String]) -> void:
	var yuren := ProviderCatalog.get_provider("yurenapi")
	if yuren.get("name", "") != "Yuren OpenAI" or yuren.get("npm", "") != "@ai-sdk/openai-compatible":
		failures.append("yuren provider identity should match the preserved OpenAI-compatible preset")
	var yuren_options := yuren.get("options", {}) as Dictionary
	if yuren.get("base_url", "") != "https://yurenapi.cn/v1" or yuren_options.get("baseURL", "") != "https://yurenapi.cn/v1":
		failures.append("yuren provider should prefer the yurenapi.cn base URL")
	if not (yuren.get("alternate_base_urls", []) as Array).has("https://yurenapi.com/v1"):
		failures.append("yuren provider should preserve yurenapi.com as an alternate valid base URL")
	if yuren.get("api_key_env", "") != "YUREN_API_KEY" or yuren_options.get("apiKey", "") != "{env:YUREN_API_KEY}":
		failures.append("yuren provider API key source should use YUREN_API_KEY")
	if yuren.get("api_mode", "") != "chat_completions":
		failures.append("yuren provider should default to Chat Completions-compatible API mode")
	var yuren_models := ProviderCatalog.models_for("yurenapi")
	if yuren_models != ["gpt-5.4-mini", "gpt-5.4", "gpt-5.5"]:
		failures.append("yuren provider should expose the supported model order")
	var yuren_model_details := yuren.get("model_details", {}) as Dictionary
	for model_name in ["gpt-5.4-mini", "gpt-5.4", "gpt-5.5"]:
		var detail := yuren_model_details.get(model_name, {}) as Dictionary
		var limit := detail.get("limit", {}) as Dictionary
		var modalities := detail.get("modalities", {}) as Dictionary
		var variants := detail.get("variants", {}) as Dictionary
		if not bool(detail.get("attachment", false)) or not bool(detail.get("reasoning", false)):
			failures.append("yuren model %s should preserve attachment and reasoning support" % model_name)
		if int(limit.get("context", 0)) != 400000 or int(limit.get("input", 0)) != 272000 or int(limit.get("output", 0)) != 128000:
			failures.append("yuren model %s token limits should match the provider config" % model_name)
		if not (modalities.get("input", []) as Array).has("image") or not (modalities.get("input", []) as Array).has("pdf"):
			failures.append("yuren model %s should preserve image/pdf input modalities" % model_name)
		if str((variants.get("xhigh", {}) as Dictionary).get("reasoningEffort", "")) != "xhigh":
			failures.append("yuren model %s should preserve xhigh reasoning variant" % model_name)
	var state := State.new()
	state.set_provider("yurenapi")
	if state.base_url != "https://yurenapi.cn/v1" or state.api_key_env != "YUREN_API_KEY" or state.api_mode != "chat_completions":
		failures.append("state provider defaults should apply yuren settings")
	var default_settings_state := State.new()
	default_settings_state.apply_settings({
		"provider": "openai",
		"base_url": "https://api.openai.com",
		"api_key_env": "OPENAI_API_KEY",
		"api_key": "",
		"model": "gpt-5.5",
	})
	if default_settings_state.provider != "openai" or default_settings_state.base_url != "https://api.openai.com" or default_settings_state.api_key_env != "OPENAI_API_KEY" or default_settings_state.settings_migrated:
		failures.append("default empty OpenAI settings should not migrate to the Yuren provider")
	var explicit_yuren_state := State.new()
	explicit_yuren_state.apply_settings({
		"provider": "yurenapi",
		"base_url": "https://api.openai.com",
		"api_key_env": "OPENAI_API_KEY",
		"api_key": "",
		"model": "gpt-5.5",
		"api_mode": "responses",
	})
	if explicit_yuren_state.provider != "yurenapi" or explicit_yuren_state.base_url != "https://yurenapi.cn/v1" or explicit_yuren_state.api_key_env != "YUREN_API_KEY" or explicit_yuren_state.api_mode != "chat_completions" or not explicit_yuren_state.settings_migrated:
		failures.append("explicit yuren settings should normalize to the Yuren provider preset")
	var alternate_com_state := State.new()
	alternate_com_state.apply_settings({
		"provider": "yurenapi",
		"base_url": "https://yurenapi.com/v1",
		"api_key_env": "YUREN_API_KEY",
		"api_key": "",
		"model": "gpt-5.5",
		"api_mode": "chat_completions",
	})
	if alternate_com_state.provider != "yurenapi" or alternate_com_state.base_url != "https://yurenapi.com/v1" or alternate_com_state.settings_migrated:
		failures.append("explicit yurenapi.com settings should remain a valid persisted alternate base URL")
	if alternate_com_state.api_config_snapshot().get("endpoint", "") != "https://yurenapi.com/v1/chat/completions":
		failures.append("explicit yurenapi.com settings should use the Chat Completions endpoint")
	var stale_runtime_state := State.new()
	stale_runtime_state.provider = "yurenapi"
	stale_runtime_state.base_url = "https://yurenapi.cn/v1"
	stale_runtime_state.api_key_env = "YUREN_API_KEY"
	stale_runtime_state.model = "gpt-5.5"
	stale_runtime_state.api_mode = "responses"
	if not stale_runtime_state.normalize_runtime_provider():
		failures.append("runtime provider normalization should report stale Yuren API mode changes")
	if stale_runtime_state.api_mode != "chat_completions" or stale_runtime_state.api_config_snapshot().get("endpoint", "") != "https://yurenapi.cn/v1/chat/completions":
		failures.append("runtime provider normalization should prevent Yuren from falling back to Responses endpoint")
	var invalid_yuren_base_state := State.new()
	invalid_yuren_base_state.apply_settings({
		"provider": "yurenapi",
		"base_url": "https://api.openai.com",
		"api_key_env": "YUREN_API_KEY",
		"api_key": "",
		"model": "gpt-5.5",
		"api_mode": "responses",
	})
	if invalid_yuren_base_state.provider != "yurenapi" or invalid_yuren_base_state.base_url != "https://yurenapi.cn/v1" or invalid_yuren_base_state.api_mode != "chat_completions" or not invalid_yuren_base_state.settings_migrated:
		failures.append("invalid Yuren base URLs should fall back to the recommended yurenapi.cn base URL")
	var legacy_env_state := State.new()
	legacy_env_state.apply_settings({
		"provider": "openai",
		"base_url": "https://api.openai.com",
		"api_key_env": "YURENAPI_API_KEY",
		"api_key": "",
		"model": "gpt-5.5",
	})
	if legacy_env_state.provider != "yurenapi" or legacy_env_state.api_key_env != "YUREN_API_KEY":
		failures.append("legacy YURENAPI_API_KEY settings should normalize to YUREN_API_KEY and yurenapi")
	state.reasoning_effort = "xhigh"
	var snapshot := state.api_config_snapshot()
	if snapshot.get("reasoning_effort", "") != "xhigh" or snapshot.get("endpoint", "") != "https://yurenapi.cn/v1/chat/completions" or state.build_capability_summary()[0].get("detail", "").find("reasoning:xhigh") < 0:
		failures.append("state API config should expose selected reasoning effort")
	var ui_state := State.new()
	var ui_controller := DockController.new()
	var ui_root := Control.new()
	get_root().add_child(ui_root)
	var provider_option := OptionButton.new()
	provider_option.add_item("openai")
	provider_option.add_item("yurenapi")
	provider_option.select(1)
	ui_root.add_child(provider_option)
	var model_option := OptionButton.new()
	for model_name in ["gpt-5.4-mini", "gpt-5.4", "gpt-5.5"]:
		model_option.add_item(model_name)
	model_option.select(2)
	ui_root.add_child(model_option)
	var api_mode_option := OptionButton.new()
	api_mode_option.add_item("Responses API")
	api_mode_option.add_item("Chat Completions Compatible")
	api_mode_option.select(0)
	ui_root.add_child(api_mode_option)
	ui_controller.set("_state", ui_state)
	ui_controller.set("_provider", provider_option)
	var base_url_input := LineEdit.new()
	base_url_input.text = "https://yurenapi.cn/v1"
	var api_key_input := LineEdit.new()
	var api_key_env_input := LineEdit.new()
	api_key_env_input.text = "YUREN_API_KEY"
	var mcp_endpoint_input := LineEdit.new()
	var skills_toggle := CheckBox.new()
	var mcp_toggle := CheckBox.new()
	var compression_toggle := CheckBox.new()
	var command_toggle := CheckBox.new()
	var command_shell_input := LineEdit.new()
	for control in [base_url_input, api_key_input, api_key_env_input, mcp_endpoint_input, skills_toggle, mcp_toggle, compression_toggle, command_toggle, command_shell_input]:
		ui_root.add_child(control)
	ui_controller.set("_base_url", base_url_input)
	ui_controller.set("_api_key", api_key_input)
	ui_controller.set("_api_key_env", api_key_env_input)
	ui_controller.set("_model", model_option)
	ui_controller.set("_api_mode", api_mode_option)
	ui_controller.set("_mcp_endpoint", mcp_endpoint_input)
	ui_controller.set("_skills_enabled", skills_toggle)
	ui_controller.set("_mcp_enabled", mcp_toggle)
	ui_controller.set("_compression_enabled", compression_toggle)
	ui_controller.set("_command_enabled", command_toggle)
	ui_controller.set("_command_shell", command_shell_input)
	ui_controller.call("_apply_provider_fields_to_state")
	var ui_snapshot := ui_state.api_config_snapshot()
	if ui_state.provider != "yurenapi" or ui_state.api_mode != "chat_completions" or ui_snapshot.get("endpoint", "") != "https://yurenapi.cn/v1/chat/completions" or api_mode_option.selected != 1:
		failures.append("settings UI provider sync should not let a stale Responses API selector override the Yuren Chat Completions preset")
	ui_root.free()


func _check_context_compression(failures: Array[String]) -> void:
	var compressor := Compressor.new()
	if not compressor.should_compress(80, 100):
		failures.append("compression threshold invalid")
	if compressor.should_compress(80, 100, 0.90):
		failures.append("compression threshold should honor caller-provided ratios")
	var messages := []
	for i in range(40):
		messages.append({"role": "user", "content": "message %d" % i})
	var result := compressor.compress_messages(messages, 16)
	if not bool(result.get("compressed", false)):
		failures.append("messages should compress")
	if result.get("messages", []).size() > 16:
		failures.append("compressed message tail too large")


func _check_mcp_and_approval(failures: Array[String]) -> void:
	var mcp := McpClient.new()
	mcp.configure("http://127.0.0.1:3000/mcp")
	var request := mcp.build_tool_context_request("summary", 50)
	if request.get("endpoint", "") != "http://127.0.0.1:3000/mcp":
		failures.append("mcp endpoint not retained")
	if request.get("method", "") != "tools/call":
		failures.append("mcp method invalid")
	if request.get("tool", "") != "system_project_state":
		failures.append("mcp summary context should map to project state tool")
	if not bool(request.get("arguments", {}).get("summary", false)):
		failures.append("mcp summary context should request compact project summary")
	var scene_request := mcp.build_tool_context_request("scene", 80)
	var scene_sections: Array = scene_request.get("arguments", {}).get("sections", [])
	if scene_request.get("tool", "") != "system_project_state" or not scene_sections.has("files"):
		failures.append("mcp scene context should map to project-state sections instead of invalid editor-log scope")
	var scripts_request := mcp.build_tool_context_request("scripts", 120)
	var script_sections: Array = scripts_request.get("arguments", {}).get("sections", [])
	if scripts_request.get("tool", "") != "system_project_state" or not script_sections.has("files"):
		failures.append("mcp scripts context should map to project-state file sections")
	var logs_request := mcp.build_tool_context_request("logs", 25)
	if logs_request.get("tool", "") != "system_editor_log" or logs_request.get("arguments", {}).get("action", "") != "get_errors":
		failures.append("mcp logs context should call editor log with an explicit action")
	var runtime_request := mcp.build_tool_context_request("runtime", 20)
	if runtime_request.get("tool", "") != "system_runtime_diagnose" or not bool(runtime_request.get("arguments", {}).get("include_compile_errors", false)):
		failures.append("mcp runtime context should call runtime diagnose with explicit diagnostic flags")
	var call_request := mcp.build_tool_call_request("system_editor_log", {"limit": 10})
	if call_request.get("tool", "") != "system_editor_log" or call_request.get("arguments", {}).get("limit", 0) != 10:
		failures.append("mcp tool call request should retain tool name and arguments")
	if call_request.get("body", {}).get("method", "") != "tools/call" or call_request.get("body", {}).get("params", {}).get("name", "") != "system_editor_log":
		failures.append("mcp tool call request should include json-rpc body")
	var list_request := mcp.build_tools_list_request()
	if list_request.get("method", "") != "tools/list" or list_request.get("endpoint", "") != "http://127.0.0.1:3000/mcp":
		failures.append("mcp tools list request should target configured endpoint")
	if list_request.get("body", {}).get("method", "") != "tools/list" or list_request.get("body", {}).get("jsonrpc", "") != "2.0":
		failures.append("mcp tools list request should include json-rpc body")
	var parsed_tools := mcp.parse_tools_list_response(JSON.stringify({
		"result": {
			"tools": [
				{"name": "system_project_state", "description": "Read project state", "inputSchema": {"type": "object", "properties": {"summary": {"type": "boolean"}}, "required": ["summary"]}},
			],
		},
	}))
	if not bool(parsed_tools.get("success", false)) or parsed_tools.get("tools", []).size() != 1:
		failures.append("mcp tools list parser should extract tools")
	var long_paths: Array[String] = []
	for i in range(40):
		long_paths.append("res://Scripts/Generated/VeryLongPath_%d.gd" % i)
	var parsed_project_state := mcp.parse_tool_call_response(JSON.stringify({
		"result": {
			"content": [
				{"type": "text", "text": JSON.stringify({"success": true, "data": {"project_name": "Mechoes", "scripts": 418, "script_paths": long_paths}})},
			],
			"isError": false,
		},
	}))
	if not bool(parsed_project_state.get("success", false)):
		failures.append("mcp project-state parser should accept successful data payloads")
	if str(parsed_project_state.get("message", "")).find("script_paths") >= 0 or str(parsed_project_state.get("message", "")).find("VeryLongPath_39") >= 0:
		failures.append("mcp project-state parser should summarize large data instead of stringifying paths")
	if parsed_project_state.get("data", {}).get("data", {}).get("script_paths", []).size() != 40:
		failures.append("mcp project-state parser should retain full data for audit and continuation")
	var project_name_state := State.new()
	project_name_state.apply_project_summary(parsed_project_state.get("data", {}))
	if project_name_state.active_project != "Mechoes":
		failures.append("state should sync active project name from MCP project-state data")
	var project_path_state := State.new()
	project_path_state.active_project = "BeforePath"
	project_path_state.apply_project_summary({"project_path": "E:/Project/LuoxuanLove/Mechoes/"})
	if project_path_state.active_project != "Mechoes":
		failures.append("state should fall back to the project folder name when MCP only provides project_path")
	var grouped_tools := mcp.parse_tools_list_response(JSON.stringify({
		"result": {
			"toolGroups": [
				{"name": "system", "tools": [{"name": "system_help", "description": "Read help"}]},
			],
		},
	}))
	if not bool(grouped_tools.get("success", false)) or grouped_tools.get("tools", [])[0].get("group", "") != "system":
		failures.append("mcp tools list parser should extract grouped tools")
	var call_response := mcp.parse_tool_call_response(JSON.stringify({
		"result": {
			"content": [
				{"type": "text", "text": JSON.stringify({"data": {"error_count": 0}, "message": "ok", "success": true})},
			],
			"isError": false,
		},
	}))
	if not bool(call_response.get("success", false)) or call_response.get("data", {}).get("data", {}).get("error_count", -1) != 0:
		failures.append("mcp tool call parser should extract successful text payload data")
	var failed_call_response := mcp.parse_tool_call_response(JSON.stringify({
		"result": {
			"content": [
				{"type": "text", "text": JSON.stringify({"error": "bad_tool", "message": "Tool failed", "success": false})},
			],
			"isError": true,
		},
	}))
	if bool(failed_call_response.get("success", true)) or failed_call_response.get("error", "") != "bad_tool":
		failures.append("mcp tool call parser should normalize failed tool payloads")
	var approval := ApprovalPolicy.new()
	var checkpoint := approval.build_checkpoint("write_file", "Patch a file")
	if not bool(checkpoint.get("requires_approval", false)):
		failures.append("write_file must require approval")


func _check_git_change_summary_service(failures: Array[String]) -> void:
	var service := GitChangeSummaryService.new()
	var summary: Dictionary = service.build_summary({
		"status_porcelain": " M addons/godex/ui/godex_dock_controller.gd\nA  docs/new-note.md\nR  old_name.md -> docs/renamed.md\n?? docs/新文件.md\n",
		"numstat": "89\t7\taddons/godex/ui/godex_dock_controller.gd\n3\t0\tdocs/new-note.md\n0\t1\tdocs/renamed.md\n5\t0\tdocs/新文件.md\n-\t-\tassets/binary.png\n",
	})
	if int(summary.get("file_count", 0)) != 5 or int(summary.get("added", 0)) != 97 or int(summary.get("removed", 0)) != 8:
		failures.append("git change summary service should parse porcelain and numstat into aggregate deltas")
	var files: Array = summary.get("files", [])
	if files.is_empty() or str(files[0].get("path", "")).find("\\") >= 0:
		failures.append("git change summary service should normalize paths for UI rows")
	var state := State.new()
	var records := state.record_tool_calls([
		{"id": "change_summary", "name": "godex_change_review_summary", "arguments": summary},
	], "event_change_summary")
	if records.is_empty() or str(records[0].get("status", "")) != "completed":
		failures.append("change review summary tool should complete locally without pending approval")
	var review_preview: Dictionary = state.change_review_preview()
	if int(review_preview.get("file_count", 0)) != 5 or int(review_preview.get("added", 0)) != 97:
		failures.append("change review summary tool should feed persisted review strip state")
	if state.outputs.size() != 5:
		failures.append("change review summary tool should mirror changed files into output artifacts")
	else:
		var first_output: Dictionary = state.outputs[0]
		if str(first_output.get("kind", "")) != "文件" or str(first_output.get("source", "")) != "change_review":
			failures.append("right-inspector outputs should identify changed files as change-review artifacts")
	var sessions := state.to_sessions()
	var restored_state := State.new()
	restored_state.apply_sessions(sessions)
	if restored_state.outputs.size() != 5 or restored_state.change_review_preview().is_empty():
		failures.append("change review output artifacts should persist through session save/restore")
	var legacy_state := State.new()
	legacy_state.apply_sessions({
		"active_thread_id": state.active_thread_id,
		"sessions": state.threads,
		"approval_records": state.approval_records,
		"change_review_summary": review_preview,
	})
	if legacy_state.outputs.size() != 5:
		failures.append("legacy sessions without outputs should rebuild change-review output artifacts")
	restored_state.record_output_artifact({
		"title": "manual-note.md",
		"detail": "docs/manual-note.md",
		"path": "docs/manual-note.md",
		"kind": "文件",
		"source": "manual",
	})
	restored_state.clear_change_review_summary()
	if restored_state.outputs.size() != 1 or str(restored_state.outputs[0].get("source", "")) != "manual":
		failures.append("clearing change review should remove only change-review output artifacts")
	for event in state.active_model_events():
		if str(event.get("kind", "")) == "command_run":
			failures.append("change review summary tool must not create command-run events")
	if not state.latest_pending_approval().is_empty():
		failures.append("change review summary tool must not create command approval checkpoints")


func _check_agent_mcp_inspection(failures: Array[String]) -> void:
	var state := State.new()
	var agent := AgentService.new()
	agent.setup(state)
	var result := agent.inspect_mcp_connection()
	if not bool(result.get("success", false)):
		failures.append("agent MCP inspection should succeed for default endpoint")
	var mcp_context_events := state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "mcp_context")
	if mcp_context_events.is_empty():
		failures.append("agent MCP inspection should append an auditable mcp_context event")
	if not state.progress_items.is_empty() or not state.outputs.is_empty():
		failures.append("agent MCP inspection should not repopulate static right-inspector progress or outputs")
	var mcp_transcript_items := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "mcp_context")
	if not mcp_transcript_items.is_empty():
		failures.append("agent MCP inspection bookkeeping should stay out of chat transcript items")
	var discovery_request: Dictionary = agent.build_mcp_discovery_request()
	if not bool(discovery_request.get("success", false)) or discovery_request.get("request", {}).get("method", "") != "tools/list":
		failures.append("agent should build mcp tools/list request")
	if state.mcp_discovery_status != "request_ready":
		failures.append("agent mcp discovery request should update discovery status")
	var discovery_result: Dictionary = agent.handle_mcp_tools_list_response(JSON.stringify({
		"result": {
			"tools": [
				{"name": "system_editor_log", "description": "Read editor logs", "inputSchema": {"properties": {"limit": {"type": "integer"}}}},
			],
		},
	}))
	if not bool(discovery_result.get("success", false)) or state.mcp_discovered_tools.size() != 1:
		failures.append("agent should record discovered mcp tools")


func _check_state_capability_summary(failures: Array[String]) -> void:
	var state := State.new()
	var summary: Array = state.build_capability_summary()
	if summary.size() != 7:
		failures.append("state capability summary should expose seven capability rows")
	var api_snapshot: Dictionary = state.api_config_snapshot()
	if bool(api_snapshot.get("has_api_key", false)):
		failures.append("empty API config should not report an API key")
	var model_snapshot: Dictionary = state.to_model()
	var mcp_server_row: Dictionary = model_snapshot.get("mcp_server_row", {})
	var mcp_server_rows: Array = model_snapshot.get("mcp_server_rows", [])
	if str(mcp_server_row.get("id", "")) != "godot_dotnet_mcp" or str(mcp_server_row.get("transport", "")) != "streamable-http":
		failures.append("state model should expose Godot .NET MCP as a server row contract")
	if mcp_server_rows.size() != 1 or str(mcp_server_rows[0].get("endpoint", "")) != state.endpoint:
		failures.append("state model should expose a single MCP server row matching the persisted endpoint")
	state.apply_settings({"mcp_endpoint": "http://127.0.0.1:3999/mcp", "mcp_enabled": false})
	mcp_server_row = state.to_model().get("mcp_server_row", {})
	if str(mcp_server_row.get("endpoint", "")) != "http://127.0.0.1:3999/mcp" or bool(mcp_server_row.get("enabled", true)) or str(mcp_server_row.get("status", "")) != "disabled":
		failures.append("MCP server row should follow persisted endpoint and enabled state")
	state.apply_settings({"mcp_endpoint": State.DEFAULT_MCP_ENDPOINT, "mcp_enabled": true})
	state.api_key = "sk-local-test-token"
	api_snapshot = state.api_config_snapshot()
	if not bool(api_snapshot.get("has_api_key", false)) or api_snapshot.get("key_source", "") != "inline":
		failures.append("inline API key should be visible in config snapshot")
	state.command_enabled = true
	state.command_shell = "pwsh"
	var command_row: Dictionary = state.build_capability_summary()[3]
	if not bool(command_row.get("enabled", false)) or not str(command_row.get("detail", "")).contains("pwsh"):
		failures.append("command capability summary should reflect enabled shell")
	state.record_command_run({
		"id": "command_summary",
		"command": "pwd",
		"shell": "pwsh",
		"working_directory": "res://",
		"timeout_sec": 33,
	}, "queued")
	state.request_command_run_approval("command_summary")
	var command_approval_summary: Dictionary = state.pending_command_approval_summary()
	if str(command_approval_summary.get("detail", "")).find("Timeout: 33s") < 0 or str(command_approval_summary.get("command_id", "")) != "command_summary":
		failures.append("pending command approval summary should expose command contract fields")
	var approval_rows: Array = state.approval_summary_rows()
	var command_row_detail := ""
	for approval_row in approval_rows:
		if str(approval_row.get("title", "")).find("command_summary") >= 0:
			command_row_detail = str(approval_row.get("detail", ""))
	if command_row_detail.find("Shell: pwsh") < 0 or command_row_detail.find("Timeout: 33s") < 0:
		failures.append("approval summary rows should expose command approval shell/cwd/timeout")
	var command_run_rows: Array = state.command_run_summary_rows()
	if command_run_rows.is_empty() or str(command_run_rows[0].get("detail", "")).find("Command: pwd") < 0:
		failures.append("command run summary rows should expose command run state without empty endpoint/model fields")
	var discovery := state.record_mcp_discovery({
		"success": true,
		"tools": [
			{"name": "system_project_state", "description": "Read project state", "input_schema": {"properties": {"summary": {"type": "boolean"}}, "required": ["summary"]}},
		],
	})
	if str(discovery.get("status", "")) != "ready" or state.mcp_tool_summary_rows().is_empty():
		failures.append("mcp discovery should cache summary rows")
	state.update_mcp_discovery_status("request_sent")
	if state.mcp_discovery_status != "request_sent":
		failures.append("mcp discovery status updates should be retained")


func _check_session_state(failures: Array[String]) -> void:
	var state := State.new()
	if not state.active_messages().is_empty():
		failures.append("default new-chat session should start with an empty transcript")
	state.new_session()
	if not state.active_messages().is_empty():
		failures.append("new sessions should not inject assistant readiness messages into chat")
	state.append_message("assistant", "新对话已准备好。")
	state.append_message("assistant", "已归档会话：新对话。")
	state.append_message("assistant", "已创建会话分支：新对话 分支。")
	state.append_message("assistant", "已添加文件上下文：addons/godex/ui/godex_dock_controller.gd。")
	state.append_message("user", "/archive")
	if not state.active_messages().is_empty():
		failures.append("legacy local session-management messages should be filtered out of active chat text")
	state.append_message("user", "search target")
	var results := state.search_records("target")
	if results.is_empty():
		failures.append("session search should find messages")
	var renamed := state.rename_active_session("Renamed Session")
	if str(renamed.get("title", "")) != "Renamed Session":
		failures.append("session rename should update active title")
	var queued_one: Dictionary = state.queue_user_message(" queued one ", "test")
	var queued_two: Dictionary = state.queue_user_message("queued two", "test")
	var next_queued: Dictionary = state.next_queued_user_message()
	if str(next_queued.get("id", "")) != str(queued_one.get("id", "")):
		failures.append("queued user messages should expose the oldest queued record first")
	var submitted_queued: Dictionary = state.mark_queued_user_message_submitted(str(queued_one.get("id", "")), "turn_test")
	if str(submitted_queued.get("status", "")) != "submitted" or str(submitted_queued.get("submitted_turn_id", "")) != "turn_test":
		failures.append("queued user messages should support submitted status and turn attribution")
	next_queued = state.next_queued_user_message()
	if str(next_queued.get("id", "")) != str(queued_two.get("id", "")):
		failures.append("submitted queued user messages should be skipped when selecting the next queued record")
	var cancelled_queued: Dictionary = state.cancel_queued_user_message(str(queued_two.get("id", "")), "test")
	if str(cancelled_queued.get("status", "")) != "cancelled" or str(cancelled_queued.get("cancelled_by", "")) != "test":
		failures.append("queued user messages should support cancellation with source attribution")
	if not state.next_queued_user_message().is_empty():
		failures.append("cancelled queued user messages should be skipped when selecting the next queued record")
	var queued_transcript := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "queued_user_message" and str(item.get("submitted_turn_id", "")) == "turn_test")
	if not queued_transcript.is_empty():
		failures.append("queued user message bookkeeping should stay out of chat transcript items")
	var rename_by_id_state := State.new()
	rename_by_id_state.apply_sessions({
		"active_thread_id": "active_thread",
		"sessions": [
			{"id": "target_thread", "title": "Target", "status": "idle", "age": "1m", "action": "open", "archived": false, "pinned": false, "messages": []},
			{"id": "active_thread", "title": "Active", "status": "active", "age": "now", "action": "chat", "archived": false, "pinned": false, "messages": []},
		],
		"approval_records": [],
	})
	var renamed_by_id := rename_by_id_state.rename_session("target_thread", "Renamed By Id")
	if str(renamed_by_id.get("title", "")) != "Renamed By Id" or str(rename_by_id_state.active_thread).find("Renamed By Id") >= 0:
		failures.append("session rename by id should update the target session without implicitly changing the active thread")
	if str(rename_by_id_state.select_thread("target_thread").get("title", "")) != "Renamed By Id":
		failures.append("session rename by id should persist on the stored target session")
	rename_by_id_state.select_thread("active_thread")
	var pinned_by_id := rename_by_id_state.toggle_pin_session("target_thread")
	if not bool(pinned_by_id.get("pinned", false)) or bool(rename_by_id_state.select_thread("active_thread").get("pinned", false)):
		failures.append("session pin by id should update the target session without pinning the active thread")
	if not bool(rename_by_id_state.select_thread("target_thread").get("pinned", false)):
		failures.append("session pin by id should persist on the stored target session")
	rename_by_id_state.select_thread("active_thread")
	var pinned := state.toggle_pin_active_session()
	if not bool(pinned.get("pinned", false)):
		failures.append("session pin should toggle pinned state")
	var slash_goal: Dictionary = state.execute_slash_command("/goal verify sessions")
	if not bool(slash_goal.get("handled", false)) or not state.goal_tracking_enabled:
		failures.append("slash goal should be handled locally and enable goal tracking")
	var active_goal: Dictionary = state.active_goal_record()
	if str(active_goal.get("objective", "")) != "verify sessions" or str(active_goal.get("status", "")) != "active" or not bool(active_goal.get("visible", false)):
		failures.append("slash goal should store a session-scoped active goal record")
	var restored_goal_state := State.new()
	restored_goal_state.apply_sessions(state.to_sessions())
	var restored_goal: Dictionary = restored_goal_state.active_goal_record()
	if str(restored_goal.get("objective", "")) != "verify sessions" or not restored_goal_state.goal_tracking_enabled:
		failures.append("session persistence should restore the active goal record")
	var slash_goal_pause: Dictionary = state.execute_slash_command("/goal pause")
	if not bool(slash_goal_pause.get("handled", false)) or state.goal_tracking_enabled or str(state.active_goal_record().get("status", "")) != "paused":
		failures.append("slash goal pause should preserve the goal while disabling active injection")
	var slash_goal_resume: Dictionary = state.execute_slash_command("/goal resume")
	if not bool(slash_goal_resume.get("handled", false)) or not state.goal_tracking_enabled or str(state.active_goal_record().get("status", "")) != "active":
		failures.append("slash goal resume should reactivate the stored goal")
	var slash_goal_clear: Dictionary = state.execute_slash_command("/goal off")
	if not bool(slash_goal_clear.get("handled", false)) or state.goal_tracking_enabled or bool(state.active_goal_record().get("visible", true)):
		failures.append("slash goal off should clear the visible active goal")
	var subagent_task := state.record_subagent_task({
		"id": "agent_session_test",
		"name": "Session Scout",
		"role": "explorer",
		"branch": "readonly/session",
		"summary": "inspect session state",
		"source": "subagent",
		"agent_kind": "subagent",
	})
	if subagent_task.is_empty() or state.active_subagent_tasks().is_empty():
		failures.append("subagent tasks should be recorded on the active session")
	var legacy_subagent_session := State.new()
	legacy_subagent_session.threads[0]["subagent_tasks"] = [{
		"id": "agent_legacy_context_probe",
		"name": "项目上下文调查",
		"role": "explorer",
		"branch": "readonly/context",
		"status": "running",
		"summary": "legacy task without child agent source",
	}]
	if not legacy_subagent_session.active_subagent_tasks().is_empty():
		failures.append("legacy context probe rows without child-agent source should not appear as subagents")
	legacy_subagent_session.threads[0]["subagent_tasks"] = [{
		"id": "agent_legacy_marked_context_probe",
		"name": "项目上下文调查",
		"role": "explorer",
		"branch": "readonly/context",
		"status": "running",
		"summary": "legacy task incorrectly marked by an older build",
		"source": "manual_subagent",
		"agent_kind": "subagent",
	}]
	if not legacy_subagent_session.active_subagent_tasks().is_empty():
		failures.append("legacy manual context probes marked by older builds should still stay out of subagents")
	legacy_subagent_session.threads[0]["subagent_tasks"] = [{
		"id": "agent_legacy_smoke_context_probe",
		"name": "项目上下文调查",
		"role": "explorer",
		"branch": "readonly/context",
		"status": "running",
		"summary": "legacy task from non-delegated test/probe source",
		"source": "smoke",
		"agent_kind": "subagent",
	}]
	if not legacy_subagent_session.active_subagent_tasks().is_empty():
		failures.append("legacy non-delegated context probes should stay out of subagents even when marked subagent")
	var updated_subagent := state.update_subagent_task("agent_session_test", "done", {"result": "session ok"})
	if str(updated_subagent.get("status", "")) != "done" or str(updated_subagent.get("result", "")) != "session ok":
		failures.append("subagent tasks should support status/result updates")
	var handed_off_subagent := state.handoff_subagent_task_result("agent_session_test", "session result handed off", "smoke")
	if str(handed_off_subagent.get("handoff_status", "")) != "handed_off" or str(handed_off_subagent.get("handoff_summary", "")) != "session result handed off":
		failures.append("subagent tasks should record result handoff metadata")
	var cancellable_subagent := state.record_subagent_task({
		"id": "agent_cancel_test",
		"name": "Cancel Scout",
		"role": "explorer",
		"branch": "readonly/cancel",
		"status": "running",
		"summary": "inspect cancellation",
		"source": "subagent",
		"agent_kind": "subagent",
	})
	var cancelled_subagent := state.cancel_subagent_task("agent_cancel_test", "smoke")
	if cancellable_subagent.is_empty() or str(cancelled_subagent.get("status", "")) != "cancelled" or str(cancelled_subagent.get("cancelled_by", "")) != "smoke":
		failures.append("subagent tasks should support cancellable lifecycle transitions")
	var notification_task := state.record_subagent_task({
		"id": "agent_notify_test",
		"name": "Notify Scout",
		"role": "explorer",
		"branch": "readonly/notify",
		"status": "running",
		"summary": "await notification",
		"source": "subagent",
		"agent_kind": "subagent",
	})
	var completed_notification := state.record_subagent_notification({
		"task_id": "agent_notify_test",
		"child_thread_id": "thread_child_notify",
		"name": "Notify Scout",
		"status": "completed",
		"summary": "notification summary",
		"result": "notification result",
		"usage": {"tokens": 12},
		"source": "smoke",
	})
	var notified_task: Dictionary = state.next_handoffable_subagent_task()
	if notification_task.is_empty() or completed_notification.is_empty() or str(notified_task.get("id", "")) != "agent_notify_test" or str(notified_task.get("status", "")) != "done" or str(notified_task.get("result", "")) != "notification result":
		failures.append("subagent completed notifications should update the matching task and make it handoff-ready")
	var open_notification := state.record_subagent_notification({
		"task_id": "agent_open_test",
		"child_thread_id": "thread_child_open",
		"name": "Open Scout",
		"status": "running",
		"summary": "open child",
		"source": "smoke",
	})
	var grandchild_edge := state.upsert_subagent_edge("thread_child_open", "thread_grandchild", "agent_grandchild", "open")
	var closed_children := JSON.stringify(state.subagent_children(state.active_thread_id, "closed"))
	var open_descendants := JSON.stringify(state.subagent_descendants(state.active_thread_id, "open"))
	if open_notification.is_empty() or grandchild_edge.is_empty() or closed_children.find("thread_child_notify") < 0:
		failures.append("subagent notifications should create closed parent-child edges")
	if open_descendants.find("thread_child_open") < 0 or open_descendants.find("thread_grandchild") < 0 or open_descendants.find("thread_child_notify") >= 0:
		failures.append("subagent descendant queries should traverse filtered open edges without including closed workers")
	var child_session_run := state.start_subagent_child_session({
		"id": "agent_child_session",
		"name": "Child Session Scout",
		"role": "explorer",
		"branch": "child-session/local-replay",
		"prompt": "Return a tiny child-session result.",
	})
	var child_thread_id := str(child_session_run.get("child_thread_id", ""))
	var child_task: Dictionary = child_session_run.get("task", {})
	var child_session := state.select_thread(child_thread_id)
	var child_messages := state.active_messages()
	state.select_thread(str(child_task.get("parent_thread_id", "quick_chat")))
	var completed_child_session := state.complete_subagent_child_session("agent_child_session", "child session ok", "child summary", "smoke")
	var child_task_after: Dictionary = state.next_handoffable_subagent_task()
	var child_edges := JSON.stringify(state.subagent_children(state.active_thread_id, "closed"))
	if child_session_run.is_empty() or child_session.is_empty() or child_messages.size() < 2 or str(child_task.get("status", "")) != "running":
		failures.append("subagent child sessions should create a child thread with prompt messages and a running parent task")
	if completed_child_session.is_empty() or str(child_task_after.get("id", "")) != "agent_child_session" or str(child_task_after.get("status", "")) != "done" or child_edges.find(child_thread_id) < 0:
		failures.append("subagent child session completion should notify the parent task and close the child edge")
	var killed_task := state.record_subagent_task({
		"id": "agent_killed_test",
		"name": "Killed Scout",
		"role": "explorer",
		"branch": "readonly/killed",
		"status": "running",
		"source": "subagent",
		"agent_kind": "subagent",
	})
	var killed_notification := state.record_subagent_notification({
		"task_id": "agent_killed_test",
		"name": "Killed Scout",
		"status": "killed",
		"error": "worker stopped",
		"source": "smoke",
	})
	var killed_rows := JSON.stringify(state.subagent_summary_rows(8))
	if killed_task.is_empty() or killed_notification.is_empty() or killed_rows.find("Killed Scout") < 0 or killed_rows.find("worker stopped") < 0:
		failures.append("subagent killed notifications should cancel/update the matching task")
	var notification_transcript := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "subagent_notification" and str(item.get("task_id", "")) == "agent_notify_test")
	if not notification_transcript.is_empty():
		failures.append("subagent notification bookkeeping should stay out of chat transcript items")
	var restored_subagent_state := State.new()
	restored_subagent_state.apply_sessions(state.to_sessions())
	if restored_subagent_state.active_subagent_tasks().is_empty() or str(restored_subagent_state.active_subagent_tasks()[0].get("id", "")) != "agent_session_test":
		failures.append("session persistence should restore subagent tasks")
	var restored_subagent_rows := JSON.stringify(restored_subagent_state.subagent_summary_rows(6))
	if restored_subagent_rows.find("结果已交接") < 0 or restored_subagent_rows.find("取消来源: smoke") < 0:
		failures.append("session persistence should restore subagent handoff and cancellation summaries")
	var restored_notification_rows := JSON.stringify(restored_subagent_state.subagent_notification_summary_rows(6))
	if restored_notification_rows.find("Notify Scout") < 0 or restored_notification_rows.find("thread_child_notify") < 0 or restored_notification_rows.find("Killed Scout") < 0:
		failures.append("session persistence should restore subagent worker notifications")
	var restored_edge_rows := JSON.stringify(restored_subagent_state.subagent_edge_summary_rows(6))
	var restored_open_descendants := JSON.stringify(restored_subagent_state.subagent_descendants(restored_subagent_state.active_thread_id, "open"))
	if restored_edge_rows.find("thread_child_notify") < 0 or restored_edge_rows.find("thread_child_open") < 0 or restored_open_descendants.find("thread_grandchild") < 0:
		failures.append("session persistence should restore subagent edge topology")
	var slash_ide_off: Dictionary = state.execute_slash_command("/ide off")
	if not bool(slash_ide_off.get("handled", false)) or state.ide_context_enabled:
		failures.append("slash ide off should hide IDE context")
	var slash_ide_on: Dictionary = state.execute_slash_command("/ide on")
	if not bool(slash_ide_on.get("handled", false)) or not state.ide_context_enabled:
		failures.append("slash ide on should restore IDE context")
	var slash_rename: Dictionary = state.execute_slash_command("/rename Slash Session")
	if not bool(slash_rename.get("success", false)) or str(state.active_thread).find("Slash Session") < 0:
		failures.append("slash rename should rename active session")
	if JSON.stringify(state.active_messages()).find("Slash Session") >= 0:
		failures.append("slash rename should not append a chat transcript status message")
	var slash_pin: Dictionary = state.execute_slash_command("/pin")
	if not bool(slash_pin.get("success", false)) or bool(state._active_session().get("pinned", false)):
		failures.append("slash pin should toggle active session pin")
	if JSON.stringify(state.active_messages()).find("已置顶") >= 0 or JSON.stringify(state.active_messages()).find("已取消置顶") >= 0:
		failures.append("slash pin should not append a chat transcript status message")
	var slash_help: Dictionary = state.execute_slash_command("/help")
	if not bool(slash_help.get("success", false)) or str(slash_help.get("message", "")).find("/side") < 0 or str(slash_help.get("message", "")).find("/status") < 0 or str(slash_help.get("message", "")).find("/mcp") < 0:
		failures.append("slash help should describe local commands")
	var slash_status: Dictionary = state.execute_slash_command("/status")
	if not bool(slash_status.get("success", false)) or str(slash_status.get("message", "")).find("会话：") < 0 or str(slash_status.get("message", "")).find("上下文：") < 0:
		failures.append("slash status should expose a Codex-style session/context status summary")
	var slash_mcp: Dictionary = state.execute_slash_command("/mcp")
	if not bool(slash_mcp.get("success", false)) or str(slash_mcp.get("data", {}).get("view", "")) != "mcp":
		failures.append("slash mcp should open the MCP status view instead of using the plugins nav")
	var slash_suggestions := state.slash_command_suggestions("/re", 4)
	var found_resume_suggestion := false
	for suggestion in slash_suggestions:
		if str(suggestion.get("command", "")) == "/resume":
			found_resume_suggestion = true
			if not suggestion.has("icon") or str(suggestion.get("title", "")) != "恢复会话" or str(suggestion.get("detail", "")).find("搜索") < 0:
				failures.append("slash suggestions should expose Codex-style action-list title/detail/icon metadata")
	if not found_resume_suggestion:
		failures.append("slash suggestions should filter commands by typed prefix")
	var alias_suggestions := state.slash_command_suggestions("/open", 4)
	if alias_suggestions.is_empty() or str(alias_suggestions[0].get("command", "")) != "/resume":
		failures.append("slash suggestions should match command aliases")
	var ide_suggestions := state.slash_command_suggestions("/ide", 12)
	var found_ide_suggestion := false
	for suggestion in ide_suggestions:
		if str(suggestion.get("command", "")) == "/ide":
			found_ide_suggestion = true
	if not found_ide_suggestion:
		failures.append("slash suggestions should expose IDE context toggle")
	var mcp_suggestions := state.slash_command_suggestions("/mcp", 4)
	if mcp_suggestions.is_empty() or str(mcp_suggestions[0].get("command", "")) != "/mcp":
		failures.append("slash suggestions should expose MCP server status command")
	var status_suggestions := state.slash_command_suggestions("/st", 4)
	if status_suggestions.is_empty() or str(status_suggestions[0].get("command", "")) != "/status":
		failures.append("slash suggestions should expose the Codex-style status command")
	var side_suggestions := state.slash_command_suggestions("/side", 4)
	if side_suggestions.is_empty() or str(side_suggestions[0].get("command", "")) != "/side":
		failures.append("slash suggestions should expose the side/branch command")
	var slash_unknown: Dictionary = state.execute_slash_command("/does-not-exist")
	if bool(slash_unknown.get("handled", true)):
		failures.append("unknown slash command should remain unhandled")
	for i in range(32):
		state.append_message("user", "compact target %d" % i)
	var slash_compact: Dictionary = state.execute_slash_command("/compact")
	if not bool(slash_compact.get("success", false)):
		failures.append("slash compact should compact long active session")
	var last_compaction: Dictionary = state.last_compaction_preview()
	if str(last_compaction.get("source", "")) != "slash_command" or int(last_compaction.get("removed_count", 0)) <= 0:
		failures.append("slash compact should publish a last compaction summary")
	if state.compaction_history_preview().is_empty():
		failures.append("slash compact should publish a compaction history entry")
	state.context_budget = 100
	state.context_used = 65
	var warning: Dictionary = state.context_window_warning()
	if str(warning.get("status", "")) != "warning" or int(warning.get("tokens_until_auto_compact", -1)) != 7:
		failures.append("context window warning should expose tokens remaining before auto compaction")
	var compact_transcript := state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "session_compaction" and str(item.get("source", "")) == "slash_command")
	if not compact_transcript.is_empty():
		failures.append("session compaction bookkeeping should stay out of chat transcript items")
	var compression_detail := ""
	for summary in state.build_capability_summary():
		if str(summary.get("title", "")) == "自动上下文压缩":
			compression_detail = str(summary.get("detail", ""))
	if compression_detail.find("上次压缩") < 0 or compression_detail.find("接近自动压缩阈值") < 0:
		failures.append("capability summary should expose latest context compaction and warning details")
	var resumed := state.execute_slash_command("/resume Slash")
	if not bool(resumed.get("success", false)):
		failures.append("slash resume should find sessions by title")
	if JSON.stringify(state.active_messages()).find("已恢复会话") >= 0:
		failures.append("slash resume should not append a chat transcript status message")
	var fork := state.fork_active_session()
	if fork.is_empty() or str(fork.get("title", "")).find("分支") < 0:
		failures.append("session fork should create a branch title")
	if JSON.stringify(state.active_messages()).find("已创建会话分支") >= 0:
		failures.append("session fork should not append a chat transcript status message")
	var archived := state.archive_active_session()
	if archived.is_empty() or not bool(archived.get("archived", false)):
		failures.append("session archive should mark active session archived")
	if JSON.stringify(state.active_messages()).find("已归档会话") >= 0:
		failures.append("session archive should not append a chat transcript status message")
	var archived_records: Array = state.archived_records("Slash")
	if archived_records.is_empty():
		failures.append("archived records should list archived sessions separately from normal search")
	var normal_search_after_archive := state.search_records("Slash")
	for row in normal_search_after_archive:
		if str(row.get("id", "")) == str(archived.get("id", "")):
			failures.append("normal session search should keep archived sessions hidden")
	var restored := state.restore_archived_session(str(archived.get("id", "")))
	if restored.is_empty() or bool(restored.get("archived", true)) or state.active_thread_id != str(archived.get("id", "")):
		failures.append("restoring an archived session should unarchive and activate it")
	state.call("select_thread", str(restored.get("id", "")))
	var archived_for_delete := state.archive_active_session()
	var deleted_archived := state.delete_archived_session(str(archived_for_delete.get("id", "")))
	if deleted_archived.is_empty() or not state.archived_records("Slash").is_empty():
		failures.append("deleting an archived session should remove it from archived records")
	var checkpoint := {"action": "write_file", "summary": "Patch file", "risk": "medium", "requires_approval": true}
	state.record_approval_checkpoint(checkpoint)
	if state.latest_pending_approval().is_empty():
		failures.append("approval checkpoint should remain pending")
	var decision := state.decide_latest_approval("approve")
	if str(decision.get("status", "")) != "approved":
		failures.append("approval decision should mark checkpoint approved")
	var snapshot := state.to_sessions()
	if snapshot.get("approval_records", []).is_empty():
		failures.append("session snapshot should include approval records")
	state.set_change_review_summary({
		"files": [
			{"path": "addons/godex/ui/godex_dock_controller.gd", "added": 89, "removed": 7},
			{"path": "docs/超长路径/变更审查记录.md", "added": 1000, "removed": 0},
			{"path": "CHANGELOG.md", "added": 3, "removed": 1},
			{"path": "docs/architecture.md", "added": 4, "removed": 0},
			{"path": "docs/codex-feature-gap.md", "added": 2, "removed": 0},
			{"path": "docs/development-retrospective.md", "added": 5, "removed": 0},
			{"path": "docs/references/codex-desktop-ux.md", "added": 1, "removed": 0},
		],
		"title": "文件已更改",
	})
	state.set_change_review_expanded(true)
	var review_preview := state.change_review_preview()
	if int(review_preview.get("file_count", 0)) != 7 or int(review_preview.get("added", 0)) != 1104 or int(review_preview.get("removed", 0)) != 8:
		failures.append("change review summary should aggregate file count and line deltas")
	if not bool(review_preview.get("expanded", false)) or int(review_preview.get("hidden_file_count", 0)) != 1:
		failures.append("change review preview should retain expanded state and crop long file lists")
	var review_state := State.new()
	review_state.apply_sessions({"active_thread_id": state.active_thread_id, "sessions": state.threads, "change_review_summary": review_preview})
	if review_state.change_review_preview().is_empty():
		failures.append("session restore should keep change review summary")
	var event := state.append_model_event("openai_response", {
		"status": "ok",
		"endpoint": "https://api.openai.com/v1/responses",
		"model": "gpt-5.5",
		"headers": RequestBuilder.build_headers("sk-secret-token"),
		"raw": {"should": "drop"},
	})
	if event.is_empty() or state.active_model_events().is_empty():
		failures.append("model events should append to active session")
	var event_data: Dictionary = event.get("data", {})
	if str(event_data.get("raw", "")) != "" or Array(event_data.get("headers", [])).has("Authorization: Bearer sk-secret-token"):
		failures.append("model event data should redact raw payloads and bearer headers")
	if state.model_event_summary_rows().is_empty():
		failures.append("model event summary rows should be available")
	var tool_records: Array = state.record_tool_calls([
		{"id": "tool_call_1", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
	], str(event.get("id", "")))
	if tool_records.size() != 1 or state.pending_tool_calls().size() != 1:
		failures.append("tool calls should be recorded as pending model events")
	var tool_decision := state.decide_tool_call("tool_call_1", "approve")
	if str(tool_decision.get("status", "")) != "approved" or not state.pending_tool_calls().is_empty():
		failures.append("tool call decision should resolve pending state")
	var updated := state.update_tool_call_status("tool_call_1", "dispatch_ready", {"event_id": "event_1"})
	if str(updated.get("status", "")) != "dispatch_ready" or str(updated.get("result", {}).get("event_id", "")) != "event_1":
		failures.append("tool call status update should retain dispatch result metadata")
	var context_coalesce_state := State.new()
	context_coalesce_state.begin_agent_loop("test_context_cycle_guard")
	var context_coalesce_event := context_coalesce_state.append_model_event("openai_response", {"status": "ok"})
	var context_coalesce_records := context_coalesce_state.record_tool_calls([
		{"id": "context_summary", "name": "godex_mcp_context", "arguments": {"scope": "summary", "limit": 50}},
		{"id": "context_scene", "name": "godex_mcp_context", "arguments": {"scope": "scene", "limit": 80}},
		{"id": "context_scripts", "name": "godex_mcp_context", "arguments": {"scope": "scripts", "limit": 120}},
		{"id": "context_logs", "name": "godex_mcp_context", "arguments": {"scope": "logs", "limit": 120}},
	], str(context_coalesce_event.get("id", "")))
	if context_coalesce_records.size() != 1 or context_coalesce_state.pending_tool_calls().size() != 1:
		failures.append("same model response should coalesce repeated godex_mcp_context requests into one pending tool call")
	elif str(context_coalesce_records[0].get("arguments", {}).get("scope", "")) != "summary":
		failures.append("coalesced godex_mcp_context should keep the canonical summary request")
	context_coalesce_state.update_tool_call_status(str(context_coalesce_records[0].get("id", "")), "succeeded", {"message": "ok"})
	var repeated_context_records := context_coalesce_state.record_tool_calls([
		{"id": "context_summary_again", "name": "godex_mcp_context", "arguments": {"scope": "summary", "limit": 50}},
	], str(context_coalesce_event.get("id", "")))
	var cycle_blocks := context_coalesce_state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "tool_call_cycle_blocked")
	if repeated_context_records.size() != 0 or context_coalesce_state.pending_tool_calls().size() != 0 or cycle_blocks.size() != 1:
		failures.append("same-turn repeated completed tool calls should be blocked instead of creating another pending call")
	var row_reuse_state := State.new()
	var row_event := row_reuse_state.append_model_event("openai_response", {"status": "ok"})
	row_reuse_state.update_partial_tool_call({
		"id": "tool_row_reuse",
		"name": "godex_mcp_context",
		"arguments": "{\"scope\":\"summary\"}",
		"status": "streaming",
	})
	row_reuse_state.record_tool_calls([
		{"id": "tool_row_reuse", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
	], str(row_event.get("id", "")))
	row_reuse_state.update_tool_call_status("tool_row_reuse", "executing")
	row_reuse_state.update_tool_call_status("tool_row_reuse", "failed", {"message": "boom"})
	var projected_tool_rows := row_reuse_state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "tool_batch")
	var projected_partial_rows := row_reuse_state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "partial_tool_call" and str(item.get("tool_call_id", "")) == "tool_row_reuse")
	if projected_tool_rows.size() != 1 or str(projected_tool_rows[0].get("status", "")) != "failed" or int(projected_tool_rows[0].get("tool_count", 0)) != 1 or not projected_partial_rows.is_empty():
		failures.append("running and failed states for the same tool call should update one transcript batch row in place")
	var batch_state := State.new()
	var batch_event := batch_state.append_model_event("openai_response", {"status": "ok"})
	batch_state.record_tool_calls([
		{"id": "tool_batch_1", "name": "godex_mcp_context", "arguments": {"scope": "summary"}},
		{"id": "tool_batch_2", "name": "godex_read_file", "arguments": {"path": "a.gd"}},
		{"id": "tool_batch_3", "name": "godex_read_file", "arguments": {"path": "b.gd"}},
	], str(batch_event.get("id", "")))
	batch_state.update_tool_call_status("tool_batch_1", "completed", {"message": "ok"})
	batch_state.update_tool_call_status("tool_batch_2", "completed", {"message": "ok"})
	batch_state.update_tool_call_status("tool_batch_3", "failed", {"message": "boom"})
	var batch_rows := batch_state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "tool_batch")
	if batch_rows.size() != 1 or int(batch_rows[0].get("tool_count", 0)) != 3 or str(batch_rows[0].get("status", "")) != "failed":
		failures.append("same-turn tool calls should render as one Codex-style expandable batch row")
	var source_batch_state := State.new()
	source_batch_state.begin_agent_loop("test_source_batches")
	var source_batch_turn_id := str(source_batch_state.get("active_turn_id"))
	source_batch_state.append_message("user", "group by source events", {"turn_id": source_batch_turn_id})
	var source_event_a := source_batch_state.append_model_event("openai_response", {"status": "ok", "sample": "a"})
	source_batch_state.record_tool_calls([
		{"id": "source_batch_a_1", "name": "godex_mcp_context", "arguments": {"scope": "summary"}},
		{"id": "source_batch_a_2", "name": "godex_read_file", "arguments": {"path": "res://project.godot"}},
	], str(source_event_a.get("id", "")))
	var source_event_b := source_batch_state.append_model_event("openai_response", {"status": "ok", "sample": "b"})
	source_batch_state.record_tool_calls([
		{"id": "source_batch_b_1", "name": "godex_mcp_context", "arguments": {"scope": "scene"}},
	], str(source_event_b.get("id", "")))
	var source_batch_rows := source_batch_state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "tool_batch")
	if source_batch_rows.size() != 2 or int(source_batch_rows[0].get("tool_count", 0)) != 2 or int(source_batch_rows[1].get("tool_count", 0)) != 1:
		failures.append("tool transcript batches should group by model response source event instead of accumulating an entire turn")
	var guide_reuse_state := State.new()
	var guide_reuse_record: Dictionary = guide_reuse_state.record_pending_guide_instruction("queued guidance", "test")
	guide_reuse_state.mark_pending_steer_submitted(str(guide_reuse_record.get("id", "")), "turn_1")
	var guide_reuse_events := guide_reuse_state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "pending_steer" and str(event.get("data", {}).get("id", "")) == str(guide_reuse_record.get("id", "")))
	if guide_reuse_events.size() != 1 or str(guide_reuse_events[0].get("data", {}).get("status", "")) != "submitted":
		failures.append("pending guide lifecycle should update one hidden state event instead of appending duplicate guided rows")
	var command_run := state.record_command_run({
		"id": "command_1",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
	}, "running")
	if command_run.is_empty() or str(command_run.get("status", "")) != "running":
		failures.append("command runs should be recorded as model events")
	state.api_key = "sk-inline-secret"
	state.api_key_env = "GODEX_TEST_API_KEY"
	OS.set_environment("GODEX_TEST_API_KEY", "sk-env-secret")
	var chunk_stdout := state.append_command_run_chunk("command_1", "stdout", "hello sk-inline-secret", {"source": "fake"})
	var chunk_stderr := state.append_command_run_chunk("command_1", "stderr", "warn sk-env-secret", {"source": "fake"})
	if not bool(chunk_stdout.get("success", false)) or not bool(chunk_stderr.get("success", false)):
		failures.append("running command runs should accept bounded stdout/stderr chunks")
	var chunked_command: Dictionary = chunk_stderr.get("command_run", {})
	var output_chunks: Array = chunked_command.get("output_chunks", [])
	if output_chunks.size() != 2 or str(output_chunks[0].get("stream", "")) != "stdout" or str(output_chunks[1].get("stream", "")) != "stderr":
		failures.append("command output chunks should preserve stdout/stderr order")
	if JSON.stringify(output_chunks).find("sk-inline-secret") >= 0 or JSON.stringify(output_chunks).find("sk-env-secret") >= 0:
		failures.append("command output chunks should be redacted before storage")
	var command_updated := state.update_command_run_status("command_1", "completed", {
		"exit_code": 0,
		"stdout": "res://",
		"stderr": "",
		"combined_output": "res://",
		"runner_kind": "godot_os_execute_sync",
		"duration_ms": 12,
		"stderr_merged": true,
		"stderr_notice": "stderr is merged",
		"timeout_enforced": false,
	})
	if str(command_updated.get("status", "")) != "completed" or int(command_updated.get("result", {}).get("exit_code", -1)) != 0:
		failures.append("command run status update should retain exit code and output metadata")
	var command_result: Dictionary = command_updated.get("result", {})
	if str(command_result.get("combined_output", "")) != "res://" or str(command_result.get("runner_kind", "")) != "godot_os_execute_sync" or int(command_result.get("duration_ms", 0)) != 12 or not bool(command_result.get("stderr_merged", false)) or bool(command_result.get("timeout_enforced", true)):
		failures.append("command run status update should retain combined output, runner metadata, duration, stderr merge, and timeout boundary")
	var command_timeline: Array = command_updated.get("timeline", [])
	if command_timeline.size() < 2 or str(command_timeline[0].get("status", "")) != "running" or str(command_timeline[command_timeline.size() - 1].get("status", "")) != "completed" or str(command_timeline[command_timeline.size() - 1].get("summary", "")).find("12ms") < 0:
		failures.append("command runs should retain an auditable status timeline from running to terminal state with duration")
	if Array(command_updated.get("output_chunks", [])).size() != 2:
		failures.append("terminal command status updates should preserve previously streamed output chunks")
	var append_after_complete := state.append_command_run_chunk("command_1", "stdout", "late")
	if bool(append_after_complete.get("success", false)) or str(append_after_complete.get("error", "")) != "invalid_status":
		failures.append("command output chunks should not append after terminal states")
	state.record_command_run({
		"id": "command_chunk_limit",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
	}, "running")
	var limited_chunks := {}
	for chunk_index in range(45):
		limited_chunks = state.append_command_run_chunk("command_chunk_limit", "stdout", "line %s" % chunk_index)
	if Array(limited_chunks.get("command_run", {}).get("output_chunks", [])).size() > 40:
		failures.append("command output chunks should be bounded to avoid unbounded transcript growth")
	state.update_command_run_status("command_chunk_limit", "completed", {"exit_code": 0})
	state.set_command_run_expanded("command_1", true)
	var found_command_item := false
	for item in state.active_transcript_items():
		if str(item.get("kind", "")) == "command_run" and str(item.get("command_id", "")) == "command_1":
			var result: Dictionary = item.get("result", {})
			found_command_item = bool(item.get("expanded", false)) and str(item.get("detail", "")).find("combined output:") >= 0 and str(item.get("detail", "")).find("Timeout enforcement") >= 0 and Array(result.get("timeline", [])).size() >= 2 and Array(result.get("output_chunks", [])).size() == 2 and str(result.get("combined_output", "")) == "res://"
	if not found_command_item:
		failures.append("state transcript items should expose rebuildable command run rows with timeline, combined output, runner boundary, and output chunk data")
	state.api_key = ""
	state.api_key_env = "OPENAI_API_KEY"
	state.command_enabled = true
	state.command_shell = "PowerShell"
	state.command_working_directory = "res://"
	state.command_timeout_sec = 45
	var command_tool_records := state.record_tool_calls([
		{"id": "tool_command_1", "name": "godex_command_request", "arguments": {"command": "pwd", "working_directory": "res://"}},
	], "event_command_1")
	var found_command_tool_item := false
	for item in state.active_transcript_items():
		if str(item.get("kind", "")) == "command_run" and str(item.get("command_id", "")) == "command_tool_command_1":
			found_command_tool_item = str(item.get("status", "")) == "queued" and str(item.get("detail", "")).find("Command: pwd") >= 0 and str(item.get("detail", "")).find("Timeout: 45s") >= 0
	if command_tool_records.is_empty() or not found_command_tool_item:
		failures.append("command tool calls should create command transcript rows only from real model command requests")
	var exec_tool_records := state.record_tool_calls([
		{"id": "exec_command_1", "name": "exec_command", "arguments": {"command": "pwd", "workdir": "res://", "timeout_ms": 32000}},
	], "event_exec_command_1")
	var exec_command_row := state.command_run_by_id("command_exec_command_1")
	if exec_tool_records.is_empty() or str(exec_command_row.get("status", "")) != "queued" or str(exec_command_row.get("source", "")) != "exec_command" or int(exec_command_row.get("timeout_sec", 0)) != 32:
		failures.append("Codex-compatible exec_command tool calls should create approval-bound command runs with ms timeout normalization")
	state.cancel_command_run("command_exec_command_1")
	var write_stdin_records := state.record_tool_calls([
		{"id": "stdin_unsupported", "name": "write_stdin", "arguments": {"session_id": 1, "chars": ""}},
	], "event_write_stdin")
	if write_stdin_records.is_empty() or str(write_stdin_records[0].get("status", "")) != "failed" or str(write_stdin_records[0].get("result", {}).get("error", "")) != "interactive_command_sessions_not_available":
		failures.append("write_stdin should fail explicitly until Godex has an interactive process manager")
	var approval_checkpoint := state.request_command_run_approval("command_tool_command_1")
	if approval_checkpoint.is_empty() or str(approval_checkpoint.get("status", "")) != "pending":
		failures.append("command runs should create an explicit approval checkpoint before execution")
	_fake_command_runner_calls = 0
	state.record_command_run({
		"id": "command_unapproved",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
	}, "queued")
	var unapproved_result := state.execute_command_run_with_runner("command_unapproved", Callable(self, "_fake_command_runner"))
	if str(unapproved_result.get("status", "")) != "approval_required" or _fake_command_runner_calls != 0:
		failures.append("unapproved command runs should request approval without invoking the runner")
	state.decide_command_run_approval("command_tool_command_1", "approve")
	var executed_command := state.execute_command_run_with_runner("command_tool_command_1", Callable(self, "_fake_command_runner"))
	if str(executed_command.get("status", "")) != "completed" or int(executed_command.get("result", {}).get("exit_code", -1)) != 0 or _fake_command_runner_calls != 1:
		failures.append("approved command runs should execute through the supplied runner and store result metadata")
	state.record_command_run({
		"id": "command_cancel",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
	}, "queued")
	state.request_command_run_approval("command_cancel")
	var cancelled_command := state.cancel_command_run("command_cancel")
	if not bool(cancelled_command.get("success", false)) or str(cancelled_command.get("command_run", {}).get("status", "")) != "cancelled":
		failures.append("command runs should support cancellation before a real runner starts")
	var cancel_approval_still_pending := false
	for record in state.approval_records:
		if str(record.get("command_id", "")) == "command_cancel" and str(record.get("status", "")) == "pending":
			cancel_approval_still_pending = true
	if cancel_approval_still_pending:
		failures.append("cancelled command runs should clear pending command approvals")
	state.record_command_run({
		"id": "command_concurrent_running",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
	}, "running")
	state.record_command_run({
		"id": "command_concurrent_waiting",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
	}, "queued")
	state.request_command_run_approval("command_concurrent_waiting")
	state.decide_command_run_approval("command_concurrent_waiting", "approve")
	var concurrent_result := state.execute_command_run_with_runner("command_concurrent_waiting", Callable(self, "_fake_command_runner"))
	if str(concurrent_result.get("status", "")) != "blocked" or str(concurrent_result.get("result", {}).get("stderr", "")).find("Another command") < 0 or _fake_command_runner_calls != 1:
		failures.append("approved command runs should not start while another command is already running")
	state.update_command_run_status("command_concurrent_running", "completed", {"exit_code": 0})
	state.record_command_run({
		"id": "command_mutated",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
	}, "queued")
	state.request_command_run_approval("command_mutated")
	state.decide_command_run_approval("command_mutated", "approve")
	state.update_command_run_status("command_mutated", "approved", {"stdout": "changed"})
	for model_event in state.active_model_events():
		if str(model_event.get("kind", "")) == "command_run" and str(model_event.get("data", {}).get("id", "")) == "command_mutated":
			var data: Dictionary = model_event.get("data", {})
			data["command"] = "echo changed"
			model_event["data"] = data
	var mutated_result := state.execute_command_run_with_runner("command_mutated", Callable(self, "_fake_command_runner"))
	if str(mutated_result.get("status", "")) != "blocked" or str(mutated_result.get("result", {}).get("stderr", "")).find("changed after approval") < 0:
		failures.append("approved command runs should be blocked if the command changes after approval")
	state.record_command_run({
		"id": "command_bad_shell",
		"command": "pwd",
		"shell": "PowerShell -EncodedCommand deadbeef",
		"working_directory": "res://",
	}, "queued")
	var bad_shell_result := state.request_command_run_approval("command_bad_shell")
	if str(bad_shell_result.get("status", "")) != "blocked" or str(bad_shell_result.get("result", {}).get("stderr", "")).find("unsupported shell") < 0:
		failures.append("command approval should block unsupported shell strings before runner execution")
	state.record_command_run({
		"id": "command_bad_cwd",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "C:\\Windows\\System32",
	}, "queued")
	var bad_cwd_result := state.request_command_run_approval("command_bad_cwd")
	if str(bad_cwd_result.get("status", "")) != "blocked" or str(bad_cwd_result.get("result", {}).get("stderr", "")).find("unsafe working directory") < 0:
		failures.append("command approval should block unsafe working directories before runner execution")
	state.record_command_run({
		"id": "command_rejected",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
		"timeout_sec": 10,
	}, "queued")
	state.request_command_run_approval("command_rejected")
	var rejected_approval := state.decide_latest_approval("reject")
	var rejected_result := state.execute_command_run_with_runner("command_rejected", Callable(self, "_fake_command_runner"))
	if str(rejected_approval.get("status", "")) != "rejected" or str(rejected_result.get("status", "")) != "rejected":
		failures.append("generic approval decisions should route command approvals and keep rejected commands terminal")
	state.record_command_run({
		"id": "command_action",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
		"timeout_sec": 12,
	}, "queued")
	var command_action_approval := state.request_next_command_run_approval()
	if not bool(command_action_approval.get("success", false)) or str(state.next_queued_command_run().get("id", "")) == "command_action":
		failures.append("request next command approval should move the next queued command into approval_required")
	state.decide_command_run_approval("command_action", "approve")
	var command_action_execute := state.execute_next_approved_command_run()
	var command_action_result: Dictionary = command_action_execute.get("command_run", {})
	if str(command_action_execute.get("error", "")) != "runner_unavailable" or str(command_action_result.get("status", "")) != "failed" or str(command_action_result.get("result", {}).get("stderr", "")).find("runner is not available") < 0:
		failures.append("execute next approved command should fail safely when no command runner is connected")
	state.record_command_run({
		"id": "command_action_runner",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
		"timeout_sec": 12,
	}, "queued")
	state.request_command_run_approval("command_action_runner")
	state.decide_command_run_approval("command_action_runner", "approve")
	var command_action_runner_execute := state.execute_next_approved_command_run(Callable(self, "_fake_command_runner"))
	var command_action_runner_result: Dictionary = command_action_runner_execute.get("command_run", {})
	if not bool(command_action_runner_execute.get("success", false)) or str(command_action_runner_result.get("status", "")) != "completed" or int(command_action_runner_result.get("result", {}).get("exit_code", -1)) != 0:
		failures.append("execute next approved command should run through a supplied runner when one is connected")
	var runner_controller := DockController.new()
	var powershell_args: Array = runner_controller.call("_local_command_shell_args", "PowerShell", "Write-Output Godex")
	var cmd_args: Array = runner_controller.call("_local_command_shell_args", "cmd", "echo Godex")
	var unsupported_args: Array = runner_controller.call("_local_command_shell_args", "bash", "echo Godex")
	if powershell_args.size() != 6 or powershell_args[0] != "powershell.exe" or powershell_args[1] != "-NoLogo" or powershell_args[2] != "-NoProfile" or powershell_args[3] != "-NonInteractive" or powershell_args[4] != "-Command" or powershell_args[5] != "Write-Output Godex":
		failures.append("local command runner should launch Windows PowerShell with explicit non-interactive command arguments: %s" % str(powershell_args))
	if cmd_args.size() != 4 or cmd_args[0] != "cmd.exe" or cmd_args[1] != "/D" or cmd_args[2] != "/C" or cmd_args[3] != "echo Godex":
		failures.append("local command runner should map cmd commands through cmd.exe /D /C")
	if not unsupported_args.is_empty():
		failures.append("local command runner should reject unsupported shells before OS.execute")
	var project_cwd := str(runner_controller.call("_local_command_working_directory", "res://")).replace("\\", "/")
	var addon_cwd := str(runner_controller.call("_local_command_working_directory", "res://addons")).replace("\\", "/")
	if project_cwd.is_empty() or addon_cwd.is_empty() or project_cwd.find("/addons") >= 0 or addon_cwd.find("/addons") < 0:
		failures.append("local command runner should resolve only project-local res:// working directories: %s / %s" % [project_cwd, addon_cwd])
	var cwd_wrapped_args: Array = runner_controller.call("_local_command_shell_args", "PowerShell", "Write-Output (Get-Location).Path", addon_cwd)
	if cwd_wrapped_args.size() != 6 or str(cwd_wrapped_args[5]).find("Set-Location -LiteralPath") < 0 or str(cwd_wrapped_args[5]).find("Write-Output") < 0:
		failures.append("local command runner should wrap project-local working directory inside the shell command")
	state.record_command_run({
		"id": "command_timeout_mutated",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
		"timeout_sec": 10,
	}, "queued")
	state.request_command_run_approval("command_timeout_mutated")
	state.decide_command_run_approval("command_timeout_mutated", "approve")
	for timeout_event in state.active_model_events():
		if str(timeout_event.get("kind", "")) == "command_run" and str(timeout_event.get("data", {}).get("id", "")) == "command_timeout_mutated":
			var timeout_data: Dictionary = timeout_event.get("data", {})
			timeout_data["timeout_sec"] = 11
			timeout_event["data"] = timeout_data
	var timeout_mutated_result := state.execute_command_run_with_runner("command_timeout_mutated", Callable(self, "_fake_command_runner"))
	if str(timeout_mutated_result.get("status", "")) != "blocked" or str(timeout_mutated_result.get("result", {}).get("stderr", "")).find("changed after approval") < 0:
		failures.append("command timeout changes should invalidate an existing approval fingerprint")
	var pending_continuation := state.set_pending_openai_continuation({
		"success": true,
		"tool_call_id": "tool_call_1",
		"auto_send_allowed": false,
		"openai_request": {"endpoint": "https://api.openai.com/v1/responses", "api_mode": "responses", "model": "gpt-5.5", "key_source": "inline"},
		"transport_request": {"ready": true, "payload": {"model": "gpt-5.5"}},
	})
	if pending_continuation.is_empty() or state.pending_openai_continuation_summary().get("title", "").find("ready") < 0:
		failures.append("state should retain pending OpenAI continuation summary")
	if state.pending_openai_continuation.get("endpoint", "") != "https://api.openai.com/v1/responses" or state.pending_openai_continuation.get("key_source", "") != "inline":
		failures.append("pending OpenAI continuation should retain preview metadata")
	if str(state.pending_openai_continuation_summary().get("detail", "")).contains("sk-secret-token"):
		failures.append("pending OpenAI continuation summary must not expose raw API keys")
	state.clear_pending_openai_continuation("tool_call_1")
	if not state.pending_openai_continuation.is_empty():
		failures.append("state should clear matching pending OpenAI continuation")
	var approval_record := state.record_approval_checkpoint({"action": "network:openai_request", "summary": "Send OpenAI request", "risk": "high", "requires_approval": true, "source": "tool_result_continuation", "tool_call_id": "tool_call_1"})
	var approval_pending := state.set_pending_openai_approval_request({
		"ready": true,
		"endpoint": "https://api.openai.com/v1/responses",
		"api_mode": "responses",
		"model": "gpt-5.5",
		"headers": RequestBuilder.build_headers("sk-secret-token"),
		"payload": {"model": "gpt-5.5", "input": []},
	}, approval_record)
	if approval_pending.is_empty() or state.pending_openai_approval_request_preview().get("approval_id", "") != approval_record.get("id", ""):
		failures.append("state should retain pending OpenAI approval request preview")
	if state.pending_openai_approval_request_preview().get("source", "") != "tool_result_continuation" or state.pending_openai_approval_request_preview().get("tool_call_id", "") != "tool_call_1":
		failures.append("pending OpenAI approval preview should retain continuation source metadata")
	if str(state.pending_openai_approval_summary().get("detail", "")).contains("sk-secret-token"):
		failures.append("pending OpenAI approval summary must not expose raw API keys")
	if not Array(state.pending_openai_approval_transport_request().get("headers", [])).has("Authorization: Bearer sk-secret-token"):
		failures.append("pending OpenAI approval transport should retain raw headers in memory")
	state.clear_pending_openai_approval_request(str(approval_record.get("id", "")))
	if not state.pending_openai_approval_request.is_empty():
		failures.append("state should clear matching pending OpenAI approval request")
	var retry := state.set_retry_openai_request({
		"ready": true,
		"endpoint": "https://api.openai.com/v1/responses",
		"api_mode": "responses",
		"model": "gpt-5.5",
		"headers": RequestBuilder.build_headers("sk-secret-token"),
		"payload": {"model": "gpt-5.5", "input": []},
	}, "failed", "empty_response")
	if retry.is_empty() or state.retry_openai_request_preview().get("status", "") != "failed":
		failures.append("state should retain retryable OpenAI request preview")
	if str(state.retry_openai_request_summary().get("detail", "")).contains("sk-secret-token"):
		failures.append("retry summary must not expose raw API keys")
	if not Array(state.retry_openai_transport_request().get("headers", [])).has("Authorization: Bearer sk-secret-token"):
		failures.append("retry transport request should retain raw headers in memory")
	var persisted_json := JSON.stringify(state.to_sessions())
	if persisted_json.contains("Authorization: Bearer sk-") or persisted_json.contains("sk-secret-token") or persisted_json.contains("transport_request"):
		failures.append("session persistence snapshot must not include raw OpenAI transport data or API keys")
	state.clear_retry_openai_request()
	if not state.retry_openai_request.is_empty():
		failures.append("state should clear retryable OpenAI request")
	var loop_event := state.begin_agent_loop("smoke")
	if loop_event.is_empty() or state.agent_loop_status != "running":
		failures.append("state should record agent loop start")
	state.record_agent_loop_step("tool", "call_1")
	if state.agent_loop_step_count != 1 or not state.can_advance_agent_loop():
		failures.append("state should count agent loop steps")
	if state.agent_loop_max_steps != 0:
		failures.append("agent loop should default to an unbounded Codex-style follow-up loop")
	state.agent_loop_max_steps = 1
	if not state.can_advance_agent_loop():
		failures.append("state should keep the Codex-style loop unbounded even if a stale max-step value exists")
	state.stop_agent_loop("done")
	if state.agent_loop_status != "stopped" or state.agent_loop_stop_reason != "done":
		failures.append("state should record agent loop stop reason")
	if str(state.agent_loop_summary().get("detail", "")).find("done") < 0:
		failures.append("state should expose agent loop summary")


func _check_subagent_manager(failures: Array[String]) -> void:
	var manager := SubagentManager.new()
	var agent: Dictionary = manager.create_agent("Manager Scout", "explorer", "readonly/manager", true, "inspect", "gpt-5.5", "medium")
	var agent_id := str(agent.get("id", ""))
	if agent_id.is_empty() or str(agent.get("status", "")) != "queued":
		failures.append("subagent manager should create queued draft agents with stable ids")
	manager.mark_running(agent_id)
	var running: Dictionary = manager.list_agents()[0]
	if str(running.get("status", "")) != "running" or str(running.get("started_at", "")).is_empty():
		failures.append("subagent manager should record running lifecycle metadata")
	manager.mark_failed(agent_id, "manager failed")
	var failed: Dictionary = manager.list_agents()[0]
	if str(failed.get("status", "")) != "failed" or str(failed.get("error", "")) != "manager failed":
		failures.append("subagent manager should record failure metadata")
	manager.handoff(agent_id, "manager handoff", "smoke")
	var handed_off: Dictionary = manager.list_agents()[0]
	if str(handed_off.get("handoff_status", "")) != "handed_off" or str(handed_off.get("handoff_summary", "")) != "manager handoff":
		failures.append("subagent manager should record handoff metadata")
	var cancel_agent: Dictionary = manager.create_agent("Cancel Manager", "explorer", "readonly/cancel")
	var cancel_id := str(cancel_agent.get("id", ""))
	manager.cancel(cancel_id, "smoke")
	var cancelled: Dictionary = manager.list_agents()[1]
	if str(cancelled.get("status", "")) != "cancelled" or str(cancelled.get("cancelled_by", "")) != "smoke":
		failures.append("subagent manager should record cancellation metadata")


func _check_streaming_message_state(failures: Array[String]) -> void:
	var state := State.new()
	var baseline_count := state.active_messages().size()
	var index := state.append_message("assistant", "")
	state.update_message_content(index, "streamed delta")
	var messages := state.active_messages()
	if messages.size() != baseline_count + 1 or messages[index].get("content", "") != "streamed delta":
		failures.append("streaming assistant message should update in place instead of appending deltas")
	state.update_message_content(index + 1, "ignored")
	if state.active_messages().size() != baseline_count + 1:
		failures.append("out-of-range streaming message updates should not mutate the transcript")
	state.begin_agent_loop("transcript_smoke")
	var user_index := state.append_message("user", "call a tool")
	var turn_id := str(state.active_messages()[user_index].get("turn_id", ""))
	state.set("active_turn_id", turn_id)
	var turn_event := state.record_agent_loop_step("transcript_smoke", "started")
	state.api_key = "sk-test-secret"
	state.append_model_event("local_tool_probe", {
		"status": "created",
		"tool": "godex_mcp_context",
		"scope": "summary",
		"limit": 20,
		"turn_id": turn_id,
	})
	state.record_stream_step("OpenAI request", "已发送")
	state.append_model_event("mcp_context", {
		"status": "ready",
		"endpoint": "http://127.0.0.1:3000/mcp",
		"transport": "streamable-http",
		"summary": "MCP endpoint 已配置",
		"turn_id": turn_id,
	})
	state.append_model_event("context_menu_action", {
		"kind": "project_summary",
		"status": "attached",
		"turn_id": turn_id,
	})
	state.append_model_event("file_context", {
		"status": "attached",
		"path": "res://addons/godex/ui/godex_dock_controller.gd",
		"title": "godex_dock_controller.gd",
		"source": "composer_add_context",
		"turn_id": turn_id,
	})
	state.append_model_event("subagent", {
		"name": "Curie",
		"role": "explorer",
		"status": "running",
		"turn_id": turn_id,
	})
	state.append_model_event("openai_request", {
		"status": "ready",
		"api_mode": "responses",
		"model": "gpt-5.5",
		"reasoning_effort": "high",
		"endpoint": "https://api.openai.com/v1/responses",
		"turn_id": turn_id,
	})
	state.update_partial_tool_call({
		"id": "partial_tool_transcript_state",
		"name": "system_project_state",
		"arguments": "{\"api_key\":\"sk-partial-secret\",\"long\":\"%s\"}" % "x".repeat(180),
		"status": "streaming",
		"turn_id": turn_id,
		"batch_key": str(turn_event.get("id", "")),
	})
	if not state.pending_tool_calls().is_empty():
		failures.append("partial streaming tool calls must not become executable pending tool calls")
	var transcript_tool_records := state.record_tool_calls([
		{"id": "tool_transcript_state", "name": "system_project_state", "arguments": {"summary": true}},
	], str(turn_event.get("id", "")))
	state.update_tool_call_status("tool_transcript_state", "succeeded", {"message": "ok"})
	state.append_model_event("openai_transport", {
		"status": "completed",
		"model": "gpt-5.5",
		"endpoint": "https://api.openai.com/v1/responses",
		"stream_event_count": 4,
		"text_delta_total": 42,
		"tool_delta_count": 1,
		"completed_event_seen": false,
		"last_event_type": "response.output_text.delta",
		"turn_id": turn_id,
	})
	state.append_model_event("stream_trace", {
		"status": "received",
		"api_mode": "responses",
		"event_type": "response.function_call_arguments.delta",
		"text_delta_length": 0,
		"tool_delta_count": 1,
		"argument_delta_length": 18,
		"tool_names": ["godex_mcp_context"],
		"turn_id": turn_id,
	})
	state.append_model_event("stream_trace", {
		"status": "salvaged",
		"api_mode": "responses",
		"event_type": "non_stream_response",
		"text_delta_length": 32,
		"completed": true,
		"turn_id": turn_id,
	})
	state.append_model_event("openai_transport", {
		"status": "replayed",
		"source": "local_model_replay",
		"api_mode": "responses",
		"model": "gpt-5.5",
		"fixture_name": "mcp_context_tool_call",
		"turn_id": turn_id,
	})
	state.append_model_event("openai_response", {
		"status": "ok",
		"model": "gpt-5.5",
		"text": "Tool response done.",
		"tool_call_count": 1,
		"turn_id": turn_id,
	})
	state.append_model_event("openai_response", {
		"status": "ok",
		"source": "local_model_replay",
		"fixture_name": "mcp_context_tool_call",
		"model": "gpt-5.5",
		"text": "Replay response done.",
		"tool_call_count": 1,
		"turn_id": turn_id,
	})
	state.record_command_run({
		"id": "command_transcript_state",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
		"turn_id": turn_id,
	}, "failed", {"exit_code": 1, "stdout": "res:// timeline-secret-stdout", "stderr": "sk-test-secret"})
	state.set_command_run_expanded("command_transcript_state", true)
	state.set_active_goal("ship transcript goal", "active", "test")
	state.set_change_review_summary({
		"file_count": 1,
		"title": "文件已更改",
		"files": [{"path": "addons/godex/ui/godex_dock_controller.gd", "added": 12, "removed": 3}],
	})
	var transcript_items := state.active_transcript_items()
	var found_message_item := false
	var found_stream_step_item := false
	var found_partial_tool_item := false
	var found_tool_item := false
	var found_tool_batch_item := false
	var found_command_item := false
	var found_openai_request_item := false
	var found_openai_transport_item := false
	var found_openai_response_item := false
	var found_stream_trace_item := false
	var last_message_item_index := -1
	var tool_batch_item_index := -1
	var rebuild_tool_batch_id := ""
	for item in transcript_items:
		var transcript_item_index := transcript_items.find(item)
		if str(item.get("kind", "")) == "message" and int(item.get("message_index", -1)) == user_index and str(item.get("turn_id", "")) == turn_id:
			found_message_item = true
			last_message_item_index = transcript_item_index
		if str(item.get("kind", "")) == "stream_step" and str(item.get("title", "")) == "OpenAI request":
			found_stream_step_item = true
		if str(item.get("kind", "")) == "tool_batch":
			found_tool_batch_item = str(item.get("turn_id", "")) == turn_id and int(item.get("tool_count", 0)) == 2
			tool_batch_item_index = transcript_item_index
			rebuild_tool_batch_id = str(item.get("batch_id", ""))
			var calls: Array = item.get("calls", []) if item.get("calls", []) is Array else []
			for call_item in calls:
				if not (call_item is Dictionary):
					continue
				if str(call_item.get("kind", "")) == "partial_tool_call" and str(call_item.get("tool_call_id", "")) == "partial_tool_transcript_state":
					found_partial_tool_item = str(call_item.get("detail", "")).find("Partial arguments") >= 0
				if str(call_item.get("kind", "")) == "tool_call" and str(call_item.get("tool_call_id", "")) == "tool_transcript_state":
					found_tool_item = str(call_item.get("detail", "")).find("Result: ok") >= 0
		if str(item.get("kind", "")) == "command_run" and str(item.get("command_id", "")) == "command_transcript_state":
			var result: Dictionary = item.get("result", {})
			found_command_item = str(item.get("turn_id", "")) == turn_id and bool(item.get("expanded", false)) and str(item.get("detail", "")).find("Exit code: 1") >= 0 and str(result.get("stdout", "")).find("res://") >= 0 and str(result.get("stderr", "")).find("[redacted-api-key]") >= 0
		if str(item.get("kind", "")) == "openai_request":
			found_openai_request_item = true
		if str(item.get("kind", "")) == "openai_transport":
			found_openai_transport_item = true
		if str(item.get("kind", "")) == "stream_trace":
			if str(item.get("turn_id", "")) == turn_id and str(item.get("event_type", "")) == "response.function_call_arguments.delta" and int(item.get("argument_delta_length", 0)) == 18:
				found_stream_trace_item = true
		if str(item.get("kind", "")) == "openai_response":
			found_openai_response_item = true
	if transcript_tool_records.is_empty() or not found_message_item or not found_tool_batch_item or not found_tool_item or not found_command_item:
		failures.append("state should expose rebuildable transcript items for messages, grouped tool calls, and command runs in the same turn")
	if found_stream_step_item or found_openai_request_item or found_openai_transport_item or found_openai_response_item or found_stream_trace_item:
		failures.append("state should keep internal stream/OpenAI diagnostics out of the chat transcript")
	var model_events := state.active_model_events()
	var found_openai_event_audit := false
	var found_lifecycle_event_audit := false
	for event in model_events:
		if str(event.get("kind", "")).begins_with("openai_") and str(event.get("data", {}).get("turn_id", "")) == turn_id:
			found_openai_event_audit = true
		if ["agent_loop", "local_tool_probe", "mcp_context", "subagent", "goal_state"].has(str(event.get("kind", ""))):
			found_lifecycle_event_audit = true
	if not found_openai_event_audit:
		failures.append("OpenAI network diagnostics should remain in model events even when hidden from chat transcript")
	if not found_lifecycle_event_audit:
		failures.append("lifecycle diagnostics should remain in model events even when hidden from chat transcript")
	if not found_partial_tool_item:
		failures.append("state should expose transient partial tool-call transcript items inside the grouped batch without making them executable")
	state.complete_partial_tool_call("partial_tool_transcript_state")
	for item in state.active_transcript_items():
		if str(item.get("kind", "")) == "partial_tool_call":
			failures.append("completed partial tool calls should be removed from transcript items")
	if last_message_item_index < 0 or tool_batch_item_index <= last_message_item_index:
		failures.append("state transcript items should keep grouped tool rows near their owning turn instead of appending them before messages")
	var controller_source := FileAccess.get_file_as_string(CONTROLLER_SCRIPT)
	for required in [
		"HTTPClient.new()",
		"_poll_openai_stream",
		"_begin_streaming_assistant_message",
		"_record_stream_step",
		"record_stream_step",
		"_accumulate_openai_stream_tool_call",
		"_record_accumulated_openai_stream_tool_calls",
		"_record_openai_stream_trace",
		"_openai_stream_trace_summary",
		"_try_finalize_openai_stream_from_buffer",
		"_openai_stream_event_label",
		"parse_stream_residual",
		"stream_residual_json",
		"non_stream_response",
		"_stream_trace_transcript_title",
		"_create_command_transcript_row",
		"_show_command_transcript_row",
		"_toggle_command_transcript_row",
		"active_transcript_items",
		"_render_transcript_item",
		"_create_tool_transcript_row",
		"_show_tool_transcript_row",
		"_show_tool_batch_transcript_row",
		"_update_tool_transcript_row",
		"正在思考",
		"_progress_rows",
	]:
		if controller_source.find(required) < 0:
			failures.append("controller should include streaming chat UI contract: %s" % required)
	if controller_source.find("get_available_bytes") >= 0:
		failures.append("OpenAI streaming transport should not call unavailable HTTPClient.get_available_bytes in Godot 4.6")
	if controller_source.find("_add_message(\"assistant\", \"设置已保存到") >= 0:
		failures.append("settings save status should not be appended into the chat transcript")
	if controller_source.find("_add_persisted_message(\"assistant\", _mcp_tool_chat_summary(parsed))") >= 0:
		failures.append("MCP tool completion should update a transcript row instead of adding a plain assistant summary")
	var controller_script := load(CONTROLLER_SCRIPT)
	if controller_script == null or not controller_script.can_instantiate():
		failures.append("controller script should instantiate before tool transcript row checks")
		return
	var controller = controller_script.new()
	controller.set("_state", state)
	var readable_stream_error := str(controller.call("_openai_stream_error_message", "stream_poll_27"))
	if readable_stream_error.find("stream_poll_27") < 0 or readable_stream_error.find("连接错误") < 0:
		failures.append("stream poll connection errors should keep the raw code while showing a readable network hint")
	var readable_timeout_error := str(controller.call("_openai_stream_error_message", "stream_timeout"))
	if readable_timeout_error.find("超时") < 0:
		failures.append("stream timeout errors should show a readable timeout hint")
	var readable_http_error := str(controller.call("_openai_stream_error_message", "http_401"))
	if readable_http_error.find("HTTP") < 0 or readable_http_error.find("错误体") < 0 or readable_http_error.find("可重试") < 0:
		failures.append("stream HTTP status errors should expose provider bodies and preserve retry state")
	controller.set("_openai_stream_started_at_msec", 1000)
	controller.set("_openai_stream_last_activity_msec", 1000)
	if not bool(controller.call("_openai_stream_timed_out_at", 77000)):
		failures.append("manual OpenAI stream transport should enforce an idle timeout")
	controller.set("_openai_stream_started_at_msec", 1000)
	controller.set("_openai_stream_last_activity_msec", 2000)
	if bool(controller.call("_openai_stream_timed_out_at", 4000)):
		failures.append("manual OpenAI stream transport should keep active streams alive before idle timeout")
	state.call("stop_agent_loop", "openai_approval_required")
	controller.call("_resume_agent_loop_for_approved_openai_source", "user_prompt")
	if state.agent_loop_status != "running" or not state.can_advance_agent_loop() or state.agent_loop_stop_reason != "user_prompt":
		failures.append("approving a user-prompt OpenAI request should resume the agent loop before tool-call handling")
	state.call("stop_agent_loop", "openai_approval_required")
	controller.call("_resume_agent_loop_for_approved_openai_source", "retry_request")
	if state.agent_loop_status != "running" or not state.can_advance_agent_loop() or state.agent_loop_stop_reason != "retry_request":
		failures.append("approving a retry OpenAI request should resume the agent loop before tool-call handling")
	var error_body := JSON.stringify({"error": {"type": "bad_gateway", "message": "upstream stream gateway failed"}})
	if str(controller.call("_openai_http_error_code", 502, error_body)) != "http_502:bad_gateway":
		failures.append("stream HTTP errors should preserve provider error type in retry diagnostics")
	if str(controller.call("_openai_http_error_message", 502, error_body)).find("upstream stream gateway failed") < 0:
		failures.append("stream HTTP errors should preserve provider error messages")
	if not bool(controller.call("_openai_stream_error_allows_fallback", 502, error_body)):
		failures.append("HTTP 502 stream failures should allow a non-stream fallback attempt")
	if bool(controller.call("_openai_stream_error_allows_fallback", 401, "")):
		failures.append("credential failures should not be retried as non-stream fallback without provider compatibility evidence")
	var plain_fallback_payload: Dictionary = controller.call("_openai_plain_chat_fallback_payload", {
		"model": "gpt-5.5",
		"messages": [{"role": "user", "content": "ping"}],
		"stream": true,
		"tools": [{"type": "function", "function": {"name": "godex_mcp_context"}}],
		"reasoning_effort": "medium",
		"parallel_tool_calls": true,
	})
	if plain_fallback_payload.is_empty() or plain_fallback_payload.has("stream") or plain_fallback_payload.has("tools") or plain_fallback_payload.has("reasoning_effort") or plain_fallback_payload.has("parallel_tool_calls"):
		failures.append("plain Chat Completions compatibility fallback should strip stream, tools, and reasoning-only fields")
	if plain_fallback_payload.get("messages", []).size() != 1 or plain_fallback_payload.get("model", "") != "gpt-5.5":
		failures.append("plain Chat Completions compatibility fallback should preserve model and message content")
	var tool_result_fallback_payload: Dictionary = controller.call("_openai_plain_chat_fallback_payload", {
		"model": "gpt-5.5",
		"messages": [
			{"role": "system", "content": "Inspect Godot"},
			{"role": "user", "content": "Check scene"},
			{
				"role": "assistant",
				"content": "",
				"tool_calls": [
					{"id": "call_plain_1", "type": "function", "function": {"name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"}},
				],
			},
			{"role": "tool", "tool_call_id": "call_plain_1", "content": "{\"ok\":true}"},
		],
		"stream": true,
		"tools": [{"type": "function", "function": {"name": "godex_mcp_context"}}],
		"reasoning_effort": "medium",
	})
	var tool_result_fallback_messages: Array = tool_result_fallback_payload.get("messages", [])
	var plain_tool_protocol_left := false
	var found_plain_tool_request := false
	var found_plain_tool_result := false
	for fallback_message in tool_result_fallback_messages:
		if not (fallback_message is Dictionary):
			continue
		if fallback_message.has("tool_calls") or fallback_message.has("tool_call_id") or str(fallback_message.get("role", "")) == "tool":
			plain_tool_protocol_left = true
		var fallback_content := str(fallback_message.get("content", ""))
		if fallback_content.find("工具调用请求：godex_mcp_context") >= 0:
			found_plain_tool_request = true
		if fallback_content.find("工具结果（call_plain_1）") >= 0:
			found_plain_tool_result = true
	if tool_result_fallback_payload.is_empty() or plain_tool_protocol_left or not found_plain_tool_request or not found_plain_tool_result:
		failures.append("plain Chat fallback should rewrite tool-result continuations into pure text messages without Chat tool protocol fields")
	if not bool(controller.call("_openai_compatibility_fallback_allowed", "chat_completions", 502, error_body, {"error": "http_502"})):
		failures.append("chat completions HTTP 502 failures should allow one plain-text compatibility fallback")
	if not bool(controller.call("_openai_compatibility_fallback_allowed", "chat_completions", 0, "", {"error": "stream_timeout"})):
		failures.append("chat completions stream timeouts should allow one plain-text compatibility fallback")
	if not bool(controller.call("_openai_compatibility_fallback_allowed", "chat_completions", 0, "", {"error": "stream_poll_31"})):
		failures.append("chat completions stream poll errors should allow one plain-text compatibility fallback")
	if not bool(controller.call("_openai_compatibility_fallback_allowed", "chat_completions", 0, "", {"error": "empty_chat_completion"})):
		failures.append("empty chat completions should allow one plain-text compatibility fallback")
	if bool(controller.call("_openai_compatibility_fallback_allowed", "chat_completions", 401, "", {"error": "auth"})):
		failures.append("plain-text compatibility fallback must not mask credential failures")
	if bool(controller.call("_openai_compatibility_fallback_allowed", "responses", 502, error_body, {"error": "http_502"})):
		failures.append("plain-text compatibility fallback should be limited to Chat Completions compatible providers")
	var fallback_root := Control.new()
	get_root().add_child(fallback_root)
	var fallback_request_node := HTTPRequest.new()
	fallback_root.add_child(fallback_request_node)
	var fallback_state := State.new()
	fallback_state.base_url = "https://yurenapi.cn/v1"
	fallback_state.set("is_running", true)
	var fallback_status := Label.new()
	var fallback_stream_timer := Timer.new()
	fallback_root.add_child(fallback_status)
	fallback_root.add_child(fallback_stream_timer)
	fallback_stream_timer.start(10.0)
	var fallback_controller = controller_script.new()
	fallback_controller.set("_state", fallback_state)
	fallback_controller.set("_openai_request", fallback_request_node)
	fallback_controller.set("_openai_stream_status", fallback_status)
	fallback_controller.set("_openai_stream_timer", fallback_stream_timer)
	fallback_controller.set("_openai_stream_started_at_msec", Time.get_ticks_msec())
	fallback_controller.set("_active_openai_transport_request", {
		"endpoint": "https://yurenapi.cn/v1/responses",
		"api_mode": "responses",
		"model": "gpt-5.5",
		"payload": {
			"model": "gpt-5.5",
			"messages": [{"role": "user", "content": "ping"}],
			"stream": true,
			"tools": [{"type": "function", "function": {"name": "godex_mcp_context"}}],
			"reasoning_effort": "medium",
		},
		"headers": PackedStringArray(),
	})
	if not bool(fallback_controller.call("_try_start_openai_plain_chat_fallback", "chat_completions", 502, error_body, {"error": "http_502"})):
		failures.append("plain Chat Completions compatibility fallback should start for compatible Chat HTTP failures")
	var fallback_snapshot: Dictionary = fallback_controller.get("_active_openai_transport_request")
	var fallback_payload: Dictionary = fallback_snapshot.get("payload", {})
	if str(fallback_snapshot.get("endpoint", "")) != "https://yurenapi.cn/v1/chat/completions" or str(fallback_snapshot.get("api_mode", "")) != "chat_completions":
		failures.append("plain Chat Completions compatibility fallback should rewrite stale endpoint snapshots to /v1/chat/completions")
	if not bool(fallback_snapshot.get("compatibility_fallback_attempted", false)) or str(fallback_snapshot.get("compatibility_fallback_mode", "")) != "plain_chat":
		failures.append("plain Chat Completions compatibility fallback should mark the active transport snapshot as degraded")
	if fallback_payload.has("stream") or fallback_payload.has("tools") or fallback_payload.has("reasoning_effort"):
		failures.append("plain Chat Completions compatibility fallback active request should store the stripped payload")
	if not fallback_stream_timer.is_stopped():
		failures.append("plain Chat compatibility fallback should stop the previous stream poll timer before starting HTTPRequest fallback")
	var found_fallback_audit := false
	for fallback_event in fallback_state.active_model_events():
		var fallback_data: Dictionary = fallback_event.get("data", {})
		if str(fallback_event.get("kind", "")) == "openai_transport" and str(fallback_data.get("status", "")) == "compatibility_fallback" and str(fallback_data.get("endpoint", "")) == "https://yurenapi.cn/v1/chat/completions":
			found_fallback_audit = true
	if not found_fallback_audit:
		failures.append("plain Chat Completions compatibility fallback should audit the rewritten Chat endpoint")
	fallback_root.free()
	var timeout_fallback_root := Control.new()
	get_root().add_child(timeout_fallback_root)
	var timeout_request_node := HTTPRequest.new()
	timeout_fallback_root.add_child(timeout_request_node)
	var timeout_state := State.new()
	timeout_state.base_url = "https://yurenapi.cn/v1"
	timeout_state.set("is_running", true)
	var timeout_status := Label.new()
	timeout_fallback_root.add_child(timeout_status)
	var timeout_fallback_controller = controller_script.new()
	timeout_fallback_controller.set("_state", timeout_state)
	timeout_fallback_controller.set("_openai_request", timeout_request_node)
	timeout_fallback_controller.set("_openai_stream_status", timeout_status)
	timeout_fallback_controller.set("_openai_stream_started_at_msec", Time.get_ticks_msec())
	timeout_fallback_controller.set("_active_openai_api_mode", "chat_completions")
	timeout_fallback_controller.set("_active_openai_transport_request", {
		"endpoint": "https://yurenapi.cn/v1/chat/completions",
		"api_mode": "chat_completions",
		"model": "gpt-5.5",
		"payload": {
			"model": "gpt-5.5",
			"messages": [{"role": "user", "content": "ping"}],
			"stream": true,
			"tools": [{"type": "function", "function": {"name": "godex_mcp_context"}}],
			"reasoning_effort": "medium",
		},
		"headers": PackedStringArray(),
	})
	if not bool(timeout_fallback_controller.call("_try_start_openai_plain_chat_fallback_from_error", "stream_timeout")):
		failures.append("chat completions stream timeouts should start a plain Chat fallback")
	var timeout_snapshot: Dictionary = timeout_fallback_controller.get("_active_openai_transport_request")
	var timeout_payload: Dictionary = timeout_snapshot.get("payload", {})
	if not bool(timeout_snapshot.get("compatibility_fallback_attempted", false)) or timeout_payload.has("stream") or timeout_payload.has("tools") or timeout_payload.has("reasoning_effort"):
		failures.append("stream timeout fallback should preserve only minimal plain Chat payload fields")
	timeout_fallback_root.free()
	var direct_payload_controller = controller_script.new()
	var direct_payload_state := State.new()
	direct_payload_state.provider = "yurenapi"
	direct_payload_state.api_mode = "chat_completions"
	direct_payload_controller.set("_state", direct_payload_state)
	var direct_transport_request := {
		"provider": "yurenapi",
		"api_mode": "chat_completions",
		"endpoint": "https://yurenapi.cn/v1/chat/completions",
		"payload": {
			"model": "gpt-5.5",
			"messages": [{"role": "user", "content": "ping"}],
			"stream": true,
			"tools": [{"type": "function", "function": {"name": "godex_mcp_context"}}],
			"reasoning_effort": "medium",
		},
	}
	if not bool(direct_payload_controller.call("_openai_transport_prefers_http_request", direct_transport_request)):
		failures.append("OpenAI-compatible Chat Completions providers should prefer direct HTTPRequest transport before stream fallback")
	direct_payload_state.provider = "openai"
	if not bool(direct_payload_controller.call("_openai_transport_prefers_http_request", direct_transport_request)):
		failures.append("direct HTTP routing should use the request-local provider snapshot instead of the current UI provider")
	var direct_first_payload: Dictionary = direct_payload_controller.call("_openai_first_send_payload", direct_transport_request, true)
	if direct_first_payload.has("stream") or direct_first_payload.get("model", "") != "gpt-5.5" or direct_first_payload.get("messages", []).size() != 1 or direct_first_payload.get("tools", []).size() != 1:
		failures.append("direct HTTP first-send payload should strip stream while preserving model, messages, tools, and reasoning fields")
	var openai_payload_state := State.new()
	openai_payload_state.provider = "yurenapi"
	openai_payload_state.api_mode = "responses"
	direct_payload_controller.set("_state", openai_payload_state)
	if bool(direct_payload_controller.call("_openai_transport_prefers_http_request", {"api_mode": "responses", "payload": {}})):
		failures.append("OpenAI Responses mode should keep the streaming HTTPClient transport path")
	if bool(direct_payload_controller.call("_openai_transport_prefers_http_request", {
		"provider": "openai",
		"api_mode": "chat_completions",
		"endpoint": "https://api.openai.com/v1/chat/completions",
		"payload": {"stream": true},
	})):
		failures.append("request-local OpenAI Chat Completions snapshots should not be rerouted by a later Yuren UI selection")
	var streamed_first_payload: Dictionary = direct_payload_controller.call("_openai_first_send_payload", direct_transport_request, false)
	if not streamed_first_payload.has("stream"):
		failures.append("streaming first-send payload should preserve the stream flag")
	var trace_controller = controller_script.new()
	trace_controller.set("_state", State.new())
	trace_controller.set("_active_openai_api_mode", "chat_completions")
	trace_controller.set("_active_openai_transport_request", {
		"api_mode": "chat_completions",
		"stream_path": "/v1/chat/completions",
		"stream_fallback_attempted": true,
		"stream_fallback_from": "http_502",
	})
	var trace_summary: Dictionary = trace_controller.call("_openai_stream_trace_summary")
	if trace_summary.get("stream_path", "") != "/v1/chat/completions" or trace_summary.get("api_mode", "") != "chat_completions" or not bool(trace_summary.get("stream_fallback_attempted", false)):
		failures.append("OpenAI stream trace summary should expose API mode, request path, and fallback state")
	controller.set("_openai_stream_buffer", JSON.stringify({
		"id": "resp_json_body",
		"output": [{"type": "message", "content": [{"type": "output_text", "text": "Body JSON done."}]}],
	}))
	if not bool(controller.call("_openai_stream_buffer_has_complete_json")):
		failures.append("OpenAI stream transport should detect complete JSON bodies before idle timeout")
	controller.set("_openai_stream_buffer", "{\"output\":[")
	if bool(controller.call("_openai_stream_buffer_has_complete_json")):
		failures.append("OpenAI stream transport should not treat partial JSON chunks as complete responses")
	controller.set("_openai_stream_buffer", "data: %s\n\n" % JSON.stringify({"type": "response.output_text.delta", "delta": "Hi"}))
	if bool(controller.call("_openai_stream_buffer_has_complete_json")):
		failures.append("OpenAI stream transport should not treat SSE data events as complete JSON bodies")
	var json_finalize_state := State.new()
	json_finalize_state.begin_agent_loop("user_prompt")
	json_finalize_state.set("is_running", true)
	var json_finalize_agent := AgentService.new()
	json_finalize_agent.setup(json_finalize_state)
	var json_finalize_root = load(MAIN_SCENE).instantiate()
	get_root().add_child(json_finalize_root)
	_prepare_headless_root(json_finalize_root, Vector2(1280.0, 720.0))
	var json_finalize_controller = controller_script.new()
	json_finalize_controller.set("_root", json_finalize_root)
	json_finalize_controller.set("_state", json_finalize_state)
	json_finalize_controller.set("_agent", json_finalize_agent)
	json_finalize_controller.call("_assign_nodes")
	json_finalize_controller.call("_apply_static_chrome")
	json_finalize_controller.call("_apply_model", json_finalize_state.to_model())
	json_finalize_controller.set("_active_openai_api_mode", "responses")
	json_finalize_controller.set("_active_openai_transport_request", {
		"endpoint": "https://yurenapi.cn/v1/responses",
		"api_mode": "responses",
		"model": "gpt-5.5",
		"source": "user_prompt",
	})
	json_finalize_controller.set("_openai_stream_started_at_msec", Time.get_ticks_msec())
	json_finalize_controller.call("_begin_streaming_assistant_message")
	json_finalize_controller.set("_openai_stream_buffer", JSON.stringify({
		"id": "resp_json_controller",
		"output_text": "Controller JSON body done.",
	}))
	if not bool(json_finalize_controller.call("_try_finalize_openai_json_body_from_buffer", "non_stream_body")):
		failures.append("controller should finalize complete non-stream JSON bodies without waiting for timeout")
	var json_finalize_messages_state := json_finalize_state.active_messages()
	var json_finalize_text := str(json_finalize_messages_state[json_finalize_messages_state.size() - 1].get("content", "")) if not json_finalize_messages_state.is_empty() else ""
	if json_finalize_text != "Controller JSON body done." or json_finalize_state.agent_loop_status != "stopped" or json_finalize_state.agent_loop_stop_reason != "final_model_response":
		failures.append("controller JSON body finalization should persist final assistant text and close the Agent loop: %s / %s / %s" % [json_finalize_text, json_finalize_state.agent_loop_status, json_finalize_state.agent_loop_stop_reason])
	if json_finalize_text == "模型响应已完成。":
		failures.append("controller JSON body finalization should not fall back to placeholder completion text")
	if not str(json_finalize_controller.get("_openai_stream_buffer")).is_empty() or not bool(json_finalize_controller.get("_openai_stream_completed")) or str(json_finalize_controller.get("_openai_stream_text")) != "Controller JSON body done.":
		failures.append("controller JSON body finalization should clear the buffer, mark stream completion, and retain stream text")
	if bool(json_finalize_state.get("is_running")) or not (json_finalize_controller.get("_active_openai_transport_request") as Dictionary).is_empty():
		failures.append("controller JSON body finalization should clear running UI/transport state")
	var found_json_stream_trace := false
	var found_json_response_event := false
	var found_json_transport_event := false
	for json_event in json_finalize_state.active_model_events():
		var json_data: Dictionary = json_event.get("data", {})
		if str(json_event.get("kind", "")) == "stream_trace" and str(json_data.get("event_type", "")) == "non_stream_response" and str(json_data.get("status", "")) == "salvaged":
			found_json_stream_trace = true
		if str(json_event.get("kind", "")) == "openai_response" and str(json_data.get("source", "")) == "stream_residual_json" and str(json_data.get("text", "")) == "Controller JSON body done.":
			found_json_response_event = true
		if str(json_event.get("kind", "")) == "openai_transport" and str(json_data.get("status", "")) == "completed" and bool(json_data.get("stream", false)):
			found_json_transport_event = true
	if not found_json_stream_trace or not found_json_response_event or not found_json_transport_event:
		failures.append("controller JSON body finalization should leave stream trace, response, and completed transport audit events")
	json_finalize_root.queue_free()
	var direct_http_state := State.new()
	direct_http_state.provider = "yurenapi"
	direct_http_state.api_mode = "chat_completions"
	direct_http_state.begin_agent_loop("user_prompt")
	direct_http_state.set("is_running", true)
	var direct_http_baseline_count := direct_http_state.active_messages().size()
	var direct_http_agent := AgentService.new()
	direct_http_agent.setup(direct_http_state)
	var direct_http_root = load(MAIN_SCENE).instantiate()
	get_root().add_child(direct_http_root)
	_prepare_headless_root(direct_http_root, Vector2(1280.0, 720.0))
	var direct_http_request_node := HTTPRequest.new()
	direct_http_root.add_child(direct_http_request_node)
	var direct_http_controller = controller_script.new()
	direct_http_controller.set("_root", direct_http_root)
	direct_http_controller.set("_state", direct_http_state)
	direct_http_controller.set("_agent", direct_http_agent)
	direct_http_controller.call("_assign_nodes")
	direct_http_controller.call("_apply_static_chrome")
	direct_http_controller.call("_apply_model", direct_http_state.to_model())
	direct_http_controller.set("_openai_request", direct_http_request_node)
	direct_http_controller.set("_active_openai_api_mode", "chat_completions")
	direct_http_controller.set("_active_openai_transport_request", {
		"endpoint": "https://yurenapi.cn/v1/chat/completions",
		"api_mode": "chat_completions",
		"model": "gpt-5.5",
		"source": "user_prompt",
		"stage": "non_stream_direct",
		"payload": {
			"model": "gpt-5.5",
			"messages": [{"role": "user", "content": "ping"}],
		},
	})
	direct_http_controller.set("_openai_stream_started_at_msec", Time.get_ticks_msec())
	direct_http_controller.call("_begin_streaming_assistant_message")
	var direct_http_body := JSON.stringify({
		"id": "chatcmpl_direct_http",
		"object": "chat.completion",
		"model": "gpt-5.5",
		"choices": [{
			"index": 0,
			"message": {"role": "assistant", "content": "Direct HTTP done."},
			"finish_reason": "stop",
		}],
	})
	direct_http_controller.call("_on_openai_request_completed", HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), direct_http_body.to_utf8_buffer())
	var direct_http_messages := direct_http_state.active_messages()
	var direct_http_text := str(direct_http_messages[direct_http_messages.size() - 1].get("content", "")) if not direct_http_messages.is_empty() else ""
	if direct_http_messages.size() != direct_http_baseline_count + 1 or direct_http_text != "Direct HTTP done." or direct_http_state.agent_loop_status != "stopped" or direct_http_state.agent_loop_stop_reason != "final_model_response":
		failures.append("direct HTTP Chat Completions completion should update the streaming placeholder and close the Agent loop: %d / %s / %s / %s" % [direct_http_messages.size(), direct_http_text, direct_http_state.agent_loop_status, direct_http_state.agent_loop_stop_reason])
	if bool(direct_http_state.get("is_running")) or not (direct_http_controller.get("_active_openai_transport_request") as Dictionary).is_empty():
		failures.append("direct HTTP Chat Completions completion should clear running UI/transport state")
	var found_direct_http_transport := false
	var found_direct_http_response := false
	for direct_event in direct_http_state.active_model_events():
		var direct_data: Dictionary = direct_event.get("data", {})
		if str(direct_event.get("kind", "")) == "openai_transport" and str(direct_data.get("status", "")) == "completed" and str(direct_data.get("stage", "")) == "non_stream_direct" and not bool(direct_data.get("stream", true)):
			found_direct_http_transport = true
		if str(direct_event.get("kind", "")) == "openai_response" and str(direct_data.get("text", "")) == "Direct HTTP done.":
			found_direct_http_response = true
	if not found_direct_http_transport or not found_direct_http_response:
		failures.append("direct HTTP Chat Completions completion should audit non-stream transport and model response events")
	var direct_http_title := str(direct_http_controller.call("_openai_transport_transcript_title", {
		"status": "completed",
		"stage": "non_stream_direct",
		"model": "gpt-5.5",
		"endpoint": "https://yurenapi.cn/v1/chat/completions",
	}))
	if direct_http_title.find("非流式请求完成") < 0 or direct_http_title.find("gpt-5.5") < 0:
		failures.append("direct HTTP Chat Completions transcript should expose the non-stream request stage: %s" % direct_http_title)
	direct_http_root.queue_free()
	var chat_sse_state := State.new()
	chat_sse_state.begin_agent_loop("user_prompt")
	chat_sse_state.set("is_running", true)
	var chat_sse_agent := AgentService.new()
	chat_sse_agent.setup(chat_sse_state)
	var chat_sse_root = load(MAIN_SCENE).instantiate()
	get_root().add_child(chat_sse_root)
	_prepare_headless_root(chat_sse_root, Vector2(1280.0, 720.0))
	var chat_sse_controller = controller_script.new()
	chat_sse_controller.set("_root", chat_sse_root)
	chat_sse_controller.set("_state", chat_sse_state)
	chat_sse_controller.set("_agent", chat_sse_agent)
	chat_sse_controller.call("_assign_nodes")
	chat_sse_controller.call("_apply_static_chrome")
	chat_sse_controller.call("_apply_model", chat_sse_state.to_model())
	chat_sse_controller.set("_active_openai_api_mode", "chat_completions")
	chat_sse_controller.set("_active_openai_transport_request", {
		"endpoint": "https://yurenapi.cn/v1/chat/completions",
		"api_mode": "chat_completions",
		"model": "gpt-5.5",
		"source": "user_prompt",
	})
	chat_sse_controller.set("_openai_stream_started_at_msec", Time.get_ticks_msec())
	chat_sse_controller.call("_begin_streaming_assistant_message")
	var chat_delta := JSON.stringify({
		"id": "resp_yuren_sse",
		"object": "chat.completion.chunk",
		"model": "gpt-5.5",
		"choices": [{"index": 0, "delta": {"content": "Yuren SSE done."}, "finish_reason": null}],
	})
	var chat_done := JSON.stringify({
		"id": "resp_yuren_sse",
		"object": "chat.completion.chunk",
		"model": "gpt-5.5",
		"choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
	})
	chat_sse_controller.set("_openai_stream_buffer", "data: %s\n\ndata: %s\n\n" % [chat_delta, chat_done])
	if not bool(chat_sse_controller.call("_try_finalize_openai_stream_from_buffer", "stream_disconnected")):
		failures.append("controller should finalize Yuren-style Chat Completions SSE chunks on disconnect")
	var chat_sse_messages := chat_sse_state.active_messages()
	var chat_sse_text := str(chat_sse_messages[chat_sse_messages.size() - 1].get("content", "")) if not chat_sse_messages.is_empty() else ""
	if chat_sse_text != "Yuren SSE done." or chat_sse_state.agent_loop_status != "stopped" or chat_sse_state.agent_loop_stop_reason != "final_model_response":
		failures.append("Yuren-style Chat Completions SSE should persist final assistant text and close the Agent loop: %s / %s / %s" % [chat_sse_text, chat_sse_state.agent_loop_status, chat_sse_state.agent_loop_stop_reason])
	var found_chat_sse_transport := false
	var found_chat_sse_completed_trace := false
	for chat_event in chat_sse_state.active_model_events():
		var chat_data: Dictionary = chat_event.get("data", {})
		if str(chat_event.get("kind", "")) == "openai_transport" and str(chat_data.get("status", "")) == "completed" and str(chat_data.get("api_mode", "")) == "chat_completions" and bool(chat_data.get("stream", false)):
			found_chat_sse_transport = true
		if str(chat_event.get("kind", "")) == "stream_trace" and str(chat_data.get("status", "")) == "received" and bool(chat_data.get("completed", false)) and str(chat_data.get("event_type", "")) == "stream.completed":
			found_chat_sse_completed_trace = true
	if not found_chat_sse_transport or not found_chat_sse_completed_trace:
		failures.append("Yuren-style Chat Completions SSE should leave completed stream trace and transport audit events")
	chat_sse_root.queue_free()
	var empty_chat_state := State.new()
	empty_chat_state.begin_agent_loop("user_prompt")
	empty_chat_state.set("is_running", true)
	var empty_chat_agent := AgentService.new()
	empty_chat_agent.setup(empty_chat_state)
	var empty_chat_root = load(MAIN_SCENE).instantiate()
	get_root().add_child(empty_chat_root)
	_prepare_headless_root(empty_chat_root, Vector2(1280.0, 720.0))
	var empty_chat_request_node := HTTPRequest.new()
	empty_chat_root.add_child(empty_chat_request_node)
	var empty_chat_controller = controller_script.new()
	empty_chat_controller.set("_root", empty_chat_root)
	empty_chat_controller.set("_state", empty_chat_state)
	empty_chat_controller.set("_agent", empty_chat_agent)
	empty_chat_controller.call("_assign_nodes")
	empty_chat_controller.call("_apply_static_chrome")
	empty_chat_controller.call("_apply_model", empty_chat_state.to_model())
	empty_chat_controller.set("_openai_request", empty_chat_request_node)
	empty_chat_controller.set("_active_openai_api_mode", "chat_completions")
	empty_chat_controller.set("_active_openai_transport_request", {
		"endpoint": "https://yurenapi.cn/v1/chat/completions",
		"api_mode": "chat_completions",
		"model": "gpt-5.5",
		"source": "user_prompt",
		"payload": {
			"model": "gpt-5.5",
			"messages": [{"role": "user", "content": "ping"}],
			"stream": true,
			"reasoning_effort": "medium",
		},
		"headers": PackedStringArray(),
	})
	empty_chat_controller.set("_openai_stream_started_at_msec", Time.get_ticks_msec())
	empty_chat_controller.call("_begin_streaming_assistant_message")
	var empty_chat_done := JSON.stringify({
		"id": "resp_empty_chat",
		"object": "chat.completion.chunk",
		"model": "gpt-5.5",
		"choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
	})
	empty_chat_controller.set("_openai_stream_buffer", "data: %s\n\n" % empty_chat_done)
	if not bool(empty_chat_controller.call("_try_finalize_openai_stream_from_buffer", "stream_disconnected")):
		failures.append("empty Chat Completions SSE should be consumed before deciding fallback/failure")
	var empty_snapshot: Dictionary = empty_chat_controller.get("_active_openai_transport_request")
	var empty_payload: Dictionary = empty_snapshot.get("payload", {})
	var empty_messages := empty_chat_state.active_messages()
	var empty_text := str(empty_messages[empty_messages.size() - 1].get("content", "")) if not empty_messages.is_empty() else ""
	if empty_chat_state.agent_loop_status == "stopped" and empty_chat_state.agent_loop_stop_reason == "final_model_response":
		failures.append("empty Chat Completions SSE should not close the Agent loop as a successful final response")
	if empty_text == "模型响应已完成。":
		failures.append("empty Chat Completions SSE should not write placeholder completion text")
	if not bool(empty_snapshot.get("compatibility_fallback_attempted", false)) or empty_payload.has("stream") or empty_payload.has("reasoning_effort"):
		failures.append("empty Chat Completions SSE should trigger a minimal plain Chat fallback")
	empty_chat_root.queue_free()
	var transcript_messages := VBoxContainer.new()
	controller.set("_messages", transcript_messages)
	controller.call("_render_active_messages")
	var rendered_event_row_count := _count_named_descendants(transcript_messages, "StreamStepRow")
	if rendered_event_row_count != 0:
		failures.append("controller should keep internal lifecycle/status rows out of the chat transcript; rendered %d rows: %s" % [rendered_event_row_count, _collect_control_label_text(transcript_messages)])
	var rendered_text := _collect_control_label_text(transcript_messages)
	var rendered_tooltips := _collect_control_tooltips(transcript_messages)
	if rendered_text.find("本地 MCP 探针") >= 0 or rendered_text.find("MCP 上下文") >= 0 or rendered_text.find("子智能体") >= 0 or rendered_text.find("目标追踪") >= 0 or rendered_text.find("OpenAI 请求已构建") >= 0 or rendered_text.find("模型响应") >= 0 or rendered_text.find("response.function_call_arguments.delta") >= 0 or rendered_text.find("非流式响应兼容收尾") >= 0 or rendered_text.find("未见完成事件") >= 0:
		failures.append("controller should keep lifecycle, OpenAI request/response, and internal stream diagnostics out of the chat transcript: %s" % rendered_text)
	if rendered_text.find("sk-partial-secret") >= 0 or rendered_tooltips.find("sk-partial-secret") >= 0:
		failures.append("tool transcript details should summarize/redact partial tool arguments instead of exposing raw secrets")
	var output_list := VBoxContainer.new()
	var bottom_output_list := VBoxContainer.new()
	var subagent_list := VBoxContainer.new()
	var source_list := HBoxContainer.new()
	var progress_section := Control.new()
	var output_section := Control.new()
	var subagents_section := Control.new()
	var sources_section := Control.new()
	controller.set("_output_list", output_list)
	controller.set("_bottom_output_list", bottom_output_list)
	controller.set("_subagent_list", subagent_list)
	controller.set("_source_list", source_list)
	controller.set("_progress_section", progress_section)
	controller.set("_output_section", output_section)
	controller.set("_subagents_section", subagents_section)
	controller.set("_sources_section", sources_section)
	controller.call("_rebuild_outputs", [])
	controller.call("_rebuild_subagents", [], state.to_model())
	controller.call("_rebuild_sources", state.to_model())
	if output_list.find_child("RightRailOutputRow", true, false) == null:
		failures.append("right inspector output section should summarize generated artifacts and changed files")
	if _collect_control_label_text(output_list).find("godex_dock_controller.gd") < 0:
		failures.append("right inspector output should show artifact/file names rather than model, command, or tool logs")
	controller.call("_rebuild_outputs", state.to_model().get("outputs", []))
	if _count_named_descendants(output_list, "RightRailOutputRow") != 1:
		failures.append("right inspector output should deduplicate state artifacts and changed-file summary rows")
	if subagent_list.find_child("RightRailSubagentRow", true, false) == null:
		failures.append("right inspector sub-agent section should summarize real sub-agent events")
	state.record_subagent_task({"id": "agent_ui_task", "name": "UI Scout", "role": "explorer", "branch": "readonly/ui", "summary": "inspect UI", "source": "subagent", "agent_kind": "subagent"})
	controller.call("_rebuild_subagents", [], state.to_model())
	var subagent_text := _collect_control_label_text(subagent_list)
	var subagent_tooltips := _collect_control_tooltips(subagent_list)
	if subagent_text.find("UI Scout") < 0 or subagent_tooltips.find("readonly/ui") < 0:
		failures.append("right inspector sub-agent rows should prefer session-backed task records: %s / %s" % [subagent_text, subagent_tooltips])
	if source_list.find_child("RightRailSourceChip", true, false) == null:
		failures.append("right inspector source section should summarize invoked external tools")
	var source_tooltips := _collect_control_tooltips(source_list)
	if source_tooltips.find("godot-dotnet-mcp") < 0:
		failures.append("right inspector sources should identify the external MCP tool provider: %s" % source_tooltips)
	if source_tooltips.find("OpenAI") >= 0 or source_tooltips.find("本地模型回放") >= 0 or source_tooltips.find("文件上下文") >= 0 or source_tooltips.find("Godot 项目摘要") >= 0:
		failures.append("right inspector sources should not list model transport, context attachments, or local replay fixtures: %s" % source_tooltips)
	if _collect_control_label_text(output_list).find("Tool response done") >= 0 or _collect_control_label_text(output_list).find("pwd") >= 0:
		failures.append("right inspector output should not treat assistant text, command logs, or tool events as artifacts")
	var progress_list := VBoxContainer.new()
	var openai_progress_section := Control.new()
	var openai_progress_state := State.new()
	openai_progress_state.set_retry_openai_request({
		"endpoint": "https://api.openai.com/v1/responses",
		"api_mode": "responses",
		"model": "gpt-5.5",
		"stage": "stream",
		"payload": {"input": []},
	}, "failed", "stream_timeout")
	controller.set("_state", openai_progress_state)
	controller.set("_progress_list", progress_list)
	controller.set("_progress_section", openai_progress_section)
	controller.call("_rebuild_progress", openai_progress_state.to_model())
	var progress_text := _right_progress_row_text(progress_list)
	var progress_tooltips := _collect_control_tooltips(progress_list)
	if not progress_text.is_empty() or progress_tooltips.find("stream_timeout") >= 0:
		failures.append("right inspector progress should not mirror OpenAI transport/retry state automatically: %s / %s" % [progress_text, progress_tooltips])
	openai_progress_state.progress_items.clear()
	openai_progress_state.progress_items.append({"title": "修复聊天正文", "detail": "assistant replies stay visible", "status": "done"})
	openai_progress_state.progress_items.append({"title": "同步设置宽度", "detail": "sidebar width persists", "status": "pending"})
	controller.call("_rebuild_progress", openai_progress_state.to_model())
	progress_text = _right_progress_row_text(progress_list)
	progress_tooltips = _collect_control_tooltips(progress_list)
	if progress_text.find("修复聊天正文") < 0 or progress_text.find("同步设置宽度") < 0 or progress_tooltips.find("sidebar width persists") < 0:
		failures.append("right inspector progress should render explicit model-controlled progress_items only: %s / %s" % [progress_text, progress_tooltips])
	var stage_controller = controller_script.new()
	var compatibility_title := str(stage_controller.call("_openai_transport_transcript_title", {
		"status": "compatibility_fallback",
		"stage": "compatibility_fallback",
		"model": "gpt-5.5",
		"endpoint": "https://yurenapi.cn/v1/chat/completions",
	}))
	if compatibility_title.find("纯文本降级") < 0 or compatibility_title.find("gpt-5.5") < 0:
		failures.append("OpenAI transport transcript should expose plain compatibility fallback stage: %s" % compatibility_title)
	var provider_probe_title := str(stage_controller.call("_openai_transport_transcript_title", {
		"status": "provider_probe_failed",
		"stage": "provider_probe",
		"source": "provider_probe",
		"model": "gpt-5.5",
		"message": "HTTP 502",
	}))
	if provider_probe_title.find("Provider 探针失败") < 0 or provider_probe_title.find("HTTP 502") < 0:
		failures.append("OpenAI transport transcript should expose provider probe failure stage: %s" % provider_probe_title)
	var diagnostic_state := State.new()
	var diagnostic_turn_id := str(diagnostic_state.get("active_turn_id"))
	diagnostic_state.append_message("user", "你是谁", {"turn_id": diagnostic_turn_id})
	diagnostic_state.append_model_event("openai_transport", {
		"status": "failed",
		"stage": "compatibility_fallback",
		"model": "gpt-5.5",
		"endpoint": "https://yurenapi.cn/v1/chat/completions",
		"status_code": 502,
		"body_preview": "upstream unavailable",
		"compatibility_fallback_attempted": true,
		"compatibility_fallback_mode": "plain_chat",
		"turn_id": diagnostic_turn_id,
	})
	var diagnostic_events := diagnostic_state.active_model_events()
	var diagnostic_transport: Dictionary = {}
	for event in diagnostic_events:
		if str(event.get("kind", "")) == "openai_transport":
			diagnostic_transport = event.get("data", {})
			break
	if diagnostic_transport.is_empty() or str(diagnostic_transport.get("stage", "")) != "compatibility_fallback" or int(diagnostic_transport.get("status_code", 0)) != 502 or str(diagnostic_transport.get("body_preview", "")).find("upstream") < 0:
		failures.append("state-backed OpenAI model event should preserve failure diagnostics: %s" % str(diagnostic_transport))
	var diagnostic_title := str(stage_controller.call("_openai_transport_transcript_title", diagnostic_transport))
	if diagnostic_title.find("纯文本降级失败") < 0 or diagnostic_title.find("HTTP 502") < 0 or diagnostic_title.find("upstream unavailable") < 0:
		failures.append("OpenAI transport audit helper should expose state-backed failure diagnostics: %s" % diagnostic_title)
	openai_progress_state.clear_retry_openai_request()
	openai_progress_state.progress_items.clear()
	controller.call("_rebuild_progress", openai_progress_state.to_model())
	if _right_progress_row_text(progress_list).find("OpenAI 状态") >= 0 or openai_progress_section.visible:
		failures.append("right inspector progress should not invent OpenAI status rows for idle chats")
	var probe_only_state := State.new()
	probe_only_state.append_model_event("local_tool_probe", {
		"status": "created",
		"tool": "godex_mcp_context",
	})
	controller.set("_state", probe_only_state)
	controller.call("_rebuild_sources", probe_only_state.to_model())
	if source_list.find_child("RightRailSourceChip", true, false) != null:
		failures.append("right inspector sources should not treat local probe bookkeeping as an invoked external tool")
	controller.set("_state", state)
	var full_root = load(MAIN_SCENE).instantiate()
	get_root().add_child(full_root)
	_prepare_headless_root(full_root, Vector2(1600.0, 720.0))
	state.active_project = "Mechoes"
	var full_controller = controller_script.new()
	full_controller.set("_root", full_root)
	full_controller.set("_state", state)
	full_controller.call("_assign_nodes")
	full_controller.call("_apply_static_chrome")
	full_controller.call("_apply_model", state.to_model())
	var full_main_title := full_root.get_node("Root/Shell/MainPanel/Main/Body/MainCenter/Welcome/Title") as Label
	if full_main_title == null or full_main_title.text != "我们应该在 Mechoes 中做些什么？":
		failures.append("empty chat title should separate the project name with spaces: %s" % (full_main_title.text if full_main_title != null else "missing"))
	var full_output_list := full_root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/OutputSection/OutputList") as VBoxContainer
	var full_subagent_list := full_root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/SubAgentsSection/SubAgentsList") as VBoxContainer
	var full_source_list := full_root.get_node("ProgressOverlayLayer/RightRail/RightRailBox/SourcesSection/SourceList") as HBoxContainer
	if full_output_list.find_child("RightRailOutputRow", true, false) == null:
		failures.append("real controller apply_model should refresh right inspector output artifact rows from model state")
	if full_subagent_list.find_child("RightRailSubagentRow", true, false) == null:
		failures.append("real controller apply_model should refresh right inspector sub-agent rows from model events")
	if full_source_list.find_child("RightRailSourceChip", true, false) == null:
		failures.append("real controller apply_model should refresh right inspector source chips from invoked external tools")
	full_root.free()
	transcript_messages.free()
	output_list.free()
	bottom_output_list.free()
	subagent_list.free()
	source_list.free()
	progress_section.free()
	output_section.free()
	subagents_section.free()
	sources_section.free()
	progress_list.free()
	openai_progress_section.free()
	transcript_messages = VBoxContainer.new()
	controller.set("_messages", transcript_messages)
	controller.set("_tool_transcript_rows", {})
	controller.set("_command_transcript_rows", {})
	var thread_state := State.new()
	thread_state.apply_sessions({
		"active_thread_id": "thread_ui_rename",
		"sessions": [
			{"id": "thread_ui_rename", "title": "Old Thread", "status": "active", "age": "now", "action": "open", "archived": false, "pinned": false, "messages": []},
			{"id": "thread_ui_pinned", "title": "Pinned Thread", "status": "idle", "age": "2m", "action": "open", "archived": false, "pinned": true, "messages": []},
			{"id": "thread_ui_idle", "title": "Another Thread", "status": "idle", "age": "1m", "action": "open", "archived": false, "pinned": false, "messages": []},
			{"id": "thread_ui_archived", "title": "Archived Thread", "status": "archived", "age": "3m", "action": "open", "archived": true, "pinned": true, "messages": []},
		],
		"approval_records": [],
	})
	var thread_root := Control.new()
	thread_root.name = "ThreadRenameRoot"
	thread_root.size = Vector2(900, 600)
	var thread_popover_layer := Control.new()
	thread_popover_layer.name = "ComposerPopoverLayer"
	thread_popover_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	thread_root.add_child(thread_popover_layer)
	var thread_list := VBoxContainer.new()
	thread_list.name = "Threads"
	thread_root.add_child(thread_list)
	controller.set("_state", thread_state)
	controller.set("_root", thread_root)
	controller.set("_composer_popover_layer", thread_popover_layer)
	controller.set("_thread_list", thread_list)
	controller.call("_rebuild_threads", thread_state.call("to_model").get("threads", []))
	if thread_list.find_child("ThreadGroup_已置顶", true, false) == null or thread_list.find_child("ThreadGroup_最近", true, false) == null:
		failures.append("thread list should group pinned and regular sessions when both are visible")
	var pinned_row := thread_list.find_child("ThreadRow_thread_ui_pinned", true, false) as PanelContainer
	var regular_row := thread_list.find_child("ThreadRow_thread_ui_rename", true, false) as PanelContainer
	var idle_row := thread_list.find_child("ThreadRow_thread_ui_idle", true, false) as PanelContainer
	if pinned_row == null or regular_row == null:
		failures.append("thread list should keep stable row names for grouped sessions")
	elif pinned_row.get_index() >= regular_row.get_index():
		failures.append("thread list should place pinned rows before regular rows")
	if regular_row != null and (not _panel_has_rounded_corners(regular_row) or _panel_background_alpha(regular_row) <= 0.0):
		failures.append("active thread row should render as a full-width rounded highlighted capsule")
	for candidate in thread_list.find_children("*", "Button", true, false):
		if str(candidate.text).find("Archived Thread") >= 0:
			failures.append("thread list grouping should keep archived sessions hidden from the active sidebar")
	var pin_button_inline := thread_list.find_child("ThreadPin_thread_ui_rename", true, false) as Button
	var archive_button_inline := thread_list.find_child("ThreadArchive_thread_ui_rename", true, false) as Button
	var age_label_inline := thread_list.find_child("ThreadAge_thread_ui_rename", true, false) as Label
	var title_button_inline := thread_list.find_child("ThreadTitle_thread_ui_rename", true, false) as Button
	var right_slot_inline := thread_list.find_child("ThreadRightSlot_thread_ui_rename", true, false) as Control
	if pin_button_inline == null or archive_button_inline == null or age_label_inline == null:
		failures.append("thread rows should expose hover pin/archive actions and an initial age label")
	else:
		var right_slot_width_before := right_slot_inline.custom_minimum_size.x if right_slot_inline != null else -1.0
		if title_button_inline == null or not title_button_inline.clip_text or title_button_inline.text_overrun_behavior != TextServer.OVERRUN_TRIM_ELLIPSIS:
			failures.append("thread row titles should clip with ellipsis so hover actions never widen the sidebar")
		if not age_label_inline.visible or pin_button_inline.visible or archive_button_inline.visible:
			failures.append("thread row actions should start hidden while the age label is visible")
		controller.call("_on_thread_row_hover_changed", regular_row, false, true)
		if age_label_inline.visible or not pin_button_inline.visible or not archive_button_inline.visible or _panel_background_alpha(regular_row) <= 0.0:
			failures.append("hovered thread rows should replace age with pin/archive actions")
		if right_slot_inline != null and absf(right_slot_inline.custom_minimum_size.x - right_slot_width_before) > 0.01:
			failures.append("thread hover actions should stay inside a fixed right slot instead of widening sidebar layout")
		archive_button_inline.emit_signal("pressed")
		if archive_button_inline.text != "确认":
			failures.append("first archive click should switch the row archive button into red confirmation mode")
		controller.call("_clear_thread_hover_states")
		if archive_button_inline.text == "确认" or pin_button_inline.visible or archive_button_inline.visible or not age_label_inline.visible:
			failures.append("leaving the thread row should reset archive confirmation and restore the initial age-only state")
		controller.call("_on_thread_row_hover_changed", regular_row, false, true)
		pin_button_inline.emit_signal("pressed")
		if not bool(thread_state.select_thread("thread_ui_rename").get("pinned", false)):
			failures.append("inline pin action should target the row session")
		controller.call("_show_thread_action_menu", "thread_ui_rename", "Old Thread", true, regular_row)
		var action_menu: PanelContainer = thread_popover_layer.find_child("ThreadActionMenu", true, false)
		if action_menu == null or not action_menu.visible:
			failures.append("thread action menu should still be available for secondary actions such as rename")
		var rename_button: Button = null
		for candidate in thread_popover_layer.find_children("*", "Button", true, false):
			if candidate.name == "ThreadAction_重命名":
				rename_button = candidate
				break
		if rename_button == null:
			failures.append("thread action menu should include a rename row")
		else:
			rename_button.emit_signal("pressed")
		var rename_panel: PanelContainer = thread_popover_layer.find_child("ThreadRenamePanel", true, false)
		var rename_input: LineEdit = thread_popover_layer.find_child("ThreadRenameInput", true, false)
		if rename_panel == null or rename_input == null or not rename_panel.visible or rename_input.text != "Old Thread":
			failures.append("thread action menu rename should open a floating rename input without changing row layout")
		controller.call("_commit_thread_rename", "Thread From UI")
		if str(thread_state.select_thread("thread_ui_rename").get("title", "")) != "Thread From UI":
			failures.append("thread rename UI should commit through the state boundary")
		if rename_panel != null and rename_panel.visible:
			failures.append("thread rename panel should close after commit")
	var title_after_empty := str(thread_state.select_thread("thread_ui_rename").get("title", ""))
	if not thread_state.rename_session("thread_ui_rename", "").is_empty() or str(thread_state.select_thread("thread_ui_rename").get("title", "")) != title_after_empty:
		failures.append("empty thread rename should remain a no-op")
	controller.set("_state", state)
	var row: Dictionary = controller.call("_create_tool_transcript_row", "tool_smoke", "system_project_state", "正在运行", "ID: tool_smoke", false)
	var panel: PanelContainer = row.get("panel", null)
	var body: Control = row.get("body", null)
	if panel == null or panel.name != "ToolTranscriptRow":
		failures.append("tool transcript row should render a named panel for MCP visual inspection")
	if panel != null and _panel_has_visible_border(panel):
		failures.append("tool transcript row should use a borderless Codex-style disclosure row")
	if panel != null and _panel_side_margin(panel) < 20:
		failures.append("tool transcript row should keep Codex-like side breathing room")
	var tool_header: PanelContainer = row.get("header", null)
	var tool_icon := tool_header.find_child("ToolTranscriptHeaderIcon", true, false) as TextureRect if tool_header != null else null
	var tool_arrow := row.get("header_arrow", null) as Label
	if tool_header == null or tool_icon == null or tool_icon.texture == null:
		failures.append("tool transcript row should use a semantic tool icon")
	if tool_header == null or _panel_style_background_alpha(tool_header) > 0.01:
		failures.append("collapsed tool transcript row header should start transparent until hover")
	if tool_header == null or int(tool_header.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0 or tool_header.mouse_filter != Control.MOUSE_FILTER_STOP:
		failures.append("tool transcript row header should be a full-width clickable disclosure control")
	if tool_arrow == null or tool_arrow.visible:
		failures.append("collapsed tool transcript row should hide the disclosure chevron until hover")
	if body == null or body.visible:
		failures.append("tool transcript row should start collapsed by default")
	var second_tool_row: Dictionary = controller.call("_create_tool_transcript_row", "tool_smoke_second", "system_project_files", "已运行", "ID: tool_smoke_second", false)
	var second_tool_body: Control = second_tool_row.get("body", null)
	controller.call("_toggle_tool_transcript_row", "tool_smoke")
	if body == null or not body.visible:
		failures.append("tool transcript row should expand when its header is toggled")
	if second_tool_body == null or second_tool_body.visible:
		failures.append("tool transcript rows should expand independently per tool call")
	var assistant_panel := controller.call("_add_message", "assistant", "assistant smoke") as PanelContainer
	if assistant_panel == null or _panel_has_visible_border(assistant_panel):
		failures.append("assistant transcript messages should render without card borders")
	if assistant_panel != null and _panel_side_margin(assistant_panel) < 20:
		failures.append("assistant transcript messages should keep Codex-like side breathing room")
	controller.call("_create_stream_step_transcript_row", "文件编辑", "正在运行")
	if transcript_messages.find_child("StreamStepRow", true, false) != null:
		failures.append("successful internal stream steps should not create chat transcript rows")
	var command_row: Dictionary = controller.call("_create_command_transcript_row", "command_smoke", "pwd", "failed", "Command: pwd", false, {
		"exit_code": 1,
		"combined_output": "res://\n[redacted-api-key]",
		"stdout": "res://",
		"stderr": "[redacted-api-key]",
		"runner_kind": "godot_os_execute_sync",
		"duration_ms": 33,
		"stderr_merged": true,
		"stderr_notice": "stderr is merged",
		"timeout_enforced": false,
	})
	var command_panel: PanelContainer = command_row.get("panel", null)
	var command_smoke_body: Control = command_row.get("body", null)
	if command_panel == null or _panel_has_visible_border(command_panel):
		failures.append("command transcript row should use a borderless Codex-style disclosure row")
	if command_panel != null and _panel_side_margin(command_panel) < 20:
		failures.append("command transcript rows should keep Codex-like side breathing room")
	var command_header: PanelContainer = command_row.get("header", null)
	var command_icon := command_header.find_child("CommandTranscriptHeaderIcon", true, false) as TextureRect if command_header != null else null
	var command_arrow := command_row.get("header_arrow", null) as Label
	if command_header == null or command_icon == null or command_icon.texture == null:
		failures.append("command transcript row should use a semantic terminal icon")
	if command_header == null or _panel_style_background_alpha(command_header) > 0.01:
		failures.append("collapsed command transcript row header should start transparent until hover")
	if command_header == null or int(command_header.size_flags_horizontal) & int(Control.SIZE_EXPAND_FILL) == 0 or command_header.mouse_filter != Control.MOUSE_FILTER_STOP:
		failures.append("command transcript row header should be a full-width clickable disclosure control")
	if command_arrow == null or command_arrow.visible:
		failures.append("collapsed command transcript row should hide the disclosure chevron until hover")
	if command_smoke_body == null or command_smoke_body.visible:
		failures.append("command transcript row should start collapsed by default")
	var second_command_row: Dictionary = controller.call("_create_command_transcript_row", "command_smoke_second", "ls", "completed", "Command: ls", false, {})
	var second_command_body: Control = second_command_row.get("body", null)
	if command_row.get("output", null) == null or transcript_messages.find_child("CommandTranscriptCombinedOutput", true, false) == null or transcript_messages.find_child("CommandTranscriptStdout", true, false) == null or transcript_messages.find_child("CommandTranscriptStderr", true, false) == null or transcript_messages.find_child("CommandTranscriptExitCode", true, false) == null or transcript_messages.find_child("CommandTranscriptRunner", true, false) == null or transcript_messages.find_child("CommandTranscriptDuration", true, false) == null:
		failures.append("command transcript row should render structured runner/duration/exit/combined/stdout/stderr output sections")
	controller.call("_show_command_transcript_row", "command_smoke", "pwd", "failed", "Command: pwd", false, {
		"exit_code": 1,
		"combined_output": "res://\n[redacted-api-key]",
		"stdout": "res://",
		"stderr": "[redacted-api-key]",
		"runner_kind": "godot_os_execute_sync",
		"duration_ms": 34,
		"stderr_merged": true,
		"stderr_notice": "stderr is merged",
		"timeout_enforced": false,
		"output_chunks": [
			{"stream": "stdout", "text": "chunk one"},
			{"stream": "stderr", "text": "chunk two"},
		],
		"timeline": [
			{"status": "running", "summary": "Runner started."},
			{"status": "failed", "summary": "Command failed."},
		],
	})
	if transcript_messages.find_child("CommandTranscriptOutputTimeline", true, false) == null or transcript_messages.find_child("CommandTranscriptOutputChunk", true, false) == null:
		failures.append("command transcript row should render streamed stdout/stderr chunk rows")
	if transcript_messages.find_child("CommandTranscriptTimeline", true, false) == null or transcript_messages.find_child("CommandTranscriptTimelineItem", true, false) == null:
		failures.append("command transcript row should render a compact status timeline")
	controller.call("_toggle_command_transcript_row", "command_smoke")
	if command_smoke_body == null or not command_smoke_body.visible:
		failures.append("command transcript row should expand when its header is toggled")
	if second_command_body == null or second_command_body.visible:
		failures.append("command transcript rows should expand independently per command run")
	if controller.call("_command_transcript_status_text", "approval_required") != "请求审批" or controller.call("_command_transcript_status_text", "timed_out") != "已超时":
		failures.append("command transcript rows should localize approval and timeout statuses")
	if controller.call("_tool_transcript_status_text", "streaming") != "正在解析" or controller.call("_tool_transcript_status_text", "succeeded") != "已运行":
		failures.append("tool transcript rows should localize streaming and succeeded statuses")
	if controller.call("_format_elapsed_duration", 0) != "0s" or controller.call("_format_elapsed_duration", 65) != "1m 05s" or controller.call("_format_elapsed_duration", 3665) != "1h 01m":
		failures.append("streaming status should format elapsed time like Codex-style running duration text")
	var streaming_status: Control = load("res://addons/godex/ui/godex_shimmer_text.gd").new()
	controller.set("_openai_stream_status", streaming_status)
	controller.set("_openai_stream_started_at_msec", Time.get_ticks_msec() - 65000)
	controller.set("_openai_stream_poll_ticks", 16)
	controller.call("_update_streaming_status")
	if streaming_status.text.find("正在思考") < 0 or streaming_status.text.find("已处理") >= 0:
		failures.append("streaming status should show only a lightweight live thinking label while running")
	streaming_status.text = "正在思考"
	controller.call("_finish_streaming_status", "已取消")
	if str(streaming_status.text).find("已取消") >= 0:
		failures.append("terminal streaming states should clear the thinking label instead of leaving status text in chat")
	streaming_status.queue_free()
	var thinking_status := controller.call("_create_streaming_thinking_status") as VBoxContainer
	var thinking_label := thinking_status.find_child("StreamingStatus", true, false) if thinking_status != null else null
	if thinking_status == null or thinking_label == null or not (thinking_label is Control) or str(thinking_label.get("text")) != "正在思考":
		failures.append("streaming thinking status should render only the reusable metallic thinking text")
	if thinking_status != null:
		thinking_status.queue_free()
	controller.set("_openai_stream_tool_calls", {})
	controller.set("_openai_stream_recorded_tool_calls", {})
	controller.call("_accumulate_openai_stream_tool_call", {
		"index": 0,
		"name": "system_project_state",
		"arguments_delta": "{\"summary\":",
	})
	controller.call("_accumulate_openai_stream_tool_call", {
		"id": "call_stream_index_stable",
		"index": 0,
		"arguments_delta": "true}",
	})
	var streamed_tool_calls: Dictionary = controller.get("_openai_stream_tool_calls")
	if streamed_tool_calls.size() != 1:
		failures.append("streamed tool-call deltas should merge by stable index instead of creating duplicate rows when the final id arrives")
	else:
		var stream_keys := streamed_tool_calls.keys()
		var streamed_record: Dictionary = streamed_tool_calls[stream_keys[0]]
		if str(streamed_record.get("id", "")) != "call_stream_index_stable" or str(streamed_record.get("arguments", "")) != "{\"summary\":true}":
			failures.append("streamed tool-call accumulation should preserve final id and joined arguments")
	controller.call("_remember_openai_stream_response_id", "resp_stream_late")
	var response_bound_tool_calls: Dictionary = controller.get("_openai_stream_tool_calls")
	if not response_bound_tool_calls.is_empty():
		var response_bound_keys := response_bound_tool_calls.keys()
		var response_bound_record: Dictionary = response_bound_tool_calls[response_bound_keys[0]]
		if str(response_bound_record.get("response_id", "")) != "resp_stream_late":
			failures.append("streamed tool-call accumulation should backfill late response ids before recording")
	var streamed_records: Array = controller.call("_record_accumulated_openai_stream_tool_calls", "stream_source")
	var tool_rows_after_record: Dictionary = controller.get("_tool_transcript_rows")
	var has_stream_batch_row := false
	for row_key in tool_rows_after_record.keys():
		if str(row_key).begins_with("tool_batch_"):
			has_stream_batch_row = true
	if streamed_records.size() != 1 or tool_rows_after_record.has("partial_index_0") or not has_stream_batch_row:
		failures.append("completed streamed tool calls should replace transient partial rows with the final Codex-style batch transcript row")
	if not streamed_records.is_empty() and str(streamed_records[0].get("response_id", "")) != "resp_stream_late":
		failures.append("recorded streamed tool calls should preserve the stream response id for Responses continuation")
	if not state.partial_tool_calls.is_empty():
		failures.append("completed streamed tool calls should clear transient partial state")
	var review_surface := PanelContainer.new()
	var review_files := VBoxContainer.new()
	var review_toggle := Button.new()
	var review_action := Button.new()
	var review_title := Label.new()
	var review_added := Label.new()
	var review_removed := Label.new()
	var composer_panel := PanelContainer.new()
	var bottom_drawer := PanelContainer.new()
	var conversation_scroll := ScrollContainer.new()
	conversation_scroll.size = Vector2(1200, 400)
	controller.set("_change_review_surface", review_surface)
	controller.set("_change_review_files", review_files)
	controller.set("_change_review_toggle", review_toggle)
	controller.set("_change_review_action", review_action)
	controller.set("_change_review_title", review_title)
	controller.set("_change_review_added", review_added)
	controller.set("_change_review_removed", review_removed)
	controller.set("_composer_panel", composer_panel)
	controller.set("_bottom_drawer", bottom_drawer)
	controller.set("_conversation_scroll", conversation_scroll)
	controller.call("_apply_change_review_model", {
		"file_count": 2,
		"added": 100,
		"removed": 7,
		"title": "文件已更改",
		"expanded": true,
		"files": [
			{"path": "addons/godex/ui/godex_dock_controller.gd", "added": 89, "removed": 7},
			{"path": "docs/很长很长很长很长很长很长/审查.md", "added": 11, "removed": 0},
		],
	})
	if not review_surface.visible or review_title.text.find("2 个文件已更改") < 0 or review_added.text != "+100" or review_removed.text != "-7":
		failures.append("change review strip should render file count and fixed delta labels")
	if review_added.custom_minimum_size.x < 56.0 or review_removed.custom_minimum_size.x < 56.0:
		failures.append("change review delta labels should keep fixed width to avoid number jitter")
	controller.call("_set_change_review_delta_label", review_added, 1000, "+", Color.GREEN)
	if review_added.text != "+1000" or int(review_added.get_meta("godex_delta_value", 0)) != 1000 or review_added.custom_minimum_size.x < 56.0:
		failures.append("change review delta labels should store animated value state without losing fixed width")
	if not review_files.visible or review_files.get_child_count() != 2:
		failures.append("expanded change review strip should render file rows")
	controller.call("_apply_conversation_column_layout")
	if int(review_surface.custom_minimum_size.x) != int(composer_panel.custom_minimum_size.x) or int(review_surface.custom_minimum_size.x) != int(bottom_drawer.custom_minimum_size.x):
		failures.append("change review strip should share the fixed conversation column width")
	if int(composer_panel.custom_minimum_size.x) < 1000:
		failures.append("wide editor layouts should keep the composer close to the Codex transcript column instead of falling back to the minimum width")
	conversation_scroll.size = Vector2(520, 400)
	controller.call("_apply_conversation_column_layout")
	if int(composer_panel.custom_minimum_size.x) > 520 or int(composer_panel.custom_minimum_size.x) < 460:
		failures.append("narrow split layouts should let the composer shrink responsively without forcing the wide transcript maximum")
	review_surface.free()
	review_files.free()
	review_toggle.free()
	review_action.free()
	review_title.free()
	review_added.free()
	review_removed.free()
	composer_panel.free()
	bottom_drawer.free()
	conversation_scroll.free()
	state.set_tool_batch_expanded(rebuild_tool_batch_id, true)
	controller.call("_render_active_messages")
	if transcript_messages.find_child("ToolBatchTranscriptRow", true, false) == null:
		failures.append("controller should rebuild Codex-style tool batch transcript rows from state transcript items")
	if transcript_messages.find_child("StreamStepRow", true, false) != null:
		failures.append("controller should not rebuild internal stream/lifecycle rows into the chat transcript")
	if transcript_messages.find_child("CommandTranscriptRow", true, false) == null:
		failures.append("controller should rebuild command transcript rows from state transcript items")
	var rebuilt_body := transcript_messages.find_child("ToolBatchTranscriptBody", true, false) as Control
	if rebuilt_body == null or not rebuilt_body.visible:
		failures.append("tool batch transcript expanded state should survive state-backed UI rebuilds")
	else:
		if rebuilt_body.find_child("ToolBatchCallRow", true, false) == null or rebuilt_body.find_child("ToolBatchCallDetail", true, false) == null:
			failures.append("expanded tool batches should render Codex-style selectable command rows with detail cards")
	var has_expanded_command_body := false
	for command_body in transcript_messages.find_children("CommandTranscriptBody", "Control", true, false):
		if command_body.visible:
			has_expanded_command_body = true
	if not has_expanded_command_body:
		failures.append("command transcript expanded state should survive state-backed UI rebuilds")
	thread_root.free()
	var search_state := State.new()
	search_state.apply_sessions({
		"active_thread_id": "search_active",
		"sessions": [
			{"id": "search_active", "title": "Current", "status": "active", "age": "now", "action": "open", "archived": false, "pinned": false, "messages": []},
			{"id": "search_target", "title": "Target Session", "status": "idle", "age": "1m", "action": "open", "archived": false, "pinned": false, "messages": [{"role": "user", "content": "needle"}]},
		],
		"approval_records": [],
	})
	var search_input := LineEdit.new()
	search_input.text = "needle"
	var search_results := VBoxContainer.new()
	controller.set("_state", search_state)
	controller.set("_search_input", search_input)
	controller.set("_search_results", search_results)
	controller.set("_root", null)
	controller.set("_main_title", null)
	controller.call("_rebuild_search_results", search_state.call("to_model"))
	var search_result_button: Button = search_results.find_child("SearchResult_search_target", true, false)
	if search_result_button == null:
		failures.append("search results should render matching sessions as openable rows")
	else:
		search_result_button.emit_signal("pressed")
		if search_state.active_thread_id != "search_target":
			failures.append("clicking a search result should open the target session")
	search_input.free()
	search_results.free()
	controller.set("_state", state)
	var archived_state := State.new()
	archived_state.apply_sessions({
		"active_thread_id": "archived_active",
		"sessions": [
			{"id": "archived_active", "title": "Current", "status": "active", "age": "now", "action": "chat", "archived": false, "pinned": false, "messages": []},
			{"id": "archived_target", "title": "Archived Target", "status": "archived", "age": "2m", "action": "open", "archived": true, "pinned": false, "messages": [{"role": "user", "content": "history needle"}]},
		],
		"approval_records": [],
	})
	var archived_search_input := LineEdit.new()
	var archived_results := VBoxContainer.new()
	var archived_thread_list := VBoxContainer.new()
	controller.set("_state", archived_state)
	controller.set("_archived_search_input", archived_search_input)
	controller.set("_archived_results", archived_results)
	controller.set("_thread_list", archived_thread_list)
	archived_search_input.text = "history"
	controller.call("_rebuild_archived_view")
	var archived_button: Button = archived_results.find_child("ArchivedResult_archived_target", true, false)
	if archived_button == null:
		failures.append("archived view should render archived session rows")
	else:
		archived_button.emit_signal("pressed")
		if archived_state.active_thread_id != "archived_target" or bool(archived_state.select_thread("archived_target").get("archived", true)):
			failures.append("clicking an archived row should restore and open the target session")
		var restored_thread_button: Button = null
		for candidate in archived_thread_list.find_children("*", "Button", true, false):
			restored_thread_button = candidate
			break
		if restored_thread_button == null:
			failures.append("restored archived sessions should return to the sidebar thread list")
	archived_search_input.text = "missing"
	controller.call("_rebuild_archived_view")
	var found_empty_match_copy := false
	for candidate in archived_results.find_children("*", "Label", true, false):
		if str(candidate.text).find("暂无匹配") >= 0:
			found_empty_match_copy = true
	if not found_empty_match_copy:
		failures.append("archived view should show a filtered empty state when no archived rows match")
	archived_search_input.free()
	archived_results.free()
	archived_thread_list.free()
	controller.set("_state", state)
	controller.set("_thread_list", null)
	var automation_state := State.new()
	automation_state.command_enabled = true
	automation_state.record_command_run({
		"id": "command_automation",
		"command": "pwd",
		"shell": "PowerShell",
		"working_directory": "res://",
		"timeout_sec": 21,
	}, "queued")
	automation_state.request_command_run_approval("command_automation")
	automation_state.set_active_goal("automation goal summary", "active", "test")
	automation_state.record_subagent_task({"id": "agent_automation", "name": "Automation Scout", "role": "explorer", "branch": "readonly/automation", "summary": "check automation", "source": "subagent", "agent_kind": "subagent"})
	automation_state.update_subagent_task("agent_automation", "done", {"result": "automation result"})
	automation_state.handoff_subagent_task_result("agent_automation", "automation handoff", "smoke")
	automation_state.record_subagent_task({"id": "agent_automation_cancel", "name": "Cancel Automation", "role": "explorer", "branch": "readonly/cancel", "status": "running", "summary": "cancel automation", "source": "subagent", "agent_kind": "subagent"})
	automation_state.cancel_subagent_task("agent_automation_cancel", "smoke")
	automation_state.record_subagent_task({"id": "agent_automation_live", "name": "Live Automation", "role": "explorer", "branch": "readonly/live", "status": "running", "summary": "live automation", "source": "subagent", "agent_kind": "subagent"})
	automation_state.record_subagent_task({"id": "agent_automation_ready", "name": "Ready Automation", "role": "explorer", "branch": "readonly/ready", "status": "done", "result": "ready handoff", "source": "subagent", "agent_kind": "subagent"})
	automation_state.record_subagent_task({"id": "agent_automation_notice", "name": "Notice Automation", "role": "explorer", "branch": "readonly/notice", "status": "running", "summary": "waiting notice", "source": "subagent", "agent_kind": "subagent"})
	automation_state.record_subagent_notification({"task_id": "agent_automation_notice", "child_thread_id": "thread_notice", "name": "Notice Automation", "status": "completed", "summary": "notice summary", "result": "notice result", "source": "smoke"})
	for i in range(30):
		automation_state.append_message("user", "automation compact message %d" % i)
	automation_state.auto_compact_active_session(24, 80000, 100000)
	automation_state.context_budget = 100
	automation_state.context_used = 65
	var automation_controller = controller_script.new()
	var automation_list := VBoxContainer.new()
	var approve_button := Button.new()
	var reject_button := Button.new()
	var request_command_button := Button.new()
	var execute_command_button := Button.new()
	var cancel_command_button := Button.new()
	var cancel_subagent_button := Button.new()
	var handoff_subagent_button := Button.new()
	var send_button := Button.new()
	var replay_continuation_button := Button.new()
	var preview_detail := Label.new()
	var preview_title := Label.new()
	automation_controller.set("_state", automation_state)
	automation_controller.set("_automation_list", automation_list)
	automation_controller.set("_approve_latest", approve_button)
	automation_controller.set("_reject_latest", reject_button)
	automation_controller.set("_request_command_approval", request_command_button)
	automation_controller.set("_execute_approved_command", execute_command_button)
	automation_controller.set("_cancel_command_run", cancel_command_button)
	automation_controller.set("_cancel_subagent_task", cancel_subagent_button)
	automation_controller.set("_handoff_subagent_result", handoff_subagent_button)
	automation_controller.set("_send_continuation", send_button)
	automation_controller.set("_replay_continuation_button", replay_continuation_button)
	automation_controller.set("_continuation_preview_detail", preview_detail)
	automation_controller.set("_continuation_preview_title", preview_title)
	automation_controller.call("_rebuild_automation_view", automation_state.call("to_model"))
	var automation_text := _collect_control_label_text(automation_list)
	if automation_text.find("命令审批") < 0 or automation_text.find("command_automation") < 0 or automation_text.find("Timeout: 21s") < 0:
		failures.append("automation view should expose pending command approval contract fields")
	if automation_text.find("命令运行") < 0 or automation_text.find("Command: pwd") < 0:
		failures.append("automation view should expose command run summary rows")
	if automation_text.find("目标追踪") < 0 or automation_text.find("automation goal summary") < 0:
		failures.append("automation view should expose active goal summary rows")
	if automation_text.find("Automation Scout") < 0 or automation_text.find("readonly/automation") < 0:
		failures.append("automation view should expose subagent task summary rows")
	if automation_text.find("结果已交接") < 0 or automation_text.find("automation handoff") < 0 or automation_text.find("取消来源: smoke") < 0:
		failures.append("automation view should expose subagent handoff and cancellation lifecycle rows")
	if automation_text.find("子智能体通知") < 0 or automation_text.find("Notice Automation") < 0 or automation_text.find("thread_notice") < 0:
		failures.append("automation view should expose subagent worker notification rows")
	if automation_text.find("子智能体关系") < 0 or automation_text.find("thread_notice") < 0 or automation_text.find("关闭") < 0:
		failures.append("automation view should expose subagent parent-child edge rows")
	if automation_text.find("上次自动压缩") < 0 or automation_text.find("移除") < 0 or automation_text.find("保留") < 0:
		failures.append("automation view should expose latest context compaction details")
	if automation_text.find("上下文窗口 · 65%") < 0 or automation_text.find("接近自动压缩阈值") < 0 or automation_text.find("压缩历史 · 自动") < 0:
		failures.append("automation view should expose context warning and compaction history rows")
	if approve_button.disabled or reject_button.disabled or approve_button.tooltip_text.find("command_automation") < 0:
		failures.append("automation approve/reject controls should target pending command approvals")
	if not request_command_button.disabled or not execute_command_button.disabled or cancel_command_button.disabled or cancel_command_button.tooltip_text.find("command_automation") < 0:
		failures.append("automation command action buttons should separate approval-required and approved command states")
	if cancel_subagent_button.disabled or cancel_subagent_button.tooltip_text.find("agent_automation_live") < 0:
		failures.append("automation should enable the subagent cancel action for the newest cancellable task")
	if handoff_subagent_button.disabled or handoff_subagent_button.tooltip_text.find("agent_automation_notice") < 0:
		failures.append("automation should enable the subagent handoff action for the newest finished task")
	if not replay_continuation_button.disabled:
		failures.append("automation local continuation replay should stay disabled until a ready continuation exists")
	automation_state.set_pending_openai_continuation({
		"success": true,
		"tool_call_id": "call_replay",
		"openai_request": {
			"endpoint": "https://api.openai.com/v1/responses",
			"api_mode": "responses",
			"model": "gpt-5.5",
			"key_source": "inline",
		},
		"transport_request": {"payload": {"input": []}},
	})
	automation_controller.call("_rebuild_automation_view", automation_state.call("to_model"))
	if replay_continuation_button.disabled or replay_continuation_button.tooltip_text.find("不发送外部 OpenAI 请求") < 0:
		failures.append("automation local continuation replay should be enabled only for ready continuations and explain that it is local")
	automation_state.clear_pending_openai_continuation("call_replay")
	automation_state.decide_command_run_approval("command_automation", "approve")
	automation_controller.call("_rebuild_automation_view", automation_state.call("to_model"))
	if not request_command_button.disabled or execute_command_button.disabled or cancel_command_button.disabled or execute_command_button.tooltip_text.find("command_automation") < 0:
		failures.append("automation command execute button should target approved command runs without consuming MCP tools")
	automation_controller.call("_cancel_next_command_run")
	if str(automation_state.next_cancellable_command_run().get("id", "")) == "command_automation":
		failures.append("automation cancel command action should cancel the current command run")
	transcript_messages.free()
	automation_list.free()
	approve_button.free()
	reject_button.free()
	request_command_button.free()
	execute_command_button.free()
	cancel_command_button.free()
	send_button.free()
	replay_continuation_button.free()
	preview_detail.free()
	preview_title.free()


func _panel_has_visible_border(panel: PanelContainer) -> bool:
	var style := panel.get_theme_stylebox("panel")
	if not (style is StyleBoxFlat):
		return false
	var flat := style as StyleBoxFlat
	return flat.border_width_left > 0 or flat.border_width_top > 0 or flat.border_width_right > 0 or flat.border_width_bottom > 0


func _panel_has_rounded_corners(panel: PanelContainer) -> bool:
	var style := panel.get_theme_stylebox("panel")
	if not (style is StyleBoxFlat):
		return false
	var flat := style as StyleBoxFlat
	return flat.get_corner_radius(CORNER_TOP_LEFT) > 0 and flat.get_corner_radius(CORNER_TOP_RIGHT) > 0 and flat.get_corner_radius(CORNER_BOTTOM_LEFT) > 0 and flat.get_corner_radius(CORNER_BOTTOM_RIGHT) > 0


func _panel_background_alpha(panel: PanelContainer) -> float:
	var style := panel.get_theme_stylebox("panel")
	if not (style is StyleBoxFlat):
		return 0.0
	var flat := style as StyleBoxFlat
	return flat.bg_color.a


func _button_style_has_visible_border(button: Button, style_name: String) -> bool:
	if button == null:
		return false
	var style := button.get_theme_stylebox(style_name)
	if not (style is StyleBoxFlat):
		return false
	var flat := style as StyleBoxFlat
	var has_width := flat.border_width_left > 0 or flat.border_width_top > 0 or flat.border_width_right > 0 or flat.border_width_bottom > 0
	return has_width and flat.border_color.a > 0.01


func _button_style_background_alpha(button: Button, style_name: String) -> float:
	if button == null:
		return 0.0
	var style := button.get_theme_stylebox(style_name)
	if not (style is StyleBoxFlat):
		return 0.0
	var flat := style as StyleBoxFlat
	return flat.bg_color.a


func _panel_style_background_alpha(panel: PanelContainer) -> float:
	if panel == null:
		return 0.0
	var style := panel.get_theme_stylebox("panel")
	if not (style is StyleBoxFlat):
		return 0.0
	var flat := style as StyleBoxFlat
	return flat.bg_color.a


func _panel_side_margin(panel: PanelContainer) -> float:
	var style := panel.get_theme_stylebox("panel")
	if not (style is StyleBoxFlat):
		return 0.0
	var flat := style as StyleBoxFlat
	return min(flat.content_margin_left, flat.content_margin_right)


func _right_progress_row_text(root: Node) -> String:
	var parts: Array[String] = []
	for node in root.find_children("RightRailProgressText", "Label", true, false):
		parts.append(str(node.text))
	return " ".join(parts)


func _count_named_descendants(root: Node, node_name: String) -> int:
	var count := 0
	for child in root.get_children():
		var child_name := str(child.name)
		if child_name == node_name or child_name.find(node_name) >= 0:
			count += 1
		count += _count_named_descendants(child, node_name)
	return count


func _collect_control_label_text(root: Node) -> String:
	var parts: Array[String] = []
	for node in root.find_children("*", "Label", true, false):
		parts.append(str(node.text))
	for node in root.find_children("*", "Button", true, false):
		parts.append(str(node.text))
	return "\n".join(parts)


func _collect_control_tooltips(root: Node) -> String:
	var parts: Array[String] = []
	for node in root.find_children("*", "Control", true, false):
		parts.append(str(node.tooltip_text))
	return "\n".join(parts)


func _check_agent_turn_audit(failures: Array[String]) -> void:
	var state := State.new()
	state.mcp_enabled = false
	state.skills_enabled = false
	state.command_enabled = true
	state.command_shell = "PowerShell"
	state.reasoning_effort = "high"
	state.set_model("gpt-5.4-mini")
	var agent := AgentService.new()
	agent.setup(state)
	var result: Dictionary = agent.prepare_turn("Inspect current scene")
	var audit: Dictionary = result.get("audit", {})
	if not audit.has("payload_mode") or audit.get("payload_mode", "") != "responses":
		failures.append("agent audit should include payload mode")
	if bool(audit.get("api_config", {}).get("ready", true)):
		failures.append("agent audit should report missing API key as not ready")
	if audit.get("openai_request", {}).get("error", "") != "missing_api_key":
		failures.append("agent audit should include OpenAI request readiness error")
	if result.get("payload", {}).get("reasoning", {}).get("effort", "") != "high":
		failures.append("agent turn payload should include selected reasoning effort")
	if audit.get("openai_request", {}).get("reasoning_effort", "") != "high":
		failures.append("agent audit should expose selected reasoning effort")
	if result.get("payload", {}).get("model", "") != "gpt-5.4-mini":
		failures.append("agent turn payload should use selected model")
	if Array(audit.get("openai_request", {}).get("headers", [])).any(func(header): return str(header).contains("Bearer sk-")):
		failures.append("agent audit must not expose raw bearer headers")
	if audit.get("model_event", {}).is_empty() or state.active_model_events().is_empty():
		failures.append("agent turn should record an OpenAI model event")
	var model_event_data: Dictionary = audit.get("model_event", {}).get("data", {})
	if model_event_data.get("reasoning_effort", "") != "high":
		failures.append("agent model event should expose selected reasoning effort")
	if not audit.get("mcp_request", {}).is_empty():
		failures.append("agent audit should omit MCP request when MCP is disabled")
	if not audit.get("subagent", {}).is_empty():
		failures.append("agent audit should omit subagent when skills are disabled")
	if not bool(audit.get("command_request", {}).get("enabled", false)):
		failures.append("agent audit should reflect enabled command capability")
	if not audit.get("command_run", {}).is_empty():
		failures.append("agent audit should not create fake command transcript rows before a model command request exists")
	var goal_state := State.new()
	goal_state.api_key = "sk-local-test-token"
	goal_state.mcp_enabled = false
	goal_state.skills_enabled = false
	goal_state.set_active_goal("ship active goal audit", "active", "test")
	var goal_agent := AgentService.new()
	goal_agent.setup(goal_state)
	var goal_result: Dictionary = goal_agent.prepare_turn("Continue")
	var goal_audit: Dictionary = goal_result.get("audit", {}).get("goal", {})
	if str(goal_result.get("payload", {}).get("instructions", "")).find("ship active goal audit") < 0 or str(goal_audit.get("objective", "")) != "ship active goal audit":
		failures.append("agent turn should inject the active session goal into instructions and audit")
	var yuren_state := State.new()
	yuren_state.provider = "yurenapi"
	yuren_state.base_url = "https://yurenapi.cn/v1"
	yuren_state.api_key_env = "YUREN_API_KEY"
	yuren_state.api_key = "sk-local-test-token"
	yuren_state.api_mode = "responses"
	yuren_state.model = "gpt-5.5"
	yuren_state.mcp_enabled = false
	yuren_state.skills_enabled = false
	var yuren_agent := AgentService.new()
	yuren_agent.setup(yuren_state)
	var yuren_result: Dictionary = yuren_agent.prepare_turn("Say pong")
	var yuren_payload: Dictionary = yuren_result.get("payload", {})
	var yuren_transport: Dictionary = yuren_result.get("transport_request", {})
	if yuren_state.api_mode != "chat_completions" or yuren_payload.has("input") or not yuren_payload.has("messages"):
		failures.append("agent turn should normalize stale Yuren state into a Chat Completions payload")
	if yuren_transport.get("api_mode", "") != "chat_completions" or yuren_transport.get("endpoint", "") != "https://yurenapi.cn/v1/chat/completions":
		failures.append("agent turn should send Yuren requests to the Chat Completions endpoint")
	var plan_state := State.new()
	plan_state.api_key = "sk-local-test-token"
	plan_state.mcp_enabled = true
	plan_state.skills_enabled = false
	plan_state.plan_mode_enabled = true
	plan_state.reasoning_effort = "medium"
	var plan_agent := AgentService.new()
	plan_agent.setup(plan_state)
	var plan_result: Dictionary = plan_agent.prepare_turn("Plan the implementation without editing files")
	var plan_payload: Dictionary = plan_result.get("payload", {})
	var plan_audit: Dictionary = plan_result.get("audit", {})
	if plan_payload.has("tools") and not (plan_payload.get("tools", []) as Array).is_empty():
		failures.append("plan mode request payload should omit OpenAI tool schemas")
	if str(plan_payload.get("instructions", "")).find("Plan Mode is active") < 0:
		failures.append("plan mode request payload should include the Codex plan-mode contract")
	if not bool(plan_audit.get("plan_mode", {}).get("enabled", false)) or bool(plan_audit.get("plan_mode", {}).get("tools_enabled", true)):
		failures.append("plan mode audit should record that tools are disabled")
	if not bool(plan_audit.get("openai_request", {}).get("plan_mode", false)) or int(plan_audit.get("openai_request", {}).get("tool_count", -1)) != 0:
		failures.append("plan mode OpenAI request audit should expose plan mode with zero tools")
	var found_plan_transcript_item := false
	var found_plan_request_audit := false
	for item in plan_state.active_transcript_items():
		if str(item.get("kind", "")) == "plan_mode" and bool(item.get("enabled", false)):
			found_plan_transcript_item = true
	for event in plan_state.active_model_events():
		if str(event.get("kind", "")) == "openai_request" and bool(event.get("data", {}).get("plan_mode", false)) and int(event.get("data", {}).get("tool_count", -1)) == 0:
			found_plan_request_audit = true
	if found_plan_transcript_item or not found_plan_request_audit:
		failures.append("plan mode should stay out of chat transcript items while the OpenAI request audit stays in model events")
	var guide_state := State.new()
	guide_state.api_key = "sk-local-test-token"
	guide_state.mcp_enabled = false
	guide_state.skills_enabled = false
	var guide_record: Dictionary = guide_state.record_pending_guide_instruction("prefer concise test-first steps", "test")
	var guide_agent := AgentService.new()
	guide_agent.setup(guide_state)
	var guide_result: Dictionary = guide_agent.prepare_turn("Continue with the task")
	var guide_payload: Dictionary = guide_result.get("payload", {})
	var guide_audit: Dictionary = guide_result.get("audit", {}).get("guide_instruction", {})
	if str(guide_payload.get("instructions", "")).find("Composer Guide Instruction") < 0 or str(guide_payload.get("instructions", "")).find("prefer concise test-first steps") < 0:
		failures.append("pending guide instructions should be injected into the next OpenAI instructions")
	if str(guide_audit.get("status", "")) != "submitted" or str(guide_audit.get("id", "")) != str(guide_record.get("id", "")):
		failures.append("agent audit should mark the pending guide instruction as submitted for the turn")
	if not guide_state.active_pending_guide_instruction().is_empty():
		failures.append("submitted guide instructions should not remain pending for future turns")
	var guide_transcript := guide_state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "pending_steer" and str(item.get("status", "")) == "submitted")
	if not guide_transcript.is_empty():
		failures.append("submitted guide instructions should stay out of chat transcript items")
	var cancel_guide_state := State.new()
	cancel_guide_state.api_key = "sk-local-test-token"
	cancel_guide_state.mcp_enabled = false
	cancel_guide_state.skills_enabled = false
	var cancelled_guide: Dictionary = cancel_guide_state.record_pending_guide_instruction("cancel before next turn", "test")
	var cancelled_result: Dictionary = cancel_guide_state.cancel_pending_steer(str(cancelled_guide.get("id", "")), "test")
	if str(cancelled_result.get("status", "")) != "cancelled" or str(cancelled_result.get("cancelled_by", "")) != "test":
		failures.append("pending guide instructions should support cancellation with source attribution")
	var cancel_guide_agent := AgentService.new()
	cancel_guide_agent.setup(cancel_guide_state)
	var cancel_guide_result: Dictionary = cancel_guide_agent.prepare_turn("Continue without cancelled guidance")
	if str(cancel_guide_result.get("payload", {}).get("instructions", "")).find("cancel before next turn") >= 0:
		failures.append("cancelled guide instructions should not be injected into the next Agent turn")
	var compact_state := State.new()
	compact_state.api_key = "sk-local-test-token"
	compact_state.mcp_enabled = false
	compact_state.skills_enabled = false
	compact_state.context_budget = 100
	compact_state.context_used = 80
	for i in range(30):
		compact_state.append_message("user" if i % 2 == 0 else "assistant", "auto compact source message %d with enough text to summarize" % i)
	var compact_agent := AgentService.new()
	compact_agent.setup(compact_state)
	compact_agent.set_messages(compact_state.active_messages())
	var compact_result: Dictionary = compact_agent.prepare_turn("Continue after automatic compaction")
	var compact_audit: Dictionary = compact_result.get("audit", {}).get("compression", {})
	if not bool(compact_audit.get("compressed", false)) or str(compact_audit.get("source", "")) != "auto_prepare_turn":
		failures.append("agent turn should audit automatic context compaction when token use crosses the threshold")
	var compact_last: Dictionary = compact_state.last_compaction_preview()
	if str(compact_last.get("source", "")) != "auto_prepare_turn" or int(compact_last.get("removed_count", 0)) <= 0:
		failures.append("automatic context compaction should persist a session summary record")
	var compact_messages := compact_state.active_messages()
	if compact_messages.is_empty() or str(compact_messages[0].get("content", "")).find("Prior conversation summary") < 0:
		failures.append("automatic context compaction should write the summary back to the active session")
	var compact_input: Array = compact_result.get("payload", {}).get("input", [])
	var compact_payload_text := ""
	if not compact_input.is_empty() and compact_input[0] is Dictionary:
		var compact_content: Array = compact_input[0].get("content", [])
		if not compact_content.is_empty() and compact_content[0] is Dictionary:
			compact_payload_text = str(compact_content[0].get("text", ""))
	if compact_payload_text.find("Prior conversation summary") < 0:
		failures.append("automatic context compaction should use the compacted message history in the OpenAI payload")
	var parsed: Dictionary = agent.handle_model_response("responses", JSON.stringify({
		"output": [
			{"type": "message", "content": [{"type": "output_text", "text": "Need context."}]},
			{"type": "function_call", "call_id": "call_pending", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
		],
	}))
	if not bool(parsed.get("success", false)) or parsed.get("tool_call_records", []).size() != 1:
		failures.append("agent model response should record parsed tool calls")
	if state.pending_tool_calls().is_empty():
		failures.append("parsed tool calls should be pending in state")
	state.begin_agent_loop("response_tool_calls")
	var http_state := State.new()
	http_state.api_key = "sk-local-test-token"
	var http_agent := AgentService.new()
	http_agent.setup(http_state)
	var http_result: Dictionary = http_agent.handle_model_http_result("responses", 200, JSON.stringify({
		"output": [
			{"type": "message", "content": [{"type": "output_text", "text": "HTTP done."}]},
			{"type": "function_call", "call_id": "call_http", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
		],
	}))
	if not bool(http_result.get("success", false)) or http_result.get("text", "") != "HTTP done.":
		failures.append("agent HTTP result should parse successful OpenAI text")
	if http_state.pending_tool_calls().size() != 1:
		failures.append("agent HTTP result should record parsed tool calls")
	var http_error: Dictionary = http_agent.handle_model_http_result("responses", 401, JSON.stringify({"error": {"type": "invalid_api_key", "message": "Bad key"}}))
	if bool(http_error.get("success", true)) or http_error.get("error", "") != "invalid_api_key":
		failures.append("agent HTTP result should normalize OpenAI API errors")
	var probe_state := State.new()
	var probe_agent := AgentService.new()
	probe_agent.setup(probe_state)
	var probe: Dictionary = probe_agent.inject_mcp_context_probe("summary", 20)
	if not bool(probe.get("success", false)) or probe_state.pending_tool_calls().size() != 1:
		failures.append("agent should inject a local MCP context probe tool call")
	var probe_steps := probe_state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "stream_step")
	var found_probe_audit := false
	for probe_event in probe_state.active_model_events():
		if str(probe_event.get("kind", "")) == "local_tool_probe":
			found_probe_audit = true
	if not probe_steps.is_empty() or not found_probe_audit or not probe_state.progress_items.is_empty() or not probe_state.outputs.is_empty():
		failures.append("local MCP context probe should stay out of chat transcript while preserving model-event audit")
	var replay_state := State.new()
	replay_state.set_model("gpt-5.4-mini")
	var replay_agent := AgentService.new()
	replay_agent.setup(replay_state)
	var replay: Dictionary = replay_agent.inject_model_response_replay()
	if not bool(replay.get("success", false)) or replay.get("tool_call_records", []).size() != 1:
		failures.append("local model replay should parse a Responses-compatible fixture into one pending tool call")
	if replay_state.pending_tool_calls().size() != 1:
		failures.append("local model replay should leave a normal pending tool call for the MCP execution path")
	var found_replay_transport := false
	var found_replay_response := false
	for replay_event in replay_state.active_model_events():
		var replay_data: Dictionary = replay_event.get("data", {})
		if str(replay_event.get("kind", "")) == "openai_transport" and str(replay_data.get("source", "")) == "local_model_replay" and str(replay_data.get("status", "")) == "replayed":
			found_replay_transport = true
		if str(replay_event.get("kind", "")) == "openai_response" and str(replay_data.get("source", "")) == "local_model_replay" and int(replay_data.get("tool_call_count", 0)) == 1:
			found_replay_response = true
	if not found_replay_transport or not found_replay_response:
		failures.append("local model replay should be marked as replayed transport/response events instead of looking like a live OpenAI request")
	var replay_transcript_text := JSON.stringify(replay_state.active_transcript_items())
	if replay_transcript_text.find("transport_request") >= 0 or replay_transcript_text.find("Authorization") >= 0 or replay_transcript_text.find("Bearer") >= 0:
		failures.append("local model replay transcript items must not expose transport requests or headers")
	state.approval_mode = "请求批准"
	var blocked: Dictionary = agent.dispatch_next_tool_call()
	if not bool(blocked.get("blocked", false)) or state.latest_pending_approval().is_empty():
		failures.append("pending tool call dispatch should require approval in review mode")
	state.decide_latest_approval("approve")
	var approved_after_checkpoint: Dictionary = agent.dispatch_next_tool_call()
	if not bool(approved_after_checkpoint.get("success", false)):
		failures.append("approved tool call checkpoint should allow dispatch")
	parsed = agent.handle_model_response("responses", JSON.stringify({
		"output": [
			{"type": "function_call", "call_id": "call_assisted", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
		],
	}))
	state.approval_mode = "替我审批"
	var approved: Dictionary = agent.dispatch_next_tool_call()
	if not bool(approved.get("success", false)):
		failures.append("pending tool call dispatch should auto-approve in assisted mode")
	state.record_agent_loop_step("mcp_tool_dispatch", str(approved.get("tool_call_id", "")))
	if state.agent_loop_step_count < 1:
		failures.append("agent loop should retain dispatch step count")
	if approved.get("request", {}).get("tool", "") != "system_project_state":
		failures.append("godex_mcp_context dispatch should map to system_project_state")
	if approved.get("request", {}).get("body", {}).get("method", "") != "tools/call":
		failures.append("dispatch-ready tool call should include tools/call transport body")
	var started: Dictionary = agent.begin_tool_call_execution(str(approved.get("tool_call_id", "")))
	if not bool(started.get("success", false)):
		failures.append("dispatch-ready tool call should transition to executing")
	var response: Dictionary = agent.handle_mcp_tool_call_response(str(approved.get("tool_call_id", "")), JSON.stringify({
		"result": {
			"content": [
				{"type": "text", "text": JSON.stringify({"data": {"ok": true}, "message": "tool ok", "success": true})},
			],
			"isError": false,
		},
	}))
	if not bool(response.get("success", false)):
		failures.append("mcp tool call response should complete successfully")
	var completed := false
	for event in state.active_model_events():
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) == str(approved.get("tool_call_id", "")) and str(data.get("status", "")) == "succeeded":
			completed = true
	if not completed:
		failures.append("executed tool call should update original tool-call event")
	if not state.pending_tool_calls().is_empty():
		failures.append("dispatch-ready tool call should no longer be pending")
	var missing_key_state := State.new()
	var missing_key_agent := AgentService.new()
	missing_key_agent.setup(missing_key_state)
	missing_key_agent.handle_model_response("responses", JSON.stringify({
		"output": [
			{"type": "function_call", "call_id": "call_missing_key", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
		],
	}))
	missing_key_state.approval_mode = "替我审批"
	var missing_key_dispatch: Dictionary = missing_key_agent.dispatch_next_tool_call()
	missing_key_agent.begin_tool_call_execution(str(missing_key_dispatch.get("tool_call_id", "")))
	missing_key_agent.handle_mcp_tool_call_response(str(missing_key_dispatch.get("tool_call_id", "")), JSON.stringify({
		"result": {
			"content": [
				{"type": "text", "text": JSON.stringify({"data": {"ok": true}, "message": "tool ok", "success": true})},
			],
			"isError": false,
		},
	}))
	var continuation_blocked: Dictionary = missing_key_agent.build_tool_result_continuation(str(missing_key_dispatch.get("tool_call_id", "")))
	if not bool(continuation_blocked.get("blocked", false)) or continuation_blocked.get("error", "") != "missing_api_key":
		failures.append("tool result continuation should block cleanly when API key is missing")
	var missing_key_tool_id := str(missing_key_dispatch.get("tool_call_id", ""))
	var missing_key_tool_rows := missing_key_state.active_transcript_items().filter(func(item): return str(item.get("kind", "")) == "tool_batch")
	if missing_key_tool_rows.size() != 1 or str(missing_key_tool_rows[0].get("status", "")) != "completed":
		failures.append("blocked OpenAI continuation should not turn the completed tool call into a failed transcript row")
	var missing_key_tool_events := missing_key_state.active_model_events().filter(func(event): return str(event.get("kind", "")) == "tool_call" and str(event.get("data", {}).get("id", "")) == missing_key_tool_id)
	if missing_key_tool_events.size() != 1 or str(missing_key_tool_events[0].get("data", {}).get("status", "")) != "succeeded" or str(missing_key_tool_events[0].get("data", {}).get("continuation", {}).get("status", "")) != "blocked":
		failures.append("tool call status should remain terminal while continuation state is stored separately")
	var continuation_state := State.new()
	continuation_state.api_key = "sk-local-test-token"
	continuation_state.reasoning_effort = "xhigh"
	var continuation_agent := AgentService.new()
	continuation_agent.setup(continuation_state)
	var continuation_parsed: Dictionary = continuation_agent.handle_model_response("responses", JSON.stringify({
		"id": "resp_continue",
		"output": [
			{"type": "function_call", "call_id": "call_continue", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
		],
	}))
	if not bool(continuation_parsed.get("success", false)):
		failures.append("continuation fixture should parse initial tool call")
	continuation_state.approval_mode = "替我审批"
	var continuation_dispatch: Dictionary = continuation_agent.dispatch_next_tool_call()
	continuation_agent.begin_tool_call_execution(str(continuation_dispatch.get("tool_call_id", "")))
	continuation_agent.handle_mcp_tool_call_response(str(continuation_dispatch.get("tool_call_id", "")), JSON.stringify({
		"result": {
			"content": [
				{"type": "text", "text": JSON.stringify({"data": {"ok": true}, "message": "tool ok", "success": true})},
			],
			"isError": false,
		},
	}))
	var continuation: Dictionary = continuation_agent.build_tool_result_continuation(str(continuation_dispatch.get("tool_call_id", "")))
	if not bool(continuation.get("success", false)) or continuation.get("transport_request", {}).get("payload", {}).is_empty():
		failures.append("completed tool result should build a ready OpenAI continuation request")
	var continuation_payload: Dictionary = continuation.get("transport_request", {}).get("payload", {})
	if continuation_payload.get("reasoning", {}).get("effort", "") != "xhigh":
		failures.append("tool result continuation payload should include selected reasoning effort")
	if continuation_payload.get("previous_response_id", "") != "resp_continue":
		failures.append("tool result continuation payload should use the parsed provider response id")
	var continuation_input: Array = continuation_payload.get("input", [])
	if continuation_input.size() != 1 or continuation_input[0].get("type", "") != "function_call_output":
		failures.append("tool result continuation payload should send only function_call_output with previous_response_id")
	var continuation_transport: Dictionary = continuation.get("transport_request", {})
	if continuation_transport.get("source", "") != "tool_result_continuation" or continuation_transport.get("tool_call_id", "") != "call_continue" or continuation_transport.get("previous_response_id", "") != "resp_continue":
		failures.append("tool result continuation transport should retain source, tool call, and previous response audit metadata")
	if int(continuation_transport.get("payload_input_count", 0)) != 1 or str(continuation_transport.get("payload_fingerprint", "")).is_empty():
		failures.append("tool result continuation transport should expose safe payload audit metadata")
	if continuation.get("openai_request", {}).get("reasoning_effort", "") != "xhigh":
		failures.append("tool result continuation audit should expose selected reasoning effort")
	if continuation_state.pending_openai_continuation.is_empty() or continuation_state.pending_openai_continuation.get("status", "") != "ready":
		failures.append("ready tool result continuation should be retained for explicit sending")
	if continuation_state.pending_openai_continuation.get("previous_response_id", "") != "resp_continue":
		failures.append("ready tool result continuation should retain previous_response_id for replay/send")
	if not bool(continuation.get("auto_send_allowed", false)):
		failures.append("tool result continuation should auto-send in assisted approval mode")
	continuation_state.approval_mode = "请求批准"
	var manual_send_continuation: Dictionary = continuation_agent.build_tool_result_continuation(str(continuation_dispatch.get("tool_call_id", "")))
	if bool(manual_send_continuation.get("auto_send_allowed", true)):
		failures.append("tool result continuation should wait for explicit approval in request-approval mode")
	continuation_state.approval_mode = "完全访问权限"
	var auto_send_continuation: Dictionary = continuation_agent.build_tool_result_continuation(str(continuation_dispatch.get("tool_call_id", "")))
	if not bool(auto_send_continuation.get("auto_send_allowed", false)):
		failures.append("tool result continuation should allow auto-send in full access mode")
	if str(continuation.get("openai_request", {}).get("headers", [])).contains("sk-local-test-token"):
		failures.append("tool result continuation audit should not expose raw API key")
	continuation_state.approval_mode = "替我审批"
	var replayable_continuation: Dictionary = continuation_agent.build_tool_result_continuation(str(continuation_dispatch.get("tool_call_id", "")))
	if not bool(replayable_continuation.get("success", false)):
		failures.append("ready continuation should be rebuilt before local replay")
	var replayed_continuation: Dictionary = continuation_agent.replay_pending_tool_result_continuation()
	if not bool(replayed_continuation.get("success", false)) or str(replayed_continuation.get("text", "")).find("本地续跑回放") < 0:
		failures.append("local tool-result continuation replay should produce a final assistant message")
	if not continuation_state.pending_openai_continuation.is_empty():
		failures.append("local continuation replay should clear the pending continuation slot")
	var continuation_messages := continuation_state.active_messages()
	var final_message: Dictionary = continuation_messages[-1] if not continuation_messages.is_empty() and continuation_messages[-1] is Dictionary else {}
	if str(final_message.get("content", "")).find("本地续跑回放") < 0 or str(final_message.get("turn_id", "")).is_empty():
		failures.append("local continuation replay should persist the final assistant response in the active turn")
	if continuation_state.agent_loop_status != "stopped" or continuation_state.agent_loop_stop_reason != "local_continuation_replay_final":
		failures.append("local continuation replay should close the Agent loop with a diagnostic stop reason")
	var found_local_continuation_transport := false
	var found_local_continuation_response := false
	for continuation_event in continuation_state.active_model_events():
		var continuation_data: Dictionary = continuation_event.get("data", {})
		if str(continuation_event.get("kind", "")) == "openai_transport" and str(continuation_data.get("source", "")) == "local_tool_result_continuation_replay":
			found_local_continuation_transport = str(continuation_data.get("status", "")) == "replayed" and int(continuation_data.get("continuation_input_count", 0)) > 0
		if str(continuation_event.get("kind", "")) == "openai_response" and str(continuation_data.get("source", "")) == "local_tool_result_continuation_replay":
			found_local_continuation_response = int(continuation_data.get("tool_call_count", -1)) == 0
	if not found_local_continuation_transport or not found_local_continuation_response:
		failures.append("local continuation replay should be auditable as replayed transport and final response events")
	var chat_continuation_state := State.new()
	chat_continuation_state.provider = "yurenapi"
	chat_continuation_state.base_url = "https://api.openai.com"
	chat_continuation_state.api_key_env = "OPENAI_API_KEY"
	chat_continuation_state.api_key = "sk-local-test-token"
	chat_continuation_state.model = "gpt-5.5"
	chat_continuation_state.api_mode = "responses"
	chat_continuation_state.reasoning_effort = "high"
	chat_continuation_state.append_message("user", "请读取项目概要")
	var chat_continuation_agent := AgentService.new()
	chat_continuation_agent.setup(chat_continuation_state)
	var chat_tool_response: Dictionary = chat_continuation_agent.handle_model_response("chat_completions", JSON.stringify({
		"id": "chat_continue",
		"choices": [
			{
				"message": {
					"content": "",
					"tool_calls": [
						{"id": "chat_call_continue", "type": "function", "function": {"name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"}},
					],
				},
			},
		],
	}))
	if not bool(chat_tool_response.get("success", false)):
		failures.append("chat continuation fixture should parse initial Chat Completions tool call")
	chat_continuation_state.approval_mode = "替我审批"
	var chat_continuation_dispatch: Dictionary = chat_continuation_agent.dispatch_next_tool_call()
	chat_continuation_agent.begin_tool_call_execution(str(chat_continuation_dispatch.get("tool_call_id", "")))
	chat_continuation_agent.handle_mcp_tool_call_response(str(chat_continuation_dispatch.get("tool_call_id", "")), JSON.stringify({
		"result": {
			"content": [
				{"type": "text", "text": JSON.stringify({"data": {"ok": true}, "message": "chat tool ok", "success": true})},
			],
			"isError": false,
		},
	}))
	var chat_continuation: Dictionary = chat_continuation_agent.build_tool_result_continuation(str(chat_continuation_dispatch.get("tool_call_id", "")))
	var chat_continuation_transport: Dictionary = chat_continuation.get("transport_request", {})
	var chat_continuation_payload: Dictionary = chat_continuation_transport.get("payload", {})
	var chat_continuation_messages: Array = chat_continuation_payload.get("messages", [])
	if not bool(chat_continuation.get("success", false)):
		failures.append("completed Yuren Chat tool result should build a ready continuation request")
	if chat_continuation_state.api_mode != "chat_completions" or chat_continuation_transport.get("api_mode", "") != "chat_completions" or chat_continuation_transport.get("endpoint", "") != "https://yurenapi.cn/v1/chat/completions":
		failures.append("Yuren tool result continuation should normalize stale runtime state to Chat Completions")
	if chat_continuation_payload.has("input") or not chat_continuation_payload.has("messages"):
		failures.append("Yuren tool result continuation payload should use Chat messages rather than Responses input")
	if chat_continuation_payload.get("reasoning_effort", "") != "high":
		failures.append("Yuren Chat continuation should retain selected reasoning effort")
	if chat_continuation_messages.size() < 4 or chat_continuation_messages[-1].get("role", "") != "tool" or chat_continuation_messages[-1].get("tool_call_id", "") != "chat_call_continue":
		failures.append("Yuren Chat continuation should append the tool result in Chat Completions tool-message form: %s" % JSON.stringify(chat_continuation_messages))
	var blocked_state := State.new()
	blocked_state.api_key = "sk-local-test-token"
	var blocked_agent := AgentService.new()
	blocked_agent.setup(blocked_state)
	blocked_agent.handle_model_response("responses", JSON.stringify({
		"output": [
			{"type": "function_call", "call_id": "call_done", "name": "godex_mcp_context", "arguments": "{\"scope\":\"summary\"}"},
			{"type": "function_call", "call_id": "call_waiting", "name": "godex_read_file", "arguments": "{\"path\":\"res://project.godot\"}"},
		],
	}))
	blocked_state.approval_mode = "替我审批"
	var done_dispatch: Dictionary = blocked_agent.dispatch_tool_call("call_done")
	blocked_agent.begin_tool_call_execution(str(done_dispatch.get("tool_call_id", "")))
	blocked_agent.handle_mcp_tool_call_response(str(done_dispatch.get("tool_call_id", "")), JSON.stringify({
		"result": {
			"content": [{"type": "text", "text": JSON.stringify({"message": "first ok", "success": true})}],
			"isError": false,
		},
	}))
	var unresolved_block: Dictionary = blocked_agent.build_tool_result_continuation("call_done")
	if not bool(unresolved_block.get("blocked", false)) or unresolved_block.get("error", "") != "unresolved_tool_calls":
		failures.append("continuation should wait for other unresolved tool calls")


func _check_command_capability(failures: Array[String]) -> void:
	var commands := CommandCapability.new()
	var request := commands.build_request("git reset --hard")
	if not bool(request.get("blocked", false)):
		failures.append("dangerous command must be blocked")
	var remove_request := commands.build_request("remove-item -recurse foo")
	if not bool(remove_request.get("blocked", false)):
		failures.append("dangerous PowerShell command variants must be blocked")
	var encoded_request := commands.build_request("PowerShell -EncodedCommand deadbeef")
	if not bool(encoded_request.get("blocked", false)):
		failures.append("encoded shell commands must be blocked")
	var safe_request := commands.build_request("pwd")
	if bool(safe_request.get("enabled", true)) or not bool(safe_request.get("requires_approval", false)) or safe_request.has("result"):
		failures.append("command requests should remain disabled by default and only prepare approval metadata")
	commands.shell = "PowerShell -NoProfile"
	var shell_request := commands.build_request("pwd")
	if not bool(shell_request.get("blocked", false)) or str(shell_request.get("blocked_reason", "")) != "unsupported_shell":
		failures.append("command requests should reject unsupported shell strings")
	commands.shell = "pwsh"
	commands.working_directory = "../../"
	var cwd_request := commands.build_request("pwd")
	if not bool(cwd_request.get("blocked", false)) or str(cwd_request.get("blocked_reason", "")) != "unsafe_working_directory":
		failures.append("command requests should reject working directory escape attempts")
	commands.working_directory = "res://"
	var normalized_request := commands.build_request("pwd")
	if bool(normalized_request.get("blocked", false)) or str(normalized_request.get("shell", "")) != "pwsh":
		failures.append("command requests should accept known shell aliases and project-local working directories")
	commands.timeout_sec = 999
	if int(commands.build_request("pwd").get("timeout_sec", 0)) != 300:
		failures.append("command request timeout should be clamped to the safety maximum")

	var settings_state := State.new()
	settings_state.apply_settings({"command_working_directory": "res://addons", "command_timeout_sec": 120, "plan_mode_enabled": true, "sidebar_width": 468.0})
	var settings := settings_state.to_settings()
	if str(settings.get("command_working_directory", "")) != "res://addons" or int(settings.get("command_timeout_sec", 0)) != 120:
		failures.append("command working directory and timeout settings should persist")
	if not bool(settings.get("plan_mode_enabled", false)):
		failures.append("plan mode setting should persist with the rest of agent settings")
	if absf(float(settings.get("sidebar_width", 0.0)) - 468.0) > 0.01:
		failures.append("sidebar width should persist with the rest of local UI settings")
	settings_state.apply_settings({"sidebar_width": 999.0})
	if absf(float(settings_state.sidebar_width) - 520.0) > 0.01:
		failures.append("sidebar width should clamp to a safe maximum")
	settings_state.apply_settings({"sidebar_width": 12.0})
	if absf(float(settings_state.sidebar_width) - 240.0) > 0.01:
		failures.append("sidebar width should clamp to a safe minimum")


func _fake_command_runner(command_run: Dictionary) -> Dictionary:
	_fake_command_runner_calls += 1
	return {
		"exit_code": 0,
		"stdout": str(command_run.get("working_directory", "")),
		"stderr": "",
		"combined_output": str(command_run.get("working_directory", "")),
		"runner_kind": "custom_callable",
		"duration_ms": 7,
		"timeout_enforced": false,
	}
