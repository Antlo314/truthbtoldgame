extends CharacterBody3D
## A Watcher — an ordinary man until the Veil calls. Stares at you when
## you're close; once the chase starts, he hunts at just under your speed.

const MODEL := preload("res://assets/models/enemies/agent_businessman.glb")
const CHASE_SPEED := 4.6
const STARE_RANGE := 12.0
const TURN_SPEED := 8.0
const HEIGHT := 1.8

var chasing := false
var home := Vector3.ZERO

var _target: Node3D
var _anim: AnimationPlayer


func setup(target: Node3D) -> void:
	_target = target


func _ready() -> void:
	home = position

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
	visual.rotation_degrees.y = 180.0

	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0]
		for n in _anim.get_animation_list():
			_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_play("Idle")


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	var to_player := _target.global_position - global_position
	to_player.y = 0.0

	if chasing:
		var dir := to_player.normalized()
		velocity.x = dir.x * CHASE_SPEED
		velocity.z = dir.z * CHASE_SPEED
		_face(dir, delta)
		_play("Run")
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if to_player.length() < STARE_RANGE:
			_face(to_player.normalized(), delta)
		_play("Idle")

	move_and_slide()


func start_chase() -> void:
	chasing = true


func stop_chase() -> void:
	chasing = false
	velocity = Vector3.ZERO


func reset_home() -> void:
	position = home
	velocity = Vector3.ZERO


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	var yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, TURN_SPEED * delta)


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
