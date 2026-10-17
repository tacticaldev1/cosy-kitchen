## Sfx: plays the ASMR sounds (rendered from the web version's Web Audio synth into WAVs
## by tools/audio/render_audio.mjs). One-shots have a few random variations each.
## Buses: SFX, Ambience, Music — volumes come from Save.settings.
extends Node

const SFX_DIR := "res://assets/audio/sfx/"
const LOOP_DIR := "res://assets/audio/loops/"
const MUSIC_DIR := "res://assets/audio/music/"

var _sfx := {}      # name -> Array[AudioStream]
var _loops := {}    # name -> AudioStream
var _pool: Array[AudioStreamPlayer] = []
var _pi := 0
var _last := {}
var _amb: AudioStreamPlayer
var _music: AudioStreamPlayer
var _tracks: Array = []
var _track_i := 0

class LoopHandle:
	var player: AudioStreamPlayer
	var base_pitch := 1.0
	var kind := ""
	func set_param(v: float) -> void:
		if player and kind == "blender":
			player.pitch_scale = 0.8 + v * 0.55
	func stop() -> void:
		if player == null: return
		var p := player
		player = null
		var tw := p.create_tween()
		tw.tween_property(p, "volume_db", -40.0, 0.25)
		tw.tween_callback(p.queue_free)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in ["SFX", "Ambience", "Music"]:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	_scan()
	if Shot.arg("dev") != "":
		print("AUDIO sfx=%d loops=%d music=%d" % [_sfx.size(), _loops.size(), _tracks.size()])
	for i in 16:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_amb = AudioStreamPlayer.new()
	_amb.bus = "Ambience"
	add_child(_amb)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.finished.connect(_next_track)
	add_child(_music)
	apply_volumes()

func _scan() -> void:
	for dir in [SFX_DIR, LOOP_DIR, MUSIC_DIR]:
		var files := ResourceLoader.list_directory(dir) if ResourceLoader.has_method("list_directory") else DirAccess.get_files_at(dir)
		for f in files:
			var fn := String(f).trim_suffix(".import").trim_suffix(".remap")
			if not (fn.ends_with(".wav") or fn.ends_with(".ogg")): continue
			var res = load(dir + fn)
			if res == null: continue
			var base := fn.get_basename()
			if dir == SFX_DIR:
				var nm := base
				var us := base.rfind("_")
				if us > 0 and base.substr(us + 1).is_valid_int(): nm = base.substr(0, us)
				if not _sfx.has(nm): _sfx[nm] = []
				if not _sfx[nm].has(res): _sfx[nm].append(res)
			elif dir == LOOP_DIR:
				_loops[base] = res
			else:
				if not _tracks.has(res): _tracks.append(res)

func has(name: String) -> bool: return _sfx.has(name)

## intensity scales volume (0..1)
func play(name: String, intensity := 1.0, pitch := 1.0) -> void:
	var list: Array = _sfx.get(name, [])
	if list.is_empty(): return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(name, -1000)) < 25: return
	_last[name] = now
	var p := _pool[_pi]
	_pi = (_pi + 1) % _pool.size()
	p.stream = list[randi() % list.size()]
	p.volume_db = linear_to_db(clampf(intensity, 0.05, 1.5))
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()

func loop(name: String) -> LoopHandle:
	var h := LoopHandle.new()
	h.kind = name
	if not _loops.has(name): return h
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = _loops[name]
	p.volume_db = -40.0
	add_child(p)
	p.play()
	p.create_tween().tween_property(p, "volume_db", 0.0, 0.1)
	h.player = p
	return h

func set_ambience(on: bool) -> void:
	if not _loops.has("rain"): return
	if on and not _amb.playing:
		_amb.stream = _loops["rain"]
		_amb.volume_db = -40.0
		_amb.play()
		_amb.create_tween().tween_property(_amb, "volume_db", 0.0, 1.2)
	elif not on and _amb.playing:
		var tw := _amb.create_tween()
		tw.tween_property(_amb, "volume_db", -40.0, 0.8)
		tw.tween_callback(_amb.stop)

func start_music() -> void:
	if _tracks.is_empty() or _music.playing: return
	_track_i = randi() % _tracks.size()
	_music.stream = _tracks[_track_i]
	_music.play()

func _next_track() -> void:
	if _tracks.is_empty(): return
	_track_i = (_track_i + 1) % _tracks.size()
	_music.stream = _tracks[_track_i]
	_music.play()

func apply_volumes() -> void:
	var s: Dictionary = Save.settings if Save and "settings" in Save else {}
	_bus("SFX", s.get("sfx", 0.9))
	_bus("Ambience", s.get("amb", 0.6))
	_bus("Music", s.get("music", 0.45))
	_bus("Master", s.get("master", 1.0))

func _bus(n: String, v: float) -> void:
	var i := AudioServer.get_bus_index(n)
	if i < 0: return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(i, v <= 0.001)
