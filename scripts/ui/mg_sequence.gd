extends "res://scripts/ui/mg_base.gd"
## Light Sequence — watch the lamps, then repeat. Reach the target length and
## the seal opens. "Enoch was given the names and the orders of the holy ones."

const COLORS := [
	Color(0.85, 0.35, 0.35), Color(0.40, 0.70, 0.95),
	Color(0.55, 0.85, 0.45), Color(0.95, 0.82, 0.40),
]
const TARGET := 5  # final sequence length that wins

var _pads: Array[Button] = []
var _seq: Array[int] = []
var _input_at := 0
var _accepting := false


func build() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	grid.anchor_left = 0.5
	grid.anchor_right = 0.5
	grid.anchor_top = 0.5
	grid.anchor_bottom = 0.5
	grid.offset_left = -210.0
	grid.offset_right = 210.0
	grid.offset_top = -210.0
	grid.offset_bottom = 210.0
	content.add_child(grid)

	for i in 4:
		var b := Button.new()
		b.custom_minimum_size = Vector2(196, 196)
		b.modulate = _dim(i)
		b.pressed.connect(_tap.bind(i))
		grid.add_child(b)
		_pads.append(b)

	_extend.call_deferred()


func _dim(i: int) -> Color:
	return COLORS[i].darkened(0.45)


func _extend() -> void:
	_seq.append(randi() % 4)
	_input_at = 0
	_accepting = false
	set_instruction("Watch… (%d)" % _seq.size())
	await _show_sequence()
	_accepting = true
	set_instruction("Now repeat the lamps.")


func _show_sequence() -> void:
	await _wait(0.5)
	for idx in _seq:
		_pads[idx].modulate = COLORS[idx]
		Sfx.play("shard")
		await _wait(0.45)
		_pads[idx].modulate = _dim(idx)
		await _wait(0.2)


func _tap(i: int) -> void:
	if not _accepting:
		return
	_flash(i)
	if i == _seq[_input_at]:
		_input_at += 1
		if _input_at >= _seq.size():
			_accepting = false
			if _seq.size() >= TARGET:
				win()
			else:
				set_instruction("Right. The next lamp lights…")
				await _wait(0.7)
				_extend()
	else:
		Sfx.play("error")
		set_instruction("Broken order. Watch again from the start.")
		_accepting = false
		_seq.clear()
		await _wait(0.8)
		_extend()


func _flash(i: int) -> void:
	_pads[i].modulate = COLORS[i]
	var t := create_tween()
	t.tween_interval(0.18)
	t.tween_callback(func() -> void:
		if is_instance_valid(_pads[i]):
			_pads[i].modulate = _dim(i))


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func debug_solve() -> void:
	# Force a winning state for screenshot/flow verification.
	_seq = [0, 1, 2, 3, 0]
	win()
