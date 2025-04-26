extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL	
}

var gravity = ProjectSettings.get("physics/2d/default_gravity")
#跑步速度
const RUN_SPEED := 160.0
#加速度_地面
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
#加速度_空中
const AIR_ACCELERATION := RUN_SPEED / 0.02
#跳跃高度
const JUMP_VELOCITY := -320.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
		
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2
	

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta
	
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		velocity.y = JUMP_VELOCITY
		coyote_timer.stop()
		jump_request_timer.stop()
		
	if is_on_floor():
		if is_zero_approx(direction) && is_zero_approx(velocity.x):
			animation_player.play("idle")
		else:
			animation_player.play("running")
	elif velocity.y < 0:
		animation_player.play("jump")
	else:
		animation_player.play("fall")
	
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
	
	var was_on_floor := is_on_floor()
	move_and_slide()
	
	if is_on_floor() != was_on_floor:
		if was_on_floor && !should_jump:
			coyote_timer.start()
		else:
			coyote_timer.stop()
