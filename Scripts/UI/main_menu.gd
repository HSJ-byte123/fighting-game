extends Control


func _ready() -> void:
	SoundManager.stop_bgm()
	$MainPanel/MainVBox/PVEButton.pressed.connect(_on_pve)
	$MainPanel/MainVBox/PVPButton.pressed.connect(_on_pvp)
	$MainPanel/MainVBox/SettingsButton.pressed.connect(_on_settings)
	$MainPanel/MainVBox/QuitButton.pressed.connect(_on_quit)

	$MainPanel/SettingsVBox/SettingsBackBtn.pressed.connect(_on_settings_back)

	$MainPanel/SettingsVBox/TimeRow/TimeSlider.value_changed.connect(_on_time_changed)
	$MainPanel/SettingsVBox/BGMVolRow/BGMVolSlider.value_changed.connect(_on_bgm_vol_changed)
	$MainPanel/SettingsVBox/SFXVolRow/SFXVolSlider.value_changed.connect(_on_sfx_vol_changed)

	_sync_sliders_from_settings()


func _on_pve() -> void:
	SoundManager.click_sound()
	get_tree().change_scene_to_file("res://Scenes/UI/CharacterSelect.tscn")


func _on_pvp() -> void:
	SoundManager.click_sound()
	get_tree().change_scene_to_file("res://Scenes/Stages/TestStage.tscn")


func _on_settings() -> void:
	SoundManager.click_sound()
	$MainPanel/MainVBox.hide()
	$MainPanel/SettingsVBox.show()


func _on_settings_back() -> void:
	SoundManager.click_sound()
	$MainPanel/SettingsVBox.hide()
	$MainPanel/MainVBox.show()


func _on_quit() -> void:
	get_tree().quit()


func _sync_sliders_from_settings() -> void:
	$MainPanel/SettingsVBox/TimeRow/TimeSlider.value = GameSettings.round_time
	$MainPanel/SettingsVBox/TimeRow/TimeValue.text = str(int(GameSettings.round_time))
	$MainPanel/SettingsVBox/BGMVolRow/BGMVolSlider.value = GameSettings.bgm_volume * 100.0
	$MainPanel/SettingsVBox/BGMVolRow/BGMVolValue.text = str(int(GameSettings.bgm_volume * 100.0))
	$MainPanel/SettingsVBox/SFXVolRow/SFXVolSlider.value = GameSettings.sfx_volume * 100.0
	$MainPanel/SettingsVBox/SFXVolRow/SFXVolValue.text = str(int(GameSettings.sfx_volume * 100.0))


func _on_time_changed(val: float) -> void:
	GameSettings.round_time = val
	$MainPanel/SettingsVBox/TimeRow/TimeValue.text = str(int(val))


func _on_bgm_vol_changed(val: float) -> void:
	GameSettings.bgm_volume = val / 100.0
	$MainPanel/SettingsVBox/BGMVolRow/BGMVolValue.text = str(int(val))
	SoundManager.apply_bgm_volume()


func _on_sfx_vol_changed(val: float) -> void:
	GameSettings.sfx_volume = val / 100.0
	$MainPanel/SettingsVBox/SFXVolRow/SFXVolValue.text = str(int(val))
