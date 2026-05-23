extends Control

var selected_character: String = ""


func _ready() -> void:
	var xi_frames: SpriteFrames = load("res://Assets/Characters/Animations/xi_sprite_frames.tres")
	if xi_frames and xi_frames.has_animation("idle") and xi_frames.get_frame_count("idle") > 0:
		$Cards/XICard/XITexture.texture = xi_frames.get_frame_texture("idle", 0)

	var pim_frames: SpriteFrames = load("res://Assets/Characters/Animations/pim_sprite_frames.tres")
	if pim_frames and pim_frames.has_animation("idle") and pim_frames.get_frame_count("idle") > 0:
		$Cards/PIMCard/PIMTexture.texture = pim_frames.get_frame_texture("idle", 0)

	$Cards/XICard/XISelectBtn.pressed.connect(_on_xi_selected)
	$Cards/PIMCard/PIMSelectBtn.pressed.connect(_on_pim_selected)
	$BackBtn.pressed.connect(_on_back)


func _on_xi_selected() -> void:
	SoundManager.click_sound()
	PVEGlobal.player_character = "xi"
	get_tree().change_scene_to_file("res://Scenes/UI/DifficultySelect.tscn")


func _on_pim_selected() -> void:
	SoundManager.click_sound()
	PVEGlobal.player_character = "pim"
	get_tree().change_scene_to_file("res://Scenes/UI/DifficultySelect.tscn")


func _on_back() -> void:
	SoundManager.click_sound()
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
