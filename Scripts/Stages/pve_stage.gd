extends Node2D

const PAUSE_MENU := preload("res://Scenes/UI/PauseMenu.tscn")

@onready var camera: Camera2D = $Camera2D

var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var camera_offset: Vector2 = Vector2.ZERO
var camera_base: Vector2 = Vector2(0, 300)
var _pause_menu: Control


func _ready() -> void:
	SoundManager.start_bgm()
	camera.position = camera_base

	var hud: CanvasLayer = $GameHUD
	var p1: CharacterBody2D = $Player1
	var p2: CharacterBody2D = $Player2

	if PVEGlobal.player_character == "pim":
		p1.ai_controlled = true
		p1.ai_difficulty = PVEGlobal.difficulty
		p2.ai_controlled = false
	else:
		p1.ai_controlled = false
		p2.ai_controlled = true
		p2.ai_difficulty = PVEGlobal.difficulty

	# Human always uses WASD (P2 controls)
	var human: CharacterBody2D = p2 if p1.ai_controlled else p1
	human.action_left = "p2_move_left"
	human.action_right = "p2_move_right"
	human.action_down = "p2_move_down"
	human.action_jump = "p2_jump"
	human.action_attack = "p2_attack"

	p1.opponent = p2
	p2.opponent = p1

	if is_instance_valid(hud) and hud.has_method("setup"):
		hud.setup(p1, p2)

	_connect_player(p1)
	_connect_player(p2)

	_pause_menu = PAUSE_MENU.instantiate()
	add_child(_pause_menu)


func _connect_player(player: Node) -> void:
	if is_instance_valid(player) and player.has_signal("hit_received"):
		player.hit_received.connect(_on_player_hit)


func _on_player_hit() -> void:
	shake_intensity = 6.0


func _process(delta: float) -> void:
	# Pause
	if Input.is_action_just_pressed("pause") and is_instance_valid(_pause_menu):
		if _pause_menu.visible:
			_pause_menu.close()
		else:
			_pause_menu.open()

	# Screen shake
	if shake_intensity > 0.1:
		camera_offset.x = randf_range(-shake_intensity, shake_intensity)
		camera_offset.y = randf_range(-shake_intensity, shake_intensity)
		camera.position = camera_base + camera_offset
		shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta * 10.0)
	elif camera_offset != Vector2.ZERO:
		camera_offset = Vector2.ZERO
		camera.position = camera_base

	# Rematch
	if Input.is_action_just_pressed("rematch"):
		get_tree().paused = false
		get_tree().reload_current_scene()
