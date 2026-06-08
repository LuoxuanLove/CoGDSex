extends SceneTree

const SkillRegistry = preload("res://addons/godex/core/godex_skill_registry.gd")
const State = preload("res://addons/godex/core/godex_state.gd")
const AgentService = preload("res://addons/godex/core/agent_service.gd")
const RequestBuilder = preload("res://addons/godex/core/openai_request_builder.gd")
const TEST_ROOT := "res://.tmp/skill_registry_smoke"


func _initialize() -> void:
	var failures: Array[String] = []
	_prepare_fixture()
	_check_registry_scan(failures)
	_cleanup_fixture()
	if failures.is_empty():
		print("GODEX_SKILL_REGISTRY_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_registry_scan(failures: Array[String]) -> void:
	var registry := SkillRegistry.new()
	var skills := registry.scan(TEST_ROOT)
	if skills.size() != 2:
		failures.append("registry should discover exactly two local skills")
		return
	var planner := _find_skill(skills, "planner")
	var reviewer := _find_skill(skills, "reviewer")
	if planner.is_empty():
		failures.append("registry should parse explicit skill name from frontmatter")
	if reviewer.is_empty():
		failures.append("registry should fall back to directory name when name is missing")
	if str(planner.get("description", "")) != "Plan Godot editor work.":
		failures.append("registry should parse top-level description")
	if str(planner.get("short_description", "")) != "Plans Godot tasks":
		failures.append("registry should parse metadata.short-description")
	if str(planner.get("scope", "")) != "user" or str(planner.get("source", "")) != "local":
		failures.append("registry should expose default scope and source")
	var interface: Dictionary = planner.get("interface", {})
	if str(interface.get("display_name", "")) != "Godot Planner":
		failures.append("registry should parse interface.display_name from agents/openai.yaml")
	if str(interface.get("short_description", "")) != "Plan editor tasks with project context":
		failures.append("registry should parse interface.short_description from agents/openai.yaml")
	if str(interface.get("icon_small", "")) != "%s/planner/assets/planner-small.svg" % TEST_ROOT:
		failures.append("registry should resolve interface.icon_small relative to skill directory")
	if str(interface.get("icon_large", "")) != "%s/planner/assets/planner.png" % TEST_ROOT:
		failures.append("registry should resolve interface.icon_large relative to skill directory")
	if str(interface.get("brand_color", "")) != "#33aaff":
		failures.append("registry should parse interface.brand_color")
	if str(interface.get("default_prompt", "")) != "Use $planner to plan this Godot task.":
		failures.append("registry should parse interface.default_prompt")
	var dependencies: Dictionary = planner.get("dependencies", {})
	var tools: Array = dependencies.get("tools", [])
	if tools.size() != 2:
		failures.append("registry should parse dependency tools")
	else:
		var first_tool: Dictionary = tools[0]
		var second_tool: Dictionary = tools[1]
		if str(first_tool.get("type", "")) != "mcp" or str(first_tool.get("value", "")) != "godot":
			failures.append("registry should parse first dependency tool type/value")
		if str(first_tool.get("description", "")) != "Godot editor MCP server" or str(first_tool.get("transport", "")) != "stdio":
			failures.append("registry should parse dependency tool optional fields")
		if str(second_tool.get("type", "")) != "command" or str(second_tool.get("command", "")) != "godot --headless":
			failures.append("registry should parse second dependency command field")
	var policy: Dictionary = planner.get("policy", {})
	if bool(policy.get("allow_implicit_invocation", true)):
		failures.append("registry should parse policy.allow_implicit_invocation")
	var products: Array = policy.get("products", [])
	if products != ["codex", "godex"]:
		failures.append("registry should parse policy.products list")
	if not bool(planner.get("enabled", false)) or not registry.is_enabled(str(planner.get("path", ""))):
		failures.append("skills should be enabled by default")
	var search_results := registry.search("godot tasks")
	if search_results.size() != 1 or str(search_results[0].get("name", "")) != "planner":
		failures.append("registry search should match query tokens across parsed fields")
	var interface_search_results := registry.search("Godot Planner")
	if interface_search_results.size() != 1 or str(interface_search_results[0].get("name", "")) != "planner":
		failures.append("registry search should match interface display name")
	var disabled := registry.set_enabled(str(planner.get("path", "")), false)
	if not bool(disabled.get("success", false)) or registry.is_enabled(str(planner.get("path", ""))):
		failures.append("registry should disable a skill by normalized path")
	var model := registry.to_model()
	if bool(_find_skill(model.get("skills", []), "planner").get("enabled", true)):
		failures.append("registry model should reflect disabled state")
	if int(model.get("skill_count", 0)) != 2 or int(model.get("enabled_count", 0)) != 1:
		failures.append("registry model should summarize skill and enabled counts")
	if not (str(planner.get("path", "")) in model.get("disabled_paths", [])):
		failures.append("registry model should expose disabled skill paths")
	if bool(model.get("remote_enabled", true)) or bool(model.get("marketplace_enabled", true)):
		failures.append("registry should not enable remote or marketplace sources by default")
	registry.set_enabled(str(planner.get("path", "")), true)
	model = registry.to_model()
	var state := State.new()
	state.api_key = "sk-local-test-token"
	state.mcp_enabled = false
	state.skills_enabled = true
	state.set_skill_registry_model(model)
	var prompt := state.enabled_skill_prompt_from_registry()
	if prompt.find("$planner") < 0 or prompt.find("explicit-only") < 0:
		failures.append("state should expose enabled Skill hints with explicit invocation policy")
	var agent := AgentService.new()
	agent.setup(state)
	var turn: Dictionary = agent.prepare_turn("Use $planner for the next implementation plan")
	var payload_input: Array = turn.get("payload", {}).get("input", [])
	if payload_input.is_empty():
		failures.append("agent turn should include the current user prompt in the OpenAI payload")
	var instructions := str(turn.get("payload", {}).get("instructions", ""))
	if instructions.find("Explicit Skill instructions selected by the user") < 0 or instructions.find("Planner body.") < 0:
		failures.append("agent turn should inject explicitly mentioned SKILL.md contents")
	var tool_schemas: Array = turn.get("payload", {}).get("tools", [])
	if _find_tool_schema(tool_schemas, "godex_update_progress").is_empty():
		failures.append("agent turn should expose the progress update tool schema")
	var audit_skills: Dictionary = turn.get("audit", {}).get("skills", {})
	if not (audit_skills.get("explicit", []) as Array).has("planner"):
		failures.append("agent audit should record explicitly injected Skill names")
	registry.set_enabled(str(planner.get("path", "")), false)
	state.set_skill_registry_model(registry.to_model())
	var disabled_agent := AgentService.new()
	disabled_agent.setup(state)
	var disabled_turn: Dictionary = disabled_agent.prepare_turn("Use $planner again")
	if str(disabled_turn.get("payload", {}).get("instructions", "")).find("Planner body.") >= 0:
		failures.append("disabled Skills should not inject even when explicitly mentioned")
	var reference_state := State.new()
	reference_state.add_composer_reference("text", "selected snippet from assistant output", {"title": "1 个已选文本片段", "source": "selection"})
	var message_index := reference_state.append_message("user", "Use this reference")
	if message_index < 0:
		failures.append("composer references should allow normal user message append")
	if not reference_state.active_composer_references().is_empty():
		failures.append("composer references should be consumed after sending a user message")
	var reference_messages := reference_state.active_messages()
	if reference_messages.is_empty() or (reference_messages[0].get("references", []) as Array).size() != 1:
		failures.append("sent user messages should carry selected text references")
	var reference_payload: Dictionary = RequestBuilder.build_responses_payload("gpt-5.5", "instructions", reference_messages)
	var reference_input: Array = reference_payload.get("input", [])
	var reference_text := ""
	if not reference_input.is_empty() and reference_input[0] is Dictionary:
		var reference_content: Array = reference_input[0].get("content", [])
		if not reference_content.is_empty() and reference_content[0] is Dictionary:
			reference_text = str(reference_content[0].get("text", ""))
	if reference_text.find("[Selected text: 1 个已选文本片段]") < 0 or reference_text.find("selected snippet from assistant output") < 0:
		failures.append("OpenAI payload should include selected text references")
	var reference_only_state := State.new()
	reference_only_state.add_composer_reference("text", "standalone selected text", {"title": "1 个已选文本片段", "source": "selection"})
	var reference_only_index := reference_only_state.append_message("user", "")
	if reference_only_index < 0:
		failures.append("reference-only user messages should still append")
	var reference_only_messages := reference_only_state.active_messages()
	if reference_only_messages.is_empty() or (reference_only_messages[0].get("references", []) as Array).size() != 1:
		failures.append("reference-only user messages should retain their composer references")
	reference_state.add_composer_reference("image", "https://example.com/reference.png", {"title": "截图"})
	reference_state.append_message("user", "Inspect image")
	var image_payload: Dictionary = RequestBuilder.build_responses_payload("gpt-5.5", "instructions", reference_state.active_messages())
	var image_input: Array = image_payload.get("input", [])
	var found_input_image := false
	if image_input.size() >= 2 and image_input[1] is Dictionary:
		for content_part in (image_input[1] as Dictionary).get("content", []):
			if content_part is Dictionary and str(content_part.get("type", "")) == "input_image" and str(content_part.get("image_url", "")) == "https://example.com/reference.png":
				found_input_image = true
	if not found_input_image:
		failures.append("OpenAI Responses payload should include image references as input_image parts")
	var image_chat_payload: Dictionary = RequestBuilder.build_chat_completions_payload("gpt-5.5", "instructions", reference_state.active_messages())
	var image_chat_messages: Array = image_chat_payload.get("messages", [])
	var found_chat_image := false
	if image_chat_messages.size() >= 3 and image_chat_messages[2] is Dictionary:
		var chat_content = (image_chat_messages[2] as Dictionary).get("content", "")
		if chat_content is Array:
			for content_part in chat_content:
				if content_part is Dictionary and str(content_part.get("type", "")) == "image_url":
					var image_url: Dictionary = content_part.get("image_url", {})
					if str(image_url.get("url", "")) == "https://example.com/reference.png":
						found_chat_image = true
	if not found_chat_image:
		failures.append("OpenAI Chat Completions payload should include image references as image_url parts")
	var progress_state := State.new()
	progress_state.new_session()
	progress_state.set_progress_items([
		{"title": "修复聊天正文", "done": true},
		{"title": "验证 Mechoes 同步", "detail": "headless smoke", "done": false},
	])
	var progress_model: Dictionary = progress_state.to_model()
	var progress_items: Array = progress_model.get("progress_items", [])
	if progress_items.size() != 2 or str((progress_items[0] as Dictionary).get("title", "")) != "修复聊天正文":
		failures.append("state should expose model-controlled progress_items in to_model")
	var progress_records := progress_state.record_tool_calls([{
		"id": "progress_tool_call",
		"name": "godex_update_progress",
		"arguments": {"items": [{"title": "模型短期计划", "done": false}]},
	}])
	if progress_records.size() != 1 or str((progress_records[0] as Dictionary).get("status", "")) != "completed":
		failures.append("progress update tool calls should auto-complete without approval")
	var tool_progress_items: Array = progress_state.to_model().get("progress_items", [])
	if tool_progress_items.size() != 1 or str((tool_progress_items[0] as Dictionary).get("title", "")) != "模型短期计划":
		failures.append("progress update tool calls should replace the right rail short-term plan")
	progress_state.api_key = "sk-local-test-token"
	progress_state.mcp_enabled = false
	var progress_agent := AgentService.new()
	progress_agent.setup(progress_state)
	var progress_continuation: Dictionary = progress_agent.build_tool_result_continuation("progress_tool_call")
	if not bool(progress_continuation.get("success", false)):
		failures.append("auto-completed progress tool calls should be valid model follow-up boundaries")
	for transcript_item in progress_state.active_transcript_items():
		if transcript_item is Dictionary and str(transcript_item.get("kind", "")) == "tool_call" and str(transcript_item.get("name", "")) == "godex_update_progress":
			failures.append("progress update tool calls should not appear in the chat transcript")


func _find_skill(source_skills: Array, skill_name: String) -> Dictionary:
	for skill in source_skills:
		if skill is Dictionary and str(skill.get("name", "")) == skill_name:
			return skill
	return {}


func _find_tool_schema(tools: Array, tool_name: String) -> Dictionary:
	for tool in tools:
		if tool is Dictionary and str((tool as Dictionary).get("name", "")) == tool_name:
			return tool
	return {}


func _prepare_fixture() -> void:
	_cleanup_fixture()
	var dir := DirAccess.open("res://")
	if dir != null:
		dir.make_dir_recursive(".tmp/skill_registry_smoke/planner")
		dir.make_dir_recursive(".tmp/skill_registry_smoke/planner/agents")
		dir.make_dir_recursive(".tmp/skill_registry_smoke/reviewer")
		dir.make_dir_recursive(".tmp/skill_registry_smoke/not_a_skill/nested")
	_write_file("%s/planner/SKILL.md" % TEST_ROOT, "\n".join([
		"---",
		"name: planner",
		"description: \"Plan Godot editor work.\"",
		"metadata:",
		"  short-description: Plans Godot tasks",
		"---",
		"",
		"Planner body.",
	]))
	_write_file("%s/planner/agents/openai.yaml" % TEST_ROOT, "\n".join([
		"interface:",
		"  display_name: \"Godot Planner\"",
		"  short_description: \"Plan editor tasks with project context\"",
		"  icon_small: \"./assets/planner-small.svg\"",
		"  icon_large: \"./assets/planner.png\"",
		"  brand_color: \"#33aaff\"",
		"  default_prompt: \"Use $planner to plan this Godot task.\"",
		"",
		"dependencies:",
		"  tools:",
		"    - type: \"mcp\"",
		"      value: \"godot\"",
		"      description: \"Godot editor MCP server\"",
		"      transport: \"stdio\"",
		"      url: \"http://127.0.0.1:6005\"",
		"    - type: \"command\"",
		"      value: \"godot-headless\"",
		"      command: \"godot --headless\"",
		"",
		"policy:",
		"  allow_implicit_invocation: false",
		"  products:",
		"    - codex",
		"    - godex",
	]))
	_write_file("%s/reviewer/SKILL.md" % TEST_ROOT, "\n".join([
		"---",
		"description: Review local Godex changes.",
		"---",
		"",
		"Reviewer body.",
	]))
	_write_file("%s/not_a_skill/nested/README.md" % TEST_ROOT, "No skill here.")


func _write_file(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(content)


func _cleanup_fixture() -> void:
	_remove_file("%s/planner/SKILL.md" % TEST_ROOT)
	_remove_file("%s/planner/agents/openai.yaml" % TEST_ROOT)
	_remove_file("%s/reviewer/SKILL.md" % TEST_ROOT)
	_remove_file("%s/not_a_skill/nested/README.md" % TEST_ROOT)
	_remove_dir("%s/not_a_skill/nested" % TEST_ROOT)
	_remove_dir("%s/not_a_skill" % TEST_ROOT)
	_remove_dir("%s/planner/agents" % TEST_ROOT)
	_remove_dir("%s/planner" % TEST_ROOT)
	_remove_dir("%s/reviewer" % TEST_ROOT)
	_remove_dir(TEST_ROOT)


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _remove_dir(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute_path):
		DirAccess.remove_absolute(absolute_path)
