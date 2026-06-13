extends "res://scripts/ui/mg_base.gd"
## Cipher Lock — the letters are scrambled; tap two tiles to swap them until
## they spell the word that breaks the seal. A "decode the truth" puzzle.
## Set `target` before open() to choose the word.

var target := "TRUTH"

var _letters: Array = []
var _buttons: Array[Button] = []
var _selected := -1
var _row: HBoxContainer


func build() -> void:
	_letters = []
	for c in target:
		_letters.append(c)
	# Scramble until it isn't already the answer.
	var attempts := 0
	while _join() == target and attempts < 20:
		_letters.shuffle()
		attempts += 1

	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 14)
	_row.anchor_left = 0.5
	_row.anchor_right = 0.5
	_row.anchor_top = 0.5
	_row.anchor_bottom = 0.5
	_row.offset_left = -float(target.length()) * 52.0
	_row.offset_right = float(target.length()) * 52.0
	_row.offset_top = -52.0
	_row.offset_bottom = 52.0
	content.add_child(_row)

	for i in _letters.size():
		var b := Button.new()
		b.text = _letters[i]
		b.add_theme_font_size_override("font_size", 40)
		b.custom_minimum_size = Vector2(88, 104)
		b.pressed.connect(_tap.bind(i))
		_row.add_child(b)
		_buttons.append(b)


func _tap(i: int) -> void:
	if _selected == -1:
		_selected = i
		_buttons[i].modulate = Color(1.0, 0.85, 0.45)
		Sfx.play("swing")
		return
	if _selected == i:
		_buttons[i].modulate = Color.WHITE
		_selected = -1
		return
	# Swap the two tiles.
	var tmp = _letters[_selected]
	_letters[_selected] = _letters[i]
	_letters[i] = tmp
	_buttons[_selected].text = _letters[_selected]
	_buttons[i].text = _letters[i]
	_buttons[_selected].modulate = Color.WHITE
	_selected = -1
	Sfx.play("shard")
	if _join() == target:
		for b in _buttons:
			b.modulate = Color(1.0, 0.85, 0.45)
			b.disabled = true
		win()


func _join() -> String:
	var s := ""
	for c in _letters:
		s += c
	return s


func debug_solve() -> void:
	_letters = []
	for c in target:
		_letters.append(c)
	win()
