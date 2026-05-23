extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const MAX_JUMPS = 2

var jumps_remaining := MAX_JUMPS

func _physics_process(delta: float) -> void:
	# 1. 基础重力
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_remaining = MAX_JUMPS

	# 2. 获取玩家输入状态
	var direction := Input.get_axis("ui_left", "ui_right")
	var is_crouching := Input.is_action_pressed("ui_down")

	# 3. 下蹲逻辑
	if is_crouching and is_on_floor():
		velocity.x = 0
		scale.y = 0.5
	else:
		scale.y = 1.0

		# 4. 跳跃逻辑（支持二段跳）
		if Input.is_action_just_pressed("ui_accept") and jumps_remaining > 0:
			velocity.y = JUMP_VELOCITY
			jumps_remaining -= 1

		# 5. 移动与转向逻辑
		if direction:
			velocity.x = direction * SPEED
			$Sprite2D.flip_h = direction < 0
		else:
			velocity.x = 0

	# 6. 执行物理运算
	move_and_slide()
