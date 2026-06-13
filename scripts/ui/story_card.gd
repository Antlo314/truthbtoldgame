extends CanvasLayer
## Full-screen story card — the placeholder slot for cutscenes. Pauses the
## game while open; the real Grok videos drop into this same slot later
## (VideoStreamPlayer instead of the label stack).

signal closed

var _built := false


func open(title: String, body: String) -> void:
	if _built:
		return
	_built = true
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.02, 0.05, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(720, 0)
	v.add_theme_constant_override("separation", 24)
	center.add_child(v)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 34)
	t.add_theme_color_override("font_color", Color(1.0, 0.84, 0.45))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var b := Label.new()
	b.text = body
	b.add_theme_font_size_override("font_size", 22)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(720, 0)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)

	var btn := Button.new()
	btn.text = "CONTINUE"
	btn.add_theme_font_size_override("font_size", 22)
	btn.custom_minimum_size = Vector2(220, 56)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(close)
	v.add_child(btn)

	get_tree().paused = true
	Sfx.play("card_open")


func close() -> void:
	Sfx.play("card_close")
	if get_tree():
		get_tree().paused = false
	closed.emit()
	queue_free()
