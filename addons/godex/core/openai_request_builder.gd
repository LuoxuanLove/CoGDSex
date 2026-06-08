@tool
class_name GodexOpenAIRequestBuilder
extends RefCounted


static func build_responses_payload(model: String, instructions: String, messages: Array, tools: Array = [], options: Dictionary = {}) -> Dictionary:
	var input := []
	for message in messages:
		input.append({
			"role": str(message.get("role", "user")),
			"content": _responses_content_for_message(message),
		})
	var payload := {
		"model": model,
		"instructions": instructions,
		"input": input,
	}
	if not tools.is_empty():
		payload["tools"] = tools
	_apply_responses_options(payload, options)
	return payload


static func build_responses_tool_result_payload(
	model: String,
	instructions: String,
	messages: Array,
	tool_call: Dictionary,
	tool_output: String,
	tools: Array = [],
	options: Dictionary = {}
) -> Dictionary:
	var payload := build_responses_payload(model, instructions, messages, tools, options)
	var input: Array = payload.get("input", [])
	var previous_response_id := str(options.get("previous_response_id", tool_call.get("response_id", ""))).strip_edges()
	if not previous_response_id.is_empty():
		payload["previous_response_id"] = previous_response_id
		input.clear()
	else:
		input.append({
			"type": "function_call",
			"call_id": str(tool_call.get("id", "")),
			"name": str(tool_call.get("name", "")),
			"arguments": JSON.stringify(tool_call.get("arguments", {})),
		})
	input.append({
		"type": "function_call_output",
		"call_id": str(tool_call.get("id", "")),
		"output": tool_output,
	})
	payload["input"] = input
	return payload


static func build_chat_completions_payload(model: String, instructions: String, messages: Array, tools: Array = [], options: Dictionary = {}) -> Dictionary:
	var chat_messages := [{"role": "system", "content": instructions}]
	for message in messages:
		chat_messages.append({
			"role": str(message.get("role", "user")),
			"content": _chat_content_for_message(message),
		})
	var payload := {
		"model": model,
		"messages": chat_messages,
	}
	if not tools.is_empty():
		payload["tools"] = _chat_tools_from_responses_tools(tools)
	_apply_chat_options(payload, options)
	return payload


static func _responses_content_for_message(message: Dictionary) -> Array:
	var content: Array = [{"type": "input_text", "text": _message_text_with_text_references(message)}]
	for reference in _message_references(message):
		var kind := str(reference.get("kind", "")).strip_edges().to_lower()
		if kind != "image":
			continue
		var value := str(reference.get("value", "")).strip_edges()
		if _is_image_payload_url(value):
			content.append({"type": "input_image", "image_url": value})
	return content


static func _chat_content_for_message(message: Dictionary) -> Variant:
	var parts: Array[Dictionary] = [{"type": "text", "text": _message_text_with_text_references(message)}]
	for reference in _message_references(message):
		var kind := str(reference.get("kind", "")).strip_edges().to_lower()
		if kind != "image":
			continue
		var value := str(reference.get("value", "")).strip_edges()
		if _is_image_payload_url(value):
			parts.append({"type": "image_url", "image_url": {"url": value}})
	if parts.size() == 1:
		return str(parts[0].get("text", ""))
	return parts


static func _message_text_with_text_references(message: Dictionary) -> String:
	var text := str(message.get("content", ""))
	var additions: Array[String] = []
	for reference in _message_references(message):
		var kind := str(reference.get("kind", "")).strip_edges().to_lower()
		var title := str(reference.get("title", "")).strip_edges()
		var value := str(reference.get("value", "")).strip_edges()
		if value.is_empty():
			continue
		match kind:
			"image":
				if _is_image_payload_url(value):
					if not title.is_empty():
						additions.append("[Image reference: %s]" % title)
				else:
					additions.append("[Image reference: %s]" % (title if not title.is_empty() else value))
			"file":
				additions.append("[File reference: %s]\n%s" % [title if not title.is_empty() else "file", value])
			"source":
				additions.append("[Source reference: %s]\n%s" % [title if not title.is_empty() else "source", value])
			_:
				additions.append("[Selected text: %s]\n%s" % [title if not title.is_empty() else "text", value])
	if additions.is_empty():
		return text
	if text.strip_edges().is_empty():
		return "\n\n".join(additions)
	return "%s\n\n%s" % [text, "\n\n".join(additions)]


static func _message_references(message: Dictionary) -> Array:
	var references = message.get("references", [])
	if references is Array:
		return references
	return []


static func _is_image_payload_url(value: String) -> bool:
	var clean_value := value.strip_edges()
	return clean_value.begins_with("http://") or clean_value.begins_with("https://") or clean_value.begins_with("data:image/")


static func build_chat_completions_tool_result_payload(
	model: String,
	instructions: String,
	messages: Array,
	tool_call: Dictionary,
	tool_output: String,
	tools: Array = [],
	options: Dictionary = {}
) -> Dictionary:
	var payload := build_chat_completions_payload(model, instructions, messages, tools, options)
	var chat_messages: Array = payload.get("messages", [])
	chat_messages.append({
		"role": "assistant",
		"content": "",
		"tool_calls": [
			_chat_tool_call_from_record(tool_call),
		],
	})
	chat_messages.append({
		"role": "tool",
		"tool_call_id": _tool_call_id(tool_call),
		"content": tool_output,
	})
	payload["messages"] = chat_messages
	return payload


static func _apply_responses_options(payload: Dictionary, options: Dictionary) -> void:
	if bool(options.get("stream", false)):
		payload["stream"] = true
	var effort := str(options.get("reasoning_effort", "")).strip_edges()
	if effort.is_empty():
		return
	payload["reasoning"] = {"effort": effort}


static func _apply_chat_options(payload: Dictionary, options: Dictionary) -> void:
	if bool(options.get("stream", false)):
		payload["stream"] = true
	var effort := str(options.get("reasoning_effort", "")).strip_edges()
	if effort.is_empty():
		return
	payload["reasoning_effort"] = effort


static func _chat_tools_from_responses_tools(tools: Array) -> Array:
	var chat_tools: Array[Dictionary] = []
	for tool in tools:
		if not (tool is Dictionary):
			continue
		var tool_dict: Dictionary = tool
		if tool_dict.has("function") and tool_dict.get("function") is Dictionary:
			chat_tools.append(tool_dict.duplicate(true))
			continue
		if str(tool_dict.get("type", "")) != "function":
			continue
		chat_tools.append({
			"type": "function",
			"function": {
				"name": str(tool_dict.get("name", "")),
				"description": str(tool_dict.get("description", "")),
				"parameters": tool_dict.get("parameters", {}),
			},
		})
	return chat_tools


static func _chat_tool_call_from_record(tool_call: Dictionary) -> Dictionary:
	var function_payload := tool_call.get("function", {})
	if function_payload is Dictionary:
		return {
			"id": _tool_call_id(tool_call),
			"type": str(tool_call.get("type", "function")),
			"function": {
				"name": str(function_payload.get("name", tool_call.get("name", ""))),
				"arguments": str(function_payload.get("arguments", JSON.stringify(tool_call.get("arguments", {})))),
			},
		}
	return {
		"id": _tool_call_id(tool_call),
		"type": "function",
		"function": {
			"name": str(tool_call.get("name", "")),
			"arguments": JSON.stringify(tool_call.get("arguments", {})),
		},
	}


static func _tool_call_id(tool_call: Dictionary) -> String:
	return str(tool_call.get("id", tool_call.get("tool_call_id", tool_call.get("call_id", ""))))


static func endpoint_for(base_url: String, api_mode: String) -> String:
	var root := base_url.strip_edges().trim_suffix("/")
	if root.ends_with("/v1"):
		root = root.trim_suffix("/v1")
	if api_mode == "chat_completions":
		return "%s/v1/chat/completions" % root
	return "%s/v1/responses" % root


static func build_headers(api_key: String) -> PackedStringArray:
	var headers := PackedStringArray(["Content-Type: application/json"])
	var token := api_key.strip_edges()
	if not token.is_empty():
		headers.append("Authorization: Bearer %s" % token)
	return headers


static func mask_api_key(api_key: String) -> String:
	var token := api_key.strip_edges()
	if token.is_empty():
		return ""
	if token.length() <= 8:
		return "****"
	return "%s****%s" % [token.substr(0, 4), token.substr(token.length() - 4, 4)]
