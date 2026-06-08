@tool
class_name GodexShimmerText
extends Control

@export var text: String = "正在思考":
	set(value):
		if text == value:
			return
		text = value
		queue_redraw()
		update_minimum_size()

@export var font_size: int = 14:
	set(value):
		if font_size == value:
			return
		font_size = value
		queue_redraw()
		update_minimum_size()

@export var base_color: Color = Color(0.56, 0.58, 0.60):
	set(value):
		if base_color == value:
			return
		base_color = value
		queue_redraw()

@export var highlight_color: Color = Color(0.92, 0.94, 0.98):
	set(value):
		if highlight_color == value:
			return
		highlight_color = value
		queue_redraw()

var _phase := 0.0


func _ready() -> void:
	set_shimmer_active(true)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_shimmer_active(active: bool) -> void:
	set_process(active)
	if not active:
		_phase = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * 0.65, 1.0)
	queue_redraw()


func _get_minimum_size() -> Vector2:
	var font := get_theme_font("font", "Label")
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	return Vector2(ceil(size.x), ceil(size.y))


func _draw() -> void:
	var font := get_theme_font("font", "Label")
	if font == null or text.is_empty():
		return
	var ascent := font.get_ascent(font_size)
	var cursor_x := 0.0
	var width := max(1.0, size.x)
	var light_x := lerpf(-width * 0.35, width * 1.25, _phase)
	var band := max(20.0, width * 0.34)
	for i in range(text.length()):
		var ch := text.substr(i, 1)
		var advance := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var center_x := cursor_x + advance * 0.5
		var distance := abs(center_x - light_x)
		var glow := clampf(1.0 - distance / band, 0.0, 1.0)
		var color := base_color.lerp(highlight_color, glow)
		font.draw_string(get_canvas_item(), Vector2(cursor_x, ascent), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		cursor_x += advance
