@tool
class_name GodexDockController
extends RefCounted

const GodexTheme = preload("res://addons/godex/ui/godex_theme.gd")
const OpenAIRequestBuilder = preload("res://addons/godex/core/openai_request_builder.gd")
const GodexShimmerText = preload("res://addons/godex/ui/godex_shimmer_text.gd")
const GodexSkillRegistry = preload("res://addons/godex/core/godex_skill_registry.gd")

const MAIN := "Root/Shell/MainPanel/Main"
const STATE_SCRIPT_PATH := "res://addons/godex/core/godex_state.gd"
const AGENT_SCRIPT_PATH := "res://addons/godex/core/agent_service.gd"
const SETTINGS_STORE_SCRIPT_PATH := "res://addons/godex/core/settings_store.gd"
const SESSION_STORE_SCRIPT_PATH := "res://addons/godex/core/session_store.gd"
const MENU_ICON_SCRIPT_PATH := "res://addons/godex/ui/godex_menu_icon.gd"
const SIDEBAR_MIN_WIDTH := 240.0
const SIDEBAR_MAX_WIDTH := 520.0
const APPROVAL_POPOVER_WIDTH := 574.0
const APPROVAL_POPOVER_MIN_WIDTH := 320.0
const APPROVAL_POPOVER_ROW_HEIGHT := 68.0
const APPROVAL_POPOVER_TITLE_HEIGHT := 31.0
const APPROVAL_POPOVER_VERTICAL_PADDING := 24.0
const APPROVAL_POPOVER_ROW_GAP := 4.0
const APPROVAL_POPOVER_TITLE_GAP := 6.0
const ADD_CONTEXT_POPOVER_WIDTH := 300.0
const ADD_CONTEXT_POPOVER_MIN_WIDTH := 260.0
const ADD_CONTEXT_POPOVER_ROW_HEIGHT := 48.0
const ADD_CONTEXT_POPOVER_TITLE_HEIGHT := 0.0
const ADD_CONTEXT_POPOVER_VERTICAL_PADDING := 20.0
const ADD_CONTEXT_POPOVER_ROW_GAP := 2.0
const ADD_CONTEXT_POPOVER_TITLE_GAP := 0.0
const MODEL_POPOVER_WIDTH := 300.0
const MODEL_POPOVER_MIN_WIDTH := 240.0
const MODEL_POPOVER_ROW_HEIGHT := 36.0
const MODEL_POPOVER_TITLE_HEIGHT := 28.0
const MODEL_POPOVER_VERTICAL_PADDING := 24.0
const MODEL_POPOVER_ROW_GAP := 2.0
const MODEL_POPOVER_TITLE_GAP := 4.0
const REASONING_POPOVER_WIDTH := 260.0
const REASONING_POPOVER_MIN_WIDTH := 230.0
const PICKER_SUBMENU_GAP := 0.0
const PICKER_SUBMENU_TOP_OFFSET := 70.0
const COMPOSER_POPOVER_MARGIN := 12.0
const LAYOUT_MENU_WIDTH := 360.0
const LAYOUT_MENU_MIN_WIDTH := 300.0
const LAYOUT_MENU_MARGIN := 12.0
const LAYOUT_MENU_ACTION_HEIGHT := 48.0
const LAYOUT_MENU_RECOMMENDED_HEIGHT := 36.0
const TRANSCRIPT_COLUMN_WIDTH := 1040.0
const TRANSCRIPT_COLUMN_MIN_WIDTH := 640.0
const TRANSCRIPT_COLUMN_NARROW_MIN_WIDTH := 460.0
const TRANSCRIPT_COLUMN_SIDE_MARGIN := 56.0
const ARCHIVED_COLUMN_WIDTH := 840.0
const TRANSCRIPT_CONTENT_SIDE_PADDING := 24
const USER_MESSAGE_BUBBLE_MIN_WIDTH := 112.0
const USER_MESSAGE_BUBBLE_MAX_WIDTH := 640.0
const USER_MESSAGE_BUBBLE_HORIZONTAL_PADDING := 32.0
const COMPOSER_QUEUE_ROW_HEIGHT := 48.0
const RIGHT_RAIL_OVERLAY_WIDTH := 420.0
const RIGHT_RAIL_OVERLAY_GAP := 28.0
const OPENAI_STREAM_IDLE_TIMEOUT_SEC := 75
const OPENAI_STREAM_TOTAL_TIMEOUT_SEC := 300
const OPENAI_ERROR_BODY_PREVIEW_LENGTH := 360
const COMMAND_EXECUTION_OUTPUT_MERGED_NOTICE := "stderr is merged into stdout by Godot OS.execute(read_stderr=true)."
const BOTTOM_TERMINAL_ERROR_COLOR := Color(0.94, 0.36, 0.36)
const SETTINGS_PANEL_PATH := "Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel"
const SETTINGS_BOX_PATH := "Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox"
const SETTINGS_CONTENT_PATH := "Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsContentWrap/SettingsScroll/SettingsContentCenter/SettingsContent"
const SETTINGS_RAIL_PATH := "Root/Shell/MainPanel/Main/Body/MainCenter/SettingsPanel/SettingsBox/SettingsRail"
const SETTINGS_RAIL_SIDEBAR_PATH := "Root/Shell/SidebarPanel/Sidebar/SettingsRail"

var _plugin: EditorPlugin
var _root: Control
var _state: RefCounted
var _agent: RefCounted
var _settings_store: RefCounted
var _session_store: RefCounted
var _editor_theme: Theme
var _fallback_icon_texture: Texture2D

var _thread_list: VBoxContainer
var _thread_rename_panel: PanelContainer
var _thread_rename_input: LineEdit
var _thread_rename_target_id := ""
var _thread_action_menu: PanelContainer
var _thread_action_menu_list: VBoxContainer
var _thread_action_menu_target_id := ""
var _thread_action_menu_target_title := ""
var _thread_action_menu_target_pinned := false
var _thread_archive_confirm_id := ""
var _thread_archive_notice: PanelContainer
var _thread_archive_notice_label: Label
var _thread_archive_notice_settings: Button
var _thread_archive_notice_timer: Timer
var _main_title: Label
var _welcome_panel: VBoxContainer
var _conversation_scroll: ScrollContainer
var _messages: VBoxContainer
var _conversation_tween: Tween
var _change_review_surface: PanelContainer
var _change_review_toggle: Button
var _change_review_title: Label
var _change_review_added: Label
var _change_review_removed: Label
var _change_review_action: Button
var _change_review_files: VBoxContainer
var _search_panel: PanelContainer
var _search_input: LineEdit
var _search_results: VBoxContainer
var _plugins_panel: PanelContainer
var _mcp_panel: PanelContainer
var _mcp_summary: Label
var _mcp_tool_list: VBoxContainer
var _automation_panel: PanelContainer
var _automation_list: VBoxContainer
var _archived_panel: PanelContainer
var _archived_search_input: LineEdit
var _archived_results: VBoxContainer
var _continuation_preview: PanelContainer
var _continuation_preview_title: Label
var _continuation_preview_detail: Label
var _approve_latest: Button
var _reject_latest: Button
var _inject_probe_tool: Button
var _replay_model_response_button: Button
var _provider_probe_button: Button
var _execute_next_tool: Button
var _request_command_approval: Button
var _execute_approved_command: Button
var _cancel_command_run: Button
var _cancel_subagent_task: Button
var _handoff_subagent_result: Button
var _send_continuation: Button
var _replay_continuation_button: Button
var _composer_panel: PanelContainer
var _composer_queue_surface: PanelContainer
var _composer_queue_list: VBoxContainer
var _composer_popover_layer: Control
var _composer: TextEdit
var _slash_command_panel: PanelContainer
var _slash_command_title: Label
var _slash_command_scroll: ScrollContainer
var _slash_command_list: VBoxContainer
var _slash_command_suggestions: Array = []
var _slash_command_selected_index := -1
var _slash_command_query := ""
var _approval_button: Button
var _approval_mode_panel: Control
var _approval_mode_surface: PanelContainer
var _approval_mode_box: VBoxContainer
var _approval_mode_list: VBoxContainer
var _add_context_panel: Control
var _add_context_surface: PanelContainer
var _add_context_box: VBoxContainer
var _add_context_list: VBoxContainer
var _goal_button: Button
var _add_context_button: Button
var _send_button: Button
var _composer_reference_bar: HBoxContainer
var _selection_action_panel: PanelContainer
var _selection_action_bar: HBoxContainer
var _selection_action_label: Label
var _selection_source_panel: PanelContainer
var _selection_source_label: RichTextLabel
var _selection_source_role := ""
var _selection_text := ""
var _send_button_hint_panel: PanelContainer
var _send_button_hint_box: VBoxContainer
var _send_button_hovered := false
var _send_button_hint_hold_until_msec := 0
var _send_button_hover_watch: Timer
var _message_hover_watch: Timer
var _message_hover_panels: Array[PanelContainer] = []
var _ide_context_button: Button
var _model_button: Button
var _reasoning_button: Button
var _model_picker_panel: Control
var _model_picker_surface: PanelContainer
var _model_picker_list: VBoxContainer
var _model_submenu_anchor: Control
var _model_submenu_hover_watch: Timer
var _thread_hover_watch: Timer
var _reasoning_picker_panel: Control
var _reasoning_picker_surface: PanelContainer
var _reasoning_picker_list: VBoxContainer
var _progress_list: VBoxContainer
var _output_list: VBoxContainer
var _subagent_list: VBoxContainer
var _source_list: HBoxContainer
var _progress_section: Control
var _output_section: Control
var _subagents_section: Control
var _sources_section: Control
var _settings_panel: Control
var _settings_scroll: ScrollContainer
var _settings_search: LineEdit
var _settings_no_results: Label
var _active_settings_category := "general"
var _last_non_archived_settings_category := "general"
var _settings_rail_original_parent: Node
var _settings_rail_original_index := -1
var _provider: OptionButton
var _base_url: LineEdit
var _api_key: LineEdit
var _api_key_env: LineEdit
var _api_status: Label
var _model: OptionButton
var _api_mode: OptionButton
var _sidebar_panel: PanelContainer
var _sidebar_resize_handle: Control
var _bottom_drawer: PanelContainer
var _bottom_output_list: VBoxContainer
var _bottom_output_scroll: ScrollContainer
var _control_panel_toggle: Button
var _bottom_panel_toggle: Button
var _side_panel_toggle: Button
var _layout_menu_panel: Control
var _layout_menu_surface: PanelContainer
var _layout_menu_actions: VBoxContainer
var _layout_menu_recommended: VBoxContainer
var _refresh_godex: Button
var _mcp_server_row: PanelContainer
var _mcp_server_status_icon: Label
var _mcp_server_name: Label
var _mcp_server_detail: Label
var _mcp_endpoint: LineEdit
var _mcp_refresh_tools: Button
var _mcp_server_settings: Button
var _mcp_add_server: Button
var _skills_enabled: CheckBox
var _skill_manager_search: LineEdit
var _skill_manager_list: VBoxContainer
var _skill_registry: GodexSkillRegistry
var _mcp_enabled: CheckBox
var _compression_enabled: CheckBox
var _command_enabled: CheckBox
var _command_shell: LineEdit
var _capability_preview: VBoxContainer
var _nav_buttons: Dictionary = {}
var _nav_hovered: Dictionary = {}
var _active_view := "chat"
var _active_sidebar_surface := "thread"
var _mcp_tools_request: HTTPRequest
var _mcp_tool_call_request: HTTPRequest
var _openai_request: HTTPRequest
var _provider_probe_request: HTTPRequest
var _openai_stream_client: HTTPClient
var _openai_stream_timer: Timer
var _active_tool_call_id := ""
var _active_provider_probe_request: Dictionary = {}
var _active_openai_api_mode := ""
var _active_openai_transport_request: Dictionary = {}
var _openai_cancel_requested := false
var _openai_stream_buffer := ""
var _openai_stream_message_index := -1
var _openai_stream_text := ""
var _openai_stream_label: RichTextLabel
var _openai_stream_status: GodexShimmerText
var _openai_stream_status_row: VBoxContainer
var _openai_stream_steps: VBoxContainer
var _openai_stream_started := false
var _openai_stream_completed := false
var _openai_stream_started_at_msec := 0
var _openai_stream_last_activity_msec := 0
var _openai_stream_poll_ticks := 0
var _openai_stream_event_count := 0
var _openai_stream_text_delta_total := 0
var _openai_stream_tool_delta_count := 0
var _openai_stream_tool_call_count := 0
var _openai_stream_last_event_type := ""
var _openai_stream_completed_event_seen := false
var _openai_stream_response_id := ""
var _openai_stream_http_error_code := 0
var _openai_stream_http_error_body := ""
var _openai_stream_tool_calls: Dictionary = {}
var _openai_stream_recorded_tool_calls: Dictionary = {}
var _tool_transcript_rows: Dictionary = {}
var _command_transcript_rows: Dictionary = {}
var _ide_context_hovered := false
var _goal_hovered := false
var _bottom_panel_visible := false
var _sidebar_visible := true
var _right_inspector_visible := true
var _sidebar_resizing := false
var _sidebar_resize_start_x := 0.0
var _sidebar_resize_start_width := 310.0


func setup(plugin: EditorPlugin, root: Control) -> void:
	_plugin = plugin
	_root = root
	_editor_theme = plugin.get_editor_interface().get_editor_theme()
	_create_services()
	_state.call("refresh_active_project_from_settings")
	var loaded_settings: Dictionary = _settings_store.call("load_settings")
	_state.call("apply_settings", loaded_settings)
	if bool(_state.get("settings_migrated")):
		_settings_store.call("save_settings", _state.call("to_settings"))
	_state.call("apply_sessions", _session_store.call("load_sessions"))
	_agent.call("setup", _state)
	_assign_nodes()
	_apply_static_chrome()
	_apply_sidebar_width(float(_state.get("sidebar_width")))
	_bind_events()
	_setup_transport_nodes()
	_configure_send_button_hover_watch()
	_configure_message_hover_watch()
	_ensure_composer_reference_bar()
	_ensure_selection_action_panel()
	_render_active_messages()
	if _state.mcp_enabled:
		_start_mcp_tool_discovery()
	_apply_model(_state.call("to_model"))


func _create_services() -> void:
	_state = _new_service(STATE_SCRIPT_PATH)
	_agent = _new_service(AGENT_SCRIPT_PATH)
	_settings_store = _new_service(SETTINGS_STORE_SCRIPT_PATH)
	_session_store = _new_service(SESSION_STORE_SCRIPT_PATH)


func _new_service(path: String) -> RefCounted:
	var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if script == null:
		push_error("[Godex] Failed to load service script: %s" % path)
		return RefCounted.new()
	return script.new()


func _assign_nodes() -> void:
	_sidebar_panel = _node("Root/Shell/SidebarPanel")
	_sidebar_resize_handle = _node("Root/Shell/SidebarResizeHandle")
	_thread_list = _node("Root/Shell/SidebarPanel/Sidebar/ThreadScroll/Threads")
	_main_title = _node("%s/Body/MainCenter/Welcome/Title" % MAIN)
	_welcome_panel = _node("%s/Body/MainCenter/Welcome" % MAIN)
	_conversation_scroll = _node("%s/Body/MainCenter/ConversationScroll" % MAIN)
	_messages = _node("%s/Body/MainCenter/ConversationScroll/TranscriptCenter/Messages" % MAIN)
	_bottom_drawer = _node("%s/Body/MainCenter/BottomDrawer" % MAIN)
	_bottom_output_scroll = _node("%s/Body/MainCenter/BottomDrawer/BottomDrawerBox/BottomDrawerScroll" % MAIN)
	_bottom_output_list = _node("%s/Body/MainCenter/BottomDrawer/BottomDrawerBox/BottomDrawerScroll/BottomDrawerList" % MAIN)
	_change_review_surface = _node("%s/Body/MainCenter/ChangeReviewSurface" % MAIN)
	_change_review_toggle = _node("%s/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewStrip/ChangeReviewToggle" % MAIN)
	_change_review_title = _node("%s/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewStrip/ChangeReviewTitle" % MAIN)
	_change_review_added = _node("%s/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewStrip/ChangeReviewAdded" % MAIN)
	_change_review_removed = _node("%s/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewStrip/ChangeReviewRemoved" % MAIN)
	_change_review_action = _node("%s/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewStrip/ChangeReviewAction" % MAIN)
	_change_review_files = _node("%s/Body/MainCenter/ChangeReviewSurface/ChangeReviewBox/ChangeReviewFiles" % MAIN)
	_search_panel = _node("%s/Body/MainCenter/SearchPanel" % MAIN)
	_search_input = _node("%s/Body/MainCenter/SearchPanel/SearchBox/SearchInput" % MAIN)
	_search_results = _node("%s/Body/MainCenter/SearchPanel/SearchBox/SearchResults" % MAIN)
	_plugins_panel = _node("%s/Body/MainCenter/PluginsPanel" % MAIN)
	_mcp_panel = _node("%s/Body/MainCenter/McpPanel" % MAIN)
	_mcp_summary = _node("%s/Body/MainCenter/McpPanel/McpBox/McpSummary" % MAIN)
	_mcp_tool_list = _node("%s/Body/MainCenter/McpPanel/McpBox/McpToolList" % MAIN)
	_automation_panel = _node("%s/Body/MainCenter/AutomationPanel" % MAIN)
	_archived_panel = _node("%s/Body/MainCenter/ArchivedPanel" % MAIN)
	_archived_search_input = _node("%s/Body/MainCenter/ArchivedPanel/ArchivedBox/ArchivedSearchInput" % MAIN)
	_archived_results = _node("%s/Body/MainCenter/ArchivedPanel/ArchivedBox/ArchivedResults" % MAIN)
	_continuation_preview = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ContinuationPreview" % MAIN)
	_continuation_preview_title = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ContinuationPreview/ContinuationPreviewBox/ContinuationPreviewTitle" % MAIN)
	_continuation_preview_detail = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ContinuationPreview/ContinuationPreviewBox/ContinuationPreviewDetail" % MAIN)
	_approve_latest = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ApproveLatest" % MAIN)
	_reject_latest = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/RejectLatest" % MAIN)
	_inject_probe_tool = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/InjectProbeTool" % MAIN)
	_replay_model_response_button = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ReplayModelResponse" % MAIN)
	_provider_probe_button = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ProviderProbe" % MAIN)
	_execute_next_tool = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ExecuteNextTool" % MAIN)
	_request_command_approval = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/CommandActions/RequestCommandApproval" % MAIN)
	_execute_approved_command = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/CommandActions/ExecuteApprovedCommand" % MAIN)
	_cancel_command_run = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/CommandActions/CancelCommandRun" % MAIN)
	_cancel_subagent_task = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/SubagentActions/CancelSubagentTask" % MAIN)
	_handoff_subagent_result = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/SubagentActions/HandoffSubagentResult" % MAIN)
	_send_continuation = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/SendContinuation" % MAIN)
	_replay_continuation_button = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/ApprovalActions/ReplayContinuation" % MAIN)
	_automation_list = _node("%s/Body/MainCenter/AutomationPanel/AutomationBox/AutomationList" % MAIN)
	_composer_panel = _node("%s/Body/MainCenter/ComposerPanel" % MAIN)
	_ensure_composer_queue_surface()
	_composer_popover_layer = _root.get_node_or_null("ComposerPopoverLayer")
	_composer = _node("%s/Body/MainCenter/ComposerPanel/ComposerBox/Prompt" % MAIN)
	var composer_popover_root := "ComposerPopoverLayer" if _composer_popover_layer != null else "%s/Body/MainCenter/ComposerPanel/ComposerBox" % MAIN
	_slash_command_panel = _node("%s/SlashCommandPanel" % composer_popover_root)
	_slash_command_title = _node("%s/SlashCommandPanel/SlashCommandBox/SlashCommandTitle" % composer_popover_root)
	_slash_command_scroll = _node("%s/SlashCommandPanel/SlashCommandBox/SlashCommandScroll" % composer_popover_root)
	_slash_command_list = _node("%s/SlashCommandPanel/SlashCommandBox/SlashCommandScroll/SlashCommandList" % composer_popover_root)
	_add_context_button = _node("%s/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/AddContext" % MAIN)
	_send_button = _node("%s/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/SendButton" % MAIN)
	_add_context_panel = _node("%s/AddContextPanel" % composer_popover_root)
	_add_context_surface = _add_context_panel.get_node_or_null("AddContextSurface") if _add_context_panel != null else null
	var add_context_root := "%s/AddContextPanel/AddContextSurface" % composer_popover_root if _add_context_surface != null else "%s/AddContextPanel" % composer_popover_root
	_add_context_box = _node("%s/AddContextBox" % add_context_root)
	_add_context_list = _node("%s/AddContextBox/AddContextList" % add_context_root)
	_approval_button = _node("%s/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ApprovalButton" % MAIN)
	_approval_mode_panel = _node("%s/ApprovalModePanel" % composer_popover_root)
	_approval_mode_surface = _approval_mode_panel.get_node_or_null("ApprovalModeSurface") if _approval_mode_panel != null else null
	var approval_content_root := "%s/ApprovalModePanel/ApprovalModeSurface" % composer_popover_root if _approval_mode_surface != null else "%s/ApprovalModePanel" % composer_popover_root
	_approval_mode_box = _node("%s/ApprovalModeBox" % approval_content_root)
	_approval_mode_list = _node("%s/ApprovalModeBox/ApprovalModeList" % approval_content_root)
	_goal_button = _node("%s/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/GoalButton" % MAIN)
	_model_button = _node("%s/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ModelButton" % MAIN)
	_reasoning_button = _node("%s/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/ReasoningButton" % MAIN)
	_model_picker_panel = _node("%s/ModelPickerPanel" % composer_popover_root)
	_model_picker_surface = _model_picker_panel.get_node_or_null("ModelPickerSurface") if _model_picker_panel != null else null
	var model_picker_root := "%s/ModelPickerPanel/ModelPickerSurface" % composer_popover_root if _model_picker_surface != null else "%s/ModelPickerPanel" % composer_popover_root
	_model_picker_list = _node("%s/ModelPickerBox/ModelPickerList" % model_picker_root)
	if _model_picker_panel != null:
		_model_picker_panel.mouse_exited.connect(_schedule_model_submenu_close)
	_reasoning_picker_panel = _node("%s/ReasoningPickerPanel" % composer_popover_root)
	_reasoning_picker_surface = _reasoning_picker_panel.get_node_or_null("ReasoningPickerSurface") if _reasoning_picker_panel != null else null
	var reasoning_picker_root := "%s/ReasoningPickerPanel/ReasoningPickerSurface" % composer_popover_root if _reasoning_picker_surface != null else "%s/ReasoningPickerPanel" % composer_popover_root
	_reasoning_picker_list = _node("%s/ReasoningPickerBox/ReasoningPickerList" % reasoning_picker_root)
	_ide_context_button = _node("%s/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls/IdeContextButton" % MAIN)
	_progress_section = _node("ProgressOverlayLayer/RightRail/RightRailBox/ProgressSection")
	_output_section = _node("ProgressOverlayLayer/RightRail/RightRailBox/OutputSection")
	_subagents_section = _node("ProgressOverlayLayer/RightRail/RightRailBox/SubAgentsSection")
	_sources_section = _node("ProgressOverlayLayer/RightRail/RightRailBox/SourcesSection")
	_progress_list = _node("ProgressOverlayLayer/RightRail/RightRailBox/ProgressSection/ProgressList")
	_output_list = _node("ProgressOverlayLayer/RightRail/RightRailBox/OutputSection/OutputList")
	_subagent_list = _node("ProgressOverlayLayer/RightRail/RightRailBox/SubAgentsSection/SubAgentsList")
	_source_list = _node("ProgressOverlayLayer/RightRail/RightRailBox/SourcesSection/SourceList")
	_control_panel_toggle = _node("%s/Header/HeaderLayoutControls/ControlPanelToggle" % MAIN)
	_bottom_panel_toggle = _node("%s/Header/HeaderLayoutControls/BottomPanelToggle" % MAIN)
	_side_panel_toggle = _node("%s/Header/HeaderLayoutControls/SidePanelToggle" % MAIN)
	_layout_menu_panel = _node("ProgressOverlayLayer/LayoutMenuPanel")
	_layout_menu_surface = _node("ProgressOverlayLayer/LayoutMenuPanel/LayoutMenuSurface")
	_layout_menu_actions = _node("ProgressOverlayLayer/LayoutMenuPanel/LayoutMenuSurface/LayoutMenuBox/LayoutMenuActions")
	_layout_menu_recommended = _node("ProgressOverlayLayer/LayoutMenuPanel/LayoutMenuSurface/LayoutMenuBox/LayoutMenuRecommended")
	_refresh_godex = _node("%s/Header/RefreshGodex" % MAIN)
	_settings_panel = _node(SETTINGS_BOX_PATH)
	_settings_scroll = _node("%s/SettingsContentWrap/SettingsScroll" % SETTINGS_BOX_PATH)
	_settings_search = _settings_rail_child("SettingsSearch") as LineEdit
	_settings_no_results = _node("%s/SettingsNoResults" % SETTINGS_CONTENT_PATH)
	_provider = _node("%s/ProviderCard/ProviderSettings/ProviderRow/Provider" % SETTINGS_CONTENT_PATH)
	_base_url = _node("%s/ProviderCard/ProviderSettings/BaseUrlRow/BaseUrl" % SETTINGS_CONTENT_PATH)
	_api_key = _node("%s/ProviderCard/ProviderSettings/ApiKeyRow/ApiKey" % SETTINGS_CONTENT_PATH)
	_api_key_env = _node("%s/ProviderCard/ProviderSettings/ApiKeyEnvRow/ApiKeyEnv" % SETTINGS_CONTENT_PATH)
	_api_status = _node("%s/ProviderCard/ProviderSettings/ApiStatus" % SETTINGS_CONTENT_PATH)
	_model = _node("%s/ProviderCard/ProviderSettings/ModelRow/Model" % SETTINGS_CONTENT_PATH)
	_api_mode = _node("%s/IntegrationCard/IntegrationSettings/ApiModeRow/ApiMode" % SETTINGS_CONTENT_PATH)
	_mcp_server_row = _node("%s/IntegrationCard/IntegrationSettings/McpServerRow" % SETTINGS_CONTENT_PATH)
	_mcp_server_status_icon = _node("%s/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/ServerStatusIcon" % SETTINGS_CONTENT_PATH)
	_mcp_server_name = _node("%s/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/EndpointCopy/EndpointLabel" % SETTINGS_CONTENT_PATH)
	_mcp_server_detail = _node("%s/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/EndpointCopy/EndpointHelp" % SETTINGS_CONTENT_PATH)
	_mcp_endpoint = _node("%s/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/Endpoint" % SETTINGS_CONTENT_PATH)
	_mcp_enabled = _node("%s/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/McpEnabled" % SETTINGS_CONTENT_PATH)
	_mcp_refresh_tools = _node("%s/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/RefreshMcpTools" % SETTINGS_CONTENT_PATH)
	_mcp_server_settings = _node("%s/IntegrationCard/IntegrationSettings/McpServerRow/McpServerContent/McpServerSettings" % SETTINGS_CONTENT_PATH)
	_mcp_add_server = _node("%s/IntegrationCard/IntegrationSettings/AddMcpServer" % SETTINGS_CONTENT_PATH)
	_skills_enabled = _node("%s/FeatureCard/FeatureToggles/SkillsEnabled" % SETTINGS_CONTENT_PATH)
	_skill_manager_search = _node("%s/SkillManagerSearch" % SETTINGS_CONTENT_PATH)
	_skill_manager_list = _node("%s/SkillManagerList" % SETTINGS_CONTENT_PATH)
	_compression_enabled = _node("%s/FeatureCard/FeatureToggles/CompressionEnabled" % SETTINGS_CONTENT_PATH)
	_command_enabled = _node("%s/FeatureCard/FeatureToggles/CommandEnabled" % SETTINGS_CONTENT_PATH)
	_command_shell = _node("%s/CodingCard/CodingSettings/CommandShellRow/CommandShell" % SETTINGS_CONTENT_PATH)
	_capability_preview = _node("%s/CapabilityPreview" % SETTINGS_CONTENT_PATH)
	_nav_buttons = {
		"chat": _node("Root/Shell/SidebarPanel/Sidebar/TopNav/NewChat"),
		"search": _node("Root/Shell/SidebarPanel/Sidebar/TopNav/Search"),
		"plugins": _node("Root/Shell/SidebarPanel/Sidebar/TopNav/Plugins"),
		"automation": _node("Root/Shell/SidebarPanel/Sidebar/TopNav/Automation"),
		"settings": _node("Root/Shell/SidebarPanel/Sidebar/Footer/Settings"),
	}


func _node(path: String):
	return _root.get_node(path)


func _ensure_composer_queue_surface() -> void:
	if _root == null or _composer_panel == null:
		return
	var main_center := _root.get_node_or_null("%s/Body/MainCenter" % MAIN) as VBoxContainer
	if main_center == null:
		return
	_composer_queue_surface = main_center.get_node_or_null("ComposerQueueSurface") as PanelContainer
	if _composer_queue_surface == null:
		_composer_queue_surface = PanelContainer.new()
		_composer_queue_surface.name = "ComposerQueueSurface"
		_composer_queue_surface.visible = false
		_composer_queue_surface.clip_contents = true
		_composer_queue_surface.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var margin := MarginContainer.new()
		margin.name = "ComposerQueueMargin"
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		_composer_queue_list = VBoxContainer.new()
		_composer_queue_list.name = "ComposerQueueList"
		_composer_queue_list.add_theme_constant_override("separation", 0)
		margin.add_child(_composer_queue_list)
		_composer_queue_surface.add_child(margin)
		main_center.add_child(_composer_queue_surface)
		var anchor := _change_review_surface if _change_review_surface != null else _composer_panel
		main_center.move_child(_composer_queue_surface, max(0, anchor.get_index()))
	else:
		_composer_queue_list = _composer_queue_surface.get_node_or_null("ComposerQueueMargin/ComposerQueueList") as VBoxContainer
		var anchor := _change_review_surface if _change_review_surface != null else _composer_panel
		main_center.move_child(_composer_queue_surface, max(0, anchor.get_index()))


func _connect_settings_category_button(button_name: String, category: String) -> void:
	var button := _settings_rail_child(button_name) as Button
	if button != null:
		button.pressed.connect(_on_settings_category_pressed.bind(category))


func _bind_events() -> void:
	_node("Root/Shell/SidebarPanel/Sidebar/TopNav/NewChat").pressed.connect(_on_new_chat)
	_node("Root/Shell/SidebarPanel/Sidebar/TopNav/Search").pressed.connect(_show_search)
	_node("Root/Shell/SidebarPanel/Sidebar/TopNav/Plugins").pressed.connect(_show_plugins)
	_node("Root/Shell/SidebarPanel/Sidebar/TopNav/Automation").pressed.connect(_show_automation)
	if _sidebar_resize_handle != null:
		_sidebar_resize_handle.mouse_default_cursor_shape = Control.CURSOR_HSIZE
		_sidebar_resize_handle.gui_input.connect(_on_sidebar_resize_handle_input)
	for key in _nav_buttons.keys():
		var button: Button = _nav_buttons[key]
		if button == null:
			continue
		button.mouse_entered.connect(_on_nav_button_hover_changed.bind(key, true))
		button.mouse_exited.connect(_on_nav_button_hover_changed.bind(key, false))
	_node("Root/Shell/SidebarPanel/Sidebar/Footer/Settings").pressed.connect(_show_settings)
	var thread_scroll := _thread_list.get_parent() as ScrollContainer
	if thread_scroll != null:
		thread_scroll.mouse_exited.connect(_clear_thread_hover_states)
	_node("Root/Shell/SidebarPanel/Sidebar").mouse_exited.connect(_clear_thread_hover_states)
	_send_button.pressed.connect(_on_send_button_pressed)
	_send_button.mouse_entered.connect(_on_send_button_hover_changed.bind(true))
	_send_button.mouse_exited.connect(_on_send_button_hover_changed.bind(false))
	if _composer_panel != null:
		_composer_panel.mouse_entered.connect(_clear_message_hover_states)
	_composer.text_changed.connect(_on_composer_text_changed)
	_composer.focus_entered.connect(_on_composer_text_changed)
	_composer.gui_input.connect(_on_composer_gui_input)
	_composer.focus_entered.connect(_hide_selection_action_panel)
	if _composer_panel != null:
		_composer_panel.gui_input.connect(_on_composer_panel_gui_input)
	_control_panel_toggle.pressed.connect(_toggle_layout_menu)
	_bottom_panel_toggle.pressed.connect(_toggle_bottom_panel)
	_side_panel_toggle.pressed.connect(_toggle_right_inspector)
	_refresh_godex.pressed.connect(_refresh_plugin_ui)
	_search_input.text_changed.connect(_on_search_text_changed)
	_approve_latest.pressed.connect(_approve_latest_checkpoint)
	_reject_latest.pressed.connect(_reject_latest_checkpoint)
	_inject_probe_tool.pressed.connect(_inject_probe_tool_call)
	_replay_model_response_button.pressed.connect(_replay_model_response)
	_provider_probe_button.pressed.connect(_run_provider_probe)
	_execute_next_tool.pressed.connect(_execute_next_tool_call)
	_request_command_approval.pressed.connect(_request_next_command_approval)
	_execute_approved_command.pressed.connect(_execute_next_approved_command)
	_cancel_command_run.pressed.connect(_cancel_next_command_run)
	_cancel_subagent_task.pressed.connect(_cancel_next_subagent_task)
	_handoff_subagent_result.pressed.connect(_handoff_next_subagent_result)
	_archived_search_input.text_changed.connect(_on_archived_search_text_changed)
	_change_review_toggle.pressed.connect(_toggle_change_review_expanded)
	_change_review_action.pressed.connect(_open_change_review)
	_send_continuation.pressed.connect(_send_pending_openai_continuation)
	_replay_continuation_button.pressed.connect(_replay_pending_tool_result_continuation)
	_add_context_button.pressed.connect(_toggle_add_context_menu)
	_approval_button.pressed.connect(_toggle_approval_mode_menu)
	_goal_button.pressed.connect(_toggle_goal_tracking)
	_ide_context_button.pressed.connect(_toggle_ide_context)
	_goal_button.mouse_entered.connect(_on_goal_hover_changed.bind(true))
	_goal_button.mouse_exited.connect(_on_goal_hover_changed.bind(false))
	_ide_context_button.mouse_entered.connect(_on_ide_context_hover_changed.bind(true))
	_ide_context_button.mouse_exited.connect(_on_ide_context_hover_changed.bind(false))
	_model_button.pressed.connect(_toggle_model_picker)
	_reasoning_button.pressed.connect(_toggle_reasoning_picker)
	_provider.item_selected.connect(_on_provider_selected)
	_base_url.text_changed.connect(_on_provider_text_changed)
	_api_key.text_changed.connect(_on_provider_text_changed)
	_api_key_env.text_changed.connect(_on_provider_text_changed)
	_model.item_selected.connect(_on_model_setting_selected)
	_mcp_endpoint.text_changed.connect(_on_endpoint_changed)
	_mcp_refresh_tools.pressed.connect(_refresh_mcp_tools_from_settings)
	_mcp_server_settings.pressed.connect(_focus_mcp_endpoint_from_settings)
	_node("%s/SettingsActions/SaveSettings" % SETTINGS_CONTENT_PATH).pressed.connect(_save_settings_from_ui)
	_node("%s/SettingsActions/CloseSettings" % SETTINGS_CONTENT_PATH).pressed.connect(_hide_settings)
	var back_to_app := _settings_rail_child("BackToApp") as Button
	if back_to_app != null:
		back_to_app.pressed.connect(_hide_settings)
	_settings_search.text_changed.connect(_on_settings_search_changed)
	_skill_manager_search.text_changed.connect(_on_skill_manager_search_changed)
	_connect_settings_category_button("GeneralCategory", "general")
	_connect_settings_category_button("ConfigCategory", "config")
	_connect_settings_category_button("McpCategory", "mcp")
	_connect_settings_category_button("SkillsCategory", "skills")
	_connect_settings_category_button("ShellCategory", "shell")
	_connect_settings_category_button("ArchiveCategory", "archived")
	_mcp_enabled.toggled.connect(_on_capability_toggle_changed)
	_skills_enabled.toggled.connect(_on_capability_toggle_changed)
	_compression_enabled.toggled.connect(_on_capability_toggle_changed)
	_command_enabled.toggled.connect(_on_capability_toggle_changed)
	_command_shell.text_changed.connect(_on_capability_text_changed)
	_root.resized.connect(_position_visible_composer_popovers)
	_root.resized.connect(_position_visible_layout_menu)
	_root.resized.connect(_apply_conversation_column_layout)
	_composer_panel.resized.connect(_position_visible_composer_popovers)
	_composer.resized.connect(_position_visible_composer_popovers)
	_approval_button.resized.connect(_position_visible_composer_popovers)
	_model_button.resized.connect(_position_visible_composer_popovers)
	_reasoning_button.resized.connect(_position_visible_composer_popovers)


func _setup_transport_nodes() -> void:
	_openai_request = HTTPRequest.new()
	_openai_request.timeout = 90.0
	_openai_request.request_completed.connect(_on_openai_request_completed)
	_root.add_child(_openai_request)
	_provider_probe_request = HTTPRequest.new()
	_provider_probe_request.timeout = 45.0
	_provider_probe_request.request_completed.connect(_on_provider_probe_completed)
	_root.add_child(_provider_probe_request)
	_openai_stream_client = HTTPClient.new()
	_openai_stream_timer = Timer.new()
	_openai_stream_timer.wait_time = 0.05
	_openai_stream_timer.one_shot = false
	_openai_stream_timer.timeout.connect(_poll_openai_stream)
	_root.add_child(_openai_stream_timer)
	_mcp_tools_request = HTTPRequest.new()
	_mcp_tools_request.timeout = 10.0
	_mcp_tools_request.request_completed.connect(_on_mcp_tools_request_completed)
	_root.add_child(_mcp_tools_request)
	_mcp_tool_call_request = HTTPRequest.new()
	_mcp_tool_call_request.timeout = 15.0
	_mcp_tool_call_request.request_completed.connect(_on_mcp_tool_call_request_completed)
	_root.add_child(_mcp_tool_call_request)


func _apply_static_chrome() -> void:
	_root.add_theme_stylebox_override("panel", GodexTheme.panel_style(GodexTheme.BG, 0, GodexTheme.BG))
	_node("Root/Shell/SidebarPanel").add_theme_stylebox_override("panel", GodexTheme.panel_style(GodexTheme.SIDEBAR, 0, Color(0, 0, 0, 0)))
	_node("Root/Shell/MainPanel").add_theme_stylebox_override("panel", _main_panel_style())
	for panel_path in [
		"%s/Body/MainCenter/ComposerPanel" % MAIN,
		"%s/Body/MainCenter/BottomDrawer" % MAIN,
		"%s/Body/MainCenter/ChangeReviewSurface" % MAIN,
		"%s/Body/MainCenter/SearchPanel" % MAIN,
		"%s/Body/MainCenter/PluginsPanel" % MAIN,
		"%s/Body/MainCenter/McpPanel" % MAIN,
		"%s/Body/MainCenter/AutomationPanel" % MAIN,
		"%s/Body/MainCenter/ArchivedPanel" % MAIN,
		"%s/Body/MainCenter/AutomationPanel/AutomationBox/ContinuationPreview" % MAIN,
	]:
		_node(panel_path).add_theme_stylebox_override("panel", GodexTheme.panel_style())
	_node(SETTINGS_PANEL_PATH).add_theme_stylebox_override("panel", _transparent_panel_style())
	_node("ProgressOverlayLayer/RightRail").add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.145, 0.145, 0.145), 18, Color(0.24, 0.25, 0.26)))
	if _layout_menu_surface != null:
		_layout_menu_surface.add_theme_stylebox_override("panel", _composer_popover_style())
	for section_title in [
		"ProgressOverlayLayer/RightRail/RightRailBox/ProgressSection/ProgressTitle",
		"ProgressOverlayLayer/RightRail/RightRailBox/OutputSection/OutputTitle",
		"ProgressOverlayLayer/RightRail/RightRailBox/SubAgentsSection/SubAgentsTitle",
		"ProgressOverlayLayer/RightRail/RightRailBox/SourcesSection/SourcesTitle",
	]:
		GodexTheme.paint_label(_node(section_title), GodexTheme.MUTED, 16)
	for sidebar_section in [
		"Root/Shell/SidebarPanel/Sidebar/ProjectLabel",
		"Root/Shell/SidebarPanel/Sidebar/ConversationLabel",
	]:
		var sidebar_label := _root.get_node_or_null(sidebar_section) as Control
		if sidebar_label != null:
			sidebar_label.visible = false
	_slash_command_panel.add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.15, 0.15, 0.15), 14, GodexTheme.BORDER))
	_node("%s/Body/MainCenter/ComposerPanel" % MAIN).add_theme_stylebox_override("panel", _composer_panel_style())
	_bottom_drawer.add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.105, 0.105, 0.105), 14, Color(0.24, 0.25, 0.26)))
	_change_review_surface.add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.13, 0.13, 0.13), 14, Color(0.23, 0.24, 0.25)))
	if _archived_panel != null:
		_archived_panel.add_theme_stylebox_override("panel", _transparent_panel_style())
	if _composer_queue_surface != null:
		_composer_queue_surface.add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.145, 0.145, 0.145), 18, Color(0.24, 0.24, 0.24)))
	var settings_box := _root.get_node_or_null(SETTINGS_BOX_PATH) as HBoxContainer
	if settings_box != null:
		settings_box.add_theme_constant_override("separation", 0)
	var settings_left_spacer := _root.get_node_or_null("%s/SettingsContentLeftSpacer" % SETTINGS_BOX_PATH) as Control
	if settings_left_spacer != null:
		settings_left_spacer.visible = false
	var settings_right_spacer := _root.get_node_or_null("%s/SettingsContentRightSpacer" % SETTINGS_BOX_PATH) as Control
	if settings_right_spacer != null:
		settings_right_spacer.visible = false
	var settings_content_wrap := _root.get_node_or_null("%s/SettingsContentWrap" % SETTINGS_BOX_PATH) as MarginContainer
	if settings_content_wrap != null:
		settings_content_wrap.custom_minimum_size = Vector2(0, 0)
		settings_content_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		settings_content_wrap.add_theme_constant_override("margin_left", 96)
		settings_content_wrap.add_theme_constant_override("margin_right", 96)
	var settings_content_center := _root.get_node_or_null("%s/SettingsContentWrap/SettingsScroll/SettingsContentCenter" % SETTINGS_BOX_PATH) as CenterContainer
	if settings_content_center != null:
		settings_content_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		settings_content_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var settings_content := _root.get_node_or_null(SETTINGS_CONTENT_PATH) as VBoxContainer
	if settings_content != null:
		settings_content.custom_minimum_size = Vector2(900, 0)
	if _add_context_surface != null:
		_add_context_surface.add_theme_stylebox_override("panel", _composer_popover_style())
	if _approval_mode_surface != null:
		_approval_mode_surface.add_theme_stylebox_override("panel", _composer_popover_style())
	if _model_picker_surface != null:
		_model_picker_surface.add_theme_stylebox_override("panel", _composer_popover_style())
	if _reasoning_picker_surface != null:
		_reasoning_picker_surface.add_theme_stylebox_override("panel", _composer_popover_style())
	_composer.add_theme_stylebox_override("normal", _composer_input_style(false))
	_composer.add_theme_stylebox_override("focus", _composer_input_style(true))
	_composer.add_theme_stylebox_override("read_only", _composer_input_style(false))
	_composer.add_theme_color_override("font_color", GodexTheme.TEXT)
	_composer.add_theme_color_override("font_placeholder_color", GodexTheme.MUTED)
	_composer.add_theme_font_size_override("font_size", 16)
	_composer.tooltip_text = ""
	_node("%s/Body/MainCenter/ComposerPanel/ComposerBox/ComposerControls" % MAIN).add_theme_constant_override("separation", 6)
	_change_review_files.add_theme_constant_override("separation", 4)
	for button in _root.find_children("*", "Button", true, false):
		GodexTheme.paint_button(button)
	for label in _root.find_children("*", "Label", true, false):
		GodexTheme.paint_label(label)
	_style_settings_workspace()
	_main_title.add_theme_font_size_override("font_size", 28)
	_paint_editor_icons()
	_apply_layout_state()
	_rebuild_layout_menu()
	_configure_composer_popovers()
	_ensure_send_button_hint_panel()
	_inject_probe_tool.tooltip_text = "创建一个本地 MCP 上下文探针，并通过真实工具调用链路验证当前编辑器连接。"
	_replay_model_response_button.tooltip_text = "使用本地 OpenAI Responses API 兼容样例验证模型响应解析、工具调用和信息流。不会发送网络请求。"
	_provider_probe_button.tooltip_text = "从当前 Godot 编辑器进程发送最小非流式 OpenAI-compatible 请求，验证供应商 endpoint、模型和认证状态。"
	_execute_next_tool.tooltip_text = "执行下一个待处理或已准备好的 MCP 工具调用。"
	_send_continuation.tooltip_text = "显式发送已经准备好的 OpenAI 工具结果续跑请求。"
	_refresh_godex.tooltip_text = "重新加载 Godex 主界面和控制器，用于安装更新后的安全刷新。"


func _configure_composer_popovers() -> void:
	var progress_layer := _root.get_node_or_null("ProgressOverlayLayer") as Control
	if progress_layer != null:
		progress_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		progress_layer.offset_left = 0
		progress_layer.offset_top = 0
		progress_layer.offset_right = 0
		progress_layer.offset_bottom = 0
		progress_layer.z_index = 50
	var right_rail := _root.get_node_or_null("ProgressOverlayLayer/RightRail") as Control
	if right_rail != null:
		right_rail.custom_minimum_size.x = RIGHT_RAIL_OVERLAY_WIDTH
		right_rail.anchor_left = 1.0
		right_rail.anchor_right = 1.0
		right_rail.anchor_top = 0.0
		right_rail.anchor_bottom = 0.0
		right_rail.offset_left = -360
		right_rail.offset_top = 84
		right_rail.offset_right = -16
		right_rail.offset_bottom = 0
	if _layout_menu_panel != null:
		_layout_menu_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_layout_menu_panel.z_index = 90
		_layout_menu_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_layout_menu_panel.custom_minimum_size = Vector2(LAYOUT_MENU_MIN_WIDTH, 0)
	if _layout_menu_surface != null:
		_layout_menu_surface.clip_contents = true
	if _composer_popover_layer == null:
		_composer_popover_layer = _root.get_node_or_null("ComposerPopoverLayer")
	if _composer_popover_layer == null:
		_composer_popover_layer = Control.new()
		_composer_popover_layer.name = "ComposerPopoverLayer"
		_composer_popover_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_composer_popover_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_root.add_child(_composer_popover_layer)
	_composer_popover_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_composer_popover_layer.offset_left = 0
	_composer_popover_layer.offset_top = 0
	_composer_popover_layer.offset_right = 0
	_composer_popover_layer.offset_bottom = 0
	_composer_popover_layer.z_index = 70
	_composer_popover_layer.move_to_front()
	for panel in [_slash_command_panel, _add_context_panel, _approval_mode_panel, _model_picker_panel, _reasoning_picker_panel]:
		if panel.get_parent() != _composer_popover_layer:
			var was_visible: bool = panel.visible
			panel.visible = false
			if panel.get_parent() != null:
				panel.get_parent().remove_child(panel)
			_clear_scene_owner(panel)
			_composer_popover_layer.add_child(panel)
			panel.visible = was_visible
		panel.set_as_top_level(false)
		panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		panel.offset_left = 0
		panel.offset_top = 0
		panel.offset_right = 0
		panel.offset_bottom = 0
		panel.z_index = 80
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_approval_mode_panel.z_index = 90
	_add_context_panel.z_index = 90
	_add_context_panel.custom_minimum_size = Vector2(ADD_CONTEXT_POPOVER_MIN_WIDTH, 0)
	_add_context_panel.clip_contents = false
	if _add_context_surface != null:
		_add_context_surface.set_anchors_preset(Control.PRESET_FULL_RECT)
		_add_context_surface.offset_left = 0
		_add_context_surface.offset_top = 0
		_add_context_surface.offset_right = 0
		_add_context_surface.offset_bottom = 0
		_add_context_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_add_context_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_add_context_surface.clip_contents = true
	if _add_context_box != null:
		_add_context_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_add_context_box.clip_contents = false
		var add_context_title := _add_context_box.get_node_or_null("AddContextTitle") as Label
		if add_context_title != null:
			add_context_title.visible = false
	if _add_context_list != null:
		_add_context_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_add_context_list.clip_contents = false
	_approval_mode_panel.custom_minimum_size = Vector2(APPROVAL_POPOVER_MIN_WIDTH, 0)
	_approval_mode_panel.clip_contents = true
	if _approval_mode_surface != null:
		_approval_mode_surface.set_anchors_preset(Control.PRESET_FULL_RECT)
		_approval_mode_surface.offset_left = 0
		_approval_mode_surface.offset_top = 0
		_approval_mode_surface.offset_right = 0
		_approval_mode_surface.offset_bottom = 0
		_approval_mode_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_approval_mode_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_approval_mode_surface.clip_contents = true
	if _approval_mode_box != null:
		_approval_mode_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_approval_mode_box.clip_contents = true
	if _approval_mode_list != null:
		_approval_mode_list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_approval_mode_list.clip_contents = true
	_configure_picker_panel(_model_picker_panel, _model_picker_surface, _model_picker_list, MODEL_POPOVER_MIN_WIDTH)
	_configure_picker_panel(_reasoning_picker_panel, _reasoning_picker_surface, _reasoning_picker_list, REASONING_POPOVER_MIN_WIDTH)
	_configure_model_submenu_hover_watch()
	_configure_thread_hover_watch()
	_ensure_thread_archive_notice()
	_ensure_selection_action_panel()


func _configure_picker_panel(panel: Control, surface: PanelContainer, list: VBoxContainer, min_width: float) -> void:
	if panel == null:
		return
	panel.custom_minimum_size = Vector2(min_width, 0)
	panel.clip_contents = false
	if surface != null:
		surface.set_anchors_preset(Control.PRESET_FULL_RECT)
		surface.offset_left = 0
		surface.offset_top = 0
		surface.offset_right = 0
		surface.offset_bottom = 0
		surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
		surface.clip_contents = true
	if list != null:
		list.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		list.clip_contents = true


func _configure_model_submenu_hover_watch() -> void:
	if _composer_popover_layer == null:
		return
	if _model_submenu_hover_watch != null and is_instance_valid(_model_submenu_hover_watch):
		return
	_model_submenu_hover_watch = Timer.new()
	_model_submenu_hover_watch.name = "ModelSubmenuHoverWatch"
	_model_submenu_hover_watch.wait_time = 0.08
	_model_submenu_hover_watch.one_shot = false
	_model_submenu_hover_watch.autostart = false
	_clear_scene_owner(_model_submenu_hover_watch)
	_composer_popover_layer.add_child(_model_submenu_hover_watch)
	_model_submenu_hover_watch.timeout.connect(_close_model_submenu_if_pointer_outside)


func _configure_thread_hover_watch() -> void:
	if _root == null:
		return
	if _thread_hover_watch != null and is_instance_valid(_thread_hover_watch):
		return
	_thread_hover_watch = Timer.new()
	_thread_hover_watch.name = "ThreadHoverWatch"
	_thread_hover_watch.wait_time = 0.06
	_thread_hover_watch.one_shot = false
	_thread_hover_watch.autostart = false
	_clear_scene_owner(_thread_hover_watch)
	_root.add_child(_thread_hover_watch)
	_thread_hover_watch.timeout.connect(_refresh_thread_hover_states)


func _configure_send_button_hover_watch() -> void:
	if _root == null:
		return
	if _send_button_hover_watch != null and is_instance_valid(_send_button_hover_watch):
		return
	_send_button_hover_watch = Timer.new()
	_send_button_hover_watch.name = "SendButtonHoverWatch"
	_send_button_hover_watch.wait_time = 0.05
	_send_button_hover_watch.one_shot = false
	_send_button_hover_watch.autostart = true
	_clear_scene_owner(_send_button_hover_watch)
	_root.add_child(_send_button_hover_watch)
	_send_button_hover_watch.timeout.connect(_refresh_send_button_hover_from_pointer)
	_send_button_hover_watch.start()


func _configure_message_hover_watch() -> void:
	if _root == null:
		return
	if _message_hover_watch != null and is_instance_valid(_message_hover_watch):
		return
	_message_hover_watch = Timer.new()
	_message_hover_watch.name = "MessageHoverWatch"
	_message_hover_watch.wait_time = 0.05
	_message_hover_watch.one_shot = false
	_message_hover_watch.autostart = true
	_clear_scene_owner(_message_hover_watch)
	_root.add_child(_message_hover_watch)
	_message_hover_watch.timeout.connect(_refresh_message_hover_from_pointer)
	_message_hover_watch.start()


func _ensure_thread_archive_notice() -> void:
	if _thread_archive_notice != null and is_instance_valid(_thread_archive_notice):
		return
	var parent := _root.get_node_or_null("ProgressOverlayLayer") as Control if _root != null else null
	if parent == null:
		return
	_thread_archive_notice = PanelContainer.new()
	_thread_archive_notice.name = "ThreadArchiveNotice"
	_thread_archive_notice.visible = false
	_thread_archive_notice.mouse_filter = Control.MOUSE_FILTER_STOP
	_thread_archive_notice.add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.16, 0.16, 0.16), 14, Color(0.28, 0.29, 0.30)))
	var box := HBoxContainer.new()
	box.name = "ThreadArchiveNoticeBox"
	box.add_theme_constant_override("separation", 6)
	_thread_archive_notice_label = Label.new()
	_thread_archive_notice_label.name = "ThreadArchiveNoticeLabel"
	_thread_archive_notice_label.text = "已归档会话。查看已归档的聊天："
	GodexTheme.paint_label(_thread_archive_notice_label, GodexTheme.TEXT, 13)
	_thread_archive_notice_settings = Button.new()
	_thread_archive_notice_settings.name = "ThreadArchiveNoticeSettings"
	_thread_archive_notice_settings.text = "设置"
	_thread_archive_notice_settings.tooltip_text = ""
	_thread_archive_notice_settings.flat = true
	_thread_archive_notice_settings.focus_mode = Control.FOCUS_NONE
	_thread_archive_notice_settings.add_theme_color_override("font_color", GodexTheme.BLUE)
	_thread_archive_notice_settings.add_theme_color_override("font_hover_color", GodexTheme.BLUE)
	_thread_archive_notice_settings.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_thread_archive_notice_settings.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_thread_archive_notice_settings.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_thread_archive_notice_settings.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_thread_archive_notice_settings.pressed.connect(_open_archived_settings_from_notice)
	box.add_child(_thread_archive_notice_label)
	box.add_child(_thread_archive_notice_settings)
	_thread_archive_notice.add_child(box)
	parent.add_child(_thread_archive_notice)
	_thread_archive_notice.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_thread_archive_notice.z_index = 120
	_thread_archive_notice_timer = Timer.new()
	_thread_archive_notice_timer.name = "ThreadArchiveNoticeTimer"
	_thread_archive_notice_timer.one_shot = true
	_thread_archive_notice_timer.wait_time = 4.0
	_clear_scene_owner(_thread_archive_notice_timer)
	parent.add_child(_thread_archive_notice_timer)
	_thread_archive_notice_timer.timeout.connect(_hide_thread_archive_notice)


func _ensure_composer_reference_bar() -> void:
	if _composer_reference_bar != null and is_instance_valid(_composer_reference_bar):
		return
	var composer_box := _root.get_node_or_null("%s/Body/MainCenter/ComposerPanel/ComposerBox" % MAIN) as VBoxContainer if _root != null else null
	if composer_box == null or _composer == null:
		return
	_composer_reference_bar = HBoxContainer.new()
	_composer_reference_bar.name = "ComposerReferenceBar"
	_composer_reference_bar.visible = false
	_composer_reference_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_composer_reference_bar.add_theme_constant_override("separation", 6)
	_clear_scene_owner(_composer_reference_bar)
	composer_box.add_child(_composer_reference_bar)
	composer_box.move_child(_composer_reference_bar, max(0, _composer.get_index()))


func _ensure_selection_action_panel() -> void:
	if _selection_action_panel != null and is_instance_valid(_selection_action_panel):
		return
	if _composer_popover_layer == null:
		_configure_composer_popovers()
	if _composer_popover_layer == null:
		return
	_selection_action_panel = PanelContainer.new()
	_selection_action_panel.name = "SelectionActionPanel"
	_selection_action_panel.visible = false
	_selection_action_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_selection_action_panel.add_theme_stylebox_override("panel", _selection_action_panel_style())
	_selection_action_bar = HBoxContainer.new()
	_selection_action_bar.name = "SelectionActionBar"
	_selection_action_bar.add_theme_constant_override("separation", 8)
	_selection_action_bar.add_child(_build_selection_action_button("SelectionAddToConversation", "添加到对话", ["Chat", "Add", "Message"], Callable(self, "_add_selection_reference_to_composer")))
	_selection_action_bar.add_child(_build_selection_action_button("SelectionAskSideChat", "在侧边聊天中提问", ["New", "Chat", "Add"], Callable(self, "_ask_selection_in_side_chat")))
	_selection_action_panel.add_child(_selection_action_bar)
	_clear_scene_owner(_selection_action_panel)
	_composer_popover_layer.add_child(_selection_action_panel)
	_selection_action_panel.z_index = 130


func _build_selection_action_button(node_name: String, title: String, icon_candidates: Array, action: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = title
	button.custom_minimum_size = Vector2(170, 38)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = title
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", 18)
	_set_button_icon(button, icon_candidates)
	_paint_selection_action_button(button)
	button.pressed.connect(action)
	return button


func _clear_scene_owner(node: Node) -> void:
	node.owner = null
	for child in node.get_children():
		_clear_scene_owner(child)


func _composer_panel_style() -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0.105, 0.105, 0.105), 14, Color(0.24, 0.25, 0.26))
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _main_panel_style() -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0.061, 0.063, 0.065), 14, Color(0.20, 0.21, 0.22))
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _transparent_panel_style(left: int = 0, top: int = 0, right: int = 0, bottom: int = 0) -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0, 0, 0, 0), 0, Color(0, 0, 0, 0))
	style.set_border_width_all(0)
	style.content_margin_left = left
	style.content_margin_top = top
	style.content_margin_right = right
	style.content_margin_bottom = bottom
	return style


func _transcript_row_style(vertical_padding: int = 4) -> StyleBoxFlat:
	return _transparent_panel_style(TRANSCRIPT_CONTENT_SIDE_PADDING, vertical_padding, TRANSCRIPT_CONTENT_SIDE_PADDING, vertical_padding)


func _user_message_bubble_style() -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0.145, 0.145, 0.145), 14, Color(0.17, 0.17, 0.17))
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.set_border_width_all(1)
	return style


func _user_message_bubble_width(text: String) -> float:
	var max_line_width := 0.0
	for line in text.split("\n"):
		var line_width := 0.0
		for i in line.length():
			var code := line.unicode_at(i)
			if code <= 32:
				line_width += 7.0
			elif code < 128:
				line_width += 9.0
			else:
				line_width += 17.0
		max_line_width = max(max_line_width, line_width)
	return clamp(max_line_width + USER_MESSAGE_BUBBLE_HORIZONTAL_PADDING, USER_MESSAGE_BUBBLE_MIN_WIDTH, USER_MESSAGE_BUBBLE_MAX_WIDTH)


func _composer_input_style(focused: bool) -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0.085, 0.085, 0.085), 8, Color(0, 0, 0, 0))
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	if focused:
		style.border_color = Color(0.30, 0.31, 0.33)
		style.set_border_width_all(1)
	else:
		style.set_border_width_all(0)
	return style


func _composer_popover_style() -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0.15, 0.15, 0.15), 14, Color(0.28, 0.29, 0.30))
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _selection_action_panel_style() -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0.15, 0.15, 0.15), 22, Color(0.30, 0.31, 0.32))
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style


func _paint_selection_action_button(button: Button) -> void:
	button.flat = true
	button.add_theme_stylebox_override("normal", _round_icon_button_style(Color(0.17, 0.17, 0.17), 19))
	button.add_theme_stylebox_override("hover", _round_icon_button_style(Color(0.22, 0.22, 0.22), 19))
	button.add_theme_stylebox_override("pressed", _round_icon_button_style(Color(0.25, 0.25, 0.25), 19))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", GodexTheme.TEXT)
	button.add_theme_color_override("font_hover_color", GodexTheme.TEXT)
	button.add_theme_color_override("font_pressed_color", GodexTheme.TEXT)
	button.add_theme_color_override("icon_normal_color", GodexTheme.TEXT)
	button.add_theme_color_override("icon_hover_color", GodexTheme.TEXT)
	button.add_theme_color_override("icon_pressed_color", GodexTheme.TEXT)


func _round_icon_button_style(color: Color, radius: int = 17) -> StyleBoxFlat:
	var style := GodexTheme.panel_style(color, radius, Color(0, 0, 0, 0))
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _paint_editor_icons() -> void:
	var refs := {
		"NewChat": ["Edit"],
		"Search": ["Search"],
		"Plugins": ["GuiTabMenuHl", "Groups", "Node"],
		"Automation": ["Time"],
		"Archived": ["History", "Folder"],
		"Settings": ["Tools"],
		"SendButton": ["ArrowUp"],
		"AddContext": ["Add"],
		"IdeContextButton": ["GuiVisibilityVisible"],
		"ApprovalButton": ["Shield", "Lock", "StatusSuccess"],
		"GoalButton": ["TrackColor"],
		"ProjectPill": ["Folder"],
		"ControlPanelToggle": ["GuiTabMenuHl", "ListSelect", "Tools"],
		"BottomPanelToggle": ["PanelBottom", "Window", "GuiScrollBar"],
		"SidePanelToggle": ["PanelLeft", "PanelRight", "GuiDockBottom"],
		"RefreshMcpTools": ["Reload"],
		"McpServerSettings": ["Tools"],
		"AddMcpServer": ["Add"],
		"GeneralCategory": ["EditorSettings", "Tools"],
		"AppearanceCategory": ["Theme", "ColorPick", "CanvasItem"],
		"ConfigCategory": ["GuiTabMenuHl", "Tools"],
		"McpCategory": ["Network", "ConnectionSignal", "Node"],
		"SkillsCategory": ["Script", "PluginScript"],
		"ShellCategory": ["Terminal", "Console", "Output"],
		"ArchiveCategory": ["History", "Folder"],
	}
	for node_name in refs.keys():
		var found := _root.find_child(node_name, true, false)
		if not (found is Button):
			continue
		_set_button_icon(found, refs[node_name])


func _set_button_icon(button: Button, icon_candidates: Array) -> bool:
	var texture := _editor_icon_texture(icon_candidates)
	if texture == null:
		return false
	button.icon = texture
	return true


func _editor_icon_texture(icon_candidates) -> Texture2D:
	if _editor_theme == null:
		return _fallback_editor_icon_texture()
	var candidates: Array = icon_candidates if icon_candidates is Array else [icon_candidates]
	for icon_name in candidates:
		if _editor_theme.has_icon(str(icon_name), "EditorIcons"):
			return _editor_theme.get_icon(str(icon_name), "EditorIcons")
	var fallback_candidates := ["Node", "Object", "File", "Tools", "Script", "Play", "StatusSuccess"]
	for icon_name in fallback_candidates:
		if _editor_theme.has_icon(icon_name, "EditorIcons"):
			return _editor_theme.get_icon(icon_name, "EditorIcons")
	return _fallback_editor_icon_texture()


func _fallback_editor_icon_texture() -> Texture2D:
	if _fallback_icon_texture != null:
		return _fallback_icon_texture
	var image := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(3, 9):
		for x in range(3, 9):
			if x == 3 or x == 8 or y == 3 or y == 8:
				image.set_pixel(x, y, GodexTheme.MUTED)
	_fallback_icon_texture = ImageTexture.create_from_image(image)
	return _fallback_icon_texture


func _apply_model(model: Dictionary) -> void:
	var project_name := str(model.get("active_project", "Godot"))
	_main_title.text = "我们应该在 %s 中做些什么？" % project_name
	var sidebar_project := _node("Root/Shell/SidebarPanel/Sidebar/ProjectName") as Label
	sidebar_project.text = project_name
	sidebar_project.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar_project.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sidebar_project.clip_text = true
	GodexTheme.paint_label(sidebar_project, GodexTheme.TEXT, 16)
	_node("%s/Header/ProjectPill" % MAIN).text = project_name
	_node("%s/Header/McpStatus" % MAIN).text = "MCP 已连接" if str(model.get("endpoint", "")).begins_with("http://127.0.0.1") else "MCP 未确认"
	_node("%s/Header/EndpointLabel" % MAIN).text = str(model.get("endpoint", ""))
	_apply_composer_model(model)
	_rebuild_composer_queue(model)
	_apply_change_review_model(model.get("change_review_summary", {}))
	_rebuild_slash_command_suggestions(_composer.text)
	_apply_settings_model(model)
	_rebuild_threads(model.get("threads", []))
	_rebuild_progress(model)
	_rebuild_outputs(model.get("outputs", []))
	_rebuild_bottom_terminal(model)
	_rebuild_subagents(model.get("tools", []), model)
	_rebuild_sources(model)
	_rebuild_search_results(model)
	_rebuild_mcp_view(model)
	_rebuild_automation_view(model)
	_rebuild_archived_view()
	_apply_layout_state()
	_refresh_nav_state()


func _apply_layout_state() -> void:
	if _root == null:
		return
	var empty_chat := _active_view == "chat" and not _has_visible_chat_transcript()
	var header := _root.get_node_or_null("%s/Header" % MAIN) as Control
	if header != null:
		header.visible = _active_view != "settings"
	if _composer_panel != null:
		_composer_panel.visible = _active_view != "settings"
	var right_rail := _root.get_node_or_null("ProgressOverlayLayer/RightRail") as Control
	if right_rail != null:
		right_rail.visible = _right_inspector_visible and _active_view == "chat" and _can_show_right_rail_without_covering_transcript()
	if _bottom_drawer != null:
		_bottom_drawer.visible = _bottom_panel_visible and _active_view == "chat"
	if _change_review_surface != null:
		var review_summary: Dictionary = _state.call("change_review_preview") if _state != null and _state.has_method("change_review_preview") else {}
		_change_review_surface.visible = _active_view == "chat" and not review_summary.is_empty() and int(review_summary.get("file_count", 0)) > 0
	if _composer_queue_surface != null:
		_composer_queue_surface.visible = _active_view == "chat" and _composer_queue_list != null and _composer_queue_list.get_child_count() > 0
	if _sidebar_panel != null:
		_sidebar_panel.visible = _sidebar_visible
	if _sidebar_resize_handle != null:
		_sidebar_resize_handle.visible = _sidebar_visible
	var main_center := _root.get_node_or_null("%s/Body/MainCenter" % MAIN) as BoxContainer
	if main_center != null:
		main_center.alignment = BoxContainer.ALIGNMENT_CENTER if empty_chat else BoxContainer.ALIGNMENT_BEGIN
	if _conversation_scroll != null:
		_conversation_scroll.visible = _active_view == "chat" and not empty_chat
	if _welcome_panel != null:
		_welcome_panel.visible = _active_view == "chat" and empty_chat
	_apply_sidebar_mode()
	_paint_layout_menu_button()
	_paint_layout_button(_bottom_panel_toggle, _bottom_panel_visible, "隐藏底部输出", "显示底部输出")
	_paint_layout_button(_side_panel_toggle, _right_inspector_visible, "隐藏右侧检查器", "显示右侧检查器")
	_apply_conversation_column_layout()
	call_deferred("_apply_conversation_column_layout")


func _apply_sidebar_width(width: float) -> void:
	var next_width := clampf(width, SIDEBAR_MIN_WIDTH, SIDEBAR_MAX_WIDTH)
	if _state != null:
		_state.set("sidebar_width", next_width)
	if _sidebar_panel != null:
		_sidebar_panel.custom_minimum_size.x = next_width


func _on_sidebar_resize_handle_input(event: InputEvent) -> void:
	if _sidebar_panel == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_sidebar_resizing = event.pressed
		if event.pressed:
			_sidebar_resize_start_x = event.global_position.x
			_sidebar_resize_start_width = float(_sidebar_panel.custom_minimum_size.x)
			if _sidebar_resize_start_width <= 0.0:
				_sidebar_resize_start_width = float(_state.get("sidebar_width")) if _state != null else 310.0
		else:
			_persist_sidebar_width()
		_sidebar_resize_handle.accept_event()
	elif event is InputEventMouseMotion and _sidebar_resizing:
		var mouse_event := event as InputEventMouseMotion
		var delta_x: float = mouse_event.global_position.x - _sidebar_resize_start_x
		_apply_sidebar_width(_sidebar_resize_start_width + delta_x)
		_sidebar_resize_handle.accept_event()


func _persist_sidebar_width() -> void:
	if _settings_store == null or _state == null:
		return
	_settings_store.call("save_settings", _state.call("to_settings"))


func _has_visible_chat_transcript() -> bool:
	if _state == null:
		return false
	for item in _state.call("active_transcript_items"):
		if not (item is Dictionary):
			continue
		if str(item.get("kind", "")) in ["message", "tool_batch", "tool_call", "partial_tool_call", "command_run"]:
			return true
	return false


func _apply_sidebar_mode() -> void:
	var settings_mode := _active_view == "settings"
	var settings_rail := _settings_rail_node()
	var sidebar := _root.get_node_or_null("Root/Shell/SidebarPanel/Sidebar") as VBoxContainer
	if settings_mode:
		_mount_settings_rail_in_sidebar(settings_rail, sidebar)
	else:
		_restore_settings_rail(settings_rail)
	_set_sidebar_chat_controls_visible(not settings_mode)
	if settings_rail != null:
		settings_rail.visible = settings_mode


func _settings_rail_node() -> Control:
	if _root == null:
		return null
	var rail := _root.get_node_or_null(SETTINGS_RAIL_PATH) as Control
	if rail == null:
		rail = _root.get_node_or_null(SETTINGS_RAIL_SIDEBAR_PATH) as Control
	return rail


func _settings_rail_child(child_name: String) -> Node:
	var rail := _settings_rail_node()
	return rail.get_node_or_null(child_name) if rail != null else null


func _mount_settings_rail_in_sidebar(settings_rail: Control, sidebar: VBoxContainer) -> void:
	if settings_rail == null or sidebar == null:
		return
	if _settings_rail_original_parent == null:
		_settings_rail_original_parent = settings_rail.get_parent()
		_settings_rail_original_index = settings_rail.get_index()
	if settings_rail.get_parent() != sidebar:
		var current_parent := settings_rail.get_parent()
		if current_parent != null:
			current_parent.remove_child(settings_rail)
		sidebar.add_child(settings_rail)
		sidebar.move_child(settings_rail, 0)
	settings_rail.custom_minimum_size = Vector2(0, 0)
	settings_rail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL


func _restore_settings_rail(settings_rail: Control) -> void:
	if settings_rail == null or _settings_rail_original_parent == null:
		return
	if settings_rail.get_parent() != _settings_rail_original_parent:
		var current_parent := settings_rail.get_parent()
		if current_parent != null:
			current_parent.remove_child(settings_rail)
		_settings_rail_original_parent.add_child(settings_rail)
		var restore_index := clampi(_settings_rail_original_index, 0, _settings_rail_original_parent.get_child_count() - 1)
		_settings_rail_original_parent.move_child(settings_rail, restore_index)
	settings_rail.custom_minimum_size = Vector2(260, 0)
	settings_rail.size_flags_horizontal = Control.SIZE_FILL
	settings_rail.size_flags_vertical = Control.SIZE_FILL


func _set_sidebar_chat_controls_visible(visible: bool) -> void:
	for path in [
		"Root/Shell/SidebarPanel/Sidebar/TopNav",
		"Root/Shell/SidebarPanel/Sidebar/ProjectName",
		"Root/Shell/SidebarPanel/Sidebar/ThreadScroll",
		"Root/Shell/SidebarPanel/Sidebar/Footer",
	]:
		var node := _root.get_node_or_null(path) as Control
		if node != null:
			node.visible = visible
	for heading_path in [
		"Root/Shell/SidebarPanel/Sidebar/ProjectLabel",
		"Root/Shell/SidebarPanel/Sidebar/ConversationLabel",
	]:
		var sidebar_heading := _root.get_node_or_null(heading_path) as Control
		if sidebar_heading != null:
			sidebar_heading.visible = false


func _paint_layout_button(button: Button, selected: bool, on_tooltip: String, off_tooltip: String) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(32, 32)
	button.focus_mode = Control.FOCUS_NONE
	button.flat = true
	button.button_pressed = selected
	button.tooltip_text = on_tooltip if selected else off_tooltip
	if button.icon != null:
		button.text = ""
	button.add_theme_stylebox_override("normal", _round_icon_button_style(Color(0.17, 0.17, 0.17) if selected else Color(0, 0, 0, 0), 10))
	button.add_theme_stylebox_override("hover", _round_icon_button_style(Color(0.20, 0.20, 0.20), 10))
	button.add_theme_stylebox_override("pressed", _round_icon_button_style(Color(0.24, 0.24, 0.24), 10))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", GodexTheme.TEXT if selected else GodexTheme.MUTED)
	button.add_theme_color_override("icon_normal_color", GodexTheme.TEXT if selected else GodexTheme.MUTED)
	button.add_theme_color_override("icon_hover_color", GodexTheme.TEXT)
	button.add_theme_color_override("icon_pressed_color", GodexTheme.TEXT)


func _style_settings_workspace() -> void:
	var rail := _settings_rail_node() as VBoxContainer
	if rail != null:
		rail.add_theme_constant_override("separation", 8)
		rail.add_theme_constant_override("margin_left", 0)
	for button_name in [
		"BackToApp",
		"GeneralCategory",
		"AppearanceCategory",
		"ConfigCategory",
		"McpCategory",
		"SkillsCategory",
		"ShellCategory",
	]:
		var button := _settings_rail_child(button_name) as Button
		if button == null:
			continue
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 32)
		var category := _settings_category_for_button(button_name)
		var disabled: bool = button_name == "AppearanceCategory"
		button.disabled = disabled
		if button_name == "BackToApp":
			button.tooltip_text = "返回 Godex 对话工作区。"
		else:
			button.tooltip_text = "外观设置将在主题偏好接入后启用。" if disabled else _settings_category_tooltip(category)
		_paint_settings_category_button(button, category == _active_settings_category and _settings_search_query().is_empty(), disabled)
	if _settings_search != null:
		_settings_search.add_theme_stylebox_override("normal", _composer_input_style(false))
		_settings_search.add_theme_stylebox_override("focus", _composer_input_style(true))
		_settings_search.add_theme_font_size_override("font_size", 13)
	if _skill_manager_search != null:
		_skill_manager_search.add_theme_stylebox_override("normal", _composer_input_style(false))
		_skill_manager_search.add_theme_stylebox_override("focus", _composer_input_style(true))
		_skill_manager_search.add_theme_font_size_override("font_size", 13)
	if _settings_no_results != null:
		GodexTheme.paint_label(_settings_no_results, GodexTheme.MUTED, 14)
	for card_path in [
		"%s/ProviderCard" % SETTINGS_CONTENT_PATH,
		"%s/IntegrationCard" % SETTINGS_CONTENT_PATH,
		"%s/FeatureCard" % SETTINGS_CONTENT_PATH,
		"%s/CodingCard" % SETTINGS_CONTENT_PATH,
	]:
		var card := _root.get_node_or_null(card_path) as PanelContainer
		if card != null:
			card.add_theme_stylebox_override("panel", _settings_card_style())
	if _mcp_server_row != null:
		_mcp_server_row.add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.155, 0.155, 0.155), 8, Color(0.24, 0.25, 0.26)))
		var server_content := _mcp_server_row.get_node_or_null("McpServerContent") as HBoxContainer
		if server_content != null:
			server_content.add_theme_constant_override("separation", 10)
	for icon_button in [_mcp_refresh_tools, _mcp_server_settings]:
		if icon_button == null:
			continue
		icon_button.flat = true
		icon_button.focus_mode = Control.FOCUS_NONE
		icon_button.add_theme_stylebox_override("normal", _round_icon_button_style(Color(0.18, 0.18, 0.18), 8))
		icon_button.add_theme_stylebox_override("hover", _round_icon_button_style(Color(0.24, 0.24, 0.24), 8))
		icon_button.add_theme_stylebox_override("pressed", _round_icon_button_style(Color(0.28, 0.28, 0.28), 8))
		icon_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		icon_button.add_theme_color_override("font_color", GodexTheme.MUTED)
		icon_button.add_theme_color_override("icon_normal_color", GodexTheme.MUTED)
		icon_button.add_theme_color_override("icon_hover_color", GodexTheme.TEXT)
	if _mcp_add_server != null:
		GodexTheme.paint_button(_mcp_add_server)
	for container_path in [
		"%s/ProviderCard/ProviderSettings" % SETTINGS_CONTENT_PATH,
		"%s/IntegrationCard/IntegrationSettings" % SETTINGS_CONTENT_PATH,
		"%s/FeatureCard/FeatureToggles" % SETTINGS_CONTENT_PATH,
		"%s/CodingCard/CodingSettings" % SETTINGS_CONTENT_PATH,
	]:
		var container := _root.get_node_or_null(container_path) as VBoxContainer
		if container != null:
			container.add_theme_constant_override("separation", 0)
	for title_path in [
		"%s/ProviderSectionTitle" % SETTINGS_CONTENT_PATH,
		"%s/IntegrationSectionTitle" % SETTINGS_CONTENT_PATH,
		"%s/PermissionsSectionTitle" % SETTINGS_CONTENT_PATH,
		"%s/SkillManagerTitle" % SETTINGS_CONTENT_PATH,
		"%s/CodingSectionTitle" % SETTINGS_CONTENT_PATH,
		"%s/CapabilityPreviewTitle" % SETTINGS_CONTENT_PATH,
	]:
		var title := _root.get_node_or_null(title_path) as Label
		if title != null:
			GodexTheme.paint_label(title, GodexTheme.MUTED, 13)
	for rail_title_name in ["PersonalTitle", "IntegrationTitle", "CodingTitle"]:
		var title := _settings_rail_child(rail_title_name) as Label
		if title != null:
			GodexTheme.paint_label(title, GodexTheme.MUTED, 13)
	var page_title := _root.get_node_or_null("%s/SettingsTitle" % SETTINGS_CONTENT_PATH) as Label
	if page_title != null:
		GodexTheme.paint_label(page_title, GodexTheme.TEXT, 18)
		page_title.add_theme_font_size_override("font_size", 20)
	if _mcp_endpoint != null:
		_mcp_endpoint.add_theme_stylebox_override("normal", _composer_input_style(false))
		_mcp_endpoint.add_theme_stylebox_override("focus", _composer_input_style(true))
	for help_label in _root.find_children("*Help", "Label", true, false):
		GodexTheme.paint_label(help_label, GodexTheme.MUTED, 12)
	_apply_settings_category_visibility()


func _paint_settings_category_button(button: Button, selected: bool, disabled: bool = false) -> void:
	var normal_color := Color(0.17, 0.19, 0.205) if selected else Color(0, 0, 0, 0)
	button.add_theme_stylebox_override("normal", GodexTheme.button_style(normal_color, selected))
	button.add_theme_stylebox_override("hover", GodexTheme.button_style(Color(0.20, 0.215, 0.23), selected))
	button.add_theme_stylebox_override("pressed", GodexTheme.button_style(Color(0.22, 0.235, 0.25), true))
	button.add_theme_stylebox_override("disabled", GodexTheme.button_style(Color(0, 0, 0, 0), false))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var color := GodexTheme.TEXT if selected else GodexTheme.MUTED
	var disabled_color := Color(GodexTheme.MUTED.r, GodexTheme.MUTED.g, GodexTheme.MUTED.b, 0.45)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", GodexTheme.TEXT)
	button.add_theme_color_override("font_disabled_color", disabled_color if disabled else GodexTheme.MUTED)
	button.add_theme_color_override("icon_normal_color", color)
	button.add_theme_color_override("icon_hover_color", GodexTheme.TEXT)
	button.add_theme_color_override("icon_pressed_color", GodexTheme.TEXT)
	button.add_theme_color_override("icon_disabled_color", disabled_color if disabled else GodexTheme.MUTED)


func _settings_category_for_button(button_name: String) -> String:
	match button_name:
		"GeneralCategory":
			return "general"
		"ConfigCategory":
			return "config"
		"McpCategory":
			return "mcp"
		"SkillsCategory":
			return "skills"
		"ShellCategory":
			return "shell"
		"ArchiveCategory":
			return "archived"
		_:
			return ""


func _settings_category_tooltip(category: String) -> String:
	match category:
		"general":
			return "查看常规模型与权限设置。"
		"config":
			return "查看供应商、API 地址与模型配置。"
		"mcp":
			return "管理外部 MCP 来源。"
		"skills":
			return "查看 Skill 和上下文自动化能力。"
		"shell":
			return "配置本地命令行能力。"
		"archived":
			return "搜索、恢复或删除已归档对话。"
		_:
			return "设置分类。"


func _settings_category_title(category: String) -> String:
	match category:
		"config":
			return "配置"
		"mcp":
			return "MCP 服务器"
		"skills":
			return "Skills"
		"shell":
			return "命令行"
		"archived":
			return "已归档对话"
		_:
			return "常规"


func _settings_search_query() -> String:
	return _settings_search.text.strip_edges().to_lower() if _settings_search != null else ""


func _settings_sections() -> Array[Dictionary]:
	if _active_settings_category == "archived" and _settings_search_query().is_empty():
		return []
	return [
		{
			"id": "provider",
			"categories": ["general", "config"],
			"title_path": "%s/ProviderSectionTitle" % SETTINGS_CONTENT_PATH,
			"content_path": "%s/ProviderCard" % SETTINGS_CONTENT_PATH,
			"terms": "常规 配置 供应商 provider openai azure compatible yurenapi api api key base url key env model 模型 认证 responses"
		},
		{
			"id": "integration",
			"categories": ["mcp", "config"],
			"title_path": "%s/IntegrationSectionTitle" % SETTINGS_CONTENT_PATH,
			"content_path": "%s/IntegrationCard" % SETTINGS_CONTENT_PATH,
			"terms": "集成 mcp server endpoint 来源 工具 外部 godot dotnet streamable http api 模式 responses chat completions"
		},
		{
			"id": "permissions",
			"categories": ["general", "skills"],
			"title_path": "%s/PermissionsSectionTitle" % SETTINGS_CONTENT_PATH,
			"content_path": "%s/FeatureCard" % SETTINGS_CONTENT_PATH,
			"terms": "权限 skill skills 自动触发 上下文 压缩 compression 命令行 审批 permission"
		},
		{
			"id": "skill_manager",
			"categories": ["skills"],
			"title_path": "%s/SkillManagerTitle" % SETTINGS_CONTENT_PATH,
			"content_path": "%s/SkillManagerList" % SETTINGS_CONTENT_PATH,
			"terms": "skill skills 管理 搜索 启用 禁用 registry 本地 system user repo"
		},
		{
			"id": "coding",
			"categories": ["general", "shell"],
			"title_path": "%s/CodingSectionTitle" % SETTINGS_CONTENT_PATH,
			"content_path": "%s/CodingCard" % SETTINGS_CONTENT_PATH,
			"terms": "编码 命令 shell powershell command terminal 本地"
		},
		{
			"id": "capabilities",
			"categories": ["general", "skills", "shell"],
			"title_path": "%s/CapabilityPreviewTitle" % SETTINGS_CONTENT_PATH,
			"content_path": "%s/CapabilityPreview" % SETTINGS_CONTENT_PATH,
			"terms": "能力 预览 capability openai mcp skill command"
		},
	]


func _apply_settings_category_visibility() -> void:
	if _root == null:
		return
	var query := _settings_search_query()
	var archived_settings := _active_settings_category == "archived" and query.is_empty()
	var settings_panel := _root.get_node_or_null(SETTINGS_PANEL_PATH) as Control
	if settings_panel != null:
		settings_panel.visible = _active_view == "settings" and not archived_settings
	if _archived_panel != null:
		_archived_panel.visible = _active_view == "settings" and archived_settings
	var page_title := _root.get_node_or_null("%s/SettingsTitle" % SETTINGS_CONTENT_PATH) as Label
	if page_title != null:
		page_title.text = "搜索设置" if not query.is_empty() else _settings_category_title(_active_settings_category)
	var visible_section_count := 0
	if archived_settings:
		for path in [
			"%s/ProviderSectionTitle" % SETTINGS_CONTENT_PATH,
			"%s/ProviderCard" % SETTINGS_CONTENT_PATH,
			"%s/IntegrationSectionTitle" % SETTINGS_CONTENT_PATH,
			"%s/IntegrationCard" % SETTINGS_CONTENT_PATH,
			"%s/PermissionsSectionTitle" % SETTINGS_CONTENT_PATH,
			"%s/FeatureCard" % SETTINGS_CONTENT_PATH,
			"%s/SkillManagerTitle" % SETTINGS_CONTENT_PATH,
			"%s/SkillManagerSearch" % SETTINGS_CONTENT_PATH,
			"%s/SkillManagerList" % SETTINGS_CONTENT_PATH,
			"%s/CodingSectionTitle" % SETTINGS_CONTENT_PATH,
			"%s/CodingCard" % SETTINGS_CONTENT_PATH,
			"%s/CapabilityPreviewTitle" % SETTINGS_CONTENT_PATH,
			"%s/CapabilityPreview" % SETTINGS_CONTENT_PATH,
		]:
			var node := _root.get_node_or_null(path) as Control
			if node != null:
				node.visible = false
	for section in _settings_sections():
		var title := _root.get_node_or_null(str(section.get("title_path", ""))) as Control
		var content := _root.get_node_or_null(str(section.get("content_path", ""))) as Control
		var categories: Array = section.get("categories", [])
		var visible := categories.has(_active_settings_category)
		if not query.is_empty():
			var haystack := "%s %s" % [str(section.get("id", "")), str(section.get("terms", ""))]
			visible = haystack.to_lower().find(query) >= 0
		if visible:
			visible_section_count += 1
		if title != null:
			title.visible = visible
		if content != null:
			content.visible = visible
		if str(section.get("id", "")) == "skill_manager" and _skill_manager_search != null:
			_skill_manager_search.visible = visible
	if _settings_no_results != null:
		_settings_no_results.visible = not archived_settings and not query.is_empty() and visible_section_count == 0
	_refresh_settings_category_buttons()
	if archived_settings:
		_rebuild_archived_view()


func _refresh_settings_category_buttons() -> void:
	for button_name in ["GeneralCategory", "AppearanceCategory", "ConfigCategory", "McpCategory", "SkillsCategory", "ShellCategory", "ArchiveCategory"]:
		var button := _settings_rail_child(button_name) as Button
		if button == null:
			continue
		var category := _settings_category_for_button(button_name)
		var disabled: bool = button_name == "AppearanceCategory"
		_paint_settings_category_button(button, category == _active_settings_category and _settings_search_query().is_empty(), disabled)


func _on_settings_category_pressed(category: String) -> void:
	if category.is_empty():
		return
	if category != "archived":
		_last_non_archived_settings_category = category
	_active_settings_category = category
	if _settings_search != null and not _settings_search.text.is_empty():
		_settings_search.text = ""
	_apply_settings_category_visibility()
	_scroll_settings_to_visible_top()


func _on_settings_search_changed(value: String) -> void:
	if value.strip_edges().is_empty() and _active_settings_category == "archived":
		_active_settings_category = _last_non_archived_settings_category
	_apply_settings_category_visibility()
	_scroll_settings_to_visible_top()


func _scroll_settings_to_visible_top() -> void:
	if _settings_scroll == null:
		return
	_settings_scroll.scroll_vertical = 0


func _settings_card_style() -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0.125, 0.125, 0.125), 8, Color(0.22, 0.23, 0.24))
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _paint_layout_menu_button() -> void:
	if _control_panel_toggle == null:
		return
	var selected := _layout_menu_panel != null and _layout_menu_panel.visible
	_control_panel_toggle.toggle_mode = false
	_control_panel_toggle.custom_minimum_size = Vector2(32, 32)
	_control_panel_toggle.focus_mode = Control.FOCUS_NONE
	_control_panel_toggle.flat = true
	_control_panel_toggle.button_pressed = false
	_control_panel_toggle.tooltip_text = "打开启动菜单"
	if _control_panel_toggle.icon != null:
		_control_panel_toggle.text = ""
	_control_panel_toggle.add_theme_stylebox_override("normal", _round_icon_button_style(Color(0.17, 0.17, 0.17) if selected else Color(0, 0, 0, 0), 10))
	_control_panel_toggle.add_theme_stylebox_override("hover", _round_icon_button_style(Color(0.20, 0.20, 0.20), 10))
	_control_panel_toggle.add_theme_stylebox_override("pressed", _round_icon_button_style(Color(0.24, 0.24, 0.24), 10))
	_control_panel_toggle.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_control_panel_toggle.add_theme_color_override("font_color", GodexTheme.TEXT if selected else GodexTheme.MUTED)
	_control_panel_toggle.add_theme_color_override("icon_normal_color", GodexTheme.TEXT if selected else GodexTheme.MUTED)
	_control_panel_toggle.add_theme_color_override("icon_hover_color", GodexTheme.TEXT)
	_control_panel_toggle.add_theme_color_override("icon_pressed_color", GodexTheme.TEXT)


func _apply_conversation_column_layout() -> void:
	if _messages == null:
		return
	var empty_chat := _active_view == "chat" and not _has_visible_chat_transcript()
	var side_margin := TRANSCRIPT_COLUMN_SIDE_MARGIN
	if empty_chat:
		side_margin = min(TRANSCRIPT_COLUMN_SIDE_MARGIN, 40.0)
	var width_source := _conversation_column_width_source()
	var available := width_source - (side_margin * 2.0)
	var floor_width := TRANSCRIPT_COLUMN_MIN_WIDTH if width_source >= TRANSCRIPT_COLUMN_MIN_WIDTH + (side_margin * 2.0) else TRANSCRIPT_COLUMN_NARROW_MIN_WIDTH
	var target_width := clamp(available, floor_width, TRANSCRIPT_COLUMN_WIDTH)
	_messages.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_messages.clip_contents = false
	_messages.custom_minimum_size.x = target_width
	if _composer_panel != null:
		_composer_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_composer_panel.custom_minimum_size.y = max(_composer_panel.custom_minimum_size.y, 138.0)
		_composer_panel.custom_minimum_size.x = target_width
		if _composer != null:
			_composer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _bottom_drawer != null:
		_bottom_drawer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_bottom_drawer.custom_minimum_size.x = target_width
	if _change_review_surface != null:
		_change_review_surface.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_change_review_surface.custom_minimum_size.x = target_width
	if _composer_queue_surface != null:
		_composer_queue_surface.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_composer_queue_surface.custom_minimum_size.x = target_width
	_apply_archived_column_layout()
	if _conversation_tween != null and _conversation_tween.is_valid():
		_conversation_tween.kill()
	_conversation_tween = null


func _conversation_column_width_source() -> float:
	var width_source := 0.0
	if _root == null:
		return TRANSCRIPT_COLUMN_WIDTH
	for path in ["%s/Body/MainCenter" % MAIN, "%s/Body" % MAIN, MAIN, "Root/Shell/MainPanel", "Root/Shell"]:
		var container := _root.get_node_or_null(path) as Control
		if container != null:
			width_source = max(width_source, container.size.x)
	if _composer_panel != null:
		var composer_parent := _composer_panel.get_parent() as Control
		if composer_parent != null:
			width_source = max(width_source, composer_parent.size.x)
	if _conversation_scroll != null:
		width_source = max(width_source, _conversation_scroll.size.x)
	var viewport_size := _root.get_viewport_rect().size if _root.is_inside_tree() else Vector2.ZERO
	if viewport_size.x > 0.0:
		var viewport_available := viewport_size.x
		var sidebar := _root.get_node_or_null("Root/Shell/SidebarPanel") as Control
		if sidebar != null and sidebar.visible:
			viewport_available -= sidebar.size.x
		var right_rail := _root.get_node_or_null("ProgressOverlayLayer/RightRail") as Control
		if right_rail != null and right_rail.visible:
			viewport_available -= min(right_rail.size.x + RIGHT_RAIL_OVERLAY_GAP, viewport_size.x * 0.34)
		width_source = max(width_source, viewport_available)
	if width_source <= 0.0:
		width_source = TRANSCRIPT_COLUMN_WIDTH + (TRANSCRIPT_COLUMN_SIDE_MARGIN * 2.0)
	return width_source


func _apply_archived_column_layout() -> void:
	if _archived_panel == null:
		return
	_archived_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_archived_panel.custom_minimum_size.x = ARCHIVED_COLUMN_WIDTH
	var archived_box := _archived_panel.get_node_or_null("ArchivedBox") as VBoxContainer
	if archived_box != null:
		archived_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		archived_box.add_theme_constant_override("separation", 12)
	if _archived_search_input != null:
		_archived_search_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _archived_results != null:
		_archived_results.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_archived_results.add_theme_constant_override("separation", 0)


func _can_show_right_rail_without_covering_transcript() -> bool:
	if _root == null:
		return true
	var root_width := _root.size.x
	if root_width <= 0.0:
		return true
	var required_width := TRANSCRIPT_COLUMN_WIDTH + RIGHT_RAIL_OVERLAY_WIDTH + TRANSCRIPT_COLUMN_SIDE_MARGIN + RIGHT_RAIL_OVERLAY_GAP
	return root_width >= required_width


func _apply_settings_model(model: Dictionary) -> void:
	_set_provider_field_signals_blocked(true)
	_set_option_by_text(_provider, str(model.get("provider", "openai")))
	_base_url.text = str(model.get("base_url", ""))
	_api_key.text = str(model.get("api_key", ""))
	_api_key_env.text = str(model.get("api_key_env", ""))
	_api_status.text = _api_status_text(model.get("api_config", {}))
	_apply_settings_model_choices(model.get("model_choices", []), str(model.get("model", "")))
	_set_option_by_text(_api_mode, "Chat Completions Compatible" if str(model.get("api_mode", "")) == "chat_completions" else "Responses API")
	_set_provider_field_signals_blocked(false)
	_skills_enabled.button_pressed = bool(model.get("skills_enabled", true))
	_compression_enabled.button_pressed = bool(model.get("compression_enabled", true))
	_command_enabled.button_pressed = bool(model.get("command_enabled", false))
	_command_shell.text = str(model.get("command_shell", "PowerShell"))
	_apply_mcp_server_row_model(model.get("mcp_server_row", {}))
	_rebuild_capability_preview(model.get("capability_summary", []))
	_rebuild_skill_manager()


func _apply_mcp_server_row_model(row) -> void:
	if not (row is Dictionary):
		row = {}
	var endpoint_text := str(row.get("endpoint", _state.endpoint if _state != null else ""))
	if _mcp_endpoint != null and _mcp_endpoint.text != endpoint_text:
		_mcp_endpoint.text = endpoint_text
	if _mcp_enabled != null:
		_mcp_enabled.button_pressed = bool(row.get("enabled", true))
	if _mcp_server_name != null:
		_mcp_server_name.text = str(row.get("name", "Godot .NET MCP"))
	var status := str(row.get("status", "idle"))
	var tool_count := int(row.get("tool_count", 0))
	var status_label := _mcp_status_label(status)
	if _mcp_server_status_icon != null:
		_mcp_server_status_icon.text = "●"
		_mcp_server_status_icon.add_theme_color_override("font_color", _mcp_status_color(status))
		_mcp_server_status_icon.tooltip_text = "MCP 连接状态：%s" % status_label
	if _mcp_server_detail != null:
		var detail := "%s · %s · %d 个工具" % [str(row.get("transport", "streamable-http")), status_label, tool_count]
		var error_text := str(row.get("error", "")).strip_edges()
		if not error_text.is_empty():
			detail = "%s · %s" % [detail, error_text]
		_mcp_server_detail.text = detail
	if _mcp_refresh_tools != null:
		_mcp_refresh_tools.disabled = not bool(row.get("enabled", true)) or status in ["request_starting", "request_sent"]
	if _mcp_server_settings != null:
		_mcp_server_settings.disabled = not bool(row.get("editable", true))


func _mcp_status_label(status: String) -> String:
	match status:
		"ready":
			return "已发现"
		"request_ready", "request_starting", "request_sent":
			return "发现中"
		"error":
			return "需要检查"
		"disabled":
			return "已停用"
		_:
			return "待发现"


func _mcp_status_color(status: String) -> Color:
	match status:
		"ready":
			return GodexTheme.GREEN
		"request_ready", "request_starting", "request_sent":
			return GodexTheme.BLUE
		"error":
			return GodexTheme.WARNING
		"disabled":
			return GodexTheme.MUTED
		_:
			return GodexTheme.MUTED


func _on_skill_manager_search_changed(_value: String) -> void:
	_rebuild_skill_manager()


func _rebuild_skill_manager() -> void:
	if _skill_manager_list == null:
		return
	if _skill_registry == null:
		_skill_registry = GodexSkillRegistry.new()
	_scan_skill_roots()
	_clear(_skill_manager_list)
	var query := _skill_manager_search.text.strip_edges() if _skill_manager_search != null else ""
	var skills := _skill_registry.search(query)
	if skills.is_empty():
		_skill_manager_list.add_child(_skill_empty_row())
		return
	for skill in skills:
		if skill is Dictionary:
			_skill_manager_list.add_child(_skill_row(skill))


func _scan_skill_roots() -> void:
	if _skill_registry == null:
		return
	if _state != null:
		_skill_registry.set_disabled_paths(_state.get("skill_disabled_paths"))
	var seen_paths := {}
	var aggregate: Array[Dictionary] = []
	for root in _skill_roots():
		var normalized_root := str(root).replace("\\", "/").strip_edges()
		if normalized_root.is_empty() or seen_paths.has(normalized_root):
			continue
		seen_paths[normalized_root] = true
		if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(normalized_root)) or DirAccess.dir_exists_absolute(normalized_root):
			var root_registry := GodexSkillRegistry.new()
			root_registry.enabled_by_path = _skill_registry.enabled_by_path
			root_registry.scan(normalized_root)
			for skill in root_registry.skills:
				if skill is Dictionary:
					aggregate.append((skill as Dictionary).duplicate(true))
	_skill_registry.skills = aggregate
	if _state != null and _state.has_method("set_skill_registry_model"):
		_state.call("set_skill_registry_model", _skill_registry.to_model())


func _skill_roots() -> Array[String]:
	var roots: Array[String] = [
		"res://.agents/skills",
		"res://.codex/skills",
		"res://skills",
		"res://addons/godex/skills",
	]
	var global_user := OS.get_environment("USERPROFILE").replace("\\", "/").strip_edges()
	if not global_user.is_empty():
		roots.append("%s/.agents/skills" % global_user)
		roots.append("%s/.codex/skills" % global_user)
	return roots


func _skill_empty_row() -> Control:
	var label := Label.new()
	label.name = "SkillManagerEmpty"
	label.text = "未发现本地 Skill。"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(label, GodexTheme.MUTED, 13)
	return label


func _skill_row(skill: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "SkillManagerRow"
	panel.add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.145, 0.145, 0.145, 0.0), 0, Color(0.25, 0.25, 0.25, 0.45)))
	var row := HBoxContainer.new()
	row.name = "SkillManagerRowContent"
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size.y = 54
	var icon := TextureRect.new()
	icon.name = "SkillManagerIcon"
	icon.custom_minimum_size = Vector2(18, 18)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _editor_icon_texture(["Script", "PluginScript", "PackedScene"])
	icon.modulate = GodexTheme.MUTED
	row.add_child(icon)
	var copy := VBoxContainer.new()
	copy.name = "SkillManagerCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.name = "SkillManagerTitle"
	title.text = _skill_display_name(skill)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	GodexTheme.paint_label(title, GodexTheme.TEXT, 14)
	copy.add_child(title)
	var detail := Label.new()
	detail.name = "SkillManagerDetail"
	detail.text = _skill_detail(skill)
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	GodexTheme.paint_label(detail, GodexTheme.MUTED, 12)
	copy.add_child(detail)
	row.add_child(copy)
	var scope := Label.new()
	scope.name = "SkillManagerScope"
	scope.custom_minimum_size.x = 52
	scope.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scope.text = _skill_scope_label(str(skill.get("scope", "user")))
	GodexTheme.paint_label(scope, GodexTheme.MUTED, 12)
	row.add_child(scope)
	var toggle := Button.new()
	toggle.name = "SkillManagerToggle"
	toggle.text = "开启" if bool(skill.get("enabled", true)) else "关闭"
	toggle.custom_minimum_size = Vector2(64, 30)
	GodexTheme.paint_button(toggle, bool(skill.get("enabled", true)))
	toggle.pressed.connect(_toggle_skill_enabled.bind(str(skill.get("path", ""))))
	row.add_child(toggle)
	panel.add_child(row)
	return panel


func _skill_display_name(skill: Dictionary) -> String:
	var interface: Dictionary = skill.get("interface", {})
	var display_name := str(interface.get("display_name", "")).strip_edges()
	return display_name if not display_name.is_empty() else str(skill.get("name", "Skill"))


func _skill_detail(skill: Dictionary) -> String:
	var interface: Dictionary = skill.get("interface", {})
	var detail := str(interface.get("short_description", "")).strip_edges()
	if detail.is_empty():
		detail = str(skill.get("short_description", "")).strip_edges()
	if detail.is_empty():
		detail = str(skill.get("description", "")).strip_edges()
	if detail.is_empty():
		detail = str(skill.get("path", "")).strip_edges()
	return detail


func _skill_scope_label(scope: String) -> String:
	match scope:
		"system":
			return "系统"
		"repo":
			return "仓库"
		"admin":
			return "管理"
		_:
			return "用户"


func _toggle_skill_enabled(path: String) -> void:
	if _skill_registry == null:
		return
	var enabled := not _skill_registry.is_enabled(path)
	_skill_registry.set_enabled(path, enabled)
	if _state != null and _state.has_method("set_skill_disabled_paths"):
		_state.call("set_skill_disabled_paths", _skill_registry.disabled_paths())
	if _state != null and _state.has_method("set_skill_registry_model"):
		_state.call("set_skill_registry_model", _skill_registry.to_model())
	if _settings_store != null and _state != null:
		_settings_store.call("save_settings", _state.call("to_settings"))
	_rebuild_skill_manager()
	if _state != null:
		_apply_model(_state.call("to_model"))


func _apply_composer_model(model: Dictionary) -> void:
	if not bool(model.get("ide_context_enabled", true)):
		_ide_context_hovered = false
	var goal_record: Dictionary = model.get("active_goal", {})
	var goal_visible := bool(goal_record.get("visible", model.get("goal_tracking_enabled", false)))
	if not goal_visible:
		_goal_hovered = false
	_apply_add_context_menu_model()
	_apply_context_pill_model(_ide_context_button, bool(model.get("ide_context_enabled", true)), _ide_context_hovered, "IDE 上下文", "包含来自 IDE 的上下文，如选择状态和已打开的文件。", "/ide 切换", ["GuiVisibilityVisible", "Show"])
	_apply_approval_button_model(str(model.get("approval_mode", "替我审批")))
	_apply_context_pill_model(_goal_button, goal_visible, _goal_hovered, _goal_pill_label(goal_record), _goal_pill_tooltip(goal_record), "/goal off 关闭", ["TrackColor", "Target"])
	_refresh_openai_transport_buttons(false, false)
	_apply_model_button_model(model.get("model_choices", []), str(model.get("model", "gpt-5.5")))
	_apply_reasoning_button_model(str(model.get("reasoning_effort", "medium")))
	_apply_send_button_model(model)


func _refresh_openai_transport_buttons(cancel_enabled: bool = false, retry_enabled: bool = false) -> void:
	if _state != null:
		_apply_send_button_model(_state.call("to_model"))


func _apply_send_button_model(model: Dictionary) -> void:
	if _send_button == null:
		return
	var running := bool(model.get("is_running", false)) or str(model.get("agent_loop_status", "")) == "running" or _is_openai_busy()
	var queued_count := (model.get("queued_user_messages", []) as Array).filter(func(record): return record is Dictionary and str(record.get("status", "")) == "queued").size()
	var pending_steer_count := (model.get("pending_steers", []) as Array).filter(func(record): return record is Dictionary and str(record.get("status", "")) == "pending").size()
	var details: Array[String] = ["停止当前请求" if running else "发送"]
	if queued_count > 0:
		details.append("排队消息：%d 条" % queued_count)
	if pending_steer_count > 0:
		details.append("待用指南指令：%d 条" % pending_steer_count)
	var warning = model.get("context_window_warning", {})
	if warning is Dictionary and str(warning.get("status", "")) in ["warning", "auto_ready"]:
		details.append(str(warning.get("message", "")))
	_send_button.tooltip_text = "\n".join(details)
	_send_button.text = ""
	_send_button.custom_minimum_size = Vector2(38, 38)
	_set_button_icon(_send_button, ["Stop"] if running else ["ArrowUp"])
	var has_prompt := _composer != null and (not _composer.text.strip_edges().is_empty() or not _active_composer_references().is_empty())
	# Keep the idle-empty button interactive so the Codex-style hover hint can explain why it will not send.
	_send_button.disabled = false
	_send_button.tooltip_text = ""
	_paint_send_button(_send_button, running, queued_count > 0 or pending_steer_count > 0, has_prompt)
	_refresh_send_button_hint()


func _paint_send_button(button: Button, running: bool, attention: bool, has_prompt: bool = true) -> void:
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE
	var disabled := not running and not has_prompt
	var normal := Color(0.92, 0.92, 0.90) if disabled else Color(0.98, 0.98, 0.96)
	if attention and not running and not disabled:
		normal = Color(1.0, 1.0, 0.98)
	button.add_theme_stylebox_override("normal", _round_icon_button_style(normal, 19))
	button.add_theme_stylebox_override("hover", _round_icon_button_style(Color(1.0, 1.0, 1.0), 19))
	button.add_theme_stylebox_override("pressed", _round_icon_button_style(Color(0.82, 0.82, 0.80), 19))
	button.add_theme_stylebox_override("disabled", _round_icon_button_style(normal, 19))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var icon_color := Color(0.13, 0.13, 0.13) if not disabled or running else Color(0.15, 0.15, 0.15, 0.72)
	button.add_theme_color_override("icon_normal_color", icon_color)
	button.add_theme_color_override("icon_hover_color", icon_color)
	button.add_theme_color_override("icon_pressed_color", icon_color)
	button.add_theme_color_override("icon_disabled_color", icon_color)
	button.add_theme_color_override("font_color", icon_color)


func _on_send_button_hover_changed(hovered: bool) -> void:
	_send_button_hovered = hovered
	_refresh_send_button_hint()


func _refresh_send_button_hover_from_pointer() -> void:
	var holding_hint := Time.get_ticks_msec() < _send_button_hint_hold_until_msec
	if _send_button == null or not is_instance_valid(_send_button) or not _send_button.visible:
		if _send_button_hovered and not holding_hint:
			_send_button_hovered = false
			_refresh_send_button_hint()
		return
	var pointer := _root.get_global_mouse_position() if _root != null else _send_button.get_global_mouse_position()
	var hovered := _send_button.get_global_rect().has_point(pointer)
	if not hovered and _send_button_hint_panel != null and is_instance_valid(_send_button_hint_panel) and _send_button_hint_panel.visible:
		hovered = _send_button_hint_panel.get_global_rect().has_point(pointer)
	if holding_hint:
		hovered = true
	if hovered == _send_button_hovered:
		return
	_send_button_hovered = hovered
	_refresh_send_button_hint()


func _refresh_send_button_hint() -> void:
	if not _send_button_hovered or _send_button == null:
		_hide_send_button_hint()
		return
	_ensure_send_button_hint_panel()
	if _send_button_hint_panel == null or _send_button_hint_box == null:
		return
	_clear(_send_button_hint_box)
	var model: Dictionary = _state.call("to_model") if _state != null else {}
	var running := bool(model.get("is_running", false)) or str(model.get("agent_loop_status", "")) == "running" or _is_openai_busy()
	var has_prompt := _composer != null and not _composer.text.strip_edges().is_empty()
	if running:
		_send_button_hint_box.add_child(_build_send_button_hint_row("停止", "Esc", true))
	elif has_prompt:
		_send_button_hint_box.add_child(_build_send_button_hint_label("发送"))
	else:
		_send_button_hint_box.add_child(_build_send_button_hint_label("输入消息，点击发送以开始使用"))
	_send_button_hint_panel.visible = true
	_position_send_button_hint()


func _ensure_send_button_hint_panel() -> void:
	if _send_button_hint_panel != null and is_instance_valid(_send_button_hint_panel):
		return
	if _composer_popover_layer == null:
		_configure_composer_popovers()
	if _composer_popover_layer == null:
		return
	_send_button_hint_panel = PanelContainer.new()
	_send_button_hint_panel.name = "SendButtonHintPanel"
	_send_button_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_send_button_hint_panel.add_theme_stylebox_override("panel", _composer_popover_style())
	_send_button_hint_box = VBoxContainer.new()
	_send_button_hint_box.name = "SendButtonHintBox"
	_send_button_hint_box.add_theme_constant_override("separation", 2)
	_send_button_hint_panel.add_child(_send_button_hint_box)
	_composer_popover_layer.add_child(_send_button_hint_panel)
	_send_button_hint_panel.z_index = 120
	_send_button_hint_panel.visible = false


func _build_send_button_hint_label(text: String) -> Label:
	var label := Label.new()
	label.name = "SendButtonHintText"
	label.text = text
	label.custom_minimum_size = Vector2(276, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GodexTheme.paint_label(label, GodexTheme.TEXT, 15)
	return label


func _build_send_button_hint_row(title: String, shortcut: String, first: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "SendButtonHintRow"
	row.custom_minimum_size = Vector2(136, 34)
	row.add_theme_constant_override("separation", 12)
	var title_label := Label.new()
	title_label.name = "SendButtonHintTitle"
	title_label.text = title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GodexTheme.paint_label(title_label, GodexTheme.TEXT, 18)
	row.add_child(title_label)
	var key := Label.new()
	key.name = "SendButtonHintShortcut"
	key.text = shortcut
	key.custom_minimum_size = Vector2(0, 26)
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	key.add_theme_stylebox_override("normal", _round_icon_button_style(Color(0.26, 0.26, 0.26), 13))
	GodexTheme.paint_label(key, GodexTheme.TEXT, 15)
	row.add_child(key)
	return row


func _position_send_button_hint() -> void:
	if _send_button_hint_panel == null or _send_button == null:
		return
	var layer_rect := _composer_popover_layer.get_global_rect() if _composer_popover_layer != null else _root.get_global_rect()
	var button_rect := _send_button.get_global_rect()
	var hint_size := _send_button_hint_panel.get_combined_minimum_size()
	if hint_size.x <= 0:
		hint_size.x = 160
	if hint_size.y <= 0:
		hint_size.y = 42
	var pos := Vector2(button_rect.end.x - hint_size.x, button_rect.position.y - hint_size.y - 8) - layer_rect.position
	pos.x = clamp(pos.x, 8.0, max(8.0, layer_rect.size.x - hint_size.x - 8.0))
	pos.y = max(8.0, pos.y)
	_send_button_hint_panel.position = pos
	_send_button_hint_panel.size = hint_size


func _hide_send_button_hint() -> void:
	if _send_button_hint_panel != null:
		_send_button_hint_panel.visible = false


func _rebuild_composer_queue(model: Dictionary) -> void:
	if _composer_queue_surface == null or _composer_queue_list == null:
		return
	_clear(_composer_queue_list)
	var queued: Array = model.get("queued_user_messages", [])
	for item in queued:
		if not (item is Dictionary):
			continue
		var record: Dictionary = item
		if str(record.get("status", "")) != "queued":
			continue
		_composer_queue_list.add_child(_build_composer_queue_row(record))
	_composer_queue_surface.visible = _active_view == "chat" and _composer_queue_list.get_child_count() > 0


func _build_composer_queue_row(record: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "ComposerQueueRow"
	row.custom_minimum_size = Vector2(0, COMPOSER_QUEUE_ROW_HEIGHT)
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon := TextureRect.new()
	icon.name = "ComposerQueueIcon"
	icon.custom_minimum_size = Vector2(18, 18)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _editor_icon_texture(["Forwarded", "Redo", "Play", "StatusWarning"])
	icon.modulate = GodexTheme.MUTED
	row.add_child(icon)
	var title := Label.new()
	title.name = "ComposerQueueText"
	title.text = _preview_text(str(record.get("text", "")), 108)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GodexTheme.paint_label(title, GodexTheme.MUTED, 16)
	row.add_child(title)
	var guide := Button.new()
	guide.name = "ComposerQueueGuide"
	guide.text = "引导"
	guide.focus_mode = Control.FOCUS_NONE
	guide.custom_minimum_size = Vector2(58, 32)
	GodexTheme.paint_button(guide)
	guide.pressed.connect(_guide_queued_composer_message.bind(str(record.get("id", ""))))
	row.add_child(guide)
	var remove := Button.new()
	remove.name = "ComposerQueueDelete"
	remove.text = ""
	remove.focus_mode = Control.FOCUS_NONE
	remove.custom_minimum_size = Vector2(34, 32)
	_set_button_icon(remove, ["Remove", "Trash", "GuiCloseCustomizable"])
	GodexTheme.paint_button(remove)
	remove.pressed.connect(_cancel_queued_composer_message.bind(str(record.get("id", ""))))
	row.add_child(remove)
	var more := Button.new()
	more.name = "ComposerQueueMore"
	more.text = "..."
	more.disabled = true
	more.focus_mode = Control.FOCUS_NONE
	more.custom_minimum_size = Vector2(34, 32)
	GodexTheme.paint_button(more)
	row.add_child(more)
	return row


func _apply_model_button_model(choices: Array, current_model: String) -> void:
	_model_button.visible = false
	_model_button.text = _model_to_compact_label(current_model)
	_model_button.tooltip_text = "模型选择已合并到推理菜单。当前模型：%s。" % current_model
	GodexTheme.paint_button(_model_button)
	_rebuild_model_picker(choices, current_model)


func _apply_settings_model_choices(choices: Array, current_model: String) -> void:
	if _model == null:
		return
	_model.clear()
	var normalized_choices: Array[String] = []
	for choice in choices:
		var value := str(choice).strip_edges()
		if value.is_empty() or normalized_choices.has(value):
			continue
		normalized_choices.append(value)
	if normalized_choices.is_empty() and not current_model.strip_edges().is_empty():
		normalized_choices.append(current_model.strip_edges())
	for value in normalized_choices:
		_model.add_item(value)
	var selected_model := current_model.strip_edges()
	if selected_model.is_empty() or not normalized_choices.has(selected_model):
		selected_model = normalized_choices[0] if not normalized_choices.is_empty() else ""
	_set_option_by_text(_model, selected_model)
	_model.tooltip_text = "默认模型。当前供应商支持：%s" % " / ".join(normalized_choices)


func _apply_reasoning_button_model(current_effort: String) -> void:
	_reasoning_button.text = "%s  %s  v" % [_model_to_compact_label(str(_state.model)), _reasoning_to_label(current_effort)]
	_reasoning_button.tooltip_text = "选择推理强度和模型。当前：%s · %s。" % [_reasoning_to_label(current_effort), str(_state.model)]
	GodexTheme.paint_button(_reasoning_button)
	_rebuild_reasoning_picker(current_effort)


func _apply_add_context_menu_model() -> void:
	_add_context_button.disabled = false
	_add_context_button.text = ""
	_add_context_button.custom_minimum_size = Vector2(34, 34)
	_add_context_button.focus_mode = Control.FOCUS_NONE
	var warning: Dictionary = _state.call("context_window_warning") if _state != null else {}
	var warning_text := str(warning.get("message", "")).strip_edges()
	_add_context_button.tooltip_text = "添加上下文：项目摘要、IDE 状态、目标或后续文件/截图来源。"
	if str(warning.get("status", "")) in ["warning", "auto_ready"]:
		_add_context_button.tooltip_text += "\n%s\n可从菜单压缩当前会话。" % warning_text
	_paint_add_context_button()
	_rebuild_add_context_menu()


func _paint_add_context_button() -> void:
	var warning: Dictionary = _state.call("context_window_warning") if _state != null else {}
	var is_context_warning := str(warning.get("status", "")) in ["warning", "auto_ready"]
	var normal_color := Color(0.28, 0.22, 0.11) if is_context_warning else Color(0.18, 0.18, 0.18)
	var hover_color := Color(0.36, 0.28, 0.14) if is_context_warning else Color(0.24, 0.24, 0.24)
	var pressed_color := Color(0.42, 0.32, 0.16) if is_context_warning else Color(0.28, 0.28, 0.28)
	var icon_color := GodexTheme.WARNING if is_context_warning else GodexTheme.MUTED
	_add_context_button.add_theme_stylebox_override("normal", _round_icon_button_style(normal_color))
	_add_context_button.add_theme_stylebox_override("hover", _round_icon_button_style(hover_color))
	_add_context_button.add_theme_stylebox_override("pressed", _round_icon_button_style(pressed_color))
	_add_context_button.add_theme_stylebox_override("disabled", _round_icon_button_style(Color(0.18, 0.18, 0.18)))
	_add_context_button.add_theme_color_override("font_color", icon_color)
	_add_context_button.add_theme_color_override("font_disabled_color", GodexTheme.MUTED)
	_add_context_button.add_theme_color_override("icon_normal_color", icon_color)
	_add_context_button.add_theme_color_override("icon_hover_color", GodexTheme.TEXT)
	_add_context_button.add_theme_color_override("icon_pressed_color", icon_color)
	_add_context_button.add_theme_color_override("icon_disabled_color", GodexTheme.MUTED)


func _add_context_menu_items() -> Array[Dictionary]:
	var warning: Dictionary = _state.call("context_window_warning") if _state != null else {}
	var active_messages: Array = _state.call("active_messages") if _state != null else []
	var active_message_count: int = active_messages.size()
	var items: Array[Dictionary] = [
		{"id": "project_summary", "title": "当前项目摘要", "enabled": true, "symbol": "circle", "action": Callable(self, "_add_mcp_project_summary_context")},
		{"id": "image_placeholder", "title": "图片附件占位", "enabled": true, "symbol": "paperclip", "detail": "仅添加本地 UI/数据占位，不发送图片网络请求。", "action": Callable(self, "_add_image_attachment_placeholder")},
		{"id": "compact_context", "title": "压缩当前会话", "enabled": active_message_count > 24, "symbol": "compress", "detail": str(warning.get("message", "")), "action": Callable(self, "_compact_context_from_menu")},
		{"id": "plan_mode", "title": "计划模式", "enabled": true, "symbol": "plan", "kind": "toggle", "selected": bool(_state.plan_mode_enabled), "action": Callable(self, "_toggle_plan_mode_from_menu")},
		{"id": "goal_context", "title": "追求目标", "enabled": true, "symbol": "target", "kind": "toggle", "selected": bool(_state.goal_tracking_enabled), "action": Callable(self, "_toggle_goal_context_from_menu")},
		{"id": "plugins", "title": "插件", "enabled": true, "symbol": "plugins", "kind": "submenu", "action": Callable(self, "_open_plugins_from_context_menu")},
	]
	var files: Array = _state.call("recommended_context_files", 1) if _state != null else []
	if not files.is_empty():
		items.insert(1, {"id": "recommended_file", "title": "添加推荐文件", "enabled": true, "symbol": "paperclip", "action": Callable(self, "_add_first_recommended_file_context")})
	return items


func _rebuild_add_context_menu() -> void:
	if _add_context_list == null:
		return
	_clear(_add_context_list)
	_add_context_list.add_theme_constant_override("separation", int(ADD_CONTEXT_POPOVER_ROW_GAP))
	var items := _add_context_menu_items()
	for index in range(items.size()):
		_add_context_list.add_child(_build_add_context_row(index, items[index]))
		if index == 1 or index == 3:
			_add_context_list.add_child(_build_add_context_separator(index))


func _build_add_context_row(index: int, item: Dictionary) -> Button:
	var enabled := bool(item.get("enabled", false))
	var button := Button.new()
	button.name = "AddContext%s" % index
	button.custom_minimum_size = Vector2(0, ADD_CONTEXT_POPOVER_ROW_HEIGHT)
	button.text = ""
	button.disabled = not enabled
	button.tooltip_text = "%s\n%s" % [str(item.get("title", "")), str(item.get("detail", ""))]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	GodexTheme.paint_button(button)
	var content := HBoxContainer.new()
	content.name = "AddContextRowContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 18
	content.offset_right = -18
	content.offset_top = 0
	content.offset_bottom = 0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 14)
	content.add_child(_build_add_context_icon(str(item.get("symbol", "")), enabled))
	var copy := HBoxContainer.new()
	copy.name = "AddContextCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.name = "AddContextTitle"
	title.custom_minimum_size = Vector2(150, 0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text = str(item.get("title", ""))
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(title, GodexTheme.TEXT if enabled else GodexTheme.MUTED, 18)
	copy.add_child(title)
	content.add_child(copy)
	var suffix := _build_add_context_suffix(item)
	if suffix != null:
		content.add_child(suffix)
	button.add_child(content)
	if enabled:
		var action: Callable = item.get("action", Callable())
		if action.is_valid():
			button.pressed.connect(action)
	return button


func _build_add_context_icon(symbol: String, enabled: bool) -> Control:
	var icon_script := ResourceLoader.load(MENU_ICON_SCRIPT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if icon_script == null:
		var fallback := Label.new()
		fallback.name = "AddContextIcon"
		fallback.custom_minimum_size = Vector2(24, 0)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fallback.text = "+"
		GodexTheme.paint_label(fallback, GodexTheme.TEXT if enabled else GodexTheme.MUTED, 22)
		return fallback
	var icon := icon_script.new() as Control
	icon.name = "AddContextIcon"
	icon.custom_minimum_size = Vector2(24, 24)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set("icon_kind", symbol)
	icon.set("icon_color", GodexTheme.TEXT if enabled else GodexTheme.MUTED)
	return icon


func _build_add_context_suffix(item: Dictionary) -> Control:
	match str(item.get("kind", "")):
		"toggle":
			return _build_add_context_switch(bool(item.get("selected", false)))
		"submenu":
			var chevron := Label.new()
			chevron.name = "AddContextChevron"
			chevron.custom_minimum_size = Vector2(20, 0)
			chevron.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			chevron.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			chevron.text = "›"
			chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
			GodexTheme.paint_label(chevron, GodexTheme.MUTED, 24)
			return chevron
		_:
			return null


func _build_add_context_switch(enabled: bool) -> Control:
	var switch := Control.new()
	switch.name = "AddContextSwitch"
	switch.custom_minimum_size = Vector2(46, 26)
	switch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	switch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	switch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	switch.set_meta("switch_enabled", enabled)
	var track := PanelContainer.new()
	track.name = "AddContextSwitchTrack"
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = GodexTheme.BLUE if enabled else Color(0.25, 0.25, 0.25)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.set_corner_radius_all(13)
	track.add_theme_stylebox_override("panel", style)
	switch.add_child(track)
	var knob := PanelContainer.new()
	knob.name = "AddContextSwitchKnob"
	knob.custom_minimum_size = Vector2(20, 20)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var knob_style := StyleBoxFlat.new()
	knob_style.bg_color = Color(0.95, 0.96, 0.97)
	knob_style.border_color = Color(0, 0, 0, 0)
	knob_style.set_border_width_all(0)
	knob_style.set_corner_radius_all(10)
	knob.add_theme_stylebox_override("panel", knob_style)
	knob.set_anchors_preset(Control.PRESET_TOP_LEFT)
	knob.offset_left = 23 if enabled else 3
	knob.offset_right = knob.offset_left + 20
	knob.offset_top = 3
	knob.offset_bottom = 23
	switch.add_child(knob)
	return switch


func _build_add_context_separator(index: int) -> HSeparator:
	var separator := HSeparator.new()
	separator.name = "AddContextSeparator%s" % index
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	separator.add_theme_constant_override("separation", 0)
	separator.add_theme_color_override("separator", Color(0.28, 0.28, 0.28, 0.75))
	return separator


func _on_send_button_pressed() -> void:
	if _state != null and (bool(_state.get("is_running")) or str(_state.get("agent_loop_status")) == "running" or _is_openai_busy()):
		_cancel_openai_request()
		return
	if _composer == null or (_composer.text.strip_edges().is_empty() and _active_composer_references().is_empty()):
		_send_button_hovered = true
		_send_button_hint_hold_until_msec = Time.get_ticks_msec() + 1200
		_refresh_send_button_hint()
		return
	_send_prompt()


func _queue_composer_prompt(source: String = "composer_send") -> Dictionary:
	if _composer == null or _state == null:
		return {}
	var prompt := _composer_prompt_for_queue(_composer.text.strip_edges())
	if prompt.is_empty():
		return {}
	var record: Dictionary = _state.call("queue_user_message_with_action", prompt, source, _queued_action_for_prompt(prompt))
	if record.is_empty():
		return {}
	_composer.text = ""
	_clear_composer_references()
	_save_sessions()
	_apply_model(_state.call("to_model"))
	return record


func _queued_action_for_prompt(prompt: String) -> String:
	var clean_prompt := prompt.strip_edges()
	if clean_prompt.begins_with("!"):
		return "run_shell"
	if clean_prompt.begins_with("/"):
		return "parse_slash"
	return "plain"


func _queued_composer_record(message_id: String) -> Dictionary:
	if _state == null:
		return {}
	var clean_id := message_id.strip_edges()
	if clean_id.is_empty():
		return {}
	for item in _state.call("active_queued_user_messages"):
		if item is Dictionary:
			var record: Dictionary = item
			if str(record.get("id", "")) != clean_id:
				continue
			return record.duplicate(true)
	return {}


func _cancel_queued_composer_message(message_id: String) -> void:
	if _state == null:
		return
	_state.call("cancel_queued_user_message", message_id, "composer_queue")
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _guide_queued_composer_message(message_id: String) -> void:
	if _state == null:
		return
	var record := _queued_composer_record(message_id)
	var prompt := str(record.get("text", "")).strip_edges()
	if prompt.is_empty():
		return
	_state.call("cancel_queued_user_message", message_id, "composer_queue_guide")
	if bool(_state.get("is_running")) or _is_openai_busy():
		_state.call("record_pending_guide_instruction", prompt, "composer_queue_guide")
		_save_sessions()
		_apply_model(_state.call("to_model"))
		return
	_send_prompt_text(prompt, "user_prompt")
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _apply_approval_button_model(mode: String) -> void:
	_approval_button.text = "%s  v" % mode
	_approval_button.tooltip_text = "%s\n点击展开权限选项。" % _approval_mode_tooltip(mode)
	_rebuild_approval_mode_menu(mode)
	GodexTheme.paint_button(_approval_button, true)
	var assisted := mode == "替我审批"
	_approval_button.add_theme_color_override("font_color", GodexTheme.BLUE if assisted else GodexTheme.TEXT)
	_approval_button.add_theme_color_override("font_hover_color", GodexTheme.BLUE.lightened(0.12) if assisted else GodexTheme.TEXT)
	_approval_button.add_theme_color_override("font_pressed_color", GodexTheme.BLUE.darkened(0.08) if assisted else GodexTheme.TEXT)
	_approval_button.add_theme_color_override("icon_normal_color", GodexTheme.BLUE)
	_approval_button.add_theme_color_override("icon_hover_color", GodexTheme.BLUE.lightened(0.12))
	_approval_button.add_theme_color_override("icon_pressed_color", GodexTheme.BLUE.darkened(0.08))


func _apply_context_pill_model(button: Button, enabled: bool, hovered: bool, label: String, detail: String, command_hint: String, icon_candidates: Array) -> void:
	button.visible = enabled
	if not enabled:
		button.text = label
		button.icon = null
		button.tooltip_text = ""
		return
	button.text = "× %s" % label if hovered else label
	button.tooltip_text = "%s\n%s" % [detail, command_hint]
	GodexTheme.paint_button(button, true)
	if hovered:
		button.text = label if _set_button_icon(button, ["Close", "Remove", "GuiCloseCustomizable"]) else "× %s" % label
	else:
		button.text = label
		_set_button_icon(button, icon_candidates)


func _goal_pill_label(goal: Dictionary) -> String:
	var status := str(goal.get("status", "")).strip_edges()
	match status:
		"paused":
			return "目标暂停"
		"complete":
			return "目标完成"
		"blocked":
			return "目标受阻"
		_:
			return "目标"


func _goal_pill_tooltip(goal: Dictionary) -> String:
	var status := _goal_status_text(str(goal.get("status", "")))
	var summary := str(goal.get("summary", "")).strip_edges()
	if summary.is_empty():
		return "追踪当前目标并把目标状态注入回合上下文。"
	return "当前目标：%s\n状态：%s\n目标状态会注入下一次 Agent 回合上下文。" % [summary, status]


func _goal_status_text(status: String) -> String:
	match status:
		"active":
			return "进行中"
		"paused":
			return "已暂停"
		"blocked":
			return "受阻"
		"complete":
			return "已完成"
		"cleared":
			return "已关闭"
		_:
			return status if not status.is_empty() else "未设置"


func _approval_mode_tooltip(mode: String) -> String:
	match mode:
		"请求批准":
			return "请求批准：发送网络请求、执行工具或命令前会停下等待你审核。"
		"替我审批":
			return "替我审批：低风险步骤自动继续，高风险写入、命令和网络动作仍保留审核点。"
		"完全访问权限":
			return "完全访问权限：允许 Agent 更主动地连续执行；危险动作仍会留下审计记录。"
		_:
			return "切换 Codex 风格的审批模式。"


func _rebuild_model_picker(choices: Array, current_model: String) -> void:
	if _model_picker_list == null:
		return
	_clear(_model_picker_list)
	_model_picker_list.add_theme_constant_override("separation", int(MODEL_POPOVER_ROW_GAP))
	var rendered_current := false
	for index in range(choices.size()):
		var value := str(choices[index])
		if value == current_model:
			rendered_current = true
		_model_picker_list.add_child(_build_model_picker_row(index, value, value == current_model, false))
	if not rendered_current and not current_model.strip_edges().is_empty():
		_model_picker_list.add_child(_build_model_picker_row(choices.size(), current_model, true, true))


func _build_model_picker_row(index: int, value: String, selected: bool, custom: bool) -> Button:
	var title := "%s  自定义" % _model_to_menu_label(value) if custom else _model_to_menu_label(value)
	return _build_compact_picker_row(
		"ModelChoice%s" % index,
		title,
		selected,
		false,
		_on_model_picker_selected.bind(value)
	)


func _rebuild_reasoning_picker(current_effort: String) -> void:
	if _reasoning_picker_list == null:
		return
	_clear(_reasoning_picker_list)
	_reasoning_picker_list.add_theme_constant_override("separation", int(MODEL_POPOVER_ROW_GAP))
	var values := _reasoning_values()
	for index in range(values.size()):
		var value := values[index]
		_reasoning_picker_list.add_child(_build_reasoning_picker_row(index, value, value == current_effort))
	var separator := HSeparator.new()
	separator.name = "ModelPickerSeparator"
	separator.custom_minimum_size = Vector2(0, 10)
	_reasoning_picker_list.add_child(separator)
	_reasoning_picker_list.add_child(_build_model_submenu_row(str(_state.model)))


func _build_reasoning_picker_row(index: int, value: String, selected: bool) -> Button:
	return _build_compact_picker_row(
		"ReasoningChoice%s" % index,
		_reasoning_to_label(value),
		selected,
		false,
		_on_reasoning_picker_selected.bind(value)
	)


func _build_model_submenu_row(current_model: String) -> Button:
	var row := _build_compact_picker_row(
		"ModelSubmenu",
		_model_to_menu_label(current_model),
		false,
		true,
		Callable()
	)
	_model_submenu_anchor = row
	row.mouse_entered.connect(_on_model_submenu_hover_changed.bind(true, row))
	row.mouse_exited.connect(_on_model_submenu_hover_changed.bind(false, row))
	return row


func _build_compact_picker_row(name: String, title_text: String, selected: bool, chevron: bool, callback: Callable) -> Button:
	var button := Button.new()
	button.name = name
	button.custom_minimum_size = Vector2(0, MODEL_POPOVER_ROW_HEIGHT)
	button.text = ""
	button.tooltip_text = title_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	GodexTheme.paint_button(button, selected)
	var content := HBoxContainer.new()
	content.name = "PickerRowContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 10
	content.offset_right = -10
	content.offset_top = 0
	content.offset_bottom = 0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.name = "PickerTitle"
	title.text = title_text
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(title, GodexTheme.TEXT, 16)
	content.add_child(title)
	var check := Label.new()
	check.name = "PickerCheck"
	check.custom_minimum_size = Vector2(20, 0)
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	check.text = "›" if chevron else ("✓" if selected else "")
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(check, GodexTheme.TEXT, 22 if chevron else 18)
	content.add_child(check)
	button.add_child(content)
	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _rebuild_threads(items: Array) -> void:
	_hide_thread_rename_panel()
	_hide_thread_action_menu()
	_configure_thread_hover_watch()
	_clear(_thread_list)
	var sorted_items: Array = items.duplicate(true)
	sorted_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a.get("archived", false)) != bool(b.get("archived", false)):
			return not bool(a.get("archived", false))
		if bool(a.get("pinned", false)) != bool(b.get("pinned", false)):
			return bool(a.get("pinned", false))
		return str(a.get("title", "")) < str(b.get("title", ""))
	)
	var has_pinned := false
	var has_regular := false
	for item in sorted_items:
		if bool(item.get("archived", false)):
			continue
		if bool(item.get("pinned", false)):
			has_pinned = true
		else:
			has_regular = true
	var current_group := ""
	for item in sorted_items:
		if bool(item.get("archived", false)):
			continue
		var next_group := "已置顶" if bool(item.get("pinned", false)) else "最近"
		if has_pinned and has_regular and next_group != current_group:
			_thread_list.add_child(_build_thread_group_label(next_group))
			current_group = next_group
		_thread_list.add_child(_build_thread_row(item))
	_start_thread_hover_watch()


func _build_thread_row(item: Dictionary) -> PanelContainer:
	var thread_id := str(item.get("id", ""))
	var selected := _active_sidebar_surface == "thread" and str(item.get("status", "")) == "active"
	var row := PanelContainer.new()
	row.name = "ThreadRow_%s" % thread_id
	row.custom_minimum_size = Vector2(0, 34)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.clip_contents = true
	row.set_meta("thread_selected", selected)
	row.set_meta("thread_id", thread_id)
	_paint_thread_row_panel(row, selected, false)
	var content := HBoxContainer.new()
	content.name = "ThreadRowContent"
	content.add_theme_constant_override("separation", 4)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Button.new()
	title.name = "ThreadTitle_%s" % thread_id
	title.text = "%s%s" % ["★ " if bool(item.get("pinned", false)) else "", str(item.get("title", ""))]
	title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.clip_text = true
	title.tooltip_text = ""
	_paint_thread_content_button(title, selected)
	title.pressed.connect(_on_thread_selected.bind(thread_id, str(item.get("action", ""))))
	var right_slot := Control.new()
	right_slot.name = "ThreadRightSlot_%s" % thread_id
	right_slot.custom_minimum_size = Vector2(88, 0)
	right_slot.size_flags_horizontal = Control.SIZE_FILL
	right_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	var age := Label.new()
	age.name = "ThreadAge_%s" % thread_id
	age.text = str(item.get("age", ""))
	age.set_anchors_preset(Control.PRESET_FULL_RECT)
	age.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	age.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	age.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(age, GodexTheme.MUTED, 13)
	var actions := HBoxContainer.new()
	actions.name = "ThreadActions_%s" % thread_id
	actions.set_anchors_preset(Control.PRESET_FULL_RECT)
	actions.add_theme_constant_override("separation", 4)
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.mouse_filter = Control.MOUSE_FILTER_PASS
	var pin := _build_thread_inline_action_button("ThreadPin_%s" % thread_id, "取消置顶" if bool(item.get("pinned", false)) else "置顶", ["Pin", "Favorites"])
	pin.pressed.connect(_toggle_pin_thread_inline.bind(thread_id))
	var archive := _build_thread_inline_action_button("ThreadArchive_%s" % thread_id, "归档", ["Archive", "MoveDown", "Folder"])
	archive.pressed.connect(_archive_thread_inline.bind(thread_id, row))
	actions.add_child(pin)
	actions.add_child(archive)
	pin.visible = false
	archive.visible = false
	actions.visible = false
	row.set_meta("thread_age_name", age.name)
	row.set_meta("thread_actions_name", actions.name)
	row.set_meta("thread_pin_name", pin.name)
	row.set_meta("thread_archive_name", archive.name)
	row.mouse_entered.connect(_on_thread_row_hover_changed.bind(row, selected, true))
	row.mouse_exited.connect(_on_thread_row_hover_changed.bind(row, selected, false))
	title.mouse_entered.connect(_on_thread_row_hover_changed.bind(row, selected, true))
	title.mouse_exited.connect(_on_thread_row_hover_changed.bind(row, selected, false))
	actions.mouse_entered.connect(_on_thread_row_hover_changed.bind(row, selected, true))
	actions.mouse_exited.connect(_on_thread_row_hover_changed.bind(row, selected, false))
	pin.mouse_entered.connect(_on_thread_row_hover_changed.bind(row, selected, true))
	pin.mouse_exited.connect(_on_thread_row_hover_changed.bind(row, selected, false))
	archive.mouse_entered.connect(_on_thread_row_hover_changed.bind(row, selected, true))
	archive.mouse_exited.connect(_on_thread_row_hover_changed.bind(row, selected, false))
	_set_thread_row_actions(row, selected, false)
	content.add_child(title)
	content.add_child(right_slot)
	right_slot.add_child(age)
	right_slot.add_child(actions)
	row.add_child(content)
	_set_thread_row_actions(row, selected, false)
	return row


func _paint_thread_row_panel(row: PanelContainer, selected: bool, hovered: bool) -> void:
	var color := Color(0, 0, 0, 0)
	if selected:
		color = Color(0.16, 0.18, 0.20)
	elif hovered:
		color = Color(0.13, 0.15, 0.17)
	var style := GodexTheme.panel_style(color, 8, Color(0, 0, 0, 0))
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	row.add_theme_stylebox_override("panel", style)


func _paint_thread_content_button(button: Button, selected: bool) -> void:
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", GodexTheme.TEXT if selected else Color(0.78, 0.80, 0.82))
	button.add_theme_color_override("font_hover_color", GodexTheme.TEXT)
	button.add_theme_color_override("font_pressed_color", GodexTheme.TEXT)


func _build_thread_inline_action_button(name: String, text: String, icon_candidates: Array) -> Button:
	var button := Button.new()
	button.name = name
	button.text = ""
	button.set_meta("action_label", text)
	button.custom_minimum_size = Vector2(30, 26)
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = ""
	button.visible = false
	_set_button_icon(button, icon_candidates)
	_paint_thread_inline_action_button(button, false)
	return button


func _paint_thread_inline_action_button(button: Button, destructive: bool) -> void:
	var bg := Color(0.20, 0.21, 0.22)
	var hover_bg := Color(0.25, 0.26, 0.27)
	var pressed_bg := Color(0.28, 0.29, 0.30)
	var color := GodexTheme.TEXT
	if destructive:
		bg = Color(0.32, 0.10, 0.10)
		hover_bg = Color(0.42, 0.12, 0.12)
		pressed_bg = Color(0.50, 0.14, 0.14)
		color = Color(1.00, 0.54, 0.54)
	button.flat = true
	button.add_theme_stylebox_override("normal", GodexTheme.button_style(bg, false))
	button.add_theme_stylebox_override("hover", GodexTheme.button_style(hover_bg, false))
	button.add_theme_stylebox_override("pressed", GodexTheme.button_style(pressed_bg, destructive))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	button.add_theme_color_override("icon_normal_color", color)
	button.add_theme_color_override("icon_hover_color", color)
	button.add_theme_color_override("icon_pressed_color", color)


func _on_thread_row_hover_changed(row: PanelContainer, selected: bool, hovered: bool) -> void:
	if row == null or not is_instance_valid(row):
		return
	if hovered:
		_clear_thread_hover_states(row)
	_paint_thread_row_panel(row, selected, hovered)
	_set_thread_row_actions(row, selected, hovered)
	if hovered:
		_start_thread_hover_watch()
	else:
		_refresh_thread_hover_states()
		call_deferred("_refresh_thread_hover_states")


func _set_thread_row_actions(row: PanelContainer, selected: bool, hovered: bool) -> void:
	var age := row.find_child(str(row.get_meta("thread_age_name", "")), true, false) as Control
	var actions := row.find_child(str(row.get_meta("thread_actions_name", "")), true, false) as Control
	var thread_id := str(row.get_meta("thread_id", ""))
	var confirming := not thread_id.is_empty() and _thread_archive_confirm_id == thread_id
	if age != null:
		age.visible = not hovered and not confirming
	if actions != null:
		actions.visible = hovered or confirming
		actions.mouse_filter = Control.MOUSE_FILTER_PASS if actions.visible else Control.MOUSE_FILTER_IGNORE
	var archive := row.find_child(str(row.get_meta("thread_archive_name", "")), true, false) as Button
	var pin := row.find_child(str(row.get_meta("thread_pin_name", "")), true, false) as Button
	if pin != null:
		pin.visible = hovered and not confirming
	if archive != null:
		archive.visible = hovered or confirming
		archive.text = "确认" if confirming else ""
		archive.custom_minimum_size = Vector2(48, 26) if confirming else Vector2(30, 26)
		_paint_thread_inline_action_button(archive, confirming)


func _reset_thread_archive_confirm_if_row(row: PanelContainer) -> void:
	var thread_id := str(row.get_meta("thread_id", ""))
	if not thread_id.is_empty() and _thread_archive_confirm_id == thread_id:
		_thread_archive_confirm_id = ""


func _toggle_pin_thread_inline(thread_id: String) -> void:
	if thread_id.is_empty():
		return
	var toggled: Dictionary = _state.call("toggle_pin_session", thread_id)
	if toggled.is_empty():
		return
	_thread_archive_confirm_id = ""
	_save_sessions()
	_refresh_thread_action_model()


func _archive_thread_inline(thread_id: String, row: PanelContainer) -> void:
	if thread_id.is_empty():
		return
	if _thread_archive_confirm_id != thread_id:
		_thread_archive_confirm_id = thread_id
		if row != null and is_instance_valid(row):
			_paint_thread_row_panel(row, bool(row.get_meta("thread_selected", false)), true)
			_set_thread_row_actions(row, bool(row.get_meta("thread_selected", false)), true)
		_start_thread_hover_watch()
		return
	_thread_archive_confirm_id = ""
	_archive_thread(thread_id)


func _paint_sidebar_nav_button(button: Button, selected: bool, hovered: bool) -> void:
	if button == null:
		return
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 40)
	var color := Color(0, 0, 0, 0)
	if selected:
		color = Color(0.16, 0.18, 0.20)
	elif hovered:
		color = Color(0.13, 0.15, 0.17)
	var border := Color(0.28, 0.30, 0.32) if selected else (Color(0.22, 0.24, 0.26) if hovered else Color(0, 0, 0, 0))
	var normal := GodexTheme.panel_style(color, 8, border)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover_border := Color(0.28, 0.30, 0.32) if selected else Color(0.22, 0.24, 0.26)
	var hover := GodexTheme.panel_style(Color(0.18, 0.20, 0.22), 8, hover_border)
	hover.content_margin_left = 12
	hover.content_margin_right = 12
	hover.content_margin_top = 4
	hover.content_margin_bottom = 4
	var pressed := GodexTheme.panel_style(Color(0.20, 0.22, 0.24), 8, Color(0.32, 0.34, 0.36))
	pressed.content_margin_left = 12
	pressed.content_margin_right = 12
	pressed.content_margin_top = 4
	pressed.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var color_text := GodexTheme.TEXT if selected or hovered else Color(0.78, 0.80, 0.82)
	button.add_theme_color_override("font_color", color_text)
	button.add_theme_color_override("font_hover_color", GodexTheme.TEXT)
	button.add_theme_color_override("font_pressed_color", GodexTheme.TEXT)
	button.add_theme_color_override("icon_normal_color", color_text)
	button.add_theme_color_override("icon_hover_color", GodexTheme.TEXT)
	button.add_theme_color_override("icon_pressed_color", GodexTheme.TEXT)


func _on_nav_button_hover_changed(key: String, hovered: bool) -> void:
	_nav_hovered[key] = hovered
	_refresh_nav_state()


func _clear_thread_hover_states(except_row: PanelContainer = null) -> void:
	if _thread_list == null or not is_instance_valid(_thread_list):
		_stop_thread_hover_watch()
		return
	for child in _thread_list.get_children():
		if not (child is PanelContainer) or not str(child.name).begins_with("ThreadRow_"):
			continue
		var row := child as PanelContainer
		if except_row != null and row == except_row:
			continue
		var selected := bool(row.get_meta("thread_selected", false))
		_reset_thread_archive_confirm_if_row(row)
		_paint_thread_row_panel(row, selected, false)
		_set_thread_row_actions(row, selected, false)
	if except_row == null:
		_stop_thread_hover_watch()


func _start_thread_hover_watch() -> void:
	if _thread_hover_watch == null or not is_instance_valid(_thread_hover_watch):
		_configure_thread_hover_watch()
	if _thread_hover_watch == null or not is_instance_valid(_thread_hover_watch) or not _thread_hover_watch.is_inside_tree():
		return
	if _thread_hover_watch != null and is_instance_valid(_thread_hover_watch) and _thread_hover_watch.is_stopped():
		_thread_hover_watch.start()


func _stop_thread_hover_watch() -> void:
	if _thread_hover_watch != null and is_instance_valid(_thread_hover_watch):
		_thread_hover_watch.stop()


func _refresh_thread_hover_states() -> void:
	if _thread_list == null or not is_instance_valid(_thread_list):
		_stop_thread_hover_watch()
		return
	if _thread_list.get_viewport() == null:
		for child in _thread_list.get_children():
			if not (child is PanelContainer) or not str(child.name).begins_with("ThreadRow_"):
				continue
			var headless_row := child as PanelContainer
			var headless_selected := bool(headless_row.get_meta("thread_selected", false))
			_paint_thread_row_panel(headless_row, headless_selected, false)
			_set_thread_row_actions(headless_row, headless_selected, false)
		_stop_thread_hover_watch()
		return
	var pointer := _thread_list.get_global_mouse_position()
	var list_hovered := _thread_list.get_global_rect().grow(2.0).has_point(pointer)
	var any_row_hovered := false
	for child in _thread_list.get_children():
		if not (child is PanelContainer) or not str(child.name).begins_with("ThreadRow_"):
			continue
		var row := child as PanelContainer
		var selected := bool(row.get_meta("thread_selected", false))
		var hovered := row.get_global_rect().grow(1.0).has_point(pointer)
		any_row_hovered = any_row_hovered or hovered
		_paint_thread_row_panel(row, selected, hovered)
		if not hovered:
			_reset_thread_archive_confirm_if_row(row)
		_set_thread_row_actions(row, selected, hovered)
	if not list_hovered and not any_row_hovered:
		_thread_archive_confirm_id = ""
		_stop_thread_hover_watch()


func _build_thread_group_label(text: String) -> Label:
	var label := Label.new()
	label.name = "ThreadGroup_%s" % text
	label.text = text
	label.custom_minimum_size = Vector2(0, 24)
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(label, GodexTheme.MUTED, 12)
	return label


func _show_thread_action_menu(thread_id: String, current_title: String, pinned: bool, anchor: Control) -> void:
	if thread_id.is_empty():
		return
	_ensure_thread_action_menu()
	_thread_action_menu_target_id = thread_id
	_thread_action_menu_target_title = current_title
	_thread_action_menu_target_pinned = pinned
	_rebuild_thread_action_menu()
	_thread_action_menu.visible = true
	_thread_action_menu.move_to_front()
	var anchor_rect := anchor.get_global_rect()
	var target_size := Vector2(214, 168)
	var x := _clamp_popover_x(anchor_rect.position.x + anchor_rect.size.x - target_size.x, target_size.x)
	var y := anchor_rect.position.y + anchor_rect.size.y + 4
	_set_popover_rect(_thread_action_menu, Vector2(x, y), target_size)


func _ensure_thread_action_menu() -> void:
	if _thread_action_menu != null and is_instance_valid(_thread_action_menu):
		return
	_thread_action_menu = PanelContainer.new()
	_thread_action_menu.name = "ThreadActionMenu"
	_thread_action_menu.visible = false
	_thread_action_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	_thread_action_menu.add_theme_stylebox_override("panel", _composer_popover_style())
	var margin := MarginContainer.new()
	margin.name = "ThreadActionMenuMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_thread_action_menu_list = VBoxContainer.new()
	_thread_action_menu_list.name = "ThreadActionMenuList"
	_thread_action_menu_list.add_theme_constant_override("separation", 2)
	margin.add_child(_thread_action_menu_list)
	_thread_action_menu.add_child(margin)
	var parent := _composer_popover_layer if _composer_popover_layer != null else _root
	parent.add_child(_thread_action_menu)
	_thread_action_menu.set_anchors_preset(Control.PRESET_TOP_LEFT)


func _rebuild_thread_action_menu() -> void:
	if _thread_action_menu_list == null:
		return
	_clear(_thread_action_menu_list)
	var rows := [
		{"title": "重命名", "detail": "编辑会话标题", "icon": "✎", "action": Callable(self, "_rename_thread_from_menu")},
		{"title": "取消置顶" if _thread_action_menu_target_pinned else "置顶", "detail": "从固定列表移除" if _thread_action_menu_target_pinned else "固定到列表顶部", "icon": "★", "action": Callable(self, "_toggle_pin_thread_from_menu")},
		{"title": "创建分支", "detail": "从此会话创建副本", "icon": "⎇", "action": Callable(self, "_fork_thread_from_menu")},
		{"title": "归档", "detail": "从列表中隐藏", "icon": "×", "action": Callable(self, "_archive_thread_from_menu")},
	]
	for row in rows:
		_thread_action_menu_list.add_child(_build_thread_action_menu_row(row))


func _build_thread_action_menu_row(item: Dictionary) -> Button:
	var button := Button.new()
	button.name = "ThreadAction_%s" % str(item.get("title", ""))
	button.flat = true
	button.custom_minimum_size = Vector2(0, 36)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = str(item.get("detail", ""))
	GodexTheme.paint_button(button)
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8
	content.offset_right = -8
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)
	var icon := Label.new()
	icon.text = str(item.get("icon", ""))
	icon.custom_minimum_size = Vector2(18, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var title := Label.new()
	title.text = str(item.get("title", ""))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title)
	button.add_child(content)
	var action: Callable = item.get("action", Callable())
	if action.is_valid():
		button.pressed.connect(action)
	return button


func _rename_thread_from_menu() -> void:
	var thread_id := _thread_action_menu_target_id
	var title := _thread_action_menu_target_title
	var anchor := _thread_action_menu
	_hide_thread_action_menu()
	_show_thread_rename_panel(thread_id, title, anchor)


func _fork_thread_from_menu() -> void:
	var thread_id := _thread_action_menu_target_id
	_hide_thread_action_menu()
	_fork_thread(thread_id)


func _toggle_pin_thread_from_menu() -> void:
	var thread_id := _thread_action_menu_target_id
	_hide_thread_action_menu()
	if thread_id.is_empty():
		return
	var toggled: Dictionary = _state.call("toggle_pin_session", thread_id)
	if toggled.is_empty():
		return
	_save_sessions()
	_refresh_thread_action_model()


func _archive_thread_from_menu() -> void:
	var thread_id := _thread_action_menu_target_id
	_hide_thread_action_menu()
	_archive_thread(thread_id)


func _hide_thread_action_menu() -> void:
	_thread_action_menu_target_id = ""
	_thread_action_menu_target_title = ""
	_thread_action_menu_target_pinned = false
	if _thread_action_menu != null:
		_thread_action_menu.visible = false


func _show_thread_rename_panel(thread_id: String, current_title: String, anchor: Control) -> void:
	if thread_id.is_empty():
		return
	_hide_thread_action_menu()
	_ensure_thread_rename_panel()
	_thread_rename_target_id = thread_id
	_thread_rename_input.text = current_title
	_thread_rename_input.select_all()
	_thread_rename_panel.visible = true
	_thread_rename_panel.move_to_front()
	var anchor_rect := anchor.get_global_rect()
	var target_size := Vector2(260, 38)
	var x := _clamp_popover_x(anchor_rect.position.x + anchor_rect.size.x - target_size.x, target_size.x)
	var y := anchor_rect.position.y + anchor_rect.size.y + 4
	_set_popover_rect(_thread_rename_panel, Vector2(x, y), target_size)
	if _thread_rename_input.is_inside_tree():
		_thread_rename_input.call_deferred("grab_focus")


func _ensure_thread_rename_panel() -> void:
	if _thread_rename_panel != null and is_instance_valid(_thread_rename_panel):
		return
	_thread_rename_panel = PanelContainer.new()
	_thread_rename_panel.name = "ThreadRenamePanel"
	_thread_rename_panel.visible = false
	_thread_rename_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_thread_rename_panel.add_theme_stylebox_override("panel", _composer_popover_style())
	var margin := MarginContainer.new()
	margin.name = "ThreadRenameMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	_thread_rename_input = LineEdit.new()
	_thread_rename_input.name = "ThreadRenameInput"
	_thread_rename_input.placeholder_text = "重命名会话"
	_thread_rename_input.tooltip_text = "输入新的会话标题，按 Enter 保存。"
	_thread_rename_input.text_submitted.connect(_commit_thread_rename)
	margin.add_child(_thread_rename_input)
	_thread_rename_panel.add_child(margin)
	var parent := _composer_popover_layer if _composer_popover_layer != null else _root
	parent.add_child(_thread_rename_panel)
	_thread_rename_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)


func _commit_thread_rename(value: String) -> void:
	var renamed: Dictionary = _state.call("rename_session", _thread_rename_target_id, value)
	if renamed.is_empty():
		_hide_thread_rename_panel()
		return
	_hide_thread_rename_panel()
	_save_sessions()
	_refresh_thread_action_model()


func _hide_thread_rename_panel() -> void:
	_thread_rename_target_id = ""
	if _thread_rename_panel != null:
		_thread_rename_panel.visible = false


func _refresh_thread_action_model() -> void:
	var model: Dictionary = _state.call("to_model")
	if _root != null and _main_title != null:
		_apply_model(model)
	elif _thread_list != null:
		_rebuild_threads(model.get("threads", []))


func _rebuild_progress(model: Dictionary) -> void:
	_clear(_progress_list)
	var rows: Array = _progress_rows(model.get("progress_items", []), model)
	if _progress_section != null:
		_progress_section.visible = not rows.is_empty()
	for item in rows:
		var row := HBoxContainer.new()
		row.name = "RightRailProgressRow"
		row.add_theme_constant_override("separation", 12)
		var detail := str(item.get("detail", "")).strip_edges()
		row.tooltip_text = detail
		var mark := Label.new()
		mark.name = "RightRailProgressMark"
		mark.custom_minimum_size = Vector2(24, 0)
		var done := bool(item.get("done", false))
		mark.text = "✓" if done else "○"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		GodexTheme.paint_label(mark, GodexTheme.GREEN if done else GodexTheme.MUTED, 20)
		var text := Label.new()
		text.name = "RightRailProgressText"
		text.text = str(item.get("title", ""))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.tooltip_text = detail
		GodexTheme.paint_label(text, GodexTheme.TEXT if done else GodexTheme.MUTED, 16)
		row.add_child(mark)
		row.add_child(text)
		_progress_list.add_child(row)
	_update_right_rail_dividers()


func _rebuild_outputs(artifact_items: Array) -> void:
	_clear(_output_list)
	var rows: Array = _artifact_rows(artifact_items)
	if rows.is_empty():
		_output_list.add_child(_build_right_rail_empty_label("暂无产物"))
	else:
		for item in rows:
			_output_list.add_child(_build_right_rail_output_row(item))
	_set_right_rail_section_visible(_output_section, true)
	_update_right_rail_dividers()


func _rebuild_bottom_terminal(_model: Dictionary) -> void:
	if _bottom_output_list == null:
		return
	_clear(_bottom_output_list)
	var rows := _bottom_terminal_rows()
	if rows.is_empty():
		_bottom_output_list.add_child(_build_bottom_terminal_empty_row())
	else:
		for item in rows:
			_bottom_output_list.add_child(_build_bottom_terminal_row(item))
	if _bottom_output_scroll != null:
		_bottom_output_scroll.call_deferred("set_v_scroll", int(_bottom_output_scroll.get_v_scroll_bar().max_value))


func _bottom_terminal_rows(limit: int = 4) -> Array:
	var rows: Array = []
	var events: Array = _state.call("active_model_events") if _state != null else []
	for event in events:
		if not (event is Dictionary):
			continue
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if data.is_empty():
			continue
		rows.append(data)
	if rows.size() > limit:
		return rows.slice(rows.size() - limit, rows.size())
	return rows


func _build_bottom_terminal_empty_row() -> Control:
	var row := HBoxContainer.new()
	row.name = "BottomTerminalEmpty"
	row.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.name = "BottomTerminalEmptyIcon"
	icon.custom_minimum_size = Vector2(18, 18)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _editor_icon_texture(["Terminal", "Console", "Output"])
	row.add_child(icon)
	var label := Label.new()
	label.name = "BottomTerminalEmptyText"
	label.text = "暂无命令运行。批准并执行命令后，终端面板会显示审计状态、runner、输出和时间线。"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GodexTheme.paint_label(label, GodexTheme.MUTED, 12)
	row.add_child(label)
	return row


func _build_bottom_terminal_row(command_run: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "BottomTerminalCommandRow"
	panel.tooltip_text = "命令：%s\nShell：%s\n工作目录：%s" % [
		str(command_run.get("command", "")),
		str(command_run.get("shell", "")),
		str(command_run.get("working_directory", "")),
	]
	panel.add_theme_stylebox_override("panel", _transparent_panel_style(0, 4, 0, 4))
	var box := VBoxContainer.new()
	box.name = "BottomTerminalCommandBox"
	box.add_theme_constant_override("separation", 3)
	box.add_child(_bottom_terminal_header(command_run))
	var result_value = command_run.get("result", {})
	var result: Dictionary = result_value if result_value is Dictionary else {}
	for line in _bottom_terminal_result_lines(command_run, result):
		box.add_child(_bottom_terminal_line(line, GodexTheme.MUTED))
	var output := _bottom_terminal_output_preview(result)
	if not output.is_empty():
		box.add_child(_bottom_terminal_line(output, GodexTheme.TEXT))
	var timeline := _bottom_terminal_timeline_preview(command_run)
	if not timeline.is_empty():
		box.add_child(_bottom_terminal_line(timeline, GodexTheme.MUTED))
	panel.add_child(box)
	return panel


func _bottom_terminal_header(command_run: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "BottomTerminalHeader"
	row.add_theme_constant_override("separation", 8)
	var status := Label.new()
	status.name = "BottomTerminalStatus"
	status.custom_minimum_size = Vector2(92, 0)
	status.text = _command_transcript_status_text(str(command_run.get("status", "")))
	GodexTheme.paint_label(status, _bottom_terminal_status_color(str(command_run.get("status", ""))), 12)
	row.add_child(status)
	var command := Label.new()
	command.name = "BottomTerminalCommand"
	command.text = str(command_run.get("command", "")).strip_edges()
	command.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	command.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GodexTheme.paint_label(command, GodexTheme.TEXT, 12)
	row.add_child(command)
	var shell := Label.new()
	shell.name = "BottomTerminalShell"
	shell.text = str(command_run.get("shell", "")).strip_edges()
	shell.custom_minimum_size = Vector2(110, 0)
	shell.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	GodexTheme.paint_label(shell, GodexTheme.MUTED, 12)
	row.add_child(shell)
	return row


func _bottom_terminal_result_lines(command_run: Dictionary, result: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var cwd := str(command_run.get("working_directory", "")).strip_edges()
	var timeout := str(command_run.get("timeout_sec", "")).strip_edges()
	var metadata := _join_non_empty([cwd, "timeout %ss" % timeout if not timeout.is_empty() else ""], " · ")
	if not metadata.is_empty():
		lines.append(metadata)
	var runner := _command_runner_label(str(result.get("runner_kind", ""))).strip_edges()
	var exit_detail := ""
	if result.has("exit_code"):
		exit_detail = "exit %s" % str(result.get("exit_code", ""))
	var duration := ""
	if result.has("duration_ms"):
		duration = "%sms" % str(result.get("duration_ms", ""))
	var execution := _join_non_empty([runner, exit_detail, duration], " · ")
	if not execution.is_empty():
		lines.append(execution)
	if result.has("timeout_enforced") and not bool(result.get("timeout_enforced", true)):
		lines.append("timeout configured only; current runner cannot hard-kill a process tree")
	if bool(result.get("stderr_merged", false)):
		lines.append(str(result.get("stderr_notice", COMMAND_EXECUTION_OUTPUT_MERGED_NOTICE)).strip_edges())
	return lines


func _bottom_terminal_output_preview(result: Dictionary) -> String:
	for key in ["combined_output", "stdout", "stderr"]:
		var value := str(result.get(key, "")).strip_edges()
		if value.is_empty():
			continue
		if value.length() > 420:
			value = "%s..." % value.left(420).strip_edges()
		return "%s › %s" % [key, value]
	return ""


func _bottom_terminal_timeline_preview(command_run: Dictionary) -> String:
	var timeline_value = command_run.get("timeline", [])
	if not (timeline_value is Array) or timeline_value.is_empty():
		return ""
	var parts: Array[String] = []
	for item in timeline_value.slice(max(timeline_value.size() - 3, 0), timeline_value.size()):
		if not (item is Dictionary):
			continue
		var status := _command_transcript_status_text(str(item.get("status", "")))
		var summary := str(item.get("summary", "")).strip_edges()
		parts.append("%s %s" % [status, summary])
	return "timeline · %s" % " / ".join(parts) if not parts.is_empty() else ""


func _bottom_terminal_line(text: String, color: Color) -> Label:
	var label := Label.new()
	label.name = "BottomTerminalDetail"
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(label, color, 12)
	return label


func _bottom_terminal_status_color(status: String) -> Color:
	match status:
		"completed":
			return GodexTheme.GREEN
		"running", "approved", "approval_required", "queued":
			return GodexTheme.BLUE
		"failed", "timed_out", "blocked", "rejected", "cancelled":
			return BOTTOM_TERMINAL_ERROR_COLOR
		_:
			return GodexTheme.MUTED


func _progress_rows(items: Array, model: Dictionary = {}) -> Array:
	var rows: Array = []
	for item in items:
		if not (item is Dictionary):
			continue
		var record: Dictionary = item
		var title := str(record.get("title", "")).strip_edges()
		if title.is_empty():
			continue
		var status := str(record.get("status", "")).strip_edges()
		rows.append({
			"title": title,
			"detail": str(record.get("detail", "")).strip_edges(),
			"done": bool(record.get("done", false)) or status in ["done", "completed", "complete"],
		})
	return rows


func _openai_transport_stage_from_request(item: Dictionary) -> String:
	var stage := str(item.get("stage", "")).strip_edges()
	if not stage.is_empty():
		return stage
	var source := str(item.get("source", "")).strip_edges()
	if source == "provider_probe":
		return "provider_probe"
	if bool(item.get("compatibility_fallback_attempted", false)) or str(item.get("compatibility_fallback_mode", "")).strip_edges() == "plain_chat":
		return "compatibility_fallback"
	if bool(item.get("stream_fallback_attempted", false)):
		return "stream_fallback"
	var reason := str(item.get("reason", item.get("error", ""))).strip_edges()
	if reason.begins_with("stream_") or reason.begins_with("http_"):
		return "stream"
	return "openai"


func _openai_transport_stage_label(item: Dictionary, fallback: String = "OpenAI 请求") -> String:
	var status := str(item.get("status", "")).strip_edges()
	var reason := str(item.get("reason", item.get("error", ""))).strip_edges()
	var stage := _openai_transport_stage_from_request(item)
	if status.begins_with("provider_probe") or stage == "provider_probe":
		if status.ends_with("blocked"):
			return "Provider 探针阻塞"
		if status.ends_with("failed") or status == "failed":
			return "Provider 探针失败"
		if status.ends_with("completed") or status == "completed":
			return "Provider 探针完成"
		return "Provider 探针"
	if status == "compatibility_fallback" or stage == "compatibility_fallback":
		if status == "failed" or reason.find("compatibility") >= 0:
			return "纯文本降级失败"
		return "纯文本降级"
	if status == "stream_fallback" or stage == "stream_fallback":
		if status == "failed" or reason.find("fallback") >= 0:
			return "非流式回退失败"
		return "非流式回退"
	if stage == "non_stream_direct":
		if status == "failed" or status == "request_failed":
			return "非流式请求失败"
		if status == "completed":
			return "非流式请求完成"
		return "非流式请求"
	if reason.begins_with("stream_") or str(item.get("stream_path", "")).strip_edges() != "":
		if status == "failed" or reason.begins_with("stream_") or reason.begins_with("http_"):
			return "流式请求失败"
		return "流式请求"
	if status == "request_failed":
		return "请求启动失败"
	if status == "request_starting" or status == "request_sent":
		return "正在请求"
	if status == "failed":
		return "请求失败"
	if status == "completed":
		return "请求完成"
	return fallback


func _artifact_rows(artifact_items: Array) -> Array:
	var rows: Array = []
	var seen: Dictionary = {}
	for item in artifact_items:
		if item is Dictionary:
			var item_key := _artifact_row_key(item)
			if seen.has(item_key):
				continue
			seen[item_key] = true
			rows.append(item)
	var summary: Dictionary = _state.get("change_review_summary") if _state != null else {}
	for file in summary.get("files", []):
		if not (file is Dictionary):
			continue
		var path := str(file.get("path", "")).strip_edges().replace("\\", "/")
		if path.is_empty():
			continue
		var row := {
			"title": path.get_file(),
			"detail": path,
			"path": path,
			"kind": "文件",
			"icon": ["File", "TextFile"],
			"source": "change_review",
		}
		var row_key := _artifact_row_key(row)
		if seen.has(row_key):
			continue
		seen[row_key] = true
		rows.append(row)
	return rows


func _artifact_row_key(item: Dictionary) -> String:
	var path := str(item.get("path", item.get("detail", ""))).strip_edges().replace("\\", "/")
	if not path.is_empty():
		return "%s:%s" % [str(item.get("source", "manual")), path]
	return "%s:%s:%s" % [
		str(item.get("source", "manual")),
		str(item.get("kind", "")),
		str(item.get("title", "")),
	]


func _apply_change_review_model(summary: Dictionary) -> void:
	if _change_review_surface == null:
		return
	var visible := not summary.is_empty() and int(summary.get("file_count", 0)) > 0
	_change_review_surface.visible = visible and _active_view == "chat"
	if not visible:
		_change_review_files.visible = false
		return
	var expanded := bool(summary.get("expanded", false))
	var file_count := int(summary.get("file_count", 0))
	var added := int(summary.get("added", 0))
	var removed := int(summary.get("removed", 0))
	var title := str(summary.get("title", "文件已更改"))
	_change_review_toggle.text = "⌄" if expanded else "›"
	_change_review_toggle.tooltip_text = "收起变更摘要。" if expanded else "展开变更摘要。"
	_change_review_title.text = "%d 个%s" % [file_count, title]
	_change_review_title.tooltip_text = "当前会话记录的待审查文件变更摘要。"
	_change_review_added.custom_minimum_size = Vector2(58, 0)
	_change_review_removed.custom_minimum_size = Vector2(58, 0)
	_change_review_added.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_change_review_removed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_set_change_review_delta_label(_change_review_added, added, "+", GodexTheme.GREEN)
	_set_change_review_delta_label(_change_review_removed, removed, "-", Color(1.0, 0.42, 0.42))
	_change_review_action.tooltip_text = "打开变更审查摘要。"
	GodexTheme.paint_label(_change_review_title, GodexTheme.TEXT, 13)
	_change_review_files.visible = expanded
	_clear(_change_review_files)
	if expanded:
		for file in summary.get("files", []):
			if file is Dictionary:
				_change_review_files.add_child(_build_change_review_file_row(file))
		var hidden_count := int(summary.get("hidden_file_count", 0))
		if hidden_count > 0:
			var more := Label.new()
			more.text = "再显示 %d 个" % hidden_count
			GodexTheme.paint_label(more, GodexTheme.MUTED, 12)
			_change_review_files.add_child(more)


func _build_change_review_file_row(file: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "ChangeReviewFileRow"
	row.add_theme_constant_override("separation", 8)
	var path := Label.new()
	path.name = "ChangeReviewFilePath"
	path.text = str(file.get("path", ""))
	path.clip_text = true
	path.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GodexTheme.paint_label(path, GodexTheme.TEXT, 12)
	var added := Label.new()
	added.name = "ChangeReviewFileAdded"
	added.custom_minimum_size = Vector2(58, 0)
	added.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	added.text = "+%d" % int(file.get("added", 0))
	GodexTheme.paint_label(added, GodexTheme.GREEN, 12)
	var removed := Label.new()
	removed.name = "ChangeReviewFileRemoved"
	removed.custom_minimum_size = Vector2(58, 0)
	removed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	removed.text = "-%d" % int(file.get("removed", 0))
	GodexTheme.paint_label(removed, Color(1.0, 0.42, 0.42), 12)
	row.add_child(path)
	row.add_child(added)
	row.add_child(removed)
	return row


func _set_change_review_delta_label(label: Label, value: int, prefix: String, color: Color) -> void:
	label.custom_minimum_size = Vector2(58, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	GodexTheme.paint_label(label, color, 13)
	var previous := int(label.get_meta("godex_delta_value", value))
	label.set_meta("godex_delta_value", value)
	if previous == value or not label.is_inside_tree():
		label.text = "%s%d" % [prefix, value]
		return
	var tween := label.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_method(func(current: float) -> void:
		label.text = "%s%d" % [prefix, int(round(current))]
	, float(previous), float(value), 0.18)


func _build_right_rail_output_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "RightRailOutputRow"
	row.custom_minimum_size = Vector2(0, 36)
	row.add_theme_constant_override("separation", 12)
	var icon := _right_rail_icon(item.get("icon", ["File", "TextFile"]), GodexTheme.TEXT)
	row.add_child(icon)
	var title := Label.new()
	title.name = "RightRailOutputTitle"
	title.text = str(item.get("title", ""))
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GodexTheme.paint_label(title, GodexTheme.TEXT, 17)
	row.add_child(title)
	return row


func _rebuild_subagents(items: Array, model: Dictionary) -> void:
	_clear(_subagent_list)
	var rows: Array = _subagent_rows(items, model)
	_set_right_rail_section_visible(_subagents_section, not rows.is_empty())
	var limit: int = min(rows.size(), 6)
	for index in range(limit):
		_subagent_list.add_child(_build_subagent_row(rows[index]))
	var hidden_count: int = rows.size() - limit
	if hidden_count > 0:
		_subagent_list.add_child(_build_right_rail_more_label("再显示 %d 个" % hidden_count))
	_update_right_rail_dividers()


func _subagent_rows(items: Array, model: Dictionary) -> Array:
	var rows: Array = []
	var tasks: Array = _state.call("active_subagent_tasks") if _state != null else []
	for task_value in tasks:
		if not (task_value is Dictionary):
			continue
		var task: Dictionary = task_value
		var lifecycle_detail := _subagent_lifecycle_detail(task)
		rows.append({
			"title": str(task.get("name", "子智能体")),
			"detail": "%s · %s%s%s" % [
				str(task.get("role", "")),
				str(task.get("branch", "")),
				"\n%s" % str(task.get("summary", "")) if not str(task.get("summary", "")).strip_edges().is_empty() else "",
				"\n%s" % lifecycle_detail if not lifecycle_detail.is_empty() else "",
			],
			"status": str(task.get("status", "queued")),
			"icon": ["Groups", "Node"],
		})
	if not rows.is_empty():
		return rows
	var events: Array = _state.call("active_model_events") if _state != null else []
	for event in events:
		if not (event is Dictionary):
			continue
		var data: Dictionary = event.get("data", {})
		var event_kind := str(event.get("kind", ""))
		if event_kind == "subagent":
			rows.append({
				"title": str(data.get("name", "子智能体")),
				"detail": str(data.get("role", "")),
				"status": str(data.get("status", "queued")),
				"icon": ["Groups", "Node"],
			})
	return rows


func _build_subagent_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "RightRailSubagentRow"
	row.custom_minimum_size = Vector2(0, 38)
	row.add_theme_constant_override("separation", 12)
	var color := _subagent_status_color(str(item.get("status", "idle")))
	row.add_child(_right_rail_icon(item.get("icon", ["Groups", "Node"]), color))
	var title := Label.new()
	title.name = "RightRailSubagentName"
	title.text = str(item.get("title", ""))
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GodexTheme.paint_label(title, GodexTheme.TEXT, 17)
	row.add_child(title)
	var status := str(item.get("status", ""))
	if not status.is_empty() and status != "idle":
		var status_label := Label.new()
		status_label.name = "RightRailSubagentStatus"
		status_label.text = _subagent_status_text(status)
		GodexTheme.paint_label(status_label, GodexTheme.MUTED, 14)
		row.add_child(status_label)
	row.tooltip_text = str(item.get("detail", ""))
	return row


func _rebuild_sources(model: Dictionary) -> void:
	_clear(_source_list)
	var rows: Array = _source_rows(model)
	if rows.is_empty():
		_source_list.add_child(_build_right_rail_empty_label("暂无来源"))
	else:
		for index in range(min(rows.size(), 5)):
			_source_list.add_child(_build_source_chip(rows[index]))
		if rows.size() > 5:
			_source_list.add_child(_build_right_rail_more_label("+%d" % (rows.size() - 5)))
	_set_right_rail_section_visible(_sources_section, true)
	_update_right_rail_dividers()


func _source_rows(model: Dictionary) -> Array:
	var rows: Array = []
	var seen: Dictionary = {}
	var events: Array = _state.call("active_model_events") if _state != null else []
	for event in events:
		if not (event is Dictionary):
			continue
		var data: Dictionary = event.get("data", {})
		match str(event.get("kind", "")):
			"mcp_context":
				var endpoint := str(data.get("endpoint", ""))
				_append_unique_source(rows, seen, "godot-dotnet-mcp", endpoint, ["Node", "Tools"], GodexTheme.TEXT)
			"mcp_tool_dispatch", "mcp_tool_transport", "mcp_tool_result":
				var tool_name := str(data.get("name", data.get("tool", "Godot .NET MCP")))
				_append_unique_source(rows, seen, "godot-dotnet-mcp", tool_name, ["Node", "Tools"], GodexTheme.TEXT)
			"web_search":
				_append_unique_source(rows, seen, "网页搜索", str(data.get("query", "")), ["World", "Network"], GodexTheme.TEXT)
	return rows


func _openai_source_detail(data: Dictionary) -> String:
	var parts: Array[String] = []
	var model := str(data.get("model", "")).strip_edges()
	var endpoint := str(data.get("endpoint", "")).strip_edges()
	var api_mode := str(data.get("api_mode", "")).strip_edges()
	if not model.is_empty():
		parts.append(model)
	if not api_mode.is_empty():
		parts.append(api_mode)
	if not endpoint.is_empty():
		parts.append(endpoint)
	return " · ".join(parts)


func _append_unique_source(rows: Array, seen: Dictionary, title: String, detail: String, icon: Array, color: Color) -> void:
	var key := title.strip_edges().to_lower()
	if key.is_empty() or seen.has(key):
		return
	seen[key] = true
	rows.append({"title": title, "detail": detail, "icon": icon, "color": color})


func _build_source_chip(item: Dictionary) -> Control:
	var icon := _right_rail_icon(item.get("icon", ["Node"]), item.get("color", GodexTheme.TEXT))
	icon.name = "RightRailSourceChip"
	icon.custom_minimum_size = Vector2(22, 22)
	icon.tooltip_text = "%s\n%s" % [str(item.get("title", "")), str(item.get("detail", ""))]
	return icon


func _right_rail_icon(icon_candidates, color: Color) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _editor_icon_texture(icon_candidates)
	icon.modulate = color
	return icon


func _build_right_rail_more_label(text: String) -> Label:
	var label := Label.new()
	label.name = "RightRailMore"
	label.text = text
	GodexTheme.paint_label(label, GodexTheme.MUTED, 15)
	return label


func _build_right_rail_empty_label(text: String) -> Label:
	var label := Label.new()
	label.name = "RightRailEmpty"
	label.text = text
	label.custom_minimum_size = Vector2(120, 0)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	GodexTheme.paint_label(label, GodexTheme.MUTED, 16)
	return label


func _set_right_rail_section_visible(section: Control, visible: bool) -> void:
	if section != null:
		section.visible = visible


func _update_right_rail_dividers() -> void:
	var progress_visible := _progress_section != null and _progress_section.visible
	var output_visible := _output_section != null and _output_section.visible
	var subagents_visible := _subagents_section != null and _subagents_section.visible
	var sources_visible := _sources_section != null and _sources_section.visible
	_set_node_visible("ProgressOverlayLayer/RightRail/RightRailBox/ProgressOutputDivider", progress_visible and (output_visible or subagents_visible or sources_visible))
	_set_node_visible("ProgressOverlayLayer/RightRail/RightRailBox/OutputSubAgentsDivider", output_visible and (subagents_visible or sources_visible))
	_set_node_visible("ProgressOverlayLayer/RightRail/RightRailBox/SubAgentsSourcesDivider", subagents_visible and sources_visible)


func _set_node_visible(path: String, visible: bool) -> void:
	if _root == null:
		return
	var node := _root.get_node_or_null(path) as Control
	if node != null:
		node.visible = visible


func _subagent_status_color(status: String) -> Color:
	match status:
		"running":
			return GodexTheme.BLUE
		"done", "completed":
			return GodexTheme.GREEN
		"failed":
			return Color(1.0, 0.42, 0.42)
		"cancelled", "canceled", "interrupted":
			return GodexTheme.MUTED
		_:
			return GodexTheme.WARNING


func _subagent_status_text(status: String) -> String:
	match status:
		"running":
			return "运行中"
		"done", "completed":
			return "完成"
		"failed":
			return "失败"
		"cancelled", "canceled":
			return "已取消"
		"interrupted":
			return "已中断"
		"queued":
			return "排队"
		_:
			return ""


func _subagent_lifecycle_detail(task: Dictionary) -> String:
	var parts: Array[String] = []
	var status := str(task.get("status", "")).strip_edges().to_lower()
	if status in ["queued", "running"]:
		parts.append("可取消")
	var cancelled_by := str(task.get("cancelled_by", "")).strip_edges()
	if not cancelled_by.is_empty():
		parts.append("取消来源: %s" % cancelled_by)
	var handoff_status := str(task.get("handoff_status", "")).strip_edges()
	if handoff_status == "handed_off":
		var handoff_summary := _preview_text(str(task.get("handoff_summary", "")), 96)
		parts.append("结果已交接%s" % (" · %s" % handoff_summary if not handoff_summary.is_empty() else ""))
	elif status in ["done", "completed", "failed", "cancelled", "canceled", "interrupted"]:
		var result := str(task.get("result", task.get("summary", ""))).strip_edges()
		if not result.is_empty():
			parts.append("可交接")
	return " · ".join(parts)


func _join_non_empty(parts: Array, separator: String) -> String:
	var clean_parts: Array[String] = []
	for part in parts:
		var value := str(part).strip_edges()
		if not value.is_empty():
			clean_parts.append(value)
	return separator.join(clean_parts)


func _preview_text(text: String, limit: int = 120) -> String:
	var clean := text.strip_edges().replace("\n", " ")
	while clean.find("  ") >= 0:
		clean = clean.replace("  ", " ")
	if clean.length() > limit:
		return "%s..." % clean.left(limit).strip_edges()
	return clean


func _rebuild_search_results(model: Dictionary) -> void:
	_clear(_search_results)
	var rows: Array = _state.call("search_records", _search_input.text if _search_input != null else "")
	rows.append_array([
		{"title": "项目", "detail": "活动项目：%s" % str(model.get("active_project", "Godot Project"))},
		{"title": "MCP", "detail": str(model.get("endpoint", ""))},
		{"title": "模型", "detail": "%s · %s" % [str(model.get("provider", "")), str(model.get("model", ""))]},
	])
	for row_data in rows:
		if str(row_data.get("id", "")).is_empty():
			_search_results.add_child(_build_summary_row(row_data))
		else:
			_search_results.add_child(_build_search_result_row(row_data))


func _build_search_result_row(item: Dictionary) -> Button:
	var button := Button.new()
	button.name = "SearchResult_%s" % str(item.get("id", ""))
	button.flat = true
	button.custom_minimum_size = Vector2(0, 46)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = "打开此会话。"
	GodexTheme.paint_button(button)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10
	box.offset_top = 6
	box.offset_right = -10
	box.offset_bottom = -6
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = str(item.get("title", ""))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(title, GodexTheme.TEXT, 14)
	var detail := Label.new()
	detail.text = str(item.get("detail", item.get("subtitle", "")))
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(detail, GodexTheme.MUTED, 12)
	box.add_child(title)
	box.add_child(detail)
	button.add_child(box)
	button.pressed.connect(_open_search_result_thread.bind(str(item.get("id", ""))))
	return button


func _open_search_result_thread(thread_id: String) -> void:
	if thread_id.is_empty():
		return
	var selected: Dictionary = _state.call("select_thread", thread_id)
	if selected.is_empty():
		return
	_save_sessions()
	if _root != null and _main_title != null:
		_show_view("chat")
		_apply_model(_state.call("to_model"))
	else:
		_active_view = "chat"
		_active_sidebar_surface = "thread"
		if _thread_list != null:
			_rebuild_threads(_state.call("to_model").get("threads", []))


func _rebuild_archived_view() -> void:
	if _archived_results == null:
		return
	_clear(_archived_results)
	var query := _archived_search_input.text if _archived_search_input != null else ""
	var records: Array = _state.call("archived_records", query)
	if records.is_empty():
		var empty_title := "暂无匹配的归档对话" if not query.strip_edges().is_empty() else "暂无已归档对话"
		var empty_detail := "换一个关键词，或清空搜索条件。" if not query.strip_edges().is_empty() else "归档后的会话会显示在这里。"
		_archived_results.add_child(_build_summary_row({
			"title": empty_title,
			"detail": empty_detail,
		}))
		return
	for item in records:
		_archived_results.add_child(_build_archived_result_row(item))


func _build_archived_result_row(item: Dictionary) -> Button:
	var button := Button.new()
	button.name = "ArchivedResult_%s" % str(item.get("id", ""))
	button.flat = true
	button.custom_minimum_size = Vector2(0, 62)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = ""
	GodexTheme.paint_button(button)
	button.add_theme_stylebox_override("normal", GodexTheme.button_style(Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("hover", GodexTheme.button_style(Color(0.16, 0.16, 0.16)))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 16
	row.offset_top = 8
	row.offset_right = -16
	row.offset_bottom = -8
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.text = str(item.get("title", ""))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(title, GodexTheme.TEXT, 14)
	var detail := Label.new()
	detail.text = str(item.get("detail", item.get("subtitle", "")))
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(detail, GodexTheme.MUTED, 12)
	box.add_child(title)
	box.add_child(detail)
	var delete := _build_thread_inline_action_button("ArchivedDelete_%s" % str(item.get("id", "")), "", ["Remove", "Trash", "GuiCloseCustomizable"])
	delete.custom_minimum_size = Vector2(30, 30)
	delete.pressed.connect(_delete_archived_thread.bind(str(item.get("id", ""))))
	var restore := Button.new()
	restore.name = "ArchivedRestore_%s" % str(item.get("id", ""))
	restore.text = "取消归档"
	restore.custom_minimum_size = Vector2(92, 30)
	restore.tooltip_text = ""
	GodexTheme.paint_button(restore)
	restore.pressed.connect(_restore_archived_thread.bind(str(item.get("id", ""))))
	row.add_child(box)
	row.add_child(delete)
	row.add_child(restore)
	button.add_child(row)
	button.pressed.connect(_restore_archived_thread.bind(str(item.get("id", ""))))
	return button


func _restore_archived_thread(thread_id: String) -> void:
	if thread_id.is_empty():
		return
	var restored: Dictionary = _state.call("restore_archived_session", thread_id)
	if restored.is_empty():
		return
	_save_sessions()
	if _messages != null:
		_render_active_messages()
	if _root != null and _main_title != null:
		_show_view("chat")
		_apply_model(_state.call("to_model"))
	else:
		_active_view = "chat"
		_active_sidebar_surface = "thread"
		if _thread_list != null:
			_rebuild_threads(_state.call("to_model").get("threads", []))
		if _archived_results != null:
			_rebuild_archived_view()


func _delete_archived_thread(thread_id: String) -> void:
	if thread_id.is_empty():
		return
	var deleted: Dictionary = _state.call("delete_archived_session", thread_id)
	if deleted.is_empty():
		return
	_save_sessions()
	_rebuild_archived_view()
	_rebuild_threads(_state.call("to_model").get("threads", []))


func _rebuild_layout_menu() -> void:
	if _layout_menu_actions == null or _layout_menu_recommended == null:
		return
	_clear(_layout_menu_actions)
	_clear(_layout_menu_recommended)
	_layout_menu_actions.add_theme_constant_override("separation", 4)
	_layout_menu_recommended.add_theme_constant_override("separation", 2)
	var recommended_title := _root.find_child("LayoutMenuRecommendedTitle", true, false) as Control
	var divider := _root.find_child("LayoutMenuDivider", true, false) as Control
	var actions := [
		{"title": "文件", "detail": "浏览项目文件", "shortcut": "Ctrl+P", "icon": ["Folder", "File"], "action": Callable(self, "_layout_menu_open_files")},
		{"title": "侧边聊天", "detail": "打开并行对话入口", "shortcut": "", "icon": ["Add", "GuiTabMenuHl"], "action": Callable(self, "_layout_menu_open_side_chat")},
		{"title": "终端", "detail": "切换底部输出面板", "shortcut": "Ctrl+`", "icon": ["Terminal", "Console"], "action": Callable(self, "_layout_menu_open_terminal")},
	]
	for index in range(actions.size()):
		_layout_menu_actions.add_child(_build_layout_menu_action(index, actions[index]))
	var recommended := _layout_menu_recommended_rows()
	if recommended_title != null:
		recommended_title.visible = not recommended.is_empty()
	if divider != null:
		divider.visible = not recommended.is_empty()
	for index in range(recommended.size()):
		_layout_menu_recommended.add_child(_build_layout_menu_recommended(index, recommended[index]))


func _layout_menu_recommended_rows() -> Array:
	return []


func _build_layout_menu_action(index: int, item: Dictionary) -> Button:
	var button := Button.new()
	button.name = "LayoutMenuAction%s" % index
	button.custom_minimum_size = Vector2(0, LAYOUT_MENU_ACTION_HEIGHT)
	button.text = ""
	button.tooltip_text = "%s\n%s" % [str(item.get("title", "")), str(item.get("detail", ""))]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	GodexTheme.paint_button(button)
	var content := HBoxContainer.new()
	content.name = "LayoutMenuActionContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12
	content.offset_right = -12
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.name = "LayoutMenuActionIcon"
	icon.custom_minimum_size = Vector2(22, 0)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _editor_icon_texture(item.get("icon", ["File"]))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var title := Label.new()
	title.name = "LayoutMenuActionTitle"
	title.text = str(item.get("title", ""))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(title, GodexTheme.TEXT, 15)
	content.add_child(title)
	var shortcut := Label.new()
	shortcut.name = "LayoutMenuActionShortcut"
	shortcut.text = str(item.get("shortcut", ""))
	shortcut.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	shortcut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(shortcut, GodexTheme.MUTED, 13)
	content.add_child(shortcut)
	button.add_child(content)
	var action: Callable = item.get("action", Callable())
	if action.is_valid():
		button.pressed.connect(action)
	return button


func _build_layout_menu_recommended(index: int, item: Dictionary) -> Button:
	var button := Button.new()
	button.name = "LayoutMenuRecommended%s" % index
	button.custom_minimum_size = Vector2(0, LAYOUT_MENU_RECOMMENDED_HEIGHT)
	button.text = ""
	button.tooltip_text = "%s\n%s" % [str(item.get("title", "")), str(item.get("detail", ""))]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	GodexTheme.paint_button(button)
	var content := HBoxContainer.new()
	content.name = "LayoutMenuRecommendedContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 12
	content.offset_right = -12
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.name = "LayoutMenuRecommendedIcon"
	icon.custom_minimum_size = Vector2(20, 0)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _editor_icon_texture(item.get("icon", ["File"]))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var title := Label.new()
	title.name = "LayoutMenuRecommendedTitle"
	title.text = str(item.get("title", ""))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(title, GodexTheme.TEXT, 14)
	content.add_child(title)
	button.add_child(content)
	button.pressed.connect(_layout_menu_add_recommended_context.bind(str(item.get("title", ""))))
	return button


func _rebuild_mcp_view(model: Dictionary) -> void:
	_clear(_mcp_tool_list)
	_mcp_summary.text = "Endpoint: %s\n状态: %s\n传输: streamable-http\n工具发现: %s · %d 项" % [
		str(model.get("endpoint", "")),
		"已启用" if bool(model.get("mcp_enabled", true)) else "已禁用",
		str(model.get("mcp_discovery_status", "idle")),
		model.get("mcp_discovered_tools", []).size(),
	]
	var discovery_error := str(model.get("mcp_discovery_error", ""))
	if not discovery_error.is_empty():
		_mcp_tool_list.add_child(_build_summary_row({"title": "发现错误", "detail": discovery_error}))
	for item in model.get("tools", []):
		if str(item.get("id", "")).begins_with("mcp") or str(item.get("title", "")).find("MCP") >= 0:
			_mcp_tool_list.add_child(_build_summary_row(item))
	for summary in model.get("capability_summary", []):
		if str(summary.get("title", "")) == "MCP 上下文":
			_mcp_tool_list.add_child(_build_summary_row(summary))
	for row in _state.call("mcp_tool_summary_rows", 12):
		_mcp_tool_list.add_child(_build_summary_row(row))


func _rebuild_automation_view(model: Dictionary) -> void:
	_clear(_automation_list)
	_rebuild_continuation_preview(model.get("pending_openai_continuation", {}))
	var pending_approval = model.get("pending_approval", {})
	var pending_command: Dictionary = _state.call("pending_command_approval_summary")
	var rows := [
		{"title": "审批模式", "detail": str(model.get("approval_mode", ""))},
		{"title": "待审批", "detail": _approval_detail(pending_approval)},
		pending_command,
		_state.call("active_goal_summary_row"),
		_context_compaction_summary_row(model),
		{"title": "命令能力", "detail": "%s · %s" % [str(model.get("command_shell", "PowerShell")), "启用" if bool(model.get("command_enabled", false)) else "禁用"]},
		_state.call("agent_loop_summary"),
		_state.call("pending_openai_approval_summary"),
		_state.call("pending_openai_continuation_summary"),
		_state.call("retry_openai_request_summary"),
	]
	rows.append_array(_state.call("approval_summary_rows"))
	rows.append_array(_state.call("subagent_summary_rows", 6))
	rows.append_array(_state.call("subagent_notification_summary_rows", 4))
	rows.append_array(_state.call("subagent_edge_summary_rows", 4))
	rows.append_array(_state.call("composer_input_queue_summary_rows", 6))
	rows.append_array(_state.call("compaction_history_summary_rows", 3))
	rows.append_array(_state.call("command_run_summary_rows", 6))
	rows.append_array(_tool_call_summary_rows())
	rows.append_array(_state.call("model_event_summary_rows"))
	for row_data in rows:
		_automation_list.add_child(_build_summary_row(row_data))
	var has_pending: bool = pending_approval is Dictionary and not pending_approval.is_empty()
	_approve_latest.disabled = not has_pending
	_reject_latest.disabled = not has_pending
	var pending_command_id := str(pending_command.get("command_id", ""))
	if not pending_command_id.is_empty():
		_approve_latest.tooltip_text = "批准命令审批：%s。" % pending_command_id
		_reject_latest.tooltip_text = "拒绝命令审批：%s。" % pending_command_id
	else:
		_approve_latest.tooltip_text = "批准最新待处理审批。"
		_reject_latest.tooltip_text = "拒绝最新待处理审批。"
	var queued_command: Dictionary = _state.call("next_queued_command_run")
	var approved_command: Dictionary = _state.call("next_approved_command_run")
	var cancellable_command: Dictionary = _state.call("next_cancellable_command_run")
	var cancellable_subagent: Dictionary = _state.call("next_cancellable_subagent_task")
	var handoffable_subagent: Dictionary = _state.call("next_handoffable_subagent_task")
	var queued_id := str(queued_command.get("id", ""))
	var approved_id := str(approved_command.get("id", ""))
	var cancellable_id := str(cancellable_command.get("id", ""))
	var cancellable_subagent_id := str(cancellable_subagent.get("id", ""))
	var handoffable_subagent_id := str(handoffable_subagent.get("id", ""))
	_request_command_approval.disabled = queued_command.is_empty()
	_execute_approved_command.disabled = approved_command.is_empty()
	_cancel_command_run.disabled = cancellable_command.is_empty()
	_request_command_approval.tooltip_text = "为下一个命令请求创建审批点，不执行命令。" if queued_id.is_empty() else "为命令创建审批点：%s。" % queued_id
	_execute_approved_command.tooltip_text = "当前没有已批准命令。" if approved_id.is_empty() else "执行已批准短命令：%s。长时间运行的命令仍应等待后续终端进程管理。" % approved_id
	_cancel_command_run.tooltip_text = "当前没有可取消命令。" if cancellable_id.is_empty() else "取消命令：%s。" % cancellable_id
	if _cancel_subagent_task != null:
		_cancel_subagent_task.disabled = cancellable_subagent.is_empty()
		_cancel_subagent_task.tooltip_text = "当前没有可取消子智能体任务。" if cancellable_subagent_id.is_empty() else "取消子智能体任务：%s。" % cancellable_subagent_id
	if _handoff_subagent_result != null:
		_handoff_subagent_result.disabled = handoffable_subagent.is_empty()
		_handoff_subagent_result.tooltip_text = "当前没有可交接子智能体结果。" if handoffable_subagent_id.is_empty() else "交接子智能体结果：%s。" % handoffable_subagent_id


func _context_compaction_summary_row(model: Dictionary) -> Dictionary:
	var detail := "%d / %d tokens" % [int(model.get("context_used", 0)), int(model.get("context_budget", 0))]
	var warning = model.get("context_window_warning", {})
	if warning is Dictionary and not warning.is_empty():
		detail = "%s · %s" % [detail, str(warning.get("message", ""))]
	var last = model.get("last_compaction", {})
	if last is Dictionary and not last.is_empty():
		var source := str(last.get("source", "manual"))
		if source == "slash_command":
			source = "手动"
		elif source == "composer_add_context":
			source = "菜单"
		elif source == "auto_prepare_turn":
			source = "自动"
		detail = "%s\n上次%s压缩：移除 %d 条，保留 %d 条 · %d -> %d tokens" % [
			detail,
			source,
			int(last.get("removed_count", 0)),
			int(last.get("kept_count", 0)),
			int(last.get("context_used_before", 0)),
			int(last.get("context_used_after", 0)),
		]
	var risk := "medium" if warning is Dictionary and str(warning.get("status", "")) == "auto_ready" else "low"
	return {"title": "上下文压缩", "detail": detail, "enabled": bool(model.get("compression_enabled", true)), "risk": risk}


func _rebuild_continuation_preview(pending) -> void:
	var title := "续跑预览"
	var detail := "暂无待发送工具结果续跑。"
	var title_color := GodexTheme.TEXT
	var send_enabled := false
	var send_label := "无续跑请求"
	var send_tooltip := "当前没有可发送的 OpenAI 工具结果续跑请求。"
	var replay_enabled := false
	var replay_tooltip := "当前没有可本地回放的工具结果续跑。"
	if pending is Dictionary and not pending.is_empty():
		var status := str(pending.get("status", ""))
		var risk := "外部网络请求" if status == "ready" else "暂不可发送"
		title = "续跑预览 · %s" % status
		detail = "工具调用: %s\nEndpoint: %s\n模型: %s · %s\n认证: %s\n风险: %s" % [
			str(pending.get("tool_call_id", "")),
			str(pending.get("endpoint", "")),
			str(pending.get("model", "")),
			str(pending.get("api_mode", "")),
			str(pending.get("key_source", "missing")),
			risk,
		]
		var error := str(pending.get("error", ""))
		if not error.is_empty():
			detail += "\n阻塞: %s" % error
		title_color = GodexTheme.GREEN if status == "ready" else GodexTheme.MUTED
		send_enabled = status == "ready"
		send_label = "发送续跑请求" if send_enabled else "续跑不可发送"
		send_tooltip = "发送已准备好的 OpenAI 工具结果续跑请求。" if send_enabled else "续跑请求尚未就绪：%s" % (error if not error.is_empty() else status)
		replay_enabled = status == "ready"
		replay_tooltip = "本地回放工具结果续跑闭环，不发送外部 OpenAI 请求。" if replay_enabled else "续跑请求尚未就绪，不能回放最终响应。"
	_continuation_preview_title.text = title
	_continuation_preview_detail.text = detail
	_send_continuation.disabled = not send_enabled
	_send_continuation.text = send_label
	_send_continuation.tooltip_text = send_tooltip
	_replay_continuation_button.disabled = not replay_enabled
	_replay_continuation_button.tooltip_text = replay_tooltip
	GodexTheme.paint_label(_continuation_preview_title, title_color, 14)
	GodexTheme.paint_label(_continuation_preview_detail, GodexTheme.MUTED, 12)


func _tool_call_summary_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var tool_events: Array = []
	for event in _state.call("active_model_events"):
		if str(event.get("kind", "")) == "tool_call":
			tool_events.append(event)
	if tool_events.is_empty():
		rows.append({"title": "工具调用", "detail": "暂无待处理工具调用。"})
		return rows
	for event in tool_events.slice(max(tool_events.size() - 4, 0), tool_events.size()):
		var data: Dictionary = event.get("data", {})
		var result: Dictionary = data.get("result", {})
		var suffix := str(result.get("message", result.get("error", "")))
		rows.append({
			"title": "工具调用 · %s" % str(data.get("status", "")),
			"detail": "%s · %s%s" % [str(data.get("name", "")), str(data.get("id", "")), " · %s" % suffix if not suffix.is_empty() else ""],
		})
	return rows


func _build_summary_row(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GodexTheme.panel_style(GodexTheme.PANEL_SOFT, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = str(item.get("title", ""))
	GodexTheme.paint_label(title, GodexTheme.TEXT, 14)
	var detail := Label.new()
	detail.text = str(item.get("detail", item.get("subtitle", "")))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(detail, GodexTheme.MUTED, 12)
	box.add_child(title)
	box.add_child(detail)
	panel.add_child(box)
	return panel


func _on_composer_text_changed() -> void:
	_rebuild_slash_command_suggestions(_composer.text)


func _on_composer_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE:
		if _state != null and (bool(_state.get("is_running")) or str(_state.get("agent_loop_status")) == "running" or _is_openai_busy()):
			_cancel_openai_request()
		else:
			_hide_slash_command_panel()
		_composer.accept_event()
		return
	if key_event.keycode in [KEY_ENTER, KEY_KP_ENTER] and not _slash_command_panel.visible:
		if key_event.ctrl_pressed or key_event.meta_pressed:
			_guide_or_send_composer_prompt()
		else:
			_submit_composer_from_keyboard()
		_composer.accept_event()
		return
	if not _slash_command_panel.visible:
		return
	match key_event.keycode:
		KEY_DOWN:
			_move_slash_command_selection(1)
			_composer.accept_event()
		KEY_UP:
			_move_slash_command_selection(-1)
			_composer.accept_event()
		KEY_ENTER, KEY_KP_ENTER:
			_insert_selected_slash_command()
			_composer.accept_event()
		KEY_ESCAPE:
			_hide_slash_command_panel()
			_composer.accept_event()


func _submit_composer_from_keyboard() -> void:
	if _state == null or _composer == null:
		return
	if bool(_state.get("is_running")) or str(_state.get("agent_loop_status")) == "running" or _is_openai_busy():
		_queue_composer_prompt("composer_enter_queue")
	else:
		_send_prompt()


func _guide_or_send_composer_prompt() -> void:
	if _state == null or _composer == null:
		return
	var prompt := _composer_prompt_for_queue(_composer.text.strip_edges())
	if prompt.is_empty():
		return
	if bool(_state.get("is_running")) or str(_state.get("agent_loop_status")) == "running" or _is_openai_busy():
		_state.call("record_pending_guide_instruction", prompt, "composer_ctrl_enter")
		_composer.text = ""
		_clear_composer_references()
		_save_sessions()
		_apply_model(_state.call("to_model"))
		return
	_send_prompt_text(prompt, "user_prompt")


func _rebuild_slash_command_suggestions(text: String) -> void:
	var trimmed := text.strip_edges()
	if not trimmed.begins_with("/"):
		_hide_slash_command_panel()
		return
	var query := trimmed.substr(1)
	var query_changed := query != _slash_command_query
	_slash_command_query = query
	_slash_command_suggestions = _state.call("slash_command_suggestions", query, 10)
	_clear(_slash_command_list)
	_slash_command_title.text = "命令 · %s" % ("/%s" % query if not query.is_empty() else "/")
	if _slash_command_suggestions.is_empty():
		_slash_command_selected_index = -1
		_slash_command_list.add_child(_build_summary_row({"title": "没有匹配命令", "detail": "输入 /help 查看全部本地命令。"}))
		_show_slash_command_panel()
		return
	if query_changed or _slash_command_selected_index < 0:
		_slash_command_selected_index = 0
	_slash_command_selected_index = clampi(_slash_command_selected_index, 0, _slash_command_suggestions.size() - 1)
	for index in range(_slash_command_suggestions.size()):
		_slash_command_list.add_child(_build_slash_command_row(_slash_command_suggestions[index], index == _slash_command_selected_index))
	_show_slash_command_panel()


func _build_slash_command_row(item: Dictionary, selected: bool = false) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 48)
	var args := str(item.get("args", ""))
	var command_text := "%s%s%s" % [str(item.get("command", "")), " " if not args.is_empty() else "", args]
	var title_text := str(item.get("title", command_text))
	var detail_text := str(item.get("detail", item.get("summary", "")))
	button.tooltip_text = "%s\n%s\n插入 %s" % [title_text, detail_text, command_text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	_paint_slash_command_button(button, selected)
	var content := HBoxContainer.new()
	content.name = "SlashCommandRowContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 14
	content.offset_right = -14
	content.offset_top = 0
	content.offset_bottom = 0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 10)
	var icon := TextureRect.new()
	icon.name = "SlashCommandIcon"
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _editor_icon_texture(item.get("icon", ["Tools"]))
	content.add_child(icon)
	var copy := HBoxContainer.new()
	copy.name = "SlashCommandCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 12)
	var title := Label.new()
	title.name = "SlashCommandName"
	title.text = title_text
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.custom_minimum_size = Vector2(110, 0)
	GodexTheme.paint_label(title, GodexTheme.TEXT, 15)
	var detail := Label.new()
	detail.name = "SlashCommandSummary"
	detail.text = detail_text
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(detail, GodexTheme.MUTED, 15)
	copy.add_child(title)
	copy.add_child(detail)
	content.add_child(copy)
	button.add_child(content)
	button.pressed.connect(_insert_slash_command.bind(str(item.get("insert_text", item.get("command", "")))))
	return button


func _paint_slash_command_button(button: Button, selected: bool) -> void:
	button.flat = true
	button.add_theme_stylebox_override("normal", GodexTheme.button_style(Color(0.22, 0.22, 0.22) if selected else Color(0, 0, 0, 0)))
	button.add_theme_stylebox_override("hover", GodexTheme.button_style(Color(0.24, 0.24, 0.24)))
	button.add_theme_stylebox_override("pressed", GodexTheme.button_style(Color(0.26, 0.26, 0.26)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", GodexTheme.TEXT)


func _hide_slash_command_panel() -> void:
	_slash_command_panel.visible = false
	_clear(_slash_command_list)
	_slash_command_suggestions = []
	_slash_command_selected_index = -1
	_slash_command_query = ""


func _show_slash_command_panel() -> void:
	_hide_composer_popovers_except(_slash_command_panel)
	_slash_command_panel.visible = true
	_position_slash_command_panel()
	call_deferred("_position_slash_command_panel")


func _move_slash_command_selection(delta: int) -> void:
	if _slash_command_suggestions.is_empty():
		return
	var count := _slash_command_suggestions.size()
	_slash_command_selected_index = (_slash_command_selected_index + delta + count) % count
	_refresh_slash_command_selection()


func _refresh_slash_command_selection() -> void:
	for index in range(_slash_command_list.get_child_count()):
		var child := _slash_command_list.get_child(index)
		if child is Button:
			_paint_slash_command_button(child, index == _slash_command_selected_index)
	if _slash_command_selected_index >= 0 and _slash_command_selected_index < _slash_command_list.get_child_count():
		var selected_child := _slash_command_list.get_child(_slash_command_selected_index)
		if _slash_command_scroll != null and selected_child is Control:
			_slash_command_scroll.ensure_control_visible(selected_child)


func _insert_selected_slash_command() -> bool:
	if _slash_command_selected_index < 0 or _slash_command_selected_index >= _slash_command_suggestions.size():
		return false
	var item: Dictionary = _slash_command_suggestions[_slash_command_selected_index]
	_insert_slash_command(str(item.get("insert_text", item.get("command", ""))))
	return true


func _insert_slash_command(value: String) -> void:
	_composer.text = value
	if _composer.is_inside_tree():
		_composer.grab_focus()
	_composer.set_caret_line(0)
	_composer.set_caret_column(value.length())
	_hide_slash_command_panel()


func _position_visible_composer_popovers() -> void:
	if _slash_command_panel.visible:
		_position_slash_command_panel()
	if _add_context_panel.visible:
		_position_add_context_panel()
	if _approval_mode_panel.visible:
		_position_approval_mode_panel()
	if _model_picker_panel.visible:
		_position_model_picker_panel()
	if _reasoning_picker_panel.visible:
		_position_reasoning_picker_panel()
	if _selection_action_panel != null and _selection_action_panel.visible:
		_position_selection_action_panel()
	if _layout_menu_panel != null and _layout_menu_panel.visible:
		_position_visible_layout_menu()


func _position_slash_command_panel() -> void:
	if _root == null or _composer == null or _slash_command_panel == null:
		return
	if not is_instance_valid(_composer) or not is_instance_valid(_slash_command_panel):
		return
	if _composer_popover_layer == null:
		_configure_composer_popovers()
	var root_rect := _root.get_global_rect()
	var composer_rect := _composer.get_global_rect()
	var max_width = max(0.0, root_rect.size.x - (COMPOSER_POPOVER_MARGIN * 2.0))
	var width = min(max(composer_rect.size.x, 320.0), max_width)
	var max_height = max(0.0, root_rect.size.y - (COMPOSER_POPOVER_MARGIN * 2.0))
	var height = min(min(360.0, max(190.0, root_rect.size.y - 120.0)), max_height)
	_set_popover_rect(_slash_command_panel, Vector2(
		_clamp_popover_x(composer_rect.position.x, width),
		_popover_y_above(composer_rect, height)
	), Vector2(width, height))


func _position_approval_mode_panel() -> void:
	if _root == null or _approval_button == null or _approval_mode_panel == null:
		return
	if not is_instance_valid(_approval_button) or not is_instance_valid(_approval_mode_panel):
		return
	if _composer_popover_layer == null:
		_configure_composer_popovers()
	var root_rect := _root.get_global_rect()
	var button_rect := _approval_button.get_global_rect()
	var max_width = max(0.0, root_rect.size.x - (COMPOSER_POPOVER_MARGIN * 2.0))
	var width = min(APPROVAL_POPOVER_WIDTH, max_width)
	var max_height = max(0.0, root_rect.size.y - (COMPOSER_POPOVER_MARGIN * 2.0))
	var available_above = max(0.0, button_rect.position.y - root_rect.position.y - COMPOSER_POPOVER_MARGIN - 8.0)
	var height = min(min(_approval_mode_popover_height(), max_height), available_above)
	_approval_mode_panel.custom_minimum_size = Vector2(min(APPROVAL_POPOVER_MIN_WIDTH, width), 0)
	_set_popover_rect(_approval_mode_panel, Vector2(
		_clamp_popover_x(button_rect.position.x, width),
		_popover_y_above(button_rect, height)
	), Vector2(width, height))


func _position_add_context_panel() -> void:
	if _root == null or _add_context_button == null or _add_context_panel == null:
		return
	if not is_instance_valid(_add_context_button) or not is_instance_valid(_add_context_panel):
		return
	if _composer_popover_layer == null:
		_configure_composer_popovers()
	var root_rect := _root.get_global_rect()
	var button_rect := _add_context_button.get_global_rect()
	var max_width = max(0.0, root_rect.size.x - (COMPOSER_POPOVER_MARGIN * 2.0))
	var width = min(ADD_CONTEXT_POPOVER_WIDTH, max_width)
	var max_height = max(0.0, root_rect.size.y - (COMPOSER_POPOVER_MARGIN * 2.0))
	var available_above = max(0.0, button_rect.position.y - root_rect.position.y - COMPOSER_POPOVER_MARGIN - 8.0)
	var height = min(min(_add_context_popover_height(), max_height), available_above)
	_add_context_panel.custom_minimum_size = Vector2(min(ADD_CONTEXT_POPOVER_MIN_WIDTH, width), 0)
	_set_popover_rect(_add_context_panel, Vector2(
		_clamp_popover_x(button_rect.position.x, width),
		_popover_y_above(button_rect, height)
	), Vector2(width, height))


func _position_model_picker_panel() -> void:
	if _reasoning_picker_panel != null and _reasoning_picker_panel.visible and is_instance_valid(_reasoning_picker_panel):
		_position_model_picker_as_submenu()
	else:
		_position_picker_panel(_model_picker_panel, _reasoning_button, MODEL_POPOVER_WIDTH, MODEL_POPOVER_MIN_WIDTH, _model_picker_popover_height())


func _position_reasoning_picker_panel() -> void:
	_position_picker_panel(_reasoning_picker_panel, _reasoning_button, REASONING_POPOVER_WIDTH, REASONING_POPOVER_MIN_WIDTH, _reasoning_picker_popover_height())


func _position_model_picker_as_submenu() -> void:
	if _root == null or _model_picker_panel == null or _reasoning_picker_panel == null:
		return
	if not is_instance_valid(_model_picker_panel) or not is_instance_valid(_reasoning_picker_panel):
		return
	if _composer_popover_layer == null:
		_configure_composer_popovers()
	var root_rect := _root.get_global_rect()
	var reasoning_rect := _reasoning_picker_panel.get_global_rect()
	var max_width = max(0.0, root_rect.size.x - (COMPOSER_POPOVER_MARGIN * 2.0))
	var width = min(MODEL_POPOVER_WIDTH, max_width)
	var max_height = max(0.0, root_rect.size.y - (COMPOSER_POPOVER_MARGIN * 2.0))
	var height = min(_model_picker_popover_height(), max_height)
	var preferred_x := reasoning_rect.position.x + reasoning_rect.size.x + PICKER_SUBMENU_GAP
	var root_right := root_rect.position.x + root_rect.size.x - COMPOSER_POPOVER_MARGIN
	if preferred_x + width > root_right:
		preferred_x = reasoning_rect.position.x - width - PICKER_SUBMENU_GAP
	var preferred_y: float = reasoning_rect.position.y + PICKER_SUBMENU_TOP_OFFSET
	var max_y: float = root_rect.position.y + root_rect.size.y - height - COMPOSER_POPOVER_MARGIN
	if preferred_y > max_y:
		preferred_y = max(root_rect.position.y + COMPOSER_POPOVER_MARGIN, max_y)
	_model_picker_panel.custom_minimum_size = Vector2(min(MODEL_POPOVER_MIN_WIDTH, width), 0)
	_set_popover_rect(_model_picker_panel, Vector2(
		_clamp_popover_x(preferred_x, width),
		preferred_y
	), Vector2(width, height))


func _position_picker_panel(panel, anchor, preferred_width: float, min_width: float, preferred_height: float) -> void:
	if _root == null or panel == null or anchor == null:
		return
	if not is_instance_valid(panel) or not is_instance_valid(anchor):
		return
	if not (panel is Control) or not (anchor is Control):
		return
	if _composer_popover_layer == null:
		_configure_composer_popovers()
	var panel_control := panel as Control
	var anchor_control := anchor as Control
	var root_rect := _root.get_global_rect()
	var anchor_rect := anchor_control.get_global_rect()
	var max_width = max(0.0, root_rect.size.x - (COMPOSER_POPOVER_MARGIN * 2.0))
	var width = min(preferred_width, max_width)
	var max_height = max(0.0, root_rect.size.y - (COMPOSER_POPOVER_MARGIN * 2.0))
	var available_above = max(0.0, anchor_rect.position.y - root_rect.position.y - COMPOSER_POPOVER_MARGIN - 8.0)
	var height = min(min(preferred_height, max_height), available_above)
	panel_control.custom_minimum_size = Vector2(min(min_width, width), 0)
	_set_popover_rect(panel_control, Vector2(
		_clamp_popover_x(anchor_rect.position.x + anchor_rect.size.x - width, width),
		_popover_y_above(anchor_rect, height)
	), Vector2(width, height))


func _position_visible_layout_menu() -> void:
	if _root == null or _control_panel_toggle == null or _layout_menu_panel == null:
		return
	if not _layout_menu_panel.visible:
		return
	if not is_instance_valid(_control_panel_toggle) or not is_instance_valid(_layout_menu_panel):
		return
	var root_rect := _root.get_global_rect()
	var button_rect := _control_panel_toggle.get_global_rect()
	var max_width = max(LAYOUT_MENU_MIN_WIDTH, root_rect.size.x - (LAYOUT_MENU_MARGIN * 2.0))
	var width = min(LAYOUT_MENU_WIDTH, max_width)
	var height = min(360.0, max(240.0, root_rect.size.y - button_rect.position.y - LAYOUT_MENU_MARGIN - 8.0))
	var x = button_rect.position.x + button_rect.size.x - width
	x = clamp(x, root_rect.position.x + LAYOUT_MENU_MARGIN, root_rect.position.x + root_rect.size.x - width - LAYOUT_MENU_MARGIN)
	var y = button_rect.position.y + button_rect.size.y + 8.0
	var max_y = root_rect.position.y + root_rect.size.y - height - LAYOUT_MENU_MARGIN
	y = min(y, max_y)
	_layout_menu_panel.custom_minimum_size = Vector2(LAYOUT_MENU_MIN_WIDTH, 0)
	_set_popover_rect(_layout_menu_panel, Vector2(x, y), Vector2(width, height))


func _approval_mode_popover_height() -> float:
	var row_count := _approval_modes().size()
	return APPROVAL_POPOVER_VERTICAL_PADDING + APPROVAL_POPOVER_TITLE_HEIGHT + APPROVAL_POPOVER_TITLE_GAP + (APPROVAL_POPOVER_ROW_HEIGHT * row_count) + (APPROVAL_POPOVER_ROW_GAP * max(0, row_count - 1))


func _add_context_popover_height() -> float:
	var row_count := _add_context_menu_items().size()
	return ADD_CONTEXT_POPOVER_VERTICAL_PADDING + ADD_CONTEXT_POPOVER_TITLE_HEIGHT + ADD_CONTEXT_POPOVER_TITLE_GAP + (ADD_CONTEXT_POPOVER_ROW_HEIGHT * row_count) + (ADD_CONTEXT_POPOVER_ROW_GAP * max(0, row_count - 1))


func _model_picker_popover_height() -> float:
	var model := _state.call("to_model")
	var choices: Array = model.get("model_choices", [])
	var current_model := str(model.get("model", ""))
	var row_count := choices.size()
	if not choices.has(current_model) and not current_model.strip_edges().is_empty():
		row_count += 1
	row_count = max(1, row_count)
	return MODEL_POPOVER_VERTICAL_PADDING + MODEL_POPOVER_TITLE_HEIGHT + MODEL_POPOVER_TITLE_GAP + (MODEL_POPOVER_ROW_HEIGHT * row_count) + (MODEL_POPOVER_ROW_GAP * max(0, row_count - 1))


func _reasoning_picker_popover_height() -> float:
	var row_count := _reasoning_values().size() + 1
	var separator_height := 10.0
	return MODEL_POPOVER_VERTICAL_PADDING + MODEL_POPOVER_TITLE_HEIGHT + MODEL_POPOVER_TITLE_GAP + separator_height + (MODEL_POPOVER_ROW_HEIGHT * row_count) + (MODEL_POPOVER_ROW_GAP * max(0, row_count - 1))


func _clamp_popover_x(x: float, width: float) -> float:
	var root_rect := _root.get_global_rect()
	var min_x := root_rect.position.x + COMPOSER_POPOVER_MARGIN
	var max_x := root_rect.position.x + root_rect.size.x - width - COMPOSER_POPOVER_MARGIN
	if max_x < min_x:
		return min_x
	return clampf(x, min_x, max_x)


func _popover_y_above(anchor_rect: Rect2, height: float) -> float:
	var root_rect := _root.get_global_rect()
	var y := anchor_rect.position.y - height - 8.0
	var min_y := root_rect.position.y + COMPOSER_POPOVER_MARGIN
	var max_y := root_rect.position.y + root_rect.size.y - height - COMPOSER_POPOVER_MARGIN
	if max_y < min_y:
		return min_y
	return clampf(y, min_y, max_y)


func _set_popover_rect(panel: Control, global_top_left: Vector2, target_size: Vector2) -> void:
	var layer_rect := _composer_popover_layer.get_global_rect() if _composer_popover_layer != null else _root.get_global_rect()
	var local_top_left := global_top_left - layer_rect.position
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = local_top_left.x
	panel.offset_top = local_top_left.y
	panel.offset_right = local_top_left.x + target_size.x
	panel.offset_bottom = local_top_left.y + target_size.y
	panel.size = target_size


func _position_selection_action_panel() -> void:
	if _selection_action_panel == null or _selection_source_panel == null or not is_instance_valid(_selection_source_panel):
		_hide_selection_action_panel()
		return
	if _composer_popover_layer == null:
		_configure_composer_popovers()
	var source_rect := _selection_source_panel.get_global_rect()
	var layer_rect := _composer_popover_layer.get_global_rect() if _composer_popover_layer != null else _root.get_global_rect()
	var size := _selection_action_panel.get_combined_minimum_size()
	size.x = max(size.x, 372.0)
	size.y = max(size.y, 52.0)
	var pointer := Vector2(DisplayServer.mouse_get_position()) - Vector2(DisplayServer.window_get_position())
	if not layer_rect.grow(160.0).has_point(pointer):
		pointer = _selection_source_panel.get_global_mouse_position()
	var x := pointer.x - size.x * 0.5
	var y := pointer.y + 18.0
	var source_bottom := source_rect.position.y + source_rect.size.y
	if y + size.y > source_bottom + 88.0:
		y = source_bottom + 10.0
	if y + size.y > layer_rect.position.y + layer_rect.size.y - 8.0:
		y = pointer.y - size.y - 18.0
	x = clampf(x, layer_rect.position.x + 8.0, max(layer_rect.position.x + 8.0, layer_rect.position.x + layer_rect.size.x - size.x - 8.0))
	y = clampf(y, layer_rect.position.y + 8.0, max(layer_rect.position.y + 8.0, layer_rect.position.y + layer_rect.size.y - size.y - 8.0))
	_set_popover_rect(_selection_action_panel, Vector2(x, y), size)


func _send_prompt() -> void:
	var prompt := _composer.text.strip_edges()
	if prompt.is_empty() and _active_composer_references().is_empty():
		return
	_send_prompt_text(prompt, "user_prompt")


func _send_prompt_text(prompt: String, source: String = "user_prompt", queued_record_id: String = "") -> bool:
	var clean_prompt := prompt.strip_edges()
	var prompt_references: Array[Dictionary] = _active_composer_references() if queued_record_id.strip_edges().is_empty() else ([] as Array[Dictionary])
	if clean_prompt.is_empty() and prompt_references.is_empty():
		return false
	if clean_prompt.is_empty():
		clean_prompt = _composer_reference_prompt_summary(prompt_references)
	if source == "queued_user_message" and clean_prompt.begins_with("!"):
		return _submit_queued_shell_prompt(clean_prompt, queued_record_id)
	if clean_prompt.begins_with("/") and _handle_slash_command(clean_prompt):
		if not queued_record_id.strip_edges().is_empty():
			_state.call("mark_queued_user_message_submitted", queued_record_id, "queued_slash_command")
		_composer.text = ""
		_slash_command_panel.visible = false
		return true
	if _is_openai_busy():
		_add_persisted_message("assistant", "已有 OpenAI 请求正在执行。")
		_apply_model(_state.call("to_model"))
		return false
	_agent.call("set_messages", _state.call("active_messages"))
	_state.call("begin_agent_loop", source)
	if not queued_record_id.strip_edges().is_empty():
		_state.call("mark_queued_user_message_submitted", queued_record_id, str(_state.get("active_turn_id")))
	_state.call("append_message", "user", clean_prompt, {"references": prompt_references})
	_add_message("user", clean_prompt)
	var result: Dictionary = _agent.call("prepare_turn", clean_prompt, prompt_references)
	_composer.text = ""
	_clear_composer_references()
	var transport_request: Dictionary = result.get("transport_request", {})
	if not bool(transport_request.get("ready", false)):
		var preview := str(result.get("preview", ""))
		_state.call("stop_agent_loop", str(result.get("audit", {}).get("openai_request", {}).get("error", "openai_request_blocked")))
		_state.call("append_message", "assistant", preview)
		_add_message("assistant", preview)
		_save_sessions()
		_apply_model(_state.call("to_model"))
		return false
	if _requires_openai_send_approval():
		_queue_openai_approval_request(transport_request, source)
		_composer.text = ""
		_clear_composer_references()
		_save_sessions()
		_apply_model(_state.call("to_model"))
		return true
	if not _start_openai_transport(transport_request):
		var preview := "OpenAI 请求启动失败，已保留本轮审计。"
		_state.call("stop_agent_loop", "openai_start_failed")
		_state.call("append_message", "assistant", preview)
		_add_message("assistant", preview)
		_save_sessions()
		_apply_model(_state.call("to_model"))
		return false
	_apply_model(_state.call("to_model"))
	return true


func _submit_queued_shell_prompt(prompt: String, queued_record_id: String = "") -> bool:
	var command := prompt.trim_prefix("!").strip_edges()
	if not queued_record_id.strip_edges().is_empty():
		_state.call("mark_queued_user_message_submitted", queued_record_id, "queued_shell_prompt")
	if command.is_empty():
		_add_persisted_message("assistant", "命令提示为空。请在 `!` 后输入要通过命令审批运行的短命令。")
		_save_sessions()
		_apply_model(_state.call("to_model"))
		call_deferred("_maybe_send_next_queued_user_message")
		return true
	var command_run: Dictionary = _state.call("record_command_run", {
		"command": command,
		"shell": str(_state.command_shell),
		"working_directory": str(_state.command_working_directory),
		"timeout_sec": int(_state.command_timeout_sec),
		"requires_approval": true,
		"source": "queued_shell_prompt",
	})
	var approval: Dictionary = _state.call("request_command_run_approval", str(command_run.get("id", "")))
	var updated_command: Dictionary = command_run
	if str(approval.get("kind", "")) == "command_run":
		updated_command = approval
	elif not str(command_run.get("id", "")).is_empty():
		updated_command = _state.call("command_run_by_id", str(command_run.get("id", "")))
	var status := str(updated_command.get("status", command_run.get("status", "")))
	if status == "blocked":
		_add_persisted_message("assistant", "队列命令已阻止：%s。" % str(updated_command.get("result", {}).get("stderr", "blocked")))
	else:
		_add_persisted_message("assistant", "队列命令已进入审批：%s。" % command)
	_save_sessions()
	_refresh_command_action_model()
	return true


func _start_openai_transport(transport_request: Dictionary) -> bool:
	if _openai_stream_client == null:
		return false
	var endpoint := str(transport_request.get("endpoint", ""))
	if endpoint.is_empty():
		return false
	var direct_http := _openai_transport_prefers_http_request(transport_request)
	var payload: Dictionary = _openai_first_send_payload(transport_request, direct_http)
	var body := JSON.stringify(payload)
	var audit := _openai_transport_audit_context(transport_request, body)
	var stage := "non_stream_direct" if direct_http else "stream"
	_active_openai_api_mode = str(transport_request.get("api_mode", _state.api_mode))
	_active_openai_transport_request = transport_request.duplicate(true)
	_active_openai_transport_request["payload"] = payload
	_active_openai_transport_request["stage"] = stage
	_openai_cancel_requested = false
	_state.set("is_running", true)
	_state.call("clear_retry_openai_request")
	_refresh_openai_transport_buttons(true, false)
	var starting_event := {
		"status": "request_starting",
		"stage": stage,
		"endpoint": endpoint,
		"provider": str(_active_openai_transport_request.get("provider", _state.provider)),
		"api_mode": _active_openai_api_mode,
		"model": str(transport_request.get("model", "")),
		"body_length": body.length(),
		"stream": not direct_http,
	}
	starting_event.merge(audit, true)
	var starting_transport_event: Dictionary = _state.call("append_model_event", "openai_transport", starting_event)
	_active_openai_transport_request["sampling_batch_id"] = str(starting_transport_event.get("id", ""))
	var err := OK
	if direct_http:
		err = _start_openai_direct_http_request(endpoint, transport_request.get("headers", PackedStringArray()), body)
	else:
		err = _start_openai_stream(endpoint, transport_request.get("headers", PackedStringArray()), body)
	if err != OK:
		_state.set("is_running", false)
		_state.call("set_retry_openai_request", _active_openai_transport_request, "failed", "start_error_%d" % err)
		var failed_event := {
			"status": "request_failed",
			"stage": stage,
			"endpoint": endpoint,
			"provider": str(_active_openai_transport_request.get("provider", _state.provider)),
			"error": "HTTPRequest failed: %d" % err,
			"stream": not direct_http,
		}
		failed_event.merge(audit, true)
		_state.call("append_model_event", "openai_transport", failed_event)
		if _openai_stream_message_index >= 0:
			var failed_message := "OpenAI 请求启动失败：%d。" % err
			_state.call("update_message_content", _openai_stream_message_index, failed_message)
			_update_streaming_assistant_message(failed_message)
			_finish_streaming_status("已停止")
		return false
	var sent_event := {
		"status": "request_sent",
		"stage": stage,
		"endpoint": endpoint,
		"provider": str(_active_openai_transport_request.get("provider", _state.provider)),
		"api_mode": _active_openai_api_mode,
		"model": str(transport_request.get("model", "")),
		"body_length": body.length(),
		"stream": not direct_http,
	}
	sent_event.merge(audit, true)
	_state.call("append_model_event", "openai_transport", sent_event)
	_save_sessions()
	return true


func _openai_transport_prefers_http_request(transport_request: Dictionary) -> bool:
	var api_mode := str(transport_request.get("api_mode", _state.api_mode)).strip_edges()
	if api_mode != "chat_completions":
		return false
	var provider_id := str(transport_request.get("provider", "")).strip_edges()
	if provider_id.is_empty():
		var endpoint := str(transport_request.get("endpoint", "")).strip_edges()
		if endpoint.find("yurenapi.cn") >= 0 or endpoint.find("yurenapi.com") >= 0:
			provider_id = "yurenapi"
	if provider_id.is_empty():
		provider_id = str(_state.provider).strip_edges()
	return provider_id != "openai"


func _openai_first_send_payload(transport_request: Dictionary, direct_http: bool) -> Dictionary:
	var payload: Dictionary = transport_request.get("payload", {}).duplicate(true)
	if direct_http:
		payload.erase("stream")
	return payload


func _is_openai_busy() -> bool:
	if _openai_stream_timer != null and not _openai_stream_timer.is_stopped():
		return true
	return _openai_request != null and _openai_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED


func _openai_transport_audit_context(transport_request: Dictionary, body: String = "") -> Dictionary:
	var payload: Dictionary = transport_request.get("payload", {})
	var body_text := body
	if body_text.is_empty():
		body_text = JSON.stringify(payload)
	var input = payload.get("input", payload.get("messages", []))
	var input_count := 0
	if input is Array:
		input_count = input.size()
	return {
		"source": str(transport_request.get("source", "")),
		"tool_call_id": str(transport_request.get("tool_call_id", "")),
		"previous_response_id": str(transport_request.get("previous_response_id", "")),
		"payload_input_count": int(transport_request.get("payload_input_count", input_count)),
		"payload_fingerprint": str(transport_request.get("payload_fingerprint", str(body_text.hash()))),
	}


func _start_openai_stream(endpoint: String, headers: PackedStringArray, body: String) -> int:
	var parsed := _parse_http_url(endpoint)
	if parsed.is_empty():
		return ERR_INVALID_PARAMETER
	var connect_error := _openai_stream_client.connect_to_host(
		str(parsed.get("host", "")),
		int(parsed.get("port", 443)),
		TLSOptions.client() if bool(parsed.get("tls", false)) else null
	)
	if connect_error != OK:
		return connect_error
	_openai_stream_buffer = ""
	_openai_stream_text = ""
	_openai_stream_started = false
	_openai_stream_completed = false
	_openai_stream_started_at_msec = Time.get_ticks_msec()
	_openai_stream_last_activity_msec = _openai_stream_started_at_msec
	_openai_stream_poll_ticks = 0
	_openai_stream_event_count = 0
	_openai_stream_text_delta_total = 0
	_openai_stream_tool_delta_count = 0
	_openai_stream_tool_call_count = 0
	_openai_stream_last_event_type = ""
	_openai_stream_completed_event_seen = false
	_openai_stream_response_id = ""
	_openai_stream_http_error_code = 0
	_openai_stream_http_error_body = ""
	_openai_stream_tool_calls.clear()
	_openai_stream_recorded_tool_calls.clear()
	_state.call("clear_partial_tool_calls")
	_begin_streaming_assistant_message()
	_record_stream_step("OpenAI · %s" % str(_active_openai_transport_request.get("model", "")), "正在连接")
	_active_openai_transport_request["stream_path"] = str(parsed.get("path", "/"))
	_active_openai_transport_request["stream_headers"] = headers
	_active_openai_transport_request["stream_body"] = body
	_openai_stream_timer.start()
	return OK


func _start_openai_direct_http_request(endpoint: String, headers: PackedStringArray, body: String) -> int:
	if _openai_request == null:
		return ERR_UNCONFIGURED
	var payload := _parse_json_dictionary_quiet(body)
	if payload.has("stream"):
		return ERR_INVALID_PARAMETER
	_openai_stream_buffer = ""
	_openai_stream_text = ""
	_openai_stream_started = false
	_openai_stream_completed = false
	_openai_stream_started_at_msec = Time.get_ticks_msec()
	_openai_stream_last_activity_msec = _openai_stream_started_at_msec
	_openai_stream_poll_ticks = 0
	_openai_stream_event_count = 0
	_openai_stream_text_delta_total = 0
	_openai_stream_tool_delta_count = 0
	_openai_stream_tool_call_count = 0
	_openai_stream_last_event_type = ""
	_openai_stream_completed_event_seen = false
	_openai_stream_response_id = ""
	_openai_stream_http_error_code = 0
	_openai_stream_http_error_body = ""
	_openai_stream_tool_calls.clear()
	_openai_stream_recorded_tool_calls.clear()
	_state.call("clear_partial_tool_calls")
	_begin_streaming_assistant_message()
	_record_stream_step("OpenAI · %s" % str(_active_openai_transport_request.get("model", "")), "正在请求")
	return _openai_request.request(endpoint, headers, HTTPClient.METHOD_POST, body)


func _parse_http_url(url: String) -> Dictionary:
	var regex := RegEx.new()
	if regex.compile("^(https?)://([^/:]+)(?::([0-9]+))?(/.*)?$") != OK:
		return {}
	var result := regex.search(url.strip_edges())
	if result == null:
		return {}
	var scheme := result.get_string(1)
	var default_port := 443 if scheme == "https" else 80
	var port_text := result.get_string(3)
	return {
		"scheme": scheme,
		"host": result.get_string(2),
		"port": int(port_text) if not port_text.is_empty() else default_port,
		"path": result.get_string(4) if not result.get_string(4).is_empty() else "/",
		"tls": scheme == "https",
	}


func _poll_openai_stream() -> void:
	if _openai_stream_client == null:
		return
	_openai_stream_poll_ticks += 1
	_update_streaming_status()
	if _openai_stream_timed_out():
		if _try_finalize_openai_stream_from_buffer("stream_timeout"):
			return
		if _try_start_openai_plain_chat_fallback_from_error("stream_timeout"):
			return
		_finalize_openai_stream_error("stream_timeout")
		return
	var poll_error := _openai_stream_client.poll()
	if poll_error != OK:
		if _try_start_openai_plain_chat_fallback_from_error("stream_poll_%d" % poll_error):
			return
		_finalize_openai_stream_error("stream_poll_%d" % poll_error)
		return
	match _openai_stream_client.get_status():
		HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING:
			return
		HTTPClient.STATUS_CONNECTED:
			if _openai_stream_started:
				return
			var request_error := _openai_stream_client.request(
				HTTPClient.METHOD_POST,
				str(_active_openai_transport_request.get("stream_path", "/")),
				_active_openai_transport_request.get("stream_headers", PackedStringArray()),
				str(_active_openai_transport_request.get("stream_body", ""))
			)
			if request_error != OK:
				if _try_start_openai_plain_chat_fallback_from_error("stream_request_%d" % request_error):
					return
				_finalize_openai_stream_error("stream_request_%d" % request_error)
				return
			_openai_stream_started = true
			_openai_stream_last_activity_msec = Time.get_ticks_msec()
			_record_stream_step("OpenAI request", "已发送")
		HTTPClient.STATUS_REQUESTING:
			return
		HTTPClient.STATUS_BODY:
			var response_code := _openai_stream_client.get_response_code()
			if response_code < 200 or response_code >= 300:
				_read_openai_stream_http_error_body(response_code)
				return
			_read_openai_stream_chunks()
		HTTPClient.STATUS_DISCONNECTED:
			if not _openai_stream_completed:
				if _try_finalize_openai_stream_from_buffer("stream_disconnected"):
					return
				if _try_start_openai_plain_chat_fallback_from_error("stream_disconnected"):
					return
				_finalize_openai_stream_error("stream_disconnected")


func _openai_stream_timed_out() -> bool:
	return _openai_stream_timed_out_at(Time.get_ticks_msec())


func _openai_stream_timed_out_at(now_msec: int) -> bool:
	if _openai_stream_started_at_msec <= 0:
		return false
	var total_elapsed := now_msec - _openai_stream_started_at_msec
	if total_elapsed > OPENAI_STREAM_TOTAL_TIMEOUT_SEC * 1000:
		return true
	var last_activity := _openai_stream_last_activity_msec
	if last_activity <= 0:
		last_activity = _openai_stream_started_at_msec
	return now_msec - last_activity > OPENAI_STREAM_IDLE_TIMEOUT_SEC * 1000


func _read_openai_stream_chunks() -> void:
	var chunk_count := 0
	while _openai_stream_client != null and _openai_stream_client.get_status() == HTTPClient.STATUS_BODY and chunk_count < 64:
		var chunk := _openai_stream_client.read_response_body_chunk()
		if chunk.is_empty():
			break
		chunk_count += 1
		_openai_stream_last_activity_msec = Time.get_ticks_msec()
		_openai_stream_buffer += chunk.get_string_from_utf8()
		_drain_openai_stream_events()
		if _openai_stream_completed:
			break
		if _try_finalize_openai_json_body_from_buffer("non_stream_body"):
			break
	if _openai_stream_client != null and _openai_stream_client.get_status() == HTTPClient.STATUS_DISCONNECTED and not _openai_stream_completed:
		if _try_finalize_openai_stream_from_buffer("stream_disconnected"):
			return
		if _try_start_openai_plain_chat_fallback_from_error("stream_disconnected"):
			return
		_finalize_openai_stream_error("stream_disconnected")


func _read_openai_stream_http_error_body(response_code: int) -> void:
	_openai_stream_http_error_code = response_code
	var chunk_count := 0
	while _openai_stream_client != null and _openai_stream_client.get_status() == HTTPClient.STATUS_BODY and chunk_count < 64:
		var chunk := _openai_stream_client.read_response_body_chunk()
		if chunk.is_empty():
			break
		chunk_count += 1
		_openai_stream_http_error_body += chunk.get_string_from_utf8()
		if _openai_stream_http_error_body.length() > OPENAI_ERROR_BODY_PREVIEW_LENGTH * 4:
			_openai_stream_http_error_body = _openai_stream_http_error_body.left(OPENAI_ERROR_BODY_PREVIEW_LENGTH * 4)
			break
	if _openai_stream_client != null and _openai_stream_client.get_status() == HTTPClient.STATUS_BODY:
		return
	var effective_api_mode: String = _active_openai_api_mode
	if effective_api_mode.is_empty():
		effective_api_mode = str(_state.api_mode)
	if _try_start_openai_plain_chat_fallback(effective_api_mode, response_code, _openai_stream_http_error_body, {"error": _openai_http_error_code(response_code, _openai_stream_http_error_body)}):
		return
	if _try_start_openai_non_stream_fallback(response_code, _openai_stream_http_error_body):
		return
	_finalize_openai_stream_error(_openai_http_error_code(response_code, _openai_stream_http_error_body))


func _try_start_openai_non_stream_fallback(response_code: int, response_body: String) -> bool:
	if not _openai_stream_error_allows_fallback(response_code, response_body):
		return false
	if bool(_active_openai_transport_request.get("stream_fallback_attempted", false)):
		return false
	if _openai_request == null:
		return false
	var fallback_request := _active_openai_transport_request.duplicate(true)
	var payload: Dictionary = fallback_request.get("payload", {}).duplicate(true)
	if not bool(payload.get("stream", false)):
		return false
	payload.erase("stream")
	fallback_request["payload"] = payload
	fallback_request["stream_fallback_attempted"] = true
	fallback_request["stream_fallback_from"] = _openai_http_error_code(response_code, response_body)
	fallback_request["stage"] = "stream_fallback"
	_active_openai_transport_request = fallback_request
	_active_openai_api_mode = str(fallback_request.get("api_mode", _state.api_mode))
	var body := JSON.stringify(payload)
	_state.call("append_model_event", "openai_transport", {
		"status": "stream_fallback",
		"stage": "stream_fallback",
		"endpoint": str(fallback_request.get("endpoint", "")),
		"api_mode": _active_openai_api_mode,
		"model": str(fallback_request.get("model", "")),
		"status_code": response_code,
		"error": _openai_http_error_code(response_code, response_body),
		"message": _openai_http_error_message(response_code, response_body),
		"body_preview": _openai_http_error_body_preview(response_body),
		"stream": false,
	})
	_record_stream_step("OpenAI 非流式回退", "正在重试")
	_stop_openai_stream_timer()
	var err := _openai_request.request(
		str(fallback_request.get("endpoint", "")),
		fallback_request.get("headers", PackedStringArray()),
		HTTPClient.METHOD_POST,
		body
	)
	if err != OK:
		_finalize_openai_stream_error("fallback_start_error_%d" % err)
		return true
	return true


func _try_start_openai_plain_chat_fallback(api_mode: String, response_code: int, response_body: String, parsed_result: Dictionary) -> bool:
	if not _openai_compatibility_fallback_allowed(api_mode, response_code, response_body, parsed_result):
		return false
	if bool(_active_openai_transport_request.get("compatibility_fallback_attempted", false)):
		return false
	if _openai_request == null:
		return false
	var fallback_request := _active_openai_transport_request.duplicate(true)
	var payload: Dictionary = _openai_plain_chat_fallback_payload(fallback_request.get("payload", {}))
	if payload.is_empty():
		return false
	fallback_request["payload"] = payload
	fallback_request["api_mode"] = "chat_completions"
	var fallback_endpoint := str(fallback_request.get("endpoint", "")).strip_edges()
	if fallback_endpoint.find("/chat/completions") < 0:
		fallback_endpoint = OpenAIRequestBuilder.endpoint_for(str(_state.base_url), "chat_completions")
	fallback_request["endpoint"] = fallback_endpoint
	fallback_request["compatibility_fallback_attempted"] = true
	fallback_request["compatibility_fallback_mode"] = "plain_chat"
	fallback_request["compatibility_fallback_from"] = _openai_http_error_code(response_code, response_body)
	fallback_request["stage"] = "compatibility_fallback"
	_active_openai_transport_request = fallback_request
	_active_openai_api_mode = "chat_completions"
	var body := JSON.stringify(payload)
	_state.set("is_running", true)
	_refresh_openai_transport_buttons(true, false)
	_state.call("append_model_event", "openai_transport", {
		"status": "compatibility_fallback",
		"stage": "compatibility_fallback",
		"endpoint": fallback_endpoint,
		"api_mode": "chat_completions",
		"model": str(fallback_request.get("model", "")),
		"status_code": response_code,
		"error": _openai_http_error_code(response_code, response_body),
		"message": _openai_http_error_message(response_code, response_body),
		"body_preview": _openai_http_error_body_preview(response_body),
		"stream": false,
		"compatibility_fallback_mode": "plain_chat",
	})
	_record_stream_step("OpenAI 兼容降级", "文本对话")
	if _openai_stream_status != null:
		_openai_stream_status.text = "正在思考"
	_stop_openai_stream_timer()
	call_deferred("_start_deferred_openai_http_request", fallback_endpoint, fallback_request.get("headers", PackedStringArray()), body, "compatibility_fallback")
	return true


func _try_start_openai_plain_chat_fallback_from_error(error_code: String) -> bool:
	return _try_start_openai_plain_chat_fallback(
		_active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode,
		0,
		"",
		{"error": error_code, "message": error_code}
	)


func _start_deferred_openai_http_request(endpoint: String, headers: PackedStringArray, body: String, source: String = "openai") -> void:
	if _openai_request == null:
		_finalize_openai_stream_error("%s_start_error_missing_request" % source)
		return
	var err := _openai_request.request(endpoint, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_finalize_openai_stream_error("%s_start_error_%d" % [source, err])


func _openai_plain_chat_fallback_payload(payload_value) -> Dictionary:
	if not (payload_value is Dictionary):
		return {}
	var payload: Dictionary = (payload_value as Dictionary).duplicate(true)
	if not payload.has("messages") or not (payload.get("messages", []) is Array):
		return {}
	var changed := false
	for key in ["stream", "tools", "tool_choice", "parallel_tool_calls", "reasoning_effort"]:
		if payload.has(key):
			payload.erase(key)
			changed = true
	var clean_messages := _openai_plain_chat_fallback_messages(payload.get("messages", []))
	if clean_messages.is_empty():
		return {}
	if clean_messages != payload.get("messages", []):
		payload["messages"] = clean_messages
		changed = true
	return payload if changed else {}


func _openai_plain_chat_fallback_messages(messages_value) -> Array:
	if not (messages_value is Array):
		return []
	var clean_messages: Array[Dictionary] = []
	for message_value in messages_value:
		if not (message_value is Dictionary):
			continue
		var message: Dictionary = message_value
		var role := str(message.get("role", "user")).strip_edges()
		var clean_role := role if role in ["system", "user", "assistant"] else "user"
		var content := _openai_plain_chat_content_text(message.get("content", ""))
		var extras: Array[String] = []
		if message.has("tool_calls") and message.get("tool_calls") is Array:
			for tool_call_value in message.get("tool_calls", []):
				var summary := _openai_plain_chat_tool_call_text(tool_call_value)
				if not summary.is_empty():
					extras.append(summary)
		if role == "tool":
			var tool_id := str(message.get("tool_call_id", "")).strip_edges()
			var prefix := "工具结果"
			if not tool_id.is_empty():
				prefix += "（%s）" % tool_id
			content = "%s：%s" % [prefix, content] if not content.is_empty() else prefix
		if not extras.is_empty():
			content = _join_non_empty([content, "\n".join(extras)], "\n")
		content = content.strip_edges()
		if content.is_empty():
			continue
		clean_messages.append({"role": clean_role, "content": content})
	return clean_messages


func _openai_plain_chat_content_text(value) -> String:
	if value == null:
		return ""
	if value is String:
		return str(value)
	if value is Array:
		var parts: Array[String] = []
		for item in value:
			var item_text := _openai_plain_chat_content_text(item)
			if not item_text.strip_edges().is_empty():
				parts.append(item_text.strip_edges())
		return "\n".join(parts)
	if value is Dictionary:
		for key in ["text", "content", "input_text", "output_text"]:
			if value.has(key):
				var nested := _openai_plain_chat_content_text(value.get(key))
				if not nested.strip_edges().is_empty():
					return nested
		return JSON.stringify(value)
	return str(value)


func _openai_plain_chat_tool_call_text(tool_call_value) -> String:
	if not (tool_call_value is Dictionary):
		return ""
	var tool_call: Dictionary = tool_call_value
	var function_data = tool_call.get("function", {})
	var name := str(tool_call.get("name", "")).strip_edges()
	var arguments = tool_call.get("arguments", {})
	if function_data is Dictionary:
		name = str(function_data.get("name", name)).strip_edges()
		arguments = function_data.get("arguments", arguments)
	if name.is_empty():
		name = str(tool_call.get("id", "tool_call")).strip_edges()
	var argument_text := _openai_plain_chat_content_text(arguments).strip_edges()
	return "工具调用请求：%s%s" % [name, " · %s" % argument_text if not argument_text.is_empty() else ""]


func _openai_compatibility_fallback_allowed(api_mode: String, response_code: int, response_body: String, parsed_result: Dictionary = {}) -> bool:
	if api_mode != "chat_completions":
		return false
	if response_code in [401, 403]:
		return false
	if response_code in [400, 404, 405, 422, 500, 502, 503, 504]:
		return true
	var haystack := "%s\n%s\n%s" % [
		response_body.to_lower(),
		str(parsed_result.get("error", "")).to_lower(),
		str(parsed_result.get("message", "")).to_lower(),
	]
	for needle in ["stream", "sse", "tool", "function", "reasoning", "unsupported", "compatible", "schema"]:
		if haystack.find(needle) >= 0:
			return true
	for retryable_error in ["stream_timeout", "stream_disconnected", "empty_chat_completion", "empty_response"]:
		if haystack.find(retryable_error) >= 0:
			return true
	if haystack.find("stream_poll_") >= 0 or haystack.find("stream_request_") >= 0:
		return true
	return false


func _openai_stream_error_allows_fallback(response_code: int, response_body: String) -> bool:
	if response_code in [400, 404, 405, 422, 500, 502, 503, 504]:
		return true
	var text := response_body.to_lower()
	return text.find("stream") >= 0 or text.find("sse") >= 0 or text.find("responses") >= 0 or text.find("compatible") >= 0


func _openai_http_error_code(response_code: int, response_body: String = "") -> String:
	var parsed := _parse_json_dictionary_quiet(response_body)
	if parsed is Dictionary and parsed.has("error"):
		var error = parsed.get("error", {})
		if error is Dictionary:
			var error_type := str(error.get("type", "")).strip_edges()
			var error_code := str(error.get("code", "")).strip_edges()
			if not error_type.is_empty():
				return "http_%d:%s" % [response_code, error_type]
			if not error_code.is_empty():
				return "http_%d:%s" % [response_code, error_code]
	return "http_%d" % response_code


func _openai_http_error_message(response_code: int, response_body: String = "") -> String:
	var parsed := _parse_json_dictionary_quiet(response_body)
	if parsed is Dictionary and parsed.has("error"):
		var error = parsed.get("error", {})
		if error is Dictionary:
			var message := str(error.get("message", "")).strip_edges()
			if not message.is_empty():
				return message.left(OPENAI_ERROR_BODY_PREVIEW_LENGTH)
	var preview := _openai_http_error_body_preview(response_body)
	if not preview.is_empty():
		return preview
	return "HTTP %d" % response_code


func _parse_json_dictionary_quiet(text: String) -> Dictionary:
	var clean := text.strip_edges()
	if clean.is_empty() or not (clean.begins_with("{") and clean.ends_with("}")):
		return {}
	var parsed = JSON.parse_string(clean)
	return parsed if parsed is Dictionary else {}


func _openai_http_error_body_preview(response_body: String) -> String:
	var preview := response_body.strip_edges().replace("\r", " ").replace("\n", " ")
	while preview.find("  ") >= 0:
		preview = preview.replace("  ", " ")
	return preview.left(OPENAI_ERROR_BODY_PREVIEW_LENGTH)


func _drain_openai_stream_events() -> void:
	while true:
		var separator := _openai_stream_buffer.find("\n\n")
		var separator_length := 2
		if separator < 0:
			separator = _openai_stream_buffer.find("\r\n\r\n")
			separator_length = 4
		if separator < 0:
			return
		var event_text := _openai_stream_buffer.substr(0, separator)
		_openai_stream_buffer = _openai_stream_buffer.substr(separator + separator_length)
		for line in event_text.split("\n"):
			var stripped := str(line).strip_edges()
			if not stripped.begins_with("data:"):
				continue
			var data := stripped.substr(5).strip_edges()
			_openai_stream_last_activity_msec = Time.get_ticks_msec()
			var parsed: Dictionary = _agent.call("parse_stream_data", _active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode, data)
			if not bool(parsed.get("success", false)):
				_record_openai_stream_error_trace(str(parsed.get("message", parsed.get("error", "stream_error"))))
				_finalize_openai_stream_error(str(parsed.get("message", parsed.get("error", "stream_error"))))
				return
			_remember_openai_stream_response_id(str(parsed.get("response_id", "")))
			_record_openai_stream_trace(parsed)
			var delta := str(parsed.get("text_delta", ""))
			if not delta.is_empty():
				_append_openai_stream_delta(delta)
			var final_text := str(parsed.get("final_text", "")).strip_edges()
			if not final_text.is_empty():
				_append_openai_stream_final_text(final_text)
			for tool_delta in parsed.get("tool_call_deltas", []):
				if tool_delta is Dictionary:
					_accumulate_openai_stream_tool_call(tool_delta)
			for tool_call in parsed.get("tool_calls", []):
				if tool_call is Dictionary:
					_accumulate_openai_stream_tool_call(tool_call)
			if bool(parsed.get("completed", false)):
				_finalize_openai_stream_success()
				return


func _try_finalize_openai_stream_from_buffer(reason: String) -> bool:
	_drain_openai_stream_events()
	if _openai_stream_completed:
		return true
	if _openai_plain_chat_fallback_started():
		return true
	var residual := _openai_stream_buffer.strip_edges()
	if not residual.is_empty():
		var parsed: Dictionary = _agent.call(
			"parse_stream_residual",
			_active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode,
			residual
		)
		if not bool(parsed.get("success", false)):
			return false
		if str(parsed.get("mode", "")) == "sse" and _consume_residual_openai_stream_events(parsed.get("events", [])):
			_openai_stream_buffer = ""
			if _openai_stream_completed:
				return true
		elif str(parsed.get("mode", "")) == "json" and _try_finalize_openai_non_stream_response(str(parsed.get("response_body", residual)), reason):
			_openai_stream_buffer = ""
			return true
	if not _openai_stream_text.strip_edges().is_empty() or not _openai_stream_tool_calls.is_empty():
		_state.call("append_model_event", "stream_trace", {
			"status": "salvaged",
			"api_mode": _active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode,
			"event_type": "stream.salvaged_disconnect",
			"error": reason,
			"text_delta_length": _openai_stream_text.length(),
			"tool_call_count": _openai_stream_tool_calls.size(),
			"completed": false,
		})
		_finalize_openai_stream_success()
		return true
	return false


func _openai_plain_chat_fallback_started() -> bool:
	return bool(_active_openai_transport_request.get("compatibility_fallback_attempted", false)) and str(_active_openai_transport_request.get("compatibility_fallback_mode", "")) == "plain_chat"


func _try_finalize_openai_json_body_from_buffer(reason: String) -> bool:
	if not _openai_stream_buffer_has_complete_json():
		return false
	var residual := _openai_stream_buffer.strip_edges()
	var parsed: Dictionary = _agent.call(
		"parse_stream_residual",
		_active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode,
		residual
	)
	if bool(parsed.get("success", false)):
		if str(parsed.get("mode", "")) == "json" and _try_finalize_openai_non_stream_response(str(parsed.get("response_body", residual)), reason):
			_openai_stream_buffer = ""
			return true
		return false
	var error_code := str(parsed.get("error", "stream_error"))
	if error_code == "invalid_json" or error_code == "empty_stream_residual":
		return false
	var error_message := str(parsed.get("message", "")).strip_edges()
	_openai_stream_buffer = ""
	_finalize_openai_stream_error(error_code if error_message.is_empty() else "%s: %s" % [error_code, error_message])
	return true


func _openai_stream_buffer_has_complete_json() -> bool:
	var residual := _openai_stream_buffer.strip_edges()
	if residual.is_empty() or _openai_stream_buffer_looks_like_sse(residual):
		return false
	var parser := JSON.new()
	return parser.parse(residual) == OK and parser.data is Dictionary


func _openai_stream_buffer_looks_like_sse(text: String) -> bool:
	var clean := text.strip_edges()
	return clean.begins_with("data:") or clean.begins_with("event:") or clean.find("\ndata:") >= 0 or clean.find("\nevent:") >= 0


func _consume_residual_openai_stream_events(events: Array) -> bool:
	var consumed := false
	for parsed in events:
		if not (parsed is Dictionary):
			continue
		consumed = true
		_remember_openai_stream_response_id(str(parsed.get("response_id", "")))
		_record_openai_stream_trace(parsed)
		var delta := str(parsed.get("text_delta", ""))
		if not delta.is_empty():
			_append_openai_stream_delta(delta)
		var final_text := str(parsed.get("final_text", "")).strip_edges()
		if not final_text.is_empty():
			_append_openai_stream_final_text(final_text)
		for tool_delta in parsed.get("tool_call_deltas", []):
			if tool_delta is Dictionary:
				_accumulate_openai_stream_tool_call(tool_delta)
		for tool_call in parsed.get("tool_calls", []):
			if tool_call is Dictionary:
				_accumulate_openai_stream_tool_call(tool_call)
		if bool(parsed.get("completed", false)):
			_finalize_openai_stream_success()
			return true
	return consumed


func _try_finalize_openai_non_stream_response(response_body: String, reason: String) -> bool:
	var parsed: Dictionary = _agent.call("handle_model_response", _active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode, response_body, {
		"source": "stream_residual_json",
	})
	if not bool(parsed.get("success", false)):
		return false
	var message := str(parsed.get("text", "")).strip_edges()
	var tool_call_count := int(parsed.get("tool_call_records", []).size())
	if not message.is_empty():
		_openai_stream_text = message
		_openai_stream_text_delta_total += message.length()
		_state.call("update_message_content", _openai_stream_message_index, message)
		_update_streaming_assistant_message(message)
	_openai_stream_completed_event_seen = true
	_openai_stream_last_event_type = "non_stream_response"
	_state.call("append_model_event", "stream_trace", {
		"status": "salvaged",
		"api_mode": _active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode,
		"event_type": "non_stream_response",
		"error": reason,
		"text_delta_length": message.length(),
		"tool_call_count": tool_call_count,
		"completed": true,
	})
	_finalize_openai_stream_success(parsed.get("tool_call_records", []), true)
	return true


func _record_openai_stream_trace(parsed: Dictionary) -> void:
	_openai_stream_event_count += 1
	var event_type := _openai_stream_event_type(parsed)
	if not event_type.is_empty():
		_openai_stream_last_event_type = event_type
	_remember_openai_stream_response_id(str(parsed.get("response_id", "")))
	var text_delta_length := str(parsed.get("text_delta", "")).length()
	_openai_stream_text_delta_total += text_delta_length
	var tool_delta_count := 0
	var tool_call_count := 0
	var argument_delta_length := 0
	var argument_length := 0
	var tool_names: Array[String] = []
	for tool_delta in parsed.get("tool_call_deltas", []):
		if not (tool_delta is Dictionary):
			continue
		tool_delta_count += 1
		argument_delta_length += str(tool_delta.get("arguments_delta", "")).length()
		_append_limited_tool_name(tool_names, str(tool_delta.get("name", "")))
	for tool_call in parsed.get("tool_calls", []):
		if not (tool_call is Dictionary):
			continue
		tool_call_count += 1
		argument_length += str(tool_call.get("arguments", "")).length()
		_append_limited_tool_name(tool_names, str(tool_call.get("name", "")))
	_openai_stream_tool_delta_count += tool_delta_count
	_openai_stream_tool_call_count += tool_call_count
	var completed := bool(parsed.get("completed", false))
	if completed:
		_openai_stream_completed_event_seen = true
	if _state != null and (completed or tool_delta_count > 0 or tool_call_count > 0):
		_state.call("append_model_event", "stream_trace", {
			"status": "received",
			"api_mode": _active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode,
			"event_type": event_type,
			"text_delta_length": text_delta_length,
			"tool_delta_count": tool_delta_count,
			"tool_call_count": tool_call_count,
			"argument_delta_length": argument_delta_length,
			"argument_length": argument_length,
			"tool_names": tool_names,
			"completed": completed,
			"response_id": _openai_stream_response_id,
		})


func _record_openai_stream_error_trace(error_message: String) -> void:
	_openai_stream_event_count += 1
	_openai_stream_last_event_type = "stream.error"
	if _state == null:
		return
	_state.call("append_model_event", "stream_trace", {
		"status": "failed",
		"api_mode": _active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode,
		"event_type": "stream.error",
		"error": error_message.strip_edges(),
	})


func _openai_stream_event_type(parsed: Dictionary) -> String:
	var raw = parsed.get("raw", {})
	if raw is Dictionary:
		var raw_type := str(raw.get("type", "")).strip_edges()
		if not raw_type.is_empty():
			return raw_type
	if bool(parsed.get("completed", false)):
		return "stream.completed"
	if str(parsed.get("text_delta", "")).length() > 0:
		return "text.delta"
	if not parsed.get("tool_call_deltas", []).is_empty():
		return "tool.delta"
	if not parsed.get("tool_calls", []).is_empty():
		return "tool.call"
	return "stream.event"


func _append_limited_tool_name(names: Array[String], tool_name: String) -> void:
	var normalized := tool_name.strip_edges()
	if normalized.is_empty() or names.has(normalized) or names.size() >= 4:
		return
	names.append(normalized)


func _openai_stream_trace_summary() -> Dictionary:
	return {
		"stream_event_count": _openai_stream_event_count,
		"text_delta_total": _openai_stream_text_delta_total,
		"tool_delta_count": _openai_stream_tool_delta_count,
		"tool_call_count": max(_openai_stream_tool_call_count, _openai_stream_tool_calls.size()),
		"completed_event_seen": _openai_stream_completed_event_seen,
		"last_event_type": _openai_stream_last_event_type,
		"response_id": _openai_stream_response_id,
		"poll_ticks": _openai_stream_poll_ticks,
		"stream_path": str(_active_openai_transport_request.get("stream_path", "")),
		"api_mode": _active_openai_api_mode if not _active_openai_api_mode.is_empty() else str(_active_openai_transport_request.get("api_mode", _state.api_mode)),
		"stream_fallback_attempted": bool(_active_openai_transport_request.get("stream_fallback_attempted", false)),
		"stream_fallback_from": str(_active_openai_transport_request.get("stream_fallback_from", "")),
	}


func _remember_openai_stream_response_id(response_id: String) -> void:
	var clean_response_id := response_id.strip_edges()
	if clean_response_id.is_empty() or clean_response_id == _openai_stream_response_id:
		return
	_openai_stream_response_id = clean_response_id
	for key in _openai_stream_tool_calls.keys():
		var record: Dictionary = _openai_stream_tool_calls[key]
		if str(record.get("response_id", "")).is_empty():
			record["response_id"] = _openai_stream_response_id
			_openai_stream_tool_calls[key] = record


func _append_openai_stream_delta(delta: String) -> void:
	_openai_stream_text += delta
	_state.call("update_message_content", _openai_stream_message_index, _openai_stream_text)
	_update_streaming_assistant_message()


func _append_openai_stream_final_text(text: String) -> void:
	var final_text := text.strip_edges()
	if final_text.is_empty():
		return
	_openai_stream_text = final_text
	_state.call("update_message_content", _openai_stream_message_index, _openai_stream_text)
	_update_streaming_assistant_message()


func _accumulate_openai_stream_tool_call(item: Dictionary) -> void:
	var key := _openai_stream_tool_call_key(item)
	var record: Dictionary = _openai_stream_tool_calls.get(key, {})
	var first_seen := record.is_empty()
	record["id"] = str(item.get("id", record.get("id", key)))
	if item.has("index"):
		record["index"] = int(item.get("index", -1))
	if not str(item.get("name", "")).is_empty():
		record["name"] = str(item.get("name", ""))
	if not str(item.get("response_id", "")).is_empty():
		record["response_id"] = str(item.get("response_id", ""))
	elif not _openai_stream_response_id.is_empty() and str(record.get("response_id", "")).is_empty():
		record["response_id"] = _openai_stream_response_id
	var next_arguments := str(record.get("arguments", ""))
	if item.has("arguments_delta"):
		next_arguments += str(item.get("arguments_delta", ""))
	elif item.has("arguments"):
		next_arguments = str(item.get("arguments", ""))
	record["arguments"] = next_arguments
	_openai_stream_tool_calls[key] = record
	var partial_id := "partial_%s" % key
	record["partial_id"] = partial_id
	_openai_stream_tool_calls[key] = record
	_state.call("update_partial_tool_call", {
		"id": partial_id,
		"name": str(record.get("name", "工具调用")),
		"arguments": str(record.get("arguments", "")),
		"status": "streaming",
		"batch_key": str(_active_openai_transport_request.get("sampling_batch_id", "")),
		"expanded": true,
	})
	_render_active_messages()
	if first_seen and _openai_stream_steps != null:
		_record_stream_step("工具调用 · %s" % str(record.get("name", record.get("id", key))), "正在解析")


func _openai_stream_tool_call_key(item: Dictionary) -> String:
	if item.has("index"):
		var item_index := int(item.get("index", -1))
		for existing_key in _openai_stream_tool_calls.keys():
			var existing: Dictionary = _openai_stream_tool_calls[existing_key]
			if int(existing.get("index", -2)) == item_index:
				return str(existing_key)
	var id_key := str(item.get("id", ""))
	if not id_key.is_empty():
		return id_key
	if item.has("index"):
		return "index_%d" % int(item.get("index", _openai_stream_tool_calls.size()))
	return "index_%d" % _openai_stream_tool_calls.size()


func _record_accumulated_openai_stream_tool_calls(source_event_id: String = "") -> Array:
	var tool_calls: Array[Dictionary] = []
	var partial_ids_to_clear: Array[String] = []
	for key in _openai_stream_tool_calls.keys():
		var record: Dictionary = _openai_stream_tool_calls[key]
		if _openai_stream_recorded_tool_calls.has(key):
			continue
		if str(record.get("name", "")).is_empty() and str(record.get("arguments", "")).is_empty():
			continue
		tool_calls.append(record)
		partial_ids_to_clear.append(str(record.get("partial_id", "partial_%s" % str(key))))
		_openai_stream_recorded_tool_calls[key] = true
	if tool_calls.is_empty():
		return []
	var records: Array = _state.call("record_tool_calls", tool_calls, source_event_id)
	for partial_id in partial_ids_to_clear:
		_state.call("complete_partial_tool_call", partial_id)
		_remove_tool_transcript_row(partial_id)
	_render_active_messages()
	return records


func _finalize_openai_stream_success(pre_recorded_tool_calls: Array = [], use_pre_recorded_tool_calls: bool = false) -> void:
	if _openai_stream_completed:
		return
	_openai_stream_completed = true
	_stop_openai_stream_timer()
	var api_mode := _active_openai_api_mode
	_active_openai_api_mode = ""
	_state.set("is_running", false)
	_refresh_openai_transport_buttons(false, false)
	_state.call("clear_retry_openai_request")
	var message := _openai_stream_text.strip_edges()
	var tool_call_count := pre_recorded_tool_calls.size() if use_pre_recorded_tool_calls else _openai_stream_tool_calls.size()
	var effective_api_mode: String = api_mode
	if effective_api_mode.is_empty():
		effective_api_mode = str(_state.api_mode)
	var is_empty_chat_completion: bool = message.is_empty() and tool_call_count == 0 and effective_api_mode == "chat_completions"
	if is_empty_chat_completion:
		_openai_stream_completed = false
		_state.set("is_running", true)
		_refresh_openai_transport_buttons(true, false)
		if _try_start_openai_plain_chat_fallback("chat_completions", 0, "", {"error": "empty_chat_completion", "message": "empty_chat_completion"}):
			return
		_openai_stream_completed = true
		_state.set("is_running", false)
		_refresh_openai_transport_buttons(false, false)
		_state.call("set_retry_openai_request", _active_openai_transport_request, "failed", "empty_chat_completion")
		message = "OpenAI 请求失败：empty_chat_completion（模型未返回文本或工具调用）。"
		_state.call("update_message_content", _openai_stream_message_index, message)
		_update_streaming_assistant_message(message)
		_record_stream_step("OpenAI stream", "失败")
		_state.call("stop_agent_loop", "empty_chat_completion")
	else:
		_update_streaming_assistant_message(message)
		_record_stream_step("OpenAI stream", "已完成")
	var transport_payload := {
		"status": "failed" if is_empty_chat_completion else "completed",
		"stage": _openai_transport_stage_from_request(_active_openai_transport_request),
		"api_mode": api_mode if not api_mode.is_empty() else _state.api_mode,
		"endpoint": str(_active_openai_transport_request.get("endpoint", "")),
		"model": str(_active_openai_transport_request.get("model", _state.model)),
		"stream": true,
		"message_length": message.length(),
		"tool_call_count": tool_call_count,
	}
	if is_empty_chat_completion:
		transport_payload["error"] = "empty_chat_completion"
	transport_payload.merge(_openai_stream_trace_summary(), true)
	if use_pre_recorded_tool_calls:
		transport_payload["tool_call_count"] = pre_recorded_tool_calls.size()
	transport_payload.merge(_openai_transport_audit_context(_active_openai_transport_request), true)
	var transport_event: Dictionary = _state.call("append_model_event", "openai_transport", transport_payload)
	var sampling_batch_id := str(_active_openai_transport_request.get("sampling_batch_id", transport_event.get("id", "")))
	var tool_call_records := pre_recorded_tool_calls if use_pre_recorded_tool_calls else _record_accumulated_openai_stream_tool_calls(sampling_batch_id)
	_state.call("clear_partial_tool_calls")
	_clear_partial_tool_transcript_rows()
	if tool_call_records.size() > 0:
		if _openai_stream_text.strip_edges().is_empty():
			_remove_streaming_assistant_placeholder()
		_advance_agent_loop_after_model_response(tool_call_records.size())
	elif tool_call_count > 0 and _has_recent_tool_call_cycle_block():
		_remove_streaming_assistant_placeholder()
		_add_persisted_message("assistant", "检测到模型重复请求同一个已完成工具调用，已停止自动续跑。")
		_state.call("stop_agent_loop", "repeated_tool_call_cycle")
	elif not is_empty_chat_completion:
		_state.call("stop_agent_loop", "final_model_response")
		call_deferred("_maybe_send_next_queued_user_message")
	_finish_streaming_status("已处理")
	_save_sessions()
	_active_openai_transport_request = {}
	_apply_model(_state.call("to_model"))


func _finalize_openai_stream_error(error_message: String) -> void:
	_stop_openai_stream_timer()
	var clean_error := error_message.strip_edges()
	if clean_error.is_empty():
		clean_error = "stream_error"
	if _openai_stream_last_event_type != "stream.error":
		_record_openai_stream_error_trace(clean_error)
	var display_error := _openai_stream_error_message(clean_error)
	var provider_message := _openai_http_error_message(_openai_stream_http_error_code, _openai_stream_http_error_body) if _openai_stream_http_error_code > 0 else ""
	if _openai_stream_http_error_code > 0 and not provider_message.is_empty() and display_error.find(provider_message) < 0:
		display_error = "%s\n供应商返回：%s" % [display_error, provider_message]
	_state.set("is_running", false)
	_refresh_openai_transport_buttons(false, true)
	_state.call("clear_partial_tool_calls")
	_clear_partial_tool_transcript_rows()
	_state.call("set_retry_openai_request", _active_openai_transport_request, "failed", clean_error)
	_state.call("stop_agent_loop", clean_error)
	var message := "OpenAI 请求失败：%s。" % display_error
	if _openai_stream_message_index >= 0:
		_state.call("update_message_content", _openai_stream_message_index, message)
		_update_streaming_assistant_message(message)
	else:
		_add_persisted_message("assistant", message)
	_record_stream_step("OpenAI stream", "失败")
	_finish_streaming_status("已停止")
	var transport_payload := {
		"status": "failed",
		"endpoint": str(_active_openai_transport_request.get("endpoint", "")),
		"api_mode": _active_openai_api_mode if not _active_openai_api_mode.is_empty() else _state.api_mode,
		"model": str(_active_openai_transport_request.get("model", _state.model)),
		"error": clean_error,
		"message": display_error,
		"stream": true,
	}
	if _openai_stream_http_error_code > 0:
		transport_payload["status_code"] = _openai_stream_http_error_code
		transport_payload["body_preview"] = _openai_http_error_body_preview(_openai_stream_http_error_body)
		transport_payload["fallback_attempted"] = bool(_active_openai_transport_request.get("stream_fallback_attempted", false))
	transport_payload.merge(_openai_stream_trace_summary(), true)
	transport_payload.merge(_openai_transport_audit_context(_active_openai_transport_request), true)
	_state.call("append_model_event", "openai_transport", transport_payload)
	_active_openai_api_mode = ""
	_active_openai_transport_request = {}
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _has_recent_tool_call_cycle_block() -> bool:
	if _state == null:
		return false
	var events: Array = _state.call("active_model_events")
	for index in range(events.size() - 1, -1, -1):
		var event = events[index]
		if not (event is Dictionary):
			continue
		var kind := str((event as Dictionary).get("kind", ""))
		if kind == "tool_call_cycle_blocked":
			return true
		if kind == "tool_call" or kind == "assistant_message" or kind == "message":
			return false
	return false


func _openai_stream_error_message(error_message: String) -> String:
	var clean_error := error_message.strip_edges()
	if clean_error.begins_with("stream_poll_"):
		var code := int(clean_error.trim_prefix("stream_poll_"))
		match code:
			ERR_CANT_CONNECT:
				return "%s（无法连接到 API 端点；请检查 API Base URL、网络或代理设置）" % clean_error
			ERR_CANT_RESOLVE:
				return "%s（无法解析 API 域名；请检查 API Base URL 或 DNS/网络设置）" % clean_error
			ERR_CONNECTION_ERROR:
				return "%s（连接错误；请检查 API Base URL、网络/代理，以及当前供应商是否可访问）" % clean_error
			ERR_TIMEOUT:
				return "%s（请求超时；请检查网络、代理或供应商响应状态）" % clean_error
	if clean_error.begins_with("stream_request_"):
		return "%s（请求发送失败；请检查 API Base URL、请求路径和供应商兼容性）" % clean_error
	if clean_error.begins_with("fallback_start_error_"):
		return "%s（流式请求失败后尝试非流式回退，但回退请求未能启动）" % clean_error
	if clean_error.begins_with("compatibility_fallback_start_error"):
		return "%s（供应商兼容降级请求未能启动）" % clean_error
	if clean_error.begins_with("http_"):
		return "%s（供应商返回非成功 HTTP 状态；已读取错误体并保留可重试请求）" % clean_error
	if clean_error == "stream_timeout":
		return "stream_timeout（流式响应超时；请检查供应商响应、网络或代理状态）"
	if clean_error == "stream_disconnected":
		return "stream_disconnected（连接在完成事件前断开；请重试或检查供应商流式响应兼容性）"
	return clean_error


func _stop_openai_stream_timer() -> void:
	if _openai_stream_timer != null:
		_openai_stream_timer.stop()
	if _openai_stream_client != null:
		_openai_stream_client.close()


func _requires_openai_send_approval() -> bool:
	return str(_state.approval_mode) == "请求批准"


func _queue_openai_approval_request(transport_request: Dictionary, source: String = "user_prompt", tool_call_id: String = "") -> void:
	var source_label := "工具结果续跑" if source == "tool_result_continuation" else "用户提示"
	if source == "retry_request":
		source_label = "重试"
	elif source == "queued_user_message":
		source_label = "队列用户消息"
	var summary := "%s发送 OpenAI 请求：%s · %s · %d bytes" % [
		source_label,
		str(transport_request.get("model", "")),
		str(transport_request.get("endpoint", "")),
		JSON.stringify(transport_request.get("payload", {})).length(),
	]
	var approval: Dictionary = _state.call("record_approval_checkpoint", {
		"action": "network:openai_request",
		"summary": summary,
		"risk": "high",
		"requires_approval": true,
		"source": source,
		"tool_call_id": tool_call_id,
		"created_at": Time.get_datetime_string_from_system(),
	})
	_state.call("set_pending_openai_approval_request", transport_request, approval)
	_state.call("append_model_event", "openai_transport", {
		"status": "approval_required",
		"approval_id": str(approval.get("id", "")),
		"endpoint": str(transport_request.get("endpoint", "")),
		"api_mode": str(transport_request.get("api_mode", _state.api_mode)),
		"model": str(transport_request.get("model", "")),
		"body_length": JSON.stringify(transport_request.get("payload", {})).length(),
		"source": source,
		"tool_call_id": tool_call_id,
	})
	_state.call("stop_agent_loop", "openai_approval_required")
	_add_persisted_message("assistant", "OpenAI 请求已等待审批：%s。" % summary)


func _on_openai_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if _openai_cancel_requested:
		_openai_cancel_requested = false
		return
	var api_mode := _active_openai_api_mode
	_active_openai_api_mode = ""
	_state.set("is_running", false)
	_refresh_openai_transport_buttons(false, true)
	var text := body.get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS:
		text = JSON.stringify({"error": {"type": "transport_%d" % result, "message": "HTTPRequest transport result: %d" % result}})
	elif text.strip_edges().is_empty():
		text = JSON.stringify({"error": {"type": "empty_response", "message": "OpenAI returned an empty response."}})
	var response_metadata := _openai_transport_audit_context(_active_openai_transport_request)
	var parsed: Dictionary = _agent.call("handle_model_http_result", api_mode if not api_mode.is_empty() else _state.api_mode, response_code, text, response_metadata)
	var was_stream_fallback := bool(_active_openai_transport_request.get("stream_fallback_attempted", false))
	var was_compatibility_fallback := bool(_active_openai_transport_request.get("compatibility_fallback_attempted", false))
	var was_direct_http := _openai_transport_stage_from_request(_active_openai_transport_request) == "non_stream_direct"
	var parsed_success := bool(parsed.get("success", false))
	var parsed_message := ""
	var parsed_tool_call_count := 0
	if parsed_success:
		parsed_message = str(parsed.get("text", "")).strip_edges()
		parsed_tool_call_count = int(parsed.get("tool_call_records", []).size())
		var effective_api_mode: String = api_mode
		if effective_api_mode.is_empty():
			effective_api_mode = str(_state.api_mode)
		if parsed_message.is_empty() and parsed_tool_call_count == 0 and effective_api_mode == "chat_completions":
			if not was_compatibility_fallback and _try_start_openai_plain_chat_fallback(effective_api_mode, response_code, text, {"error": "empty_chat_completion", "message": "empty_chat_completion"}):
				return
			parsed_success = false
			parsed["error"] = "empty_chat_completion"
			parsed["message"] = "empty_chat_completion"
	if parsed_success:
		_state.call("clear_retry_openai_request")
		var message := parsed_message
		var tool_call_count := parsed_tool_call_count
		if message.is_empty() and tool_call_count > 0:
			message = ""
		if message.is_empty():
			message = "" if tool_call_count > 0 else "模型响应已完成。"
		if (was_stream_fallback or was_compatibility_fallback or was_direct_http) and _openai_stream_message_index >= 0:
			_openai_stream_text = message
			if message.is_empty() and tool_call_count > 0:
				_remove_streaming_assistant_placeholder()
			else:
				_state.call("update_message_content", _openai_stream_message_index, message)
				_update_streaming_assistant_message(message)
			_record_stream_step(_openai_non_stream_stage_label(was_stream_fallback, was_compatibility_fallback, was_direct_http), "已完成")
			_finish_streaming_status("已处理")
		else:
			if not message.is_empty():
				_add_persisted_message("assistant", message)
		if tool_call_count > 0:
			_advance_agent_loop_after_model_response(tool_call_count)
		else:
			_state.call("stop_agent_loop", "final_model_response")
			call_deferred("_maybe_send_next_queued_user_message")
	else:
		var error_message := str(parsed.get("message", "")).strip_edges()
		if error_message.is_empty():
			error_message = str(parsed.get("error", "unknown_openai_error"))
		if _try_start_openai_plain_chat_fallback(api_mode if not api_mode.is_empty() else _state.api_mode, response_code, text, parsed):
			return
		_state.call("set_retry_openai_request", _active_openai_transport_request, "failed", error_message)
		_state.call("stop_agent_loop", error_message)
		var failed_message := "OpenAI 请求失败：%s。" % error_message
		if (was_stream_fallback or was_compatibility_fallback or was_direct_http) and _openai_stream_message_index >= 0:
			_state.call("update_message_content", _openai_stream_message_index, failed_message)
			_update_streaming_assistant_message(failed_message)
			_record_stream_step(_openai_non_stream_stage_label(was_stream_fallback, was_compatibility_fallback, was_direct_http), "失败")
			_finish_streaming_status("已停止")
		else:
			_add_persisted_message("assistant", failed_message)
	var transport_event := {
		"status": "completed" if parsed_success else "failed",
		"stage": _openai_transport_stage_from_request(_active_openai_transport_request),
		"status_code": response_code,
		"endpoint": str(_active_openai_transport_request.get("endpoint", "")),
		"provider": str(_active_openai_transport_request.get("provider", _state.provider)),
		"api_mode": api_mode if not api_mode.is_empty() else _state.api_mode,
		"model": str(_active_openai_transport_request.get("model", _state.model)),
		"error": str(parsed.get("error", "")),
		"message": str(parsed.get("message", "")),
		"stream": not was_stream_fallback and not was_compatibility_fallback and not was_direct_http,
		"stream_fallback_attempted": was_stream_fallback,
		"compatibility_fallback_attempted": was_compatibility_fallback,
		"compatibility_fallback_mode": str(_active_openai_transport_request.get("compatibility_fallback_mode", "")),
	}
	transport_event.merge(_openai_transport_audit_context(_active_openai_transport_request), true)
	_state.call("append_model_event", "openai_transport", transport_event)
	_save_sessions()
	_active_openai_transport_request = {}
	_apply_model(_state.call("to_model"))


func _openai_non_stream_stage_label(was_stream_fallback: bool, was_compatibility_fallback: bool, was_direct_http: bool) -> String:
	if was_compatibility_fallback:
		return "OpenAI 兼容降级"
	if was_stream_fallback:
		return "OpenAI 非流式回退"
	if was_direct_http:
		return "OpenAI 非流式请求"
	return "OpenAI 请求"


func _cancel_openai_request() -> void:
	if not _is_openai_busy():
		if _state != null and (bool(_state.get("is_running")) or str(_state.get("agent_loop_status")) == "running"):
			_openai_cancel_requested = true
			_state.set("is_running", false)
			_state.call("stop_agent_loop", "user_canceled")
			_save_sessions()
			_apply_model(_state.call("to_model"))
			return
		_add_persisted_message("assistant", "当前没有正在执行的 OpenAI 请求。")
		_apply_model(_state.call("to_model"))
		return
	if _openai_stream_timer != null and not _openai_stream_timer.is_stopped():
		_stop_openai_stream_timer()
	elif _openai_request != null:
		_openai_request.cancel_request()
	_openai_cancel_requested = true
	var api_mode := _active_openai_api_mode
	_active_openai_api_mode = ""
	_state.set("is_running", false)
	_refresh_openai_transport_buttons(false, true)
	_state.call("clear_partial_tool_calls")
	_clear_partial_tool_transcript_rows()
	_state.call("set_retry_openai_request", _active_openai_transport_request, "canceled", "user_canceled")
	var cancel_audit := _openai_transport_audit_context(_active_openai_transport_request)
	_active_openai_transport_request = {}
	var canceled_event := {
		"status": "canceled",
		"api_mode": api_mode if not api_mode.is_empty() else _state.api_mode,
		"stream": true,
	}
	canceled_event.merge(cancel_audit, true)
	_state.call("append_model_event", "openai_transport", canceled_event)
	if _openai_stream_message_index >= 0:
		var message := _openai_stream_text.strip_edges()
		if message.is_empty():
			message = "已停止当前 OpenAI 请求。"
		else:
			message = "%s\n\n[已停止]" % message
		_state.call("update_message_content", _openai_stream_message_index, message)
		_update_streaming_assistant_message(message)
		_record_stream_step("OpenAI stream", "已停止")
		_finish_streaming_status("已取消")
	else:
		_add_persisted_message("assistant", "已停止当前 OpenAI 请求。")
	_state.call("stop_agent_loop", "user_canceled")
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _retry_openai_request() -> void:
	if _is_openai_busy():
		_add_persisted_message("assistant", "已有 OpenAI 请求正在执行，暂不能重试。")
		_apply_model(_state.call("to_model"))
		return
	var transport_request: Dictionary = _state.call("retry_openai_transport_request")
	if transport_request.is_empty():
		_add_persisted_message("assistant", "当前没有可重试的 OpenAI 请求。")
		_apply_model(_state.call("to_model"))
		return
	transport_request = _normalize_retry_openai_transport_request(transport_request)
	if _requires_openai_send_approval():
		_queue_openai_approval_request(transport_request, "retry_request")
		_save_sessions()
		_apply_model(_state.call("to_model"))
		return
	if not _start_openai_transport(transport_request):
		_add_persisted_message("assistant", "OpenAI 重试请求启动失败，已保留可重试状态。")
		_save_sessions()
	_apply_model(_state.call("to_model"))


func _normalize_retry_openai_transport_request(transport_request: Dictionary) -> Dictionary:
	if _state != null and _state.has_method("normalize_runtime_provider"):
		_state.call("normalize_runtime_provider")
	var normalized := transport_request.duplicate(true)
	var target_api_mode := str(normalized.get("api_mode", _state.api_mode)).strip_edges()
	if str(_state.provider) == "yurenapi":
		target_api_mode = "chat_completions"
		normalized["api_mode"] = target_api_mode
		normalized["endpoint"] = OpenAIRequestBuilder.endpoint_for(str(_state.base_url), target_api_mode)
	return normalized


func _retry_tooltip(preview: Dictionary) -> String:
	if preview.is_empty():
		return "没有失败或已取消的 OpenAI 请求可重试。"
	var reason := str(preview.get("reason", ""))
	var detail := "%s · %s" % [str(preview.get("model", "")), str(preview.get("endpoint", ""))]
	if not reason.is_empty():
		detail += " · %s" % reason
	return "重试上一条 OpenAI 请求：%s" % detail


func _add_message(role: String, text: String, metadata: Dictionary = {}) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = _next_transcript_row_name("UserMessageRow" if role == "user" else "AssistantMessageRow")
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.clip_contents = false
	panel.add_theme_stylebox_override("panel", _transcript_row_style())
	var row := HBoxContainer.new()
	row.name = "MessageRowContent"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", 0)
	var bubble: PanelContainer = null
	if role == "user":
		bubble = PanelContainer.new()
		bubble.name = "UserMessageBubble"
		bubble.mouse_filter = Control.MOUSE_FILTER_PASS
		bubble.custom_minimum_size.x = _user_message_bubble_width(text)
		bubble.size_flags_horizontal = Control.SIZE_SHRINK_END
		bubble.add_theme_stylebox_override("panel", _user_message_bubble_style())
	var box := VBoxContainer.new()
	box.name = "UserMessageBubbleContent" if role == "user" else "AssistantMessageContent"
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	box.add_theme_constant_override("separation", 4)
	if role != "user":
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := RichTextLabel.new()
	label.name = "MessageText"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.fit_content = true
	label.bbcode_enabled = false
	label.selection_enabled = true
	label.scroll_active = false
	label.text = _message_display_text(role, text)
	if role == "user":
		label.custom_minimum_size = Vector2(max(0.0, bubble.custom_minimum_size.x - USER_MESSAGE_BUBBLE_HORIZONTAL_PADDING), 20)
	else:
		label.custom_minimum_size = Vector2(0, 20)
	label.add_theme_stylebox_override("normal", _transparent_panel_style(0, 0, 0, 0))
	panel.set_meta("message_label", label)
	panel.set_meta("message_role", role)
	panel.set_meta("message_text", text)
	panel.set_meta("message_metadata", metadata.duplicate(true))
	box.add_child(label)
	if role == "user":
		var reference_summary := _message_reference_summary(metadata.get("references", []))
		if not reference_summary.is_empty():
			var reference_label := Label.new()
			reference_label.name = "MessageReferenceSummary"
			reference_label.text = reference_summary
			reference_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			GodexTheme.paint_label(reference_label, GodexTheme.MUTED, 12)
			box.add_child(reference_label)
	if _message_is_long(text):
		var hint := Label.new()
		hint.text = "完整内容已保留在会话与 Automation 审计中。"
		GodexTheme.paint_label(hint, GodexTheme.MUTED, 12)
		box.add_child(hint)
	if role == "user":
		var spacer := Control.new()
		spacer.name = "UserMessageLeadingSpacer"
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(spacer)
		bubble.add_child(box)
		row.add_child(bubble)
	else:
		row.add_child(box)
	panel.mouse_entered.connect(_on_message_hover_changed.bind(panel, true))
	panel.mouse_exited.connect(_on_message_hover_changed.bind(panel, false))
	panel.gui_input.connect(_on_message_gui_input.bind(panel))
	row.mouse_entered.connect(_on_message_hover_changed.bind(panel, true))
	row.mouse_exited.connect(_on_message_hover_changed.bind(panel, false))
	row.gui_input.connect(_on_message_gui_input.bind(panel))
	box.mouse_entered.connect(_on_message_hover_changed.bind(panel, true))
	box.mouse_exited.connect(_on_message_hover_changed.bind(panel, false))
	box.gui_input.connect(_on_message_gui_input.bind(panel))
	label.mouse_entered.connect(_on_message_hover_changed.bind(panel, true))
	label.mouse_exited.connect(_on_message_hover_changed.bind(panel, false))
	label.gui_input.connect(_on_message_gui_input.bind(panel))
	if bubble != null:
		bubble.mouse_entered.connect(_on_message_hover_changed.bind(panel, true))
		bubble.mouse_exited.connect(_on_message_hover_changed.bind(panel, false))
		bubble.gui_input.connect(_on_message_gui_input.bind(panel))
	panel.add_child(row)
	if role == "user":
		var copy_button := Button.new()
		copy_button.name = "MessageCopyButton"
		copy_button.text = ""
		copy_button.visible = false
		copy_button.focus_mode = Control.FOCUS_NONE
		copy_button.custom_minimum_size = Vector2(28, 28)
		copy_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		copy_button.tooltip_text = "复制"
		_set_button_icon(copy_button, ["ActionCopy", "Duplicate", "Copy"])
		GodexTheme.paint_button(copy_button)
		copy_button.pressed.connect(_copy_message_text.bind(panel))
		copy_button.mouse_entered.connect(_on_message_hover_changed.bind(panel, true))
		copy_button.mouse_exited.connect(_on_message_hover_changed.bind(panel, false))
		copy_button.gui_input.connect(_on_message_gui_input.bind(panel))
		panel.set_meta("message_copy_button", copy_button)
		panel.add_child(copy_button)
	panel.custom_minimum_size = Vector2(0, 0)
	_messages.add_child(panel)
	if role == "user" and not _message_hover_panels.has(panel):
		_message_hover_panels.append(panel)
	if role == "user":
		panel.resized.connect(_position_message_copy_button.bind(panel))
		call_deferred("_position_message_copy_button", panel)
	return panel


func _on_message_hover_changed(panel: PanelContainer, hovered: bool) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var copy_button := _message_copy_button(panel)
	if copy_button != null:
		_position_message_copy_button(panel)
		if hovered:
			panel.set_meta("message_hovered", true)
			copy_button.visible = true
		else:
			var still_hovered := _is_pointer_over_message_panel(panel, true)
			panel.set_meta("message_hovered", still_hovered)
			copy_button.visible = still_hovered


func _on_message_gui_input(event: InputEvent, panel: PanelContainer) -> void:
	if event is InputEventMouse:
		_on_message_hover_changed(panel, true)
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_update_message_selection_actions(panel)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_update_message_selection_actions(panel)


func _update_message_selection_actions(panel: PanelContainer) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var role := str(panel.get_meta("message_role", ""))
	if role != "assistant":
		_hide_selection_action_panel()
		return
	var label := panel.get_meta("message_label", null) as RichTextLabel
	if label == null:
		_hide_selection_action_panel()
		return
	var selected := label.get_selected_text().strip_edges()
	if selected.is_empty():
		_hide_selection_action_panel()
		return
	_selection_source_panel = panel
	_selection_source_label = label
	_selection_source_role = role
	_selection_text = selected
	_show_selection_action_panel()


func _show_selection_action_panel() -> void:
	_ensure_selection_action_panel()
	if _selection_action_panel == null:
		return
	_selection_action_panel.visible = true
	_position_selection_action_panel()


func _hide_selection_action_panel() -> void:
	if _selection_action_panel != null:
		_selection_action_panel.visible = false


func _add_selection_reference_to_composer() -> void:
	if _selection_text.strip_edges().is_empty():
		_hide_selection_action_panel()
		return
	_add_composer_reference({
		"kind": "quote",
		"title": "引用输出",
		"detail": _preview_text(_selection_text, 90),
		"content": _selection_text,
	})
	_hide_selection_action_panel()
	if _composer != null and _composer.is_inside_tree():
		_composer.grab_focus()


func _ask_selection_in_side_chat() -> void:
	if _selection_text.strip_edges().is_empty():
		_hide_selection_action_panel()
		return
	_add_composer_reference({
		"kind": "quote",
		"title": "侧边聊天提问",
		"detail": _preview_text(_selection_text, 90),
		"content": _selection_text,
	})
	if _composer != null:
		var prefix := "基于这段引用继续提问："
		if _composer.text.strip_edges().is_empty():
			_composer.text = prefix
			_composer.set_caret_line(0)
			_composer.set_caret_column(prefix.length())
		if _composer.is_inside_tree():
			_composer.grab_focus()
	_hide_selection_action_panel()


func _add_composer_reference(reference: Dictionary) -> void:
	if _state == null:
		return
	var kind := str(reference.get("kind", "text"))
	if kind == "quote":
		kind = "text"
	var value := str(reference.get("content", reference.get("value", reference.get("detail", ""))))
	var metadata := reference.duplicate(true)
	metadata["title"] = str(metadata.get("title", "引用"))
	metadata["source"] = str(metadata.get("source", "composer"))
	metadata["detail"] = str(metadata.get("detail", value))
	_state.call("add_composer_reference", kind, value, metadata)
	_rebuild_composer_reference_bar()
	_apply_send_button_model(_state.call("to_model"))


func _rebuild_composer_reference_bar() -> void:
	_ensure_composer_reference_bar()
	if _composer_reference_bar == null:
		return
	_clear(_composer_reference_bar)
	var references := _active_composer_references()
	_composer_reference_bar.visible = not references.is_empty()
	for item in references:
		_composer_reference_bar.add_child(_build_composer_reference_chip(item))


func _build_composer_reference_chip(item: Dictionary) -> PanelContainer:
	var chip := PanelContainer.new()
	chip.name = "ComposerReferenceChip"
	chip.mouse_filter = Control.MOUSE_FILTER_STOP
	chip.add_theme_stylebox_override("panel", GodexTheme.panel_style(Color(0.17, 0.17, 0.17), 8, Color(0.31, 0.32, 0.34)))
	var row := HBoxContainer.new()
	row.name = "ComposerReferenceChipRow"
	row.add_theme_constant_override("separation", 6)
	var icon := Label.new()
	icon.name = "ComposerReferenceChipIcon"
	icon.text = "IMG" if str(item.get("kind", "")) == "image" else "REF"
	icon.custom_minimum_size = Vector2(30, 24)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GodexTheme.paint_label(icon, GodexTheme.MUTED, 11)
	row.add_child(icon)
	var text := Label.new()
	text.name = "ComposerReferenceChipText"
	text.text = "%s · %s" % [str(item.get("title", "引用")), _preview_text(str(item.get("detail", item.get("value", ""))), 42)]
	text.custom_minimum_size = Vector2(0, 24)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	GodexTheme.paint_label(text, GodexTheme.TEXT, 12)
	row.add_child(text)
	var close := Button.new()
	close.name = "ComposerReferenceChipClose"
	close.text = "×"
	close.custom_minimum_size = Vector2(24, 24)
	close.focus_mode = Control.FOCUS_NONE
	close.tooltip_text = "移除引用"
	GodexTheme.paint_button(close)
	close.pressed.connect(_remove_composer_reference.bind(str(item.get("id", ""))))
	row.add_child(close)
	chip.add_child(row)
	return chip


func _remove_composer_reference(reference_id: String) -> void:
	if _state != null:
		_state.call("remove_composer_reference", reference_id)
	_rebuild_composer_reference_bar()
	if _state != null:
		_apply_send_button_model(_state.call("to_model"))


func _clear_composer_references() -> void:
	if _active_composer_references().is_empty():
		return
	if _state != null:
		_state.call("clear_composer_references")
	_rebuild_composer_reference_bar()


func _active_composer_references() -> Array[Dictionary]:
	if _state == null or not _state.has_method("active_composer_references"):
		return [] as Array[Dictionary]
	return _state.call("active_composer_references")


func _composer_prompt_for_queue(prompt: String) -> String:
	var clean_prompt := prompt.strip_edges()
	var references := _active_composer_references()
	if references.is_empty():
		return clean_prompt
	var lines: Array[String] = ["引用与附件上下文："]
	for item in references:
		var kind := "图片附件占位" if str(item.get("kind", "")) == "image" else "引用"
		var content := str(item.get("value", item.get("detail", ""))).strip_edges()
		lines.append("- %s：%s" % [kind, content])
	if not clean_prompt.is_empty():
		lines.append("")
		lines.append(clean_prompt)
	return "\n".join(lines).strip_edges()


func _composer_reference_prompt_summary(references: Array[Dictionary]) -> String:
	var image_count := 0
	var file_count := 0
	var source_count := 0
	var text_count := 0
	for item in references:
		if not (item is Dictionary):
			continue
		match str((item as Dictionary).get("kind", "")).strip_edges().to_lower():
			"image":
				image_count += 1
			"file":
				file_count += 1
			"source":
				source_count += 1
			_:
				text_count += 1
	var parts: Array[String] = []
	if text_count > 0:
		parts.append("%d 个文本片段" % text_count)
	if image_count > 0:
		parts.append("%d 张图片" % image_count)
	if file_count > 0:
		parts.append("%d 个文件" % file_count)
	if source_count > 0:
		parts.append("%d 个资料" % source_count)
	if parts.is_empty():
		return "请参考已附加的引用资料。"
	return "请参考已附加的%s。" % "、".join(parts)


func _refresh_message_hover_from_pointer() -> void:
	for i in range(_message_hover_panels.size() - 1, -1, -1):
		var panel := _message_hover_panels[i]
		if panel == null or not is_instance_valid(panel):
			_message_hover_panels.remove_at(i)
			continue
		var copy_button := _message_copy_button(panel)
		if copy_button == null:
			continue
		_position_message_copy_button(panel)
		var hovered := _is_pointer_over_message_panel(panel)
		panel.set_meta("message_hovered", hovered)
		copy_button.visible = hovered


func _clear_message_hover_states() -> void:
	for panel in _message_hover_panels:
		if panel == null or not is_instance_valid(panel):
			continue
		panel.set_meta("message_hovered", false)
		var copy_button := _message_copy_button(panel)
		if copy_button != null:
			copy_button.visible = false


func _is_pointer_over_message_panel(panel: PanelContainer, include_copy_button: bool = false) -> bool:
	if panel == null or not is_instance_valid(panel):
		return false
	var local_pointer := panel.get_local_mouse_position()
	if Rect2(Vector2.ZERO, panel.size).grow(4.0).has_point(local_pointer):
		return true
	var candidate_pointers: Array[Vector2] = [panel.get_global_mouse_position()]
	if _root != null:
		candidate_pointers.append(_root.get_global_mouse_position())
	var viewport := panel.get_viewport()
	if viewport != null:
		candidate_pointers.append(viewport.get_mouse_position())
	var window_pointer := Vector2(DisplayServer.mouse_get_position()) - Vector2(DisplayServer.window_get_position())
	candidate_pointers.append(window_pointer)
	var candidates: Array[Control] = []
	candidates.append(panel)
	var row := panel.get_node_or_null("MessageRowContent") as Control
	if row != null:
		candidates.append(row)
	var bubble := panel.find_child("UserMessageBubble", true, false) as Control
	if bubble != null:
		candidates.append(bubble)
	var label := panel.get_meta("message_label", null) as Control
	if label != null:
		candidates.append(label)
	if include_copy_button:
		var copy_button := _message_copy_button(panel) as Control
		if copy_button != null:
			candidates.append(copy_button)
	for pointer in candidate_pointers:
		for item in candidates:
			if item != null and is_instance_valid(item) and item.get_global_rect().grow(4.0).has_point(pointer):
				return true
	return false


func _position_message_copy_button(panel: PanelContainer) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var copy_button := _message_copy_button(panel)
	if copy_button == null:
		return
	var row := panel.get_node_or_null("MessageRowContent") as Control
	var target_global := row.get_global_rect() if row != null else panel.get_global_rect()
	var bubble := panel.find_child("UserMessageBubble", true, false) as Control
	if bubble != null:
		target_global = bubble.get_global_rect()
	var panel_global := panel.get_global_rect()
	var target_rect := Rect2(target_global.position - panel_global.position, target_global.size)
	var button_size := Vector2(28, 28)
	copy_button.size = button_size
	copy_button.position = Vector2(
		max(0.0, target_rect.position.x + target_rect.size.x - button_size.x - 6.0),
		max(0.0, target_rect.position.y + target_rect.size.y - button_size.y - 6.0)
	)


func _message_copy_button(panel: PanelContainer) -> Button:
	if panel == null or not is_instance_valid(panel) or not panel.has_meta("message_copy_button"):
		return null
	return panel.get_meta("message_copy_button") as Button


func _copy_message_text(panel: PanelContainer) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var label := panel.get_meta("message_label", null) as RichTextLabel
	if label == null:
		return
	DisplayServer.clipboard_set(label.text)


func _begin_streaming_assistant_message() -> void:
	_openai_stream_message_index = int(_state.call("append_message", "assistant", ""))
	var panel := _add_message("assistant", "")
	var box := _message_content_box(panel)
	_openai_stream_label = panel.get_meta("message_label") as RichTextLabel
	if _openai_stream_label != null:
		_openai_stream_label.text = ""
	if box == null:
		return
	_openai_stream_status_row = _create_streaming_thinking_status()
	_openai_stream_status = _openai_stream_status_row.find_child("StreamingStatus", true, false) as GodexShimmerText
	box.add_child(_openai_stream_status_row)
	_start_streaming_thinking_shimmer()
	_openai_stream_steps = VBoxContainer.new()
	_openai_stream_steps.name = "StreamingSteps"
	_openai_stream_steps.visible = false
	_openai_stream_steps.add_theme_constant_override("separation", 3)
	box.add_child(_openai_stream_steps)
	_show_view("chat")


func _create_streaming_thinking_status() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "StreamingThinkingStatus"
	box.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.name = "StreamingThinkingRow"
	row.add_theme_constant_override("separation", 0)
	var label := GodexShimmerText.new()
	label.name = "StreamingStatus"
	label.text = "正在思考"
	label.font_size = 14
	row.add_child(label)
	box.add_child(row)
	return box


func _start_streaming_thinking_shimmer() -> void:
	if _openai_stream_status != null and is_instance_valid(_openai_stream_status):
		_openai_stream_status.text = "正在思考"
		_openai_stream_status.visible = true
		_openai_stream_status.set_shimmer_active(true)


func _stop_streaming_thinking_shimmer() -> void:
	if _openai_stream_status != null and is_instance_valid(_openai_stream_status):
		_openai_stream_status.set_shimmer_active(false)


func _clear_streaming_thinking_status() -> void:
	_stop_streaming_thinking_shimmer()
	if _openai_stream_status_row != null and is_instance_valid(_openai_stream_status_row):
		_openai_stream_status_row.queue_free()
	_openai_stream_status_row = null
	_openai_stream_status = null


func _remove_streaming_assistant_placeholder() -> void:
	_clear_streaming_thinking_status()
	if _openai_stream_message_index >= 0 and _state != null and _state.has_method("remove_message_at"):
		_state.call("remove_message_at", _openai_stream_message_index)
	_openai_stream_message_index = -1
	if _openai_stream_label != null and is_instance_valid(_openai_stream_label):
		var current: Node = _openai_stream_label
		while current != null and not (current is PanelContainer):
			current = current.get_parent()
		if current != null and is_instance_valid(current):
			current.queue_free()
	_openai_stream_label = null


func _message_content_box(panel: PanelContainer) -> VBoxContainer:
	if panel == null:
		return null
	var row := panel.get_node_or_null("MessageRowContent") as HBoxContainer
	if row == null:
		return null
	var content := row.get_node_or_null("AssistantMessageContent") as VBoxContainer
	if content == null:
		content = row.get_node_or_null("UserMessageBubble/UserMessageBubbleContent") as VBoxContainer
	return content


func _update_streaming_assistant_message(text_override: String = "") -> void:
	var text := text_override if not text_override.is_empty() else _openai_stream_text
	if _openai_stream_label != null:
		_openai_stream_label.text = _message_display_text("assistant", text)
	if _conversation_scroll != null:
		_conversation_scroll.call_deferred("set_v_scroll", int(_conversation_scroll.get_v_scroll_bar().max_value))


func _update_streaming_status() -> void:
	if _openai_stream_status == null:
		return
	_openai_stream_status.text = "正在思考"
	_openai_stream_status.set_shimmer_active(true)


func _finish_streaming_status(label: String) -> void:
	if _openai_stream_status == null:
		return
	if label in ["已处理", "已完成", "已停止", "已取消"]:
		_clear_streaming_thinking_status()
		return
	_openai_stream_status.text = "%s %s" % [label, _openai_stream_elapsed_text()]


func _openai_stream_elapsed_text() -> String:
	var started := int(_openai_stream_started_at_msec)
	if started <= 0:
		return "0s"
	var elapsed_msec := max(0, Time.get_ticks_msec() - started)
	return _format_elapsed_duration(int(elapsed_msec / 1000))


func _format_elapsed_duration(total_seconds: int) -> String:
	var seconds := max(0, total_seconds)
	if seconds < 60:
		return "%ds" % seconds
	var minutes: int = int(seconds / 60)
	var remainder: int = seconds % 60
	if minutes < 60:
		return "%dm %02ds" % [minutes, remainder]
	var hours: int = int(minutes / 60)
	return "%dh %02dm" % [hours, minutes % 60]


func _record_stream_step(title: String, status: String) -> void:
	if _state != null:
		_state.call("record_stream_step", title, status)


func _create_stream_step_transcript_row(title: String, status: String) -> void:
	pass


func _next_transcript_row_name(base_name: String) -> String:
	if _messages == null or _messages.find_child(base_name, false, false) == null:
		return base_name
	return "%s_%03d" % [base_name, _messages.get_child_count()]


func _message_display_text(role: String, text: String) -> String:
	return text


func _message_is_long(text: String) -> bool:
	return false


func _message_reference_summary(references) -> String:
	if not (references is Array) or (references as Array).is_empty():
		return ""
	var image_count := 0
	var file_count := 0
	var text_count := 0
	var other_count := 0
	for item in references:
		if not (item is Dictionary):
			continue
		match str((item as Dictionary).get("kind", "")).strip_edges().to_lower():
			"image":
				image_count += 1
			"file":
				file_count += 1
			"text", "quote":
				text_count += 1
			_:
				other_count += 1
	var parts: Array[String] = []
	if text_count > 0:
		parts.append("%d 个已选文本片段" % text_count)
	if image_count > 0:
		parts.append("%d 张图片" % image_count)
	if file_count > 0:
		parts.append("%d 个文件" % file_count)
	if other_count > 0:
		parts.append("%d 个引用" % other_count)
	if parts.is_empty():
		return ""
	return "附带引用：%s" % "、".join(parts)


func _mcp_tool_chat_summary(parsed: Dictionary) -> String:
	var status := "完成" if bool(parsed.get("success", false)) else "失败"
	var message := str(parsed.get("message", parsed.get("error", ""))).strip_edges()
	if message.is_empty():
		message = str(parsed.get("error", "无摘要"))
	if message.length() > 240:
		message = "%s..." % message.left(240).strip_edges()
	return "MCP 工具调用%s：%s。" % [status, message]


func _create_tool_transcript_row(tool_call_id: String, tool_name: String, status: String, detail: String, expanded: bool = false) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "ToolTranscriptRow"
	panel.add_theme_stylebox_override("panel", _transcript_row_style(6))
	var box := VBoxContainer.new()
	box.name = "ToolTranscriptBox"
	box.add_theme_constant_override("separation", 4)
	var header_record := _create_transcript_disclosure_header("ToolTranscriptHeader", ["Tools", "Node", "Object", "Script"], _tool_transcript_header_text(tool_name, status), expanded)
	var header: PanelContainer = header_record.get("header", null)
	var body := VBoxContainer.new()
	body.name = "ToolTranscriptBody"
	body.visible = expanded
	body.add_theme_constant_override("separation", 3)
	var detail_label := Label.new()
	detail_label.name = "ToolTranscriptDetail"
	detail_label.text = detail
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(detail_label, GodexTheme.MUTED, 12)
	body.add_child(detail_label)
	box.add_child(header)
	var body_margin := _transcript_detail_margin(body)
	box.add_child(body_margin)
	panel.add_child(box)
	_messages.add_child(panel)
	var row := {
		"panel": panel,
		"header": header,
		"header_title": header_record.get("title", null),
		"header_arrow": header_record.get("arrow", null),
		"body": body,
		"body_margin": body_margin,
		"detail": detail_label,
		"tool_name": tool_name,
		"status": status,
		"expanded": expanded,
	}
	header.gui_input.connect(_on_tool_transcript_header_input.bind(tool_call_id))
	_tool_transcript_rows[tool_call_id] = row
	return row


func _create_command_transcript_row(command_id: String, command: String, status: String, detail: String, expanded: bool = false, result: Dictionary = {}) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "CommandTranscriptRow"
	panel.add_theme_stylebox_override("panel", _transcript_row_style(6))
	var box := VBoxContainer.new()
	box.name = "CommandTranscriptBox"
	box.add_theme_constant_override("separation", 4)
	var header_record := _create_transcript_disclosure_header("CommandTranscriptHeader", ["Terminal", "Console", "Output", "Script", "Node"], _command_transcript_header_text(command, status), expanded)
	var header: PanelContainer = header_record.get("header", null)
	var body := VBoxContainer.new()
	body.name = "CommandTranscriptBody"
	body.visible = expanded
	body.add_theme_constant_override("separation", 3)
	var detail_label := Label.new()
	detail_label.name = "CommandTranscriptDetail"
	detail_label.text = detail
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(detail_label, GodexTheme.MUTED, 12)
	body.add_child(detail_label)
	var output_box := VBoxContainer.new()
	output_box.name = "CommandTranscriptOutput"
	output_box.add_theme_constant_override("separation", 4)
	body.add_child(output_box)
	var chunk_box := VBoxContainer.new()
	chunk_box.name = "CommandTranscriptOutputTimeline"
	chunk_box.add_theme_constant_override("separation", 3)
	body.add_child(chunk_box)
	var timeline_box := VBoxContainer.new()
	timeline_box.name = "CommandTranscriptTimeline"
	timeline_box.add_theme_constant_override("separation", 3)
	body.add_child(timeline_box)
	box.add_child(header)
	var body_margin := _transcript_detail_margin(body)
	box.add_child(body_margin)
	panel.add_child(box)
	_messages.add_child(panel)
	var row := {
		"panel": panel,
		"header": header,
		"header_title": header_record.get("title", null),
		"header_arrow": header_record.get("arrow", null),
		"body": body,
		"body_margin": body_margin,
		"detail": detail_label,
		"output": output_box,
		"chunks": chunk_box,
		"timeline": timeline_box,
		"result": result.duplicate(true),
		"command": command,
		"status": status,
		"expanded": expanded,
	}
	_refresh_command_transcript_output(row)
	header.gui_input.connect(_on_command_transcript_header_input.bind(command_id))
	_command_transcript_rows[command_id] = row
	return row


func _show_command_transcript_row(command_id: String, command: String, status: String, detail: String, expanded: bool = false, result: Dictionary = {}) -> void:
	if command_id.is_empty():
		return
	var row: Dictionary = _command_transcript_rows.get(command_id, {})
	if row.is_empty() or not is_instance_valid(row.get("panel", null)):
		row = _create_command_transcript_row(command_id, command, status, detail, expanded, result)
	else:
		row["command"] = command
		row["status"] = status
		row["expanded"] = bool(row.get("expanded", expanded))
		row["result"] = result.duplicate(true)
		var detail_label: Label = row.get("detail", null)
		if detail_label != null:
			detail_label.text = detail
		_refresh_command_transcript_output(row)
		_refresh_command_transcript_row(command_id)
	if _conversation_scroll != null:
		_conversation_scroll.call_deferred("set_v_scroll", int(_conversation_scroll.get_v_scroll_bar().max_value))


func _toggle_command_transcript_row(command_id: String) -> void:
	var row: Dictionary = _command_transcript_rows.get(command_id, {})
	if row.is_empty():
		return
	row["expanded"] = not bool(row.get("expanded", false))
	_command_transcript_rows[command_id] = row
	if _state != null:
		_state.call("set_command_run_expanded", command_id, bool(row.get("expanded", false)))
	_refresh_command_transcript_row(command_id)


func _refresh_command_transcript_row(command_id: String) -> void:
	var row: Dictionary = _command_transcript_rows.get(command_id, {})
	if row.is_empty():
		return
	var expanded := bool(row.get("expanded", false))
	var body: Control = row.get("body", null)
	if body != null:
		body.visible = expanded
	var body_margin: Control = row.get("body_margin", null)
	if body_margin != null:
		body_margin.visible = expanded
	var title: Label = row.get("header_title", null)
	if title != null:
		title.text = _command_transcript_header_text(str(row.get("command", "命令")), str(row.get("status", "")))
	_refresh_transcript_disclosure_arrow(row)
	_command_transcript_rows[command_id] = row


func _refresh_command_transcript_output(row: Dictionary) -> void:
	var output_box: VBoxContainer = row.get("output", null)
	if output_box == null:
		return
	_clear(output_box)
	var result: Dictionary = row.get("result", {})
	var chunk_box: VBoxContainer = row.get("chunks", null)
	if chunk_box != null:
		_clear(chunk_box)
		var output_chunks: Array = result.get("output_chunks", [])
		chunk_box.visible = not output_chunks.is_empty()
		for item in output_chunks:
			if item is Dictionary:
				chunk_box.add_child(_command_output_chunk_label(item))
	var timeline_box: VBoxContainer = row.get("timeline", null)
	if timeline_box != null:
		_clear(timeline_box)
		var timeline: Array = result.get("timeline", [])
		timeline_box.visible = not timeline.is_empty()
		for item in timeline:
			if item is Dictionary:
				timeline_box.add_child(_command_timeline_label(item))
	output_box.visible = result.has("exit_code") or result.has("combined_output") or result.has("stdout") or result.has("stderr") or result.has("runner_kind") or result.has("duration_ms") or result.has("stderr_notice")
	if result.has("runner_kind"):
		output_box.add_child(_command_output_label("Runner", _command_runner_label(str(result.get("runner_kind", "")))))
	if result.has("duration_ms"):
		output_box.add_child(_command_output_label("Duration", "%sms" % str(result.get("duration_ms", ""))))
	if result.has("timeout_enforced") and not bool(result.get("timeout_enforced", true)):
		output_box.add_child(_command_output_label("Timeout enforcement", "Not hard-enforced by the current synchronous runner."))
	if bool(result.get("stderr_merged", false)):
		var stderr_notice := str(result.get("stderr_notice", COMMAND_EXECUTION_OUTPUT_MERGED_NOTICE)).strip_edges()
		output_box.add_child(_command_output_label("stderr handling", stderr_notice))
	if result.has("exit_code"):
		output_box.add_child(_command_output_label("Exit code", str(result.get("exit_code", ""))))
	for key in ["combined_output", "stdout", "stderr"]:
		var result_key := str(key)
		var value := str(result.get(result_key, ""))
		if value.is_empty():
			continue
		var section_title := result_key
		if bool(result.get("%s_truncated" % result_key, false)):
			section_title += " · truncated"
		output_box.add_child(_command_output_label(section_title, value))


func _command_output_chunk_label(item: Dictionary) -> Label:
	var label := Label.new()
	label.name = "CommandTranscriptOutputChunk"
	var stream := str(item.get("stream", "stdout")).strip_edges()
	var text := str(item.get("text", "")).strip_edges()
	var prefix := "stderr" if stream == "stderr" else "stdout"
	if bool(item.get("truncated", false)):
		prefix += " · truncated"
	label.text = "%s › %s" % [prefix, text]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(label, GodexTheme.MUTED, 12)
	return label


func _command_timeline_label(item: Dictionary) -> Label:
	var label := Label.new()
	label.name = "CommandTranscriptTimelineItem"
	var status := _command_transcript_status_text(str(item.get("status", "")))
	var summary := str(item.get("summary", "")).strip_edges()
	if summary.is_empty():
		summary = str(item.get("created_at", "")).strip_edges()
	label.text = "%s  %s" % [status, summary]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(label, GodexTheme.MUTED, 12)
	return label


func _command_output_label(title: String, value: String) -> Label:
	var label := Label.new()
	label.name = "CommandTranscript%s" % title.capitalize().replace(" ", "").replace("_", "").replace("·", "")
	label.text = "%s:\n%s" % [title, value]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	GodexTheme.paint_label(label, GodexTheme.MUTED, 12)
	return label


func _command_runner_label(runner_kind: String) -> String:
	match runner_kind:
		"godot_os_execute_sync":
			return "Godot OS.execute (同步短命令)"
		"custom_callable":
			return "自定义执行器"
		_:
			return runner_kind


func _command_transcript_header_text(command: String, status: String) -> String:
	var title := command.strip_edges()
	if title.length() > 72:
		title = "%s..." % title.left(72).strip_edges()
	return "%s %s" % [_command_transcript_status_text(status), title]


func _show_tool_transcript_row(tool_call_id: String, tool_name: String, status: String, detail: String, expanded: bool = false) -> void:
	if tool_call_id.is_empty():
		return
	var row: Dictionary = _tool_transcript_rows.get(tool_call_id, {})
	if row.is_empty() or not is_instance_valid(row.get("panel", null)):
		row = _create_tool_transcript_row(tool_call_id, tool_name, status, detail, expanded)
	else:
		row["tool_name"] = tool_name
		row["status"] = status
		row["expanded"] = bool(row.get("expanded", expanded))
		var detail_label: Label = row.get("detail", null)
		if detail_label != null:
			detail_label.text = detail
		_refresh_tool_transcript_row(tool_call_id)
	if _conversation_scroll != null:
		_conversation_scroll.call_deferred("set_v_scroll", int(_conversation_scroll.get_v_scroll_bar().max_value))


func _show_tool_batch_transcript_row(item: Dictionary) -> void:
	var batch_id := str(item.get("batch_id", "")).strip_edges()
	if batch_id.is_empty():
		batch_id = "tool_batch_%s" % str(item.get("turn_id", "unbound"))
	var calls: Array = item.get("calls", []) if item.get("calls", []) is Array else []
	var status := str(item.get("status", "completed"))
	var expanded := bool(item.get("expanded", false))
	var row: Dictionary = _tool_transcript_rows.get(batch_id, {})
	if row.is_empty() or not is_instance_valid(row.get("panel", null)):
		row = _create_tool_batch_transcript_row(batch_id, calls, status, expanded)
	else:
		row["status"] = status
		row["calls"] = calls
		row["expanded"] = bool(row.get("expanded", expanded))
		_refresh_tool_batch_transcript_row(batch_id)
	if _conversation_scroll != null:
		_conversation_scroll.call_deferred("set_v_scroll", int(_conversation_scroll.get_v_scroll_bar().max_value))


func _create_tool_batch_transcript_row(batch_id: String, calls: Array, status: String, expanded: bool = false) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "ToolBatchTranscriptRow"
	panel.add_theme_stylebox_override("panel", _transcript_row_style(6))
	var box := VBoxContainer.new()
	box.name = "ToolBatchTranscriptBox"
	box.add_theme_constant_override("separation", 4)
	var header_record := _create_transcript_disclosure_header("ToolBatchTranscriptHeader", ["Terminal", "Console", "Tools", "Node"], _tool_batch_header_text(status, calls.size()), expanded)
	var header: PanelContainer = header_record.get("header", null)
	var body := VBoxContainer.new()
	body.name = "ToolBatchTranscriptBody"
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.visible = expanded
	body.add_theme_constant_override("separation", 5)
	box.add_child(header)
	var body_margin := _transcript_detail_margin(body)
	box.add_child(body_margin)
	panel.add_child(box)
	_messages.add_child(panel)
	var row := {
		"panel": panel,
		"header": header,
		"header_title": header_record.get("title", null),
		"header_arrow": header_record.get("arrow", null),
		"body": body,
		"body_margin": body_margin,
		"status": status,
		"calls": calls,
		"expanded": expanded,
	}
	header.gui_input.connect(_on_tool_batch_transcript_header_input.bind(batch_id))
	_tool_transcript_rows[batch_id] = row
	_refresh_tool_batch_transcript_row(batch_id)
	return row


func _refresh_tool_batch_transcript_row(batch_id: String) -> void:
	var row: Dictionary = _tool_transcript_rows.get(batch_id, {})
	if row.is_empty():
		return
	var calls: Array = row.get("calls", []) if row.get("calls", []) is Array else []
	var status := str(row.get("status", "completed"))
	var expanded := bool(row.get("expanded", false))
	var body: VBoxContainer = row.get("body", null)
	if body != null:
		body.visible = expanded
		_clear(body)
		for call_item in calls:
			if call_item is Dictionary:
				body.add_child(_create_tool_batch_call_row(batch_id, call_item))
	var body_margin: Control = row.get("body_margin", null)
	if body_margin != null:
		body_margin.visible = expanded
	var title: Label = row.get("header_title", null)
	if title != null:
		title.text = _tool_batch_header_text(status, calls.size())
	_refresh_transcript_disclosure_arrow(row)
	_tool_transcript_rows[batch_id] = row


func _create_tool_batch_call_row(batch_id: String, call_item: Dictionary) -> Control:
	var wrapper := VBoxContainer.new()
	wrapper.name = "ToolBatchCall"
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_constant_override("separation", 4)
	var call_id := str(call_item.get("tool_call_id", call_item.get("event_id", ""))).strip_edges()
	var panel := PanelContainer.new()
	panel.name = "ToolBatchCallRow"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	panel.add_theme_stylebox_override("panel", _tool_batch_call_row_style(false))
	var row := HBoxContainer.new()
	row.name = "ToolBatchCallRowContent"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var label := Label.new()
	label.name = "ToolBatchCallLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s %s" % [
		_tool_transcript_status_text(str(call_item.get("status", ""))),
		_tool_batch_call_summary(call_item),
	]
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = str(call_item.get("detail", ""))
	GodexTheme.paint_label(label, GodexTheme.MUTED, 16)
	var arrow := Label.new()
	arrow.name = "ToolBatchCallArrow"
	arrow.text = "›"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.custom_minimum_size = Vector2(20, 20)
	arrow.visible = false
	GodexTheme.paint_label(arrow, GodexTheme.MUTED, 16)
	row.add_child(label)
	row.add_child(arrow)
	panel.add_child(row)
	var detail_card := _create_tool_batch_call_detail(call_item)
	detail_card.name = "ToolBatchCallDetail"
	detail_card.visible = bool(call_item.get("expanded", false))
	wrapper.add_child(panel)
	wrapper.add_child(detail_card)
	panel.mouse_entered.connect(_on_tool_batch_call_hover.bind(panel, label, arrow, true))
	panel.mouse_exited.connect(_on_tool_batch_call_hover.bind(panel, label, arrow, false))
	panel.gui_input.connect(_on_tool_batch_call_input.bind(batch_id, call_id, detail_card, panel, label, arrow))
	return wrapper


func _create_tool_batch_call_detail(call_item: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _tool_batch_call_detail_style())
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	var shell_label := Label.new()
	shell_label.text = "Shell"
	GodexTheme.paint_label(shell_label, GodexTheme.MUTED, 16)
	var detail_label := RichTextLabel.new()
	detail_label.name = "ToolBatchCallDetailText"
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.fit_content = true
	detail_label.scroll_active = false
	detail_label.bbcode_enabled = false
	detail_label.text = _tool_batch_call_detail_text(call_item)
	detail_label.selection_enabled = true
	detail_label.add_theme_font_size_override("normal_font_size", 15)
	detail_label.add_theme_color_override("default_color", GodexTheme.TEXT)
	var status_label := Label.new()
	status_label.name = "ToolBatchCallDetailStatus"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.text = "✓ 成功" if str(call_item.get("status", "")) in ["completed", "succeeded"] else _tool_transcript_status_text(str(call_item.get("status", "")))
	GodexTheme.paint_label(status_label, GodexTheme.MUTED, 16)
	box.add_child(shell_label)
	box.add_child(detail_label)
	box.add_child(status_label)
	margin.add_child(box)
	card.add_child(margin)
	return card


func _tool_batch_call_detail_text(call_item: Dictionary) -> String:
	var summary := _tool_batch_call_summary(call_item)
	var detail := str(call_item.get("detail", "")).strip_edges()
	if detail.is_empty():
		return "$ %s" % summary
	return "$ %s\n\n%s" % [summary, detail]


func _on_tool_batch_call_hover(panel: PanelContainer, label: Label, arrow: Label, hovered: bool) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	panel.add_theme_stylebox_override("panel", _tool_batch_call_row_style(hovered))
	if label != null:
		GodexTheme.paint_label(label, GodexTheme.TEXT if hovered else GodexTheme.MUTED, 16)
	if arrow != null:
		arrow.visible = hovered


func _on_tool_batch_call_input(event: InputEvent, batch_id: String, call_id: String, detail_card: Control, panel: PanelContainer, label: Label, arrow: Label) -> void:
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	if detail_card == null:
		return
	var expanded := not detail_card.visible
	detail_card.visible = expanded
	_on_tool_batch_call_hover(panel, label, arrow, expanded)


func _tool_batch_call_summary(call_item: Dictionary) -> String:
	var name := str(call_item.get("name", "工具调用")).strip_edges()
	var detail := str(call_item.get("detail", "")).strip_edges()
	if detail.is_empty():
		return name
	var lines := detail.split("\n", false)
	for line in lines:
		if line.begins_with("Arguments: "):
			var args := line.replace("Arguments: ", "").strip_edges()
			if args.length() > 96:
				args = "%s..." % args.left(96).strip_edges()
			return "%s %s" % [name, args]
	return name


func _tool_batch_header_text(status: String, count: int) -> String:
	var clean_count := maxi(count, 1)
	var noun := "条命令" if clean_count != 1 else "条命令"
	return "%s %d %s" % [_tool_transcript_status_text(status), clean_count, noun]


func _remove_tool_transcript_row(tool_call_id: String) -> void:
	var row: Dictionary = _tool_transcript_rows.get(tool_call_id, {})
	if row.is_empty():
		return
	var panel: Node = row.get("panel", null)
	if panel != null and is_instance_valid(panel):
		panel.queue_free()
	_tool_transcript_rows.erase(tool_call_id)


func _clear_partial_tool_transcript_rows() -> void:
	for key in _tool_transcript_rows.keys():
		var tool_call_id := str(key)
		if tool_call_id.begins_with("partial_"):
			_remove_tool_transcript_row(tool_call_id)


func _update_tool_transcript_row(tool_call_id: String, status: String, detail: String) -> void:
	if tool_call_id.is_empty():
		return
	var tool_name := _tool_name_for_call(tool_call_id)
	_show_tool_transcript_row(tool_call_id, tool_name, status, detail, false)


func _toggle_tool_transcript_row(tool_call_id: String) -> void:
	var row: Dictionary = _tool_transcript_rows.get(tool_call_id, {})
	if row.is_empty():
		return
	row["expanded"] = not bool(row.get("expanded", false))
	_tool_transcript_rows[tool_call_id] = row
	if _state != null:
		_state.call("set_tool_call_expanded", tool_call_id, bool(row.get("expanded", false)))
	_refresh_tool_transcript_row(tool_call_id)


func _refresh_tool_transcript_row(tool_call_id: String) -> void:
	var row: Dictionary = _tool_transcript_rows.get(tool_call_id, {})
	if row.is_empty():
		return
	var expanded := bool(row.get("expanded", false))
	var body: Control = row.get("body", null)
	if body != null:
		body.visible = expanded
	var body_margin: Control = row.get("body_margin", null)
	if body_margin != null:
		body_margin.visible = expanded
	var title: Label = row.get("header_title", null)
	if title != null:
		title.text = _tool_transcript_header_text(str(row.get("tool_name", "工具调用")), str(row.get("status", "")))
	_refresh_transcript_disclosure_arrow(row)
	_tool_transcript_rows[tool_call_id] = row


func _tool_transcript_header_text(tool_name: String, status: String) -> String:
	return "%s %s" % [_tool_transcript_status_text(status), tool_name]


func _create_transcript_disclosure_header(name: String, icon_candidates: Array, title_text: String, expanded: bool) -> Dictionary:
	var header := PanelContainer.new()
	header.name = name
	header.custom_minimum_size = Vector2(0, 36)
	header.mouse_filter = Control.MOUSE_FILTER_STOP
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_stylebox_override("panel", _transcript_disclosure_button_style(false, false))
	var row := HBoxContainer.new()
	row.name = "%sContent" % name
	row.add_theme_constant_override("separation", 8)
	var icon := TextureRect.new()
	icon.name = "%sIcon" % name
	icon.custom_minimum_size = Vector2(20, 20)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _editor_icon_texture(icon_candidates)
	icon.modulate = GodexTheme.MUTED
	row.add_child(icon)
	var title := Label.new()
	title.name = "%sTitle" % name
	title.text = title_text
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	GodexTheme.paint_label(title, GodexTheme.MUTED, 16)
	row.add_child(title)
	var arrow := Label.new()
	arrow.name = "%sArrow" % name
	arrow.custom_minimum_size = Vector2(16, 0)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	GodexTheme.paint_label(arrow, GodexTheme.MUTED, 16)
	row.add_child(arrow)
	header.add_child(row)
	header.set_meta("expanded", expanded)
	header.set_meta("hovered", false)
	header.mouse_entered.connect(_on_transcript_disclosure_hover.bind(header, true))
	header.mouse_exited.connect(_on_transcript_disclosure_hover.bind(header, false))
	_refresh_transcript_disclosure_header(header, title, arrow)
	return {"header": header, "title": title, "arrow": arrow}


func _on_transcript_disclosure_hover(header: PanelContainer, hovered: bool) -> void:
	if header == null or not is_instance_valid(header):
		return
	header.set_meta("hovered", hovered)
	var title := header.find_child("%sTitle" % header.name, true, false) as Label
	var arrow := header.find_child("%sArrow" % header.name, true, false) as Label
	_refresh_transcript_disclosure_header(header, title, arrow)


func _refresh_transcript_disclosure_header(header: PanelContainer, title: Label, arrow: Label) -> void:
	if header == null:
		return
	var expanded := bool(header.get_meta("expanded", false))
	var hovered := bool(header.get_meta("hovered", false))
	header.add_theme_stylebox_override("panel", _transcript_disclosure_button_style(hovered, false))
	if title != null:
		GodexTheme.paint_label(title, GodexTheme.TEXT if hovered else GodexTheme.MUTED, 16)
	if arrow != null:
		arrow.text = "⌄" if expanded else "›"
		arrow.visible = expanded or hovered


func _refresh_transcript_disclosure_arrow(row: Dictionary) -> void:
	var header: PanelContainer = row.get("header", null)
	var title: Label = row.get("header_title", null)
	var arrow: Label = row.get("header_arrow", null)
	if header != null:
		header.set_meta("expanded", bool(row.get("expanded", false)))
	_refresh_transcript_disclosure_header(header, title, arrow)


func _on_tool_transcript_header_input(event: InputEvent, tool_call_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_tool_transcript_row(tool_call_id)


func _on_tool_batch_transcript_header_input(event: InputEvent, batch_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var row: Dictionary = _tool_transcript_rows.get(batch_id, {})
		if row.is_empty():
			return
		row["expanded"] = not bool(row.get("expanded", false))
		_tool_transcript_rows[batch_id] = row
		if _state != null:
			_state.call("set_tool_batch_expanded", batch_id, bool(row.get("expanded", false)))
		_refresh_tool_batch_transcript_row(batch_id)


func _on_command_transcript_header_input(event: InputEvent, command_id: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_command_transcript_row(command_id)


func _transcript_detail_margin(content: Control) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.name = "%sMargin" % content.name
	margin.visible = content.visible
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_child(content)
	return margin


func _paint_transcript_disclosure_button(button: Button) -> void:
	button.flat = true
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", GodexTheme.MUTED)
	button.add_theme_color_override("font_hover_color", GodexTheme.TEXT)
	button.add_theme_stylebox_override("normal", _transcript_disclosure_button_style(false, false))
	button.add_theme_stylebox_override("hover", _transcript_disclosure_button_style(true, false))
	button.add_theme_stylebox_override("pressed", _transcript_disclosure_button_style(true, true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _transcript_disclosure_button_style(hovered: bool, pressed: bool) -> StyleBoxFlat:
	var color := Color(0, 0, 0, 0)
	if pressed:
		color = Color(0.22, 0.23, 0.24, 0.85)
	elif hovered:
		color = Color(0.18, 0.19, 0.20, 0.72)
	var style := GodexTheme.panel_style(color, 6, Color(0, 0, 0, 0))
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	style.set_border_width_all(0)
	return style


func _tool_batch_call_row_style(hovered: bool) -> StyleBoxFlat:
	var color := Color(0, 0, 0, 0)
	if hovered:
		color = Color(0.18, 0.19, 0.20, 0.82)
	var style := GodexTheme.panel_style(color, 6, Color(0, 0, 0, 0))
	style.content_margin_left = 4
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.set_border_width_all(0)
	return style


func _tool_batch_call_detail_style() -> StyleBoxFlat:
	var style := GodexTheme.panel_style(Color(0.16, 0.16, 0.16), 8, Color(0.23, 0.24, 0.25))
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _partial_tool_transcript_detail(partial: Dictionary) -> String:
	var parts: Array[String] = ["ID: %s" % str(partial.get("id", ""))]
	var arguments := str(partial.get("arguments", "")).strip_edges()
	if not arguments.is_empty():
		if arguments.length() > 480:
			arguments = "%s..." % arguments.left(480).strip_edges()
		parts.append("Partial arguments: %s" % arguments)
	return "\n".join(parts)


func _tool_name_for_call(tool_call_id: String) -> String:
	for event in _state.call("active_model_events"):
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) == tool_call_id:
			return str(data.get("name", "工具调用"))
	return "工具调用"


func _tool_transcript_detail(tool_call_id: String, request: Dictionary = {}, parsed: Dictionary = {}) -> String:
	var parts: Array[String] = ["ID: %s" % tool_call_id]
	if not request.is_empty():
		parts.append("Endpoint: %s" % str(request.get("endpoint", "")))
		parts.append("Method: %s" % str(request.get("method", "")))
	if not parsed.is_empty():
		var message := str(parsed.get("message", parsed.get("error", ""))).strip_edges()
		if message.is_empty():
			message = str(parsed.get("summary", "")).strip_edges()
		if message.length() > 360:
			message = "%s..." % message.left(360).strip_edges()
		if not message.is_empty():
			parts.append("Result: %s" % message)
	return "\n".join(parts)


func _on_new_chat() -> void:
	_show_view("chat")
	_state.call("new_session")
	_render_active_messages()
	_save_sessions()
	_apply_model(_state.call("to_model"))
	_composer.grab_focus()


func _on_thread_selected(thread_id: String, action: String) -> void:
	if thread_id.is_empty():
		return
	_state.call("select_thread", thread_id)
	_render_active_messages()
	match action:
		"chat":
			_show_view("chat")
		"inspect_mcp":
			var result: Dictionary = _agent.call("inspect_mcp_connection")
			_state.call("append_model_event", "session_action", {
				"status": "completed",
				"action": "inspect_mcp",
				"summary": str(result.get("summary", "MCP 状态已更新。")),
				"source": "thread_action",
			})
		"show_runtime_plan":
			var runtime_plan: Dictionary = _agent.call("build_runtime_plan")
			_state.call("append_model_event", "session_action", {
				"status": "completed",
				"action": "show_runtime_plan",
				"summary": str(runtime_plan.get("summary", "")),
				"source": "thread_action",
			})
		"show_ui_plan":
			var ui_plan: Dictionary = _agent.call("build_ui_plan")
			_state.call("append_model_event", "session_action", {
				"status": "completed",
				"action": "show_ui_plan",
				"summary": str(ui_plan.get("summary", "")),
				"source": "thread_action",
			})
		_:
			_state.call("append_model_event", "session_action", {
				"status": "skipped",
				"action": action,
				"source": "thread_action",
			})
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _fork_thread(thread_id: String) -> void:
	if thread_id.is_empty():
		return
	_state.call("select_thread", thread_id)
	var fork: Dictionary = _state.call("fork_active_session")
	_state.call("append_model_event", "session_action", {
		"status": "failed" if fork.is_empty() else "completed",
		"action": "fork",
		"title": str(fork.get("title", "")),
		"source": "thread_menu",
	})
	_show_view("chat")
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _archive_thread(thread_id: String) -> void:
	if thread_id.is_empty():
		return
	_state.call("select_thread", thread_id)
	var archived: Dictionary = _state.call("archive_active_session")
	_state.call("append_model_event", "session_action", {
		"status": "failed" if archived.is_empty() else "completed",
		"action": "archive",
		"title": str(archived.get("title", "")),
		"source": "thread_menu",
	})
	if not archived.is_empty():
		_show_thread_archive_notice()
	_show_view("chat")
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _show_thread_archive_notice() -> void:
	_ensure_thread_archive_notice()
	if _thread_archive_notice == null:
		return
	_thread_archive_notice.visible = true
	_thread_archive_notice.move_to_front()
	var target_size := Vector2(330, 38)
	var viewport_width := _root.size.x if _root != null else target_size.x
	var x := max(8.0, (viewport_width - target_size.x) * 0.5)
	_set_popover_rect(_thread_archive_notice, Vector2(x, 18), target_size)
	if _thread_archive_notice_timer != null:
		_thread_archive_notice_timer.start()


func _hide_thread_archive_notice() -> void:
	if _thread_archive_notice != null:
		_thread_archive_notice.visible = false


func _open_archived_settings_from_notice() -> void:
	_hide_thread_archive_notice()
	_show_archived()


func _handle_slash_command(prompt: String) -> bool:
	var result: Dictionary = _state.call("execute_slash_command", prompt)
	if not bool(result.get("handled", false)):
		return false
	_state.call("append_model_event", "slash_command", {
		"status": "completed" if bool(result.get("success", false)) else "failed",
		"command": str(result.get("command", "")),
		"message": str(result.get("message", "")),
		"source": "composer",
	})
	var slash_data: Dictionary = result.get("data", {})
	if str(result.get("command", "")) in ["resume", "open", "fork", "branch", "archive", "new", "newchat"]:
		_render_active_messages()
	if str(slash_data.get("view", "")) == "mcp":
		_show_mcp()
	else:
		_show_view("chat")
	_save_sessions()
	_apply_model(_state.call("to_model"))
	return true


func _show_search() -> void:
	_show_view("search")
	_rebuild_search_results(_state.call("to_model"))


func _show_plugins() -> void:
	_show_view("plugins")


func _show_mcp() -> void:
	_show_view("mcp")
	_start_mcp_tool_discovery()
	_rebuild_mcp_view(_state.call("to_model"))


func _show_automation() -> void:
	_show_view("automation")
	_rebuild_automation_view(_state.call("to_model"))


func _show_archived() -> void:
	_active_settings_category = "archived"
	if _settings_search != null and not _settings_search.text.is_empty():
		_settings_search.text = ""
	_show_view("settings")
	_apply_settings_category_visibility()
	_rebuild_archived_view()


func _show_settings() -> void:
	_show_view("settings")
	var settings_panel := _root.get_node_or_null(SETTINGS_PANEL_PATH) if _root != null else null
	if settings_panel != null:
		settings_panel.move_to_front()


func _hide_settings() -> void:
	_show_view("chat")


func _toggle_layout_menu() -> void:
	if _layout_menu_panel == null:
		return
	if _layout_menu_panel.visible:
		_hide_layout_menu()
	else:
		_show_layout_menu()


func _show_layout_menu() -> void:
	if _layout_menu_panel == null:
		return
	_hide_composer_popovers_except()
	_rebuild_layout_menu()
	_layout_menu_panel.visible = true
	_position_visible_layout_menu()
	call_deferred("_position_visible_layout_menu")
	_apply_layout_state()


func _hide_layout_menu() -> void:
	if _layout_menu_panel != null:
		_layout_menu_panel.visible = false
	_paint_layout_menu_button()


func _layout_menu_open_files() -> void:
	_hide_layout_menu()
	_show_search()
	if _search_input != null and _search_input.is_inside_tree():
		_search_input.grab_focus()


func _layout_menu_open_side_chat() -> void:
	_hide_layout_menu()
	_right_inspector_visible = true
	_show_view("chat")


func _layout_menu_open_terminal() -> void:
	_hide_layout_menu()
	_bottom_panel_visible = true
	_show_view("chat")


func _layout_menu_add_recommended_context(title: String) -> void:
	_hide_layout_menu()
	if title.strip_edges().is_empty():
		return
	_add_persisted_message("assistant", "已将 %s 加入后续上下文候选。" % title)
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _toggle_change_review_expanded() -> void:
	var summary: Dictionary = _state.get("change_review_summary")
	if summary.is_empty():
		return
	var expanded := not bool(summary.get("expanded", false))
	_state.call("set_change_review_expanded", expanded)
	_apply_model(_state.call("to_model"))


func _open_change_review() -> void:
	var summary: Dictionary = _state.call("change_review_preview")
	if summary.is_empty():
		_add_persisted_message("assistant", "当前没有待审查的文件变更。")
	else:
		_add_persisted_message("assistant", "%d 个文件已更改：+%d -%d。审查面板将在后续版本接入真实 diff。" % [
			int(summary.get("file_count", 0)),
			int(summary.get("added", 0)),
			int(summary.get("removed", 0)),
		])
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _toggle_bottom_panel() -> void:
	_hide_layout_menu()
	_bottom_panel_visible = not _bottom_panel_visible
	_apply_layout_state()


func _toggle_right_inspector() -> void:
	_hide_layout_menu()
	_right_inspector_visible = not _right_inspector_visible
	_apply_layout_state()


func _refresh_plugin_ui() -> void:
	if _plugin == null or not _plugin.has_method("rebuild_main_screen"):
		_add_persisted_message("assistant", "当前 Godex 插件实例不支持界面刷新。")
		_apply_model(_state.call("to_model"))
		return
	_save_sessions()
	var result: Dictionary = _plugin.call("rebuild_main_screen")
	if not bool(result.get("success", false)):
		push_error("[Godex] UI refresh failed.")


func _show_view(view: String) -> void:
	if view != _active_view:
		_hide_layout_menu()
	if view != "chat":
		_hide_composer_popovers_except()
		_hide_thread_action_menu()
		_hide_thread_rename_panel()
	_active_view = view
	_active_sidebar_surface = "thread" if view == "chat" else view
	if _active_sidebar_surface != "thread":
		_clear_thread_hover_states()
	if _welcome_panel != null:
		_welcome_panel.visible = view == "chat"
	if _conversation_scroll != null:
		_conversation_scroll.visible = view == "chat"
	if _search_panel != null:
		_search_panel.visible = view == "search"
	if _plugins_panel != null:
		_plugins_panel.visible = view == "plugins"
	if _mcp_panel != null:
		_mcp_panel.visible = view == "mcp"
	if _automation_panel != null:
		_automation_panel.visible = view == "automation"
	if _archived_panel != null:
		_archived_panel.visible = view == "settings" and _active_settings_category == "archived"
	var settings_panel := _root.get_node_or_null("%s/Body/MainCenter/SettingsPanel" % MAIN) if _root != null else null
	if settings_panel != null:
		settings_panel.visible = view == "settings"
	_apply_layout_state()
	_rebuild_threads(_state.call("to_model").get("threads", []))
	_refresh_nav_state()


func _start_mcp_tool_discovery() -> void:
	if _mcp_tools_request == null or _mcp_tools_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var discovery: Dictionary = _agent.call("build_mcp_discovery_request")
	var request: Dictionary = discovery.get("request", {})
	var body := JSON.stringify(request.get("body", {}))
	_state.call("update_mcp_discovery_status", "request_starting")
	if _active_view == "mcp":
		_rebuild_mcp_view(_state.call("to_model"))
	if _active_view == "settings":
		_apply_settings_model(_state.call("to_model"))
	var err := _mcp_tools_request.request(
		str(request.get("endpoint", "")),
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		body
	)
	if err != OK:
		_agent.call("handle_mcp_tools_list_response", JSON.stringify({"error": {"code": "request_failed", "message": "HTTPRequest failed: %d" % err}}))
	else:
		_state.call("update_mcp_discovery_status", "request_sent")
	if _active_view == "mcp":
		_rebuild_mcp_view(_state.call("to_model"))
	if _active_view == "settings":
		_apply_settings_model(_state.call("to_model"))
	_state.call("append_model_event", "mcp_tools_transport", {
		"status": "request_started" if err == OK else "request_failed",
		"error": str(err),
		"endpoint": str(request.get("endpoint", "")),
		"body_length": body.length(),
	})


func _on_mcp_tools_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var text := body.get_string_from_utf8()
	if _result != HTTPRequest.RESULT_SUCCESS:
		text = JSON.stringify({"error": {"code": "transport_%d" % _result, "message": "HTTPRequest transport result: %d" % _result}})
	elif text.strip_edges().is_empty():
		text = JSON.stringify({"error": {"code": "empty_response", "message": "MCP tools/list returned an empty response."}})
	if response_code < 200 or response_code >= 300:
		text = JSON.stringify({"error": {"code": "http_%d" % response_code, "message": text}})
	_agent.call("handle_mcp_tools_list_response", text)
	if _active_view == "mcp":
		_rebuild_mcp_view(_state.call("to_model"))
	if _active_view == "settings":
		_apply_settings_model(_state.call("to_model"))


func _inject_probe_tool_call() -> void:
	var result: Dictionary = _agent.call("inject_mcp_context_probe", "summary", 20)
	if bool(result.get("success", false)):
		var tool_call: Dictionary = result.get("tool_call", {})
		_add_persisted_message("assistant", "已创建本地 MCP 上下文探针：%s。可在聊天信息流、外部工具来源和自动化面板中跟踪。" % str(tool_call.get("id", "")))
	else:
		_add_persisted_message("assistant", "本地 MCP 上下文探针创建失败。")
	_show_view("chat")
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _replay_model_response() -> void:
	var result: Dictionary = _agent.call("inject_model_response_replay")
	if bool(result.get("success", false)):
		var tool_count := int(result.get("tool_call_records", []).size())
		_add_persisted_message("assistant", "已回放本地模型响应，生成 %d 个待处理工具调用。未发送网络请求。" % tool_count)
		_advance_agent_loop_after_model_response(tool_count)
	else:
		_add_persisted_message("assistant", "本地模型回放失败：%s。" % str(result.get("message", result.get("error", "unknown"))))
		_state.call("stop_agent_loop", "local_model_replay_failed")
	_show_view("chat")
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _run_provider_probe() -> void:
	_apply_provider_fields_to_state()
	if _provider_probe_request == null:
		_add_persisted_message("assistant", "Provider 探针不可用：HTTPRequest 节点未初始化。")
		_apply_model(_state.call("to_model"))
		return
	if _provider_probe_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_add_persisted_message("assistant", "Provider 探针正在运行，请等待当前探针结束。")
		_apply_model(_state.call("to_model"))
		return
	var api_config: Dictionary = _state.call("api_config_snapshot")
	if not bool(api_config.get("has_api_key", false)):
		_state.call("append_model_event", "openai_transport", {
			"status": "provider_probe_blocked",
			"stage": "provider_probe",
			"source": "provider_probe",
			"endpoint": str(api_config.get("endpoint", "")),
			"api_mode": str(api_config.get("api_mode", _state.api_mode)),
			"model": str(api_config.get("model", _state.model)),
			"key_source": str(api_config.get("key_source", "missing")),
			"error": "missing_api_key",
			"message": "缺少 API Key，Provider 探针未发送网络请求。",
		})
		_add_persisted_message("assistant", "Provider 探针未发送：缺少 API Key。")
		_apply_model(_state.call("to_model"))
		return
	var payload := _provider_probe_payload(str(api_config.get("api_mode", _state.api_mode)), str(api_config.get("model", _state.model)))
	var request := {
		"source": "provider_probe",
		"stage": "provider_probe",
		"endpoint": str(api_config.get("endpoint", "")),
		"api_mode": str(api_config.get("api_mode", _state.api_mode)),
		"model": str(api_config.get("model", _state.model)),
		"key_source": str(api_config.get("key_source", "missing")),
		"payload": payload,
	}
	var body := JSON.stringify(payload)
	_active_provider_probe_request = request.duplicate(true)
	_state.call("append_model_event", "openai_transport", {
		"status": "provider_probe_starting",
		"stage": "provider_probe",
		"source": "provider_probe",
		"endpoint": str(request.get("endpoint", "")),
		"api_mode": str(request.get("api_mode", "")),
		"model": str(request.get("model", "")),
		"key_source": str(request.get("key_source", "")),
		"body_length": body.length(),
	})
	var err := _provider_probe_request.request(
		str(request.get("endpoint", "")),
		api_config.get("headers", PackedStringArray()),
		HTTPClient.METHOD_POST,
		body
	)
	if err != OK:
		_active_provider_probe_request = {}
		_state.call("append_model_event", "openai_transport", {
			"status": "provider_probe_failed",
			"stage": "provider_probe",
			"source": "provider_probe",
			"endpoint": str(request.get("endpoint", "")),
			"api_mode": str(request.get("api_mode", "")),
			"model": str(request.get("model", "")),
			"error": "request_start_%d" % err,
		})
		_add_persisted_message("assistant", "Provider 探针启动失败：%d。" % err)
	_apply_model(_state.call("to_model"))


func _provider_probe_payload(api_mode: String, probe_model: String) -> Dictionary:
	if api_mode == "chat_completions":
		var chat_payload := OpenAIRequestBuilder.build_chat_completions_payload(probe_model, "Reply with exactly: pong", [{"role": "user", "content": "ping"}], [], {"reasoning_effort": str(_state.reasoning_effort)})
		chat_payload["max_tokens"] = 16
		chat_payload.erase("stream")
		return chat_payload
	var responses_payload := OpenAIRequestBuilder.build_responses_payload(probe_model, "Reply with exactly: pong", [{"role": "user", "content": "ping"}], [], {"reasoning_effort": str(_state.reasoning_effort)})
	responses_payload["max_output_tokens"] = 16
	responses_payload.erase("stream")
	return responses_payload


func _on_provider_probe_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var request := _active_provider_probe_request.duplicate(true)
	_active_provider_probe_request = {}
	var api_mode := str(request.get("api_mode", _state.api_mode))
	var text := body.get_string_from_utf8()
	var parsed: Dictionary = _agent.call("handle_model_http_result", api_mode, response_code, text, {"source": "provider_probe"})
	var success := result == HTTPRequest.RESULT_SUCCESS and bool(parsed.get("success", false))
	var message := str(parsed.get("text", "")).strip_edges()
	if message.is_empty():
		message = str(parsed.get("message", parsed.get("error", ""))).strip_edges()
	_state.call("append_model_event", "openai_transport", {
		"status": "provider_probe_completed" if success else "provider_probe_failed",
		"stage": "provider_probe",
		"source": "provider_probe",
		"endpoint": str(request.get("endpoint", "")),
		"api_mode": api_mode,
		"model": str(request.get("model", "")),
		"key_source": str(request.get("key_source", "")),
		"result": result,
		"status_code": response_code,
		"success": success,
		"message": message,
		"body_preview": _openai_http_error_body_preview(text),
		"body_length": text.length(),
	})
	if success:
		_add_persisted_message("assistant", "Provider 探针成功：HTTP %d · %s · %s。" % [response_code, api_mode, message.left(80)])
	else:
		_add_persisted_message("assistant", "Provider 探针失败：HTTP %d · result %d · %s。" % [response_code, result, message.left(120)])
	_apply_model(_state.call("to_model"))


func _execute_next_tool_call() -> void:
	_try_start_next_tool_call(true)


func _request_next_command_approval() -> void:
	var result: Dictionary = _state.call("request_next_command_run_approval")
	if bool(result.get("success", false)):
		_add_persisted_message("assistant", "已创建命令审批：%s。" % str(result.get("command_id", "")))
	else:
		_add_persisted_message("assistant", str(result.get("message", "没有等待审批的命令请求。")))
	_save_sessions()
	_refresh_command_action_model()


func _execute_next_approved_command() -> void:
	var result: Dictionary = _state.call("execute_next_approved_command_run", Callable(self, "_run_local_command"))
	if str(result.get("error", "")) == "runner_unavailable":
		_add_persisted_message("assistant", "命令执行器尚未接入，已记录 runner unavailable：%s。" % str(result.get("command_id", "")))
	elif bool(result.get("success", false)):
		_add_persisted_message("assistant", "命令执行完成：%s。" % str(result.get("command_id", "")))
	else:
		_add_persisted_message("assistant", str(result.get("message", "没有已批准且等待执行的命令。")))
	_save_sessions()
	_refresh_command_action_model()


func _run_local_command(command_run: Dictionary) -> Dictionary:
	var shell_name := str(command_run.get("shell", "PowerShell"))
	var command := str(command_run.get("command", ""))
	var target_cwd := _local_command_working_directory(str(command_run.get("working_directory", "")))
	var args := _local_command_shell_args(shell_name, command, target_cwd)
	if args.is_empty():
		return {
			"exit_code": -1,
			"stderr": "Unsupported command shell: %s" % shell_name,
			"combined_output": "Unsupported command shell: %s" % shell_name,
			"runner_kind": "godot_os_execute_sync",
			"timeout_enforced": false,
			"timed_out": false,
		}
	var started_at_msec := Time.get_ticks_msec()
	var output: Array = []
	var executable := str(args[0])
	var arguments: PackedStringArray = []
	for index in range(1, args.size()):
		arguments.append(str(args[index]))
	var exit_code := OS.execute(executable, arguments, output, true, true)
	var stdout := "\n".join(output)
	var duration_ms := max(0, Time.get_ticks_msec() - started_at_msec)
	var result := {
		"exit_code": exit_code,
		"stdout": stdout,
		"combined_output": stdout,
		"runner_kind": "godot_os_execute_sync",
		"duration_ms": duration_ms,
		"stderr_merged": true,
		"stderr_notice": COMMAND_EXECUTION_OUTPUT_MERGED_NOTICE,
		"timeout_enforced": false,
		"timed_out": false,
	}
	if exit_code == -1:
		result["stderr"] = "Command process failed to start."
		result["combined_output"] = str(result.get("stderr", ""))
	return result


func _local_command_shell_args(shell_name: String, command: String, working_directory: String = "") -> Array[String]:
	var wrapped_command := _local_command_with_working_directory(shell_name, command, working_directory)
	match shell_name:
		"PowerShell":
			return ["powershell.exe", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", wrapped_command]
		"pwsh":
			return ["pwsh", "-NoLogo", "-NoProfile", "-NonInteractive", "-Command", wrapped_command]
		"cmd":
			return ["cmd.exe", "/D", "/C", wrapped_command]
		_:
			return []


func _local_command_with_working_directory(shell_name: String, command: String, working_directory: String) -> String:
	if working_directory.strip_edges().is_empty():
		return command
	match shell_name:
		"PowerShell", "pwsh":
			return "Set-Location -LiteralPath '%s'; %s" % [_powershell_single_quote(working_directory), command]
		"cmd":
			return "cd /d \"%s\" && %s" % [working_directory.replace("\"", "\"\""), command]
		_:
			return command


func _powershell_single_quote(value: String) -> String:
	return value.replace("'", "''")


func _local_command_working_directory(value: String) -> String:
	var clean := value.strip_edges()
	if clean.is_empty() or clean == "res://":
		return ProjectSettings.globalize_path("res://")
	if clean.begins_with("res://"):
		return ProjectSettings.globalize_path(clean)
	return ""


func _cancel_next_command_run() -> void:
	var command_run: Dictionary = _state.call("next_cancellable_command_run")
	if command_run.is_empty():
		_add_persisted_message("assistant", "当前没有可取消命令。")
	else:
		var command_id := str(command_run.get("id", ""))
		var result: Dictionary = _state.call("cancel_command_run", command_id)
		if bool(result.get("success", false)):
			_add_persisted_message("assistant", "已取消命令：%s。" % command_id)
		else:
			_add_persisted_message("assistant", "命令无法取消：%s。" % str(result.get("error", "unknown")))
	_save_sessions()
	_refresh_command_action_model()


func _cancel_next_subagent_task() -> void:
	var task: Dictionary = _state.call("next_cancellable_subagent_task")
	if task.is_empty():
		_add_persisted_message("assistant", "当前没有可取消子智能体任务。")
	else:
		var task_id := str(task.get("id", ""))
		var result: Dictionary = _state.call("cancel_subagent_task", task_id, "automation")
		if result.is_empty():
			_add_persisted_message("assistant", "子智能体任务无法取消：%s。" % task_id)
		else:
			_add_persisted_message("assistant", "已取消子智能体任务：%s。" % task_id)
	_save_sessions()
	_refresh_command_action_model()


func _handoff_next_subagent_result() -> void:
	var task: Dictionary = _state.call("next_handoffable_subagent_task")
	if task.is_empty():
		_add_persisted_message("assistant", "当前没有可交接子智能体结果。")
	else:
		var task_id := str(task.get("id", ""))
		var summary := str(task.get("result", task.get("summary", ""))).strip_edges()
		var result: Dictionary = _state.call("handoff_subagent_task_result", task_id, summary, "automation")
		if result.is_empty():
			_add_persisted_message("assistant", "子智能体结果无法交接：%s。" % task_id)
		else:
			_add_persisted_message("assistant", "已交接子智能体结果：%s。" % task_id)
	_save_sessions()
	_refresh_command_action_model()


func _refresh_command_action_model() -> void:
	var model: Dictionary = _state.call("to_model")
	if _root != null and _main_title != null:
		_apply_model(model)
	elif _automation_list != null:
		_rebuild_automation_view(model)


func _advance_agent_loop_after_model_response(tool_call_count: int) -> void:
	_state.call("record_agent_loop_step", "model_tool_calls", "%d tool call(s)" % tool_call_count)
	if not _try_start_next_tool_call(false):
		_continue_after_auto_completed_tool_calls()
		_apply_model(_state.call("to_model"))


func _maybe_send_next_queued_user_message() -> bool:
	if _state == null or _agent == null:
		return false
	if str(_state.get("agent_loop_status")) == "running":
		return false
	if _is_openai_busy():
		return false
	if _composer != null and not _composer.text.strip_edges().is_empty():
		return false
	var record: Dictionary = _state.call("next_queued_user_message")
	if record.is_empty():
		return false
	var action := str(record.get("action", "plain"))
	var api_config: Dictionary = _state.call("api_config_snapshot")
	if action not in ["run_shell", "parse_slash"] and not bool(api_config.get("has_api_key", false)):
		return false
	var prompt := str(record.get("text", "")).strip_edges()
	if prompt.is_empty():
		return false
	return _send_prompt_text(prompt, "queued_user_message", str(record.get("id", "")))


func _try_start_next_tool_call(report_empty: bool) -> bool:
	if _mcp_tool_call_request == null or _mcp_tool_call_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		if report_empty:
			_add_persisted_message("assistant", "已有 MCP 工具调用正在执行。")
			_apply_model(_state.call("to_model"))
		return false
	if str(_state.get("agent_loop_status")) != "running":
		_state.call("begin_agent_loop", "manual_tool_execution" if report_empty else "auto_tool_execution")
	var dispatch: Dictionary = _agent.call("dispatch_next_tool_call")
	if not bool(dispatch.get("success", false)):
		if bool(dispatch.get("blocked", false)):
			_state.call("stop_agent_loop", "approval_required")
			if report_empty:
				_add_persisted_message("assistant", "工具调用需要先审批。")
				_apply_model(_state.call("to_model"))
			return false
		dispatch = _dispatch_existing_ready_tool_call()
		if not bool(dispatch.get("success", false)):
			if report_empty:
				_add_persisted_message("assistant", "当前没有可执行的 MCP 工具调用。")
				_apply_model(_state.call("to_model"))
			return false
	_state.call("record_agent_loop_step", "mcp_tool_dispatch", str(dispatch.get("tool", dispatch.get("tool_call_id", ""))))
	if str(dispatch.get("tool", "")) == "exec_command":
		call_deferred("_start_exec_command_tool_call", str(dispatch.get("tool_call_id", "")), str(dispatch.get("command_id", "")))
		return true
	_start_mcp_tool_call_transport(str(dispatch.get("tool_call_id", "")))
	return true


func _continue_after_auto_completed_tool_calls() -> bool:
	var completed_tool_call_id := _latest_completed_tool_call_id()
	if completed_tool_call_id.is_empty():
		return false
	if str(_state.get("agent_loop_status")) != "running":
		return false
	call_deferred("_continue_after_tool_result", completed_tool_call_id)
	return true


func _latest_completed_tool_call_id() -> String:
	var events: Array = _state.call("active_model_events")
	for index in range(events.size() - 1, -1, -1):
		var event = events[index]
		if not (event is Dictionary) or str((event as Dictionary).get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = (event as Dictionary).get("data", {})
		if str(data.get("status", "")) in ["succeeded", "failed", "completed"]:
			return str(data.get("id", ""))
	return ""


func _dispatch_existing_ready_tool_call() -> Dictionary:
	for event in _state.call("active_model_events"):
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("status", "")) == "dispatch_ready":
			return {
				"success": true,
				"tool_call_id": str(data.get("id", "")),
				"request": data.get("result", {}).get("request", {}),
			}
	return {"success": false}


func _start_mcp_tool_call_transport(tool_call_id: String) -> void:
	var execution: Dictionary = _agent.call("begin_tool_call_execution", tool_call_id)
	if not bool(execution.get("success", false)):
		_add_persisted_message("assistant", "工具调用执行准备失败：%s。" % str(execution.get("error", "")))
		_apply_model(_state.call("to_model"))
		return
	var request: Dictionary = execution.get("request", {})
	var body := JSON.stringify(request.get("body", {}))
	_render_active_messages()
	_active_tool_call_id = tool_call_id
	var err := _mcp_tool_call_request.request(
		str(request.get("endpoint", "")),
		PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST,
		body
	)
	if err != OK:
		var failed: Dictionary = _agent.call("handle_mcp_tool_call_response", tool_call_id, JSON.stringify({"error": {"code": "request_failed", "message": "HTTPRequest failed: %d" % err}}))
		_render_active_messages()
		_active_tool_call_id = ""
	else:
		_state.call("append_model_event", "mcp_tool_transport", {
			"status": "request_sent",
			"tool_call_id": tool_call_id,
			"endpoint": str(request.get("endpoint", "")),
			"body_length": body.length(),
		})
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _start_exec_command_tool_call(tool_call_id: String, command_id: String) -> void:
	if tool_call_id.is_empty() or command_id.is_empty():
		return
	_state.call("update_tool_call_status", tool_call_id, "executing", {
		"command_id": command_id,
		"message": "Executing approved exec_command.",
	})
	_render_active_messages()
	var execution: Dictionary = _state.call("execute_command_run_with_runner", command_id, Callable(self, "_run_local_command"))
	var parsed: Dictionary = _agent.call("handle_exec_command_tool_result", tool_call_id, execution)
	_render_active_messages()
	_continue_after_tool_result(tool_call_id)
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _on_mcp_tool_call_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var tool_call_id := _active_tool_call_id
	_active_tool_call_id = ""
	if tool_call_id.is_empty():
		return
	var text := body.get_string_from_utf8()
	if _result != HTTPRequest.RESULT_SUCCESS:
		text = JSON.stringify({"error": {"code": "transport_%d" % _result, "message": "HTTPRequest transport result: %d" % _result}})
	elif text.strip_edges().is_empty():
		text = JSON.stringify({"error": {"code": "empty_response", "message": "MCP tools/call returned an empty response."}})
	if response_code < 200 or response_code >= 300:
		text = JSON.stringify({"error": {"code": "http_%d" % response_code, "message": text}})
	_agent.call("handle_mcp_tool_call_response", tool_call_id, text)
	_render_active_messages()
	_continue_after_tool_result(tool_call_id)
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _continue_after_tool_result(tool_call_id: String) -> void:
	if _is_openai_busy():
		_add_persisted_message("assistant", "工具结果已记录，等待当前 OpenAI 请求结束后再继续。")
		_state.call("stop_agent_loop", "openai_request_busy")
		return
	var continuation: Dictionary = _agent.call("build_tool_result_continuation", tool_call_id)
	if bool(continuation.get("success", false)):
		if not bool(continuation.get("auto_send_allowed", false)):
			_add_persisted_message("assistant", "工具结果续跑请求已准备好。当前审批模式不会自动发送外部 OpenAI 请求。")
			_state.call("stop_agent_loop", "continuation_ready_waiting_for_user")
			return
		if not _start_openai_transport(continuation.get("transport_request", {})):
			_add_persisted_message("assistant", "工具结果续跑请求启动失败，已保留审计事件。")
			_state.call("stop_agent_loop", "continuation_start_failed")
		else:
			_state.call("record_agent_loop_step", "openai_continuation", tool_call_id)
			_state.call("clear_pending_openai_continuation", tool_call_id)
		return
	var error := str(continuation.get("error", "")).strip_edges()
	match error:
		"missing_api_key":
			_add_persisted_message("assistant", "工具结果已准备好，但 API Key 尚未就绪，续跑请求已暂存。")
			_state.call("stop_agent_loop", "missing_api_key")
		"unresolved_tool_calls":
			if _state.call("can_advance_agent_loop") and _try_start_next_tool_call(false):
				return
			_add_persisted_message("assistant", "工具结果已记录，仍有 %d 个工具调用待处理。" % int(continuation.get("unresolved_count", 0)))
			_state.call("stop_agent_loop", "unresolved_tool_calls")
		_:
			_add_persisted_message("assistant", "工具结果续跑暂不可用：%s。" % (error if not error.is_empty() else "unknown"))
			_state.call("stop_agent_loop", error if not error.is_empty() else "continuation_unavailable")


func _send_pending_openai_continuation() -> void:
	if _is_openai_busy():
		_add_persisted_message("assistant", "已有 OpenAI 请求正在执行。")
		_apply_model(_state.call("to_model"))
		return
	var pending: Dictionary = _state.pending_openai_continuation
	if pending.is_empty():
		_add_persisted_message("assistant", "当前没有待发送的 OpenAI 续跑请求。")
		_apply_model(_state.call("to_model"))
		return
	if str(pending.get("status", "")) != "ready":
		_add_persisted_message("assistant", "续跑请求尚未就绪：%s。" % str(pending.get("error", "unknown")))
		_apply_model(_state.call("to_model"))
		return
	var transport_request: Dictionary = pending.get("transport_request", {})
	if _requires_openai_send_approval():
		_queue_openai_approval_request(transport_request, "tool_result_continuation", str(pending.get("tool_call_id", "")))
		_save_sessions()
		_apply_model(_state.call("to_model"))
		return
	if not _start_openai_transport(transport_request):
		_add_persisted_message("assistant", "OpenAI 续跑请求启动失败，已保留审计事件。")
		_apply_model(_state.call("to_model"))
		return
	_send_continuation.disabled = true
	_send_continuation.text = "续跑发送中"
	_state.call("clear_pending_openai_continuation", str(pending.get("tool_call_id", "")))
	_add_persisted_message("assistant", "已发送 OpenAI 工具结果续跑请求。")
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _replay_pending_tool_result_continuation() -> void:
	var result: Dictionary = _agent.call("replay_pending_tool_result_continuation")
	if not bool(result.get("success", false)):
		var error := str(result.get("message", result.get("error", "unknown"))).strip_edges()
		_add_persisted_message("assistant", "本地工具结果续跑回放失败：%s。" % error)
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _on_search_text_changed(_value: String) -> void:
	_rebuild_search_results(_state.call("to_model"))


func _on_archived_search_text_changed(_value: String) -> void:
	_rebuild_archived_view()


func _approve_latest_checkpoint() -> void:
	_decide_latest_checkpoint("approve")


func _reject_latest_checkpoint() -> void:
	_decide_latest_checkpoint("reject")


func _decide_latest_checkpoint(decision: String) -> void:
	var record: Dictionary = _state.call("decide_latest_approval", decision)
	if record.is_empty():
		_add_persisted_message("assistant", "当前没有待处理审批。")
	else:
		var label := "已批准" if decision == "approve" else "已拒绝"
		_add_persisted_message("assistant", "%s：%s。" % [label, str(record.get("summary", ""))])
		_maybe_start_approved_openai_request(record, decision)
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _maybe_start_approved_openai_request(record: Dictionary, decision: String) -> void:
	var approval_id := str(record.get("id", ""))
	var pending: Dictionary = _state.pending_openai_approval_request
	if pending.is_empty() or str(pending.get("approval_id", "")) != approval_id:
		return
	if decision != "approve":
		_state.call("clear_pending_openai_approval_request", approval_id)
		_state.call("stop_agent_loop", "openai_approval_rejected")
		return
	var transport_request: Dictionary = _state.call("pending_openai_approval_transport_request")
	if transport_request.is_empty():
		_state.call("clear_pending_openai_approval_request", approval_id)
		_add_persisted_message("assistant", "已批准，但待发送 OpenAI 请求已不可用。")
		return
	var source := str(record.get("source", ""))
	var tool_call_id := str(record.get("tool_call_id", ""))
	_resume_agent_loop_for_approved_openai_source(source)
	_state.call("clear_pending_openai_approval_request", approval_id)
	if not _start_openai_transport(transport_request):
		_state.call("set_retry_openai_request", transport_request, "failed", "approval_send_start_failed")
		_add_persisted_message("assistant", "已批准，但 OpenAI 请求启动失败，已保留重试。")
		return
	if source == "tool_result_continuation":
		_state.call("clear_pending_openai_continuation", tool_call_id)
		_state.call("record_agent_loop_step", "openai_continuation", tool_call_id)
		_add_persisted_message("assistant", "已批准并发送 OpenAI 工具结果续跑请求。")
	elif source == "retry_request":
		_state.call("clear_retry_openai_request")
		_add_persisted_message("assistant", "已批准并发送 OpenAI 重试请求。")


func _resume_agent_loop_for_approved_openai_source(source: String) -> void:
	if _state == null:
		return
	if str(_state.get("agent_loop_status")) == "running":
		return
	match source:
		"user_prompt":
			_state.call("begin_agent_loop", "approved_user_prompt")
			_state.call("record_agent_loop_step", "openai_approved", "user_prompt")
		"queued_user_message":
			_state.call("begin_agent_loop", "approved_queued_user_message")
			_state.call("record_agent_loop_step", "openai_approved", "queued_user_message")
		"retry_request":
			_state.call("begin_agent_loop", "approved_retry_request")
			_state.call("record_agent_loop_step", "openai_approved", "retry_request")
		"tool_result_continuation":
			_state.call("begin_agent_loop", "approved_tool_result_continuation")
			_state.call("record_agent_loop_step", "openai_continuation_approved", "tool_result_continuation")


func _refresh_nav_state() -> void:
	for key in _nav_buttons.keys():
		var button: Button = _nav_buttons[key]
		_paint_sidebar_nav_button(button, key == _active_sidebar_surface, bool(_nav_hovered.get(key, false)))


func _on_endpoint_changed(value: String) -> void:
	_state.set("endpoint", value)
	_state.capability_summary = _state.call("build_capability_summary")
	_apply_model(_state.call("to_model"))


func _refresh_mcp_tools_from_settings() -> void:
	_apply_provider_fields_to_state()
	_start_mcp_tool_discovery()
	_apply_model(_state.call("to_model"))


func _focus_mcp_endpoint_from_settings() -> void:
	if _mcp_endpoint == null:
		return
	_mcp_endpoint.grab_focus()
	_mcp_endpoint.select_all()


func _save_settings_from_ui() -> void:
	_apply_provider_fields_to_state()
	var result: Dictionary = _settings_store.call("save_settings", _state.call("to_settings"))
	_apply_model(_state.call("to_model"))
	_api_status.text = "%s\n%s" % [
		_api_status_text(_state.call("api_config_snapshot")),
		"设置已保存到 %s。" % str(result.get("path", "user://godex/settings.json")) if bool(result.get("success", false)) else "设置保存失败。",
	]


func _apply_provider_fields_to_state() -> void:
	_state.call("set_provider", _provider.get_item_text(_provider.selected))
	_state.set("base_url", _base_url.text.strip_edges())
	_state.set("api_key", _api_key.text)
	_state.set("api_key_env", _api_key_env.text.strip_edges())
	var selected_model := _model.get_item_text(_model.selected).strip_edges() if _model != null and _model.selected >= 0 else ""
	_state.set("model", selected_model)
	_state.call("set_model", selected_model)
	var selected_api_mode := "chat_completions" if _api_mode.selected == 1 else "responses"
	if str(_state.provider) == "yurenapi":
		selected_api_mode = "chat_completions"
		_set_option_by_text(_api_mode, "Chat Completions Compatible")
	_state.set("api_mode", selected_api_mode)
	_state.set("endpoint", _mcp_endpoint.text.strip_edges())
	_state.set("skills_enabled", _skills_enabled.button_pressed)
	_state.set("mcp_enabled", _mcp_enabled.button_pressed)
	_state.set("compression_enabled", _compression_enabled.button_pressed)
	_state.set("command_enabled", _command_enabled.button_pressed)
	_state.set("command_shell", _command_shell.text.strip_edges())
	_state.set("reasoning_effort", str(_state.reasoning_effort))
	_state.capability_summary = _state.call("build_capability_summary")


func _toggle_ide_context() -> void:
	var next_enabled: bool = not bool(_state.ide_context_enabled)
	_state.set("ide_context_enabled", next_enabled)
	if not next_enabled:
		_ide_context_hovered = false
	_state.capability_summary = _state.call("build_capability_summary")
	_apply_model(_state.call("to_model"))


func _toggle_add_context_menu() -> void:
	if _add_context_panel.visible:
		_hide_add_context_menu()
	else:
		_show_add_context_menu()


func _add_image_attachment_placeholder() -> void:
	_hide_add_context_menu()
	_add_composer_reference({
		"kind": "image",
		"title": "图片占位",
		"detail": "来自 + 菜单，尚未接入图片上传或网络请求。",
		"content": "[图片附件占位：待选择图片]",
	})


func _on_composer_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if _try_add_drop_placeholder("composer_click_placeholder"):
			_composer_panel.accept_event()


func _try_add_drop_placeholder(source: String) -> bool:
	if not Input.is_key_pressed(KEY_CTRL) and not Input.is_key_pressed(KEY_META):
		return false
	_add_composer_reference({
		"kind": "image",
		"title": "拖拽图片占位",
		"detail": "来源：%s。仅记录 UI/数据占位，不发送图片内容。" % source,
		"content": "[图片附件占位：拖拽接入待实现]",
	})
	return true


func _show_add_context_menu() -> void:
	_hide_composer_popovers_except(_add_context_panel)
	_rebuild_add_context_menu()
	_add_context_panel.visible = true
	_position_add_context_panel()
	call_deferred("_position_add_context_panel")


func _hide_add_context_menu() -> void:
	if _add_context_panel != null:
		_add_context_panel.visible = false


func _add_mcp_project_summary_context() -> void:
	_hide_add_context_menu()
	var result: Dictionary = _agent.call("inject_mcp_context_probe", "summary", 20)
	_state.call("append_model_event", "context_menu_action", {
		"status": "requested",
		"kind": "project_summary",
		"label": "当前项目摘要",
		"detail": "通过 Godot .NET MCP 读取项目、场景、脚本和日志摘要",
		"source": "composer_add_context",
		"tool_call_id": str(result.get("tool_call", {}).get("id", "")),
	})
	_apply_model(_state.call("to_model"))
	_save_sessions()


func _add_first_recommended_file_context() -> void:
	var files: Array = _state.call("recommended_context_files", 1)
	if files.is_empty():
		return
	_add_recommended_file_context(str(files[0].get("path", "")))


func _add_recommended_file_context(path: String) -> void:
	_hide_add_context_menu()
	var event: Dictionary = _state.call("record_file_context", path, "composer_add_context")
	if event.is_empty():
		_state.call("append_model_event", "context_menu_action", {
			"status": "failed",
			"kind": "recommended_file",
			"label": "添加推荐文件",
			"detail": "no recommended file",
			"source": "composer_add_context",
		})
	else:
		_state.call("append_model_event", "context_menu_action", {
			"status": "attached",
			"kind": "recommended_file",
			"label": "添加推荐文件",
			"detail": path,
			"source": "composer_add_context",
		})
		_render_active_messages()
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _toggle_ide_context_from_menu() -> void:
	_hide_add_context_menu()
	_toggle_ide_context()
	_save_settings_from_ui()


func _toggle_goal_context_from_menu() -> void:
	_hide_add_context_menu()
	_toggle_goal_tracking()
	_save_settings_from_ui()


func _toggle_plan_mode_from_menu() -> void:
	_state.set("plan_mode_enabled", not bool(_state.plan_mode_enabled))
	_state.call("append_model_event", "plan_mode", {
		"status": "enabled" if bool(_state.plan_mode_enabled) else "disabled",
		"enabled": bool(_state.plan_mode_enabled),
		"detail": "只规划，不执行修改。" if bool(_state.plan_mode_enabled) else "恢复默认执行模式。",
	})
	_rebuild_add_context_menu()
	_apply_model(_state.call("to_model"))
	_save_settings_from_ui()
	_save_sessions()


func _open_plugins_from_context_menu() -> void:
	_hide_add_context_menu()
	_show_plugins()


func _compact_context_from_menu() -> void:
	_hide_add_context_menu()
	var result: Dictionary = _state.call("compact_active_session", 24, "composer_add_context")
	_state.call("append_model_event", "context_menu_action", {
		"status": "completed" if bool(result.get("success", false)) else "skipped",
		"kind": "compact_session",
		"label": "压缩当前会话",
		"detail": "移除 %d 条，保留 %d 条" % [int(result.get("removed_count", 0)), int(result.get("kept_count", 0))] if bool(result.get("success", false)) else str(result.get("error", "not_needed")),
		"source": "composer_add_context",
	})
	_save_sessions()
	_apply_model(_state.call("to_model"))


func _approval_modes() -> Array[String]:
	return ["请求批准", "替我审批", "完全访问权限"]


func _toggle_approval_mode_menu() -> void:
	if _approval_mode_panel.visible:
		_hide_approval_mode_menu()
	else:
		_show_approval_mode_menu()


func _show_approval_mode_menu() -> void:
	_hide_composer_popovers_except(_approval_mode_panel)
	_rebuild_approval_mode_menu(str(_state.approval_mode))
	_approval_mode_panel.visible = true
	_position_approval_mode_panel()
	call_deferred("_position_approval_mode_panel")


func _hide_approval_mode_menu() -> void:
	_approval_mode_panel.visible = false


func _hide_composer_popovers_except(keep_panel: Control = null) -> void:
	if keep_panel != _slash_command_panel:
		_hide_slash_command_panel()
	if keep_panel != _add_context_panel:
		_hide_add_context_menu()
	if keep_panel != _approval_mode_panel:
		_hide_approval_mode_menu()
	if keep_panel != _model_picker_panel:
		_hide_model_picker()
	if keep_panel != _reasoning_picker_panel:
		_hide_reasoning_picker()


func _rebuild_approval_mode_menu(current_mode: String) -> void:
	if _approval_mode_list == null:
		return
	_clear(_approval_mode_list)
	_approval_mode_list.add_theme_constant_override("separation", int(APPROVAL_POPOVER_ROW_GAP))
	var modes := _approval_modes()
	for i in range(modes.size()):
		_approval_mode_list.add_child(_build_approval_mode_row(i, modes[i], modes[i] == current_mode))


func _build_approval_mode_row(index: int, mode: String, selected: bool) -> Button:
	var button := Button.new()
	button.name = "ApprovalMode%s" % index
	button.custom_minimum_size = Vector2(0, APPROVAL_POPOVER_ROW_HEIGHT)
	button.text = ""
	button.tooltip_text = _approval_mode_tooltip(mode)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	GodexTheme.paint_button(button, selected)
	var content := HBoxContainer.new()
	content.name = "ApprovalModeRowContent"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16
	content.offset_right = -16
	content.offset_top = 0
	content.offset_bottom = 0
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 14)
	var icon := TextureRect.new()
	icon.name = "ApprovalModeIcon"
	icon.custom_minimum_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _editor_icon_texture(_approval_mode_icon(mode))
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon)
	var copy := VBoxContainer.new()
	copy.name = "ApprovalModeCopy"
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.name = "ApprovalModeName"
	title.text = mode
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(title, GodexTheme.TEXT, 16)
	var detail := Label.new()
	detail.name = "ApprovalModeDetail"
	detail.text = _approval_mode_menu_detail(mode)
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(detail, GodexTheme.MUTED, 15)
	copy.add_child(title)
	copy.add_child(detail)
	content.add_child(copy)
	var check := Label.new()
	check.name = "ApprovalModeCheck"
	check.custom_minimum_size = Vector2(24, 0)
	check.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	check.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	check.text = "✓" if selected else ""
	check.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GodexTheme.paint_label(check, GodexTheme.TEXT, 24)
	content.add_child(check)
	button.add_child(content)
	button.pressed.connect(_on_approval_mode_selected.bind(index))
	return button


func _on_approval_mode_selected(id: int) -> void:
	var modes := _approval_modes()
	if id < 0 or id >= modes.size():
		return
	_state.set("approval_mode", modes[id])
	_hide_approval_mode_menu()
	_apply_model(_state.call("to_model"))


func _approval_mode_menu_detail(mode: String) -> String:
	match mode:
		"请求批准":
			return "编辑外部文件和使用互联网时始终询问"
		"替我审批":
			return "仅对检测到的风险操作请求批准"
		"完全访问权限":
			return "可不受限制地访问互联网和您的电脑上的任何文件"
		_:
			return ""


func _approval_mode_icon(mode: String) -> Array:
	match mode:
		"请求批准":
			return ["Hand", "Pan", "ToolMove"]
		"替我审批":
			return ["Shield", "Lock", "StatusSuccess"]
		"完全访问权限":
			return ["Warnings", "StatusWarning", "NodeWarning"]
		_:
			return ["Shield"]


func _on_ide_context_hover_changed(hovered: bool) -> void:
	_ide_context_hovered = hovered
	_apply_composer_model(_state.call("to_model"))


func _on_goal_hover_changed(hovered: bool) -> void:
	_goal_hovered = hovered
	_apply_composer_model(_state.call("to_model"))


func _toggle_goal_tracking() -> void:
	var current_goal: Dictionary = _state.call("active_goal_record")
	var next_enabled: bool = not bool(current_goal.get("visible", _state.goal_tracking_enabled))
	_state.call("set_active_goal_enabled", next_enabled, "composer_goal_button")
	if not next_enabled:
		_goal_hovered = false
	_state.capability_summary = _state.call("build_capability_summary")
	_apply_model(_state.call("to_model"))
	_save_sessions()


func _toggle_model_picker() -> void:
	if _model_picker_panel.visible:
		_hide_model_picker()
	else:
		_show_model_picker()


func _on_model_submenu_hover_changed(hovered: bool, anchor: Control = null) -> void:
	if hovered:
		if anchor != null:
			_model_submenu_anchor = anchor
		_show_model_picker()
	else:
		_schedule_model_submenu_close()


func _schedule_model_submenu_close() -> void:
	call_deferred("_close_model_submenu_if_pointer_outside")


func _close_model_submenu_if_pointer_outside() -> void:
	if _model_picker_panel == null or not _model_picker_panel.visible:
		return
	var viewport := _model_picker_panel.get_viewport()
	if viewport == null:
		_hide_model_picker()
		return
	var pointer := viewport.get_mouse_position()
	var inside_model := _model_picker_panel.get_global_rect().has_point(pointer)
	var inside_anchor := _model_submenu_anchor != null and is_instance_valid(_model_submenu_anchor) and _model_submenu_anchor.get_global_rect().has_point(pointer)
	if not inside_model and not inside_anchor:
		_hide_model_picker()


func _show_model_picker() -> void:
	var model := _state.call("to_model")
	_rebuild_model_picker(model.get("model_choices", []), str(model.get("model", "gpt-5.5")))
	_model_picker_panel.visible = true
	_position_model_picker_panel()
	call_deferred("_position_model_picker_panel")
	if _reasoning_picker_panel != null and _reasoning_picker_panel.visible and _model_submenu_anchor != null:
		_start_model_submenu_hover_watch()


func _hide_model_picker() -> void:
	if _model_picker_panel != null:
		_model_picker_panel.visible = false
	_stop_model_submenu_hover_watch()


func _start_model_submenu_hover_watch() -> void:
	if _model_submenu_hover_watch == null or not is_instance_valid(_model_submenu_hover_watch):
		_configure_model_submenu_hover_watch()
	if _model_submenu_hover_watch != null and is_instance_valid(_model_submenu_hover_watch) and _model_submenu_hover_watch.is_stopped():
		_model_submenu_hover_watch.start()


func _stop_model_submenu_hover_watch() -> void:
	if _model_submenu_hover_watch != null and is_instance_valid(_model_submenu_hover_watch):
		_model_submenu_hover_watch.stop()


func _on_model_picker_selected(value: String) -> void:
	_state.call("set_model", value)
	_apply_settings_model_choices(_state.get("model_choices"), str(_state.model))
	_hide_composer_popovers_except()
	_apply_model(_state.call("to_model"))


func _toggle_reasoning_picker() -> void:
	if _reasoning_picker_panel.visible:
		_hide_reasoning_picker()
	else:
		_show_reasoning_picker()


func _show_reasoning_picker() -> void:
	_hide_composer_popovers_except(_reasoning_picker_panel)
	_rebuild_reasoning_picker(str(_state.reasoning_effort))
	_reasoning_picker_panel.visible = true
	_position_reasoning_picker_panel()
	call_deferred("_position_reasoning_picker_panel")


func _hide_reasoning_picker() -> void:
	if _reasoning_picker_panel != null:
		_reasoning_picker_panel.visible = false
	_hide_model_picker()


func _on_reasoning_picker_selected(value: String) -> void:
	if _reasoning_values().has(value):
		_state.set("reasoning_effort", value)
	_hide_composer_popovers_except()
	_apply_model(_state.call("to_model"))


func _on_provider_text_changed(_value: String) -> void:
	_apply_provider_fields_to_state()
	_api_status.text = _api_status_text(_state.call("api_config_snapshot"))
	_rebuild_capability_preview(_state.call("build_capability_summary"))


func _on_provider_selected(_index: int) -> void:
	_state.call("set_provider", _provider.get_item_text(_provider.selected))
	_set_provider_field_signals_blocked(true)
	_base_url.text = str(_state.base_url)
	_api_key_env.text = str(_state.api_key_env)
	_set_option_by_text(_api_mode, "Chat Completions Compatible" if str(_state.api_mode) == "chat_completions" else "Responses API")
	_set_provider_field_signals_blocked(false)
	_apply_settings_model_choices(_state.get("model_choices"), str(_state.model))
	_apply_model(_state.call("to_model"))


func _on_model_setting_selected(_index: int) -> void:
	_apply_provider_fields_to_state()
	_api_status.text = _api_status_text(_state.call("api_config_snapshot"))
	_rebuild_capability_preview(_state.call("build_capability_summary"))


func _refresh_capability_preview() -> void:
	_state.set("mcp_enabled", _mcp_enabled.button_pressed)
	_state.set("skills_enabled", _skills_enabled.button_pressed)
	_state.set("compression_enabled", _compression_enabled.button_pressed)
	_state.set("command_enabled", _command_enabled.button_pressed)
	_state.set("command_shell", _command_shell.text.strip_edges())
	_state.capability_summary = _state.call("build_capability_summary")
	_rebuild_capability_preview(_state.capability_summary)


func _rebuild_capability_preview(items: Array) -> void:
	_clear(_capability_preview)
	for item in items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var status := Label.new()
		var enabled := bool(item.get("enabled", false))
		status.text = "ON" if enabled else "OFF"
		GodexTheme.paint_label(status, GodexTheme.GREEN if enabled else GodexTheme.MUTED, 12)
		var text := Label.new()
		text.text = "%s · %s" % [str(item.get("title", "")), str(item.get("detail", ""))]
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		GodexTheme.paint_label(text, GodexTheme.TEXT if enabled else GodexTheme.MUTED, 12)
		row.add_child(status)
		row.add_child(text)
		_capability_preview.add_child(row)


func _on_capability_toggle_changed(_pressed: bool) -> void:
	_refresh_capability_preview()


func _on_capability_text_changed(_value: String) -> void:
	_refresh_capability_preview()


func _render_active_messages() -> void:
	_clear(_messages)
	_message_hover_panels.clear()
	_tool_transcript_rows.clear()
	_command_transcript_rows.clear()
	for item in _state.call("active_transcript_items"):
		_render_transcript_item(item)
	_apply_layout_state()


func _render_transcript_item(item) -> void:
	if not (item is Dictionary):
		return
	match str(item.get("kind", "")):
		"message":
			_add_message(str(item.get("role", "assistant")), str(item.get("content", "")), item)
		"local_tool_probe":
			pass
		"tool_batch":
			_show_tool_batch_transcript_row(item)
		"tool_call", "partial_tool_call":
			var fallback_batch_id := "tool_batch_%s" % str(item.get("turn_id", "unbound")).strip_edges()
			if fallback_batch_id == "tool_batch_":
				fallback_batch_id = "tool_batch_unbound"
			_show_tool_batch_transcript_row({
				"kind": "tool_batch",
				"batch_id": fallback_batch_id,
				"turn_id": str(item.get("turn_id", "")),
				"status": str(item.get("status", "completed")),
				"tool_count": 1,
				"calls": [item],
				"expanded": bool(item.get("expanded", false)),
			})
		"stream_step":
			pass
		"stream_trace":
			pass
		"agent_loop":
			pass
		"mcp_context":
			pass
		"context_menu_action":
			pass
		"queued_user_message":
			pass
		"pending_steer":
			pass
		"plan_mode":
			pass
		"goal_state":
			pass
		"session_compaction":
			pass
		"file_context":
			pass
		"subagent":
			pass
		"subagent_notification":
			pass
		"subagent_edge":
			pass
		"command_run":
			_show_command_transcript_row(
				str(item.get("command_id", "")),
				str(item.get("command", "")),
				_command_transcript_status_text(str(item.get("status", ""))),
				str(item.get("detail", "")),
				bool(item.get("expanded", false)),
				item.get("result", {})
			)


func _agent_loop_transcript_title(item: Dictionary) -> String:
	var action := str(item.get("action", "")).strip_edges()
	if action.is_empty():
		action = str(item.get("detail", "")).strip_edges()
	if action.is_empty():
		action = "Agent 循环"
	var steps := "%d 步" % int(item.get("step_count", 0))
	return "%s · %s" % [action, steps]


func _agent_loop_transcript_status(item: Dictionary) -> String:
	var status := str(item.get("status", ""))
	if status == "running":
		return "正在运行"
	if status == "stopped":
		return "已停止"
	return _event_status_text(status)


func _mcp_context_transcript_title(item: Dictionary) -> String:
	var summary := str(item.get("summary", "")).strip_edges()
	if summary.is_empty():
		summary = str(item.get("endpoint", "")).strip_edges()
	return "MCP 上下文 · %s" % (summary if not summary.is_empty() else "已记录")


func _subagent_notification_transcript_title(item: Dictionary) -> String:
	var name := str(item.get("name", "子智能体")).strip_edges()
	var detail := str(item.get("summary", item.get("result", item.get("error", "")))).strip_edges()
	var child_thread_id := str(item.get("child_thread_id", "")).strip_edges()
	var suffix_parts: Array[String] = []
	if not child_thread_id.is_empty():
		suffix_parts.append(child_thread_id)
	if not detail.is_empty():
		suffix_parts.append(_preview_text(detail, 72))
	return "子智能体通知 · %s%s" % [name, " · %s" % " · ".join(suffix_parts) if not suffix_parts.is_empty() else ""]


func _subagent_notification_status_text(status: String) -> String:
	match status:
		"completed", "done", "success":
			return "完成"
		"failed", "error":
			return "失败"
		"killed", "cancelled", "canceled":
			return "已终止"
		"interrupted":
			return "已中断"
		"running":
			return "运行中"
		"queued", "pending":
			return "排队"
		_:
			return status if not status.is_empty() else "已记录"


func _subagent_edge_transcript_title(item: Dictionary) -> String:
	var task_id := str(item.get("task_id", "")).strip_edges()
	var suffix := " · %s" % task_id if not task_id.is_empty() else ""
	return "子智能体关系 · %s -> %s%s" % [
		str(item.get("parent_thread_id", "")),
		str(item.get("child_thread_id", "")),
		suffix,
	]


func _subagent_edge_status_text(status: String) -> String:
	match status:
		"open", "running", "queued":
			return "打开"
		"closed", "done", "completed", "failed", "cancelled", "canceled", "killed", "interrupted":
			return "关闭"
		_:
			return status if not status.is_empty() else "已记录"


func _context_menu_action_transcript_title(item: Dictionary) -> String:
	var label := str(item.get("label", "")).strip_edges()
	if label.is_empty():
		match str(item.get("action_kind", "")):
			"project_summary":
				label = "当前项目摘要"
			"recommended_file":
				label = "推荐文件"
			_:
				label = "添加上下文"
	var detail := str(item.get("detail", "")).strip_edges()
	return "添加上下文 · %s%s" % [label, " · %s" % detail.left(72) if not detail.is_empty() else ""]


func _queued_user_message_transcript_title(item: Dictionary) -> String:
	var text := str(item.get("text", "")).strip_edges()
	return "用户消息队列 · %s" % (_preview_text(text, 96) if not text.is_empty() else "已记录")


func _pending_steer_transcript_title(item: Dictionary) -> String:
	var instructions := str(item.get("instructions", "")).strip_edges()
	var submitted_turn := str(item.get("submitted_turn_id", "")).strip_edges()
	var suffix := " · 已提交到 %s" % submitted_turn if not submitted_turn.is_empty() else ""
	return "指南指令 · %s%s" % [_preview_text(instructions, 96) if not instructions.is_empty() else "已记录", suffix]


func _plan_mode_transcript_title(item: Dictionary) -> String:
	if bool(item.get("enabled", false)):
		var detail := str(item.get("detail", "")).strip_edges()
		return "计划模式 · %s" % (detail if not detail.is_empty() else "只规划，不执行")
	return "计划模式 · 已关闭"


func _goal_state_transcript_title(item: Dictionary) -> String:
	var summary := str(item.get("summary", item.get("objective", ""))).strip_edges()
	if summary.is_empty():
		summary = "当前会话目标"
	return "目标追踪 · %s" % summary.left(96)


func _session_compaction_transcript_title(item: Dictionary) -> String:
	var source := str(item.get("source", "")).strip_edges()
	var label := "自动上下文压缩" if source == "auto_prepare_turn" else "上下文压缩"
	return "%s · 移除 %d 条，保留 %d 条 · %d -> %d tokens" % [
		label,
		int(item.get("removed_count", 0)),
		int(item.get("kept_count", 0)),
		int(item.get("context_used_before", 0)),
		int(item.get("context_used_after", 0)),
	]


func _file_context_transcript_title(item: Dictionary) -> String:
	var path := str(item.get("path", "")).strip_edges()
	var title := str(item.get("title", "")).strip_edges()
	if title.is_empty() and not path.is_empty():
		title = path.replace("\\", "/").get_file()
	if title.is_empty():
		title = "文件"
	return "文件上下文 · %s" % title


func _local_tool_probe_transcript_title(item: Dictionary) -> String:
	var tool := str(item.get("tool", "")).strip_edges()
	var scope := str(item.get("scope", "")).strip_edges()
	var detail := _join_non_empty([tool, scope], " · ")
	return "本地 MCP 探针 · %s" % (detail if not detail.is_empty() else "已创建")


func _openai_transport_transcript_title(item: Dictionary) -> String:
	if str(item.get("source", "")) == "local_model_replay":
		return "本地模型回放 · %s · 未发送网络请求" % _local_model_replay_fixture_label(str(item.get("fixture_name", "")))
	var title := _openai_transport_stage_label(item, "OpenAI 请求")
	var model := str(item.get("model", "")).strip_edges()
	if not model.is_empty():
		title += " · %s" % model
	var event_count := int(item.get("stream_event_count", 0))
	if event_count > 0:
		title += " · %d 个流式事件" % event_count
	var last_event_type := str(item.get("last_event_type", "")).strip_edges()
	if not last_event_type.is_empty():
		title += " · %s" % _openai_stream_event_label(last_event_type).left(48)
	if str(item.get("status", "")) == "completed" and event_count > 0 and not bool(item.get("completed_event_seen", false)):
		title += " · 未见完成事件"
	var error := str(item.get("message", item.get("error", ""))).strip_edges()
	if not error.is_empty():
		title += " · %s" % error.left(72)
	var status_code := int(item.get("status_code", 0))
	if status_code > 0 and title.find("HTTP %d" % status_code) < 0:
		title += " · HTTP %d" % status_code
	var body_preview := str(item.get("body_preview", "")).strip_edges()
	if not body_preview.is_empty() and body_preview != error:
		title += " · %s" % body_preview.left(96)
	return title


func _stream_trace_transcript_title(item: Dictionary) -> String:
	var event_type := str(item.get("event_type", "")).strip_edges()
	var title := "OpenAI stream"
	if not event_type.is_empty():
		title += " · %s" % _openai_stream_event_label(event_type).left(56)
	var names: Array[String] = []
	for name in item.get("tool_names", []):
		var tool_name := str(name).strip_edges()
		if not tool_name.is_empty() and not names.has(tool_name):
			names.append(tool_name)
	if not names.is_empty():
		title += " · %s" % ", ".join(names)
	var error := str(item.get("error", "")).strip_edges()
	if not error.is_empty():
		title += " · %s" % _openai_stream_error_message(error).left(72)
	return title


func _stream_trace_transcript_status(item: Dictionary) -> String:
	if str(item.get("status", "")) == "failed":
		return "失败"
	if str(item.get("status", "")) == "salvaged":
		return "已恢复"
	if bool(item.get("completed", false)):
		return "已完成"
	var argument_delta_length := int(item.get("argument_delta_length", 0))
	if argument_delta_length > 0:
		return "参数 +%d" % argument_delta_length
	var argument_length := int(item.get("argument_length", 0))
	if argument_length > 0:
		return "参数 %d" % argument_length
	var tool_delta_count := int(item.get("tool_delta_count", 0))
	var tool_call_count := int(item.get("tool_call_count", 0))
	if tool_delta_count + tool_call_count > 0:
		return "工具 %d" % (tool_delta_count + tool_call_count)
	var text_delta_length := int(item.get("text_delta_length", 0))
	if text_delta_length > 0:
		return "文本 +%d" % text_delta_length
	return _event_status_text(str(item.get("status", "")))


func _openai_stream_event_label(event_type: String) -> String:
	match event_type:
		"non_stream_response":
			return "非流式响应兼容收尾"
		"stream.salvaged_disconnect":
			return "断开后使用已接收内容收尾"
		"stream.error":
			return "流式错误"
		"response.completed":
			return "完成事件"
		_:
			return event_type


func _openai_request_transcript_title(item: Dictionary) -> String:
	var title := "OpenAI 请求已构建"
	var model := str(item.get("model", "")).strip_edges()
	var api_mode := str(item.get("api_mode", "")).strip_edges()
	if not model.is_empty():
		title += " · %s" % model
	if not api_mode.is_empty():
		title += " · %s" % api_mode
	if bool(item.get("plan_mode", false)):
		title += " · 计划模式"
		if int(item.get("tool_count", -1)) == 0:
			title += " · 无工具"
	var error := str(item.get("error", "")).strip_edges()
	if not error.is_empty():
		title += " · %s" % error.left(72)
	return title


func _openai_response_transcript_title(item: Dictionary) -> String:
	var prefix := "本地模型回放响应" if str(item.get("source", "")) == "local_model_replay" else "模型响应"
	var tool_call_count := int(item.get("tool_call_count", 0))
	if tool_call_count > 0:
		return "%s · %d 个工具调用" % [prefix, tool_call_count]
	var text := str(item.get("text", "")).strip_edges()
	if not text.is_empty():
		return "%s · %s" % [prefix, text.left(72)]
	return prefix


func _local_model_replay_fixture_label(fixture_name: String) -> String:
	match fixture_name.strip_edges():
		"mcp_context_tool_call":
			return "MCP 上下文工具调用"
		_:
			return "Responses 样例"


func _event_status_text(status: String) -> String:
	match status:
		"ok", "ready", "completed", "done", "success", "succeeded":
			return "已完成"
		"queued":
			return "已排队"
		"pending":
			return "待使用"
		"submitted":
			return "已提交"
		"blocked":
			return "已阻塞"
		"failed", "error":
			return "失败"
		"request_sent":
			return "已发送"
		"approval_required":
			return "等待审批"
		"canceled", "cancelled":
			return "已停止"
		"running", "streaming":
			return "正在运行"
		_:
			return status if not status.is_empty() else "已记录"


func _tool_transcript_status_text(status: String) -> String:
	match status:
		"pending":
			return "等待审批"
		"approved", "dispatch_ready":
			return "已批准"
		"streaming":
			return "正在解析"
		"executing":
			return "正在运行"
		"completed", "succeeded":
			return "已运行"
		"failed", "error":
			return "失败"
		"rejected":
			return "已拒绝"
		_:
			return status if not status.is_empty() else "工具调用"


func _command_transcript_status_text(status: String) -> String:
	match status:
		"queued":
			return "等待审批"
		"approval_required":
			return "请求审批"
		"approved":
			return "已批准"
		"running":
			return "正在运行"
		"completed", "succeeded":
			return "已运行"
		"failed", "error":
			return "失败"
		"blocked":
			return "已阻止"
		"rejected":
			return "已拒绝"
		"timed_out":
			return "已超时"
		"cancelled":
			return "已取消"
		_:
			return status if not status.is_empty() else "命令"


func _add_persisted_message(role: String, text: String) -> void:
	if _state == null:
		return
	var message_index := int(_state.call("append_message", role, text))
	if message_index < 0:
		return
	if _messages != null:
		_add_message(role, text)


func _save_sessions() -> void:
	if _session_store == null:
		return
	var snapshot: Dictionary = _state.call("to_sessions")
	_session_store.call("save_sessions", str(snapshot.get("active_thread_id", "")), snapshot.get("sessions", []), snapshot.get("approval_records", []))


func _approval_detail(approval) -> String:
	if not (approval is Dictionary) or approval.is_empty():
		return "没有待处理审批。"
	return "%s · %s · %s" % [str(approval.get("risk", "")), str(approval.get("action", "")), str(approval.get("summary", ""))]


func _api_status_text(config) -> String:
	if not (config is Dictionary):
		return "认证状态：缺少 API Key"
	var source := str(config.get("key_source", "missing"))
	var endpoint := str(config.get("endpoint", ""))
	match source:
		"environment":
			return "认证状态：环境变量 %s · %s" % [str(config.get("key_env", "")), endpoint]
		"inline":
			return "认证状态：手动输入 %s · %s" % [str(config.get("masked_api_key", "")), endpoint]
		_:
			return "认证状态：缺少 API Key · %s" % endpoint


func _set_provider_field_signals_blocked(blocked: bool) -> void:
	for field in [_base_url, _api_key, _api_key_env]:
		if field != null:
			field.set_block_signals(blocked)
	if _model != null:
		_model.set_block_signals(blocked)
	if _api_mode != null:
		_api_mode.set_block_signals(blocked)


func _set_option_by_text(option: OptionButton, text: String) -> void:
	for index in range(option.item_count):
		if option.get_item_text(index) == text:
			option.selected = index
			return


func _model_to_menu_label(value: String) -> String:
	match value:
		"gpt-5.5":
			return "GPT-5.5"
		"gpt-5.4":
			return "GPT-5.4"
		"gpt-5.4-mini":
			return "GPT-5.4-Mini"
		"gpt-5.3-codex":
			return "GPT-5.3-Codex"
		"gpt-5.2":
			return "GPT-5.2"
	return value


func _model_to_compact_label(value: String) -> String:
	match value:
		"gpt-5.5":
			return "5.5"
		"gpt-5.4":
			return "5.4"
		"gpt-5.4-mini":
			return "5.4-Mini"
		"gpt-5.3-codex":
			return "5.3-Codex"
		"gpt-5.2":
			return "5.2"
	return value


func _reasoning_to_label(value: String) -> String:
	match value:
		"low":
			return "低"
		"medium":
			return "中"
		"high":
			return "高"
		"xhigh":
			return "超高"
	return "中"


func _reasoning_values() -> Array[String]:
	return ["low", "medium", "high", "xhigh"]


func _reasoning_detail(value: String) -> String:
	match value:
		"low":
			return "低 · 更快响应，适合简单编辑。"
		"medium":
			return "中 · 平衡速度和推理质量。"
		"high":
			return "高 · 更细致地规划和审查。"
		"xhigh":
			return "超高 · 用于复杂重构和长链路 Agent 任务。"
	return "中 · 平衡速度和推理质量。"


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
