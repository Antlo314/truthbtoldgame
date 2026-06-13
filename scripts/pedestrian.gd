extends CharacterBody3D
## A sidewalk pedestrian — walks a two-point route, oblivious to the truth.
## The sleeping world keeps strolling no matter what you Discern.

const TURN_SPEED := 6.0

var model_path := "res://assets/models/characters/woman_casual.glb"
var point_a := Vector3.ZERO
var point_b := Vector3.ZERO
var speed := 1.9

var _target := Vector3.ZERO
var _anim: AnimationPlayer


func setup(model: String, a: Vector3, b: Vector3, walk_speed: float) -> void:
	model_path = model
	point_a = a
	point_b = b
	speed = walk_speed


func _ready() -> void:
	position = point_a
	_target = point_b
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position.y = 0.85
	add_child(col)

	var visual: Node3D = (load(model_path) as PackedScene).instantiate()
	add_child(visual)
	var aabb := _combined_aabb(visual)
	var s := 1.7 / maxf(aabb.size.y, 0.01)
	visual.scale = Vector3.ONE * s
	visual.position.y = -aabb.position.y * s
	visual.rotation_degrees.y = 180.0

	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0]
		# Animation prefixes differ between rigs (HumanArmature|Female_Walk vs
		# CharacterArmature|Walk) — match by suffix.
		for n in _anim.get_animation_list():
			if n.ends_with("Walk"):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
				_anim.play(n)
				break


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var to_target := _target - position
	to_target.y = 0.0
	if to_target.length() < 0.6:
		_target = point_a if _target.is_equal_approx(point_b) else point_b
		to_target = _target - position
		to_target.y = 0.0
	var dir := to_target.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), TURN_SPEED * delta)
	move_and_slide()


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
