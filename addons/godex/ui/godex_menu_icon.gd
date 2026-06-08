@tool
class_name GodexMenuIcon
extends Control

@export var icon_kind := "plus":
	set(value):
		icon_kind = value
		queue_redraw()

@export var icon_color := Color(0.90, 0.92, 0.94):
	set(value):
		icon_color = value
		queue_redraw()


func _ready() -> void:
	custom_minimum_size = Vector2(24, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var c := icon_color
	match icon_kind:
		"paperclip":
			_draw_paperclip(c)
		"plan":
			_draw_plan(c)
		"target":
			_draw_target(c)
		"plugins":
			_draw_plugins(c)
		"compress":
			_draw_compress(c)
		_:
			draw_line(Vector2(12, 6), Vector2(12, 18), c, 2.0, true)
			draw_line(Vector2(6, 12), Vector2(18, 12), c, 2.0, true)


func _draw_paperclip(c: Color) -> void:
	draw_arc(Vector2(12, 8), 5.0, PI, TAU, 18, c, 2.0, true)
	draw_line(Vector2(7, 8), Vector2(7, 16), c, 2.0, true)
	draw_arc(Vector2(12, 16), 5.0, 0.0, PI, 18, c, 2.0, true)
	draw_line(Vector2(17, 8), Vector2(17, 17), c, 2.0, true)
	draw_arc(Vector2(12, 17), 2.4, 0.0, PI, 12, c, 1.8, true)
	draw_line(Vector2(9.6, 9), Vector2(9.6, 16.5), c, 1.8, true)


func _draw_plan(c: Color) -> void:
	draw_line(Vector2(8, 7), Vector2(16, 7), c, 2.0, true)
	draw_line(Vector2(8, 12), Vector2(16, 12), c, 2.0, true)
	draw_line(Vector2(8, 17), Vector2(16, 17), c, 2.0, true)
	draw_circle(Vector2(5, 7), 1.5, c)
	draw_circle(Vector2(5, 12), 1.5, c)
	draw_line(Vector2(3.6, 17), Vector2(4.8, 18.4), c, 1.8, true)
	draw_line(Vector2(4.8, 18.4), Vector2(7.0, 15.4), c, 1.8, true)


func _draw_target(c: Color) -> void:
	draw_arc(Vector2(12, 12), 8.0, 0.15, TAU - 0.65, 40, c, 2.0, true)
	draw_arc(Vector2(12, 12), 4.3, 0.0, TAU, 32, c, 1.8, true)
	draw_line(Vector2(12, 3), Vector2(12, 7), c, 2.0, true)
	draw_line(Vector2(17.8, 5), Vector2(14.6, 8.2), c, 2.0, true)
	draw_circle(Vector2(12, 12), 1.4, c)


func _draw_plugins(c: Color) -> void:
	for x in [7.0, 17.0]:
		for y in [7.0, 17.0]:
			draw_arc(Vector2(x, y), 2.4, 0.0, TAU, 18, c, 1.8, true)


func _draw_compress(c: Color) -> void:
	draw_line(Vector2(5, 7), Vector2(10, 12), c, 2.0, true)
	draw_line(Vector2(5, 17), Vector2(10, 12), c, 2.0, true)
	draw_line(Vector2(19, 7), Vector2(14, 12), c, 2.0, true)
	draw_line(Vector2(19, 17), Vector2(14, 12), c, 2.0, true)
	draw_line(Vector2(10, 12), Vector2(14, 12), c, 2.0, true)
