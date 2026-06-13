extends CharacterBody3D
## Bro Truth — present-day controller. Animated Quaternius Hoodie Character
## with Idle/Walk/Run blending driven by movement speed.

const MODEL := preload("res://assets/models/characters/bro_truth_hoodie.glb")
const SPEED := 6.0
const ACCEL := 24.0
const TURN_SPEED := 12.0
const HEIGHT := 1.7

var _anim: AnimationPlayer


func _ready() -> void:
	var col := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = HEIGHT
	col.shape = capsule
	col.position.y = HEIGHT * 0.5
	add_child(col)

	var visual: Node3D = MODEL.instantiate()
	add_child(visual)
	var aabb := _combined_aabb(visual)
	var s := HEIGHT / maxf(aabb.size.y, 0.01)
	visual.scale = Vector3.ONE * s
	visual.position.y = -aabb.position.y * s
	visual.rotation_degrees.y = 180.0  # glTF models face +Z; Godot forward is -Z

	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0]
		for n in _anim.get_animation_list():
			_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_play("Idle_Neutral")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input == Vector2.ZERO:
		input = GameState.touch_move
	var dir := Vector3(input.x, 0.0, input.y)
	if dir.length() > 1.0:
		dir = dir.normalized()

	var target := dir * SPEED
	velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
	velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)

	if dir.length() > 0.1:
		var yaw := atan2(-dir.x, -dir.z)
		rotation.y = lerp_angle(rotation.y, yaw, TURN_SPEED * delta)

	move_and_slide()

	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 4.0:
		_play("Run")
	elif speed > 0.4:
		_play("Walk")
	else:
		_play("Idle_Neutral")


func _play(name: String) -> void:
	if _anim == null:
		return
	var full := "CharacterArmature|" + name
	if _anim.has_animation(full) and _anim.current_animation != full:
		_anim.play(full, 0.2)


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
