@tool
class_name GodexSessionStore
extends RefCounted

const SESSIONS_PATH := "user://godex/sessions.json"


func load_sessions() -> Dictionary:
	if not FileAccess.file_exists(SESSIONS_PATH):
		return _default_payload()
	var file := FileAccess.open(SESSIONS_PATH, FileAccess.READ)
	if file == null:
		return _default_payload()
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and parsed.has("sessions"):
		return parsed
	return _default_payload()


func save_sessions(active_thread_id: String, sessions: Array, approval_records: Array = []) -> Dictionary:
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("godex")
	var file := FileAccess.open(SESSIONS_PATH, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "open_failed"}
	file.store_string(JSON.stringify({
		"active_thread_id": active_thread_id,
		"sessions": sessions,
		"approval_records": approval_records,
	}, "\t"))
	return {"success": true, "path": SESSIONS_PATH}


func _default_payload() -> Dictionary:
	return {
		"active_thread_id": "quick_chat",
		"sessions": [
			{
				"id": "quick_chat",
				"title": "快速对话",
				"status": "active",
				"age": "现在",
				"action": "chat",
				"archived": false,
				"pinned": false,
				"messages": [
					{"role": "assistant", "content": "Godex 已接入当前 Godot 编辑器。你可以直接要求我检查场景、读取日志、规划修改，或调用项目内 MCP 能力。"},
				],
				"model_events": [],
			},
			{
				"id": "mcp_status",
				"title": "检查 MCP 插件连接",
				"status": "idle",
				"age": "现在",
				"action": "inspect_mcp",
				"archived": false,
				"pinned": false,
				"messages": [],
				"model_events": [],
			},
			{
				"id": "runtime_triage",
				"title": "整理场景运行问题",
				"status": "idle",
				"age": "12 分",
				"action": "show_runtime_plan",
				"archived": false,
				"pinned": false,
				"messages": [],
				"model_events": [],
			},
			{
				"id": "ui_plan",
				"title": "生成 UI 调整计划",
				"status": "idle",
				"age": "36 分",
				"action": "show_ui_plan",
				"archived": false,
				"pinned": false,
				"messages": [],
				"model_events": [],
			},
		],
	}
