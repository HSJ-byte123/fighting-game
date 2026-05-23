extends Node

const SFX_PATH := "res://Audio/"
const BGM_PATH := "res://Audio/Backgorund/bgm_loop.wav"
const POOL_SIZE := 8

var _bgm_player: AudioStreamPlayer
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0

# Beep fallback
var _generator: AudioStreamGenerator
var _gen_playback: AudioStreamGeneratorPlayback
var _gen_player: AudioStreamPlayer
var _sample_rate: int = 44100


func _ready() -> void:
	for _i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = _sample_rate
	_generator.buffer_length = 0.2
	_gen_player = AudioStreamPlayer.new()
	_gen_player.stream = _generator
	add_child(_gen_player)
	_gen_player.play()
	_gen_playback = _gen_player.get_stream_playback()

func start_bgm() -> void:
	if is_instance_valid(_bgm_player) and _bgm_player.playing:
		return
	var stream: AudioStream = load(BGM_PATH)
	if stream == null:
		return
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.stream = stream
	_bgm_player.volume_db = linear_to_db(GameSettings.bgm_volume) if GameSettings.bgm_volume > 0.0 else -80.0
	add_child(_bgm_player)
	_bgm_player.play()


func apply_bgm_volume() -> void:
	if is_instance_valid(_bgm_player):
		_bgm_player.volume_db = linear_to_db(GameSettings.bgm_volume) if GameSettings.bgm_volume > 0.0 else -80.0


func stop_bgm() -> void:
	if is_instance_valid(_bgm_player):
		_bgm_player.stop()


func click_sound() -> void:
	_play_beep(800.0, 0.04, 0.2)


func _play(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % POOL_SIZE
	player.stream = stream
	player.volume_db = linear_to_db(GameSettings.sfx_volume) if GameSettings.sfx_volume > 0.0 else -80.0
	player.play()


func _play_beep(frequency: float, duration: float, volume: float = 0.3) -> void:
	if not is_instance_valid(_gen_playback):
		return
	var samples: int = int(_sample_rate * duration)
	var available: int = _gen_playback.get_frames_available()
	var frames: int = min(samples, available)
	for i: int in frames:
		var t: float = float(i) / float(_sample_rate)
		var envelope: float = 1.0 - (float(i) / float(samples))
		var sample: float = sin(2.0 * PI * frequency * t) * envelope * volume * GameSettings.sfx_volume
		_gen_playback.push_frame(Vector2(sample, sample))


func jump_sound() -> void:
	_play_beep(330.0, 0.05, 0.2)


func attack_sound(is_player1: bool = true) -> void:
	var prefix := "Xi" if is_player1 else "Pim"
	_play(SFX_PATH + prefix + "/" + ("xi_attack.wav" if is_player1 else "pim_attack.wav"))


func hit_sound(is_player1: bool = true) -> void:
	var prefix := "Xi" if is_player1 else "Pim"
	_play(SFX_PATH + prefix + "/" + ("xi_hit.wav" if is_player1 else "pim_hit.wav"))


func ko_sound(loser_is_player1: bool = true) -> void:
	var prefix := "Xi" if loser_is_player1 else "Pim"
	_play(SFX_PATH + prefix + "/" + ("xi_ko.wav" if loser_is_player1 else "pim_ko.wav"))
