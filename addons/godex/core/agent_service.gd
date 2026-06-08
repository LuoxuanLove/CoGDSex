@tool
class_name GodexAgentService
extends RefCounted

const OpenAIRequestBuilder = preload("res://addons/godex/core/openai_request_builder.gd")
const CONTEXT_COMPRESSOR_SCRIPT_PATH := "res://addons/godex/core/context_compressor.gd"
const OPENAI_EXECUTION_SCRIPT_PATH := "res://addons/godex/core/openai_execution_service.gd"
const SUBAGENT_MANAGER_SCRIPT_PATH := "res://addons/godex/core/subagent_manager.gd"
const MCP_CLIENT_SCRIPT_PATH := "res://addons/godex/core/mcp_client.gd"
const APPROVAL_POLICY_SCRIPT_PATH := "res://addons/godex/core/approval_policy.gd"
const COMMAND_CAPABILITY_SCRIPT_PATH := "res://addons/godex/core/command_capability.gd"
const MAX_EXPLICIT_SKILL_INJECTIONS := 4

var _state: RefCounted
var _messages: Array[Dictionary] = []
var _compressor: RefCounted
var _openai: RefCounted
var _subagents: RefCounted
var _mcp: RefCounted
var _approval: RefCounted
var _command: RefCounted


func setup(state: RefCounted) -> void:
	_state = state
	_create_services()
	_mcp.call("configure", _state.endpoint)


func _create_services() -> void:
	_compressor = _new_service(CONTEXT_COMPRESSOR_SCRIPT_PATH)
	_openai = _new_service(OPENAI_EXECUTION_SCRIPT_PATH)
	_subagents = _new_service(SUBAGENT_MANAGER_SCRIPT_PATH)
	_mcp = _new_service(MCP_CLIENT_SCRIPT_PATH)
	_approval = _new_service(APPROVAL_POLICY_SCRIPT_PATH)
	_command = _new_service(COMMAND_CAPABILITY_SCRIPT_PATH)


func _new_service(path: String) -> RefCounted:
	var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if script == null:
		push_error("[Godex] Failed to load agent service dependency: %s" % path)
		return RefCounted.new()
	return script.new()


func _normalize_runtime_provider() -> void:
	if _state != null and _state.has_method("normalize_runtime_provider"):
		_state.call("normalize_runtime_provider")


func set_messages(messages: Array) -> void:
	_messages.assign(messages)


func prepare_turn(prompt: String, references: Array = []) -> Dictionary:
	_normalize_runtime_provider()
	var user_message := {"role": "user", "content": prompt}
	if not references.is_empty():
		user_message["references"] = references.duplicate(true)
	_messages.append(user_message)
	var explicit_skill_injections := _explicit_skill_injections(prompt)
	var audit := {
		"endpoint": OpenAIRequestBuilder.endpoint_for(_state.base_url, _state.api_mode),
		"payload_mode": _state.api_mode,
		"compression": {},
		"mcp_request": {},
		"approval": {},
		"subagent": {},
		"command_request": {},
		"api_config": {},
		"openai_request": {},
		"plan_mode": {},
		"goal": {},
		"guide_instruction": {},
		"skills": {
			"available_count": int(_state.get("skill_registry_model").get("enabled_count", 0)) if _state.get("skill_registry_model") is Dictionary else 0,
			"explicit": explicit_skill_injections.map(func(item: Dictionary): return str(item.get("name", ""))),
		},
	}
	if _state.compression_enabled and bool(_compressor.call("should_compress", _state.context_used, _state.context_budget, _state.AUTO_COMPACT_THRESHOLD_RATIO)):
		_state.call("replace_active_messages", _messages)
		var compacted: Dictionary = _state.call("auto_compact_active_session", 24, _state.context_used, _state.context_budget)
		if bool(compacted.get("success", false)):
			_messages.assign(compacted.get("messages", []))
			audit["compression"] = {
				"compressed": true,
				"summary": str(compacted.get("summary", "")),
				"removed_count": int(compacted.get("removed_count", 0)),
				"kept_count": int(compacted.get("kept_count", 0)),
				"context_used_before": int(compacted.get("context_used_before", 0)),
				"context_used_after": int(compacted.get("context_used_after", 0)),
				"context_budget": int(compacted.get("context_budget", 0)),
				"source": str(compacted.get("source", "")),
			}
			_state.call("record_stream_step", "自动压缩旧上下文", "已完成")
		else:
			audit["compression"] = {"compressed": false, "summary": "", "error": str(compacted.get("error", ""))}
	else:
		audit["compression"] = {"compressed": false, "summary": ""}
	var guide_instruction: Dictionary = _state.call("active_pending_guide_instruction")
	audit["guide_instruction"] = guide_instruction
	if not guide_instruction.is_empty():
		_state.call("record_stream_step", "指南指令：%s" % _preview_text(str(guide_instruction.get("instructions", "")), 64), "待注入")
	var payload := _build_openai_payload(explicit_skill_injections)
	if not guide_instruction.is_empty():
		var submitted: Dictionary = _state.call("mark_pending_steer_submitted", str(guide_instruction.get("id", "")), str(_state.get("active_turn_id")))
		if not submitted.is_empty():
			audit["guide_instruction"] = submitted
			_state.call("record_stream_step", "指南指令", "已注入")
	if bool(_state.plan_mode_enabled):
		audit["plan_mode"] = {
			"enabled": true,
			"tools_enabled": false,
			"source": "codex_plan_mode",
		}
		_state.call("append_model_event", "plan_mode", {
			"status": "active",
			"enabled": true,
			"detail": "工具调用已禁用；本轮只规划，不执行修改。",
		})
		_state.call("record_stream_step", "计划模式", "只规划")
	else:
		audit["plan_mode"] = {"enabled": false, "tools_enabled": true}
	var active_goal: Dictionary = _state.call("active_goal_record")
	audit["goal"] = active_goal
	if bool(active_goal.get("enabled", false)):
		_state.call("record_stream_step", "目标追踪：%s" % str(active_goal.get("summary", "")), _goal_status_label(str(active_goal.get("status", ""))))
	var api_config: Dictionary = _state.call("api_config_snapshot")
	var request_snapshot: Dictionary = _openai.call("build_request_snapshot", api_config, payload)
	var transport_request: Dictionary = _openai.call("build_transport_request", api_config, payload)
	audit["api_config"] = {
		"ready": bool(request_snapshot.get("ready", false)),
		"provider": str(request_snapshot.get("provider", "")),
		"endpoint": str(request_snapshot.get("endpoint", "")),
		"key_source": str(request_snapshot.get("key_source", "missing")),
		"masked_api_key": str(request_snapshot.get("masked_api_key", "")),
	}
	audit["openai_request"] = request_snapshot
	audit["openai_request"]["plan_mode"] = bool(_state.plan_mode_enabled)
	audit["openai_request"]["tool_count"] = int(payload.get("tools", []).size())
	var model_event: Dictionary = _state.call("append_model_event", "openai_request", {
		"status": "ready" if bool(request_snapshot.get("ready", false)) else "blocked",
		"error": str(request_snapshot.get("error", "")),
		"provider": str(request_snapshot.get("provider", "")),
		"endpoint": str(request_snapshot.get("endpoint", "")),
		"api_mode": str(request_snapshot.get("api_mode", "")),
		"model": str(request_snapshot.get("model", "")),
		"reasoning_effort": str(request_snapshot.get("reasoning_effort", "")),
		"plan_mode": bool(_state.plan_mode_enabled),
		"tool_count": int(payload.get("tools", []).size()),
		"key_source": str(request_snapshot.get("key_source", "missing")),
		"headers": request_snapshot.get("headers", PackedStringArray()),
	})
	audit["model_event"] = model_event
	_state.call("record_stream_step", "构建 OpenAI %s 请求" % _state.api_mode, "已完成")
	_state.call("record_stream_step", "检查 API 认证：%s" % str(audit["api_config"].get("key_source", "missing")), "已完成" if bool(request_snapshot.get("ready", false)) else "已阻塞")
	if _state.mcp_enabled:
		var mcp_context: Dictionary = _mcp.call("build_tool_context_request", "summary", 50)
		var approval: Dictionary = _approval.call("build_checkpoint", "mcp_context", "读取当前 Godot 项目摘要并注入本轮上下文。")
		var health: Dictionary = _mcp.call("health_snapshot")
		audit["mcp_request"] = mcp_context
		audit["approval"] = approval
		_state.call("record_approval_checkpoint", approval)
		_state.call("record_stream_step", "准备 MCP 上下文请求：%s" % str(mcp_context.get("tool", "")), "已完成")
		_state.call("record_stream_step", "审批策略：%s 风险" % str(approval.get("risk", "")), "已完成" if bool(not approval.get("requires_approval", true)) else "等待审批")
	else:
		_state.call("record_stream_step", "MCP 上下文已禁用", "已完成")
	if _state.skills_enabled:
		_state.call("append_model_event", "skill_context", {
			"status": "available",
			"enabled_count": int(_state.get("skill_registry_model").get("enabled_count", 0)) if _state.get("skill_registry_model") is Dictionary else 0,
			"explicit_count": explicit_skill_injections.size(),
		})
		_state.call("record_stream_step", "Skill 上下文", "已准备")
	else:
		_state.call("record_stream_step", "Skill / 子代理自动触发已禁用", "已完成")
	_command.set("enabled", _state.command_enabled)
	_command.set("shell", _state.command_shell)
	var command_request: Dictionary = _command.call("build_request", "pwd")
	audit["command_request"] = command_request
	_state.capability_summary = _state.call("build_capability_summary")
	return {
		"payload": payload,
		"transport_request": transport_request,
		"audit": audit,
		"preview": _build_preview(request_snapshot),
	}


func handle_model_response(api_mode: String, response_body: String, metadata: Dictionary = {}) -> Dictionary:
	var parsed: Dictionary = _openai.call("parse_response", api_mode, response_body)
	var event: Dictionary = _state.call("append_model_event", "openai_response", {
		"status": "ok" if bool(parsed.get("success", false)) else "error",
		"error": str(parsed.get("error", "")),
		"message": str(parsed.get("message", "")),
		"text": str(parsed.get("text", "")),
		"response_id": str(parsed.get("response_id", "")),
		"model": _state.model,
		"api_mode": api_mode,
		"tool_call_count": parsed.get("tool_calls", []).size(),
		"source": str(metadata.get("source", "")),
		"fixture_name": str(metadata.get("fixture_name", "")),
		"raw": parsed.get("raw", {}),
	})
	parsed["model_event"] = event
	if bool(parsed.get("success", false)):
		parsed["tool_call_records"] = _state.call("record_tool_calls", parsed.get("tool_calls", []), str(event.get("id", "")))
	else:
		parsed["tool_call_records"] = []
	return parsed


func handle_model_http_result(api_mode: String, status_code: int, response_body: String, metadata: Dictionary = {}) -> Dictionary:
	var parsed: Dictionary = _openai.call("parse_http_result", api_mode, status_code, response_body)
	var event: Dictionary = _state.call("append_model_event", "openai_response", {
		"status": "ok" if bool(parsed.get("success", false)) else "error",
		"error": str(parsed.get("error", "")),
		"message": str(parsed.get("message", "")),
		"text": str(parsed.get("text", "")),
		"response_id": str(parsed.get("response_id", "")),
		"status_code": status_code,
		"model": _state.model,
		"api_mode": api_mode,
		"tool_call_count": parsed.get("tool_calls", []).size(),
		"source": str(metadata.get("source", "")),
		"fixture_name": str(metadata.get("fixture_name", "")),
		"raw": parsed.get("raw", {}),
	})
	parsed["model_event"] = event
	if bool(parsed.get("success", false)):
		parsed["tool_call_records"] = _state.call("record_tool_calls", parsed.get("tool_calls", []), str(event.get("id", "")))
	else:
		parsed["tool_call_records"] = []
	return parsed


func parse_stream_data(api_mode: String, data: String) -> Dictionary:
	return _openai.call("parse_stream_data", api_mode, data)


func parse_stream_residual(api_mode: String, residual: String) -> Dictionary:
	return _openai.call("parse_stream_residual", api_mode, residual)


func inject_mcp_context_probe(scope: String = "summary", limit: int = 20) -> Dictionary:
	if _state.call("active_messages").is_empty():
		_state.call("new_session")
	if str(_state.get("agent_loop_status")) != "running":
		_state.call("begin_agent_loop", "local_mcp_probe")
	_state.call("record_agent_loop_step", "local_mcp_probe", "%s · %d" % [scope, limit])
	var source_event: Dictionary = _state.call("append_model_event", "local_tool_probe", {
		"status": "created",
		"tool": "godex_mcp_context",
		"scope": scope,
		"limit": limit,
	})
	var records: Array = _state.call("record_tool_calls", [
		{
			"id": "probe_%d" % Time.get_ticks_msec(),
			"name": "godex_mcp_context",
			"arguments": {
				"scope": scope,
				"limit": limit,
			},
		},
	], str(source_event.get("id", "")))
	_state.call("record_stream_step", "注入 MCP 测试工具调用：%s" % scope, "已完成" if not records.is_empty() else "失败")
	return {
		"success": not records.is_empty(),
		"tool_call": records[0] if not records.is_empty() else {},
		"model_event": source_event,
	}


func inject_model_response_replay() -> Dictionary:
	if _state.call("active_messages").is_empty():
		_state.call("new_session")
	if str(_state.get("agent_loop_status")) != "running":
		_state.call("begin_agent_loop", "local_model_replay")
	_state.call("record_agent_loop_step", "local_model_replay", "responses fixture")
	var fixture_name := "mcp_context_tool_call"
	var fixture := {
		"output": [
			{
				"type": "message",
				"content": [
					{
						"type": "output_text",
						"text": "本地模型回放：我会先读取当前 Godot 项目摘要，然后等待工具执行结果。",
					},
				],
			},
			{
				"type": "function_call",
				"call_id": "replay_%d" % Time.get_ticks_msec(),
				"name": "godex_mcp_context",
				"arguments": JSON.stringify({"scope": "summary", "limit": 20}),
			},
		],
	}
	var response_body := JSON.stringify(fixture)
	_state.call("append_model_event", "openai_transport", {
		"status": "replayed",
		"source": "local_model_replay",
		"api_mode": "responses",
		"model": _state.model,
		"body_length": response_body.length(),
		"fixture_name": fixture_name,
	})
	var parsed := handle_model_response("responses", response_body, {
		"source": "local_model_replay",
		"fixture_name": fixture_name,
	})
	_state.call("record_stream_step", "本地模型回放", "已完成" if bool(parsed.get("success", false)) else "失败")
	return parsed


func dispatch_next_tool_call() -> Dictionary:
	var pending: Array = _state.call("pending_tool_calls")
	if pending.is_empty():
		return {"success": false, "error": "no_pending_tool_call", "message": "No pending tool call is available."}
	var tool_call: Dictionary = pending[0]
	return dispatch_tool_call(str(tool_call.get("id", "")))


func dispatch_tool_call(tool_call_id: String) -> Dictionary:
	var tool_call := _find_tool_call(tool_call_id)
	if tool_call.is_empty():
		return {"success": false, "error": "tool_call_not_found", "tool_call_id": tool_call_id}
	var tool_name := str(tool_call.get("name", ""))
	if tool_name == "exec_command":
		return _dispatch_exec_command_tool_call(tool_call)
	if tool_name == "write_stdin":
		return _dispatch_unsupported_write_stdin(tool_call)
	var arguments: Dictionary = tool_call.get("arguments", {})
	var classification: Dictionary = _approval.call("classify_action", "mcp_tool:%s" % tool_name)
	var risk := str(classification.get("risk", "low"))
	var auto_allowed := _tool_call_auto_allowed(risk, bool(classification.get("requires_approval", true)))
	var action := "mcp_tool:%s" % tool_name
	var has_approval := _has_approved_tool_call_checkpoint(action, tool_call_id)
	if str(tool_call.get("status", "")) == "pending" and not auto_allowed and not has_approval:
		var checkpoint: Dictionary = _approval.call("build_checkpoint", action, "Dispatch MCP tool call %s." % tool_name)
		checkpoint["tool_call_id"] = tool_call_id
		_state.call("record_approval_checkpoint", checkpoint)
		return {
			"success": false,
			"blocked": true,
			"error": "approval_required",
			"tool_call": tool_call,
			"approval": checkpoint,
		}
	if str(tool_call.get("status", "")) == "pending":
		tool_call = _state.call("decide_tool_call", tool_call_id, "approve")
	var request: Dictionary = _build_mcp_dispatch_request(tool_name, arguments)
	var event: Dictionary = _state.call("append_model_event", "mcp_tool_dispatch", {
		"status": "ready",
		"tool_call_id": tool_call_id,
		"tool": tool_name,
		"endpoint": str(request.get("endpoint", "")),
		"method": str(request.get("method", "")),
		"arguments": arguments,
	})
	var result := {
		"request": request,
		"event_id": str(event.get("id", "")),
	}
	_state.call("update_tool_call_status", tool_call_id, "dispatch_ready", result)
	return {
		"success": true,
		"tool_call_id": tool_call_id,
		"tool": tool_name,
		"request": request,
		"model_event": event,
	}


func begin_tool_call_execution(tool_call_id: String) -> Dictionary:
	var tool_call := _find_tool_call(tool_call_id)
	if tool_call.is_empty():
		return {"success": false, "error": "tool_call_not_found", "tool_call_id": tool_call_id}
	var result: Dictionary = tool_call.get("result", {})
	var request: Dictionary = result.get("request", {})
	if request.is_empty():
		return {"success": false, "error": "missing_dispatch_request", "tool_call_id": tool_call_id}
	var event: Dictionary = _state.call("append_model_event", "mcp_tool_transport", {
		"status": "request_starting",
		"tool_call_id": tool_call_id,
		"tool": str(request.get("tool", "")),
		"endpoint": str(request.get("endpoint", "")),
		"method": str(request.get("method", "")),
	})
	_state.call("update_tool_call_status", tool_call_id, "executing", {
		"request": request,
		"event_id": str(event.get("id", "")),
	})
	return {
		"success": true,
		"tool_call_id": tool_call_id,
		"request": request,
		"model_event": event,
	}


func handle_mcp_tool_call_response(tool_call_id: String, response_body: String) -> Dictionary:
	var parsed: Dictionary = _mcp.call("parse_tool_call_response", response_body)
	var status := "succeeded" if bool(parsed.get("success", false)) else "failed"
	var tool_call := _find_tool_call(tool_call_id)
	var parsed_data = parsed.get("data", {})
	if bool(parsed.get("success", false)) and parsed_data is Dictionary:
		_state.call("apply_project_summary", parsed_data)
	var event: Dictionary = _state.call("append_model_event", "mcp_tool_result", {
		"status": status,
		"tool_call_id": tool_call_id,
		"tool": str(tool_call.get("name", "")),
		"error": str(parsed.get("error", "")),
		"message": str(parsed.get("message", "")),
		"is_error": bool(parsed.get("is_error", false)),
	})
	_state.call("update_tool_call_status", tool_call_id, status, {
		"event_id": str(event.get("id", "")),
		"message": str(parsed.get("message", "")),
		"error": str(parsed.get("error", "")),
		"data": parsed.get("data", {}),
	})
	parsed["model_event"] = event
	return parsed


func _dispatch_exec_command_tool_call(tool_call: Dictionary) -> Dictionary:
	var tool_call_id := str(tool_call.get("id", ""))
	var command_id := "command_%s" % tool_call_id
	var command_run: Dictionary = _state.call("command_run_by_id", command_id)
	if command_run.is_empty():
		return {"success": false, "error": "command_run_not_found", "tool_call_id": tool_call_id}
	if str(command_run.get("status", "")) == "queued":
		var approval: Dictionary = _state.call("request_command_run_approval", command_id)
		return {
			"success": false,
			"blocked": str(command_run.get("status", "")) != "approved",
			"error": "approval_required" if not approval.is_empty() else "command_approval_failed",
			"tool_call_id": tool_call_id,
			"tool": "exec_command",
			"command_id": command_id,
			"approval": approval,
			"command_run": _state.call("command_run_by_id", command_id),
		}
	if str(command_run.get("status", "")) == "approved":
		_state.call("update_tool_call_status", tool_call_id, "dispatch_ready", {
			"request": {
				"tool": "exec_command",
				"command_id": command_id,
				"command": str(command_run.get("command", "")),
			},
			"command_run": command_run,
		})
		return {
			"success": true,
			"tool_call_id": tool_call_id,
			"tool": "exec_command",
			"command_id": command_id,
			"command_run": command_run,
			"request": {
				"tool": "exec_command",
				"command_id": command_id,
				"command": str(command_run.get("command", "")),
			},
		}
	return {
		"success": false,
		"blocked": true,
		"error": str(command_run.get("status", "command_not_ready")),
		"tool_call_id": tool_call_id,
		"tool": "exec_command",
		"command_id": command_id,
		"command_run": command_run,
	}


func handle_exec_command_tool_result(tool_call_id: String, command_result: Dictionary) -> Dictionary:
	var tool_call := _find_tool_call(tool_call_id)
	if tool_call.is_empty():
		return {"success": false, "error": "tool_call_not_found", "tool_call_id": tool_call_id}
	var command_run: Dictionary = command_result.get("command_run", {})
	var status := str(command_run.get("status", "failed"))
	var succeeded := status in ["completed", "succeeded"]
	var result: Dictionary = command_run.get("result", {})
	var message := str(result.get("combined_output", result.get("stdout", result.get("stderr", "")))).strip_edges()
	if message.is_empty():
		message = str(command_result.get("message", "Command finished with status %s." % status))
	var event: Dictionary = _state.call("append_model_event", "command_tool_result", {
		"status": "succeeded" if succeeded else "failed",
		"tool_call_id": tool_call_id,
		"tool": "exec_command",
		"command_id": str(command_result.get("command_id", "")),
		"command_status": status,
		"exit_code": int(result.get("exit_code", -1)),
		"message": message,
	})
	_state.call("update_tool_call_status", tool_call_id, "succeeded" if succeeded else "failed", {
		"event_id": str(event.get("id", "")),
		"message": message,
		"error": "" if succeeded else str(result.get("stderr", command_result.get("error", status))),
		"data": {
			"command_run": command_run,
			"result": result,
		},
	})
	return {
		"success": succeeded,
		"tool_call_id": tool_call_id,
		"command_run": command_run,
		"message": message,
		"model_event": event,
	}


func _dispatch_unsupported_write_stdin(tool_call: Dictionary) -> Dictionary:
	return {
		"success": false,
		"blocked": true,
		"error": "interactive_command_sessions_not_available",
		"tool_call_id": str(tool_call.get("id", "")),
		"tool": "write_stdin",
		"message": "write_stdin requires a live exec session; Godex has not implemented the interactive process manager yet.",
	}


func build_tool_result_continuation(tool_call_id: String) -> Dictionary:
	var tool_call := _find_tool_call(tool_call_id)
	if tool_call.is_empty():
		return {"success": false, "error": "tool_call_not_found", "tool_call_id": tool_call_id}
	var status := str(tool_call.get("status", ""))
	if status not in ["succeeded", "failed", "completed", "continuation_ready", "continuation_blocked"]:
		return {"success": false, "error": "tool_result_not_ready", "tool_call_id": tool_call_id, "status": status}
	var unresolved: Array = _state.call("unresolved_tool_calls", tool_call_id)
	if not unresolved.is_empty():
		var event: Dictionary = _state.call("append_model_event", "openai_continuation_request", {
			"status": "blocked",
			"error": "unresolved_tool_calls",
			"tool_call_id": tool_call_id,
			"tool": str(tool_call.get("name", "")),
			"unresolved_count": unresolved.size(),
		})
		_state.call("update_tool_call_continuation", tool_call_id, "blocked", {
			"event_id": str(event.get("id", "")),
			"error": "unresolved_tool_calls",
			"message": "Waiting for %d unresolved tool call(s)." % unresolved.size(),
		})
		var blocked_continuation := {
			"success": false,
			"blocked": true,
			"error": "unresolved_tool_calls",
			"tool_call_id": tool_call_id,
			"unresolved_count": unresolved.size(),
			"model_event": event,
		}
		_state.call("set_pending_openai_continuation", blocked_continuation)
		return blocked_continuation
	_normalize_runtime_provider()
	var result: Dictionary = tool_call.get("result", {})
	var tool_output := _build_tool_output_for_model(tool_call, result)
	var payload := _build_openai_tool_result_payload(tool_call, tool_output)
	var previous_response_id := str(payload.get("previous_response_id", "")).strip_edges()
	var api_config: Dictionary = _state.call("api_config_snapshot")
	var request_snapshot: Dictionary = _openai.call("build_request_snapshot", api_config, payload)
	var transport_request: Dictionary = _openai.call("build_transport_request", api_config, payload)
	var payload_text := JSON.stringify(payload)
	var payload_input_count := _payload_input_count(payload)
	var payload_fingerprint := str(payload_text.hash())
	transport_request["source"] = "tool_result_continuation"
	transport_request["tool_call_id"] = tool_call_id
	transport_request["previous_response_id"] = previous_response_id
	transport_request["payload_input_count"] = payload_input_count
	transport_request["payload_fingerprint"] = payload_fingerprint
	var event: Dictionary = _state.call("append_model_event", "openai_continuation_request", {
		"status": "ready" if bool(request_snapshot.get("ready", false)) else "blocked",
		"error": str(request_snapshot.get("error", "")),
		"tool_call_id": tool_call_id,
		"tool": str(tool_call.get("name", "")),
		"provider": str(request_snapshot.get("provider", "")),
		"endpoint": str(request_snapshot.get("endpoint", "")),
		"api_mode": str(request_snapshot.get("api_mode", "")),
		"model": str(request_snapshot.get("model", "")),
		"reasoning_effort": str(request_snapshot.get("reasoning_effort", "")),
		"key_source": str(request_snapshot.get("key_source", "missing")),
		"previous_response_id": previous_response_id,
		"payload_input_count": payload_input_count,
		"payload_fingerprint": payload_fingerprint,
		"headers": request_snapshot.get("headers", PackedStringArray()),
	})
	_state.call("update_tool_call_continuation", tool_call_id, "ready" if bool(request_snapshot.get("ready", false)) else "blocked", {
		"event_id": str(event.get("id", "")),
		"error": str(request_snapshot.get("error", "")),
		"message": str(result.get("message", result.get("error", ""))),
	})
	_state.call("record_stream_step", "准备工具结果续跑：%s" % str(tool_call.get("name", "")), "已完成" if bool(request_snapshot.get("ready", false)) else "已阻塞")
	var continuation := {
		"success": bool(request_snapshot.get("ready", false)),
		"blocked": not bool(request_snapshot.get("ready", false)),
		"auto_send_allowed": str(_state.approval_mode) != "请求批准",
		"error": str(request_snapshot.get("error", "")),
		"tool_call_id": tool_call_id,
		"previous_response_id": previous_response_id,
		"payload": payload,
		"transport_request": transport_request,
		"openai_request": request_snapshot,
		"model_event": event,
	}
	_state.call("set_pending_openai_continuation", continuation)
	return continuation


func replay_pending_tool_result_continuation() -> Dictionary:
	var pending: Dictionary = _state.get("pending_openai_continuation")
	if pending.is_empty():
		return {"success": false, "error": "no_pending_continuation", "message": "No pending tool-result continuation is available."}
	if str(pending.get("status", "")) != "ready":
		return {
			"success": false,
			"error": str(pending.get("error", "continuation_not_ready")),
			"message": "Pending continuation is not ready.",
			"status": str(pending.get("status", "")),
		}
	var tool_call_id := str(pending.get("tool_call_id", ""))
	var transport_request: Dictionary = pending.get("transport_request", {})
	var payload: Dictionary = transport_request.get("payload", {})
	if payload.is_empty():
		return {"success": false, "error": "missing_continuation_payload", "tool_call_id": tool_call_id}
	if str(_state.get("agent_loop_status")) != "running" or str(_state.get("active_turn_id")).is_empty():
		_state.call("begin_agent_loop", "local_continuation_replay")
	var replay_text := _build_local_continuation_replay_text(tool_call_id, payload)
	var response_body := JSON.stringify({
		"output": [
			{
				"type": "message",
				"content": [{"type": "output_text", "text": replay_text}],
			},
		],
	})
	_state.call("append_model_event", "openai_transport", {
		"status": "replayed",
		"source": "local_tool_result_continuation_replay",
		"api_mode": str(pending.get("api_mode", _state.api_mode)),
		"model": str(pending.get("model", _state.model)),
		"tool_call_id": tool_call_id,
		"body_length": response_body.length(),
		"continuation_input_count": _payload_input_count(payload),
	})
	_state.call("record_agent_loop_step", "local_continuation_replay", tool_call_id)
	var parsed := handle_model_response(str(pending.get("api_mode", _state.api_mode)), response_body, {
		"source": "local_tool_result_continuation_replay",
		"fixture_name": "tool_result_final_message",
	})
	if bool(parsed.get("success", false)):
		_state.call("append_message", "assistant", str(parsed.get("text", "")))
		_state.call("clear_pending_openai_continuation", tool_call_id)
		_state.call("record_stream_step", "本地工具结果续跑回放", "已完成")
		_state.call("stop_agent_loop", "local_continuation_replay_final")
	else:
		_state.call("record_stream_step", "本地工具结果续跑回放", "失败")
	return parsed


func inspect_mcp_connection() -> Dictionary:
	_mcp.call("configure", _state.endpoint)
	var health: Dictionary = _mcp.call("health_snapshot")
	var configured := bool(health.get("configured", false))
	var endpoint := str(health.get("endpoint", ""))
	var status_text := "MCP endpoint 已配置" if configured else "MCP endpoint 格式需要检查"
	_state.call("append_model_event", "mcp_context", {
		"status": "ready" if configured else "blocked",
		"endpoint": endpoint,
		"transport": str(health.get("transport", "streamable-http")),
		"tool_count": int(health.get("tool_count", 0)),
		"summary": status_text,
	})
	return {
		"success": configured,
		"summary": "%s：%s。" % [status_text, endpoint],
		"health": health,
	}


func build_mcp_discovery_request() -> Dictionary:
	_mcp.call("configure", _state.endpoint)
	var request: Dictionary = _mcp.call("build_tools_list_request")
	var discovery: Dictionary = _state.call("record_mcp_discovery_request", request)
	return {
		"success": true,
		"request": request,
		"discovery": discovery,
	}


func handle_mcp_tools_list_response(response_body: String) -> Dictionary:
	var parsed: Dictionary = _mcp.call("parse_tools_list_response", response_body)
	var discovery: Dictionary = _state.call("record_mcp_discovery", parsed)
	parsed["discovery"] = discovery
	return parsed


func build_runtime_plan() -> Dictionary:
	return {
		"success": true,
		"summary": "运行问题整理会先读取项目状态和 Output 错误，再按场景运行、runtime bridge、截图和输入回放建立验证闭环。",
	}


func build_ui_plan() -> Dictionary:
	return {
		"success": true,
		"summary": "UI 调整计划会先截图当前 Godex 主屏，检查容器尺寸、文字溢出、主屏焦点和设置面板，再小步修改并复验。",
	}


func _build_openai_payload(explicit_skill_injections: Array[Dictionary] = []) -> Dictionary:
	var instructions := _openai_instructions(explicit_skill_injections)
	var options := {"reasoning_effort": str(_state.reasoning_effort), "stream": true}
	var tools := _build_tool_schemas()
	if bool(_state.plan_mode_enabled):
		tools = []
	if _state.api_mode == "chat_completions":
		return OpenAIRequestBuilder.build_chat_completions_payload(_state.model, instructions, _messages, tools, options)
	return OpenAIRequestBuilder.build_responses_payload(_state.model, instructions, _messages, tools, options)


func _build_openai_tool_result_payload(tool_call: Dictionary, tool_output: String) -> Dictionary:
	var instructions := _openai_instructions()
	var messages := _state.call("active_messages")
	var options := {"reasoning_effort": str(_state.reasoning_effort), "stream": true}
	var previous_response_id := str(tool_call.get("response_id", "")).strip_edges()
	if not previous_response_id.is_empty():
		options["previous_response_id"] = previous_response_id
	if _state.api_mode == "chat_completions":
		return OpenAIRequestBuilder.build_chat_completions_tool_result_payload(_state.model, instructions, messages, tool_call, tool_output, _build_tool_schemas(), options)
	return OpenAIRequestBuilder.build_responses_tool_result_payload(_state.model, instructions, messages, tool_call, tool_output, _build_tool_schemas(), options)


func _openai_instructions(explicit_skill_injections: Array[Dictionary] = []) -> String:
	var instructions := "You are Godex, a Godot editor-native coding agent. Use project MCP context, ask for approval before risky actions, and keep a concise audit trail."
	if _state.has_method("enabled_skill_prompt_from_registry"):
		var skill_prompt := str(_state.call("enabled_skill_prompt_from_registry", 8)).strip_edges()
		if not skill_prompt.is_empty():
			instructions += "\n\n%s" % skill_prompt
	var skill_injection_text := _format_skill_injections(explicit_skill_injections)
	if not skill_injection_text.is_empty():
		instructions += "\n\n%s" % skill_injection_text
	if bool(_state.plan_mode_enabled):
		instructions += "\n\nPlan Mode is active. Follow the Codex Plan Mode contract: explore only with non-mutating reasoning, treat execution requests as requests to plan the execution, do not perform mutating actions, do not call tools, and produce a decision-complete implementation plan before any execution happens."
	var active_goal: Dictionary = _state.call("active_goal_record")
	if bool(active_goal.get("enabled", false)):
		instructions += "\n\nActive Goal: %s\nGoal status: %s. Keep the response, tool choices, and audit trail aligned with this active thread goal unless the user explicitly redirects it." % [str(active_goal.get("objective", "")), _goal_status_label(str(active_goal.get("status", "")))]
	var guide_instruction: Dictionary = _state.call("active_pending_guide_instruction")
	if not guide_instruction.is_empty():
		instructions += "\n\nComposer Guide Instruction: %s\nTreat this as user-supplied guidance for this next turn only. It is not a permanent system instruction and does not override tool safety, approval policy, or repository rules." % str(guide_instruction.get("instructions", ""))
	return instructions


func _explicit_skill_injections(prompt: String) -> Array[Dictionary]:
	if not bool(_state.get("skills_enabled")):
		return []
	var registry = _state.get("skill_registry_model")
	if not (registry is Dictionary):
		return []
	var skills: Array = registry.get("skills", [])
	if skills.is_empty():
		return []
	var mentioned_names := _collect_skill_mentions(prompt)
	if mentioned_names.is_empty():
		return []
	var injections: Array[Dictionary] = []
	var seen_paths := {}
	for skill in skills:
		if injections.size() >= MAX_EXPLICIT_SKILL_INJECTIONS:
			break
		if not (skill is Dictionary):
			continue
		var skill_dict: Dictionary = skill
		if not bool(skill_dict.get("enabled", true)):
			continue
		var name := str(skill_dict.get("name", "")).strip_edges()
		if name.is_empty() or not mentioned_names.has(name.to_lower()):
			continue
		var skill_file := str(skill_dict.get("skill_file", "")).strip_edges()
		var skill_path := str(skill_dict.get("path", "")).strip_edges()
		var key := skill_file if not skill_file.is_empty() else skill_path
		if key.is_empty() or seen_paths.has(key):
			continue
		var contents := _skill_body_from_file(skill_file)
		if contents.is_empty():
			continue
		seen_paths[key] = true
		injections.append({
			"name": name,
			"path": skill_path,
			"skill_file": skill_file,
			"contents": contents,
		})
	return injections


func _collect_skill_mentions(text: String) -> Dictionary:
	var mentions := {}
	var index := 0
	while index < text.length():
		var dollar := text.find("$", index)
		if dollar < 0 or dollar >= text.length() - 1:
			break
		var start := dollar + 1
		var end := start
		while end < text.length():
			var ch := text.substr(end, 1)
			if not _is_skill_name_char(ch):
				break
			end += 1
		if end > start:
			mentions[text.substr(start, end - start).to_lower()] = true
		index = max(end, dollar + 1)
	return mentions


func _is_skill_name_char(ch: String) -> bool:
	if ch.is_empty():
		return false
	var code := ch.unicode_at(0)
	return (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or ch in ["_", "-", "."]


func _skill_body_from_file(skill_file: String) -> String:
	var path := skill_file.strip_edges()
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	var text := FileAccess.get_file_as_string(path).replace("\r\n", "\n").replace("\r", "\n")
	if text.begins_with("---\n"):
		var end_index := text.find("\n---", 4)
		if end_index >= 0:
			text = text.substr(end_index + 4)
	return text.strip_edges()


func _format_skill_injections(injections: Array[Dictionary]) -> String:
	if injections.is_empty():
		return ""
	var blocks: Array[String] = [
		"Explicit Skill instructions selected by the user for this turn:",
	]
	for injection in injections:
		var name := str(injection.get("name", "")).strip_edges()
		var path := str(injection.get("path", "")).strip_edges()
		var contents := str(injection.get("contents", "")).strip_edges()
		if name.is_empty() or contents.is_empty():
			continue
		blocks.append("<skill>\n<name>%s</name>\n<path>%s</path>\n<content>\n%s\n</content>\n</skill>" % [name, path, contents])
	return "\n".join(blocks)


func _goal_status_label(status: String) -> String:
	match status:
		"active":
			return "active"
		"blocked":
			return "blocked"
		"paused":
			return "paused"
		"complete":
			return "complete"
		_:
			return status if not status.is_empty() else "unset"


func _preview_text(text: String, limit: int = 80) -> String:
	var clean := text.strip_edges().replace("\n", " ")
	while clean.find("  ") >= 0:
		clean = clean.replace("  ", " ")
	if clean.length() > limit:
		return "%s..." % clean.left(limit).strip_edges()
	return clean


func _build_preview(request_snapshot: Dictionary) -> String:
	if not bool(request_snapshot.get("ready", false)):
		return "我已准备好一次 Agent 回合，但 API Key 尚未就绪。本轮已构建 payload、MCP 上下文请求、审批点和子代理队列；配置环境变量或手动 key 后即可进入真实 OpenAI 请求执行。"
	return "我已准备好一次 Agent 回合：API 认证已就绪，会先注入 Godot/MCP 上下文，再按审批策略调用工具，并保留可审计的 OpenAI 请求快照。"


func _build_tool_schemas() -> Array:
	return [
		{
			"type": "function",
			"name": "exec_command",
			"description": "Run a shell command through Godex's approval-bound command capability. This is the Codex-compatible command tool name; commands require approval unless policy and mode allow them.",
			"parameters": {
				"type": "object",
				"properties": {
					"command": {"type": "string"},
					"workdir": {"type": "string"},
					"timeout_ms": {"type": "integer", "minimum": 1000, "maximum": 300000},
					"login": {"type": "boolean"},
					"sandbox_permissions": {"type": "string", "enum": ["use_default", "require_escalated"]},
					"justification": {"type": "string"},
					"prefix_rule": {
						"type": "array",
						"items": {"type": "string"},
					},
				},
				"required": ["command"],
			},
		},
		{
			"type": "function",
			"name": "write_stdin",
			"description": "Continue or poll an existing command session. Godex currently records this Codex-compatible tool as an unsupported command-session continuation until the process manager is implemented.",
			"parameters": {
				"type": "object",
				"properties": {
					"session_id": {"type": "integer"},
					"chars": {"type": "string"},
					"yield_time_ms": {"type": "integer", "minimum": 0, "maximum": 300000},
					"max_output_tokens": {"type": "integer", "minimum": 1},
				},
				"required": ["session_id"],
			},
		},
		{
			"type": "function",
			"name": "godex_mcp_context",
			"description": "Read Godot project, scene, script, runtime, and editor log context through the configured MCP endpoint.",
			"parameters": {
				"type": "object",
				"properties": {
					"scope": {"type": "string", "enum": ["summary", "scene", "scripts", "runtime", "logs"]},
					"limit": {"type": "integer", "minimum": 1, "maximum": 200},
				},
				"required": ["scope"],
			},
		},
		{
			"type": "function",
			"name": "godex_request_approval",
			"description": "Create an approval checkpoint before file writes, commands, runtime control, or network actions.",
			"parameters": {
				"type": "object",
				"properties": {
					"action": {"type": "string"},
					"risk": {"type": "string", "enum": ["low", "medium", "high"]},
					"summary": {"type": "string"},
				},
				"required": ["action", "risk", "summary"],
			},
		},
		{
			"type": "function",
			"name": "godex_command_request",
			"description": "Prepare an approved command-line request. Execution is disabled unless the user enables command capability and approves the action.",
			"parameters": {
				"type": "object",
				"properties": {
					"command": {"type": "string"},
					"working_directory": {"type": "string"},
					"reason": {"type": "string"},
				},
				"required": ["command", "reason"],
			},
		},
		{
			"type": "function",
			"name": "godex_change_review_summary",
			"description": "Publish a read-only changed-file summary for the composer review strip. This updates review UI state only and never applies patches.",
			"parameters": {
				"type": "object",
				"properties": {
					"status_porcelain": {"type": "string"},
					"numstat": {"type": "string"},
					"files": {
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"path": {"type": "string"},
								"added": {"type": "integer"},
								"removed": {"type": "integer"},
								"status": {"type": "string"},
							},
							"required": ["path"],
						},
					},
					"title": {"type": "string"},
				},
			},
		},
		{
			"type": "function",
			"name": "godex_update_progress",
			"description": "Update the right rail short-term progress plan for the current conversation. Use this only for user-visible plan/memory items, not for tool logs or transport lifecycle events.",
			"parameters": {
				"type": "object",
				"properties": {
					"items": {
						"type": "array",
						"items": {
							"type": "object",
							"properties": {
								"title": {"type": "string"},
								"detail": {"type": "string"},
								"done": {"type": "boolean"},
							},
							"required": ["title"],
						},
					},
				},
				"required": ["items"],
			},
		},
	]


func _find_tool_call(tool_call_id: String) -> Dictionary:
	for event in _state.call("active_model_events"):
		if str(event.get("kind", "")) != "tool_call":
			continue
		var data: Dictionary = event.get("data", {})
		if str(data.get("id", "")) == tool_call_id:
			return data
	return {}


func _build_mcp_dispatch_request(tool_name: String, arguments: Dictionary) -> Dictionary:
	if tool_name == "godex_mcp_context":
		return _mcp.call("build_tool_context_request", str(arguments.get("scope", "summary")), int(arguments.get("limit", 50)))
	return _mcp.call("build_tool_call_request", tool_name, arguments)


func _build_tool_output_for_model(tool_call: Dictionary, result: Dictionary) -> String:
	var output := {
		"tool_call_id": str(tool_call.get("id", "")),
		"tool": str(tool_call.get("name", "")),
		"status": str(tool_call.get("status", "")),
		"message": str(result.get("message", "")),
		"error": str(result.get("error", "")),
		"data": result.get("data", {}),
	}
	return JSON.stringify(output)


func _build_local_continuation_replay_text(tool_call_id: String, payload: Dictionary) -> String:
	return "本地续跑回放：工具结果已按 Codex/Responses 的 function_call_output 语义回灌给模型。工具调用 %s 的闭环已到达最终 assistant 响应；真实网络发送仍需通过正常 OpenAI 续跑请求。" % tool_call_id


func _payload_input_count(payload: Dictionary) -> int:
	var input = payload.get("input", payload.get("messages", []))
	if input is Array:
		return input.size()
	return 0


func _has_approved_tool_call_checkpoint(action: String, tool_call_id: String) -> bool:
	for record in _state.approval_records:
		if str(record.get("action", "")) == action and str(record.get("tool_call_id", "")) == tool_call_id and str(record.get("status", "")) == "approved":
			return true
	return false


func _tool_call_auto_allowed(risk: String, requires_approval: bool) -> bool:
	if not requires_approval:
		return true
	if risk != "low":
		return false
	return str(_state.approval_mode) in ["替我审批", "完全访问权限"]
