extends CanvasLayer
## Base for in-game mini-games. Pauses the world, dims the background, frames
## the puzzle with a title + instruction + a content area, and emits `solved`
## (or `bailed` if the player backs out). Subclasses fill `content` and call
## `win()` when the puzzle is beaten.

signal solved
signal bailed

var content: Control          # subclasses build their puzzle in here
var _instruction: Label
var _won := false


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)


func open(title: String, instruction: String) -> void:
	get_tree().paused = true
	Sfx.play("card_open")

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.45))
	title_lbl.anchor_right = 1.0
	title_lbl.offset_top = 28.0
	title_lbl.offset_bottom = 70.0
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title_lbl)

	_instruction = Label.new()
	_instruction.text = instruction
	_instruction.add_theme_font_size_override("font_size", 19)
	_instruction.anchor_right = 1.0
	_instruction.offset_top = 74.0
	_instruction.offset_bottom = 122.0
	_instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_instruction)

	content = Control.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.offset_top = 130.0
	content.offset_bottom = -96.0
	add_child(content)

	var leave := Button.new()
	leave.text = "STEP BACK"
	leave.add_theme_font_size_override("font_size", 18)
	leave.anchor_left = 0.5
	leave.anchor_right = 0.5
	leave.anchor_top = 1.0
	leave.anchor_bottom = 1.0
	leave.offset_left = -110.0
	leave.offset_right = 110.0
	leave.offset_top = -78.0
	leave.offset_bottom = -34.0
	leave.pressed.connect(_bail)
	add_child(leave)

	build()


## Subclasses override to construct their puzzle inside `content`.
func build() -> void:
	pass


func set_instruction(text: String) -> void:
	if _instruction:
		_instruction.text = text


func win() -> void:
	if _won:
		return
	_won = true
	Sfx.play("cast_out")
	set_instruction("Opened.")
	var t := create_tween()
	t.tween_interval(0.7)
	t.tween_callback(func() -> void:
		get_tree().paused = false
		solved.emit()
		queue_free())


func _bail() -> void:
	Sfx.play("card_close")
	get_tree().paused = false
	bailed.emit()
	queue_free()
