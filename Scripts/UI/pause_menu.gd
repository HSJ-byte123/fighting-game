extends Control


func _ready() -> void:
	$Panel/MainVBox/ContinueBtn.pressed.connect(_on_continue)
	$Panel/MainVBox/RestartBtn.pressed.connect(_on_restart)
	$Panel/MainVBox/SettingsBtn.pressed.connect(_on_settings)
	$Panel/MainVBox/QuitBtn.pressed.connect(_on_quit)

	$Panel/SettingsVBox/SettingsBackBtn.pressed.connect(_on_settings_back)

	$Panel/SettingsVBox/BGMVolRow/BGMVolSlider.value_changed.connect(_on_bgm_vol_changed)
	$Panel/SettingsVBox/SFXVolRow/SFXVolSlider.value_changed.connect(_on_sfx_vol_changed)

	_sync_sliders_from_settings()
	hide()


func open() -> void:
	show()
	get_tree().paused = true


func close() -> void:
	get_tree().paused = false
	hide()


func _on_continue() -> void:
	SoundManager.click_sound()
	close()


func _on_restart() -> void:
	SoundManager.click_sound()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_settings() -> void:
	SoundManager.click_sound()
	$Panel/MainVBox.hide()
	$Panel/SettingsVBox.show()


func _on_settings_back() -> void:
	SoundManager.click_sound()
	$Panel/SettingsVBox.hide()
	$Panel/MainVBox.show()


func _on_quit() -> void:
	SoundManager.click_sound()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		if visible:
			if $Panel/SettingsVBox.visible:
				_on_settings_back()
			else:
				close()


func _sync_sliders_from_settings() -> void:
	$Panel/SettingsVBox/BGMVolRow/BGMVolSlider.value = GameSettings.bgm_volume * 100.0
	$Panel/SettingsVBox/BGMVolRow/BGMVolValue.text = str(int(GameSettings.bgm_volume * 100.0))
	$Panel/SettingsVBox/SFXVolRow/SFXVolSlider.value = GameSettings.sfx_volume * 100.0
	$Panel/SettingsVBox/SFXVolRow/SFXVolValue.text = str(int(GameSettings.sfx_volume * 100.0))


func _on_bgm_vol_changed(val: float) -> void:
	GameSettings.bgm_volume = val / 100.0
	$Panel/SettingsVBox/BGMVolRow/BGMVolValue.text = str(int(val))
	SoundManager.apply_bgm_volume()


func _on_sfx_vol_changed(val: float) -> void:
	GameSettings.sfx_volume = val / 100.0
	$Panel/SettingsVBox/SFXVolRow/SFXVolValue.text = str(int(val))
