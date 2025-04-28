extends CharacterBody2D
#枚举
enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING	
}
#在地面的状态
const GROUND_STATES = [State.IDLE, State.RUNNING, State.LANDING]

var default_gravity = ProjectSettings.get("physics/2d/default_gravity")
#跑步速度
const RUN_SPEED := 160.0
#加速度_地面
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
#加速度_空中
const AIR_ACCELERATION := RUN_SPEED / 0.02
#跳跃高度
const JUMP_VELOCITY := -320.0
#第一帧
var is_first_tick = false

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
	

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(default_gravity, delta)
		
		State.RUNNING:
			move(default_gravity, delta)
		
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity, delta)
		
		State.FALL:
			move(default_gravity, delta)
			
		State.JUMP:
			stand(delta)
			
	is_first_tick = false

func move(gravity: float, delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta
	
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
		
	move_and_slide()
	
func stand(delta: float) -> void:
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += default_gravity * delta
	
	move_and_slide()

func get_next_state(state: State)-> State:
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := can_jump and jump_request_timer.time_left > 0
	if should_jump:
		return State.JUMP
#	操作状态
	var direction := Input.get_axis("move_left", "move_right")
#	玩家是否是战力不动
	var is_still := is_zero_approx(direction) && is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			if not is_still:
				return State.RUNNING
		
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			if is_still:
				return State.IDLE
		
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
		
		State.FALL:
			if is_on_floor():
				return State.IDLE if is_still else State.RUNNING
				
		State.LANDING:
			if not animation_player.is_playing():
				return State.IDLE
				
	return state
	
func transition_state(from: State, to: State) -> void:
	if from not in GROUND_STATES and to in GROUND_STATES:
		coyote_timer.stop()
	
	match to:
		State.IDLE:
			animation_player.play("idle")
		
		State.RUNNING:
			animation_player.play("running")
	
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
	
		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATES:
				coyote_timer.start()
	
		State.LANDING:
			animation_player.play("landing")
			
	is_first_tick = true
