extends SceneTree
## Prints the raw AABB of key kit pieces so layout constants can be sane.
## Run: godot --headless --path . --script res://scripts/tools/measure_kits.gd

const PATHS := [
	"res://assets/models/roads/road-straight.glb",
	"res://assets/models/roads/road-crossing.glb",
	"res://assets/models/city/building-a.glb",
	"res://assets/models/city/building-skyscraper-a.glb",
	"res://assets/models/cars/sedan.glb",
	"res://assets/models/roads/light-curved.glb",
	"res://assets/models/characters/bro_truth_hoodie.glb",
]


func _initialize() -> void:
	for path in PATHS:
		var packed: PackedScene = load(path)
		if packed == null:
			print(path.get_file(), ": LOAD FAILED")
			continue
		var inst: Node3D = packed.instantiate()
		root.add_child(inst)
		var aabb := _combined_aabb(inst)
		print("%s: pos=%v size=%v" % [path.get_file(), aabb.position, aabb.size])
		inst.free()
	quit()


func _combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var xform := node.global_transform.affine_inverse() * mi.global_transform
		var aabb := xform * mi.get_aabb()
		if first:
			result = aabb
			first = false
		else:
			result = result.merge(aabb)
	return result
