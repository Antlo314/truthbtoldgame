extends Node3D
## Part 1 slice — one St. Louis block built from Kenney kit pieces, with the
## core loop on top: hold Discern to reveal hidden Witness shards (and the
## spirit world), collect all five, refill Oil at the study point in the
## alley. Progress autosaves on every pickup.
##
## Screenshot mode (used for visual verification):
##   godot --path . ++ --screenshot

const ROAD_WIDTH := 8.0  # world meters per kit tile
const CAR_SCALE := 1.76  # car kit is its own scale: sedan is 2.55 units ≈ 4.5 m
const COLLECT_RANGE := 1.7
const REFILL_RANGE := 3.0
const STUDY_POINT := Vector3(8, 0, 8)
const STORE_POS := Vector3(4.3, 0, -12)   # corner store front (building-g)
const BOOK_POS := Vector3(9, 0, 0.5)      # alley wall cavity
const DOOR_POS := Vector3(-3.7, 0, 12)    # safehouse steel door (building-j)

const CARD_SCRIPT := preload("res://scripts/ui/story_card.gd")
const INTRO_TITLE := "A MESSAGE FROM LALA"
const INTRO_BODY := "\"You ever think about using that voice of yours? Somebody's got to tell the truth.\"\n\nThen a second buzz:\n\n\"Run me a favor today? My package is waiting at the corner store on your block. I'll owe you one.\""

const BRICK_TINTS: Array[Color] = [
	Color(0.85, 0.52, 0.42),
	Color(0.92, 0.68, 0.55),
	Color(0.78, 0.45, 0.40),
	Color(0.90, 0.80, 0.70),
	Color(0.82, 0.60, 0.50),
]

const SHARD_POSITIONS: Array[Vector3] = [
	Vector3(13.5, 0.8, 8),    # in the alley
	Vector3(14, 0.8, -20),    # behind the east row
	Vector3(0, 0.8, 0),       # middle of the crosswalk
	Vector3(-2.5, 0.8, 24),   # south street
	Vector3(2, 0.8, -31),     # north plaza
]

var _kit_scale := 1.0
var _player: CharacterBody3D
var _cam_rig: Node3D
var _shards := {}
var _hidden_nodes: Array[Node3D] = []
var _env: Environment
var _watcher: CharacterBody3D
var _book: MeshInstance3D
var _beam: MeshInstance3D
var _card: CanvasLayer

var _shot := false
var _shot_quest := false
var _frames := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	_shot = args.has("--screenshot")
	_shot_quest = args.has("--screenshot-quest")
	SaveManager.load_game()
	GameState.shards_total = SHARD_POSITIONS.size()
	GameState.minimap_rects.clear()
	GameState.minimap_shards.clear()
	GameState.study_point = STUDY_POINT
	if _shot:
		GameState.quest_stage = 3
		GameState.discernment_unlocked = true
	_measure_kit()
	_build_environment()
	_build_block()
	_spawn_quest_objects()
	_spawn_shards()
	_spawn_player()
	_spawn_npcs()
	_build_camera()
	add_child(preload("res://scripts/ui/hud.gd").new())
	GameState.discern_changed.connect(_on_discern_changed)
	GameState.shards_changed.connect(_on_shards_progress)
	_apply_stage(GameState.quest_stage)
	if GameState.quest_stage == 3 and GameState.collected_shards.size() >= GameState.shards_total:
		GameState.set_stage(4)
		_apply_stage(4)
	if _shot or _shot_quest:
		process_mode = Node.PROCESS_MODE_ALWAYS
	elif GameState.quest_stage == 0:
		_show_intro.call_deferred()


func _process(delta: float) -> void:
	if _player == null:
		return
	_cam_rig.position = _cam_rig.position.lerp(_player.position + Vector3.UP * 1.7, minf(1.0, 8.0 * delta))
	for shard in _shards.values():
		shard.rotate_y(2.0 * delta)
	if _shot or _shot_quest:
		_run_screenshot_script()


func _physics_process(delta: float) -> void:
	if _player == null:
		return
	match GameState.quest_stage:
		1:
			if _player.position.distance_to(STORE_POS) < 2.6:
				_stage_card(2, "LALA'S PACKAGE",
					"The shopkeeper hands it over without a word — but his eyes hold yours one beat too long.\n\nThe quickest way home cuts through the alley.")
		2:
			if _player.position.distance_to(BOOK_POS) < 2.0:
				GameState.discernment_unlocked = true
				_stage_card(3, "THE HIDDEN BOOK",
					"In a broken cavity of the alley wall, wrapped in cloth nobody has touched in a long time: a book. The letters on the cover glow under your fingers.\n\nIt wasn't lost. It was waiting.\n\nThe alley peels back like paper. The city is not what it was.\n\n— DISCERNMENT UNLOCKED —")
		4:
			if _player.position.distance_to(DOOR_POS) < 2.4:
				_stage_card(5, "THE SAFEHOUSE",
					"A steel door swings open and a strong hand pulls you inside. Maps. Scripture. A timeline pinned across an entire wall: GENESIS 15:13 — 400 YEARS.\n\nBRO RASHAUD: \"You opened it. Then you already know — truth don't hide. It's hidden. Different thing.\"\n\n— PART 1 SLICE COMPLETE — TO BE CONTINUED —")
			elif _watcher and _watcher.chasing and _watcher.position.distance_to(_player.position) < 1.5:
				_player.position = Vector3(0, 0.2, 2)
				_player.velocity = Vector3.ZERO
				_watcher.reset_home()
				GameState.flash_message("They grabbed you — you slipped away. RUN!")
	if GameState.discerning:
		for id in _shards.keys():
			var shard: MeshInstance3D = _shards[id]
			if _player.position.distance_to(shard.position) < COLLECT_RANGE:
				GameState.collect_shard(id)
				GameState.minimap_shards.erase(SHARD_POSITIONS[id])
				shard.queue_free()
				_shards.erase(id)
	elif _player.position.distance_to(STUDY_POINT) < REFILL_RANGE:
		GameState.refill_oil(delta)


# --- world building -------------------------------------------------------

func _measure_kit() -> void:
	var tile: Node3D = (load("res://assets/models/roads/road-straight.glb") as PackedScene).instantiate()
	add_child(tile)
	var aabb := _combined_aabb(tile)
	_kit_scale = ROAD_WIDTH / maxf(aabb.size.x, 0.01)
	tile.queue_free()


func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

	_env = Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.30, 0.46)
	sky_mat.sky_horizon_color = Color(0.78, 0.62, 0.50)
	sky_mat.ground_horizon_color = Color(0.55, 0.48, 0.42)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	var world_env := WorldEnvironment.new()
	world_env.environment = _env
	add_child(world_env)

	# Visible ground (asphalt-dark), top just below the road tiles
	var ground_mesh := MeshInstance3D.new()
	var gbox := BoxMesh.new()
	gbox.size = Vector3(80, 1, 90)
	ground_mesh.mesh = gbox
	ground_mesh.position = Vector3(0, -0.54, 0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.20, 0.20, 0.19)
	ground_mesh.material_override = gmat
	add_child(ground_mesh)

	# Invisible walking surface, top at exactly y=0
	_invisible_box(Vector3(80, 1, 90), Vector3(0, -0.5, 0))

	# Boundary walls
	_invisible_box(Vector3(1, 6, 90), Vector3(-21, 3, 0))
	_invisible_box(Vector3(1, 6, 90), Vector3(21, 3, 0))
	_invisible_box(Vector3(60, 6, 1), Vector3(0, 3, -34))
	_invisible_box(Vector3(60, 6, 1), Vector3(0, 3, 34))


func _build_block() -> void:
	# Road running north-south, crosswalk in the middle
	for i in range(-4, 5):
		var z := i * ROAD_WIDTH
		var piece := "road-crossing" if i == 0 else "road-straight"
		_place_kit("res://assets/models/roads/%s.glb" % piece, Vector3(0, 0, z), 0.0, Color(0, 0, 0, 0), false, true)

	# East row (alley gap at z = 4 and z = 12)
	var east := {
		-28: "building-k", -20: "building-a", -12: "building-g", -4: "building-c",
		20: "building-d", 28: "building-b",
	}
	var west := {
		-20: "building-e", -12: "building-f", -4: "building-h",
		4: "building-i", 12: "building-j", 20: "building-l", 28: "building-m",
	}
	var tint_i := 0
	for z in east:
		_place_kit("res://assets/models/city/%s.glb" % east[z], Vector3(8, 0, z), -90.0, BRICK_TINTS[tint_i % BRICK_TINTS.size()], true)
		tint_i += 1
	for z in west:
		_place_kit("res://assets/models/city/%s.glb" % west[z], Vector3(-8, 0, z), 90.0, BRICK_TINTS[tint_i % BRICK_TINTS.size()], true)
		tint_i += 1
	# Skyscraper has a wider footprint — set back from the road
	_place_kit("res://assets/models/city/building-skyscraper-a.glb", Vector3(-10, 0, -28), 90.0, Color(0, 0, 0, 0), true)

	# Parked cars (car kit uses its own scale)
	_place_kit("res://assets/models/cars/sedan.glb", Vector3(2.7, 0, -14), 180.0, Color(0, 0, 0, 0), true, false, CAR_SCALE)
	_place_kit("res://assets/models/cars/taxi.glb", Vector3(-2.7, 0, 10), 0.0, Color(0, 0, 0, 0), true, false, CAR_SCALE)
	_place_kit("res://assets/models/cars/police.glb", Vector3(2.7, 0, 20), 180.0, Color(0, 0, 0, 0), true, false, CAR_SCALE)

	# Streetlights
	_place_kit("res://assets/models/roads/light-curved.glb", Vector3(4.6, 0, -16), -90.0)
	_place_kit("res://assets/models/roads/light-curved.glb", Vector3(-4.6, 0, 16), 90.0)

	# Study point — glowing disc in the alley
	var study := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.1
	disc.bottom_radius = 1.1
	disc.height = 0.15
	study.mesh = disc
	study.position = STUDY_POINT + Vector3(0, 0.08, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.85, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.9)
	mat.emission_energy_multiplier = 1.8
	study.material_override = mat
	add_child(study)


func _place_kit(path: String, pos: Vector3, yaw := 0.0, tint := Color(0, 0, 0, 0), with_collision := false, flush_top := false, scale_override := 0.0) -> Node3D:
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("Missing kit piece: " + path)
		return null
	var s := scale_override if scale_override > 0.0 else _kit_scale
	var inst: Node3D = packed.instantiate()
	add_child(inst)
	inst.scale = Vector3.ONE * s
	inst.rotation_degrees.y = yaw
	var aabb := _combined_aabb(inst)
	var y := pos.y - aabb.position.y * s
	if flush_top:
		y = pos.y - (aabb.position.y + aabb.size.y) * s
	inst.position = Vector3(pos.x, y, pos.z)
	if tint.a > 0.0:
		_tint(inst, tint)
	if with_collision:
		var size := aabb.size * s
		if int(roundf(absf(yaw))) % 180 == 90:
			size = Vector3(size.z, size.y, size.x)
		_invisible_box(size, Vector3(pos.x, pos.y + size.y * 0.5, pos.z))
		GameState.minimap_rects.append(Rect2(pos.x - size.x * 0.5, pos.z - size.z * 0.5, size.x, size.z))
	return inst


func _invisible_box(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _tint(inst: Node3D, color: Color) -> void:
	for child in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_active_material(s)
			if mat is StandardMaterial3D:
				var dup: StandardMaterial3D = mat.duplicate()
				dup.albedo_color = color
				mi.set_surface_override_material(s, dup)


# --- actors ---------------------------------------------------------------

func _spawn_shards() -> void:
	for id in SHARD_POSITIONS.size():
		if id in GameState.collected_shards:
			continue
		var m := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.7, 1.0, 0.7)
		m.mesh = prism
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.35)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.75, 0.2)
		mat.emission_energy_multiplier = 2.5
		m.material_override = mat
		m.position = SHARD_POSITIONS[id]
		m.visible = false
		add_child(m)
		_shards[id] = m
		GameState.minimap_shards.append(SHARD_POSITIONS[id])


func _spawn_npcs() -> void:
	# The Watcher on the west sidewalk — ordinary, until the shards are found
	_watcher = preload("res://scripts/watcher.gd").new()
	_watcher.position = Vector3(-5.2, 0.2, -6)
	add_child(_watcher)
	_watcher.setup(_player)
	# The spirit over the alley — only there when you Discern, and it bites
	if not ("alley_spirit" in GameState.delivered_spirits):
		var spirit := preload("res://scripts/spirit.gd").new()
		spirit.position = Vector3(12, 1.6, 8)
		add_child(spirit)
		spirit.setup(_player, "alley_spirit")
		spirit.visible = false
		_hidden_nodes.append(spirit)


func _spawn_npc(path: String, pos: Vector3, yaw: float, anim: String) -> Node3D:
	var packed: PackedScene = load(path)
	if packed == null:
		return null
	var inst: Node3D = packed.instantiate()
	add_child(inst)
	var aabb := _combined_aabb(inst)
	var s := 1.8 / maxf(aabb.size.y, 0.01)
	inst.scale = Vector3.ONE * s
	inst.position = pos
	inst.rotation_degrees.y = yaw
	var players := inst.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var ap: AnimationPlayer = players[0]
		for n in ap.get_animation_list():
			ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if ap.has_animation(anim):
			ap.play(anim)
	return inst


func _spawn_player() -> void:
	var player_script := preload("res://scripts/player.gd")
	_player = player_script.new()
	_player.position = Vector3(0, 0.2, 18)
	add_child(_player)
	GameState.player = _player


func _build_camera() -> void:
	_cam_rig = Node3D.new()
	_cam_rig.position = _player.position + Vector3.UP * 1.7
	add_child(_cam_rig)
	var arm := SpringArm3D.new()
	arm.spring_length = 12.0
	arm.collision_mask = 1  # pull the camera in rather than clip through buildings
	arm.margin = 0.5
	arm.add_excluded_object(_player.get_rid())
	arm.rotation_degrees = Vector3(-50, 0, 0)
	_cam_rig.add_child(arm)
	var cam := Camera3D.new()
	cam.fov = 60.0
	arm.add_child(cam)
	cam.current = true


# --- discernment ----------------------------------------------------------

func _on_discern_changed(active: bool) -> void:
	for shard in _shards.values():
		shard.visible = active
	for node in _hidden_nodes:
		if is_instance_valid(node):
			node.visible = active
	_env.fog_enabled = active
	if active:
		_env.fog_light_color = Color(0.95, 0.78, 0.35)
		_env.fog_density = 0.010
		_env.ambient_light_energy = 1.5
	else:
		_env.ambient_light_energy = 1.0


# --- quest driver ---------------------------------------------------------

func _spawn_quest_objects() -> void:
	# Objective beacon
	_beam = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 26.0
	_beam.mesh = cyl
	var bmat := StandardMaterial3D.new()
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.albedo_color = Color(1.0, 0.85, 0.4, 0.38)
	_beam.material_override = bmat
	_beam.visible = false
	add_child(_beam)

	# The Book, in the alley wall cavity
	_book = MeshInstance3D.new()
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(0.5, 0.14, 0.36)
	_book.mesh = bmesh
	_book.position = Vector3(BOOK_POS.x, 0.9, BOOK_POS.z)
	_book.rotation_degrees = Vector3(12, 30, 0)
	var bookmat := StandardMaterial3D.new()
	bookmat.albedo_color = Color(0.45, 0.30, 0.15)
	bookmat.emission_enabled = true
	bookmat.emission = Color(1.0, 0.8, 0.3)
	bookmat.emission_energy_multiplier = 1.4
	_book.material_override = bookmat
	add_child(_book)

	# Safehouse steel door + lamp on the west row
	var door := MeshInstance3D.new()
	var dmesh := BoxMesh.new()
	dmesh.size = Vector3(0.2, 2.6, 1.5)
	door.mesh = dmesh
	door.position = Vector3(-4.0, 1.3, DOOR_POS.z)
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.25, 0.27, 0.30)
	dmat.metallic = 0.7
	dmat.roughness = 0.4
	door.material_override = dmat
	add_child(door)

	var lamp := MeshInstance3D.new()
	var lmesh := BoxMesh.new()
	lmesh.size = Vector3(0.16, 0.18, 0.6)
	lamp.mesh = lmesh
	lamp.position = Vector3(-3.95, 2.85, DOOR_POS.z)
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.3, 0.9, 0.95)
	lmat.emission_enabled = true
	lmat.emission = Color(0.2, 0.85, 0.95)
	lmat.emission_energy_multiplier = 2.0
	lamp.material_override = lmat
	add_child(lamp)


func _apply_stage(stage: int) -> void:
	match stage:
		1:
			_set_beam(STORE_POS, true)
		2:
			_set_beam(BOOK_POS, true)
		3:
			GameState.discernment_unlocked = true
			if is_instance_valid(_book):
				_book.queue_free()
			_set_beam(Vector3.ZERO, false)
		4:
			GameState.discernment_unlocked = true
			if is_instance_valid(_book):
				_book.queue_free()
			GameState.set_alert(true)
			if _watcher:
				_watcher.start_chase()
			_set_beam(DOOR_POS, true)
		5:
			GameState.discernment_unlocked = true
			if is_instance_valid(_book):
				_book.queue_free()
			GameState.set_alert(false)
			if _watcher:
				_watcher.stop_chase()
			_set_beam(Vector3.ZERO, false)
		_:
			_set_beam(Vector3.ZERO, false)


func _set_beam(pos: Vector3, on: bool) -> void:
	if _beam == null:
		return
	_beam.visible = on
	GameState.objective_pos = pos + Vector3(0, 1.5, 0) if on else Vector3.INF
	if on:
		_beam.position = pos + Vector3(0, 13, 0)


func _on_shards_progress(found: int, total: int) -> void:
	if found >= total and GameState.quest_stage == 3:
		_stage_card(4, "THE WATCHERS",
			"The last shard burns in your hand — and every head on the block turns toward you at once.\n\nAcross the street, the ordinary man lowers his phone. He was never ordinary.\n\nRUN.")


func _show_intro() -> void:
	_stage_card(1, INTRO_TITLE, INTRO_BODY)


func _stage_card(stage: int, title: String, body: String) -> void:
	GameState.set_stage(stage)
	_apply_stage(stage)
	if _shot:
		return
	_show_card(title, body)


func _show_card(title: String, body: String) -> void:
	_card = CARD_SCRIPT.new()
	add_child(_card)
	_card.open(title, body)


# --- screenshot mode ------------------------------------------------------

func _run_screenshot_script() -> void:
	_frames += 1
	if _shot_quest:
		match _frames:
			20:
				_show_intro()
			60:
				_capture("quest_card.png", false)
			70:
				if is_instance_valid(_card):
					_card.close()
			110:
				_capture("quest_beam.png", true)
		return
	match _frames:
		15:
			Input.action_press("move_right")
			Input.action_press("move_forward")
		60:
			_capture("block_run.png", false)
		75:
			Input.action_release("move_right")
			Input.action_release("move_forward")
			Input.action_press("discern")
		120:
			_capture("block_discern.png", false)
		150, 180, 210, 240, 270:
			Input.action_press("strike")
		153, 183, 213, 243, 273:
			Input.action_release("strike")
		215:
			_capture("combat_strike.png", false)
		300:
			_capture("combat_cast_out.png", true)


func _capture(file: String, then_quit: bool) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://docs/previews")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir + "/" + file)
	print("SHOT_SAVED " + file)
	if then_quit:
		get_tree().quit()


func _combined_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var xform := root.global_transform.affine_inverse() * mi.global_transform
		var aabb := xform * mi.get_aabb()
		if first:
			result = aabb
			first = false
		else:
			result = result.merge(aabb)
	return result
