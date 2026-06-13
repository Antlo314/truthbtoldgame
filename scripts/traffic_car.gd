extends Node3D
## A car driving the north-south street. Loops along a lane, wrapping from
## one end to the other. No physics — it's set dressing, so it just drives.

var model_path := "res://assets/models/cars/sedan.glb"
var lane_x := 2.7
var dir := 1.0          # +1 drives south (+z), -1 drives north (-z)
var speed := 7.0
var z_min := -34.0
var z_max := 34.0
var scale_factor := 1.76


func setup(model: String, x: float, direction: float, car_speed: float, start_z: float) -> void:
	model_path = model
	lane_x = x
	dir = direction
	speed = car_speed
	position = Vector3(x, 0, start_z)


func _ready() -> void:
	var inst: Node3D = (load(model_path) as PackedScene).instantiate()
	add_child(inst)
	inst.scale = Vector3.ONE * scale_factor
	# glTF cars face +Z; rotate so the nose points the way it drives.
	inst.rotation_degrees.y = 0.0 if dir > 0.0 else 180.0
	var aabb := _combined_aabb(inst)
	inst.position.y = -aabb.position.y * scale_factor


func _process(delta: float) -> void:
	position.z += dir * speed * delta
	if dir > 0.0 and position.z > z_max:
		position.z = z_min
	elif dir < 0.0 and position.z < z_min:
		position.z = z_max


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
