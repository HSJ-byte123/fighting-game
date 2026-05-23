extends CanvasLayer

var round_time: float

@onready var p1_bar: ProgressBar = $P1HealthBar
@onready var p2_bar: ProgressBar = $P2HealthBar
@onready var p1_label: Label = $P1HealthBar/P1Label
@onready var p2_label: Label = $P2HealthBar/P2Label
@onready var timer_label: Label = $TimerLabel
@onready var ko_label: Label = $KOLabel
@onready var winner_label: Label = $WinnerLabel
@onready var rematch_label: Label = $RematchLabel

var _player1: CharacterBody2D
var _player2: CharacterBody2D
var time_left: float
var round_active: bool = true


func _ready() -> void:
	round_time = GameSettings.round_time
	time_left = round_time
	_update_timer_display()
	_apply_bar_styling(p1_bar)
	_apply_bar_styling(p2_bar)
	p1_label.text = "P1  100 / 100"
	p2_label.text = "P2  100 / 100"


func _apply_bar_styling(bar: ProgressBar) -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.15, 1.0)
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.border_width_top = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(1.0, 1.0, 1.0, 1.0)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.1, 0.1, 1.0)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	bar.add_theme_stylebox_override("fill", fill_style)


func setup(p1: Node, p2: Node) -> void:
	_player1 = p1
	_player2 = p2
	if is_instance_valid(p1) and p1.has_signal("health_changed"):
		p1.health_changed.connect(_on_p1_health_changed)
	if is_instance_valid(p2) and p2.has_signal("health_changed"):
		p2.health_changed.connect(_on_p2_health_changed)


func _process(delta: float) -> void:
	if not round_active:
		return

	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		_timeout()
	_update_timer_display()


func _on_p1_health_changed(current: float, maximum: float) -> void:
	p1_bar.max_value = maximum
	p1_bar.value = current
	p1_label.text = "P1  %d / %d" % [int(ceil(current)), int(maximum)]
	if current <= 0.0:
		_end_round("Player 2", "Wins!")


func _on_p2_health_changed(current: float, maximum: float) -> void:
	p2_bar.max_value = maximum
	p2_bar.value = current
	p2_label.text = "P2  %d / %d" % [int(ceil(current)), int(maximum)]
	if current <= 0.0:
		_end_round("Player 1", "Wins!")


func _timeout() -> void:
	var p1_hp: float = p1_bar.value
	var p2_hp: float = p2_bar.value

	if p1_hp > p2_hp:
		_end_round("Player 1", "Wins! (Timeout)")
	elif p2_hp > p1_hp:
		_end_round("Player 2", "Wins! (Timeout)")
	else:
		_end_round("", "Draw!")


func _end_round(winner: String, subtitle: String) -> void:
	round_active = false

	if is_instance_valid(_player1) and _player1.has_method("freeze"):
		_player1.freeze()
	if is_instance_valid(_player2) and _player2.has_method("freeze"):
		_player2.freeze()

	ko_label.text = "K.O."
	ko_label.visible = true

	winner_label.text = winner + "  " + subtitle
	winner_label.visible = true

	rematch_label.text = "Press R to Rematch"
	rematch_label.visible = true

	SoundManager.ko_sound(winner == "Player 2")


func _update_timer_display() -> void:
	var seconds := int(ceil(time_left))
	timer_label.text = str(seconds)
	if time_left <= 10.0:
		timer_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	else:
		timer_label.modulate = Color.WHITE
