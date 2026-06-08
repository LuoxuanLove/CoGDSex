@tool
class_name GodexGitChangeSummaryService
extends RefCounted

const DEFAULT_TITLE := "文件已更改"


func build_summary(input: Dictionary) -> Dictionary:
	var files := _merge_file_rows(
		_parse_numstat(str(input.get("numstat", ""))),
		_parse_porcelain_status(str(input.get("status_porcelain", "")))
	)
	for raw_file in input.get("files", []):
		if not (raw_file is Dictionary):
			continue
		var path := _normalize_path(str(raw_file.get("path", "")))
		if path.is_empty():
			continue
		files[path] = {
			"path": path,
			"added": max(0, int(raw_file.get("added", raw_file.get("additions", 0)))),
			"removed": max(0, int(raw_file.get("removed", raw_file.get("deletions", 0)))),
			"status": str(raw_file.get("status", "modified")),
		}
	var rows: Array[Dictionary] = []
	for key in files.keys():
		var row: Dictionary = files[key]
		if not str(row.get("path", "")).is_empty():
			rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("path", "")) < str(b.get("path", "")))
	var added := 0
	var removed := 0
	for row in rows:
		added += int(row.get("added", 0))
		removed += int(row.get("removed", 0))
	return {
		"file_count": rows.size(),
		"added": added,
		"removed": removed,
		"files": rows,
		"expanded": bool(input.get("expanded", false)),
		"status": str(input.get("status", "ready")),
		"title": str(input.get("title", DEFAULT_TITLE)),
	}


func _parse_numstat(text: String) -> Dictionary:
	var rows := {}
	for raw_line in text.split("\n", false):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		var parts := line.split("\t", false)
		if parts.size() < 3:
			parts = line.split(" ", false)
		if parts.size() < 3:
			continue
		var path := _normalize_path(str(parts[2]))
		if path.is_empty():
			continue
		rows[path] = {
			"path": path,
			"added": _parse_numstat_count(str(parts[0])),
			"removed": _parse_numstat_count(str(parts[1])),
			"status": "modified",
		}
	return rows


func _parse_porcelain_status(text: String) -> Dictionary:
	var rows := {}
	for raw_line in text.split("\n", false):
		var line := raw_line.rstrip("\r")
		if line.length() < 4:
			continue
		var status_code := line.substr(0, 2).strip_edges()
		var path := _normalize_path(line.substr(3))
		if path.contains(" -> "):
			path = _normalize_path(path.split(" -> ", false)[-1])
		if path.is_empty():
			continue
		rows[path] = {
			"path": path,
			"added": 0,
			"removed": 0,
			"status": _status_name(status_code),
		}
	return rows


func _merge_file_rows(numstat_rows: Dictionary, status_rows: Dictionary) -> Dictionary:
	var merged := {}
	for key in status_rows.keys():
		merged[key] = status_rows[key].duplicate(true)
	for key in numstat_rows.keys():
		var numstat_row: Dictionary = numstat_rows[key]
		var row: Dictionary = merged.get(key, {
			"path": str(numstat_row.get("path", key)),
			"added": 0,
			"removed": 0,
			"status": "modified",
		})
		row["added"] = int(numstat_row.get("added", 0))
		row["removed"] = int(numstat_row.get("removed", 0))
		merged[key] = row
	return merged


func _parse_numstat_count(value: String) -> int:
	if value == "-":
		return 0
	return max(0, int(value))


func _normalize_path(path: String) -> String:
	var cleaned := path.strip_edges().trim_prefix("\"").trim_suffix("\"")
	return cleaned.replace("\\", "/")


func _status_name(code: String) -> String:
	if code.begins_with("A") or code.ends_with("A") or code == "??":
		return "added"
	if code.begins_with("D") or code.ends_with("D"):
		return "deleted"
	if code.begins_with("R") or code.ends_with("R"):
		return "renamed"
	if code.begins_with("C") or code.ends_with("C"):
		return "copied"
	return "modified"
