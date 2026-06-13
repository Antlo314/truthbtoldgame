extends Node3D
## A Principality — a spirit only visible (and strikeable) while Discerning.
## It phases through the world, drains your Oil on touch, and is cast out
## after three strikes. If it drains your lamp dry, Discernment collapses
## and it vanishes from sight.

signal delivered

const MODEL := preload("res://assets/models/enemies/ghost_spirit.glb")
const FLY_SPEED := 4.0
const RETURN_SPEED := 1.6
const AGGRO_RANGE := 11.0
const TOUCH_RANGE := 1.4
const OIL_TOUCH_DRAIN := 26.0  # per second while touching

var id := "spirit"
var hp := 3
var home := Vector3.ZERO
var dead := false

var _target: Node3D
var _anim: AnimationPlayer
var _hit_cd := 0.0
var _bob := 0.0


func setup(target: Node3D, spirit_id: String) -> void:
	_target = target
	id = spirit_id


func _ready() -> void:
	add_to_group("spirits")
	home = position
	var visual: Node3D = MODEL.instantiate()
	add_child(visual)
	var aabb := _combined_aabb(visual)
	var s := 1.5 / maxf(aabb.size.y, 0.01)
	visual.scale = Vector3.ONE * s
	visual.position.y = -aabb.position.y * s - 0.75  # center on the hover point
	visual.rotation_degrees.y = 180.0
	var players := visual.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		_anim = players[0]
		for n in _anim.get_animation_list():
			if n.contains("Flying"):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_play("Flying_Idle")


func _process(delta: float) -> void:
	if dead or _target == null:
		return
	_hit_cd = maxf(_hit_cd - delta, 0.0)
	_bob += delta
	var chest: Vector3 = _target.global_position + Vector3(0, 1.2, 0)
	var to_player := chest - global_position
	var dist := to_player.length()
	if GameState.discerning and dist < AGGRO_RANGE:
		if dist > TOUCH_RANGE * 0.8:
			global_position += to_player.normalized() * FLY_SPEED * delta
		if dist < TOUCH_RANGE:
			GameState.drain_oil(OIL_TOUCH_DRAIN * delta)
			_play("Headbutt")
		else:
			_play("Fast_Flying")
		_face(to_player)
	else:
		var to_home := (home + Vector3(0, sin(_bob * 2.0) * 0.25, 0)) - global_position
		if to_home.length() > 0.1:
			global_position += to_home.limit_length(RETURN_SPEED * delta)
		_play("Flying_Idle")


func take_hit(dir: Vector3) -> void:
	if dead or _hit_cd > 0.0:
		return
	_hit_cd = 0.45
	hp -= 1
	global_position += dir * 1.4 + Vector3(0, 0.2, 0)
	Sfx.play("hit")
	if hp <= 0:
		_die()
	else:
		_force_play("HitReact")


func _die() -> void:
	dead = true
	_force_play("Death")
	GameState.deliver_spirit(id)
	delivered.emit()
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(self, "scale", Vector3.ONE * 0.05, 0.8)
	tw.tween_callback(queue_free)


func _face(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() < 0.01:
		return
	rotation.y = atan2(-dir.x, -dir.z)


func _play(name: String) -> void:
	if _anim == null:
		return
	var full := "CharacterArmature|" + name
	if _anim.has_animation(full) and _anim.current_animation != full:
		_anim.play(full, 0.2)


func _force_play(name: String) -> void:
	if _anim == null:
		return
	var full := "CharacterArmature|" + name
	if _anim.has_animation(full):
		_anim.play(full, 0.1)


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
