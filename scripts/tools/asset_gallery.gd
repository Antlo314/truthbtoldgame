extends Node3D
## Renders a labeled contact sheet of the chosen asset picks to
## docs/previews/asset_gallery.png, then quits. Run with:
##   godot --path . --resolution 1600x1000 res://scenes/asset_gallery.tscn

const CELL_W := 3.0
const ROW_H := 3.4
const TARGET_SIZE := 2.0

# Rows of [label, path], top row first.
const ROWS := [
	[
		["BRO TRUTH (placeholder)", "res://assets/models/characters/bro_truth_hoodie.glb"],
		["SISTER LOLA (placeholder)", "res://assets/models/characters/woman_casual.glb"],
		["LALA / CHRISTINA (placeholder)", "res://assets/models/characters/woman_animated.glb"],
		["ANCIENT ERA ROBES", "res://assets/models/characters/robed_mystic.glb"],
	],
	[
		["VEIL AGENT A", "res://assets/models/enemies/agent_businessman.glb"],
		["VEIL AGENT B", "res://assets/models/enemies/agent_suit.glb"],
		["GATEKEEPER (demon)", "res://assets/models/enemies/demon_gatekeeper.glb"],
		["WHISPERER (demon)", "res://assets/models/enemies/demon_whisperer.glb"],
		["SPIRIT", "res://assets/models/enemies/ghost_spirit.glb"],
	],
	[
		["BRICK SHOP A", "res://assets/models/city/building-a.glb"],
		["BRICK SHOP C", "res://assets/models/city/building-c.glb"],
		["CORNER STORE G", "res://assets/models/city/building-g.glb"],
		["BUILDING K", "res://assets/models/city/building-k.glb"],
		["SKYSCRAPER A", "res://assets/models/city/building-skyscraper-a.glb"],
	],
	[
		["ROAD STRAIGHT", "res://assets/models/roads/road-straight.glb"],
		["CROSSROAD", "res://assets/models/roads/road-crossroad-line.glb"],
		["CROSSWALK", "res://assets/models/roads/road-crossing.glb"],
		["STREETLIGHT", "res://assets/models/roads/light-curved.glb"],
		["HIGHWAY SIGN", "res://assets/models/roads/sign-highway.glb"],
	],
	[
		["SEDAN", "res://assets/models/cars/sedan.glb"],
		["TAXI", "res://assets/models/cars/taxi.glb"],
		["POLICE", "res://assets/models/cars/police.glb"],
		["VAN", "res://assets/models/cars/van.glb"],
		["SUV", "res://assets/models/cars/suv.glb"],
	],
]


func _ready() -> void:
	_build_stage()
	var row_count := ROWS.size()
	for r in row_count:
		var row: Array = ROWS[r]
		var y := (row_count - 1 - r) * ROW_H
		var x0 := -(row.size() - 1) * CELL_W * 0.5
		for c in row.size():
			_place_item(row[c][0], row[c][1], Vector3(x0 + c * CELL_W, y, 0.0))
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var dir := ProjectSettings.globalize_path("res://docs/previews")
	DirAccess.make_dir_recursive_absolute(dir)
	var img := get_viewport().get_texture().get_image()
	img.save_png(dir + "/asset_gallery.png")
	print("GALLERY_SAVED " + dir + "/asset_gallery.png")
	get_tree().quit()


func _build_stage() -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 19.5
	cam.position = Vector3(0, 6.4, 25)
	add_child(cam)
	cam.current = true

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -25, 0)
	sun.light_energy = 1.2
	add_child(sun)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _place_item(label: String, path: String, pos: Vector3) -> void:
	var wrapper := Node3D.new()
	wrapper.position = pos
	add_child(wrapper)

	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("Missing: " + path)
	else:
		var inst: Node3D = packed.instantiate()
		wrapper.add_child(inst)
		var aabb := _combined_aabb(inst)
		var max_dim := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		if max_dim <= 0.0:
			max_dim = 1.0
		var s := TARGET_SIZE / max_dim
		inst.scale = Vector3.ONE * s
		var center := aabb.get_center()
		inst.position = Vector3(-center.x * s, -aabb.position.y * s, -center.z * s)
		if aabb.size.y < 0.25 * max_dim:
			wrapper.rotation_degrees.x = 55.0  # tilt flat tiles toward the camera

	var name_label := Label3D.new()
	name_label.text = label
	name_label.font_size = 44
	name_label.position = pos + Vector3(0, -0.55, 1.5)
	add_child(name_label)

	var file_label := Label3D.new()
	file_label.text = path.get_file()
	file_label.font_size = 26
	file_label.modulate = Color(0.7, 0.75, 0.8)
	file_label.position = pos + Vector3(0, -0.95, 1.5)
	add_child(file_label)


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
