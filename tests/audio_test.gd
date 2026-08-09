extends SceneTree

const MUSIC_PATHS = [
	"res://assets/audio/music/harbor.ogg",
	"res://assets/audio/music/wilds.ogg",
	"res://assets/audio/music/dungeon.ogg",
	"res://assets/audio/music/corsair.ogg",
	"res://assets/audio/music/battle.ogg"
]
const SFX_PATHS = [
	"res://assets/audio/sfx/ui.wav",
	"res://assets/audio/sfx/interact.wav",
	"res://assets/audio/sfx/step.wav",
	"res://assets/audio/sfx/battle_start.wav",
	"res://assets/audio/sfx/attack.wav",
	"res://assets/audio/sfx/hit.wav",
	"res://assets/audio/sfx/skill.wav",
	"res://assets/audio/sfx/victory.wav",
	"res://assets/audio/sfx/defeat.wav",
	"res://assets/audio/sfx/reward.wav",
	"res://assets/audio/sfx/heal.wav",
	"res://assets/audio/sfx/sail.wav"
]

var failures = []

func _init():
	call_deferred("_run")

func _run():
	var audio = root.get_node_or_null("AudioDirector")
	_check(audio != null, "AudioDirector 必须作为全局音频管理器加载")
	if audio == null:
		_finish()
		return

	var total_bytes = 0
	for path in MUSIC_PATHS + SFX_PATHS:
		var stream = load(path)
		_check(stream != null, "音频资源无法加载：%s" % path)
		var file = FileAccess.open(path, FileAccess.READ)
		if file != null:
			total_bytes += file.get_length()
	_check(total_bytes < 1024 * 1024, "音频源文件应小于1MB，当前%d字节" % total_bytes)

	audio.set_region("field")
	_check(audio.current_track == "field", "进入野外必须切换野外音乐")
	audio.enter_battle()
	_check(audio.battle_active and audio.current_track == "battle", "进入战斗必须切换战斗音乐")
	audio.end_battle(true, false, "field")
	_check(not audio.battle_active and audio.current_track == "field", "战斗结束必须恢复原地图音乐")

	var initial_enabled = audio.is_audio_enabled()
	audio.toggle_audio()
	_check(audio.is_audio_enabled() != initial_enabled, "静音开关必须生效")
	audio.toggle_audio()
	_check(audio.is_audio_enabled() == initial_enabled, "静音开关必须能恢复原设置")
	_finish(total_bytes)

func _check(condition, message):
	if not condition:
		failures.append(message)

func _finish(total_bytes = 0):
	if failures.is_empty():
		print("AUDIO_OK: 5套场景音乐、12类音效、战斗切换与静音设置全部通过（%d KB）" % int(total_bytes / 1024))
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
