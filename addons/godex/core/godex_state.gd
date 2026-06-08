@tool
class_name GodexState
extends RefCounted

const ProviderCatalog = preload("res://addons/godex/core/provider_catalog.gd")
const RequestBuilder = preload("res://addons/godex/core/openai_request_builder.gd")
const CommandCapability = preload("res://addons/godex/core/command_capability.gd")
const GitChangeSummaryService = preload("res://addons/godex/core/git_change_summary_service.gd")
const DEFAULT_MCP_ENDPOINT := "http://127.0.0.1:3000/mcp"
const AUTO_COMPACT_THRESHOLD_RATIO := 0.72
const CONTEXT_WARNING_RATIO := 0.60
const MAX_COMPACTION_HISTORY := 6

var endpoint := DEFAULT_MCP_ENDPOINT
var model_label := "5.5"
var approval_mode := "替我审批"
var reasoning_effort := "medium"
var active_project := "Godot Project"
var active_thread := "快速对话"
var is_running := false
var context_budget := 128000
var context_used := 18432
var compression_enabled := true
var api_mode := "responses"
var base_url := "https://api.openai.com"
var model := "gpt-5.5"
var provider := "openai"
var api_key := ""
var api_key_env := "OPENAI_API_KEY"
var skills_enabled := true
var skill_disabled_paths: Array[String] = []
var skill_registry_model: Dictionary = {
	"skill_count": 0,
	"enabled_count": 0,
	"skills": [],
	"disabled_paths": [],
	"source": "local",
	"remote_enabled": false,
	"marketplace_enabled": false,
}
var mcp_enabled := true
var command_enabled := false
var command_shell := "PowerShell"
var command_working_directory := "res://"
var command_timeout_sec := 30
var ide_context_enabled := true
var goal_tracking_enabled := false
var plan_mode_enabled := false
var sidebar_width := 310.0
var capability_summary: Array[Dictionary] = []
var model_choices: Array[String] = []
var active_thread_id := "quick_chat"
var approval_records: Array[Dictionary] = []
var mcp_discovered_tools: Array[Dictionary] = []
var mcp_discovery_status := "idle"
var mcp_discovery_error := ""
var mcp_discovered_at := ""
var pending_openai_continuation: Dictionary = {}
var pending_openai_approval_request: Dictionary = {}
var retry_openai_request: Dictionary = {}
var settings_migrated := false
var agent_loop_status := "idle"
var agent_loop_step_count := 0
var agent_loop_max_steps := 0
var agent_loop_stop_reason := ""
var agent_loop_updated_at := ""
var active_turn_id := ""
var change_review_summary: Dictionary = {}
var partial_tool_calls: Dictionary = {}
var tool_batch_expanded: Dictionary = {}
var last_compaction: Dictionary = {}
var compaction_history: Array[Dictionary] = []
var composer_references: Array[Dictionary] = []
var _id_sequence := 0

var threads: Array[Dictionary] = [
	{"id": "quick_chat", "title": "快速对话", "status": "active", "age": "现在", "action": "chat", "archived": false, "pinned": false, "messages": []},
	{"id": "mcp_status", "title": "检查 MCP 插件连接", "status": "idle", "age": "现在", "action": "inspect_mcp", "archived": false, "pinned": false, "messages": []},
	{"id": "runtime_triage", "title": "整理场景运行问题", "status": "idle", "age": "12 分", "action": "show_runtime_plan", "archived": false, "pinned": false},
	{"id": "ui_plan", "title": "生成 UI 调整计划", "status": "idle", "age": "36 分", "action": "show_ui_plan", "archived": false, "pinned": false},
]

var progress_items: Array[Dictionary] = []

# Right-inspector `输出` artifacts. Do not store command stdout/stderr,
# assistant prose, MCP payloads, or model transport logs here.
var outputs: Array[Dictionary] = []

var tools: Array[Dictionary] = [
	{"id": "mcp_context", "title": "MCP 上下文", "subtitle": "读取项目、场景、脚本和日志状态", "icon": "Node"},
	{"id": "agent_run", "title": "Agent 执行", "subtitle": "规划、调用工具、记录透明步骤", "icon": "Play"},
	{"id": "subagents", "title": "子代理", "subtitle": "拆分只读调查、验证和实现分支", "icon": "Groups"},
	{"id": "approval", "title": "审批", "subtitle": "写入、命令和高风险操作前停靠", "icon": "StatusWarning"},
	{"id": "compression", "title": "上下文压缩", "subtitle": "长任务自动摘要、保留目标与证据", "icon": "Reload"},
	{"id": "openai_api", "title": "OpenAI API", "subtitle": "Responses / Chat Completions 兼容配置", "icon": "Tools"},
]
var slash_commands: Array[Dictionary] = [
	{"command": "/mcp", "args": "", "title": "MCP 服务器", "summary": "查看 MCP 连接、工具发现和项目能力", "aliases": ["mcp-server"], "icon": ["Node", "Tools"]},
	{"command": "/status", "args": "", "title": "状态", "summary": "显示会话 ID、上下文使用情况及额度限制", "aliases": ["state"], "icon": ["StatusSuccess", "Info"]},
	{"command": "/personality", "args": "[模式]", "title": "个性", "summary": "选择 Codex 的回应方式", "aliases": ["style"], "icon": ["History", "Clock"]},
	{"command": "/review", "args": "[目标]", "title": "代码审查", "summary": "审查未暂存的更改，或与某个分支进行比较", "aliases": ["code-review"], "icon": ["Search", "Inspect"]},
	{"command": "/side", "args": "", "title": "侧边", "summary": "在临时分支中发起侧边对话", "aliases": ["fork", "branch"], "icon": ["Add", "Instance"]},
	{"command": "/compact", "args": "", "title": "压缩", "summary": "压缩此会话的上下文", "aliases": [], "icon": ["Reload", "Compress"]},
	{"command": "/feedback", "args": "", "title": "反馈", "summary": "发送有关此聊天的反馈", "aliases": [], "icon": ["Chat", "Comment"]},
	{"command": "/model", "args": "[模型]", "title": "模型", "summary": "选择当前对话使用的模型", "aliases": [], "icon": ["Cube", "Object"]},
	{"command": "/reasoning", "args": "[低|中|高]", "title": "推理模式", "summary": "选择 Codex 的推理强度", "aliases": ["effort"], "icon": ["Tools"]},
	{"command": "/goal", "args": "[内容|pause|resume|complete|off]", "title": "目标", "summary": "设置当前会话目标", "aliases": [], "icon": ["TrackColor", "Key"]},
	{"command": "/ide", "args": "[on|off]", "title": "IDE 上下文", "summary": "切换 IDE 上下文", "aliases": ["context"], "icon": ["GuiVisibilityVisible", "Show"]},
	{"command": "/pin", "args": "", "title": "置顶", "summary": "固定或取消固定当前会话", "aliases": [], "icon": ["Pin", "Favorites"]},
	{"command": "/resume", "args": "<关键词>", "title": "恢复会话", "summary": "搜索并打开匹配的会话", "aliases": ["open"], "icon": ["History", "Search"]},
	{"command": "/rename", "args": "<标题>", "title": "重命名", "summary": "修改当前会话标题", "aliases": [], "icon": ["Rename", "Edit"]},
	{"command": "/archive", "args": "", "title": "归档", "summary": "收起当前会话", "aliases": [], "icon": ["MoveDown", "Folder"]},
	{"command": "/new", "args": "", "title": "新对话", "summary": "创建新的空白对话", "aliases": ["newchat"], "icon": ["Edit"]},
	{"command": "/help", "args": "", "title": "帮助", "summary": "显示可用本地命令", "aliases": [], "icon": ["Help"]},
]


func set_active_project(project_name: String) -> String:
	var clean_name := project_name.strip_edges()
	if clean_name.is_empty():
		return active_project
	active_project = clean_name
	return active_project


func refresh_active_project_from_settings() -> String:
	var configured_name := str(ProjectSettings.get_setting("application/config/name", ""))
	if configured_name.strip_edges().is_empty():
		configured_name = _project_name_from_path(ProjectSettings.globalize_path("res://"))
	return set_active_project(configured_name)


func apply_project_summary(data: Dictionary) -> String:
	var project_name := _project_name_from_summary(data)
	if project_name.is_empty():
		return active_project
	return set_active_project(project_name)


func _project_name_from_summary(data: Dictionary) -> String:
	var direct := str(data.get("project_name", "")).strip_edges()
	if not direct.is_empty():
		return direct
	for key in ["project", "summary", "data"]:
		if not data.has(key):
			continue
		var nested = data.get(key)
		if nested is Dictionary and not nested.is_empty():
			var nested_name := _project_name_from_summary(nested)
			if not nested_name.is_empty():
				return nested_name
	var project_path := str(data.get("project_path", data.get("path", ""))).strip_edges()
	return _project_name_from_path(project_path)


func _project_name_from_path(project_path: String) -> String:
	var normalized := project_path.strip_edges().replace("\\", "/")
	while normalized.ends_with("/"):
		normalized = normalized.substr(0, normalized.length() - 1)
	if normalized.is_empty():
		return ""
	return normalized.get_file()


func to_model() -> Dictionary:
	var mcp_row := mcp_server_row()
	var goal_record := active_goal_record()
	return {
		"endpoint": endpoint,
		"model_label": model_label,
		"approval_mode": approval_mode,
		"reasoning_effort": reasoning_effort,
		"active_project": active_project,
		"active_thread": active_thread,
		"is_running": is_running,
		"context_budget": context_budget,
		"context_used": context_used,
		"compression_enabled": compression_enabled,
		"api_mode": api_mode,
		"base_url": base_url,
		"model": model,
		"provider": provider,
		"api_key": api_key,
		"api_key_env": api_key_env,
		"api_config": api_config_snapshot(),
		"skills_enabled": skills_enabled,
		"skill_disabled_paths": skill_disabled_paths.duplicate(),
		"skill_registry": skill_registry_model.duplicate(true),
		"mcp_enabled": mcp_enabled,
		"command_enabled": command_enabled,
		"command_shell": command_shell,
		"ide_context_enabled": ide_context_enabled,
		"goal_tracking_enabled": bool(goal_record.get("visible", goal_record.get("enabled", goal_tracking_enabled))),
		"active_goal": goal_record,
		"plan_mode_enabled": plan_mode_enabled,
		"sidebar_width": sidebar_width,
		"active_thread_id": active_thread_id,
		"approval_records": approval_records,
		"pending_approval": latest_pending_approval(),
		"mcp_discovery_status": mcp_discovery_status,
		"mcp_discovery_error": mcp_discovery_error,
		"mcp_discovered_at": mcp_discovered_at,
		"mcp_discovered_tools": mcp_discovered_tools,
		"mcp_server_row": mcp_row,
		"mcp_server_rows": [mcp_row],
		"pending_openai_continuation": pending_openai_continuation,
		"pending_openai_approval_request": pending_openai_approval_request_preview(),
		"retry_openai_request": retry_openai_request_preview(),
		"queued_user_messages": active_queued_user_messages(),
		"composer_references": active_composer_references(),
		"pending_steers": active_pending_steers(),
		"active_pending_guide_instruction": active_pending_guide_instruction(),
		"agent_loop_status": agent_loop_status,
		"agent_loop_step_count": agent_loop_step_count,
		"agent_loop_max_steps": agent_loop_max_steps,
		"agent_loop_stop_reason": agent_loop_stop_reason,
		"change_review_summary": change_review_preview(),
		"context_window_warning": context_window_warning(),
		"last_compaction": last_compaction_preview(),
		"compaction_history": compaction_history_preview(),
		"capability_summary": build_capability_summary(),
		"provider_ids": ProviderCatalog.provider_ids(),
		"model_choices": ProviderCatalog.models_for(provider),
		"threads": threads,
		"progress_items": progress_items,
		"outputs": outputs,
		"tools": tools,
		"slash_command_suggestions": slash_command_suggestions(""),
	}


func mcp_server_row() -> Dictionary:
	var status := mcp_discovery_status
	if not mcp_enabled:
		status = "disabled"
	return {
		"id": "godot_dotnet_mcp",
		"name": "Godot .NET MCP",
		"transport": "streamable-http",
		"endpoint": endpoint,
		"enabled": mcp_enabled,
		"status": status,
		"error": mcp_discovery_error,
		"tool_count": mcp_discovered_tools.size(),
		"last_discovered_at": mcp_discovered_at,
		"auth": "none",
		"editable": true,
	}


func apply_sessions(payload: Dictionary) -> void:
	var loaded_sessions = payload.get("sessions", [])
	if loaded_sessions is Array and not loaded_sessions.is_empty():
		threads.assign(loaded_sessions)
	var loaded_approvals = payload.get("approval_records", [])
	if loaded_approvals is Array:
		approval_records.assign(loaded_approvals)
	var loaded_review = payload.get("change_review_summary", {})
	if loaded_review is Dictionary:
		set_change_review_summary(loaded_review)
	var loaded_outputs = payload.get("outputs", [])
	if payload.has("outputs") and loaded_outputs is Array:
		outputs.clear()
		for item in loaded_outputs:
			if item is Dictionary:
				record_output_artifact(item)
	active_thread_id = str(payload.get("active_thread_id", active_thread_id))
	select_thread(active_thread_id)


func to_sessions() -> Dictionary:
	return {
		"active_thread_id": active_thread_id,
		"sessions": threads,
		"approval_records": approval_records,
		"change_review_summary": change_review_summary,
		"outputs": outputs,
	}


func set_change_review_summary(summary: Dictionary) -> Dictionary:
	if summary.is_empty():
		change_review_summary = {}
		_clear_output_artifacts_by_source("change_review")
		return change_review_summary
	var files: Array[Dictionary] = []
	for raw_file in summary.get("files", []):
		if not (raw_file is Dictionary):
			continue
		files.append({
			"path": str(raw_file.get("path", "")),
			"added": max(0, int(raw_file.get("added", 0))),
			"removed": max(0, int(raw_file.get("removed", 0))),
			"status": str(raw_file.get("status", "modified")),
		})
	var added := max(0, int(summary.get("added", 0)))
	var removed := max(0, int(summary.get("removed", 0)))
	if added == 0 and removed == 0:
		for file in files:
			added += int(file.get("added", 0))
			removed += int(file.get("removed", 0))
	change_review_summary = {
		"file_count": int(summary.get("file_count", files.size())) if summary.has("file_count") else files.size(),
		"added": added,
		"removed": removed,
		"files": files,
		"expanded": bool(summary.get("expanded", false)),
		"status": str(summary.get("status", "ready")),
		"title": str(summary.get("title", "文件已更改")),
		"updated_at": Time.get_datetime_string_from_system(),
	}
	_replace_change_review_output_artifacts(files)
	return change_review_summary


func set_change_review_expanded(expanded: bool) -> Dictionary:
	if change_review_summary.is_empty():
		return {}
	change_review_summary["expanded"] = expanded
	return change_review_summary


func clear_change_review_summary() -> void:
	change_review_summary = {}
	_clear_output_artifacts_by_source("change_review")


func change_review_preview() -> Dictionary:
	if change_review_summary.is_empty():
		return {}
	var preview := change_review_summary.duplicate(true)
	var files: Array = preview.get("files", [])
	if files.size() > 6:
		preview["files"] = files.slice(0, 6)
		preview["hidden_file_count"] = files.size() - 6
	return preview


func record_output_artifact(artifact: Dictionary) -> Dictionary:
	var normalized := _normalize_output_artifact(artifact)
	if normalized.is_empty():
		return {}
	var key := _output_artifact_key(normalized)
	for index in range(outputs.size()):
		var existing: Dictionary = outputs[index]
		if _output_artifact_key(existing) == key:
			outputs[index] = normalized
			return normalized
	outputs.append(normalized)
	return normalized


func _replace_change_review_output_artifacts(files: Array[Dictionary]) -> void:
	_clear_output_artifacts_by_source("change_review")
	for file in files:
		var path := str(file.get("path", "")).strip_edges()
		if path.is_empty():
			continue
		record_output_artifact({
			"title": path.replace("\\", "/").get_file(),
			"detail": path,
			"path": path,
			"kind": "文件",
			"icon": ["File", "TextFile"],
			"source": "change_review",
			"status": str(file.get("status", "modified")),
			"added": int(file.get("added", 0)),
			"removed": int(file.get("removed", 0)),
		})


func _clear_output_artifacts_by_source(source: String) -> void:
	var kept: Array[Dictionary] = []
	for item in outputs:
		if not (item is Dictionary):
			continue
		if str(item.get("source", "")) == source:
			continue
		kept.append(item)
	outputs = kept


func _normalize_output_artifact(artifact: Dictionary) -> Dictionary:
	var path := str(artifact.get("path", artifact.get("detail", ""))).strip_edges().replace("\\", "/")
	var title := str(artifact.get("title", "")).strip_edges()
	if title.is_empty() and not path.is_empty():
		title = path.get_file()
	var detail := str(artifact.get("detail", path)).strip_edges()
	if title.is_empty() and detail.is_empty():
		return {}
	var icon = artifact.get("icon", ["File", "TextFile"])
	if not (icon is Array):
		icon = ["File", "TextFile"]
	return {
		"id": str(artifact.get("id", _output_artifact_key({
			"title": title,
			"detail": detail,
			"path": path,
			"source": str(artifact.get("source", "manual")),
		}))),
		"title": title,
		"detail": detail,
		"path": path,
		"kind": str(artifact.get("kind", "文件")),
		"icon": icon,
		"source": str(artifact.get("source", "manual")),
		"status": str(artifact.get("status", "")),
		"added": max(0, int(artifact.get("added", 0))),
		"removed": max(0, int(artifact.get("removed", 0))),
	}


func _output_artifact_key(artifact: Dictionary) -> String:
	var path := str(artifact.get("path", "")).strip_edges().replace("\\", "/")
	if not path.is_empty():
		return "%s:%s" % [str(artifact.get("source", "manual")), path]
	return "%s:%s:%s" % [
		str(artifact.get("source", "manual")),
		str(artifact.get("kind", "")),
		str(artifact.get("title", "")),
	]


func recommended_context_files(limit: int = 6) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var seen: Dictionary = {}
	var files: Array = change_review_summary.get("files", []) if change_review_summary is Dictionary else []
	for file in files:
		if not (file is Dictionary):
			continue
		var path := str(file.get("path", "")).strip_edges()
		if path.is_empty() or seen.has(path):
			continue
		seen[path] = true
		var normalized_path := path.replace("\\", "/")
		results.append({
			"path": path,
			"title": normalized_path.get_file(),
			"detail": "%s · +%d -%d" % [path, int(file.get("added", 0)), int(file.get("removed", 0))],
		})
		if results.size() >= limit:
			break
	return results


func record_file_context(path: String, source: String = "composer_add_context") -> Dictionary:
	var clean_path := path.strip_edges()
	if clean_path.is_empty():
		return {}
	var event := append_model_event("file_context", {
		"status": "attached",
		"path": clean_path,
		"title": clean_path.replace("\\", "/").get_file(),
		"source": source,
	})
	return event


func new_session() -> Dictionary:
	var next_id := _new_thread_id()
	var session := {
		"id": next_id,
		"title": "新对话",
		"status": "active",
		"age": "现在",
		"action": "chat",
		"archived": false,
		"pinned": false,
		"messages": [],
		"model_events": [],
		"subagent_tasks": [],
		"subagent_notifications": [],
		"subagent_edges": [],
		"queued_user_messages": [],
		"pending_steers": [],
		"progress_items": [],
		"active_goal": _empty_goal_record(next_id),
		"last_compaction": {},
		"compaction_history": [],
	}
	threads.push_front(session)
	select_thread(next_id)
	return session


func select_thread(thread_id: String) -> Dictionary:
	active_turn_id = ""
	var selected := {}
	for item in threads:
		if bool(item.get("archived", false)):
			item["status"] = "archived"
			continue
		if str(item.get("id", "")) == thread_id:
			item["status"] = "active"
			active_thread_id = thread_id
			active_thread = str(item.get("title", active_thread))
			selected = item
		else:
			item["status"] = "idle"
	if selected.is_empty() and not threads.is_empty():
		for item in threads:
			if not bool(item.get("archived", false)):
				item["status"] = "active"
				active_thread_id = str(item.get("id", active_thread_id))
				active_thread = str(item.get("title", active_thread))
				selected = item
				break
	var selected_compaction = selected.get("last_compaction", {}) if selected is Dictionary else {}
	last_compaction = selected_compaction.duplicate(true) if selected_compaction is Dictionary else {}
	var selected_history = selected.get("compaction_history", []) if selected is Dictionary else []
	compaction_history.clear()
	if selected_history is Array:
		for item in selected_history:
			if item is Dictionary:
				compaction_history.append(item.duplicate(true))
	var selected_progress = selected.get("progress_items", []) if selected is Dictionary else []
	progress_items = _normalize_progress_items(selected_progress)
	_sync_goal_tracking_from_active_session()
	return selected


func rename_active_session(title: String) -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	return rename_session(str(session.get("id", "")), title)


func rename_session(thread_id: String, title: String) -> Dictionary:
	var index := _find_session_index(thread_id)
	if index < 0:
		return {}
	var session: Dictionary = threads[index].duplicate(true)
	var clean_title := title.strip_edges()
	if clean_title.is_empty():
		return {}
	session["title"] = clean_title
	threads[index] = session
	if str(session.get("id", "")) == active_thread_id:
		active_thread = clean_title
	return session


func toggle_pin_active_session() -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	return toggle_pin_session(str(session.get("id", "")))


func toggle_pin_session(thread_id: String) -> Dictionary:
	var index := _find_session_index(thread_id)
	if index < 0:
		return {}
	var session: Dictionary = threads[index].duplicate(true)
	session["pinned"] = not bool(session.get("pinned", false))
	threads[index] = session
	return session


func compact_active_session(limit: int = 24, source: String = "slash_command") -> Dictionary:
	return _compact_active_session(limit, source, false, context_used, context_budget)


func auto_compact_active_session(limit: int = 24, used: int = -1, budget: int = -1) -> Dictionary:
	if used < 0:
		used = context_used
	if budget < 0:
		budget = context_budget
	if not compression_enabled:
		return {"success": false, "error": "compression_disabled", "context_used": used, "context_budget": budget}
	return _compact_active_session(limit, "auto_prepare_turn", true, used, budget)


func last_compaction_preview() -> Dictionary:
	if last_compaction.is_empty():
		return {}
	return {
		"status": str(last_compaction.get("status", "")),
		"source": str(last_compaction.get("source", "")),
		"removed_count": int(last_compaction.get("removed_count", 0)),
		"kept_count": int(last_compaction.get("kept_count", 0)),
		"context_used_before": int(last_compaction.get("context_used_before", 0)),
		"context_used_after": int(last_compaction.get("context_used_after", 0)),
		"context_budget": int(last_compaction.get("context_budget", context_budget)),
		"created_at": str(last_compaction.get("created_at", "")),
	}


func compaction_history_preview(limit: int = MAX_COMPACTION_HISTORY) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var start := max(compaction_history.size() - limit, 0)
	for item in compaction_history.slice(start, compaction_history.size()):
		if item is Dictionary:
			rows.append(_compaction_preview(item))
	return rows


func context_window_warning() -> Dictionary:
	var used := max(0, context_used)
	var budget := max(0, context_budget)
	var percent := 0
	var until_auto := 0
	var status := "unknown"
	var message := "上下文预算不可用。"
	if budget > 0:
		percent = int(round(float(used) / float(budget) * 100.0))
		var auto_threshold := int(floor(float(budget) * AUTO_COMPACT_THRESHOLD_RATIO))
		until_auto = max(0, auto_threshold - used)
		if used >= auto_threshold:
			status = "auto_ready"
			message = "已达到自动压缩阈值；下一次 Agent 回合会先压缩旧上下文。"
		elif float(used) / float(budget) >= CONTEXT_WARNING_RATIO:
			status = "warning"
			message = "接近自动压缩阈值，还剩约 %d tokens。" % until_auto
		else:
			status = "ok"
			message = "上下文余量充足，距离自动压缩约 %d tokens。" % until_auto
	return {
		"status": status,
		"percent": percent,
		"context_used": used,
		"context_budget": budget,
		"auto_threshold_percent": int(round(AUTO_COMPACT_THRESHOLD_RATIO * 100.0)),
		"warning_threshold_percent": int(round(CONTEXT_WARNING_RATIO * 100.0)),
		"tokens_until_auto_compact": until_auto,
		"message": message,
	}


func compaction_history_summary_rows(limit: int = 3) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var warning := context_window_warning()
	rows.append({
		"title": "上下文窗口 · %s%%" % int(warning.get("percent", 0)),
		"detail": str(warning.get("message", "")),
		"enabled": str(warning.get("status", "")) in ["warning", "auto_ready"],
		"risk": "medium" if str(warning.get("status", "")) == "auto_ready" else "low",
	})
	var history := compaction_history_preview(limit)
	for index in range(history.size() - 1, -1, -1):
		var item: Dictionary = history[index]
		rows.append({
			"title": "压缩历史 · %s" % _compaction_source_label(str(item.get("source", ""))),
			"detail": "移除 %d 条，保留 %d 条 · %d -> %d tokens · %s" % [
				int(item.get("removed_count", 0)),
				int(item.get("kept_count", 0)),
				int(item.get("context_used_before", 0)),
				int(item.get("context_used_after", 0)),
				str(item.get("created_at", "")),
			],
			"enabled": false,
			"risk": "low",
		})
	if rows.size() == 1:
		rows.append({"title": "压缩历史", "detail": "暂无上下文压缩记录。", "enabled": false, "risk": "low"})
	return rows


func _compact_active_session(limit: int, source: String, automatic: bool, used: int, budget: int) -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {"success": false, "error": "no_active_session"}
	var messages = session.get("messages", [])
	if not (messages is Array):
		return {"success": false, "error": "messages_unavailable"}
	if messages.size() <= limit:
		return {"success": false, "error": "not_needed", "message_count": messages.size(), "context_used": used, "context_budget": budget}
	var keep_count := maxi(6, int(limit / 2))
	var removed: Array = messages.slice(0, messages.size() - keep_count)
	var kept: Array = messages.slice(messages.size() - keep_count)
	var summary_lines: Array[String] = []
	for item in removed:
		if not (item is Dictionary):
			continue
		var role := str(item.get("role", "user"))
		var content := str(item.get("content", "")).strip_edges()
		if content.length() > 120:
			content = content.substr(0, 120) + "..."
		summary_lines.append("%s: %s" % [role, content])
	var summary := "Prior conversation summary:\n%s" % "\n".join(summary_lines)
	var compacted_messages := [{"role": "system", "content": summary}] + kept
	session["messages"] = compacted_messages
	var context_after := _estimate_messages_tokens(compacted_messages)
	context_used = context_after
	var created_at := Time.get_datetime_string_from_system()
	last_compaction = {
		"status": "compacted",
		"source": source,
		"automatic": automatic,
		"removed_count": removed.size(),
		"kept_count": kept.size(),
		"limit": limit,
		"context_used_before": max(0, used),
		"context_used_after": context_after,
		"context_budget": budget,
		"created_at": created_at,
		"summary": summary,
	}
	session["last_compaction"] = last_compaction.duplicate(true)
	compaction_history.append(last_compaction.duplicate(true))
	if compaction_history.size() > MAX_COMPACTION_HISTORY:
		compaction_history = compaction_history.slice(compaction_history.size() - MAX_COMPACTION_HISTORY, compaction_history.size())
	session["compaction_history"] = compaction_history.duplicate(true)
	append_model_event("session_compaction", last_compaction)
	return {
		"success": true,
		"removed_count": removed.size(),
		"kept_count": kept.size(),
		"summary": summary,
		"messages": compacted_messages,
		"context_used_before": max(0, used),
		"context_used_after": context_after,
		"context_budget": budget,
		"source": source,
		"automatic": automatic,
	}


func execute_slash_command(command_text: String) -> Dictionary:
	var text := command_text.strip_edges()
	if not text.begins_with("/"):
		return {"success": false, "handled": false, "error": "not_slash_command"}
	var without_slash := text.substr(1).strip_edges()
	var command := without_slash
	var args := ""
	var space_index := without_slash.find(" ")
	if space_index >= 0:
		command = without_slash.substr(0, space_index).strip_edges()
		args = without_slash.substr(space_index + 1).strip_edges()
	command = command.to_lower()
	match command:
		"mcp", "mcp-server":
			return _slash_result(true, command, "已打开 MCP 服务器状态。配置请进入设置。", {"view": "mcp"})
		"status", "state":
			return _slash_result(true, command, _status_command_message(), {
				"active_thread_id": active_thread_id,
				"context_used": context_used,
				"context_budget": context_budget,
				"agent_loop_status": agent_loop_status,
				"agent_loop_step_count": agent_loop_step_count,
			})
		"personality", "style":
			return _slash_result(true, command, "个性设置入口已记录；后续会接入 Codex 风格回应模式选择。", {"personality": args})
		"review", "code-review":
			return _slash_result(true, command, "代码审查入口已记录；后续会接入未暂存更改或分支比较审查。", {"review_target": args})
		"new", "newchat":
			var session := new_session()
			return _slash_result(true, command, "已创建新对话：%s。" % str(session.get("title", "")), session)
		"resume", "open":
			var resumed := _resume_session(args)
			return _slash_result(not resumed.is_empty(), command, "已恢复会话：%s。" % str(resumed.get("title", "")), resumed, "session_not_found")
		"side", "fork", "branch":
			var fork := fork_active_session()
			return _slash_result(not fork.is_empty(), command, "已创建当前会话分支：%s。" % str(fork.get("title", "")), fork)
		"archive":
			var archived := archive_active_session()
			return _slash_result(not archived.is_empty(), command, "已归档会话：%s。" % str(archived.get("title", "")), archived)
		"rename":
			var renamed := rename_active_session(args)
			return _slash_result(not renamed.is_empty(), command, "已重命名为：%s。" % str(renamed.get("title", "")), renamed, "missing_title")
		"pin":
			var pinned := toggle_pin_active_session()
			var state_text := "已置顶" if bool(pinned.get("pinned", false)) else "已取消置顶"
			return _slash_result(not pinned.is_empty(), command, "%s：%s。" % [state_text, str(pinned.get("title", ""))], pinned)
		"goal":
			var goal_result := _execute_goal_command(args)
			return _slash_result(true, command, str(goal_result.get("message", "目标已更新。")), goal_result)
		"ide", "context":
			var normalized_args := args.to_lower()
			if normalized_args in ["on", "true", "1", "开启"]:
				ide_context_enabled = true
			elif normalized_args in ["off", "false", "0", "关闭"]:
				ide_context_enabled = false
			else:
				ide_context_enabled = not ide_context_enabled
			return _slash_result(true, command, "IDE 上下文%s。" % ("已开启" if ide_context_enabled else "已关闭"), {"ide_context_enabled": ide_context_enabled})
		"compact":
			var compacted := compact_active_session()
			return _slash_result(bool(compacted.get("success", false)), command, "已压缩当前会话：移除 %d 条，保留 %d 条。" % [int(compacted.get("removed_count", 0)), int(compacted.get("kept_count", 0))], compacted, str(compacted.get("error", "compact_failed")))
		"feedback":
			return _slash_result(true, command, "反馈入口已记录；当前版本先保留本地审计，不发送外部反馈。", {})
		"model":
			if not args.strip_edges().is_empty():
				model = args.strip_edges()
			return _slash_result(true, command, "模型：%s。" % model, {"model": model})
		"reasoning", "effort":
			if args.to_lower() in ["low", "medium", "high", "xhigh"]:
				reasoning_effort = args.to_lower()
			elif args in ["低"]:
				reasoning_effort = "low"
			elif args in ["中"]:
				reasoning_effort = "medium"
			elif args in ["高"]:
				reasoning_effort = "high"
			return _slash_result(true, command, "推理模式：%s。" % reasoning_effort, {"reasoning_effort": reasoning_effort})
		"help":
			return _slash_result(true, command, "可用命令：/mcp、/status、/personality、/review、/side、/compact、/feedback、/model、/reasoning、/goal、/ide、/new、/resume、/archive、/rename、/pin。", {})
		_:
			return {"success": false, "handled": false, "command": command, "error": "unknown_slash_command"}


func _status_command_message() -> String:
	var remaining := max(context_budget - context_used, 0)
	var percent := int(round((float(remaining) / float(max(context_budget, 1))) * 100.0))
	var parts: Array[String] = [
		"会话：%s" % active_thread_id,
		"上下文：剩余 %d%%（已使用 %d / 共 %d）" % [percent, context_used, context_budget],
		"Agent：%s · %d 步" % [agent_loop_status, agent_loop_step_count],
	]
	return "\n".join(parts)


func slash_command_suggestions(query: String = "", limit: int = 6) -> Array[Dictionary]:
	var normalized := query.strip_edges().to_lower()
	if normalized.begins_with("/"):
		normalized = normalized.substr(1).strip_edges()
	var matches: Array[Dictionary] = []
	for item in slash_commands:
		var command := str(item.get("command", ""))
		var bare := command.trim_prefix("/").to_lower()
		var aliases: Array = item.get("aliases", [])
		var matched := normalized.is_empty() or bare.begins_with(normalized) or bare.find(normalized) >= 0
		if not matched:
			for alias in aliases:
				var alias_text := str(alias).to_lower()
				if alias_text.begins_with(normalized) or alias_text.find(normalized) >= 0:
					matched = true
					break
		if not matched:
			continue
		matches.append({
			"command": command,
			"args": str(item.get("args", "")),
			"title": _slash_command_title(item),
			"summary": str(item.get("summary", "")),
			"detail": _slash_command_detail(item),
			"aliases": aliases,
			"icon": item.get("icon", ["Tools"]),
			"insert_text": "%s%s" % [command, " " if not str(item.get("args", "")).is_empty() else ""],
		})
		if matches.size() >= limit:
			break
	return matches


func _slash_command_title(item: Dictionary) -> String:
	return str(item.get("title", str(item.get("command", ""))))


func _slash_command_detail(item: Dictionary) -> String:
	var command := str(item.get("command", ""))
	match command:
		"/ide":
			return "关闭 IDE 上下文" if ide_context_enabled else "打开 IDE 上下文"
		"/compact":
			var used_percent := 0
			if context_budget > 0:
				used_percent = int(round(float(context_used) / float(context_budget) * 100.0))
			return "压缩此会话的上下文（已使用 %d%%）" % used_percent
		"/goal":
			var goal := active_goal_record()
			if bool(goal.get("visible", false)):
				return "当前目标：%s · %s" % [str(goal.get("summary", "")), _goal_status_label(str(goal.get("status", "")))]
			return "设置当前会话目标"
		"/pin":
			var session := _active_session()
			return "取消固定当前会话" if bool(session.get("pinned", false)) else "固定当前会话"
		_:
			return str(item.get("summary", ""))


func active_messages() -> Array:
	var session := _active_session()
	if session.is_empty():
		return []
	var messages = session.get("messages", [])
	if messages is Array:
		var visible_messages: Array = []
		for message in messages:
			if not (message is Dictionary):
				continue
			var normalized: Dictionary = message
			if _is_local_transcript_noise(normalized):
				continue
			visible_messages.append(normalized)
		return visible_messages
	return []


func _is_local_transcript_noise(message: Dictionary) -> bool:
	var role := str(message.get("role", "")).strip_edges()
	var content := str(message.get("content", "")).strip_edges()
	var references = message.get("references", [])
	if role == "user" and references is Array and not (references as Array).is_empty():
		return false
	if content.is_empty():
		return true
	if role == "user" and _is_known_local_slash_command(content):
		return true
	if role != "assistant":
		return false
	var exact_noise := [
		"新对话已准备好。",
		"当前会话暂不需要压缩。",
		"当前没有可添加的推荐文件上下文。",
		"会话分支创建失败。",
		"会话归档失败。",
		"Agent 循环已达到最大步数，已停止自动推进。",
		"Agent 循环已达到最大步数，已停止自动续跑。",
	]
	if content in exact_noise:
		return true
	for prefix in [
		"已归档会话：",
		"已恢复会话：",
		"已创建新对话：",
		"已创建当前会话分支：",
		"已创建会话分支：",
		"已创建会话分支",
		"已重命名为：",
		"已置顶：",
		"已取消置顶：",
		"已添加文件上下文：",
		"已通过上下文菜单压缩当前会话：",
	]:
		if content.begins_with(prefix):
			return true
	return false


func _is_known_local_slash_command(content: String) -> bool:
	if not content.begins_with("/"):
		return false
	var command := content.substr(1).strip_edges().split(" ", false, 1)[0].to_lower()
	for item in slash_commands:
		var slash_command := str(item.get("command", "")).trim_prefix("/").to_lower()
		if command == slash_command:
			return true
		for alias in item.get("aliases", []):
			if command == str(alias).to_lower():
				return true
	return false


func append_message(role: String, content: String, metadata: Dictionary = {}) -> int:
	var session := _active_session()
	if session.is_empty():
		return -1
	var probe := {"role": role, "content": content}
	if not content.strip_edges().is_empty() and _is_local_transcript_noise(probe):
		return -1
	var messages = session.get("messages", [])
	if not (messages is Array):
		messages = []
	var message := {"role": role, "content": content}
	var turn_id := str(metadata.get("turn_id", active_turn_id))
	if not turn_id.is_empty():
		message["turn_id"] = turn_id
	for key in metadata.keys():
		if str(key) in ["role", "content"]:
			continue
		message[str(key)] = metadata[key]
	if role == "user":
		var references := active_composer_references()
		if not references.is_empty() and not message.has("references"):
			message["references"] = references
			clear_composer_references()
	messages.append(message)
	session["messages"] = messages
	return messages.size() - 1


func append_message_to_session(thread_id: String, role: String, content: String, metadata: Dictionary = {}) -> int:
	return _append_message_to_session(thread_id, role, content, metadata)


func replace_active_messages(messages: Array) -> Array:
	var session := _active_session()
	if session.is_empty():
		return []
	var normalized: Array[Dictionary] = []
	for item in messages:
		if not (item is Dictionary):
			continue
		var message: Dictionary = item.duplicate(true)
		message["role"] = str(message.get("role", "user"))
		message["content"] = str(message.get("content", ""))
		normalized.append(message)
	session["messages"] = normalized
	return normalized


func active_composer_references() -> Array[Dictionary]:
	var references: Array[Dictionary] = []
	for item in composer_references:
		if item is Dictionary:
			references.append((item as Dictionary).duplicate(true))
	return references


func add_composer_reference(kind: String, value: String, metadata: Dictionary = {}) -> Dictionary:
	var clean_kind := kind.strip_edges().to_lower()
	var clean_value := value.strip_edges()
	if clean_kind.is_empty() or clean_value.is_empty():
		return {}
	if clean_kind not in ["text", "image", "file", "source"]:
		clean_kind = "text"
	var record := {
		"id": "ref_%d_%d" % [Time.get_ticks_msec(), composer_references.size()],
		"kind": clean_kind,
		"value": clean_value,
		"title": str(metadata.get("title", _composer_reference_default_title(clean_kind))).strip_edges(),
		"source": str(metadata.get("source", "")).strip_edges(),
		"created_at": Time.get_datetime_string_from_system(),
	}
	for key in metadata.keys():
		if str(key) in ["id", "kind", "value"]:
			continue
		record[str(key)] = metadata[key]
	composer_references.append(record)
	return record.duplicate(true)


func remove_composer_reference(reference_id: String) -> Dictionary:
	var clean_id := reference_id.strip_edges()
	for index in range(composer_references.size()):
		var item: Dictionary = composer_references[index]
		if str(item.get("id", "")) == clean_id:
			composer_references.remove_at(index)
			return item
	return {}


func clear_composer_references() -> void:
	composer_references.clear()


func _composer_reference_default_title(kind: String) -> String:
	match kind:
		"image":
			return "图片"
		"file":
			return "文件"
		"source":
			return "资料"
		_:
			return "已选文本片段"


func queue_user_message(text: String, source: String = "send_action_menu") -> Dictionary:
	return queue_user_message_with_action(text, source, "plain")


func queue_user_message_with_action(text: String, source: String = "send_action_menu", action: String = "plain") -> Dictionary:
	var clean_text := text.strip_edges()
	if clean_text.is_empty():
		return {}
	var session := _active_session()
	if session.is_empty():
		return {}
	var records := _session_array(session, "queued_user_messages")
	var clean_action := action.strip_edges().to_lower()
	if clean_action not in ["plain", "parse_slash", "run_shell"]:
		clean_action = "plain"
	var record := {
		"id": _new_session_record_id(session, "queued_user_messages", "queued"),
		"text": clean_text,
		"action": clean_action,
		"status": "queued",
		"source": source,
		"session_id": active_thread_id,
		"turn_id": active_turn_id,
		"created_at": Time.get_datetime_string_from_system(),
		"updated_at": Time.get_datetime_string_from_system(),
	}
	records.append(record)
	session["queued_user_messages"] = records
	append_model_event("queued_user_message", record)
	return record


func active_queued_user_messages() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for item in _session_array(_active_session(), "queued_user_messages"):
		if item is Dictionary:
			records.append(item)
	return records


func next_queued_user_message() -> Dictionary:
	for record in active_queued_user_messages():
		if str(record.get("status", "")) == "queued":
			return record.duplicate(true)
	return {}


func mark_queued_user_message_submitted(message_id: String, turn_id: String = "") -> Dictionary:
	var clean_id := message_id.strip_edges()
	if clean_id.is_empty():
		return {}
	var session := _active_session()
	if session.is_empty():
		return {}
	var records := _session_array(session, "queued_user_messages")
	for index in range(records.size()):
		var item = records[index]
		if not (item is Dictionary):
			continue
		var record: Dictionary = item.duplicate(true)
		if str(record.get("id", "")) != clean_id:
			continue
		record["status"] = "submitted"
		record["submitted_at"] = Time.get_datetime_string_from_system()
		record["submitted_turn_id"] = turn_id if not turn_id.strip_edges().is_empty() else active_turn_id
		record["updated_at"] = Time.get_datetime_string_from_system()
		records[index] = record
		session["queued_user_messages"] = records
		upsert_model_event("queued_user_message", "id", clean_id, record)
		return record
	return {}


func cancel_queued_user_message(message_id: String, source: String = "send_action_menu") -> Dictionary:
	var clean_id := message_id.strip_edges()
	if clean_id.is_empty():
		return {}
	var session := _active_session()
	if session.is_empty():
		return {}
	var records := _session_array(session, "queued_user_messages")
	for index in range(records.size()):
		var item = records[index]
		if not (item is Dictionary):
			continue
		var record: Dictionary = item.duplicate(true)
		if str(record.get("id", "")) != clean_id:
			continue
		if str(record.get("status", "")) != "queued":
			return record
		record["status"] = "cancelled"
		record["cancelled_at"] = Time.get_datetime_string_from_system()
		record["cancelled_by"] = source
		record["updated_at"] = Time.get_datetime_string_from_system()
		records[index] = record
		session["queued_user_messages"] = records
		upsert_model_event("queued_user_message", "id", clean_id, record)
		return record
	return {}


func record_pending_guide_instruction(text: String, source: String = "send_action_menu") -> Dictionary:
	return record_pending_steer(text, source, "guide_instruction")


func record_pending_steer(instructions: String, source: String = "send_action_menu", kind: String = "guide_instruction") -> Dictionary:
	var clean_instructions := instructions.strip_edges()
	if clean_instructions.is_empty():
		return {}
	var session := _active_session()
	if session.is_empty():
		return {}
	var records := _session_array(session, "pending_steers")
	var record := {
		"id": _new_session_record_id(session, "pending_steers", "steer"),
		"kind": kind,
		"instructions": clean_instructions,
		"status": "pending",
		"source": source,
		"session_id": active_thread_id,
		"turn_id": active_turn_id,
		"created_at": Time.get_datetime_string_from_system(),
		"updated_at": Time.get_datetime_string_from_system(),
	}
	records.append(record)
	session["pending_steers"] = records
	upsert_model_event("pending_steer", "id", str(record.get("id", "")), record)
	return record


func active_pending_steers() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for item in _session_array(_active_session(), "pending_steers"):
		if item is Dictionary:
			records.append(item)
	return records


func active_pending_guide_instruction() -> Dictionary:
	var records := active_pending_steers()
	for i in range(records.size() - 1, -1, -1):
		var record: Dictionary = records[i]
		if str(record.get("status", "")) == "pending" and str(record.get("kind", "")) == "guide_instruction":
			return record
	return {}


func mark_pending_steer_submitted(steer_id: String, turn_id: String = "") -> Dictionary:
	var clean_id := steer_id.strip_edges()
	if clean_id.is_empty():
		return {}
	var session := _active_session()
	if session.is_empty():
		return {}
	var records := _session_array(session, "pending_steers")
	for index in range(records.size()):
		var item = records[index]
		if not (item is Dictionary):
			continue
		var record: Dictionary = item.duplicate(true)
		if str(record.get("id", "")) != clean_id:
			continue
		record["status"] = "submitted"
		record["submitted_at"] = Time.get_datetime_string_from_system()
		record["submitted_turn_id"] = turn_id if not turn_id.strip_edges().is_empty() else active_turn_id
		record["updated_at"] = Time.get_datetime_string_from_system()
		records[index] = record
		session["pending_steers"] = records
		upsert_model_event("pending_steer", "id", clean_id, record)
		return record
	return {}


func cancel_pending_steer(steer_id: String, source: String = "send_action_menu") -> Dictionary:
	var clean_id := steer_id.strip_edges()
	if clean_id.is_empty():
		return {}
	var session := _active_session()
	if session.is_empty():
		return {}
	var records := _session_array(session, "pending_steers")
	for index in range(records.size()):
		var item = records[index]
		if not (item is Dictionary):
			continue
		var record: Dictionary = item.duplicate(true)
		if str(record.get("id", "")) != clean_id:
			continue
		if str(record.get("status", "")) != "pending":
			return record
		record["status"] = "cancelled"
		record["cancelled_at"] = Time.get_datetime_string_from_system()
		record["cancelled_by"] = source
		record["updated_at"] = Time.get_datetime_string_from_system()
		records[index] = record
		session["pending_steers"] = records
		upsert_model_event("pending_steer", "id", clean_id, record)
		return record
	return {}


func update_message_content(index: int, content: String) -> void:
	var session := _active_session()
	if session.is_empty():
		return
	var messages = session.get("messages", [])
	if not (messages is Array):
		return
	if index < 0 or index >= messages.size():
		return
	var message = messages[index]
	if not (message is Dictionary):
		return
	message["content"] = content
	messages[index] = message
	session["messages"] = messages


func remove_message_at(index: int) -> void:
	var session := _active_session()
	if session.is_empty():
		return
	var messages = session.get("messages", [])
	if not (messages is Array):
		return
	if index < 0 or index >= messages.size():
		return
	messages.remove_at(index)
	session["messages"] = messages


func record_subagent_task(task: Dictionary) -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	var tasks_value = session.get("subagent_tasks", [])
	var tasks: Array = tasks_value if tasks_value is Array else []
	var now := Time.get_datetime_string_from_system()
	var record := {
		"id": str(task.get("id", _new_thread_id().replace("thread", "agent"))),
		"session_id": active_thread_id,
		"parent_thread_id": active_thread_id,
		"name": str(task.get("name", "子智能体")),
		"role": str(task.get("role", "explorer")),
		"branch": str(task.get("branch", "")),
		"readonly": bool(task.get("readonly", true)),
		"status": _normalize_subagent_status(str(task.get("status", "queued"))),
		"prompt": str(task.get("prompt", "")),
		"child_thread_id": str(task.get("child_thread_id", "")),
		"model": str(task.get("model", model)),
		"reasoning_effort": str(task.get("reasoning_effort", reasoning_effort)),
		"summary": str(task.get("summary", "")),
		"result": str(task.get("result", "")),
		"error": str(task.get("error", "")),
		"created_at": str(task.get("created_at", now)),
		"updated_at": now,
		"started_at": str(task.get("started_at", "")),
		"finished_at": str(task.get("finished_at", "")),
		"turn_id": str(task.get("turn_id", active_turn_id)),
		"source": str(task.get("source", "manual_subagent")),
		"agent_kind": str(task.get("agent_kind", "task")),
	}
	if str(record.get("created_at", "")).is_empty():
		record["created_at"] = now
	if str(record.get("status", "")) == "running" and str(record.get("started_at", "")).is_empty():
		record["started_at"] = now
	if str(record.get("status", "")) in ["done", "failed", "cancelled"] and str(record.get("finished_at", "")).is_empty():
		record["finished_at"] = now
	tasks.append(record)
	session["subagent_tasks"] = tasks
	append_model_event("subagent", record)
	return record


func start_subagent_child_session(task: Dictionary) -> Dictionary:
	var parent_session := _active_session()
	if parent_session.is_empty():
		return {}
	var parent_thread_id := active_thread_id
	var now := Time.get_datetime_string_from_system()
	var task_id := str(task.get("id", _new_thread_id().replace("thread", "agent")))
	var child_thread_id := str(task.get("child_thread_id", "")).strip_edges()
	if child_thread_id.is_empty():
		child_thread_id = _new_thread_id().replace("thread", "subagent_thread")
	var prompt := str(task.get("prompt", "请作为只读子智能体检查当前任务并返回简短结果。")).strip_edges()
	if prompt.is_empty():
		prompt = "请作为只读子智能体检查当前任务并返回简短结果。"
	var title := str(task.get("title", task.get("name", "子智能体会话"))).strip_edges()
	if title.is_empty():
		title = "子智能体会话"
	var child_session := {
		"id": child_thread_id,
		"title": title,
		"status": "active",
		"age": "现在",
		"action": "subagent_child",
		"archived": false,
		"pinned": false,
		"source": "subagent_child_session",
		"parent_thread_id": parent_thread_id,
		"task_id": task_id,
		"messages": [
			{"role": "assistant", "content": "子智能体会话已启动。", "turn_id": active_turn_id},
			{"role": "user", "content": prompt, "turn_id": active_turn_id},
		],
		"model_events": [],
		"subagent_tasks": [],
		"subagent_notifications": [],
		"subagent_edges": [],
		"queued_user_messages": [],
		"pending_steers": [],
		"active_goal": _empty_goal_record(child_thread_id),
		"last_compaction": {},
		"compaction_history": [],
		"created_at": now,
		"updated_at": now,
	}
	var existing_child_index := _find_session_index(child_thread_id)
	if existing_child_index >= 0:
		threads[existing_child_index] = child_session
	else:
		threads.push_front(child_session)
	select_thread(parent_thread_id)
	var record := record_subagent_task({
		"id": task_id,
		"name": str(task.get("name", "子智能体")),
		"role": str(task.get("role", "explorer")),
		"branch": str(task.get("branch", "child-session/local-replay")),
		"readonly": bool(task.get("readonly", true)),
		"status": "running",
		"prompt": prompt,
		"child_thread_id": child_thread_id,
		"model": str(task.get("model", model)),
		"reasoning_effort": str(task.get("reasoning_effort", reasoning_effort)),
		"summary": str(task.get("summary", "子会话已启动")),
		"source": "subagent_child_session",
	})
	var edge := upsert_subagent_edge(parent_thread_id, child_thread_id, task_id, "open")
	return {
		"task": record,
		"child_thread_id": child_thread_id,
		"child_session": child_session,
		"edge": edge,
	}


func complete_subagent_child_session(task_id: String, result: String, summary: String = "", source: String = "subagent_child_session") -> Dictionary:
	var task := _active_subagent_task(task_id)
	if task.is_empty():
		return {}
	var child_thread_id := str(task.get("child_thread_id", "")).strip_edges()
	var clean_result := result.strip_edges()
	var clean_summary := summary.strip_edges()
	if clean_summary.is_empty():
		clean_summary = _short_preview(clean_result, 160)
	if not child_thread_id.is_empty():
		_append_message_to_session(child_thread_id, "assistant", clean_result, {
			"turn_id": str(task.get("turn_id", active_turn_id)),
			"source": source,
		})
	return record_subagent_notification({
		"task_id": task_id,
		"child_thread_id": child_thread_id,
		"name": str(task.get("name", "子智能体")),
		"status": "completed",
		"summary": clean_summary,
		"result": clean_result,
		"source": source,
		"turn_id": str(task.get("turn_id", active_turn_id)),
	})


func fail_subagent_child_session(task_id: String, error: String, source: String = "subagent_child_session") -> Dictionary:
	var task := _active_subagent_task(task_id)
	if task.is_empty():
		return {}
	var child_thread_id := str(task.get("child_thread_id", "")).strip_edges()
	var clean_error := error.strip_edges()
	if clean_error.is_empty():
		clean_error = "subagent_child_session_failed"
	if not child_thread_id.is_empty():
		_append_message_to_session(child_thread_id, "assistant", "子智能体失败：%s" % clean_error, {
			"turn_id": str(task.get("turn_id", active_turn_id)),
			"source": source,
		})
	return record_subagent_notification({
		"task_id": task_id,
		"child_thread_id": child_thread_id,
		"name": str(task.get("name", "子智能体")),
		"status": "failed",
		"error": clean_error,
		"source": source,
		"turn_id": str(task.get("turn_id", active_turn_id)),
	})


func update_subagent_task(agent_id: String, status: String, patch: Dictionary = {}) -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	var tasks_value = session.get("subagent_tasks", [])
	if not (tasks_value is Array):
		return {}
	var tasks: Array = tasks_value
	var normalized_status := _normalize_subagent_status(status)
	for index in range(tasks.size()):
		if not (tasks[index] is Dictionary):
			continue
		var task: Dictionary = tasks[index].duplicate(true)
		if str(task.get("id", "")) != agent_id:
			continue
		task["status"] = normalized_status
		for key in patch.keys():
			if str(key) in ["id", "created_at"]:
				continue
			if str(key) == "source" and _is_delegated_subagent_source(str(task.get("source", ""))) and not _is_delegated_subagent_source(str(patch[key])):
				continue
			task[str(key)] = patch[key]
		task["updated_at"] = Time.get_datetime_string_from_system()
		if normalized_status == "running" and str(task.get("started_at", "")).is_empty():
			task["started_at"] = str(task.get("updated_at", ""))
		if normalized_status in ["done", "failed", "cancelled"] and str(task.get("finished_at", "")).is_empty():
			task["finished_at"] = str(task.get("updated_at", ""))
		tasks[index] = task
		session["subagent_tasks"] = tasks
		append_model_event("subagent", task)
		return task
	return {}


func record_subagent_notification(notification: Dictionary) -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	var notifications_value = session.get("subagent_notifications", [])
	var notifications: Array = notifications_value if notifications_value is Array else []
	var now := Time.get_datetime_string_from_system()
	var task_id := str(notification.get("task_id", notification.get("agent_id", ""))).strip_edges()
	var status := _normalize_subagent_notification_status(str(notification.get("status", "")))
	var record: Dictionary = {
		"id": str(notification.get("id", _new_session_record_id(session, "subagent_notifications", "subagent_notice"))),
		"session_id": active_thread_id,
		"parent_thread_id": str(notification.get("parent_thread_id", active_thread_id)),
		"child_thread_id": str(notification.get("child_thread_id", notification.get("thread_id", ""))),
		"task_id": task_id,
		"agent_id": str(notification.get("agent_id", task_id)),
		"name": str(notification.get("name", "子智能体")),
		"status": status,
		"summary": str(notification.get("summary", "")),
		"result": str(notification.get("result", "")),
		"error": str(notification.get("error", "")),
		"usage": notification.get("usage", {}),
		"source": str(notification.get("source", "subagent_notification")),
		"created_at": str(notification.get("created_at", now)),
		"received_at": now,
		"turn_id": str(notification.get("turn_id", active_turn_id)),
	}
	if str(record.get("created_at", "")).is_empty():
		record["created_at"] = now
	notifications.append(record)
	session["subagent_notifications"] = notifications
	var child_thread_id := str(record.get("child_thread_id", "")).strip_edges()
	if not child_thread_id.is_empty():
		var edge := upsert_subagent_edge(
			str(record.get("parent_thread_id", active_thread_id)),
			child_thread_id,
			task_id,
			_subagent_edge_status_for_notification(status)
		)
		record["edge_status"] = str(edge.get("status", ""))
		record["edge_id"] = str(edge.get("id", ""))
		notifications[notifications.size() - 1] = record
		session["subagent_notifications"] = notifications
	var task_status := _subagent_notification_task_status(status)
	if not task_id.is_empty():
		var patch: Dictionary = {
			"notification_id": str(record.get("id", "")),
			"notification_status": status,
			"notification_received_at": now,
			"child_thread_id": str(record.get("child_thread_id", "")),
			"edge_status": str(record.get("edge_status", "")),
			"edge_id": str(record.get("edge_id", "")),
			"notification_source": str(record.get("source", "")),
		}
		var summary := str(record.get("summary", "")).strip_edges()
		var result := str(record.get("result", "")).strip_edges()
		var error := str(record.get("error", "")).strip_edges()
		if not summary.is_empty():
			patch["summary"] = summary
		if not result.is_empty():
			patch["result"] = result
		if not error.is_empty():
			patch["error"] = error
		update_subagent_task(task_id, task_status, patch)
	append_model_event("subagent_notification", record)
	return record


func upsert_subagent_edge(parent_thread_id: String, child_thread_id: String, task_id: String = "", status: String = "open") -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	var parent := parent_thread_id.strip_edges()
	if parent.is_empty():
		parent = active_thread_id
	var child := child_thread_id.strip_edges()
	if child.is_empty():
		return {}
	var clean_task_id := task_id.strip_edges()
	var normalized_status := _normalize_subagent_edge_status(status)
	var edges_value = session.get("subagent_edges", [])
	var edges: Array = edges_value if edges_value is Array else []
	var now := Time.get_datetime_string_from_system()
	for index in range(edges.size()):
		if not (edges[index] is Dictionary):
			continue
		var edge: Dictionary = edges[index].duplicate(true)
		if str(edge.get("child_thread_id", "")) != child:
			continue
		edge["parent_thread_id"] = parent
		if not clean_task_id.is_empty():
			edge["task_id"] = clean_task_id
		edge["status"] = normalized_status
		edge["updated_at"] = now
		edges[index] = edge
		session["subagent_edges"] = edges
		append_model_event("subagent_edge", edge)
		return edge
	var edge: Dictionary = {
		"id": _new_session_record_id(session, "subagent_edges", "subagent_edge"),
		"session_id": active_thread_id,
		"parent_thread_id": parent,
		"child_thread_id": child,
		"task_id": clean_task_id,
		"status": normalized_status,
		"created_at": now,
		"updated_at": now,
		"turn_id": active_turn_id,
	}
	edges.append(edge)
	session["subagent_edges"] = edges
	append_model_event("subagent_edge", edge)
	return edge


func set_subagent_edge_status(child_thread_id: String, status: String) -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	var child := child_thread_id.strip_edges()
	if child.is_empty():
		return {}
	var edges_value = session.get("subagent_edges", [])
	var edges: Array = edges_value if edges_value is Array else []
	var normalized_status := _normalize_subagent_edge_status(status)
	for index in range(edges.size()):
		if not (edges[index] is Dictionary):
			continue
		var edge: Dictionary = edges[index].duplicate(true)
		if str(edge.get("child_thread_id", "")) != child:
			continue
		edge["status"] = normalized_status
		edge["updated_at"] = Time.get_datetime_string_from_system()
		edges[index] = edge
		session["subagent_edges"] = edges
		append_model_event("subagent_edge", edge)
		return edge
	return {}


func cancel_subagent_task(agent_id: String, source: String = "automation") -> Dictionary:
	var task := _active_subagent_task(agent_id)
	if task.is_empty():
		return {}
	var status := _normalize_subagent_status(str(task.get("status", "")))
	if not (status in ["queued", "running", "interrupted"]):
		return task
	var now := Time.get_datetime_string_from_system()
	return update_subagent_task(agent_id, "cancelled", {
		"cancelled_at": now,
		"cancelled_by": source,
		"handoff_available": false,
	})


func handoff_subagent_task_result(agent_id: String, summary: String = "", source: String = "automation") -> Dictionary:
	var task := _active_subagent_task(agent_id)
	if task.is_empty():
		return {}
	var status := _normalize_subagent_status(str(task.get("status", "")))
	if not (status in ["done", "failed", "cancelled", "interrupted"]):
		return task
	var clean_summary := summary.strip_edges()
	if clean_summary.is_empty():
		clean_summary = str(task.get("result", task.get("summary", ""))).strip_edges()
	var now := Time.get_datetime_string_from_system()
	return update_subagent_task(agent_id, status, {
		"handoff_status": "handed_off",
		"handoff_summary": clean_summary,
		"handoff_at": now,
		"handoff_source": source,
		"handoff_available": false,
	})


func _active_subagent_task(agent_id: String) -> Dictionary:
	if agent_id.strip_edges().is_empty():
		return {}
	for item in active_subagent_tasks():
		if item is Dictionary and str(item.get("id", "")) == agent_id:
			return item.duplicate(true)
	return {}


func next_cancellable_subagent_task() -> Dictionary:
	var tasks := active_subagent_tasks()
	for index in range(tasks.size() - 1, -1, -1):
		var item = tasks[index]
		if not (item is Dictionary):
			continue
		var task: Dictionary = item
		var status := _normalize_subagent_status(str(task.get("status", "")))
		if status in ["queued", "running", "interrupted"]:
			return task.duplicate(true)
	return {}


func next_handoffable_subagent_task() -> Dictionary:
	var tasks := active_subagent_tasks()
	for index in range(tasks.size() - 1, -1, -1):
		var item = tasks[index]
		if not (item is Dictionary):
			continue
		var task: Dictionary = item
		if str(task.get("handoff_status", "")) == "handed_off":
			continue
		var status := _normalize_subagent_status(str(task.get("status", "")))
		if status in ["done", "failed", "cancelled", "interrupted"]:
			return task.duplicate(true)
	return {}


func active_subagent_tasks() -> Array:
	var session := _active_session()
	if session.is_empty():
		return []
	var tasks = session.get("subagent_tasks", [])
	if not (tasks is Array):
		return []
	var edges = session.get("subagent_edges", [])
	var child_thread_ids := {}
	if edges is Array:
		for edge_item in edges:
			if not (edge_item is Dictionary):
				continue
			var child_id := str(edge_item.get("child_thread_id", "")).strip_edges()
			if not child_id.is_empty():
				child_thread_ids[child_id] = true
	var active_tasks: Array = []
	for item in tasks:
		if not (item is Dictionary):
			continue
		var task: Dictionary = item
		var source := str(task.get("source", "")).strip_edges()
		var child_thread_id := str(task.get("child_thread_id", "")).strip_edges()
		var has_child_thread_edge := not child_thread_id.is_empty() and child_thread_ids.has(child_thread_id)
		var delegated_source := _is_delegated_subagent_source(source)
		if delegated_source or has_child_thread_edge:
			active_tasks.append(task)
	return active_tasks


func _is_delegated_subagent_source(source: String) -> bool:
	return source.strip_edges() in ["subagent_child_session", "codex_delegate", "subagent"]


func active_subagent_notifications() -> Array:
	var session := _active_session()
	if session.is_empty():
		return []
	var notifications = session.get("subagent_notifications", [])
	if notifications is Array:
		return notifications
	return []


func active_subagent_edges() -> Array:
	var session := _active_session()
	if session.is_empty():
		return []
	var edges = session.get("subagent_edges", [])
	if edges is Array:
		return edges
	return []


func subagent_children(parent_thread_id: String = "", status_filter: String = "") -> Array[Dictionary]:
	var parent := parent_thread_id.strip_edges()
	if parent.is_empty():
		parent = active_thread_id
	var filter := _normalize_optional_subagent_edge_filter(status_filter)
	var children: Array[Dictionary] = []
	for item in active_subagent_edges():
		if not (item is Dictionary):
			continue
		var edge: Dictionary = item
		if str(edge.get("parent_thread_id", "")) != parent:
			continue
		if not filter.is_empty() and _normalize_subagent_edge_status(str(edge.get("status", ""))) != filter:
			continue
		children.append(edge.duplicate(true))
	return children


func subagent_descendants(root_thread_id: String = "", status_filter: String = "") -> Array[Dictionary]:
	var root := root_thread_id.strip_edges()
	if root.is_empty():
		root = active_thread_id
	var filter := _normalize_optional_subagent_edge_filter(status_filter)
	var descendants: Array[Dictionary] = []
	var queue: Array[String] = [root]
	var seen: Dictionary = {root: true}
	while not queue.is_empty():
		var parent: String = queue.pop_front()
		for edge in subagent_children(parent, filter):
			var child := str(edge.get("child_thread_id", "")).strip_edges()
			if child.is_empty() or seen.has(child):
				continue
			seen[child] = true
			descendants.append(edge.duplicate(true))
			queue.append(child)
	return descendants


func append_model_event(kind: String, data: Dictionary) -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	var events = session.get("model_events", [])
	if not (events is Array):
		events = []
	var event_data := data.duplicate(true)
	if not active_turn_id.is_empty() and str(event_data.get("turn_id", "")).is_empty():
		event_data["turn_id"] = active_turn_id
	var event := {
		"id": _new_thread_id().replace("thread", "event"),
		"kind": kind,
		"created_at": Time.get_datetime_string_from_system(),
		"data": _redact_model_event_data(event_data),
	}
	events.append(event)
	session["model_events"] = events
	return event


func upsert_model_event(kind: String, match_key: String, match_value: String, data: Dictionary) -> Dictionary:
	if match_key.strip_edges().is_empty() or match_value.strip_edges().is_empty():
		return append_model_event(kind, data)
	var session := _active_session()
	if session.is_empty():
		return {}
	var events = session.get("model_events", [])
	if not (events is Array):
		events = []
	for index in range(events.size()):
		if not (events[index] is Dictionary):
			continue
		var event: Dictionary = events[index]
		if str(event.get("kind", "")) != kind:
			continue
		var event_data: Dictionary = event.get("data", {})
		if str(event_data.get(match_key, "")) != match_value:
			continue
		var merged := event_data.duplicate(true)
		for key in data.keys():
			merged[key] = data[key]
		merged["updated_at"] = Time.get_datetime_string_from_system()
		if not active_turn_id.is_empty() and str(merged.get("turn_id", "")).is_empty():
			merged["turn_id"] = active_turn_id
		event["data"] = _redact_model_event_data(merged)
		events[index] = event
		session["model_events"] = events
		return event
	return append_model_event(kind, data)


func record_tool_calls(tool_calls: Array, source_event_id: String = "") -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for item in _coalesce_model_tool_calls(tool_calls):
		if not (item is Dictionary):
			continue
		if _is_repeated_terminal_tool_call(item):
			append_model_event("tool_call_cycle_blocked", {
				"status": "blocked",
				"source_event_id": source_event_id,
				"name": str((item as Dictionary).get("name", "")),
				"arguments": _normalize_tool_call_arguments((item as Dictionary).get("arguments", {})),
				"message": "Repeated terminal tool call in the same turn was blocked to avoid an automatic tool loop.",
			})
			continue
		var arguments = item.get("arguments", {})
		var record := {
			"id": str(item.get("id", _new_thread_id().replace("thread", "tool_call"))),
			"kind": "tool_call",
			"created_at": Time.get_datetime_string_from_system(),
			"turn_id": active_turn_id,
			"status": "pending",
			"decision": "",
			"decided_at": "",
			"source_event_id": source_event_id,
			"name": str(item.get("name", "")),
			"arguments": _normalize_tool_call_arguments(arguments),
		}
		record["projection_key"] = _tool_call_projection_key(record)
		var response_id := str(item.get("response_id", ""))
		if not response_id.is_empty():
			record["response_id"] = response_id
		if str(record.get("name", "")) == "godex_change_review_summary":
			var review_service := GitChangeSummaryService.new()
			var summary: Dictionary = review_service.build_summary(record.get("arguments", {}))
			set_change_review_summary(summary)
			record["status"] = "completed"
			record["decision"] = "auto"
			record["result"] = {
				"file_count": int(summary.get("file_count", 0)),
				"added": int(summary.get("added", 0)),
				"removed": int(summary.get("removed", 0)),
			}
		elif str(record.get("name", "")) == "godex_update_progress":
			var progress := set_progress_items(record.get("arguments", {}).get("items", []))
			record["status"] = "completed"
			record["decision"] = "auto"
			record["result"] = {
				"message": "Progress items updated.",
				"count": progress.size(),
			}
		var event := upsert_model_event("tool_call", "id", str(record.get("id", "")), record)
		var stored_record: Dictionary = event.get("data", record)
		if str(record.get("name", "")) in ["godex_command_request", "exec_command"]:
			var command_capability := CommandCapability.new()
			command_capability.enabled = command_enabled
			command_capability.shell = command_shell
			var command_arguments: Dictionary = record.get("arguments", {})
			command_capability.working_directory = str(command_arguments.get("workdir", command_arguments.get("working_directory", command_working_directory)))
			command_capability.timeout_sec = _exec_command_timeout_sec(command_arguments)
			var command_request := command_capability.build_request(str(command_arguments.get("command", "")))
			command_request["id"] = "command_%s" % str(record.get("id", ""))
			command_request["blocked"] = bool(command_request.get("blocked", false)) or not command_enabled
			record_command_run({
				"id": str(command_request.get("id", "")),
				"command": str(command_request.get("command", "")),
				"shell": str(command_request.get("shell", command_shell)),
				"working_directory": str(command_request.get("working_directory", "")),
				"timeout_sec": int(command_request.get("timeout_sec", command_timeout_sec)),
				"requires_approval": true,
				"blocked": bool(command_request.get("blocked", false)),
				"source": str(record.get("name", "")),
				"tool_call_id": str(record.get("id", "")),
			}, "blocked" if bool(command_request.get("blocked", false)) else "queued")
		elif str(record.get("name", "")) == "write_stdin":
			record["status"] = "failed"
			record["decision"] = "auto"
			record["result"] = {
				"error": "interactive_command_sessions_not_available",
				"message": "write_stdin requires a live exec session; Godex has not implemented the interactive process manager yet.",
			}
			event = upsert_model_event("tool_call", "id", str(record.get("id", "")), record)
			stored_record = event.get("data", record)
		records.append(stored_record)
	return records


func _coalesce_model_tool_calls(tool_calls: Array) -> Array:
	var coalesced: Array = []
	var context_index := -1
	var selected_context: Dictionary = {}
	for item in tool_calls:
		if not (item is Dictionary):
			continue
		var call: Dictionary = item
		if str(call.get("name", "")) != "godex_mcp_context":
			coalesced.append(call)
			continue
		if context_index < 0:
			context_index = coalesced.size()
			selected_context = call
			coalesced.append(call)
			continue
		if _mcp_context_call_rank(call) > _mcp_context_call_rank(selected_context):
			selected_context = call
			coalesced[context_index] = call
	return coalesced


func _mcp_context_call_rank(call: Dictionary) -> int:
	var arguments = call.get("arguments", {})
	var scope := "summary"
	if arguments is Dictionary:
		scope = str(arguments.get("scope", "summary")).strip_edges().to_lower()
	else:
		var parsed = JSON.parse_string(str(arguments))
		if parsed is Dictionary:
			scope = str(parsed.get("scope", "summary")).strip_edges().to_lower()
	match scope:
		"summary":
			return 50
		"scene":
			return 40
		"scripts":
			return 30
		"runtime":
			return 20
		"logs":
			return 10
		_:
			return 0


func _is_repeated_terminal_tool_call(item: Dictionary) -> bool:
	var active_turn := str(active_turn_id).strip_edges()
	if active_turn.is_empty():
		return false
	var name := str(item.get("name", "")).strip_edges()
	if name.is_empty():
		return false
	var arguments := _normalize_tool_call_arguments(item.get("arguments", {}))
	var fingerprint := _tool_call_fingerprint(name, arguments)
	for event in active_model_events():
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("turn_id", "")) != active_turn:
			continue
		if str(data.get("status", "")) not in ["succeeded", "completed"]:
			continue
		if _tool_call_fingerprint(str(data.get("name", "")), data.get("arguments", {})) == fingerprint:
			return true
	return false


func _tool_call_fingerprint(name: String, arguments) -> String:
	var normalized_arguments = arguments
	if not (normalized_arguments is Dictionary):
		normalized_arguments = _normalize_tool_call_arguments(arguments)
	return "%s|%s" % [name.strip_edges(), JSON.stringify(normalized_arguments)]


func _exec_command_timeout_sec(arguments: Dictionary) -> int:
	if arguments.has("timeout_sec"):
		return int(arguments.get("timeout_sec", command_timeout_sec))
	if arguments.has("timeout_ms"):
		return ceili(float(arguments.get("timeout_ms", command_timeout_sec * 1000)) / 1000.0)
	return command_timeout_sec


func _tool_call_projection_key(data: Dictionary) -> String:
	var tool_call_id := str(data.get("id", data.get("tool_call_id", ""))).strip_edges()
	if not tool_call_id.is_empty():
		return "tool_call|%s" % tool_call_id
	var turn_id := str(data.get("turn_id", active_turn_id)).strip_edges()
	var batch_key := _tool_call_batch_key(data)
	var name := str(data.get("name", "")).strip_edges()
	var arguments = data.get("arguments", {})
	var args_text := ""
	if arguments is Dictionary:
		args_text = JSON.stringify(arguments)
	else:
		args_text = str(arguments)
	if args_text.length() > 240:
		args_text = args_text.left(240)
	return "tool_call|%s|%s|%s|%s" % [turn_id, batch_key, name, args_text]


func _tool_call_batch_key(data: Dictionary) -> String:
	var source_event_id := str(data.get("source_event_id", "")).strip_edges()
	if not source_event_id.is_empty():
		return source_event_id
	var turn_id := str(data.get("turn_id", active_turn_id)).strip_edges()
	if not turn_id.is_empty():
		return turn_id
	var tool_call_id := str(data.get("id", data.get("tool_call_id", ""))).strip_edges()
	return tool_call_id if not tool_call_id.is_empty() else "__unbound_tools"


func pending_tool_calls() -> Array[Dictionary]:
	var pending: Array[Dictionary] = []
	for event in active_model_events():
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("status", "")) == "pending":
			pending.append(data)
	return pending


func unresolved_tool_calls(except_tool_call_id: String = "") -> Array[Dictionary]:
	var unresolved: Array[Dictionary] = []
	for event in active_model_events():
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) == except_tool_call_id:
			continue
		var status := str(data.get("status", ""))
		if status in ["pending", "approved", "dispatch_ready", "executing"]:
			unresolved.append(data)
	return unresolved


func decide_tool_call(tool_call_id: String, decision: String) -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) != tool_call_id:
			continue
		data["status"] = "approved" if decision == "approve" else "rejected"
		data["decision"] = decision
		data["decided_at"] = Time.get_datetime_string_from_system()
		event["data"] = data
		return data
	return {}


func update_tool_call_status(tool_call_id: String, status: String, result: Dictionary = {}) -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) != tool_call_id:
			continue
		data["status"] = status
		data["updated_at"] = Time.get_datetime_string_from_system()
		if not result.is_empty():
			data["result"] = result.duplicate(true)
		event["data"] = data
		return data
	return {}


func update_tool_call_continuation(tool_call_id: String, status: String, continuation: Dictionary = {}) -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) != tool_call_id:
			continue
		var record := continuation.duplicate(true)
		record["status"] = status
		record["updated_at"] = Time.get_datetime_string_from_system()
		data["continuation"] = record
		event["data"] = data
		return data
	return {}


func set_tool_call_expanded(tool_call_id: String, expanded: bool) -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) != tool_call_id:
			continue
		data["expanded"] = expanded
		event["data"] = data
		return data
	return {}


func set_tool_batch_expanded(batch_id: String, expanded: bool) -> void:
	var clean_id := batch_id.strip_edges()
	if clean_id.is_empty():
		return
	tool_batch_expanded[clean_id] = expanded


func update_partial_tool_call(partial: Dictionary) -> Dictionary:
	var partial_id := str(partial.get("id", ""))
	if partial_id.is_empty():
		return {}
	var record: Dictionary = partial_tool_calls.get(partial_id, {})
	record["id"] = partial_id
	record["name"] = str(partial.get("name", record.get("name", "工具调用")))
	record["arguments"] = str(partial.get("arguments", record.get("arguments", "")))
	record["status"] = str(partial.get("status", "streaming"))
	record["turn_id"] = str(partial.get("turn_id", active_turn_id))
	record["source_event_id"] = str(partial.get("source_event_id", record.get("source_event_id", "")))
	record["batch_key"] = str(partial.get("batch_key", record.get("batch_key", "")))
	record["expanded"] = bool(partial.get("expanded", record.get("expanded", true)))
	record["updated_at"] = Time.get_datetime_string_from_system()
	partial_tool_calls[partial_id] = record
	return record


func complete_partial_tool_call(partial_id: String) -> Dictionary:
	var record: Dictionary = partial_tool_calls.get(partial_id, {})
	if not record.is_empty():
		partial_tool_calls.erase(partial_id)
	return record


func clear_partial_tool_calls() -> void:
	partial_tool_calls.clear()


func record_stream_step(title: String, status: String) -> Dictionary:
	return append_model_event("stream_step", {
		"title": title,
		"status": status,
	})


func set_progress_items(items: Array) -> Array[Dictionary]:
	progress_items = _normalize_progress_items(items)
	var session := _active_session()
	if not session.is_empty():
		session["progress_items"] = progress_items.duplicate(true)
	append_model_event("progress_update", {
		"status": "updated",
		"count": progress_items.size(),
	})
	return progress_items.duplicate(true)


func clear_progress_items() -> void:
	progress_items.clear()
	var session := _active_session()
	if not session.is_empty():
		session["progress_items"] = []


func _normalize_progress_items(items) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if not (items is Array):
		return normalized
	for item in items:
		if not (item is Dictionary):
			continue
		var source: Dictionary = item
		var title := str(source.get("title", source.get("text", ""))).strip_edges()
		if title.is_empty():
			continue
		normalized.append({
			"title": title,
			"detail": str(source.get("detail", source.get("description", ""))).strip_edges(),
			"done": bool(source.get("done", false)),
		})
		if normalized.size() >= 8:
			break
	return normalized


func record_command_run(command_request: Dictionary, status: String = "queued", result: Dictionary = {}) -> Dictionary:
	var record := {
		"id": str(command_request.get("id", _new_thread_id().replace("thread", "command"))),
		"command": str(command_request.get("command", "")),
		"shell": str(command_request.get("shell", command_shell)),
		"working_directory": str(command_request.get("working_directory", command_working_directory)),
		"timeout_sec": int(command_request.get("timeout_sec", command_timeout_sec)),
		"status": status,
		"requires_approval": bool(command_request.get("requires_approval", true)),
		"blocked": bool(command_request.get("blocked", false)),
		"source": str(command_request.get("source", "")),
		"created_at": Time.get_datetime_string_from_system(),
		"expanded": bool(command_request.get("expanded", false)),
		"turn_id": str(command_request.get("turn_id", active_turn_id)),
	}
	record["timeline"] = [_command_run_timeline_event(status, result)]
	if not result.is_empty():
		record["result"] = _sanitize_command_result_for_storage(result)
	var event := append_model_event("command_run", record)
	var data: Dictionary = event.get("data", {})
	data["event_id"] = str(event.get("id", ""))
	return data


func update_command_run_status(command_id: String, status: String, result: Dictionary = {}) -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) != command_id:
			continue
		data["status"] = status
		data["updated_at"] = Time.get_datetime_string_from_system()
		data["timeline"] = _append_command_run_timeline(data, status, result)
		if not result.is_empty():
			data["result"] = _merge_command_result_for_storage(data, result)
		event["data"] = data
		return data
	return {}


func command_run_by_id(command_id: String) -> Dictionary:
	return _find_command_run(command_id).duplicate(true)


func append_command_run_chunk(command_id: String, stream: String, text: String, metadata: Dictionary = {}) -> Dictionary:
	var normalized_stream := stream.strip_edges().to_lower()
	if normalized_stream not in ["stdout", "stderr"]:
		return {"success": false, "error": "invalid_stream", "message": "Command output stream must be stdout or stderr."}
	for event in active_model_events():
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) != command_id:
			continue
		if str(data.get("status", "")) != "running":
			return {"success": false, "error": "invalid_status", "command_run": data.duplicate(true)}
		var chunks := _append_command_output_chunk(data, normalized_stream, text, metadata)
		data["output_chunks"] = chunks
		data["result"] = _merge_command_chunk_result(data, normalized_stream, str(chunks[chunks.size() - 1].get("text", "")))
		data["updated_at"] = Time.get_datetime_string_from_system()
		event["data"] = data
		return {
			"success": true,
			"chunk": chunks[chunks.size() - 1].duplicate(true),
			"command_run": data,
		}
	return {"success": false, "error": "not_found"}


func next_queued_command_run() -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("status", "")) == "queued":
			return data
	return {}


func next_approved_command_run() -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("status", "")) == "approved":
			return data
	return {}


func next_cancellable_command_run() -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("status", "")) in ["queued", "approval_required", "approved", "running"]:
			return data
	return {}


func request_next_command_run_approval() -> Dictionary:
	var command_run := next_queued_command_run()
	if command_run.is_empty():
		return {"success": false, "error": "no_queued_command", "message": "没有等待审批的命令请求。"}
	var approval := request_command_run_approval(str(command_run.get("id", "")))
	if approval.is_empty():
		return {"success": false, "error": "approval_failed", "message": "命令审批请求创建失败。"}
	var updated := _find_command_run(str(command_run.get("id", "")))
	return {
		"success": str(updated.get("status", "")) == "approval_required",
		"command_id": str(command_run.get("id", "")),
		"approval": approval,
		"command_run": updated,
		"message": "命令审批已创建。",
	}


func execute_next_approved_command_run(runner: Callable = Callable()) -> Dictionary:
	var command_run := next_approved_command_run()
	if command_run.is_empty():
		return {"success": false, "error": "no_approved_command", "message": "没有已批准且等待执行的命令。"}
	var updated := execute_command_run_with_runner(str(command_run.get("id", "")), runner)
	if runner.is_valid():
		var status := str(updated.get("status", ""))
		return {
			"success": status == "completed",
			"error": "" if status == "completed" else status,
			"command_id": str(command_run.get("id", "")),
			"command_run": updated,
			"message": "命令执行完成。" if status == "completed" else "命令执行结束：%s。" % status,
		}
	return {
		"success": false,
		"error": "runner_unavailable",
		"command_id": str(command_run.get("id", "")),
		"command_run": updated,
		"message": "命令执行器尚未接入，已保留审计状态。",
	}


func cancel_command_run(command_id: String) -> Dictionary:
	var command_run := _find_command_run(command_id)
	if command_run.is_empty():
		return {"success": false, "error": "not_found"}
	var status := str(command_run.get("status", ""))
	if status in ["completed", "failed", "timed_out", "cancelled", "rejected", "blocked"]:
		return {"success": false, "error": "terminal_status", "command_run": command_run}
	_cancel_command_run_approvals(command_id)
	var updated := update_command_run_status(command_id, "cancelled", {"stderr": "Command cancelled by user."})
	return {
		"success": true,
		"command_id": command_id,
		"command_run": updated,
	}


func request_command_run_approval(command_id: String) -> Dictionary:
	var command_run := _find_command_run(command_id)
	if command_run.is_empty():
		return {}
	var safety := _command_run_safety(command_run)
	if bool(command_run.get("blocked", false)) or str(command_run.get("status", "")) == "blocked" or bool(safety.get("blocked", false)):
		return update_command_run_status(command_id, "blocked", {"stderr": _command_blocked_message(safety)})
	if not command_enabled:
		return update_command_run_status(command_id, "blocked", {"stderr": "Command capability is disabled."})
	var current_status := str(command_run.get("status", ""))
	if current_status in ["approved", "running", "completed", "failed", "timed_out", "cancelled", "rejected"]:
		return command_run
	var existing_approval := _find_command_run_approval(command_id)
	if not existing_approval.is_empty():
		return update_command_run_status(command_id, "approval_required", {
			"approval_id": str(existing_approval.get("id", "")),
			"stderr": "Waiting for command approval.",
		})
	var checkpoint := record_approval_checkpoint({
		"action": "command",
		"summary": "Run `%s` in %s" % [str(command_run.get("command", "")), str(command_run.get("shell", ""))],
		"risk": "high",
		"requires_approval": true,
		"command_id": command_id,
		"command": str(command_run.get("command", "")),
		"shell": str(command_run.get("shell", "")),
		"working_directory": str(command_run.get("working_directory", "")),
		"timeout_sec": int(command_run.get("timeout_sec", command_timeout_sec)),
		"fingerprint": _command_run_fingerprint(command_run),
	})
	update_command_run_status(command_id, "approval_required", {
		"approval_id": str(checkpoint.get("id", "")),
		"stderr": "Waiting for command approval.",
	})
	return checkpoint


func decide_command_run_approval(command_id: String, decision: String) -> Dictionary:
	for record in approval_records:
		if str(record.get("command_id", "")) != command_id:
			continue
		if str(record.get("status", "")) != "pending":
			return record
		record["status"] = "approved" if decision == "approve" else "rejected"
		record["decision"] = decision
		record["decided_at"] = Time.get_datetime_string_from_system()
		update_command_run_status(command_id, str(record.get("status", "")), {
			"approval_id": str(record.get("id", "")),
			"stderr": "" if decision == "approve" else "Command approval rejected.",
		})
		return record
	return {}


func execute_command_run_with_runner(command_id: String, runner: Callable) -> Dictionary:
	var command_run := _find_command_run(command_id)
	if command_run.is_empty():
		return {}
	var safety := _command_run_safety(command_run)
	var status := str(command_run.get("status", ""))
	if bool(command_run.get("blocked", false)) or status == "blocked" or bool(safety.get("blocked", false)):
		return update_command_run_status(command_id, "blocked", {"stderr": _command_blocked_message(safety)})
	if status in ["running", "completed", "failed", "timed_out", "cancelled", "rejected"]:
		return command_run
	if not command_enabled:
		return update_command_run_status(command_id, "blocked", {"stderr": "Command capability is disabled."})
	var approval := _find_command_run_approval(command_id)
	if approval.is_empty() or str(approval.get("status", "")) != "approved":
		request_command_run_approval(command_id)
		return _find_command_run(command_id)
	if str(approval.get("fingerprint", "")) != _command_run_fingerprint(command_run):
		return update_command_run_status(command_id, "blocked", {"stderr": "Command changed after approval."})
	if _has_running_command_run(command_id):
		return update_command_run_status(command_id, "blocked", {"stderr": "Another command is already running."})
	if not runner.is_valid():
		return update_command_run_status(command_id, "failed", {"exit_code": -1, "stderr": "Command runner is not available."})
	update_command_run_status(command_id, "running", {"approval_id": str(approval.get("id", ""))})
	var raw_result = runner.call(command_run.duplicate(true))
	var result := _normalize_command_result(raw_result)
	var final_status := "completed"
	if bool(result.get("timed_out", false)):
		final_status = "timed_out"
	elif int(result.get("exit_code", 0)) != 0:
		final_status = "failed"
	return update_command_run_status(command_id, final_status, result)


func set_command_run_expanded(command_id: String, expanded: bool) -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) != command_id:
			continue
		data["expanded"] = expanded
		event["data"] = data
		return data
	return {}


func active_transcript_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	var messages := active_messages()
	var turn_message_counts: Dictionary = {}
	var complete_tool_call_ids: Dictionary = {}
	for event in active_model_events():
		if not (event is Dictionary) or str(event.get("kind", "")) != "tool_call":
			continue
		var tool_data: Dictionary = event.get("data", {})
		var tool_id := str(tool_data.get("id", ""))
		if not tool_id.is_empty():
			complete_tool_call_ids[tool_id] = true
	for message in messages:
		if not (message is Dictionary):
			continue
		var message_turn_id := str(message.get("turn_id", ""))
		if message_turn_id.is_empty():
			continue
		turn_message_counts[message_turn_id] = int(turn_message_counts.get(message_turn_id, 0)) + 1
	var event_items_by_turn: Dictionary = {}
	var unbound_event_items: Array[Dictionary] = []
	for event in active_model_events():
		if not (event is Dictionary):
			continue
		var item := _model_event_transcript_item(event)
		if item.is_empty():
			continue
		var event_turn_id := str(item.get("turn_id", ""))
		if event_turn_id.is_empty() or not turn_message_counts.has(event_turn_id):
			unbound_event_items = _append_projected_transcript_item(unbound_event_items, item)
			continue
		if not event_items_by_turn.has(event_turn_id):
			event_items_by_turn[event_turn_id] = []
		var turn_event_items: Array = event_items_by_turn[event_turn_id]
		turn_event_items = _append_projected_transcript_item(turn_event_items, item)
		event_items_by_turn[event_turn_id] = turn_event_items
	for key in partial_tool_calls.keys():
		var partial = partial_tool_calls[key]
		if not (partial is Dictionary):
			continue
		var partial_id := str(partial.get("id", ""))
		if complete_tool_call_ids.has(partial_id):
			continue
		var item := _partial_tool_call_transcript_item(partial)
		if item.is_empty():
			continue
		var partial_turn_id := str(item.get("turn_id", ""))
		if partial_turn_id.is_empty() or not turn_message_counts.has(partial_turn_id):
			unbound_event_items = _append_projected_transcript_item(unbound_event_items, item)
			continue
		if not event_items_by_turn.has(partial_turn_id):
			event_items_by_turn[partial_turn_id] = []
		var partial_turn_items: Array = event_items_by_turn[partial_turn_id]
		partial_turn_items = _append_projected_transcript_item(partial_turn_items, item)
		event_items_by_turn[partial_turn_id] = partial_turn_items
	for i in range(messages.size()):
		var message = messages[i]
		if not (message is Dictionary):
			continue
		var message_turn_id := str(message.get("turn_id", ""))
		items.append({
			"kind": "message",
			"message_index": i,
			"role": str(message.get("role", "assistant")),
			"content": str(message.get("content", "")),
			"references": (message as Dictionary).get("references", []),
			"turn_id": message_turn_id,
		})
		if not message_turn_id.is_empty():
			turn_message_counts[message_turn_id] = int(turn_message_counts.get(message_turn_id, 1)) - 1
			if int(turn_message_counts.get(message_turn_id, 0)) <= 0 and event_items_by_turn.has(message_turn_id):
				var turn_event_items: Array = event_items_by_turn[message_turn_id]
				for event_item in _group_transcript_tool_items(turn_event_items):
					items.append(event_item)
	for item in _group_transcript_tool_items(unbound_event_items):
		items = _append_projected_transcript_item(items, item)
	return items


func _group_transcript_tool_items(source_items: Array) -> Array:
	var grouped: Array = []
	var tool_items_by_batch: Dictionary = {}
	var tool_order: Array[String] = []
	for item in source_items:
		if not (item is Dictionary):
			continue
		var transcript_item: Dictionary = item
		var kind := str(transcript_item.get("kind", ""))
		if kind in ["tool_call", "partial_tool_call"]:
			var batch_key := str(transcript_item.get("batch_key", "")).strip_edges()
			if batch_key.is_empty():
				batch_key = str(transcript_item.get("turn_id", "")).strip_edges()
			if batch_key.is_empty():
				batch_key = "__unbound_tools"
			if not tool_items_by_batch.has(batch_key):
				tool_items_by_batch[batch_key] = []
				tool_order.append(batch_key)
				grouped.append({
					"kind": "__tool_batch_placeholder",
					"batch_key": batch_key,
					"turn_id": str(transcript_item.get("turn_id", "")),
				})
			var batch_tools: Array = tool_items_by_batch[batch_key]
			batch_tools = _append_projected_transcript_item(batch_tools, transcript_item)
			tool_items_by_batch[batch_key] = batch_tools
			continue
		grouped.append(transcript_item)
	var result: Array = []
	for item in grouped:
		if not (item is Dictionary):
			continue
		var grouped_item: Dictionary = item
		if str(grouped_item.get("kind", "")) != "__tool_batch_placeholder":
			result.append(grouped_item)
			continue
		var batch_key := str(grouped_item.get("batch_key", ""))
		var calls: Array = tool_items_by_batch.get(batch_key, [])
		if calls.is_empty():
			continue
		result.append(_tool_batch_transcript_item(batch_key, calls))
	return result


func _tool_batch_transcript_item(batch_key: String, calls: Array) -> Dictionary:
	var status := _tool_batch_status(calls)
	var clean_batch_key := batch_key.strip_edges()
	if clean_batch_key.is_empty():
		clean_batch_key = "__unbound_tools"
	var turn_id := ""
	for item in calls:
		if item is Dictionary:
			turn_id = str((item as Dictionary).get("turn_id", ""))
			if not turn_id.is_empty():
				break
	var batch_id := "tool_batch_%s" % clean_batch_key
	return {
		"kind": "tool_batch",
		"batch_id": batch_id,
		"batch_key": clean_batch_key if clean_batch_key != "__unbound_tools" else "",
		"turn_id": turn_id if turn_id != "__unbound_tools" else "",
		"status": status,
		"tool_count": calls.size(),
		"calls": calls,
		"expanded": bool(tool_batch_expanded.get(batch_id, false)),
	}


func _tool_batch_status(calls: Array) -> String:
	var has_running := false
	var has_failed := false
	var has_pending := false
	for item in calls:
		if not (item is Dictionary):
			continue
		var status := _visible_tool_call_status(str((item as Dictionary).get("status", "")))
		if status in ["executing", "streaming", "running"]:
			has_running = true
		elif status in ["failed", "error"]:
			has_failed = true
		elif status in ["pending", "approved", "dispatch_ready"]:
			has_pending = true
	if has_running:
		return "running"
	if has_failed:
		return "failed"
	if has_pending:
		return "pending"
	return "completed"


func _visible_tool_call_status(status: String) -> String:
	match status:
		"continuation_ready", "continuation_blocked":
			return "completed"
		"success":
			return "succeeded"
		"done":
			return "completed"
		_:
			return status


func _append_projected_transcript_item(target: Array, item: Dictionary) -> Array:
	var projection_key := _transcript_item_projection_key(item)
	if projection_key.is_empty():
		target.append(item)
		return target
	for index in range(target.size()):
		if not (target[index] is Dictionary):
			continue
		var existing: Dictionary = target[index]
		if _transcript_item_projection_key(existing) != projection_key:
			continue
		target[index] = item
		return target
	target.append(item)
	return target


func _transcript_item_projection_key(item: Dictionary) -> String:
	var projection_key := str(item.get("projection_key", "")).strip_edges()
	if not projection_key.is_empty():
		return projection_key
	var kind := str(item.get("kind", ""))
	if not (kind in ["tool_call", "partial_tool_call"]):
		return ""
	var turn_id := str(item.get("turn_id", "")).strip_edges()
	var name := str(item.get("name", "")).strip_edges()
	if turn_id.is_empty() or name.is_empty():
		return ""
	return "%s|%s" % [turn_id, name]


func _model_event_transcript_item(event: Dictionary) -> Dictionary:
	var kind := str(event.get("kind", ""))
	var data: Dictionary = event.get("data", {})
	match kind:
		"tool_call":
			if str(data.get("name", "")) == "godex_update_progress":
				return {}
			return {
				"kind": "tool_call",
				"event_id": str(event.get("id", "")),
				"tool_call_id": str(data.get("id", "")),
				"name": str(data.get("name", "工具调用")),
				"status": _visible_tool_call_status(str(data.get("status", "pending"))),
				"detail": _tool_call_transcript_detail(data),
				"turn_id": str(data.get("turn_id", "")),
				"source_event_id": str(data.get("source_event_id", "")),
				"batch_key": _tool_call_batch_key(data),
				"projection_key": _tool_call_projection_key(data),
				"expanded": bool(data.get("expanded", false)),
			}
		"stream_step", "stream_trace":
			return {}
		"agent_loop", "local_tool_probe", "mcp_context", "context_menu_action", "queued_user_message", "pending_steer", "plan_mode", "goal_state", "session_compaction", "file_context", "subagent", "subagent_notification", "subagent_edge", "openai_transport", "openai_request", "openai_response", "progress_update":
			return {}
		"command_run":
			return {
				"kind": "command_run",
				"event_id": str(event.get("id", "")),
				"command_id": str(data.get("id", "")),
				"command": str(data.get("command", "")),
				"shell": str(data.get("shell", "")),
				"status": str(data.get("status", "queued")),
				"detail": _command_run_transcript_detail(data),
				"result": _command_run_transcript_result(data),
				"turn_id": str(data.get("turn_id", "")),
				"expanded": bool(data.get("expanded", false)),
			}
		_:
			return {}


func _partial_tool_call_transcript_item(data: Dictionary) -> Dictionary:
	return {
		"kind": "partial_tool_call",
		"tool_call_id": str(data.get("id", "")),
		"name": str(data.get("name", "工具调用")),
		"status": str(data.get("status", "streaming")),
		"detail": _partial_tool_call_transcript_detail(data),
		"turn_id": str(data.get("turn_id", "")),
		"source_event_id": str(data.get("source_event_id", "")),
		"batch_key": str(data.get("batch_key", "")).strip_edges() if not str(data.get("batch_key", "")).strip_edges().is_empty() else _tool_call_batch_key(data),
		"projection_key": _tool_call_projection_key(data),
		"expanded": bool(data.get("expanded", true)),
	}


func _partial_tool_call_transcript_detail(data: Dictionary) -> String:
	var parts: Array[String] = ["ID: %s" % str(data.get("id", ""))]
	var arguments := str(data.get("arguments", "")).strip_edges()
	if not arguments.is_empty():
		parts.append("Partial arguments: %s" % _safe_tool_arguments_summary(arguments))
	return "\n".join(parts)


func _tool_call_transcript_detail(data: Dictionary) -> String:
	var parts: Array[String] = ["ID: %s" % str(data.get("id", ""))]
	var source_event_id := str(data.get("source_event_id", ""))
	if not source_event_id.is_empty():
		parts.append("Source event: %s" % source_event_id)
	var arguments = data.get("arguments", {})
	if arguments is Dictionary and not arguments.is_empty():
		parts.append("Arguments: %s" % _safe_tool_arguments_summary(arguments))
	var result = data.get("result", {})
	if result is Dictionary and not result.is_empty():
		var result_text := str(result.get("message", result.get("error", result.get("summary", "")))).strip_edges()
		if result_text.is_empty():
			var result_keys: Array[String] = []
			for key in result.keys():
				result_keys.append(str(key))
				if result_keys.size() >= 6:
					break
			result_text = "fields: %s" % ", ".join(result_keys)
		if result_text.length() > 360:
			result_text = "%s..." % result_text.left(360).strip_edges()
		parts.append("Result: %s" % result_text)
	return "\n".join(parts)


func _safe_tool_arguments_summary(arguments) -> String:
	if arguments is Dictionary:
		var dict: Dictionary = arguments
		var parts: Array[String] = []
		for key in dict.keys():
			var key_text := str(key)
			var value = dict[key]
			if value is int or value is float or value is bool:
				parts.append("%s=%s" % [key_text, str(value)])
			elif value is String and str(value).length() <= 80 and _looks_safe_argument_key(key_text):
				parts.append("%s=%s" % [key_text, str(value)])
			else:
				parts.append("%s=<redacted>" % key_text)
			if parts.size() >= 8:
				break
		return ", ".join(parts)
	var text := str(arguments).strip_edges()
	if text.length() > 120:
		return "length=%d chars" % text.length()
	return text.replace("sk-", "sk-<redacted>")


func _looks_safe_argument_key(key: String) -> bool:
	return key.to_lower() in ["scope", "limit", "mode", "kind", "status", "name", "tool"]


func _command_run_transcript_detail(data: Dictionary) -> String:
	var parts: Array[String] = ["Command: %s" % str(data.get("command", ""))]
	var shell_name := str(data.get("shell", ""))
	if not shell_name.is_empty():
		parts.append("Shell: %s" % shell_name)
	var working_directory := str(data.get("working_directory", ""))
	if not working_directory.is_empty():
		parts.append("Working directory: %s" % working_directory)
	if data.has("timeout_sec"):
		parts.append("Timeout: %ss" % str(data.get("timeout_sec", "")))
	var result = data.get("result", {})
	if result is Dictionary and not result.is_empty():
		var runner_kind := _command_runner_label(str(result.get("runner_kind", "")))
		if not runner_kind.is_empty():
			parts.append("Runner: %s" % runner_kind)
		if result.has("duration_ms"):
			parts.append("Duration: %sms" % str(result.get("duration_ms", "")))
		if result.has("timeout_enforced") and not bool(result.get("timeout_enforced", true)):
			parts.append("Timeout enforcement: not hard-enforced by current runner.")
		if bool(result.get("stderr_merged", false)):
			var notice := str(result.get("stderr_notice", "stderr is merged into combined output.")).strip_edges()
			parts.append("stderr handling: %s" % notice)
		if result.has("exit_code"):
			parts.append("Exit code: %s" % str(result.get("exit_code", "")))
		var combined := _sanitize_command_output(str(result.get("combined_output", ""))).strip_edges()
		if combined.length() > 480:
			combined = "%s..." % combined.left(480).strip_edges()
		if not combined.is_empty():
			parts.append("combined output:\n%s" % combined)
		var stdout := _sanitize_command_output(str(result.get("stdout", ""))).strip_edges()
		if stdout.length() > 480:
			stdout = "%s..." % stdout.left(480).strip_edges()
		if not stdout.is_empty():
			parts.append("stdout:\n%s" % stdout)
		var stderr := _sanitize_command_output(str(result.get("stderr", ""))).strip_edges()
		if stderr.length() > 480:
			stderr = "%s..." % stderr.left(480).strip_edges()
		if not stderr.is_empty():
			parts.append("stderr:\n%s" % stderr)
	if bool(data.get("blocked", false)):
		parts.append("Blocked by safety policy.")
	return "\n".join(parts)


func _command_run_transcript_result(data: Dictionary) -> Dictionary:
	var raw_result = data.get("result", {})
	var result: Dictionary = {}
	if raw_result is Dictionary and not raw_result.is_empty():
		if raw_result.has("exit_code"):
			result["exit_code"] = raw_result.get("exit_code", "")
		if raw_result.has("runner_kind"):
			result["runner_kind"] = str(raw_result.get("runner_kind", ""))
		if raw_result.has("duration_ms"):
			result["duration_ms"] = max(0, int(raw_result.get("duration_ms", 0)))
		if raw_result.has("timeout_enforced"):
			result["timeout_enforced"] = bool(raw_result.get("timeout_enforced", false))
		if raw_result.has("stderr_merged"):
			result["stderr_merged"] = bool(raw_result.get("stderr_merged", false))
		for key in ["combined_output", "stdout", "stderr", "stderr_notice"]:
			var value := _sanitize_command_output(str(raw_result.get(key, ""))).strip_edges()
			if value.length() > 480:
				value = "%s..." % value.left(480).strip_edges()
				result["%s_truncated" % key] = true
			if not value.is_empty():
				result[key] = value
	var timeline: Array[Dictionary] = []
	for item in data.get("timeline", []):
		if not (item is Dictionary):
			continue
		var row: Dictionary = item.duplicate(true)
		row["summary"] = _sanitize_command_output(str(row.get("summary", ""))).strip_edges()
		timeline.append(row)
	if not timeline.is_empty():
		result["timeline"] = timeline
	var output_chunks: Array[Dictionary] = []
	for item in data.get("output_chunks", []):
		if not (item is Dictionary):
			continue
		var row: Dictionary = item.duplicate(true)
		row["text"] = _sanitize_command_output(str(row.get("text", ""))).strip_edges()
		output_chunks.append(row)
	if not output_chunks.is_empty():
		result["output_chunks"] = output_chunks
	return result


func _find_command_run(command_id: String) -> Dictionary:
	for event in active_model_events():
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) == command_id:
			return data
	return {}


func _find_command_run_approval(command_id: String) -> Dictionary:
	for record in approval_records:
		if str(record.get("command_id", "")) == command_id:
			return record
	return {}


func _has_running_command_run(except_command_id: String = "") -> bool:
	for event in active_model_events():
		if str(event.get("kind", "")) != "command_run":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) == except_command_id:
			continue
		if str(data.get("status", "")) == "running":
			return true
	return false


func _cancel_command_run_approvals(command_id: String) -> void:
	for record in approval_records:
		if str(record.get("command_id", "")) != command_id:
			continue
		if str(record.get("status", "")) != "pending":
			continue
		record["status"] = "cancelled"
		record["decision"] = "cancel"
		record["decided_at"] = Time.get_datetime_string_from_system()


func _append_command_run_timeline(data: Dictionary, status: String, result: Dictionary = {}) -> Array[Dictionary]:
	var timeline: Array[Dictionary] = []
	for item in data.get("timeline", []):
		if item is Dictionary:
			var item_dict: Dictionary = item
			timeline.append(item_dict.duplicate(true))
	timeline.append(_command_run_timeline_event(status, result))
	return timeline


func _command_run_timeline_event(status: String, result: Dictionary = {}) -> Dictionary:
	var summary := _command_run_timeline_summary(status, result)
	return {
		"status": status,
		"summary": summary,
		"created_at": Time.get_datetime_string_from_system(),
	}


func _command_run_timeline_summary(status: String, result: Dictionary = {}) -> String:
	match status:
		"queued":
			return "Queued for approval."
		"approval_required":
			return "Waiting for command approval."
		"approved":
			return "Approval granted."
		"rejected":
			return "Approval rejected."
		"running":
			return "Runner started."
		"blocked":
			return str(result.get("stderr", "Blocked by command safety policy."))
		"failed":
			return str(result.get("stderr", "Command failed."))
		"timed_out":
			return "Command timed out."
		"cancelled":
			return "Command cancelled."
		"completed":
			var exit_code := str(result.get("exit_code", "0"))
			var duration := int(result.get("duration_ms", -1))
			if duration >= 0:
				return "Completed with exit code %s in %sms." % [exit_code, duration]
			return "Completed with exit code %s." % exit_code
		_:
			return status if not status.is_empty() else "Command updated."


func _append_command_output_chunk(data: Dictionary, stream: String, text: String, metadata: Dictionary = {}) -> Array[Dictionary]:
	var chunks: Array[Dictionary] = []
	for item in data.get("output_chunks", []):
		if item is Dictionary:
			var item_dict: Dictionary = item
			chunks.append(item_dict.duplicate(true))
	var sanitized := _sanitize_command_output(text)
	var truncated := false
	if sanitized.length() > 1200:
		sanitized = "%s..." % sanitized.left(1200).strip_edges()
		truncated = true
	var chunk := {
		"sequence": chunks.size() + 1,
		"stream": stream,
		"text": sanitized,
		"created_at": Time.get_datetime_string_from_system(),
	}
	if truncated:
		chunk["truncated"] = true
	if metadata.has("source"):
		chunk["source"] = str(metadata.get("source", ""))
	chunks.append(chunk)
	while chunks.size() > 40:
		chunks.pop_front()
	for index in range(chunks.size()):
		chunks[index]["sequence"] = index + 1
	return chunks


func _merge_command_chunk_result(data: Dictionary, stream: String, text: String) -> Dictionary:
	var result := _existing_command_result(data)
	result[stream] = _append_limited_command_output(str(result.get(stream, "")), text)
	result["combined_output"] = _command_combined_output_from_streams(result)
	return result


func _merge_command_result_for_storage(data: Dictionary, result: Dictionary) -> Dictionary:
	var merged := _existing_command_result(data)
	var sanitized := _sanitize_command_result_for_storage(result)
	for key in sanitized.keys():
		merged[key] = sanitized[key]
	for key in ["combined_output", "stdout", "stderr", "stderr_notice"]:
		if not sanitized.has(key) and merged.has(key):
			merged[key] = _sanitize_command_output(str(merged.get(key, "")))
	if not merged.has("combined_output"):
		merged["combined_output"] = _command_combined_output_from_streams(merged)
	return merged


func _sanitize_command_result_for_storage(result: Dictionary) -> Dictionary:
	var sanitized := result.duplicate(true)
	for key in ["combined_output", "stdout", "stderr", "stderr_notice"]:
		if sanitized.has(key):
			sanitized[key] = _sanitize_command_output(str(sanitized.get(key, "")))
	if not sanitized.has("combined_output"):
		sanitized["combined_output"] = _command_combined_output_from_streams(sanitized)
	if sanitized.has("duration_ms"):
		sanitized["duration_ms"] = max(0, int(sanitized.get("duration_ms", 0)))
	if sanitized.has("timeout_enforced"):
		sanitized["timeout_enforced"] = bool(sanitized.get("timeout_enforced", false))
	if sanitized.has("stderr_merged"):
		sanitized["stderr_merged"] = bool(sanitized.get("stderr_merged", false))
	return sanitized


func _existing_command_result(data: Dictionary) -> Dictionary:
	var raw_result = data.get("result", {})
	if raw_result is Dictionary:
		return raw_result.duplicate(true)
	return {}


func _append_limited_command_output(existing: String, chunk: String) -> String:
	var merged := chunk if existing.is_empty() else "%s\n%s" % [existing, chunk]
	if merged.length() > 4000:
		merged = "...%s" % merged.substr(max(0, merged.length() - 3997))
	return merged


func _command_combined_output_from_streams(result: Dictionary) -> String:
	var parts: Array[String] = []
	for key in ["stdout", "stderr"]:
		var value := _sanitize_command_output(str(result.get(key, ""))).strip_edges()
		if not value.is_empty():
			parts.append(value)
	return _append_limited_command_output("", "\n".join(parts))


func _command_runner_label(runner_kind: String) -> String:
	match runner_kind:
		"godot_os_execute_sync":
			return "Godot OS.execute (同步短命令)"
		"custom_callable":
			return "自定义执行器"
		_:
			return runner_kind


func _command_run_safety(command_run: Dictionary) -> Dictionary:
	var command_capability := CommandCapability.new()
	command_capability.enabled = command_enabled
	command_capability.shell = str(command_run.get("shell", command_shell))
	command_capability.working_directory = str(command_run.get("working_directory", ""))
	command_capability.timeout_sec = int(command_run.get("timeout_sec", command_timeout_sec))
	return command_capability.build_request(str(command_run.get("command", "")))


func _command_blocked_message(safety: Dictionary) -> String:
	var reason := str(safety.get("blocked_reason", ""))
	match reason:
		"unsupported_shell":
			return "Blocked by safety policy: unsupported shell."
		"unsafe_working_directory":
			return "Blocked by safety policy: unsafe working directory."
		"blocked_command":
			return "Blocked by safety policy: blocked command."
		_:
			return "Blocked by safety policy."


func _command_run_fingerprint(command_run: Dictionary) -> String:
	var payload := {
		"command": str(command_run.get("command", "")),
		"shell": str(command_run.get("shell", "")),
		"working_directory": str(command_run.get("working_directory", "")),
		"timeout_sec": int(command_run.get("timeout_sec", command_timeout_sec)),
	}
	return JSON.stringify(payload)


func _normalize_command_result(raw_result) -> Dictionary:
	var result: Dictionary = {}
	if raw_result is Dictionary:
		result = raw_result.duplicate(true)
	else:
		result["stdout"] = str(raw_result)
	if not result.has("exit_code"):
		result["exit_code"] = 0
	result["stdout"] = _sanitize_command_output(str(result.get("stdout", "")))
	result["stderr"] = _sanitize_command_output(str(result.get("stderr", "")))
	if result.has("combined_output"):
		result["combined_output"] = _sanitize_command_output(str(result.get("combined_output", "")))
	else:
		result["combined_output"] = _command_combined_output_from_streams(result)
	if result.has("stderr_notice"):
		result["stderr_notice"] = _sanitize_command_output(str(result.get("stderr_notice", "")))
	if result.has("duration_ms"):
		result["duration_ms"] = max(0, int(result.get("duration_ms", 0)))
	if result.has("timeout_enforced"):
		result["timeout_enforced"] = bool(result.get("timeout_enforced", false))
	if result.has("stderr_merged"):
		result["stderr_merged"] = bool(result.get("stderr_merged", false))
	if result.has("runner_kind"):
		result["runner_kind"] = str(result.get("runner_kind", ""))
	return result


func _sanitize_command_output(output: String) -> String:
	var text := output
	var inline_key := api_key.strip_edges()
	var env_name := api_key_env.strip_edges()
	var env_key := OS.get_environment(env_name).strip_edges() if not env_name.is_empty() else ""
	for secret in [inline_key, env_key]:
		if not str(secret).is_empty():
			text = text.replace(str(secret), "[redacted-api-key]")
	if text.length() > 4000:
		text = "%s..." % text.left(4000).strip_edges()
	return text


func set_pending_openai_continuation(continuation: Dictionary) -> Dictionary:
	if continuation.is_empty():
		pending_openai_continuation = {}
		return pending_openai_continuation
	var previous_response_id := str(continuation.get("previous_response_id", ""))
	var payload: Dictionary = continuation.get("payload", {})
	if previous_response_id.is_empty() and payload.has("previous_response_id"):
		previous_response_id = str(payload.get("previous_response_id", ""))
	var transport_request: Dictionary = continuation.get("transport_request", {})
	var transport_payload: Dictionary = transport_request.get("payload", {})
	if previous_response_id.is_empty() and transport_payload.has("previous_response_id"):
		previous_response_id = str(transport_payload.get("previous_response_id", ""))
	pending_openai_continuation = {
		"tool_call_id": str(continuation.get("tool_call_id", "")),
		"status": "ready" if bool(continuation.get("success", false)) else "blocked",
		"error": str(continuation.get("error", "")),
		"previous_response_id": previous_response_id,
		"endpoint": str(continuation.get("openai_request", {}).get("endpoint", "")),
		"api_mode": str(continuation.get("openai_request", {}).get("api_mode", api_mode)),
		"model": str(continuation.get("openai_request", {}).get("model", model)),
		"key_source": str(continuation.get("openai_request", {}).get("key_source", "missing")),
		"auto_send_allowed": bool(continuation.get("auto_send_allowed", false)),
		"transport_request": continuation.get("transport_request", {}).duplicate(true),
	}
	return pending_openai_continuation


func clear_pending_openai_continuation(tool_call_id: String = "") -> void:
	if tool_call_id.is_empty() or str(pending_openai_continuation.get("tool_call_id", "")) == tool_call_id:
		pending_openai_continuation = {}


func set_pending_openai_approval_request(transport_request: Dictionary, approval: Dictionary) -> Dictionary:
	if transport_request.is_empty():
		pending_openai_approval_request = {}
		return pending_openai_approval_request
	pending_openai_approval_request = {
		"status": "pending",
		"approval_id": str(approval.get("id", "")),
		"summary": str(approval.get("summary", "")),
		"endpoint": str(transport_request.get("endpoint", "")),
		"provider": str(transport_request.get("provider", provider)),
		"api_mode": str(transport_request.get("api_mode", api_mode)),
		"model": str(transport_request.get("model", model)),
		"body_length": JSON.stringify(transport_request.get("payload", {})).length(),
		"source": str(approval.get("source", "")),
		"tool_call_id": str(approval.get("tool_call_id", "")),
		"transport_request": transport_request.duplicate(true),
		"created_at": Time.get_datetime_string_from_system(),
	}
	return pending_openai_approval_request


func pending_openai_approval_request_preview() -> Dictionary:
	if pending_openai_approval_request.is_empty():
		return {}
	return {
		"status": str(pending_openai_approval_request.get("status", "")),
		"approval_id": str(pending_openai_approval_request.get("approval_id", "")),
		"summary": str(pending_openai_approval_request.get("summary", "")),
		"endpoint": str(pending_openai_approval_request.get("endpoint", "")),
		"provider": str(pending_openai_approval_request.get("provider", provider)),
		"api_mode": str(pending_openai_approval_request.get("api_mode", api_mode)),
		"model": str(pending_openai_approval_request.get("model", model)),
		"body_length": int(pending_openai_approval_request.get("body_length", 0)),
		"source": str(pending_openai_approval_request.get("source", "")),
		"tool_call_id": str(pending_openai_approval_request.get("tool_call_id", "")),
		"created_at": str(pending_openai_approval_request.get("created_at", "")),
	}


func pending_openai_approval_transport_request() -> Dictionary:
	return pending_openai_approval_request.get("transport_request", {}).duplicate(true)


func pending_openai_approval_summary() -> Dictionary:
	if pending_openai_approval_request.is_empty():
		return {"title": "OpenAI 审批", "detail": "暂无待审批 OpenAI 发送请求。"}
	return {
		"title": "OpenAI 审批 · %s" % str(pending_openai_approval_request.get("status", "")),
		"detail": "%s · %s · %s bytes · %s" % [
			str(pending_openai_approval_request.get("model", "")),
			str(pending_openai_approval_request.get("endpoint", "")),
			str(pending_openai_approval_request.get("body_length", 0)),
			str(pending_openai_approval_request.get("source", "")),
		],
	}


func clear_pending_openai_approval_request(approval_id: String = "") -> void:
	if approval_id.is_empty() or str(pending_openai_approval_request.get("approval_id", "")) == approval_id:
		pending_openai_approval_request = {}


func set_retry_openai_request(transport_request: Dictionary, status: String, reason: String = "") -> Dictionary:
	if transport_request.is_empty():
		retry_openai_request = {}
		return retry_openai_request
	retry_openai_request = {
		"status": status,
		"reason": reason,
		"endpoint": str(transport_request.get("endpoint", "")),
		"provider": str(transport_request.get("provider", provider)),
		"api_mode": str(transport_request.get("api_mode", api_mode)),
		"model": str(transport_request.get("model", model)),
		"stage": str(transport_request.get("stage", "")),
		"body_length": JSON.stringify(transport_request.get("payload", {})).length(),
		"source": str(transport_request.get("source", "")),
		"tool_call_id": str(transport_request.get("tool_call_id", "")),
		"previous_response_id": str(transport_request.get("previous_response_id", "")),
		"payload_input_count": int(transport_request.get("payload_input_count", 0)),
		"payload_fingerprint": str(transport_request.get("payload_fingerprint", "")),
		"transport_request": transport_request.duplicate(true),
		"updated_at": Time.get_datetime_string_from_system(),
	}
	return retry_openai_request


func clear_retry_openai_request() -> void:
	retry_openai_request = {}


func begin_agent_loop(reason: String = "user_prompt") -> Dictionary:
	active_turn_id = _new_thread_id().replace("thread", "turn")
	agent_loop_status = "running"
	agent_loop_step_count = 0
	agent_loop_stop_reason = reason
	agent_loop_updated_at = Time.get_datetime_string_from_system()
	return append_model_event("agent_loop", {
		"status": agent_loop_status,
		"step_count": agent_loop_step_count,
		"max_steps": agent_loop_max_steps,
		"reason": reason,
	})


func record_agent_loop_step(action: String, detail: String = "") -> Dictionary:
	if agent_loop_status != "running":
		agent_loop_status = "running"
	agent_loop_step_count += 1
	agent_loop_stop_reason = detail
	agent_loop_updated_at = Time.get_datetime_string_from_system()
	return append_model_event("agent_loop", {
		"status": agent_loop_status,
		"step_count": agent_loop_step_count,
		"max_steps": agent_loop_max_steps,
		"action": action,
		"detail": detail,
	})


func stop_agent_loop(reason: String) -> Dictionary:
	agent_loop_status = "stopped"
	agent_loop_stop_reason = reason
	agent_loop_updated_at = Time.get_datetime_string_from_system()
	var event := append_model_event("agent_loop", {
		"status": agent_loop_status,
		"step_count": agent_loop_step_count,
		"max_steps": agent_loop_max_steps,
		"reason": reason,
	})
	active_turn_id = ""
	return event


func can_advance_agent_loop() -> bool:
	return agent_loop_status == "running"


func agent_loop_summary() -> Dictionary:
	var detail := "%d 步" % int(agent_loop_step_count)
	if not agent_loop_stop_reason.is_empty():
		detail += " · %s" % agent_loop_stop_reason
	if not agent_loop_updated_at.is_empty():
		detail += " · %s" % agent_loop_updated_at
	return {
		"title": "Agent 循环 · %s" % agent_loop_status,
		"detail": detail,
	}


func retry_openai_request_preview() -> Dictionary:
	if retry_openai_request.is_empty():
		return {}
	return {
		"status": str(retry_openai_request.get("status", "")),
		"reason": str(retry_openai_request.get("reason", "")),
		"endpoint": str(retry_openai_request.get("endpoint", "")),
		"provider": str(retry_openai_request.get("provider", provider)),
		"api_mode": str(retry_openai_request.get("api_mode", api_mode)),
		"model": str(retry_openai_request.get("model", model)),
		"stage": str(retry_openai_request.get("stage", "")),
		"body_length": int(retry_openai_request.get("body_length", 0)),
		"source": str(retry_openai_request.get("source", "")),
		"tool_call_id": str(retry_openai_request.get("tool_call_id", "")),
		"previous_response_id": str(retry_openai_request.get("previous_response_id", "")),
		"payload_input_count": int(retry_openai_request.get("payload_input_count", 0)),
		"payload_fingerprint": str(retry_openai_request.get("payload_fingerprint", "")),
		"updated_at": str(retry_openai_request.get("updated_at", "")),
	}


func pending_openai_continuation_summary() -> Dictionary:
	if pending_openai_continuation.is_empty():
		return {"title": "OpenAI 续跑", "detail": "暂无待发送工具结果续跑。"}
	var status := str(pending_openai_continuation.get("status", ""))
	var error := str(pending_openai_continuation.get("error", ""))
	var detail := "%s · %s · %s" % [
		str(pending_openai_continuation.get("tool_call_id", "")),
		str(pending_openai_continuation.get("model", "")),
		str(pending_openai_continuation.get("endpoint", "")),
	]
	if not error.is_empty():
		detail += " · %s" % error
	return {
		"title": "OpenAI 续跑 · %s" % status,
		"detail": detail,
	}


func retry_openai_request_summary() -> Dictionary:
	if retry_openai_request.is_empty():
		return {"title": "OpenAI 重试", "detail": "暂无可重试请求。"}
	var reason := str(retry_openai_request.get("reason", ""))
	var detail := "%s · %s · %s bytes" % [
		str(retry_openai_request.get("api_mode", api_mode)),
		str(retry_openai_request.get("endpoint", "")),
		str(retry_openai_request.get("body_length", 0)),
	]
	if not reason.is_empty():
		detail += " · %s" % reason
	return {
		"title": "OpenAI 重试 · %s" % str(retry_openai_request.get("status", "")),
		"detail": detail,
	}


func retry_openai_transport_request() -> Dictionary:
	return retry_openai_request.get("transport_request", {}).duplicate(true)


func record_mcp_discovery_request(request: Dictionary) -> Dictionary:
	mcp_discovery_status = "request_ready"
	mcp_discovery_error = ""
	mcp_discovered_at = Time.get_datetime_string_from_system()
	var event := append_model_event("mcp_tools_list_request", {
		"status": mcp_discovery_status,
		"endpoint": str(request.get("endpoint", endpoint)),
		"method": str(request.get("method", "tools/list")),
	})
	return {
		"status": mcp_discovery_status,
		"event": event,
	}


func update_mcp_discovery_status(status: String, error: String = "") -> Dictionary:
	mcp_discovery_status = status
	mcp_discovery_error = error
	mcp_discovered_at = Time.get_datetime_string_from_system()
	var event := append_model_event("mcp_tools_discovery_status", {
		"status": status,
		"error": error,
		"endpoint": endpoint,
	})
	return {
		"status": status,
		"error": error,
		"event": event,
	}


func record_mcp_discovery(result: Dictionary) -> Dictionary:
	mcp_discovery_status = "ready" if bool(result.get("success", false)) else "error"
	mcp_discovery_error = str(result.get("error", result.get("message", ""))) if mcp_discovery_status == "error" else ""
	mcp_discovered_at = Time.get_datetime_string_from_system()
	mcp_discovered_tools.assign(result.get("tools", []))
	var event := append_model_event("mcp_tools_discovery", {
		"status": mcp_discovery_status,
		"error": mcp_discovery_error,
		"tool_count": mcp_discovered_tools.size(),
		"endpoint": endpoint,
	})
	return {
		"status": mcp_discovery_status,
		"tool_count": mcp_discovered_tools.size(),
		"event": event,
	}


func mcp_tool_summary_rows(limit: int = 8) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if mcp_discovered_tools.is_empty():
		rows.append({
			"title": "工具发现",
			"detail": "尚未发现工具。状态：%s" % mcp_discovery_status,
		})
		return rows
	for tool in mcp_discovered_tools.slice(0, min(mcp_discovered_tools.size(), limit)):
		var schema: Dictionary = tool.get("input_schema", {})
		var group := str(tool.get("group", ""))
		var prefix := "%s · " % group if not group.is_empty() else ""
		rows.append({
			"title": str(tool.get("name", "")),
			"detail": "%s%s · %s" % [prefix, str(tool.get("description", "")), _schema_summary(schema)],
		})
	return rows


func active_model_events() -> Array:
	var session := _active_session()
	if session.is_empty():
		return []
	var events = session.get("model_events", [])
	if events is Array:
		return events
	return []


func model_event_summary_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var events := active_model_events()
	if events.is_empty():
		rows.append({"title": "模型事件", "detail": "暂无模型事件。"})
		return rows
	for event in events.slice(max(events.size() - 6, 0), events.size()):
		var data: Dictionary = event.get("data", {})
		var title_suffix := str(data.get("status", data.get("error", "")))
		if str(event.get("kind", "")) == "tool_call":
			title_suffix = "%s · %s" % [str(data.get("name", "")), str(data.get("status", ""))]
		if str(event.get("kind", "")) == "goal_state":
			title_suffix = "%s · %s" % [_goal_status_label(str(data.get("status", ""))), str(data.get("summary", ""))]
		if str(event.get("kind", "")) == "session_compaction":
			title_suffix = "%s · -%d / keep %d" % [
				str(data.get("source", "")),
				int(data.get("removed_count", 0)),
				int(data.get("kept_count", 0)),
			]
		if str(event.get("kind", "")) == "subagent_notification":
			title_suffix = "%s · %s" % [_subagent_notification_status_label(str(data.get("status", ""))), str(data.get("name", ""))]
		if str(event.get("kind", "")) == "subagent_edge":
			title_suffix = "%s · %s -> %s" % [
				_subagent_edge_status_label(str(data.get("status", ""))),
				str(data.get("parent_thread_id", "")),
				str(data.get("child_thread_id", "")),
			]
		rows.append({
			"title": "%s · %s" % [str(event.get("kind", "")), title_suffix],
			"detail": _model_event_summary_detail(event),
		})
	return rows


func _model_event_summary_detail(event: Dictionary) -> String:
	var data: Dictionary = event.get("data", {})
	match str(event.get("kind", "")):
		"subagent_notification":
			var parts: Array[String] = []
			var task_id := str(data.get("task_id", "")).strip_edges()
			var child_thread_id := str(data.get("child_thread_id", "")).strip_edges()
			var summary := str(data.get("summary", data.get("result", data.get("error", "")))).strip_edges()
			if not task_id.is_empty():
				parts.append("Task: %s" % task_id)
			if not child_thread_id.is_empty():
				parts.append("Child: %s" % child_thread_id)
			if not summary.is_empty():
				parts.append(_short_preview(summary, 120))
			return " · ".join(parts)
		"subagent_edge":
			return "Task: %s · %s -> %s" % [
				str(data.get("task_id", "")),
				str(data.get("parent_thread_id", "")),
				str(data.get("child_thread_id", "")),
			]
		_:
			return "%s · %s" % [str(data.get("endpoint", "")), str(data.get("model", ""))]


func composer_input_queue_summary_rows(limit: int = 6) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var queued := active_queued_user_messages()
	var pending_steers := active_pending_steers()
	var start_queued := max(queued.size() - limit, 0)
	for record in queued.slice(start_queued, queued.size()):
		rows.append({
			"title": "用户消息队列 · %s" % str(record.get("status", "")),
			"detail": "%s\nSource: %s" % [_short_preview(str(record.get("text", "")), 160), str(record.get("source", ""))],
			"enabled": str(record.get("status", "")) == "queued",
			"risk": "low",
		})
	var start_steers := max(pending_steers.size() - limit, 0)
	for record in pending_steers.slice(start_steers, pending_steers.size()):
		rows.append({
			"title": "指南指令 · %s" % str(record.get("status", "")),
			"detail": "%s\nSource: %s" % [_short_preview(str(record.get("instructions", "")), 160), str(record.get("source", ""))],
			"enabled": str(record.get("status", "")) == "pending",
			"risk": "low",
		})
	if rows.is_empty():
		rows.append({"title": "发送队列", "detail": "暂无排队消息或指南指令。", "enabled": false, "risk": "low"})
	return rows


func subagent_summary_rows(limit: int = 6) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var tasks: Array = active_subagent_tasks()
	if tasks.is_empty():
		rows.append({"title": "子智能体", "detail": "暂无子智能体任务。", "enabled": false, "risk": "low"})
		return rows
	var start := max(tasks.size() - limit, 0)
	for item in tasks.slice(start, tasks.size()):
		if not (item is Dictionary):
			continue
		var task: Dictionary = item
		var lifecycle_detail := _subagent_lifecycle_detail(task)
		rows.append({
			"title": "子智能体 · %s · %s" % [_subagent_status_label(str(task.get("status", ""))), str(task.get("name", ""))],
			"detail": "%s · %s%s%s" % [
				str(task.get("role", "")),
				str(task.get("branch", "")),
				_subagent_summary_suffix(task),
				"\n%s" % lifecycle_detail if not lifecycle_detail.is_empty() else "",
			],
			"enabled": _normalize_subagent_status(str(task.get("status", ""))) in ["queued", "running"] or str(task.get("handoff_status", "")) == "handed_off",
			"risk": "low" if bool(task.get("readonly", true)) else "medium",
		})
	return rows


func subagent_notification_summary_rows(limit: int = 4) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var notifications: Array = active_subagent_notifications()
	if notifications.is_empty():
		rows.append({"title": "子智能体通知", "detail": "暂无 worker 通知。", "enabled": false, "risk": "low"})
		return rows
	var start := max(notifications.size() - limit, 0)
	for item in notifications.slice(start, notifications.size()):
		if not (item is Dictionary):
			continue
		var notification: Dictionary = item
		var detail_parts: Array[String] = []
		var task_id := str(notification.get("task_id", "")).strip_edges()
		var child_thread_id := str(notification.get("child_thread_id", "")).strip_edges()
		var summary := str(notification.get("summary", "")).strip_edges()
		var result := str(notification.get("result", "")).strip_edges()
		var error := str(notification.get("error", "")).strip_edges()
		if not task_id.is_empty():
			detail_parts.append("Task: %s" % task_id)
		if not child_thread_id.is_empty():
			detail_parts.append("Child: %s" % child_thread_id)
		if not summary.is_empty():
			detail_parts.append(_short_preview(summary, 140))
		if not result.is_empty():
			detail_parts.append(_short_preview(result, 140))
		if not error.is_empty():
			detail_parts.append("Error: %s" % _short_preview(error, 120))
		rows.append({
			"title": "子智能体通知 · %s · %s" % [_subagent_notification_status_label(str(notification.get("status", ""))), str(notification.get("name", ""))],
			"detail": "\n".join(detail_parts),
			"enabled": str(notification.get("status", "")) in ["completed", "failed", "killed", "interrupted"],
			"risk": "low",
		})
	return rows


func subagent_edge_summary_rows(limit: int = 4) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var edges: Array = active_subagent_edges()
	if edges.is_empty():
		rows.append({"title": "子智能体关系", "detail": "暂无 parent-child 关系。", "enabled": false, "risk": "low"})
		return rows
	var start := max(edges.size() - limit, 0)
	for item in edges.slice(start, edges.size()):
		if not (item is Dictionary):
			continue
		var edge: Dictionary = item
		var detail_parts: Array[String] = []
		var task_id := str(edge.get("task_id", "")).strip_edges()
		if not task_id.is_empty():
			detail_parts.append("Task: %s" % task_id)
		detail_parts.append("%s -> %s" % [
			str(edge.get("parent_thread_id", "")),
			str(edge.get("child_thread_id", "")),
		])
		rows.append({
			"title": "子智能体关系 · %s" % _subagent_edge_status_label(str(edge.get("status", ""))),
			"detail": "\n".join(detail_parts),
			"enabled": _normalize_subagent_edge_status(str(edge.get("status", ""))) == "open",
			"risk": "low",
		})
	return rows


func record_approval_checkpoint(checkpoint: Dictionary) -> Dictionary:
	var record := checkpoint.duplicate(true)
	record["id"] = str(record.get("id", _new_thread_id().replace("thread", "approval")))
	record["status"] = "pending" if bool(record.get("requires_approval", true)) else "auto_approved"
	record["decision"] = ""
	record["decided_at"] = ""
	approval_records.push_front(record)
	return record


func decide_latest_approval(decision: String) -> Dictionary:
	for record in approval_records:
		if str(record.get("status", "")) == "pending":
			var command_id := str(record.get("command_id", ""))
			if not command_id.is_empty():
				return decide_command_run_approval(command_id, decision)
			record["status"] = "approved" if decision == "approve" else "rejected"
			record["decision"] = decision
			record["decided_at"] = Time.get_datetime_string_from_system()
			return record
	return {}


func latest_pending_approval() -> Dictionary:
	for record in approval_records:
		if str(record.get("status", "")) == "pending":
			return record
	return {}


func latest_pending_command_approval() -> Dictionary:
	for record in approval_records:
		if str(record.get("status", "")) == "pending" and not str(record.get("command_id", "")).is_empty():
			return record
	return {}


func pending_command_approval_summary() -> Dictionary:
	var record := latest_pending_command_approval()
	if record.is_empty():
		return {"title": "命令审批", "detail": "暂无待审批命令。", "risk": "low", "enabled": false}
	return {
		"title": "命令审批 · %s" % str(record.get("risk", "high")),
		"detail": "Command: %s\nShell: %s\nWorking directory: %s\nTimeout: %ss\nFingerprint: %s" % [
			str(record.get("command", "")),
			str(record.get("shell", "")),
			str(record.get("working_directory", "")),
			str(record.get("timeout_sec", "")),
			str(record.get("fingerprint", "")),
		],
		"risk": str(record.get("risk", "high")),
		"enabled": true,
		"command_id": str(record.get("command_id", "")),
		"approval_id": str(record.get("id", "")),
	}


func approval_summary_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if approval_records.is_empty():
		rows.append({"title": "审批记录", "detail": "暂无审批点。"})
		return rows
	for record in approval_records.slice(0, min(approval_records.size(), 6)):
		var command_id := str(record.get("command_id", ""))
		if not command_id.is_empty():
			rows.append({
				"title": "%s · %s · %s" % [str(record.get("status", "")), str(record.get("risk", "")), command_id],
				"detail": "Command: %s\nShell: %s\nWorking directory: %s\nTimeout: %ss" % [
					str(record.get("command", "")),
					str(record.get("shell", "")),
					str(record.get("working_directory", "")),
					str(record.get("timeout_sec", "")),
				],
			})
			continue
		rows.append({
			"title": "%s · %s" % [str(record.get("status", "")), str(record.get("risk", ""))],
			"detail": "%s — %s" % [str(record.get("action", "")), str(record.get("summary", ""))],
		})
	return rows


func command_run_summary_rows(limit: int = 6) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var command_events: Array[Dictionary] = []
	for event in active_model_events():
		if str(event.get("kind", "")) == "command_run":
			command_events.append(event)
	if command_events.is_empty():
		rows.append({"title": "命令运行", "detail": "暂无命令请求。"})
		return rows
	for event in command_events.slice(max(command_events.size() - limit, 0), command_events.size()):
		var data: Dictionary = event.get("data", {})
		var result = data.get("result", {})
		var exit_detail := ""
		if result is Dictionary:
			if result.has("exit_code"):
				exit_detail += "\nExit code: %s" % str(result.get("exit_code", ""))
			if result.has("runner_kind"):
				exit_detail += "\nRunner: %s" % _command_runner_label(str(result.get("runner_kind", "")))
			if result.has("duration_ms"):
				exit_detail += "\nDuration: %sms" % str(result.get("duration_ms", ""))
			if result.has("timeout_enforced") and not bool(result.get("timeout_enforced", true)):
				exit_detail += "\nTimeout: configured only; not hard-enforced by this runner."
		rows.append({
			"title": "命令运行 · %s · %s" % [str(data.get("status", "")), str(data.get("id", ""))],
			"detail": "Command: %s\nShell: %s\nWorking directory: %s\nTimeout: %ss%s" % [
				str(data.get("command", "")),
				str(data.get("shell", "")),
				str(data.get("working_directory", "")),
				str(data.get("timeout_sec", "")),
				exit_detail,
			],
		})
	return rows


func archive_active_session() -> Dictionary:
	var index := _find_session_index(active_thread_id)
	if index < 0:
		return {}
	var session: Dictionary = threads[index].duplicate(true)
	session["archived"] = true
	session["status"] = "archived"
	threads[index] = session
	select_thread("")
	return session


func archived_records(query: String = "") -> Array[Dictionary]:
	var needle := query.strip_edges().to_lower()
	var results: Array[Dictionary] = []
	for item in threads:
		if not bool(item.get("archived", false)):
			continue
		var title := str(item.get("title", ""))
		var haystack := title.to_lower()
		for message in item.get("messages", []):
			haystack += "\n%s" % str(message.get("content", "")).to_lower()
		if needle.is_empty() or haystack.find(needle) >= 0:
			results.append({
				"title": "%s%s" % ["★ " if bool(item.get("pinned", false)) else "", title],
				"detail": "已归档 · %d 条消息 · %s" % [item.get("messages", []).size(), str(item.get("id", ""))],
				"id": str(item.get("id", "")),
			})
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("title", "")) < str(b.get("title", ""))
	)
	return results


func restore_archived_session(thread_id: String) -> Dictionary:
	var index := _find_session_index(thread_id)
	if index < 0:
		return {}
	var session: Dictionary = threads[index].duplicate(true)
	if session.is_empty() or not bool(session.get("archived", false)):
		return {}
	session["archived"] = false
	session["status"] = "idle"
	threads[index] = session
	return select_thread(thread_id)


func delete_archived_session(thread_id: String) -> Dictionary:
	var index := _find_session_index(thread_id)
	if index < 0:
		return {}
	var session: Dictionary = threads[index].duplicate(true)
	if session.is_empty() or not bool(session.get("archived", false)):
		return {}
	threads.remove_at(index)
	if active_thread_id == thread_id:
		select_thread("")
	return session


func fork_active_session() -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return {}
	var fork := session.duplicate(true)
	fork["id"] = _new_thread_id()
	fork["title"] = "%s 分支" % str(session.get("title", "对话"))
	fork["age"] = "现在"
	fork["archived"] = false
	fork["pinned"] = false
	threads.push_front(fork)
	select_thread(str(fork.get("id", "")))
	return fork


func search_records(query: String) -> Array[Dictionary]:
	var needle := query.strip_edges().to_lower()
	var results: Array[Dictionary] = []
	for item in threads:
		if bool(item.get("archived", false)):
			continue
		var title := str(item.get("title", ""))
		var haystack := title.to_lower()
		for message in item.get("messages", []):
			haystack += "\n%s" % str(message.get("content", "")).to_lower()
		if needle.is_empty() or haystack.find(needle) >= 0:
			results.append({
				"title": "%s%s" % ["★ " if bool(item.get("pinned", false)) else "", title],
				"detail": "会话 · %d 条消息 · %s" % [item.get("messages", []).size(), str(item.get("id", ""))],
				"id": str(item.get("id", "")),
			})
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_id := str(a.get("id", ""))
		var b_id := str(b.get("id", ""))
		var a_session := _find_session(a_id)
		var b_session := _find_session(b_id)
		if bool(a_session.get("pinned", false)) != bool(b_session.get("pinned", false)):
			return bool(a_session.get("pinned", false))
		return str(a.get("title", "")) < str(b.get("title", ""))
	)
	return results


func apply_settings(settings: Dictionary) -> void:
	settings_migrated = false
	var normalized_settings := _normalize_provider_settings(settings)
	provider = str(normalized_settings.get("provider", provider))
	base_url = str(normalized_settings.get("base_url", base_url))
	model = str(normalized_settings.get("model", model))
	api_mode = str(normalized_settings.get("api_mode", api_mode))
	api_key = str(normalized_settings.get("api_key", api_key))
	api_key_env = str(normalized_settings.get("api_key_env", api_key_env))
	endpoint = str(normalized_settings.get("mcp_endpoint", endpoint))
	reasoning_effort = str(normalized_settings.get("reasoning_effort", reasoning_effort))
	skills_enabled = bool(normalized_settings.get("skills_enabled", skills_enabled))
	skill_disabled_paths = _normalized_string_array(normalized_settings.get("skill_disabled_paths", skill_disabled_paths))
	mcp_enabled = bool(normalized_settings.get("mcp_enabled", mcp_enabled))
	command_enabled = bool(normalized_settings.get("command_enabled", command_enabled))
	command_shell = str(normalized_settings.get("command_shell", command_shell))
	command_working_directory = str(normalized_settings.get("command_working_directory", command_working_directory))
	command_timeout_sec = clampi(int(normalized_settings.get("command_timeout_sec", command_timeout_sec)), 1, 300)
	compression_enabled = bool(normalized_settings.get("compression_enabled", compression_enabled))
	ide_context_enabled = bool(normalized_settings.get("ide_context_enabled", ide_context_enabled))
	goal_tracking_enabled = bool(normalized_settings.get("goal_tracking_enabled", goal_tracking_enabled))
	plan_mode_enabled = bool(normalized_settings.get("plan_mode_enabled", plan_mode_enabled))
	sidebar_width = clampf(float(normalized_settings.get("sidebar_width", sidebar_width)), 240.0, 520.0)
	_apply_provider_defaults(false)
	model_label = _model_to_label(model)
	capability_summary = build_capability_summary()


func normalize_runtime_provider() -> bool:
	var previous_settings_migrated := settings_migrated
	var before := {
		"provider": provider,
		"base_url": base_url,
		"model": model,
		"api_mode": api_mode,
		"api_key_env": api_key_env,
	}
	var normalized_settings := _normalize_provider_settings({
		"provider": provider,
		"base_url": base_url,
		"model": model,
		"api_mode": api_mode,
		"api_key_env": api_key_env,
		"api_key": api_key,
	})
	provider = str(normalized_settings.get("provider", provider))
	base_url = str(normalized_settings.get("base_url", base_url))
	model = str(normalized_settings.get("model", model))
	api_mode = str(normalized_settings.get("api_mode", api_mode))
	api_key_env = str(normalized_settings.get("api_key_env", api_key_env))
	_apply_provider_defaults(false)
	model_label = _model_to_label(model)
	capability_summary = build_capability_summary()
	var changed := str(before.get("provider", "")) != provider or str(before.get("base_url", "")) != base_url or str(before.get("model", "")) != model or str(before.get("api_mode", "")) != api_mode or str(before.get("api_key_env", "")) != api_key_env
	settings_migrated = previous_settings_migrated
	return changed


func _normalize_provider_settings(settings: Dictionary) -> Dictionary:
	var normalized := settings.duplicate(true)
	var next_provider := str(normalized.get("provider", provider)).strip_edges()
	var next_base_url := str(normalized.get("base_url", base_url)).strip_edges()
	var next_api_key_env := str(normalized.get("api_key_env", api_key_env)).strip_edges()
	var next_model := str(normalized.get("model", model)).strip_edges()
	if next_api_key_env == "YURENAPI_API_KEY":
		normalized["api_key_env"] = "YUREN_API_KEY"
		next_api_key_env = "YUREN_API_KEY"
		settings_migrated = true
	if next_provider == "yurenapi" or next_base_url.find("yurenapi.com") >= 0 or next_base_url.find("yurenapi.cn") >= 0 or next_api_key_env == "YUREN_API_KEY":
		_apply_provider_preset_to_settings(normalized, "yurenapi", next_model)
	return normalized


func _apply_provider_preset_to_settings(settings: Dictionary, provider_id: String, requested_model: String) -> void:
	var preset := ProviderCatalog.get_provider(provider_id)
	var models := ProviderCatalog.models_for(provider_id)
	var next_model := requested_model if models.has(requested_model) else ProviderCatalog.default_model_for(provider_id)
	var next_api_mode := _provider_api_mode(preset)
	if settings.get("provider", "") != provider_id:
		settings_migrated = true
	settings["provider"] = provider_id
	var current_base_url := str(settings.get("base_url", "")).strip_edges()
	var preferred_base_url := str(preset.get("base_url", "")).strip_edges()
	if not _provider_base_url_allowed(preset, current_base_url):
		settings_migrated = true
		settings["base_url"] = preferred_base_url
	if settings.get("api_key_env", "") != preset.get("api_key_env", ""):
		settings_migrated = true
	settings["api_key_env"] = str(preset.get("api_key_env", ""))
	if str(settings.get("api_mode", "")).strip_edges() != next_api_mode:
		settings_migrated = true
	settings["api_mode"] = next_api_mode
	if settings.get("model", "") != next_model:
		settings_migrated = true
	settings["model"] = next_model


func _provider_base_url_allowed(preset: Dictionary, candidate: String) -> bool:
	var normalized_candidate := candidate.strip_edges().trim_suffix("/")
	var primary := str(preset.get("base_url", "")).strip_edges().trim_suffix("/")
	if normalized_candidate.is_empty():
		return false
	if normalized_candidate == primary:
		return true
	for alternate in preset.get("alternate_base_urls", []):
		if normalized_candidate == str(alternate).strip_edges().trim_suffix("/"):
			return true
	return false


func to_settings() -> Dictionary:
	return {
		"provider": provider,
		"base_url": base_url,
		"model": model,
		"api_mode": api_mode,
		"api_key": api_key,
		"api_key_env": api_key_env,
		"mcp_endpoint": endpoint,
		"reasoning_effort": reasoning_effort,
		"skills_enabled": skills_enabled,
		"skill_disabled_paths": skill_disabled_paths.duplicate(),
		"mcp_enabled": mcp_enabled,
		"command_enabled": command_enabled,
		"command_shell": command_shell,
		"command_working_directory": command_working_directory,
		"command_timeout_sec": command_timeout_sec,
		"compression_enabled": compression_enabled,
		"ide_context_enabled": ide_context_enabled,
		"goal_tracking_enabled": goal_tracking_enabled,
		"plan_mode_enabled": plan_mode_enabled,
		"sidebar_width": sidebar_width,
	}


func api_config_snapshot() -> Dictionary:
	var env_name := api_key_env.strip_edges()
	var env_value := OS.get_environment(env_name) if not env_name.is_empty() else ""
	var inline_key := api_key.strip_edges()
	var resolved_key := env_value.strip_edges() if not env_value.strip_edges().is_empty() else inline_key
	var source := "missing"
	if not env_value.strip_edges().is_empty():
		source = "environment"
	elif not inline_key.is_empty():
		source = "inline"
	return {
		"provider": provider,
		"api_mode": api_mode,
		"model": model,
		"reasoning_effort": reasoning_effort,
		"endpoint": RequestBuilder.endpoint_for(base_url, api_mode),
		"key_source": source,
		"key_env": env_name,
		"has_api_key": not resolved_key.is_empty(),
		"masked_api_key": RequestBuilder.mask_api_key(resolved_key),
		"headers": RequestBuilder.build_headers(resolved_key),
	}


func build_capability_summary() -> Array[Dictionary]:
	var goal := active_goal_record()
	return [
		{
			"title": "OpenAI API",
			"enabled": api_config_snapshot().get("has_api_key", false),
			"detail": _api_config_detail(),
			"risk": "medium",
		},
		{
			"title": "MCP 上下文",
			"enabled": mcp_enabled,
			"detail": endpoint if mcp_enabled else "已禁用，Agent 不会注入项目状态。",
			"risk": "low",
		},
		{
			"title": "Skill 自动触发",
			"enabled": skills_enabled,
			"detail": _skill_capability_detail(),
			"risk": "low",
		},
		{
			"title": "命令行能力",
			"enabled": command_enabled,
			"detail": "%s · %s · %ss，需要审批点。" % [command_shell, command_working_directory, command_timeout_sec] if command_enabled else "已禁用，命令请求只生成审计草案。",
			"risk": "high" if command_enabled else "low",
		},
		{
			"title": "自动上下文压缩",
			"enabled": compression_enabled,
			"detail": _compression_capability_detail(),
			"risk": "low",
		},
		{
			"title": "IDE 上下文",
			"enabled": ide_context_enabled,
			"detail": "会附加当前文件、场景和选择背景。" if ide_context_enabled else "仅使用用户输入和显式上下文。",
			"risk": "low",
		},
		{
			"title": "目标追踪",
			"enabled": bool(goal.get("enabled", false)),
			"detail": "%s · %s" % [_goal_status_label(str(goal.get("status", ""))), str(goal.get("summary", ""))] if bool(goal.get("visible", false)) else "不会额外注入目标状态。",
			"risk": "low",
		},
	]


func set_skill_disabled_paths(paths: Array) -> void:
	skill_disabled_paths = _normalized_string_array(paths)
	capability_summary = build_capability_summary()


func set_skill_registry_model(model: Dictionary) -> void:
	skill_registry_model = model.duplicate(true)
	skill_registry_model["disabled_paths"] = skill_disabled_paths.duplicate()
	capability_summary = build_capability_summary()


func skill_capability_model(skills: Array = []) -> Dictionary:
	var enabled_skills: Array[Dictionary] = []
	for item in skills:
		if not (item is Dictionary):
			continue
		var skill: Dictionary = item
		if bool(skill.get("enabled", true)):
			enabled_skills.append(skill)
	return {
		"enabled": skills_enabled,
		"disabled_paths": skill_disabled_paths.duplicate(),
		"skill_count": skills.size(),
		"enabled_count": enabled_skills.size(),
		"skills": enabled_skills,
	}


func enabled_skill_prompt(skills: Array = [], limit: int = 8) -> String:
	if not skills_enabled:
		return ""
	var enabled_skills: Array[Dictionary] = []
	for item in skills:
		if not (item is Dictionary):
			continue
		var skill: Dictionary = item
		if bool(skill.get("enabled", true)):
			enabled_skills.append(skill)
	if enabled_skills.is_empty():
		return ""
	var lines: Array[String] = [
		"Available local Skills are enabled for this turn. Use them only when they directly match the user request; disabled Skills must be ignored.",
	]
	var count := 0
	for skill in enabled_skills:
		if count >= limit:
			break
		var interface: Dictionary = skill.get("interface", {})
		var name := str(skill.get("name", "")).strip_edges()
		var display_name := str(interface.get("display_name", "")).strip_edges()
		if display_name.is_empty():
			display_name = name
		var description := str(skill.get("short_description", skill.get("description", ""))).strip_edges()
		var policy: Dictionary = skill.get("policy", {})
		var implicit := "implicit-ok" if bool(policy.get("allow_implicit_invocation", true)) else "explicit-only"
		lines.append("- $%s: %s (%s)" % [name, description if not description.is_empty() else display_name, implicit])
		count += 1
	if enabled_skills.size() > limit:
		lines.append("- ...and %d more enabled Skills." % (enabled_skills.size() - limit))
	return "\n".join(lines)


func enabled_skill_prompt_from_registry(limit: int = 8) -> String:
	var skills: Array = skill_registry_model.get("skills", [])
	return enabled_skill_prompt(skills, limit)


func set_model(next_model: String) -> void:
	var clean_model := next_model.strip_edges()
	var available_models := ProviderCatalog.models_for(provider)
	if not available_models.is_empty() and not available_models.has(clean_model):
		clean_model = ProviderCatalog.default_model_for(provider)
	model = clean_model
	model_label = _model_to_label(model)


func set_provider(next_provider: String) -> void:
	provider = next_provider
	_apply_provider_defaults(true)
	model_label = _model_to_label(model)


func _apply_provider_defaults(update_model: bool) -> void:
	var preset: Dictionary = ProviderCatalog.get_provider(provider)
	if update_model or base_url.strip_edges().is_empty():
		base_url = str(preset.get("base_url", base_url))
	if update_model or api_key_env.strip_edges().is_empty() or api_key_env == "OPENAI_API_KEY":
		api_key_env = str(preset.get("api_key_env", api_key_env))
	var preset_api_mode := _provider_api_mode(preset)
	if update_model or api_mode.strip_edges().is_empty() or api_mode not in ["responses", "chat_completions"]:
		api_mode = preset_api_mode
	elif provider == "yurenapi" and api_mode != preset_api_mode:
		api_mode = preset_api_mode
	model_choices.assign(ProviderCatalog.models_for(provider))
	if update_model or not model_choices.has(model):
		model = ProviderCatalog.default_model_for(provider)


func _provider_api_mode(preset: Dictionary) -> String:
	var mode := str(preset.get("api_mode", "responses")).strip_edges()
	return mode if mode in ["responses", "chat_completions"] else "responses"


func _model_to_label(value: String) -> String:
	return value.replace("gpt-", "").replace("-", ".").replace(".mini", "-Mini").replace(".codex", "-Codex").to_upper()


func _api_config_detail() -> String:
	var snapshot := api_config_snapshot()
	var source := str(snapshot.get("key_source", "missing"))
	var suffix := ""
	match source:
		"environment":
			suffix = "环境变量 %s" % str(snapshot.get("key_env", ""))
		"inline":
			suffix = "手动输入 %s" % str(snapshot.get("masked_api_key", ""))
		_:
			suffix = "缺少 API Key"
	return "%s · %s · reasoning:%s · %s" % [provider, model, reasoning_effort, suffix]


func _skill_capability_detail() -> String:
	if not skills_enabled:
		return "已禁用，回合只使用基础提示。"
	var skill_count := int(skill_registry_model.get("skill_count", 0))
	var enabled_count := int(skill_registry_model.get("enabled_count", 0))
	if skill_count <= 0:
		return "按任务匹配本地 Skill；当前未发现本地 Skill。"
	if skill_disabled_paths.is_empty():
		return "按任务匹配本地 Skill；%d 个可用。" % enabled_count
	return "按任务匹配本地 Skill；%d/%d 个可用，%d 个已禁用。" % [enabled_count, skill_count, skill_disabled_paths.size()]


func _compression_capability_detail() -> String:
	var detail := "%d / %d tokens" % [context_used, context_budget]
	var warning := context_window_warning()
	if str(warning.get("status", "")) in ["warning", "auto_ready"]:
		detail += " · %s" % str(warning.get("message", ""))
	if last_compaction.is_empty():
		return detail
	return "%s · 上次压缩 -%d / 保留 %d · %d -> %d" % [
		detail,
		int(last_compaction.get("removed_count", 0)),
		int(last_compaction.get("kept_count", 0)),
		int(last_compaction.get("context_used_before", 0)),
		int(last_compaction.get("context_used_after", 0)),
	]


func _compaction_preview(record: Dictionary) -> Dictionary:
	return {
		"status": str(record.get("status", "")),
		"source": str(record.get("source", "")),
		"automatic": bool(record.get("automatic", false)),
		"removed_count": int(record.get("removed_count", 0)),
		"kept_count": int(record.get("kept_count", 0)),
		"context_used_before": int(record.get("context_used_before", 0)),
		"context_used_after": int(record.get("context_used_after", 0)),
		"context_budget": int(record.get("context_budget", context_budget)),
		"created_at": str(record.get("created_at", "")),
	}


func _compaction_source_label(source: String) -> String:
	match source:
		"auto_prepare_turn":
			return "自动"
		"composer_add_context":
			return "菜单"
		"slash_command":
			return "手动"
		_:
			return source if not source.is_empty() else "手动"


func active_goal_record() -> Dictionary:
	var session := _active_session()
	if session.is_empty():
		return _empty_goal_record(active_thread_id)
	return _normalize_goal_record(session, session.get("active_goal", {}))


func set_active_goal(objective: String, status: String = "active", source: String = "slash_goal") -> Dictionary:
	var session_index := _find_session_index(active_thread_id)
	if session_index < 0:
		return {}
	var session: Dictionary = threads[session_index].duplicate(true)
	var previous: Dictionary = _normalize_goal_record(session, session.get("active_goal", {}))
	var clean_objective := objective.strip_edges()
	if clean_objective.is_empty():
		clean_objective = str(previous.get("objective", "")).strip_edges()
	if clean_objective.is_empty():
		clean_objective = _default_goal_objective(session)
	var normalized_status := _normalize_goal_status(status)
	var now := Time.get_datetime_string_from_system()
	var created_at := str(previous.get("created_at", "")).strip_edges()
	if created_at.is_empty():
		created_at = now
	var goal := {
		"id": str(previous.get("id", "")),
		"thread_id": str(session.get("id", active_thread_id)),
		"objective": clean_objective,
		"summary": _goal_summary(clean_objective),
		"status": normalized_status,
		"enabled": _goal_status_is_enabled(normalized_status),
		"visible": normalized_status != "cleared" and not clean_objective.is_empty(),
		"created_at": created_at,
		"updated_at": now,
		"time_used_seconds": max(0, int(previous.get("time_used_seconds", 0))),
		"tokens_used": max(0, int(previous.get("tokens_used", 0))),
		"token_budget": previous.get("token_budget", null),
		"source": source,
	}
	if str(goal.get("id", "")).is_empty():
		goal["id"] = _new_thread_id().replace("thread", "goal")
	session["active_goal"] = goal
	threads[session_index] = session
	goal_tracking_enabled = bool(goal.get("enabled", false))
	append_model_event("goal_state", goal)
	return _normalize_goal_record(session, goal)


func set_active_goal_enabled(enabled: bool, source: String = "composer_goal_button") -> Dictionary:
	var current := active_goal_record()
	var objective := str(current.get("objective", "")).strip_edges()
	if objective.is_empty():
		objective = _default_goal_objective(_active_session())
	var status := "active" if enabled else "paused"
	return set_active_goal(objective, status, source)


func clear_active_goal(source: String = "slash_goal") -> Dictionary:
	var current := active_goal_record()
	if current.is_empty():
		return {}
	return set_active_goal(str(current.get("objective", "")), "cleared", source)


func active_goal_summary_row() -> Dictionary:
	var goal := active_goal_record()
	var detail := "关闭"
	var enabled := bool(goal.get("enabled", false))
	if bool(goal.get("visible", false)):
		detail = "%s · %s" % [_goal_status_label(str(goal.get("status", ""))), str(goal.get("summary", ""))]
	return {
		"title": "目标追踪",
		"detail": detail,
		"enabled": enabled,
		"risk": "low",
	}


func _active_session() -> Dictionary:
	for item in threads:
		if str(item.get("id", "")) == active_thread_id:
			return item
	return {}


func _append_message_to_session(thread_id: String, role: String, content: String, metadata: Dictionary = {}) -> int:
	var index := _find_session_index(thread_id)
	if index < 0:
		return -1
	var probe := {"role": role, "content": content}
	if not content.strip_edges().is_empty() and _is_local_transcript_noise(probe):
		return -1
	var session: Dictionary = threads[index].duplicate(true)
	var messages = session.get("messages", [])
	if not (messages is Array):
		messages = []
	var message := {"role": role, "content": content}
	var turn_id := str(metadata.get("turn_id", active_turn_id))
	if not turn_id.is_empty():
		message["turn_id"] = turn_id
	for key in metadata.keys():
		if str(key) in ["role", "content"]:
			continue
		message[str(key)] = metadata[key]
	messages.append(message)
	session["messages"] = messages
	session["updated_at"] = Time.get_datetime_string_from_system()
	threads[index] = session
	return messages.size() - 1


func _session_array(session: Dictionary, key: String) -> Array:
	if session.is_empty():
		return []
	var value = session.get(key, [])
	if value is Array:
		return value
	session[key] = []
	return session[key]


func _find_session(thread_id: String) -> Dictionary:
	for item in threads:
		if str(item.get("id", "")) == thread_id:
			return item
	return {}


func _find_session_index(thread_id: String) -> int:
	for index in range(threads.size()):
		if str(threads[index].get("id", "")) == thread_id:
			return index
	return -1


func _resume_session(query: String) -> Dictionary:
	var needle := query.strip_edges().to_lower()
	if needle.is_empty():
		return {}
	for item in threads:
		if bool(item.get("archived", false)):
			continue
		var id := str(item.get("id", ""))
		var title := str(item.get("title", ""))
		if id.to_lower() == needle or title.to_lower().find(needle) >= 0:
			return select_thread(id)
	return {}


func _sync_goal_tracking_from_active_session() -> void:
	var session := _active_session()
	if session.is_empty():
		goal_tracking_enabled = false
		return
	var goal := _normalize_goal_record(session, session.get("active_goal", {}))
	goal_tracking_enabled = bool(goal.get("enabled", false))


func _normalize_subagent_status(status: String) -> String:
	var clean := status.strip_edges().to_lower()
	match clean:
		"queued", "queue", "pending":
			return "queued"
		"running", "active", "working":
			return "running"
		"done", "completed", "complete", "success":
			return "done"
		"failed", "error":
			return "failed"
		"interrupted", "interrupt":
			return "interrupted"
		"handed_off", "handoff":
			return "handed_off"
		"cancelled", "canceled":
			return "cancelled"
		_:
			return "queued" if clean.is_empty() else clean


func _normalize_subagent_notification_status(status: String) -> String:
	var clean := status.strip_edges().to_lower()
	match clean:
		"completed", "complete", "done", "success", "succeeded":
			return "completed"
		"failed", "failure", "error", "errored":
			return "failed"
		"killed", "cancelled", "canceled", "shutdown":
			return "killed"
		"interrupted", "interrupt":
			return "interrupted"
		"running", "started":
			return "running"
		"queued", "pending":
			return "queued"
		_:
			return "completed" if clean.is_empty() else clean


func _normalize_subagent_edge_status(status: String) -> String:
	var clean := status.strip_edges().to_lower()
	match clean:
		"closed", "close", "done", "completed", "complete", "failed", "failure", "error", "killed", "cancelled", "canceled", "interrupted":
			return "closed"
		"open", "running", "started", "queued", "pending":
			return "open"
		_:
			return "open" if clean.is_empty() else clean


func _normalize_optional_subagent_edge_filter(status: String) -> String:
	var clean := status.strip_edges()
	return "" if clean.is_empty() else _normalize_subagent_edge_status(clean)


func _subagent_edge_status_for_notification(status: String) -> String:
	match _normalize_subagent_notification_status(status):
		"running", "queued":
			return "open"
		_:
			return "closed"


func _subagent_notification_task_status(status: String) -> String:
	match _normalize_subagent_notification_status(status):
		"completed":
			return "done"
		"failed":
			return "failed"
		"killed":
			return "cancelled"
		"interrupted":
			return "interrupted"
		"running":
			return "running"
		_:
			return "queued"


func _subagent_edge_status_label(status: String) -> String:
	match _normalize_subagent_edge_status(status):
		"open":
			return "打开"
		"closed":
			return "关闭"
		_:
			return status


func _subagent_notification_status_label(status: String) -> String:
	match _normalize_subagent_notification_status(status):
		"completed":
			return "完成"
		"failed":
			return "失败"
		"killed":
			return "已终止"
		"interrupted":
			return "已中断"
		"running":
			return "运行中"
		"queued":
			return "排队"
		_:
			return status


func _subagent_status_label(status: String) -> String:
	match _normalize_subagent_status(status):
		"queued":
			return "排队"
		"running":
			return "运行中"
		"done":
			return "完成"
		"failed":
			return "失败"
		"cancelled":
			return "已取消"
		"interrupted":
			return "已中断"
		"handed_off":
			return "已交接"
		_:
			return status


func _subagent_summary_suffix(task: Dictionary) -> String:
	var parts: Array[String] = []
	var summary := str(task.get("summary", "")).strip_edges()
	var result := str(task.get("result", "")).strip_edges()
	var error := str(task.get("error", "")).strip_edges()
	if not summary.is_empty():
		parts.append(summary)
	if not result.is_empty():
		parts.append(result)
	if not error.is_empty():
		parts.append("Error: %s" % error.left(120))
	return "\n%s" % "\n".join(parts) if not parts.is_empty() else ""


func _subagent_lifecycle_detail(task: Dictionary) -> String:
	var parts: Array[String] = []
	var status := _normalize_subagent_status(str(task.get("status", "")))
	if status in ["queued", "running"]:
		parts.append("可取消")
	var cancelled_by := str(task.get("cancelled_by", "")).strip_edges()
	if not cancelled_by.is_empty():
		parts.append("取消来源: %s" % cancelled_by)
	var handoff_status := str(task.get("handoff_status", "")).strip_edges()
	if handoff_status == "handed_off":
		var handoff_summary := _short_preview(str(task.get("handoff_summary", "")), 120)
		parts.append("结果已交接%s" % (" · %s" % handoff_summary if not handoff_summary.is_empty() else ""))
	elif status in ["done", "failed", "cancelled", "interrupted"]:
		var result := str(task.get("result", task.get("summary", ""))).strip_edges()
		if not result.is_empty():
			parts.append("可交接")
	return " · ".join(parts)


func _execute_goal_command(args: String) -> Dictionary:
	var clean_args := args.strip_edges()
	var normalized_args := clean_args.to_lower()
	var goal := {}
	if normalized_args in ["off", "false", "0", "关闭", "clear", "清除"]:
		goal = clear_active_goal("slash_goal")
		return _goal_command_payload(goal, "目标追踪已关闭。")
	if normalized_args in ["pause", "paused", "暂停"]:
		goal = set_active_goal_enabled(false, "slash_goal")
		return _goal_command_payload(goal, "目标已暂停。")
	if normalized_args in ["resume", "on", "true", "1", "继续", "恢复", "开启"]:
		goal = set_active_goal_enabled(true, "slash_goal")
		return _goal_command_payload(goal, "目标追踪已开启。")
	if normalized_args in ["complete", "done", "完成"]:
		goal = set_active_goal(str(active_goal_record().get("objective", "")), "complete", "slash_goal")
		return _goal_command_payload(goal, "目标已标记完成。")
	if clean_args.is_empty():
		var current := active_goal_record()
		if bool(current.get("visible", false)):
			return _goal_command_payload(current, "当前目标：%s。" % str(current.get("summary", "")))
		goal = set_active_goal_enabled(true, "slash_goal")
		return _goal_command_payload(goal, "目标追踪已开启。")
	goal = set_active_goal(clean_args, "active", "slash_goal")
	return _goal_command_payload(goal, "目标已设置：%s。" % str(goal.get("summary", "")))


func _goal_command_payload(goal: Dictionary, message: String) -> Dictionary:
	var payload := goal.duplicate(true)
	payload["message"] = message
	payload["goal_tracking_enabled"] = bool(goal.get("enabled", false))
	return payload


func _empty_goal_record(thread_id: String = "") -> Dictionary:
	return {
		"id": "",
		"thread_id": thread_id,
		"objective": "",
		"summary": "",
		"status": "cleared",
		"enabled": false,
		"visible": false,
		"created_at": "",
		"updated_at": "",
		"time_used_seconds": 0,
		"tokens_used": 0,
		"token_budget": null,
		"source": "",
	}


func _normalize_goal_record(session: Dictionary, raw_goal) -> Dictionary:
	var thread_id := str(session.get("id", active_thread_id))
	var goal := _empty_goal_record(thread_id)
	if raw_goal is Dictionary:
		var raw: Dictionary = raw_goal
		goal.merge(raw.duplicate(true), true)
	var objective := str(goal.get("objective", goal.get("text", ""))).strip_edges()
	if objective.is_empty() and bool(goal.get("enabled", false)):
		objective = _default_goal_objective(session)
	var status := _normalize_goal_status(str(goal.get("status", "")))
	if status == "cleared" and bool(goal.get("enabled", false)):
		status = "active"
	goal["thread_id"] = thread_id
	goal["objective"] = objective
	goal["summary"] = _goal_summary(objective)
	goal["status"] = status
	goal["enabled"] = _goal_status_is_enabled(status)
	goal["visible"] = status != "cleared" and not objective.is_empty()
	goal["time_used_seconds"] = max(0, int(goal.get("time_used_seconds", 0)))
	goal["tokens_used"] = max(0, int(goal.get("tokens_used", 0)))
	return goal


func _normalize_goal_status(status: String) -> String:
	var clean := status.strip_edges().to_lower()
	match clean:
		"active", "on", "enabled", "resume", "resumed":
			return "active"
		"paused", "pause", "off", "disabled":
			return "paused"
		"complete", "completed", "done":
			return "complete"
		"blocked":
			return "blocked"
		"cleared", "clear", "false", "0":
			return "cleared"
		_:
			return "cleared" if clean.is_empty() else clean


func _goal_status_is_enabled(status: String) -> bool:
	return status in ["active", "blocked"]


func _goal_status_label(status: String) -> String:
	match _normalize_goal_status(status):
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
			return status


func _default_goal_objective(session: Dictionary) -> String:
	var title := str(session.get("title", active_thread)).strip_edges()
	if title.is_empty() or title == "新对话":
		title = "继续当前会话目标"
	return title


func _goal_summary(objective: String, limit: int = 72) -> String:
	var clean := objective.strip_edges().replace("\n", " ")
	while clean.find("  ") >= 0:
		clean = clean.replace("  ", " ")
	if clean.length() > limit:
		return "%s..." % clean.left(limit).strip_edges()
	return clean


func _short_preview(text: String, limit: int = 120) -> String:
	var clean := text.strip_edges().replace("\n", " ")
	while clean.find("  ") >= 0:
		clean = clean.replace("  ", " ")
	if clean.length() > limit:
		return "%s..." % clean.left(limit).strip_edges()
	return clean


func _normalized_string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			var clean := str(item).strip_edges().replace("\\", "/")
			if clean.is_empty() or result.has(clean):
				continue
			result.append(clean)
	result.sort()
	return result


func _estimate_messages_tokens(messages: Array) -> int:
	var chars := 0
	for item in messages:
		if not (item is Dictionary):
			continue
		chars += str(item.get("role", "")).length()
		chars += str(item.get("content", "")).length()
	return max(1, int(ceil(float(chars) / 4.0)))


func _slash_result(success: bool, command: String, message: String, data: Dictionary = {}, error: String = "") -> Dictionary:
	return {
		"success": success,
		"handled": true,
		"command": command,
		"message": message if success else "命令 /%s 失败：%s。" % [command, error],
		"data": data,
		"error": "" if success else error,
	}


func _new_thread_id() -> String:
	_id_sequence += 1
	var base := "thread_%d_%d_%d" % [Time.get_unix_time_from_system(), Time.get_ticks_msec(), _id_sequence]
	var candidate := base
	var suffix := 2
	while not _find_session(candidate).is_empty():
		candidate = "%s_%d" % [base, suffix]
		suffix += 1
	return candidate


func _new_session_record_id(session: Dictionary, key: String, prefix: String) -> String:
	var base := _new_thread_id().replace("thread", prefix)
	var candidate := base
	var suffix := 2
	var records := _session_array(session, key)
	while _session_record_id_exists(records, candidate):
		candidate = "%s_%d" % [base, suffix]
		suffix += 1
	return candidate


func _session_record_id_exists(records: Array, candidate: String) -> bool:
	for item in records:
		if item is Dictionary and str(item.get("id", "")) == candidate:
			return true
	return false


func _redact_model_event_data(data: Dictionary) -> Dictionary:
	var redacted := data.duplicate(true)
	if redacted.has("headers"):
		redacted["headers"] = _redact_headers(redacted.get("headers", []))
	if redacted.has("transport_request"):
		var transport = redacted.get("transport_request", {})
		if transport is Dictionary and transport.has("headers"):
			transport["headers"] = _redact_headers(transport.get("headers", []))
			redacted["transport_request"] = transport
	if redacted.has("raw"):
		redacted.erase("raw")
	return redacted


func _normalize_tool_call_arguments(arguments) -> Dictionary:
	if arguments is Dictionary:
		return arguments.duplicate(true)
	if arguments is String:
		var parsed = JSON.parse_string(arguments)
		if parsed is Dictionary:
			return parsed
		return {"raw": str(arguments)}
	return {"raw": str(arguments)}


func _schema_summary(schema: Dictionary) -> String:
	var properties: Dictionary = schema.get("properties", {})
	var required: Array = schema.get("required", [])
	if properties.is_empty():
		return "无参数"
	var labels: Array[String] = []
	for key in properties.keys():
		var prop: Dictionary = properties.get(key, {})
		var suffix := "*" if required.has(key) else ""
		labels.append("%s%s:%s" % [str(key), suffix, str(prop.get("type", "any"))])
		if labels.size() >= 4:
			break
	return ", ".join(labels)


func _redact_headers(headers) -> PackedStringArray:
	var safe := PackedStringArray()
	if not (headers is Array or headers is PackedStringArray):
		return safe
	for header in headers:
		var text := str(header)
		if text.to_lower().begins_with("authorization:"):
			safe.append("Authorization: Bearer ****")
		else:
			safe.append(text)
	return safe
