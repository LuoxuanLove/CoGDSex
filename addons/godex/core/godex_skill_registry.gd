@tool
class_name GodexSkillRegistry
extends RefCounted

const SKILL_FILE := "SKILL.md"
const SKILL_METADATA_DIR := "agents"
const SKILL_METADATA_FILE := "openai.yaml"
const DEFAULT_SOURCE := "local"
const DEFAULT_SCOPE := "user"
const MAX_SCAN_DEPTH := 6
const MAX_SKILL_FILES := 200
const SKIP_DIR_NAMES := ["node_modules", "__pycache__", ".git", ".godot", ".import"]

var root_path := ""
var skills: Array[Dictionary] = []
var enabled_by_path: Dictionary = {}
var scan_warnings: Array[String] = []
var name_index: Dictionary = {}


func scan(scan_root: String) -> Array[Dictionary]:
	root_path = _normalize_path(scan_root)
	skills.clear()
	scan_warnings.clear()
	name_index.clear()
	if root_path.is_empty():
		return []
	var skill_files: Array[String] = []
	_collect_skill_files(root_path, skill_files, 0)
	skill_files.sort()
	for skill_file in skill_files:
		var skill := _skill_from_file(skill_file)
		if not skill.is_empty():
			skills.append(skill)
	skills.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return _skill_sort_key(left).naturalnocasecmp_to(_skill_sort_key(right)) < 0
	)
	_rebuild_name_index()
	return _model_skills(skills)


func search(query: String) -> Array[Dictionary]:
	var clean_query := query.strip_edges().to_lower()
	if clean_query.is_empty():
		return _model_skills(skills)
	var tokens := clean_query.split(" ", false)
	var matches: Array[Dictionary] = []
	for skill in skills:
		var haystack := _search_text(skill)
		var matched := true
		for token in tokens:
			if haystack.find(str(token)) < 0:
				matched = false
				break
		if matched:
			matches.append(skill)
	return _model_skills(matches)


func set_enabled(path: String, enabled: bool) -> Dictionary:
	var normalized_path := _normalize_path(path)
	if normalized_path.is_empty():
		return {"success": false, "error": "empty_path"}
	if enabled:
		enabled_by_path.erase(normalized_path)
	else:
		enabled_by_path[normalized_path] = false
	return {"success": true, "path": normalized_path, "enabled": enabled}


func set_disabled_paths(paths: Array) -> void:
	enabled_by_path.clear()
	for path in paths:
		var normalized_path := _normalize_path(str(path))
		if not normalized_path.is_empty():
			enabled_by_path[normalized_path] = false


func disabled_paths() -> Array[String]:
	var paths: Array[String] = []
	for path in enabled_by_path.keys():
		if not bool(enabled_by_path.get(path, true)):
			paths.append(str(path))
	paths.sort()
	return paths


func is_enabled(path: String) -> bool:
	var normalized_path := _normalize_path(path)
	if normalized_path.is_empty():
		return false
	return bool(enabled_by_path.get(normalized_path, true))


func to_model() -> Dictionary:
	var model_skills := _model_skills(skills)
	var enabled_count := 0
	for skill in model_skills:
		if bool(skill.get("enabled", false)):
			enabled_count += 1
	return {
		"root_path": root_path,
		"skill_count": model_skills.size(),
		"enabled_count": enabled_count,
		"skills": model_skills,
		"disabled_paths": disabled_paths(),
		"scan_warnings": scan_warnings.duplicate(),
		"name_index": name_index.duplicate(true),
		"source": DEFAULT_SOURCE,
		"remote_enabled": false,
		"marketplace_enabled": false,
	}


func _collect_skill_files(dir_path: String, output: Array[String], depth: int) -> void:
	if output.size() >= MAX_SKILL_FILES:
		if not scan_warnings.has("skill_file_limit"):
			scan_warnings.append("skill_file_limit")
		return
	if depth > MAX_SCAN_DEPTH:
		if not scan_warnings.has("max_depth"):
			scan_warnings.append("max_depth")
		return
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	var own_skill_file := _join_path(dir_path, SKILL_FILE)
	if FileAccess.file_exists(own_skill_file):
		output.append(own_skill_file)
		return
	var child_dirs: Array[String] = []
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		if not dir.current_is_dir():
			continue
		if entry in SKIP_DIR_NAMES:
			continue
		child_dirs.append(entry)
	dir.list_dir_end()
	child_dirs.sort()
	for entry in child_dirs:
		if output.size() >= MAX_SKILL_FILES:
			if not scan_warnings.has("skill_file_limit"):
				scan_warnings.append("skill_file_limit")
			return
		_collect_skill_files(_join_path(dir_path, entry), output, depth + 1)


func _skill_from_file(skill_file: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(skill_file)
	var skill_path := _normalize_path(skill_file.get_base_dir())
	var frontmatter := _parse_frontmatter(text)
	var extra_metadata := _load_skill_metadata(skill_path)
	var metadata: Dictionary = frontmatter.get("metadata", {})
	var name := str(frontmatter.get("name", "")).strip_edges()
	if name.is_empty():
		name = skill_path.get_file()
	var description := str(frontmatter.get("description", "")).strip_edges()
	var short_description := str(metadata.get("short-description", "")).strip_edges()
	if short_description.is_empty():
		short_description = str(frontmatter.get("metadata.short-description", "")).strip_edges()
	if short_description.is_empty():
		short_description = description
	var interface := _normalize_interface(skill_path, extra_metadata.get("interface", {}))
	var dependencies := _normalize_dependencies(extra_metadata.get("dependencies", {}))
	var policy := _normalize_policy(extra_metadata.get("policy", {}))
	return {
		"name": name,
		"description": description,
		"short_description": short_description,
		"interface": interface,
		"dependencies": dependencies,
		"policy": policy,
		"metadata": metadata,
		"path": skill_path,
		"skill_file": _normalize_path(skill_file),
		"scope": DEFAULT_SCOPE,
		"enabled": is_enabled(skill_path),
		"source": DEFAULT_SOURCE,
		"remote": false,
		"marketplace": false,
	}


func _parse_frontmatter(text: String) -> Dictionary:
	var result := {}
	var normalized_text := text.replace("\r\n", "\n").replace("\r", "\n")
	if not normalized_text.begins_with("---\n"):
		return result
	var end_index := normalized_text.find("\n---", 4)
	if end_index < 0:
		return result
	var yaml := normalized_text.substr(4, end_index - 4)
	return _parse_yaml_map(yaml)


func _load_skill_metadata(skill_path: String) -> Dictionary:
	var metadata_file := _join_path(_join_path(skill_path, SKILL_METADATA_DIR), SKILL_METADATA_FILE)
	if not FileAccess.file_exists(metadata_file):
		return {}
	return _parse_yaml_map(FileAccess.get_file_as_string(metadata_file))


func _parse_yaml_map(yaml: String) -> Dictionary:
	var current_section := ""
	var current_nested := ""
	var current_tool_index := -1
	var result := {}
	for raw_line in yaml.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
		var line := str(raw_line)
		if line.strip_edges().is_empty() or line.strip_edges().begins_with("#"):
			continue
		var indent := line.length() - line.strip_edges(true, false).length()
		var clean_line := line.strip_edges()
		if clean_line.begins_with("- "):
			var item_value := clean_line.substr(2).strip_edges()
			if current_section == "dependencies" and current_nested == "tools":
				var dependencies: Dictionary = result.get("dependencies", {})
				var tools: Array = dependencies.get("tools", [])
				var tool := {}
				var item_separator := item_value.find(":")
				if item_separator >= 0:
					var item_key := item_value.substr(0, item_separator).strip_edges()
					var item_scalar := item_value.substr(item_separator + 1).strip_edges()
					tool[item_key] = _parse_yaml_scalar(item_scalar)
				tools.append(tool)
				dependencies["tools"] = tools
				result["dependencies"] = dependencies
				current_tool_index = tools.size() - 1
			elif current_section == "policy" and current_nested == "products":
				var policy: Dictionary = result.get("policy", {})
				var products: Array = policy.get("products", [])
				products.append(str(_parse_yaml_scalar(item_value)))
				policy["products"] = products
				result["policy"] = policy
			continue
		var separator := clean_line.find(":")
		if separator < 0:
			continue
		var key := clean_line.substr(0, separator).strip_edges()
		var value := clean_line.substr(separator + 1).strip_edges()
		if indent == 0:
			current_section = ""
			current_nested = ""
			current_tool_index = -1
			if value.is_empty():
				result[key] = {}
				current_section = key
			else:
				result[key] = _parse_yaml_scalar(value)
			continue
		if current_section.is_empty():
			continue
		if current_section == "dependencies":
			var dependencies: Dictionary = result.get("dependencies", {})
			if indent <= 2 and key == "tools":
				dependencies["tools"] = _parse_yaml_array(value)
				current_nested = "tools"
				current_tool_index = -1
			elif current_nested == "tools" and current_tool_index >= 0:
				var tools: Array = dependencies.get("tools", [])
				if current_tool_index < tools.size() and tools[current_tool_index] is Dictionary:
					var tool: Dictionary = tools[current_tool_index]
					tool[key] = _parse_yaml_scalar(value)
					tools[current_tool_index] = tool
					dependencies["tools"] = tools
			result["dependencies"] = dependencies
			continue
		if current_section == "policy":
			var policy: Dictionary = result.get("policy", {})
			if key == "products":
				if value.is_empty():
					policy["products"] = []
					current_nested = "products"
				else:
					policy["products"] = _parse_yaml_array(value)
			else:
				policy[key] = _parse_yaml_scalar(value)
				current_nested = ""
			result["policy"] = policy
			continue
		var section = result.get(current_section, {})
		if not (section is Dictionary):
			continue
		section[key] = _parse_yaml_scalar(value)
		result[current_section] = section
	return result


func _parse_yaml_scalar(value: String):
	var clean := value.strip_edges()
	if clean.begins_with("[") and clean.ends_with("]"):
		return _parse_yaml_array(clean)
	if clean.begins_with("\"") and clean.ends_with("\"") and clean.length() >= 2:
		return clean.substr(1, clean.length() - 2).replace("\\\"", "\"")
	if clean.begins_with("'") and clean.ends_with("'") and clean.length() >= 2:
		return clean.substr(1, clean.length() - 2).replace("''", "'")
	var comment_index := clean.find(" #")
	if comment_index >= 0:
		clean = clean.substr(0, comment_index).strip_edges()
	match clean.to_lower():
		"true":
			return true
		"false":
			return false
		"null":
			return null
	return clean


func _parse_yaml_array(value: String) -> Array:
	var clean := value.strip_edges()
	if clean.is_empty():
		return []
	if not (clean.begins_with("[") and clean.ends_with("]")):
		return []
	var inner := clean.substr(1, clean.length() - 2).strip_edges()
	if inner.is_empty():
		return []
	var result: Array = []
	for item in _split_inline_array(inner):
		result.append(_parse_yaml_scalar(item))
	return result


func _split_inline_array(value: String) -> Array[String]:
	var result: Array[String] = []
	var current := ""
	var quote := ""
	var index := 0
	while index < value.length():
		var character := value.substr(index, 1)
		if not quote.is_empty():
			current += character
			if character == quote:
				quote = ""
			index += 1
			continue
		if character == "\"" or character == "'":
			quote = character
			current += character
		elif character == ",":
			result.append(current.strip_edges())
			current = ""
		else:
			current += character
		index += 1
	if not current.strip_edges().is_empty():
		result.append(current.strip_edges())
	return result


func _normalize_interface(skill_path: String, raw_interface) -> Dictionary:
	if not (raw_interface is Dictionary):
		return {}
	var interface: Dictionary = raw_interface
	var result := {}
	for key in ["display_name", "short_description", "brand_color", "default_prompt"]:
		var value := str(interface.get(key, "")).strip_edges()
		if not value.is_empty():
			result[key] = value
	for key in ["icon_small", "icon_large"]:
		var value := str(interface.get(key, "")).strip_edges()
		if not value.is_empty():
			result[key] = _resolve_skill_relative_path(skill_path, value)
	return result


func _normalize_dependencies(raw_dependencies) -> Dictionary:
	var result := {"tools": []}
	if not (raw_dependencies is Dictionary):
		return result
	var tools_value = raw_dependencies.get("tools", [])
	if not (tools_value is Array):
		return result
	var tools: Array = []
	for item in tools_value:
		if not (item is Dictionary):
			continue
		var raw_tool: Dictionary = item
		var tool := {}
		for key in ["type", "value", "description", "transport", "command", "url"]:
			var value := str(raw_tool.get(key, "")).strip_edges()
			if not value.is_empty():
				tool[key] = value
		if tool.has("type") and tool.has("value"):
			tools.append(tool)
	result["tools"] = tools
	return result


func _normalize_policy(raw_policy) -> Dictionary:
	var result := {
		"allow_implicit_invocation": true,
		"products": [],
	}
	if not (raw_policy is Dictionary):
		return result
	var policy: Dictionary = raw_policy
	if policy.has("allow_implicit_invocation"):
		result["allow_implicit_invocation"] = bool(policy.get("allow_implicit_invocation", true))
	var products: Array = []
	var raw_products = policy.get("products", [])
	if raw_products is Array:
		for item in raw_products:
			var product := str(item).strip_edges()
			if not product.is_empty():
				products.append(product)
	result["products"] = products
	return result


func _resolve_skill_relative_path(skill_path: String, value: String) -> String:
	var clean := value.replace("\\", "/").strip_edges()
	if clean.is_empty():
		return ""
	if clean.begins_with("res://") or clean.find("://") >= 0 or clean.is_absolute_path():
		return _normalize_path(clean)
	while clean.begins_with("./"):
		clean = clean.substr(2)
	return _normalize_path(_join_path(skill_path, clean))


func _model_skills(source_skills: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill in source_skills:
		if skill is Dictionary:
			result.append(_model_skill(skill))
	return result


func _rebuild_name_index() -> void:
	name_index.clear()
	for skill in skills:
		if not (skill is Dictionary):
			continue
		var name_key := str((skill as Dictionary).get("name", "")).strip_edges().to_lower()
		if name_key.is_empty():
			continue
		var entries: Array = name_index.get(name_key, [])
		entries.append({
			"path": str((skill as Dictionary).get("path", "")),
			"enabled": is_enabled(str((skill as Dictionary).get("path", ""))),
		})
		name_index[name_key] = entries


func _skill_sort_key(skill: Dictionary) -> String:
	return "%s\t%s\t%s\t%s" % [
		str(skill.get("scope", "")),
		str(skill.get("name", "")),
		str(skill.get("source", "")),
		str(skill.get("path", "")),
	]


func _model_skill(skill: Dictionary) -> Dictionary:
	var model := skill.duplicate(true)
	model["enabled"] = is_enabled(str(model.get("path", "")))
	return model


func _search_text(skill: Dictionary) -> String:
	var interface: Dictionary = skill.get("interface", {})
	return " ".join([
		str(skill.get("name", "")),
		str(skill.get("description", "")),
		str(skill.get("short_description", "")),
		str(skill.get("path", "")),
		str(interface.get("display_name", "")),
	]).to_lower()


func _join_path(base: String, child: String) -> String:
	var clean_base := _normalize_path(base)
	var clean_child := child.replace("\\", "/").strip_edges()
	if clean_base.ends_with("/"):
		return "%s%s" % [clean_base, clean_child]
	return "%s/%s" % [clean_base, clean_child]


func _normalize_path(path: String) -> String:
	var normalized := path.strip_edges().replace("\\", "/")
	while normalized.length() > 1 and normalized.ends_with("/") and not normalized.ends_with("://"):
		normalized = normalized.substr(0, normalized.length() - 1)
	return normalized
