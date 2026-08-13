extends Node

const MUSIC_VOLUME_DB = -19.0
const MUSIC_SILENT_DB = -60.0
const MUSIC = {
	"city": preload("res://assets/audio/music/harbor.ogg"),
	"field": preload("res://assets/audio/music/wilds.ogg"),
	"dungeon": preload("res://assets/audio/music/dungeon.ogg"),
	"black_sail": preload("res://assets/audio/music/corsair.ogg"),
	"white_whale": preload("res://assets/audio/music/dungeon.ogg"),
	"legacy": preload("res://assets/audio/music/corsair.ogg"),
	"sea": preload("res://assets/audio/music/harbor.ogg"),
	"battle": preload("res://assets/audio/music/battle.ogg")
}
const SFX = {
	"ui": preload("res://assets/audio/sfx/ui.wav"),
	"interact": preload("res://assets/audio/sfx/interact.wav"),
	"step": preload("res://assets/audio/sfx/step.wav"),
	"battle_start": preload("res://assets/audio/sfx/battle_start.wav"),
	"attack": preload("res://assets/audio/sfx/attack.wav"),
	"hit": preload("res://assets/audio/sfx/hit.wav"),
	"skill": preload("res://assets/audio/sfx/skill.wav"),
	"victory": preload("res://assets/audio/sfx/victory.wav"),
	"defeat": preload("res://assets/audio/sfx/defeat.wav"),
	"reward": preload("res://assets/audio/sfx/reward.wav"),
	"heal": preload("res://assets/audio/sfx/heal.wav"),
	"sail": preload("res://assets/audio/sfx/sail.wav")
}
const SFX_VOLUME = {
	"ui": -17.0, "interact": -10.0, "step": -22.0,
	"battle_start": -8.0, "attack": -8.0, "hit": -9.0,
	"skill": -5.0, "victory": -5.0, "defeat": -7.0,
	"reward": -6.0, "heal": -8.0, "sail": -7.0
}
const SETTINGS_PATH = "user://audio_settings.cfg"

var enabled = true
var current_region = "city"
var current_track = ""
var battle_active = false
var music_players = []
var active_music_index = 0
var sfx_players = []
var next_sfx_index = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	for index in range(2):
		var player = AudioStreamPlayer.new()
		player.name = "Music%d" % (index + 1)
		player.volume_db = MUSIC_SILENT_DB
		add_child(player)
		music_players.append(player)
	for index in range(8):
		var player = AudioStreamPlayer.new()
		player.name = "Sfx%d" % (index + 1)
		add_child(player)
		sfx_players.append(player)
	_switch_music("city", false)

func set_region(region_id):
	current_region = str(region_id) if MUSIC.has(str(region_id)) else "city"
	if not battle_active:
		_switch_music(current_region)

func enter_battle():
	if battle_active:
		return
	battle_active = true
	play_sfx("battle_start")
	_switch_music("battle")

func end_battle(won, fled = false, resume_region = ""):
	if resume_region != "" and MUSIC.has(str(resume_region)):
		current_region = str(resume_region)
	battle_active = false
	if fled:
		play_sfx("ui")
	elif won:
		play_sfx("victory")
	else:
		play_sfx("defeat")
	_switch_music(current_region)

func play_sfx(effect_id):
	var key = str(effect_id)
	if not enabled or not SFX.has(key) or sfx_players.is_empty():
		return
	var selected = null
	for offset in range(sfx_players.size()):
		var candidate = sfx_players[(next_sfx_index + offset) % sfx_players.size()]
		if not candidate.playing:
			selected = candidate
			next_sfx_index = (next_sfx_index + offset + 1) % sfx_players.size()
			break
	if selected == null:
		selected = sfx_players[next_sfx_index]
		next_sfx_index = (next_sfx_index + 1) % sfx_players.size()
	selected.stream = SFX[key]
	selected.volume_db = float(SFX_VOLUME.get(key, -9.0))
	selected.pitch_scale = 0.97 + randf() * 0.06 if key in ["step", "attack", "hit"] else 1.0
	selected.play()

func toggle_audio():
	enabled = not enabled
	_apply_enabled_state()
	_save_settings()
	if enabled:
		play_sfx("interact")
	return enabled

func is_audio_enabled():
	return enabled

func _switch_music(track_id, crossfade = true):
	var key = str(track_id)
	if not MUSIC.has(key) or key == current_track or music_players.size() < 2:
		_apply_enabled_state()
		return
	current_track = key
	var outgoing = music_players[active_music_index]
	active_music_index = 1 - active_music_index
	var incoming = music_players[active_music_index]
	incoming.stop()
	incoming.stream = MUSIC[key]
	if incoming.stream is AudioStreamOggVorbis:
		incoming.stream.loop = true
	incoming.volume_db = MUSIC_SILENT_DB
	incoming.play()
	var target_volume = MUSIC_VOLUME_DB if enabled else MUSIC_SILENT_DB
	if not crossfade or not outgoing.playing:
		outgoing.stop()
		incoming.volume_db = target_volume
		return
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(outgoing, "volume_db", MUSIC_SILENT_DB, 0.8)
	tween.tween_property(incoming, "volume_db", target_volume, 0.8)
	tween.set_parallel(false)
	tween.tween_callback(func():
		if outgoing != music_players[active_music_index]:
			outgoing.stop()
	)

func _apply_enabled_state():
	if music_players.is_empty():
		return
	for index in range(music_players.size()):
		music_players[index].volume_db = MUSIC_VOLUME_DB if enabled and index == active_music_index else MUSIC_SILENT_DB
	if not enabled:
		for player in sfx_players:
			player.stop()

func _load_settings():
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		enabled = bool(config.get_value("audio", "enabled", true))

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "enabled", enabled)
	config.save(SETTINGS_PATH)
