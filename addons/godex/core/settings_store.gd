@tool
class_name GodexSettingsStore
extends RefCounted

const SETTINGS_PATH := "user://godex/settings.json"


func load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return {}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func save_settings(settings: Dictionary) -> Dictionary:
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive("godex")
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return {"success": false, "error": "open_failed"}
	file.store_string(JSON.stringify(settings, "\t"))
	return {"success": true, "path": SETTINGS_PATH}
