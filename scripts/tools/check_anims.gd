extends SceneTree
## Lists the animations baked into each character/enemy GLB.
## Run: godot --headless --path . --script res://scripts/tools/check_anims.gd

const PATHS := [
	"res://assets/models/characters/bro_truth_hoodie.glb",
	"res://assets/models/characters/woman_casual.glb",
	"res://assets/models/characters/woman_animated.glb",
	"res://assets/models/characters/robed_mystic.glb",
	"res://assets/models/enemies/agent_businessman.glb",
	"res://assets/models/enemies/agent_suit.glb",
	"res://assets/models/enemies/demon_gatekeeper.glb",
	"res://assets/models/enemies/demon_whisperer.glb",
	"res://assets/models/enemies/ghost_spirit.glb",
]


func _initialize() -> void:
	for path in PATHS:
		var packed: PackedScene = load(path)
		if packed == null:
			print(path.get_file(), ": LOAD FAILED")
			continue
		var inst := packed.instantiate()
		var players := inst.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			print(path.get_file(), ": no animations")
		else:
			var names := []
			for p in players:
				names.append_array((p as AnimationPlayer).get_animation_list())
			print(path.get_file(), ": ", ", ".join(names))
		inst.free()
	quit()
