extends "res://scripts/ui/mg_base.gd"
## Star Trace — tap the stars in order (1 → N) to trace the constellation.
## "Enoch was shown the courses of the heavenly luminaries." A pure puzzle:
## the order is marked, so it's about reading the sky, not memory.

# Each entry is a screen-fraction position inside the content area.
var star_points: Array[Vector2] = [
	Vector2(0.20, 0.78), Vector2(0.34, 0.45), Vector2(0.50, 0.62),
	Vector2(0.62, 0.28), Vector2(0.78, 0.50),
]

var _next := 0
var _buttons: Array[Button] = []
var _lines: Control


class LineDraw extends Control:
	var pts: Array[Vector2] = []        # screen fractions
	var lit := 0
	func _draw() -> void:
		var gold := Color(1.0, 0.86, 0.5, 0.9)
		for i in range(1, lit):
			draw_line(pts[i - 1] * size, pts[i] * size, gold, 3.0)


func build() -> void:
	_lines = LineDraw.new()
	_lines.pts = star_points
	_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_lines)

	for i in star_points.size():
		var b := Button.new()
		b.text = str(i + 1)
		b.add_theme_font_size_override("font_size", 22)
		b.anchor_left = star_points[i].x
		b.anchor_right = star_points[i].x
		b.anchor_top = star_points[i].y
		b.anchor_bottom = star_points[i].y
		b.offset_left = -34.0
		b.offset_right = 34.0
		b.offset_top = -34.0
		b.offset_bottom = 34.0
		b.pressed.connect(_tap.bind(i))
		content.add_child(b)
		_buttons.append(b)


func _tap(i: int) -> void:
	if i == _next:
		_buttons[i].modulate = Color(1.0, 0.85, 0.45)
		_buttons[i].disabled = true
		_next += 1
		_lines.lit = _next
		_lines.queue_redraw()
		Sfx.play("shard")
		if _next >= star_points.size():
			win()
	else:
		Sfx.play("error")
		set_instruction("The course breaks. Begin again from the first star.")
		_reset()


func _reset() -> void:
	_next = 0
	_lines.lit = 0
	_lines.queue_redraw()
	for b in _buttons:
		b.modulate = Color.WHITE
		b.disabled = false


func debug_solve() -> void:
	for i in star_points.size():
		_tap(i)
