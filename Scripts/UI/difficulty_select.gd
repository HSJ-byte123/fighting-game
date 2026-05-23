extends Control


func _ready() -> void:
	$Panel/VBox/EasyBtn.pressed.connect(_on_easy)
	$Panel/VBox/MediumBtn.pressed.connect(_on_medium)
	$Panel/VBox/HardBtn.pressed.connect(_on_hard)
	$BackBtn.pressed.connect(_on_back)


func _on_easy() -> void:
	SoundManager.click_sound()
	PVEGlobal.difficulty = "easy"
	get_tree().change_scene_to_file("res://Scenes/Stages/PVEStage.tscn")


func _on_medium() -> void:
	SoundManager.click_sound()
	PVEGlobal.difficulty = "medium"
	get_tree().change_scene_to_file("res://Scenes/Stages/PVEStage.tscn")


func _on_hard() -> void:
	SoundManager.click_sound()
	PVEGlobal.difficulty = "hard"
	get_tree().change_scene_to_file("res://Scenes/Stages/PVEStage.tscn")


func _on_back() -> void:
	SoundManager.click_sound()
	get_tree().change_scene_to_file("res://Scenes/UI/CharacterSelect.tscn")
