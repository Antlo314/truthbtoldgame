extends Node3D
## The first Jasher Jump — Enoch's trial. A path of light across the heavens
## before the flood. The lamp never runs dry here; the veil gates open only
## while Discerning. At the far end: the Walking With God Gift.
## This scene is the template every later chapter (Abraham, Joseph, Moses)
## reuses: enter → one trial mechanic → one Gift → return.
##
## Screenshot mode:
##   godot --path . res://scenes/enoch_trial.tscn ++ --screenshot-trial

const PATH_WIDTH := 4.0
const GATE_Z: Array[float] = [-22.0, -46.0, -70.0]
const SUMMIT_Z := -86.0
const CARD_SCRIPT := preload("res://scripts/ui/story_card.gd")

var _player: CharacterBody3D
var _cam_rig: Node3D
var _gate_cols: Array[CollisionShape3D] = []
var _gate_mats: Array[StandardMaterial3D] = []
var _checkpoint := Vector3(0, 0.2, 2)
var _done := false
var _shot := false
var _frames := 0


func _ready() -> void:
	_shot = OS.get_cmdline_user_args().has("--screenshot-trial")
	GameState.oil_locked = true
	GameState.discernment_unlocked = true  # always true by the time you're here
	GameState.minimap_rects.clear()
	GameState.minimap_shards.clear()
	GameState.minimap_road = Rect2()
	GameState.minimap_world = Rect2(-20, -96, 40, 106)
	GameState.study_point = Vector3(0, 0, -999)  # off-map
	_build_world()
	_spawn_player()
	_build_camera()
	add_child(preload("res://scripts/ui/hud.gd").new())
	GameState.discern_changed.connect(_on_discern_changed)
	_on_discern_changed(GameState.discerning)
	GameState.objective_pos = Vector3(0, 1.5, SUMMIT_Z - 4)
	GameState.flash_message("The lamp never runs dry here. Hold DISCERN to pass the veils — walk with God.")


func _process(delta: float) -> void:
	if _player == null:
		return
	_cam_rig.position = _cam_rig.position.lerp(_player.position + Vector3.UP * 1.7, minf(1.0, 8.0 * delta))
	if _shot:
		_run_shot()


func _physics_process(_delta: float) -> void:
	if _player == null or _done:
		return
	for z in GATE_Z:
		if _player.position.z < z - 1.5 and _checkpoint.z > z:
			_checkpoint = Vector3(0, 0.2, z - 2.5)
	if _player.position.y < -10.0:
		_player.position = _checkpoint
		_player.velocity = Vector3.ZERO
		GameState.flash_message("The path holds those who keep walking.")
	if _player.position.z < SUMMIT_Z and absf(_player.position.x) < 6.0:
		_complete()


# --- world ------------------------------------------------------------------

func _build_world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 140, 0)
	sun.light_energy = 0.7
	add_child(sun)

	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.04, 0.06, 0.18)
	sky_mat.sky_horizon_color = Color(0.45, 0.32, 0.55)
	sky_mat.ground_bottom_color = Color(0.02, 0.03, 0.10)
	sky_mat.ground_horizon_color = Color(0.30, 0.22, 0.42)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# The pre-flood sea, far below
	var sea := MeshInstance3D.new()
	var sea_mesh := BoxMesh.new()
	sea_mesh.size = Vector3(400, 1, 400)
	sea.mesh = sea_mesh
	sea.position = Vector3(0, -34, -40)
	var sea_mat := StandardMaterial3D.new()
	sea_mat.albedo_color = Color(0.05, 0.10, 0.22)
	sea_mat.emission_enabled = true
	sea_mat.emission = Color(0.03, 0.08, 0.18)
	sea_mat.emission_energy_multiplier = 0.4
	sea.material_override = sea_mat
	add_child(sea)

	# The path of light
	_path_box(Vector3(10, 1, 10), Vector3(0, -0.5, 0))
	_path_box(Vector3(PATH_WIDTH, 1, 88), Vector3(0, -0.5, -49))
	_path_box(Vector3(12, 1, 12), Vector3(0, -0.5, SUMMIT_Z - 4))

	for z in GATE_Z:
		_make_gate(z)

	# Stars strewn around the walk
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 30:
		var star := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rng.randf_range(0.10, 0.30)
		sphere.height = sphere.radius * 2.0
		star.mesh = sphere
		var sx := rng.randf_range(4.0, 18.0) * (1.0 if rng.randf() > 0.5 else -1.0)
		star.position = Vector3(sx, rng.randf_range(1.0, 14.0), rng.randf_range(-94.0, -2.0))
		var smat := StandardMaterial3D.new()
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smat.albedo_color = Color(1.0, 0.97, 0.88)
		smat.emission_enabled = true
		smat.emission = Color(1.0, 0.95, 0.8)
		smat.emission_energy_multiplier = 2.0
		star.material_override = smat
		add_child(star)

	# The Presence on the horizon
	var presence := MeshInstance3D.new()
	var pm := SphereMesh.new()
	pm.radius = 14.0
	pm.height = 28.0
	presence.mesh = pm
	presence.position = Vector3(0, 4, -140)
	var pmat := StandardMaterial3D.new()
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pmat.albedo_color = Color(1.0, 0.92, 0.7)
	pmat.emission_enabled = true
	pmat.emission = Color(1.0, 0.9, 0.6)
	pmat.emission_energy_multiplier = 2.4
	presence.material_override = pmat
	add_child(presence)

	# The column of light at the summit
	var column := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.4
	cm.bottom_radius = 1.4
	cm.height = 50.0
	column.mesh = cm
	column.position = Vector3(0, 25, SUMMIT_Z - 4)
	var cmat := StandardMaterial3D.new()
	cmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cmat.albedo_color = Color(1.0, 0.95, 0.75, 0.45)
	column.material_override = cmat
	add_child(column)


func _path_box(size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var mesh_i := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_i.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.88, 0.78)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.55)
	mat.emission_energy_multiplier = 0.55
	mesh_i.material_override = mat
	body.add_child(mesh_i)
	add_child(body)
	GameState.minimap_rects.append(Rect2(pos.x - size.x * 0.5, pos.z - size.z * 0.5, size.x, size.z))


func _make_gate(z: float) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(0, 1.7, z)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(PATH_WIDTH + 0.2, 3.4, 0.5)
	col.shape = shape
	body.add_child(col)
	var mesh_i := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(PATH_WIDTH + 0.2, 3.4, 0.5)
	mesh_i.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.45, 0.20, 0.60, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.2, 0.7)
	mat.emission_energy_multiplier = 1.2
	mesh_i.material_override = mat
	body.add_child(mesh_i)
	add_child(body)
	_gate_cols.append(col)
	_gate_mats.append(mat)


func _on_discern_changed(active: bool) -> void:
	for col in _gate_cols:
		col.disabled = active
	for mat in _gate_mats:
		mat.albedo_color.a = 0.15 if active else 0.55


# --- actors -----------------------------------------------------------------

func _spawn_player() -> void:
	var player_script := preload("res://scripts/player.gd")
	_player = player_script.new()
	_player.model_path = "res://assets/models/characters/robed_mystic.glb"
	_player.position = Vector3(0, 0.2, 2)
	add_child(_player)
	GameState.player = _player


func _build_camera() -> void:
	_cam_rig = Node3D.new()
	_cam_rig.position = _player.position + Vector3.UP * 1.7
	add_child(_cam_rig)
	var arm := SpringArm3D.new()
	arm.spring_length = 12.0
	arm.collision_mask = 0
	arm.rotation_degrees = Vector3(-50, 0, 0)
	_cam_rig.add_child(arm)
	var cam := Camera3D.new()
	cam.fov = 60.0
	arm.add_child(cam)
	cam.current = true


# --- completion -------------------------------------------------------------

func _complete() -> void:
	_done = true
	GameState.grant_gift("walking_with_god")
	GameState.objective_pos = Vector3.INF
	if _shot:
		return
	var card := CARD_SCRIPT.new()
	add_child(card)
	card.open("WALKING WITH GOD",
		"Enoch walked three hundred years with God — and was not, for God took him.\n\nThe heavens fold around you like a page turning.\n\n— GIFT RECEIVED: WALKING WITH GOD —\nIn the waking world, you can now pass through veil barriers while Discerning.")
	card.closed.connect(_return_home, CONNECT_ONE_SHOT)


func _return_home() -> void:
	GameState.set_stage(6)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


# --- screenshot mode --------------------------------------------------------

func _run_shot() -> void:
	_frames += 1
	match _frames:
		15:
			Input.action_press("move_forward")
		80:
			Input.action_press("discern")
		150:
			_capture("trial_path.png", false)
		235:
			_capture("trial_gate.png", false)
		600:
			_capture("trial_mid.png", false)
		905:
			_capture("trial_summit.png", true)


func _capture(file: String, then_quit: bool) -> void:
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://docs/previews")
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir + "/" + file)
	print("SHOT_SAVED " + file)
	if then_quit:
		get_tree().quit()
