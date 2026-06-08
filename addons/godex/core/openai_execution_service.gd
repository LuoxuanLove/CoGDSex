@tool
class_name GodexOpenAIExecutionService
extends RefCounted

const RequestBuilder = preload("res://addons/godex/core/openai_request_builder.gd")


func build_request_snapshot(api_config: Dictionary, payload: Dictionary) -> Dictionary:
	var has_key := bool(api_config.get("has_api_key", false))
	var safe_headers := PackedStringArray(["Content-Type: application/json"])
	if has_key:
		safe_headers.append("Authorization: Bearer %s" % str(api_config.get("masked_api_key", "")))
	return {
		"ready": has_key,
		"error": "" if has_key else "missing_api_key",
		"provider": str(api_config.get("provider", "")),
		"endpoint": str(api_config.get("endpoint", "")),
		"api_mode": str(api_config.get("api_mode", "responses")),
		"model": str(api_config.get("model", "")),
		"reasoning_effort": _reasoning_effort_from_payload(payload),
		"key_source": str(api_config.get("key_source", "missing")),
		"masked_api_key": str(api_config.get("masked_api_key", "")),
		"headers": safe_headers,
		"payload": payload,
	}


func build_transport_request(api_config: Dictionary, payload: Dictionary) -> Dictionary:
	var snapshot := build_request_snapshot(api_config, payload)
	snapshot["headers"] = api_config.get("headers", PackedStringArray())
	return snapshot


func parse_response(api_mode: String, response_body: String) -> Dictionary:
	var parsed = _parse_json_quiet(response_body)
	if not (parsed is Dictionary):
		return _error("invalid_json", "OpenAI response was not valid JSON.")
	if parsed.has("error"):
		return _parse_error_payload(parsed.get("error", {}))
	if api_mode == "chat_completions":
		return _parse_chat_completions(parsed)
	return _parse_responses(parsed)


func parse_http_result(api_mode: String, status_code: int, response_body: String) -> Dictionary:
	if status_code < 200 or status_code >= 300:
		var parsed = _parse_json_quiet(response_body)
		if parsed is Dictionary and parsed.has("error"):
			return _parse_error_payload(parsed.get("error", {}), status_code)
		return _error("http_%d" % status_code, response_body.strip_edges(), status_code)
	return parse_response(api_mode, response_body)


func parse_stream_data(api_mode: String, data: String) -> Dictionary:
	var payload_text := data.strip_edges()
	if payload_text.is_empty():
		return {"success": true, "text_delta": "", "completed": false, "tool_calls": [], "tool_call_deltas": []}
	if payload_text == "[DONE]":
		return {"success": true, "text_delta": "", "completed": true, "tool_calls": [], "tool_call_deltas": []}
	var parsed = _parse_json_quiet(payload_text)
	if not (parsed is Dictionary):
		return _error("invalid_stream_json", "OpenAI stream event was not valid JSON.")
	if parsed.has("error"):
		return _parse_error_payload(parsed.get("error", {}))
	if api_mode == "chat_completions":
		return _parse_chat_stream_event(parsed)
	return _parse_responses_stream_event(parsed)


func parse_stream_residual(api_mode: String, residual: String) -> Dictionary:
	var text := residual.strip_edges()
	if text.is_empty():
		return _error("empty_stream_residual", "OpenAI stream residual was empty.")
	var events: Array[Dictionary] = []
	var final_response: Dictionary = {}
	if _looks_like_sse_text(text):
		for line in text.split("\n"):
			var stripped := str(line).strip_edges()
			if not stripped.begins_with("data:"):
				continue
			var parsed_event := parse_stream_data(api_mode, stripped.substr(5).strip_edges())
			if not bool(parsed_event.get("success", false)):
				return parsed_event
			events.append(parsed_event)
		if events.is_empty():
			return _error("empty_stream_residual", "OpenAI stream residual had no data events.")
	else:
		final_response = parse_response(api_mode, text)
		if not bool(final_response.get("success", false)):
			return final_response
	return {
		"success": true,
		"mode": "sse" if final_response.is_empty() else "json",
		"events": events,
		"response": final_response,
		"response_body": text if not final_response.is_empty() else "",
	}


func _parse_responses(payload: Dictionary) -> Dictionary:
	var text_parts: Array[String] = []
	var tool_calls: Array[Dictionary] = []
	var response_id := str(payload.get("id", ""))
	var output: Array = payload.get("output", [])
	for output_index in range(output.size()):
		var item = output[output_index]
		if not (item is Dictionary):
			continue
		var item_type := str(item.get("type", ""))
		if item_type == "function_call":
			var response_tool_call := {
				"id": str(item.get("call_id", item.get("id", ""))),
				"index": output_index,
				"name": str(item.get("name", "")),
				"arguments": item.get("arguments", "{}"),
			}
			if not response_id.is_empty():
				response_tool_call["response_id"] = response_id
			tool_calls.append(response_tool_call)
			continue
		var item_text := _extract_responses_text(item)
		if not item_text.is_empty():
			text_parts.append(item_text)
	if text_parts.is_empty():
		var top_level_text := _extract_responses_text(payload)
		if not top_level_text.is_empty():
			text_parts.append(top_level_text)
	return {
		"success": true,
		"text": "\n".join(text_parts).strip_edges(),
		"tool_calls": tool_calls,
		"response_id": response_id,
		"raw": payload,
	}


func _parse_responses_stream_event(payload: Dictionary) -> Dictionary:
	var event_type := str(payload.get("type", ""))
	var delta := ""
	var final_text := ""
	var response_id := str(payload.get("response_id", ""))
	var tool_calls: Array[Dictionary] = []
	var tool_call_deltas: Array[Dictionary] = []
	var completed := event_type == "response.completed"
	if response_id.is_empty():
		var event_response = payload.get("response", {})
		if event_response is Dictionary:
			response_id = str(event_response.get("id", ""))
	if event_type in ["response.output_text.delta", "response.refusal.delta"]:
		delta = str(payload.get("delta", ""))
	elif event_type == "response.output_text.done":
		final_text = str(payload.get("text", ""))
	elif event_type == "response.refusal.done":
		final_text = str(payload.get("refusal", ""))
	elif payload.has("delta") and payload.get("delta") is String:
		delta = str(payload.get("delta", ""))
	if event_type == "response.completed":
		var response = payload.get("response", {})
		if response is Dictionary:
			var parsed_response := _parse_responses(response)
			response_id = str(parsed_response.get("response_id", response_id))
			final_text = str(parsed_response.get("text", ""))
			for completed_tool_call in parsed_response.get("tool_calls", []):
				if completed_tool_call is Dictionary:
					if not response_id.is_empty() and str(completed_tool_call.get("response_id", "")).is_empty():
						completed_tool_call["response_id"] = response_id
					tool_calls.append(completed_tool_call)
		if final_text.is_empty():
			final_text = _extract_responses_text(payload)
	elif event_type == "response.output_item.added":
		var item = payload.get("item", payload.get("output_item", {}))
		if item is Dictionary and str(item.get("type", "")) == "function_call":
			var tool_delta := {
				"id": str(item.get("call_id", item.get("id", payload.get("item_id", payload.get("output_index", ""))))),
				"index": int(payload.get("output_index", -1)),
				"name": str(item.get("name", "")),
				"arguments_delta": "",
			}
			if not response_id.is_empty():
				tool_delta["response_id"] = response_id
			tool_call_deltas.append(tool_delta)
	elif event_type == "response.output_item.done":
		var item = payload.get("item", payload.get("output_item", {}))
		if item is Dictionary and str(item.get("type", "")) == "function_call":
			var done_tool_call := {
				"id": str(item.get("call_id", item.get("id", payload.get("item_id", payload.get("output_index", ""))))),
				"index": int(payload.get("output_index", -1)),
				"name": str(item.get("name", "")),
				"arguments": item.get("arguments", "{}"),
			}
			if not response_id.is_empty():
				done_tool_call["response_id"] = response_id
			tool_calls.append(done_tool_call)
	if event_type == "response.function_call_arguments.delta":
		var argument_tool_delta := {
			"id": str(payload.get("call_id", payload.get("item_id", payload.get("output_index", "")))),
			"index": int(payload.get("output_index", -1)),
			"arguments_delta": str(payload.get("delta", "")),
		}
		if not response_id.is_empty():
			argument_tool_delta["response_id"] = response_id
		tool_call_deltas.append(argument_tool_delta)
	elif event_type == "response.function_call_arguments.done":
		var argument_done_tool_call := {
			"id": str(payload.get("call_id", payload.get("item_id", payload.get("output_index", "")))),
			"index": int(payload.get("output_index", -1)),
			"name": str(payload.get("name", "")),
			"arguments": payload.get("arguments", "{}"),
		}
		if not response_id.is_empty():
			argument_done_tool_call["response_id"] = response_id
		tool_calls.append(argument_done_tool_call)
	return {
		"success": true,
		"text_delta": delta,
		"final_text": final_text,
		"response_id": response_id,
		"completed": completed,
		"tool_calls": tool_calls,
		"tool_call_deltas": tool_call_deltas,
		"raw": payload,
	}


func _extract_responses_text(payload: Dictionary) -> String:
	var text_parts: Array[String] = []
	for key in ["output_text", "text", "refusal"]:
		if payload.has(key) and payload.get(key) is String:
			var value := str(payload.get(key, "")).strip_edges()
			if not value.is_empty():
				text_parts.append(value)
	var content: Array = payload.get("content", [])
	for content_item in content:
		if not (content_item is Dictionary):
			continue
		for key in ["text", "output_text", "refusal"]:
			if content_item.has(key) and content_item.get(key) is String:
				var value := str(content_item.get(key, "")).strip_edges()
				if not value.is_empty():
					text_parts.append(value)
					break
	return "\n".join(text_parts).strip_edges()


func _parse_chat_stream_event(payload: Dictionary) -> Dictionary:
	var choices: Array = payload.get("choices", [])
	if choices.is_empty() or not (choices[0] is Dictionary):
		return {"success": true, "text_delta": "", "completed": false, "tool_calls": [], "tool_call_deltas": [], "raw": payload}
	var choice: Dictionary = choices[0]
	var delta_payload: Dictionary = choice.get("delta", {})
	var finish_reason := str(choice.get("finish_reason", ""))
	var tool_call_deltas: Array[Dictionary] = []
	for item in delta_payload.get("tool_calls", []):
		if not (item is Dictionary):
			continue
		var function: Dictionary = item.get("function", {})
		tool_call_deltas.append({
			"id": str(item.get("id", "")),
			"index": int(item.get("index", -1)),
			"name": str(function.get("name", "")),
			"arguments_delta": str(function.get("arguments", "")),
		})
	return {
		"success": true,
		"text_delta": _extract_chat_content_text(delta_payload.get("content", ""), true),
		"completed": not finish_reason.is_empty(),
		"tool_calls": [],
		"tool_call_deltas": tool_call_deltas,
		"raw": payload,
	}


func _parse_chat_completions(payload: Dictionary) -> Dictionary:
	var choices: Array = payload.get("choices", [])
	if choices.is_empty() or not (choices[0] is Dictionary):
		return _error("missing_choice", "Chat Completions response did not include a choice.")
	var message: Dictionary = choices[0].get("message", {})
	var tool_calls: Array[Dictionary] = []
	for item in message.get("tool_calls", []):
		if not (item is Dictionary):
			continue
		var function: Dictionary = item.get("function", {})
		tool_calls.append({
			"id": str(item.get("id", "")),
			"name": str(function.get("name", "")),
			"arguments": function.get("arguments", "{}"),
		})
	return {
		"success": true,
		"text": _extract_chat_content_text(message.get("content", "")),
		"tool_calls": tool_calls,
		"raw": payload,
	}


func _extract_chat_content_text(value, preserve_edges: bool = false) -> String:
	var text_parts: Array[String] = []
	if value is String:
		var string_value := str(value)
		return string_value if preserve_edges else string_value.strip_edges()
	if value is Array:
		for item in value:
			var item_text := _extract_chat_content_text(item, preserve_edges)
			if not item_text.is_empty():
				text_parts.append(item_text)
	elif value is Dictionary:
		for key in ["text", "content", "output_text", "refusal"]:
			if value.has(key):
				var nested_text := _extract_chat_content_text(value.get(key), preserve_edges)
				if not nested_text.is_empty():
					text_parts.append(nested_text)
	else:
		return ""
	var joined := "\n".join(text_parts)
	return joined if preserve_edges else joined.strip_edges()


func _parse_error_payload(payload, status_code: int = 0) -> Dictionary:
	if payload is Dictionary:
		return _error(str(payload.get("type", payload.get("code", "api_error"))), str(payload.get("message", "")), status_code)
	return _error("api_error", str(payload), status_code)


func _parse_json_quiet(text: String):
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return null
	return parser.data


func _looks_like_sse_text(text: String) -> bool:
	for line in text.split("\n"):
		if str(line).strip_edges().begins_with("data:"):
			return true
	return false


func _reasoning_effort_from_payload(payload: Dictionary) -> String:
	if payload.has("reasoning_effort"):
		return str(payload.get("reasoning_effort", ""))
	var reasoning = payload.get("reasoning", {})
	if reasoning is Dictionary:
		return str((reasoning as Dictionary).get("effort", ""))
	return ""


func _error(code: String, message: String, status_code: int = 0) -> Dictionary:
	return {
		"success": false,
		"error": code,
		"message": message,
		"status_code": status_code,
		"text": "",
		"tool_calls": [],
	}
