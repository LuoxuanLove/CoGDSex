@tool
class_name GodexMcpClient
extends RefCounted

var endpoint := "http://127.0.0.1:3000/mcp"
var timeout_sec := 10.0


func configure(next_endpoint: String, next_timeout_sec: float = 10.0) -> void:
	endpoint = next_endpoint.strip_edges()
	timeout_sec = next_timeout_sec


func build_tool_context_request(scope: String, limit: int = 50) -> Dictionary:
	var clean_scope := scope.strip_edges().to_lower()
	var clean_limit := maxi(limit, 1)
	match clean_scope:
		"summary":
			return build_tool_call_request("system_project_state", {
				"summary": true,
				"error_limit": mini(clean_limit, 50),
			})
		"scene":
			return build_tool_call_request("system_project_state", {
				"sections": ["project", "files"],
				"error_limit": mini(clean_limit, 50),
			})
		"scripts":
			return build_tool_call_request("system_project_state", {
				"sections": ["files"],
				"error_limit": mini(clean_limit, 50),
			})
		"logs":
			return build_tool_call_request("system_editor_log", {
				"action": "get_errors",
				"include_warnings": true,
				"limit": clean_limit,
			})
		"runtime":
			return build_tool_call_request("system_runtime_diagnose", {
				"tail": mini(clean_limit, 50),
				"include_compile_errors": true,
				"include_gd_errors": true,
			})
		_:
			return build_tool_call_request("system_project_state", {
				"summary": true,
				"error_limit": mini(clean_limit, 50),
			})


func build_tool_call_request(tool_name: String, arguments: Dictionary = {}) -> Dictionary:
	return {
		"endpoint": endpoint,
		"method": "tools/call",
		"tool": tool_name,
		"arguments": arguments.duplicate(true),
		"body": _build_json_rpc_body("tools/call", {
			"name": tool_name,
			"arguments": arguments.duplicate(true),
		}),
		"timeout_sec": timeout_sec,
	}


func build_tools_list_request() -> Dictionary:
	return {
		"endpoint": endpoint,
		"method": "tools/list",
		"arguments": {},
		"body": _build_json_rpc_body("tools/list", {}),
		"timeout_sec": timeout_sec,
	}


func parse_tools_list_response(response_body: String) -> Dictionary:
	var parsed = JSON.parse_string(response_body)
	if not (parsed is Dictionary):
		return _error("invalid_json", "MCP tools/list response was not valid JSON.")
	if parsed.has("error"):
		return _parse_error(parsed.get("error", {}))
	var result: Dictionary = parsed.get("result", parsed)
	var tools_value = _extract_tools_array(result)
	if not (tools_value is Array):
		return _error("missing_tools", "MCP tools/list response did not include a tools array.")
	var tools: Array[Dictionary] = []
	for item in tools_value:
		if not (item is Dictionary):
			continue
		tools.append(_normalize_tool_definition(item))
	return {
		"success": true,
		"tools": tools,
		"count": tools.size(),
	}


func parse_tool_call_response(response_body: String) -> Dictionary:
	var parsed = JSON.parse_string(response_body)
	if not (parsed is Dictionary):
		return _tool_error("invalid_json", "MCP tools/call response was not valid JSON.")
	if parsed.has("error"):
		return _parse_tool_error(parsed.get("error", {}))
	var result: Dictionary = parsed.get("result", parsed)
	var content: Array = []
	var text_parts: Array[String] = []
	for item in result.get("content", []):
		if not (item is Dictionary):
			continue
		content.append(item)
		if str(item.get("type", "")) == "text":
			text_parts.append(str(item.get("text", "")))
	var text := "\n".join(text_parts)
	var parsed_text = JSON.parse_string(text) if not text.strip_edges().is_empty() else null
	var is_error := bool(result.get("isError", false))
	if parsed_text is Dictionary and parsed_text.has("success") and not bool(parsed_text.get("success", true)):
		is_error = true
	var message := _tool_result_message(result, parsed_text, text)
	return {
		"success": not is_error,
		"error": _tool_result_error(parsed_text, result) if is_error else "",
		"message": message,
		"content": content,
		"text": text,
		"data": parsed_text if parsed_text is Dictionary else {},
		"is_error": is_error,
	}


func health_snapshot() -> Dictionary:
	return {
		"endpoint": endpoint,
		"configured": endpoint.begins_with("http://") or endpoint.begins_with("https://"),
		"transport": "streamable-http",
	}


func _extract_tools_array(result: Dictionary):
	if result.get("tools", []) is Array and not result.get("tools", []).is_empty():
		return result.get("tools", [])
	var grouped: Array = []
	for group in result.get("toolGroups", []):
		if not (group is Dictionary):
			continue
		var group_name := str(group.get("name", group.get("title", "")))
		for tool in group.get("tools", []):
			if not (tool is Dictionary):
				continue
			var normalized: Dictionary = tool.duplicate(true)
			normalized["group"] = group_name
			grouped.append(normalized)
	return grouped


func _build_json_rpc_body(method: String, params: Dictionary) -> Dictionary:
	return {
		"jsonrpc": "2.0",
		"id": "godex_%d" % Time.get_ticks_msec(),
		"method": method,
		"params": params,
	}


func _normalize_tool_definition(item: Dictionary) -> Dictionary:
	var input_schema = item.get("inputSchema", item.get("input_schema", {}))
	return {
		"name": str(item.get("name", "")),
		"title": str(item.get("title", item.get("name", ""))),
		"description": str(item.get("description", "")),
		"group": str(item.get("group", "")),
		"input_schema": input_schema if input_schema is Dictionary else {},
	}


func _parse_error(payload) -> Dictionary:
	if payload is Dictionary:
		return _error(str(payload.get("code", payload.get("type", "mcp_error"))), str(payload.get("message", "")))
	return _error("mcp_error", str(payload))


func _parse_tool_error(payload) -> Dictionary:
	if payload is Dictionary:
		return _tool_error(str(payload.get("code", payload.get("type", "mcp_error"))), str(payload.get("message", "")))
	return _tool_error("mcp_error", str(payload))


func _error(code: String, message: String) -> Dictionary:
	return {
		"success": false,
		"error": code,
		"message": message,
		"tools": [],
		"count": 0,
	}


func _tool_error(code: String, message: String) -> Dictionary:
	return {
		"success": false,
		"error": code,
		"message": message,
		"content": [],
		"text": "",
		"data": {},
		"is_error": true,
	}


func _tool_result_message(result: Dictionary, parsed_text, text: String) -> String:
	if parsed_text is Dictionary:
		if not str(parsed_text.get("message", "")).is_empty():
			return str(parsed_text.get("message", ""))
		if not str(parsed_text.get("summary", "")).is_empty():
			return str(parsed_text.get("summary", ""))
		if parsed_text.has("data"):
			return _tool_data_summary(parsed_text.get("data", {}))
	if result.has("message"):
		return str(result.get("message", ""))
	return text.left(500)


func _tool_data_summary(data) -> String:
	if not (data is Dictionary):
		return str(data).left(500)
	var dict: Dictionary = data
	var parts: Array[String] = []
	for key in ["project_name", "main_scene", "current_scene", "godot_version_string", "runtime_status"]:
		if dict.has(key):
			parts.append("%s=%s" % [key, str(dict.get(key, ""))])
	for key in ["scripts", "scenes", "resources", "error_count", "warning_count", "compile_error_count"]:
		if dict.has(key):
			parts.append("%s=%s" % [key, str(dict.get(key, ""))])
	if parts.is_empty():
		var labels: Array[String] = []
		for key in dict.keys():
			labels.append(str(key))
			if labels.size() >= 8:
				break
		parts.append("keys=%s" % ", ".join(labels))
	return "MCP data summary: %s" % " · ".join(parts)


func _tool_result_error(parsed_text, result: Dictionary) -> String:
	if parsed_text is Dictionary:
		if not str(parsed_text.get("error", "")).is_empty():
			return str(parsed_text.get("error", ""))
		if not str(parsed_text.get("message", "")).is_empty():
			return str(parsed_text.get("message", ""))
	if not str(result.get("error", "")).is_empty():
		return str(result.get("error", ""))
	return "mcp_tool_error"
