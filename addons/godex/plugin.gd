@tool
extends EditorPlugin

const CONTROLLER_SCRIPT_PATH := "res://addons/godex/ui/godex_dock_controller.gd"
const MAIN_SCENE_PATH := "res://addons/godex/ui/godex_main.tscn"

var _main_screen: Control
var _controller: RefCounted
var _target_visible := false
var _entered_distraction_free := false
var _previous_distraction_free := false
var _reload_count := 0


func _enter_tree() -> void:
	_create_main_screen()


func _exit_tree() -> void:
	_restore_distraction_free()
	if _main_screen != null:
		var parent := _main_screen.get_parent()
		if parent != null:
			parent.remove_child(_main_screen)
		_main_screen.queue_free()
		_main_screen = null
	_controller = null


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "Godex"


func _get_plugin_icon() -> Texture2D:
	var theme := get_editor_interface().get_editor_theme()
	if theme.has_icon("Script", "EditorIcons"):
		return theme.get_icon("Script", "EditorIcons")
	return null


func _make_visible(visible: bool) -> void:
	_target_visible = visible
	_apply_main_screen_visibility()
	call_deferred("_apply_main_screen_visibility")
	if visible:
		call_deferred("_enter_distraction_free")
	else:
		_restore_distraction_free()


func activate_main_screen() -> Dictionary:
	var editor := get_editor_interface()
	if editor != null:
		editor.set_main_screen_editor(_get_plugin_name())
	_target_visible = true
	_apply_main_screen_visibility()
	call_deferred("_apply_main_screen_visibility")
	call_deferred("_enter_distraction_free")
	return {
		"success": _main_screen != null,
		"visible": _main_screen != null and _main_screen.visible,
		"plugin": _get_plugin_name(),
	}


func _create_main_screen() -> void:
	_remove_existing_main_screens()
	var scene := ResourceLoader.load(MAIN_SCENE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if scene == null:
		push_error("[Godex] Failed to load main screen scene: %s" % MAIN_SCENE_PATH)
		return
	_main_screen = scene.instantiate()
	_main_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_screen.visible = false
	get_editor_interface().get_editor_main_screen().add_child(_main_screen)
	var controller_script := ResourceLoader.load(CONTROLLER_SCRIPT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	if controller_script == null:
		push_error("[Godex] Failed to load controller script: %s" % CONTROLLER_SCRIPT_PATH)
		return
	_controller = controller_script.new()
	if _controller != null and _controller.has_method("setup"):
		_controller.call("setup", self, _main_screen)


func rebuild_main_screen() -> Dictionary:
	var was_visible := _target_visible
	_reload_count += 1
	_restore_distraction_free()
	_remove_existing_main_screens()
	_controller = null
	_create_main_screen()
	_target_visible = was_visible
	_apply_main_screen_visibility()
	if was_visible:
		call_deferred("_enter_distraction_free")
	return {
		"success": _main_screen != null and _controller != null,
		"reload_count": _reload_count,
		"visible": was_visible,
	}


func _remove_existing_main_screens() -> void:
	var parent := get_editor_interface().get_editor_main_screen()
	if parent == null:
		return
	for child in parent.get_children():
		if child.name == "GodexMain":
			parent.remove_child(child)
			child.queue_free()
	if _main_screen != null and _main_screen.name == "GodexMain":
		_main_screen = null


func _apply_main_screen_visibility() -> void:
	if _main_screen == null:
		return
	var parent := get_editor_interface().get_editor_main_screen()
	if _main_screen.get_parent() != parent:
		if _main_screen.get_parent() != null:
			_main_screen.get_parent().remove_child(_main_screen)
		parent.add_child(_main_screen)
	_main_screen.visible = _target_visible
	if _target_visible:
		_main_screen.move_to_front()


func _enter_distraction_free() -> void:
	var editor := get_editor_interface()
	if editor == null or _entered_distraction_free:
		return
	_previous_distraction_free = editor.is_distraction_free_mode_enabled()
	if not _previous_distraction_free:
		editor.set_distraction_free_mode(true)
	_entered_distraction_free = true


func _restore_distraction_free() -> void:
	var editor := get_editor_interface()
	if editor == null or not _entered_distraction_free:
		return
	if not _previous_distraction_free:
		editor.set_distraction_free_mode(false)
	_entered_distraction_free = false
