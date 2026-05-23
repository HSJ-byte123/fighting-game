extends CharacterBody2D

enum State { IDLE, WALK, JUMP, CROUCH, ATTACK, HIT, KO }

signal health_changed(current: float, maximum: float)
signal hit_received

@export var speed: float = 300.0
@export var jump_velocity: float = -710.0
@export var gravity: float = 980.0
@export var attack_duration: float = 0.35
@export var hit_stun_duration: float = 0.4
@export var knockback_force: float = 300.0
@export var max_health: float = 100.0
@export var attack_damage: float = 10.0

@export var action_left: String = "move_left"
@export var action_right: String = "move_right"
@export var action_down: String = "move_down"
@export var action_jump: String = "jump"
@export var action_attack: String = "attack"
@export var sfx_prefix: String = "xi"

var opponent: CharacterBody2D
var current_health: float
var current_state: State = State.IDLE
var state_timer: float = 0.0
@export var facing_right: bool = true
var hit_active: bool = false

@export var ai_controlled: bool = false
var ai_difficulty: String = "medium"
var frozen: bool = false
var _ai_timer: float = 0.0
var _ai_move_dir: float = 0.0
var _ai_wants_attack: bool = false
var _ai_wants_jump: bool = false
var _ai_wants_down: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	current_health = max_health
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	health_changed.emit(current_health, max_health)
	sprite.play("idle")


func _input(event: InputEvent) -> void:
	if ai_controlled:
		return
	if not event is InputEventKey or event.echo:
		return
	if action_jump != "jump":
		return
	if event.physical_keycode == KEY_KP_0:
		if event.pressed:
			Input.action_press(action_jump)
		else:
			Input.action_release(action_jump)
	elif event.physical_keycode == KEY_KP_1:
		if event.pressed:
			Input.action_press(action_attack)
		else:
			Input.action_release(action_attack)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if ai_controlled:
		_ai_think(delta)

	_face_opponent()
	_update_state(delta)
	move_and_slide()


func _update_state(delta: float) -> void:
	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.WALK:
			_state_walk(delta)
		State.JUMP:
			_state_jump(delta)
		State.CROUCH:
			_state_crouch(delta)
		State.ATTACK:
			_state_attack(delta)
		State.HIT:
			_state_hit(delta)
		State.KO:
			_state_ko(delta)


func _enter_state(new_state: State) -> void:
	_exit_state(current_state)
	current_state = new_state

	match new_state:
		State.IDLE:
			sprite.play("idle")
		State.WALK:
			_play_anim_or_idle("walk")
		State.JUMP:
			_play_anim_or_idle("jump")
			SoundManager.jump_sound()
		State.CROUCH:
			_play_anim_or_idle("crouch")
			_set_crouch_shape(true)
		State.ATTACK:
			_play_anim_or_idle("attack")
			state_timer = attack_duration
			velocity.x = 0
			hit_active = true
			_activate_hitbox(true)
			SoundManager.attack_sound(sfx_prefix == "xi")
		State.HIT:
			_play_anim_or_idle("hit")
			state_timer = hit_stun_duration
			hit_active = false
			_activate_hitbox(false)
			SoundManager.hit_sound(sfx_prefix == "xi")
		State.KO:
			_play_anim_or_idle("ko")
			velocity = Vector2.ZERO
			hit_active = false
			_activate_hitbox(false)


func _exit_state(old_state: State) -> void:
	match old_state:
		State.CROUCH:
			_set_crouch_shape(false)
		State.ATTACK:
			hit_active = false
			_activate_hitbox(false)


# --- AI ---

func _ai_think(delta: float) -> void:
	_ai_timer -= delta
	if _ai_timer > 0.0:
		return

	# Difficulty parameters
	var timer_min: float
	var timer_max: float
	var attack_chance: float
	var jump_chance: float
	var attack_range: float
	var approach_range: float

	match ai_difficulty:
		"easy":
			timer_min = 0.5; timer_max = 1.0
			attack_chance = 0.3
			jump_chance = 0.05
			attack_range = 70.0
			approach_range = 50.0
		"hard":
			timer_min = 0.1; timer_max = 0.3
			attack_chance = 0.7
			jump_chance = 0.25
			attack_range = 110.0
			approach_range = 90.0
		_:
			timer_min = 0.25; timer_max = 0.5
			attack_chance = 0.5
			jump_chance = 0.15
			attack_range = 90.0
			approach_range = 70.0

	_ai_timer = randf_range(timer_min, timer_max)

	if not is_instance_valid(opponent):
		_ai_move_dir = 0.0
		_ai_wants_attack = false
		_ai_wants_jump = false
		_ai_wants_down = false
		return

	var dist := opponent.global_position.x - global_position.x
	var abs_dist: float = abs(dist)

	# Movement: approach opponent
	if abs_dist > approach_range:
		_ai_move_dir = 1.0 if dist > 0.0 else -1.0
	else:
		_ai_move_dir = 0.0

	# Attack when close
	_ai_wants_attack = abs_dist < attack_range and randf() < attack_chance

	# Jump occasionally
	_ai_wants_jump = randf() < jump_chance

	# Crouch rarely
	_ai_wants_down = randf() < 0.05


func _get_move_direction() -> float:
	if frozen or current_state == State.KO:
		return 0.0
	if ai_controlled:
		return _ai_move_dir
	return Input.get_axis(action_left, action_right)


func _wants_jump() -> bool:
	if frozen or current_state == State.KO:
		return false
	if ai_controlled:
		return _ai_wants_jump
	return Input.is_action_just_pressed(action_jump)


func _wants_down() -> bool:
	if frozen or current_state == State.KO:
		return false
	if ai_controlled:
		return _ai_wants_down
	return Input.is_action_pressed(action_down)


func _wants_attack() -> bool:
	if frozen or current_state == State.KO:
		return false
	if ai_controlled:
		return _ai_wants_attack
	return Input.is_action_just_pressed(action_attack)


func freeze() -> void:
	frozen = true
	velocity = Vector2.ZERO

# --- State handlers ---

func _state_idle(delta: float) -> void:
	var direction := _get_move_direction()

	if direction != 0:
		velocity.x = direction * speed
		_enter_state(State.WALK)
		return

	velocity.x = move_toward(velocity.x, 0, speed * 10 * delta)

	if _wants_jump() and is_on_floor():
		velocity.y = jump_velocity
		_enter_state(State.JUMP)
		return

	if _wants_down() and is_on_floor():
		_enter_state(State.CROUCH)
		return

	if _wants_attack():
		_enter_state(State.ATTACK)
		return


func _state_walk(_delta: float) -> void:
	var direction := _get_move_direction()

	if direction == 0:
		_enter_state(State.IDLE)
		return

	velocity.x = direction * speed

	if _wants_jump() and is_on_floor():
		velocity.y = jump_velocity
		_enter_state(State.JUMP)
		return

	if _wants_down() and is_on_floor():
		_enter_state(State.CROUCH)
		return

	if _wants_attack():
		_enter_state(State.ATTACK)
		return


func _state_jump(_delta: float) -> void:
	if is_on_floor() and velocity.y >= 0.0:
		_enter_state(State.IDLE)
		return

	var direction := _get_move_direction()
	velocity.x = direction * speed

	if _wants_attack():
		_enter_state(State.ATTACK)
		return


func _state_crouch(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed * 12 * _delta)

	if not _wants_down():
		_enter_state(State.IDLE)
		return

	if _wants_jump():
		_enter_state(State.IDLE)
		return

	if _wants_attack():
		_enter_state(State.ATTACK)
		return


func _state_attack(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0, speed * 5 * delta)

	if state_timer <= 0.0:
		if is_on_floor():
			_enter_state(State.IDLE)
		else:
			_enter_state(State.JUMP)


func _state_hit(delta: float) -> void:
	state_timer -= delta
	velocity.x = move_toward(velocity.x, 0, speed * 8 * delta)

	if state_timer <= 0.0:
		if current_health <= 0.0:
			_enter_state(State.KO)
		elif is_on_floor():
			_enter_state(State.IDLE)
		else:
			_enter_state(State.JUMP)


func _state_ko(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed * 8 * _delta)


# --- Hit detection ---

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not hit_active:
		return

	if not is_instance_valid(area):
		return

	var target: Node = area.get_parent()
	if not is_instance_valid(target) or target == self:
		return

	if not target.has_method("take_hit"):
		return

	if is_on_floor() and target.current_state == State.JUMP:
		return

	var knockback_dir := 1.0 if facing_right else -1.0
	var knockback := Vector2(knockback_dir * knockback_force, -knockback_force * 0.3)
	target.take_hit(knockback, attack_damage)


# --- Public interface ---

func take_hit(knockback: Vector2, damage: float) -> void:
	if current_state == State.HIT or current_state == State.KO:
		return

	current_health = max(0.0, current_health - damage)
	health_changed.emit(current_health, max_health)
	hit_received.emit()
	velocity = knockback
	_enter_state(State.HIT)


func _play_anim_or_idle(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		sprite.play("idle")


# --- Internal helpers ---

func _face_opponent() -> void:
	if not is_instance_valid(opponent):
		return
	var dir := 1.0 if opponent.global_position.x > global_position.x else -1.0
	_update_facing(dir)


func _update_facing(direction: float) -> void:
	if direction > 0:
		facing_right = true
		sprite.flip_h = false
	elif direction < 0:
		facing_right = false
		sprite.flip_h = true


func _activate_hitbox(active: bool) -> void:
	if not is_instance_valid(hitbox):
		return

	var hitbox_collision: CollisionShape2D = hitbox.get_node("CollisionShape2D")
	if not is_instance_valid(hitbox_collision):
		return

	var sign_dir := 1.0 if facing_right else -1.0
	hitbox_collision.position.x = 50.0 * sign_dir

	hitbox.set_deferred("monitoring", active)
	hitbox.set_deferred("monitorable", active)


func _set_crouch_shape(crouch: bool) -> void:
	if not is_instance_valid(sprite) or not is_instance_valid(collision_shape):
		return

	var factor := 0.5 if crouch else 1.0
	sprite.scale.y = factor
	collision_shape.scale.y = factor

	if crouch:
		collision_shape.position.y = -49.0
	else:
		collision_shape.position.y = -114.0
