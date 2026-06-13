extends Node
## One-shot SFX pool. CC0 sounds from Kenney (see assets/CREDITS.md).
## Runs in PROCESS_MODE_ALWAYS so card sounds play while the tree is paused.

const SOUNDS := {
	"shard": "res://assets/audio/confirmation_001.ogg",
	"paper": "res://assets/audio/confirmation_002.ogg",
	"discern_on": "res://assets/audio/bong_001.ogg",
	"discern_off": "res://assets/audio/close_002.ogg",
	"swing": "res://assets/audio/impactGeneric_light_001.ogg",
	"hit": "res://assets/audio/impactPunch_medium_000.ogg",
	"cast_out": "res://assets/audio/impactBell_heavy_000.ogg",
	"card_open": "res://assets/audio/click_002.ogg",
	"card_close": "res://assets/audio/click_004.ogg",
	"error": "res://assets/audio/error_004.ogg",
	"catch": "res://assets/audio/glitch_002.ogg",
}
const POOL_SIZE := 8

var _streams := {}
var _pool: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for key in SOUNDS:
		var stream := load(SOUNDS[key])
		if stream:
			_streams[key] = stream
		else:
			push_warning("Sfx missing: " + str(SOUNDS[key]))
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_pool.append(p)


func play(key: String, pitch_jitter := 0.06) -> void:
	if not _streams.has(key):
		return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = _streams[key]
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()
