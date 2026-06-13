extends Node
## Background music with a gentle crossfade between tracks. Keeps playing
## through pauses (so mini-games and story cards stay scored). CC0 loops from
## Kenney (see assets/CREDITS.md).

const VOLUME_DB := -14.0
const FADE := 1.4

var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _cur: AudioStreamPlayer
var _path := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_a = _make_player()
	_b = _make_player()
	_cur = _a


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.volume_db = -60.0
	add_child(p)
	return p


func play_track(path: String) -> void:
	if path == _path:
		return
	_path = path
	var stream = load(path)
	if stream == null:
		push_warning("Music missing: " + path)
		return
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	var nxt := _b if _cur == _a else _a
	nxt.stream = stream
	nxt.volume_db = -60.0
	nxt.play()
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(nxt, "volume_db", VOLUME_DB, FADE)
	t.tween_property(_cur, "volume_db", -60.0, FADE)
	_cur = nxt
