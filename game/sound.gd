@static_unload
class_name VigilSound
extends RefCounted
## A game sound bank, using the existing AudioManager player (no new audio service).
static var bank: Dictionary = {}
static var poly: AudioStreamPolyphonic

static func play(cue: String) -> void:
	var audio = (Engine.get_main_loop() as SceneTree).root.get_node("AudioManager")
	if not bank.has(cue):
		bank[cue] = load("res://game/audio/" + cue + ".wav")
	if poly == null:
		poly = AudioStreamPolyphonic.new()
		poly.polyphony = 12
	if audio.player.stream != poly or not audio.player.playing:
		audio.player.stream = poly
		audio.player.play()
	var playback = audio.player.get_stream_playback()
	if playback is AudioStreamPlaybackPolyphonic:
		playback.play_stream(bank[cue], -5.0)

static func music() -> void:
	var audio = (Engine.get_main_loop() as SceneTree).root.get_node("AudioManager")
	var stream = load("res://game/audio/vigil.wav") as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	audio.bgm_player.volume_db = -14
	audio.play_bgm(stream)

static func stop_all() -> void:
	var audio = (Engine.get_main_loop() as SceneTree).root.get_node("AudioManager")
	audio.player.stop()
	audio.stop_bgm()
	audio.player.stream = null
	audio.bgm_player.stream = null
	bank.clear()
	poly = null
