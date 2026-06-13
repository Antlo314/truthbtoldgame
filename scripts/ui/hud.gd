extends CanvasLayer
## Touch controls + HUD, built in code. Floating virtual joystick on the left
## half of the screen, hold-to-Discern button bottom-right, Oil bar and
## Witness shard counter. Works with mouse/keyboard on desktop too.

const STICK_RADIUS := 90.0

var _touch_id := -1
var _stick_center := Vector2.ZERO

var _stick_visual: StickVisual
var _discern_btn: Button
var _oil_bar: ProgressBar
var _shard_label: Label
var _hint: Label
var _vignette: ColorRect
var _pulse := 0.0


class StickVisual extends Control:
	var center := Vector2.ZERO
	var thumb := Vector2.ZERO
	var active := false

	func _draw() -> void:
		if not active:
			return
		draw_circle(center, 90.0, Color(1, 1, 1, 0.07))
		draw_arc(center, 90.0, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
		draw_circle(center + thumb, 34.0, Color(1, 1, 1, 0.3))


func _ready() -> void:
	_vignette = ColorRect.new()
	_vignette.color = Color(0.75, 0.08, 0.08, 0.0)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vignette)

	_stick_visual = StickVisual.new()
	_stick_visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stick_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stick_visual)

	_discern_btn = Button.new()
	_discern_btn.text = "DISCERN"
	_discern_btn.add_theme_font_size_override("font_size", 22)
	_discern_btn.anchor_left = 1.0
	_discern_btn.anchor_top = 1.0
	_discern_btn.anchor_right = 1.0
	_discern_btn.anchor_bottom = 1.0
	_discern_btn.offset_left = -190.0
	_discern_btn.offset_top = -190.0
	_discern_btn.offset_right = -40.0
	_discern_btn.offset_bottom = -40.0
	_discern_btn.button_down.connect(func() -> void: Input.action_press("discern"))
	_discern_btn.button_up.connect(func() -> void: Input.action_release("discern"))
	add_child(_discern_btn)

	_oil_bar = ProgressBar.new()
	_oil_bar.max_value = GameState.OIL_MAX
	_oil_bar.value = GameState.oil
	_oil_bar.show_percentage = false
	_oil_bar.offset_left = 24.0
	_oil_bar.offset_top = 24.0
	_oil_bar.offset_right = 280.0
	_oil_bar.offset_bottom = 52.0
	add_child(_oil_bar)

	var oil_label := Label.new()
	oil_label.text = "OIL"
	oil_label.add_theme_font_size_override("font_size", 16)
	oil_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	oil_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oil_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_oil_bar.add_child(oil_label)

	_shard_label = Label.new()
	_shard_label.add_theme_font_size_override("font_size", 24)
	_shard_label.anchor_left = 1.0
	_shard_label.anchor_right = 1.0
	_shard_label.offset_left = -340.0
	_shard_label.offset_top = 24.0
	_shard_label.offset_right = -24.0
	_shard_label.offset_bottom = 56.0
	_shard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_shard_label)

	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 20)
	_hint.anchor_top = 1.0
	_hint.anchor_bottom = 1.0
	_hint.anchor_right = 1.0
	_hint.offset_left = 24.0
	_hint.offset_top = -150.0
	_hint.offset_right = -240.0
	_hint.offset_bottom = -110.0
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_hint)

	GameState.oil_changed.connect(_on_oil_changed)
	GameState.shards_changed.connect(_on_shards_changed)
	GameState.discern_changed.connect(_on_discern_changed)
	GameState.quest_changed.connect(_on_quest_changed)
	_on_shards_changed(GameState.collected_shards.size(), GameState.shards_total)
	_on_quest_changed(GameState.quest_stage)


func _process(delta: float) -> void:
	var target := 0.0
	if GameState.alert_active:
		_pulse += delta
		target = 0.10 + 0.05 * sin(_pulse * 6.0)
	_vignette.color.a = lerpf(_vignette.color.a, target, minf(1.0, 10.0 * delta))


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1 and event.position.x < _half_width():
			_touch_id = event.index
			_stick_center = event.position
			_set_stick(Vector2.ZERO, true)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_set_stick(Vector2.ZERO, false)
	elif event is InputEventScreenDrag and event.index == _touch_id:
		var offset: Vector2 = (event.position - _stick_center).limit_length(STICK_RADIUS)
		_set_stick(offset / STICK_RADIUS, true)


func _half_width() -> float:
	return _stick_visual.get_viewport_rect().size.x * 0.5


func _set_stick(vec: Vector2, active: bool) -> void:
	GameState.touch_move = vec
	_stick_visual.center = _stick_center
	_stick_visual.thumb = vec * STICK_RADIUS
	_stick_visual.active = active
	_stick_visual.queue_redraw()


func _on_oil_changed(value: float, _max_value: float) -> void:
	_oil_bar.value = value


func _on_shards_changed(found: int, total: int) -> void:
	_shard_label.text = "Witness shards: %d / %d" % [found, total]


func _on_quest_changed(_stage: int) -> void:
	_hint.text = GameState.objective_text()
	_discern_btn.visible = GameState.discernment_unlocked
	_oil_bar.visible = GameState.discernment_unlocked
	_shard_label.visible = GameState.discernment_unlocked


func _on_discern_changed(active: bool) -> void:
	_discern_btn.modulate = Color(1.0, 0.82, 0.4) if active else Color.WHITE
