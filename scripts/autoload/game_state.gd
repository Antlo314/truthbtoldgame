extends Node
## Global game state — Part, Oil, Gifts, Witness shards, touch input bridge.
## Registered as the `GameState` autoload.

signal oil_changed(value: float, max_value: float)
signal discern_changed(active: bool)
signal shards_changed(found: int, total: int)
signal quest_changed(stage: int)
signal alert_changed(active: bool)
signal message_flashed(text: String)

const OIL_MAX := 100.0
const OIL_DRAIN := 16.0   # per second while Discerning
const OIL_REFILL := 45.0  # per second at a study point

const OBJECTIVES := {
	0: "",
	1: "Run Lala's errand — follow the gold arrow to the corner store.",
	2: "Follow the arrow. The alley is calling.",
	3: "Hold DISCERN (Space) to see the truth — and STRIKE (F) what you find. The 5 Witness shards show on your map while Discerning.",
	4: "THE VEIL SEES YOU — follow the arrow to the steel door!",
	5: "Part 1 slice complete. To be continued…",
}

var part := 1
var oil := OIL_MAX
var discerning := false
var discernment_unlocked := false
var quest_stage := 0
var alert_active := false
var shards_total := 5
var collected_shards: Array[int] = []
var gifts: Array[String] = []
var delivered_spirits: Array[String] = []
var playtime := 0.0

var _dry_flash_at := -10.0

## Virtual joystick output (set by the HUD, read by the player).
var touch_move := Vector2.ZERO

## Guidance / minimap data (set by the level each run; world units are meters,
## minimap rect coords are x/z footprints).
var player: Node3D
var objective_pos := Vector3.INF
var minimap_world := Rect2(-22, -36, 44, 72)
var minimap_road := Rect2(-4, -36, 8, 72)
var minimap_rects: Array[Rect2] = []
var minimap_shards: Array[Vector3] = []
var study_point := Vector3.ZERO


func _ready() -> void:
	_register_actions()


func _process(delta: float) -> void:
	playtime += delta
	set_discerning(discernment_unlocked and Input.is_action_pressed("discern"))
	if discerning:
		oil = maxf(oil - OIL_DRAIN * delta, 0.0)
		oil_changed.emit(oil, OIL_MAX)
		if oil <= 0.0:
			set_discerning(false)


func set_discerning(on: bool) -> void:
	if on and oil <= 0.0:
		on = false
		if Input.is_action_just_pressed("discern") and playtime - _dry_flash_at > 2.0:
			_dry_flash_at = playtime
			flash_message("Your lamp is dry — refill at the glowing study point.")
	if discerning == on:
		return
	discerning = on
	discern_changed.emit(on)


func drain_oil(amount: float) -> void:
	if oil <= 0.0:
		return
	oil = maxf(oil - amount, 0.0)
	oil_changed.emit(oil, OIL_MAX)
	if oil <= 0.0:
		set_discerning(false)


func flash_message(text: String) -> void:
	message_flashed.emit(text)


func deliver_spirit(spirit_id: String) -> void:
	if spirit_id in delivered_spirits:
		return
	delivered_spirits.append(spirit_id)
	oil = OIL_MAX
	oil_changed.emit(oil, OIL_MAX)
	flash_message("The spirit is cast out. Your lamp burns full.")
	SaveManager.save_game()


func refill_oil(delta: float) -> void:
	if oil >= OIL_MAX:
		return
	oil = minf(oil + OIL_REFILL * delta, OIL_MAX)
	oil_changed.emit(oil, OIL_MAX)


func collect_shard(id: int) -> void:
	if id in collected_shards:
		return
	collected_shards.append(id)
	shards_changed.emit(collected_shards.size(), shards_total)
	SaveManager.save_game()


func set_stage(stage: int) -> void:
	quest_stage = stage
	quest_changed.emit(stage)
	SaveManager.save_game()


func set_alert(on: bool) -> void:
	if alert_active == on:
		return
	alert_active = on
	alert_changed.emit(on)


func objective_text() -> String:
	return OBJECTIVES.get(quest_stage, "")


func apply_save(data: Dictionary) -> void:
	collected_shards.clear()
	for id in data.get("collected_shards", []):
		collected_shards.append(int(id))
	gifts.clear()
	for g in data.get("gifts", []):
		gifts.append(str(g))
	delivered_spirits.clear()
	for d in data.get("delivered_spirits", []):
		delivered_spirits.append(str(d))
	part = int(data.get("part", 1))
	quest_stage = int(data.get("quest_stage", 0))
	discernment_unlocked = bool(data.get("discernment_unlocked", false))
	oil = float(data.get("oil", OIL_MAX))
	playtime = float(data.get("playtime", 0.0))
	oil_changed.emit(oil, OIL_MAX)
	shards_changed.emit(collected_shards.size(), shards_total)
	quest_changed.emit(quest_stage)


func _register_actions() -> void:
	# Defined in code so the mapping lives next to the gameplay that uses it;
	# editor-defined actions with the same names take priority if added later.
	var bindings := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"discern": [KEY_SPACE],
		"strike": [KEY_F],
	}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for keycode in bindings[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
