@tool
class_name GodexTheme
extends RefCounted

const BG := Color(0.055, 0.058, 0.06)
const PANEL := Color(0.12, 0.12, 0.12)
const PANEL_SOFT := Color(0.16, 0.16, 0.16)
const BORDER := Color(0.22, 0.23, 0.24)
const SIDEBAR := Color(0.075, 0.105, 0.125)
const TEXT := Color(0.90, 0.92, 0.94)
const MUTED := Color(0.58, 0.60, 0.62)
const BLUE := Color(0.24, 0.62, 1.0)
const GREEN := Color(0.34, 0.78, 0.48)
const WARNING := Color(0.95, 0.72, 0.26)


static func panel_style(color: Color = PANEL, radius: int = 8, border_color: Color = BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func button_style(color: Color, pressed: bool = false) -> StyleBoxFlat:
	var style := panel_style(color, 6, Color(0, 0, 0, 0))
	if pressed:
		style.border_color = BLUE
		style.set_border_width_all(1)
	return style


static func paint_label(label: Label, color: Color = TEXT, font_size: int = 14) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)


static func paint_button(button: Button, selected: bool = false) -> void:
	button.flat = true
	button.add_theme_color_override("font_color", TEXT if selected else Color(0.78, 0.80, 0.82))
	button.add_theme_stylebox_override("normal", button_style(PANEL_SOFT if selected else Color(0, 0, 0, 0), selected))
	button.add_theme_stylebox_override("hover", button_style(Color(0.18, 0.19, 0.20), selected))
	button.add_theme_stylebox_override("pressed", button_style(Color(0.20, 0.21, 0.22), true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
