extends CanvasLayer
## Touch controls + HUD, built in code. Anchored virtual joystick bottom-left
## (visible resting pad), hold-to-Discern button bottom-right, Oil bar,
## shard counter, objective arrow with distance, and a minimap of the block.
## Works with mouse/keyboard on desktop too.

const STICK_RADIUS := 90.0

var _touch_id := -1

var _stick_visual: StickVisual
var _arrow: ArrowVisual
var _minimap: MinimapVisual
var _discern_btn: Button
var _oil_bar: ProgressBar
var _shard_label: Label
var _hint: Label
var _vignette: ColorRect
var _pulse := 0.0


class StickVisual extends Control:
	const RADIUS := 90.0
	const HOME_OFFSET := Vector2(160, 180)  # from the bottom-left corner

	var thumb := Vector2.ZERO
	var active := false

	func home() -> Vector2:
		var vp := get_viewport_rect().size
		return Vector2(HOME_OFFSET.x, vp.y - HOME_OFFSET.y)

	func _draw() -> void:
		var c := home()
		draw_circle(c, RADIUS, Color(1, 1, 1, 0.16 if active else 0.07))
		draw_arc(c, RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.30 if active else 0.14), 2.0)
		draw_circle(c + thumb, 34.0, Color(1, 1, 1, 0.35 if active else 0.16))


class ArrowVisual extends Control:
	func _draw() -> void:
		var target: Vector3 = GameState.objective_pos
		if target == Vector3.INF:
			return
		var cam := get_viewport().get_camera_3d()
		if cam == null:
			return
		var vp := get_viewport_rect().size
		var center := vp * 0.5
		var behind := cam.is_position_behind(target)
		var sp := cam.unproject_position(target)
		var dist := int(cam.global_position.distance_to(target))
		var font := ThemeDB.fallback_font
		var gold := Color(1.0, 0.84, 0.4, 0.95)
		var on_screen := not behind and sp.x > 0.0 and sp.x < vp.x and sp.y > 0.0 and sp.y < vp.y
		if on_screen:
			var p := sp + Vector2(0, -36)
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, 14), p + Vector2(-11, -6), p + Vector2(11, -6)]), gold)
			draw_string(font, p + Vector2(-24, -14), "%d m" % dist, HORIZONTAL_ALIGNMENT_CENTER, 48, 18, gold)
		else:
			var dir := sp - center
			if behind:
				dir = -dir
			if dir.length() < 1.0:
				dir = Vector2(0, -1)
			dir = dir.normalized()
			var margin := 64.0
			var tx := INF if absf(dir.x) < 0.001 else (vp.x * 0.5 - margin) / absf(dir.x)
			var ty := INF if absf(dir.y) < 0.001 else (vp.y * 0.5 - margin) / absf(dir.y)
			var p := center + dir * minf(tx, ty)
			draw_set_transform(p, dir.angle(), Vector2.ONE)
			draw_colored_polygon(PackedVector2Array([Vector2(18, 0), Vector2(-10, 11), Vector2(-10, -11)]), gold)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_string(font, p - dir * 34.0 + Vector2(-24, 6), "%d m" % dist, HORIZONTAL_ALIGNMENT_CENTER, 48, 18, gold)


class MinimapVisual extends Control:
	func _draw() -> void:
		var world: Rect2 = GameState.minimap_world
		var px := size
		draw_rect(Rect2(Vector2.ZERO, px), Color(0.05, 0.06, 0.08, 0.55))
		draw_rect(Rect2(Vector2.ZERO, px), Color(1, 1, 1, 0.25), false, 1.5)
		draw_rect(_map_rect(GameState.minimap_road, world, px), Color(0.25, 0.26, 0.28, 0.9))
		for r in GameState.minimap_rects:
			draw_rect(_map_rect(r, world, px), Color(0.55, 0.30, 0.24, 0.9))
		draw_circle(_map_pt(GameState.study_point, world, px), 3.0, Color(0.3, 0.85, 0.9))
		if GameState.discerning:
			for s in GameState.minimap_shards:
				draw_circle(_map_pt(s, world, px), 3.0, Color(1.0, 0.8, 0.3))
		if GameState.objective_pos != Vector3.INF:
			draw_circle(_map_pt(GameState.objective_pos, world, px), 4.5, Color(1.0, 0.84, 0.4))
		if GameState.player and is_instance_valid(GameState.player):
			var pp := _map_pt(GameState.player.position, world, px)
			var yaw: float = GameState.player.rotation.y
			var facing := Vector2(-sin(yaw), -cos(yaw))
			draw_line(pp, pp + facing * 9.0, Color(1, 1, 1, 0.9), 2.0)
			draw_circle(pp, 3.5, Color.WHITE)

	func _map_pt(p: Vector3, world: Rect2, px: Vector2) -> Vector2:
		return Vector2(
			(p.x - world.position.x) / world.size.x * px.x,
			(p.z - world.position.y) / world.size.y * px.y
		)

	func _map_rect(r: Rect2, world: Rect2, px: Vector2) -> Rect2:
		return Rect2(
			Vector2((r.position.x - world.position.x) / world.size.x * px.x,
				(r.position.y - world.position.y) / world.size.y * px.y),
			Vector2(r.size.x / world.size.x * px.x, r.size.y / world.size.y * px.y)
		)


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

	_arrow = ArrowVisual.new()
	_arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_arrow)

	_minimap = MinimapVisual.new()
	_minimap.anchor_left = 1.0
	_minimap.anchor_right = 1.0
	_minimap.offset_left = -180.0
	_minimap.offset_top = 64.0
	_minimap.offset_right = -24.0
	_minimap.offset_bottom = 64.0 + 156.0 * 72.0 / 44.0
	_minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_minimap)

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
	_stick_visual.queue_redraw()
	_arrow.queue_redraw()
	_minimap.queue_redraw()


func _input(event: InputEvent) -> void:
	var vp := _stick_visual.get_viewport_rect().size
	if event is InputEventScreenTouch:
		if event.pressed and _touch_id == -1 and event.position.x < vp.x * 0.5 and event.position.y > vp.y * 0.4:
			_touch_id = event.index
			_update_stick(event.position)
		elif not event.pressed and event.index == _touch_id:
			_touch_id = -1
			_set_stick(Vector2.ZERO, false)
	elif event is InputEventScreenDrag and event.index == _touch_id:
		_update_stick(event.position)


func _update_stick(touch_pos: Vector2) -> void:
	var offset: Vector2 = (touch_pos - _stick_visual.home()).limit_length(STICK_RADIUS)
	_set_stick(offset / STICK_RADIUS, true)


func _set_stick(vec: Vector2, active: bool) -> void:
	GameState.touch_move = vec
	_stick_visual.thumb = vec * STICK_RADIUS
	_stick_visual.active = active


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
