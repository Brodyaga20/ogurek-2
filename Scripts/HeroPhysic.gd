extends CharacterBody2D

var noGameplayRandom := randi()
var gameplayPandom := randi()

#region Физические константы
const acceleration := 400
const accelerationAir := 200

const maxSpeed := 770
const maxSpeedAir := 810
const minSpeed := 100

const gravAcc := 5000
const dashGravAcc := 3000
const fastFallAcc := 10000
const slowFallAcc := 20

const jumpSpeed := 950

const dashSpeed := 2000

const airFriction := 0.84
const groundFriction := 0.81
const dashFriction := 0.99

#endregion

#region Таймеры
var dashTimer : float = 0
const dashTimerMax = 0.2
var hangTimer : float = 0
const hangTimerMax = 0.2
var coyoteTimer : float = 0
const coyoteTimerMax = 0.06
var jumpContinueTimer : float = 0
const jumpContinueTimerMax = 0.12
var changePoseTimer : float = 0
const changePoseTimerMax = 0.1
var stopFallingTimer := 0
const stopFallingTimerMax = 0
var attackTimer : float = 0
#endregion

#region Переменные положения в пространстве
var checkpoint := Vector2(0, 0)
var direction := 0
var lastDirection := 0
#endregion

#region Переменные возможности действий
var autoJump = false
var canAutoJump = false
var mustAutoJump = false
var canDJump = false
var canDash = true
var canContinueJump = false
#endregion

var currentSign = ""
var currentTransAnimation := ""
var currentStableAnimation := ""

#region Переменные состояния
enum verticalState {GROUND, WALK, JUMP, FALL, DASH, HANG, FASTFALL, DEATH}
enum horizontalState {CENTER, RIGHT, LEFT}
enum attackState {NONE, SCISSORS, ROCK, PAPER}
var currentVerticalState : verticalState
var currentHorizontalState : horizontalState
var currentAttackState : attackState
#endregion

func _physics_process(delta: float) -> void:
	update_state(delta)

func _process(_delta: float) -> void:
	currentSign = get_parent().currentSign

#region Функции смены состояний
func set_vertical_state(new_state: verticalState) -> void:
	currentTransAnimation = verticalState.keys()[currentVerticalState] + "_" + verticalState.keys()[new_state] + "_" + horizontalState.keys()[currentHorizontalState]
	if currentVerticalState == new_state:
		return
	exit_vertical_state()
	currentVerticalState = new_state
	enter_vertical_state()

func set_horizontal_state(new_state: horizontalState) -> void:
	currentTransAnimation = verticalState.keys()[currentVerticalState] + "_" + horizontalState.keys()[currentHorizontalState] + "_" + horizontalState.keys()[new_state]
	if currentHorizontalState == new_state:
		return
	exit_horizontal_state()
	currentHorizontalState = new_state
	enter_horizontal_state()

func set_attack_state(new_state: attackState) -> void:
	exit_attack_state()
	currentAttackState = new_state
	enter_attack_state()

func play_trans_anim():
	$"../HeroAnimation".play(currentTransAnimation)

func enter_vertical_state() -> void:
	changePoseTimer = changePoseTimerMax
	match currentVerticalState:
		verticalState.JUMP:
			canContinueJump = true
			jumpContinueTimer = jumpContinueTimerMax
		verticalState.GROUND:
			if autoJump:
				set_vertical_state(verticalState.JUMP)
				velocity.y = -jumpSpeed
				autoJump = false
			canDash = true
			canDJump = true
		verticalState.DASH:
			canDash = false
			velocity.y = 0
			velocity.x = dashSpeed * lastDirection
			dashTimer = dashTimerMax
			if lastDirection == 1:
				set_horizontal_state(horizontalState.RIGHT)
			elif lastDirection == -1:
				set_horizontal_state(horizontalState.LEFT)
		verticalState.HANG:
			hangTimer = hangTimerMax
	return

func exit_vertical_state() -> void:
	return

func enter_horizontal_state() -> void:
	changePoseTimer = changePoseTimerMax
	return

func exit_horizontal_state() -> void:
	return

func enter_attack_state() -> void:
	match(currentAttackState):
		"Rock":
			start_attack_timer(1.5)
		"Scissors":
			start_attack_timer(0.12)
		"Paper":
			start_attack_timer(0)
	return

func exit_attack_state() -> void:
	return

func start_attack_timer(time: float) -> void:
	attackTimer = time

#endregion

func play_stable_anim() -> void:
	$"../HeroAnimation".play(currentStableAnimation)

#region Функции чекпоинтов
func set_checkpoint(newCheckpoint: Vector2):
	checkpoint = newCheckpoint + Vector2(0, -75)

func go_to_checkpoint():
	velocity = Vector2.ZERO
	position = checkpoint
#endregion

func set_direction():
	direction = int(Input.is_action_pressed("Right")) -  int(Input.is_action_pressed("Left"))

func update_free_movement(delta:float, type: String):
	velocity.x += direction * acceleration
	velocity.x = clamp(velocity.x, -maxSpeed, maxSpeed)
	if type == "ground":
		velocity.x *= groundFriction
	elif type == "air":
		velocity.x *= airFriction
		velocity.y += gravAcc * delta
	elif type == "stop":
		velocity = Vector2.ZERO
	elif type == "fastfall":
		velocity.x = 0
		velocity.y += fastFallAcc * delta

func update_vertical_state(delta:float):
	match currentVerticalState:
		verticalState.GROUND:
			update_vertical_state_ground(delta)
		verticalState.JUMP:
			update_vertical_state_jump(delta)
		verticalState.FALL:
			update_vertical_state_fall(delta)
		verticalState.DASH:
			update_vertical_state_dash(delta)
		verticalState.HANG:
			update_vertical_state_hang(delta)
		verticalState.FASTFALL:
			update_vertical_state_fastfall(delta)

func update_vertical_state_ground(delta: float):
	update_free_movement(delta, "ground")
	if Input.is_action_just_pressed("Jump"):
		set_vertical_state(verticalState.JUMP)
		velocity.y = -jumpSpeed
	elif Input.is_action_just_pressed("Dash") && currentSign == "Scissors":
		set_vertical_state(verticalState.DASH)
	elif !is_on_floor():
		coyoteTimer = coyoteTimerMax
		set_vertical_state(verticalState.FALL)
	elif Input.is_action_just_pressed("Dash") && currentSign == "Scissors":
		set_vertical_state(verticalState.DASH)

func update_vertical_state_jump(delta: float):
	update_free_movement(delta, "air")
	if velocity.y > 0:
		set_vertical_state(verticalState.FALL)
	elif Input.is_action_just_released("Jump"):
		canContinueJump = false
		velocity.y *= 0.9
	elif jumpContinueTimer > 0 && Input.is_action_pressed("Jump") && canContinueJump:
		velocity.y = -jumpSpeed
	elif Input.is_action_just_pressed("Jump") && currentSign == "Paper" && canDJump:
		velocity.y = -jumpSpeed
		canDJump = false
	elif Input.is_action_just_pressed("Jump") && currentSign == "Scissors" && canDash:
		set_vertical_state(verticalState.DASH)
	elif Input.is_action_just_pressed("Jump") && currentSign == "Rock":
		set_vertical_state(verticalState.HANG)
	if !direction:
		velocity.x *= airFriction
	else:
		lastDirection = direction

func update_vertical_state_fall(delta: float):
	update_free_movement(delta, "air")
	if is_on_floor():
		set_vertical_state(verticalState.GROUND)
	elif Input.is_action_just_pressed("Jump") && currentSign == "Scissors" && canDash:
		set_vertical_state(verticalState.DASH)
	elif Input.is_action_just_pressed("Jump") && ((currentSign == "Paper" && canDJump) || (coyoteTimer > 0)):
		velocity.y = -jumpSpeed
		canDJump = false
		set_vertical_state(verticalState.JUMP)
	elif Input.is_action_just_pressed("Jump") && currentSign == "Rock":
		set_vertical_state(verticalState.HANG)
	elif Input.is_action_just_pressed("Jump") && canAutoJump:
		autoJump = true
		canAutoJump = false
	if !direction:
		velocity.x *= airFriction
	if direction:
		lastDirection = direction

func update_vertical_state_hang(delta: float):
	update_free_movement(delta, "stop")
	hangTimer -= delta
	if hangTimer <= 0:
		hangTimer = 0
		set_vertical_state(verticalState.FASTFALL)

func update_vertical_state_dash(delta: float):
	dashTimer -= delta
	velocity.y += dashGravAcc * delta
	if dashTimer <= 0:
		dashTimer = 0
		set_vertical_state(verticalState.FALL)
	if Input.is_action_just_pressed("Jump") && currentSign == "Rock":
		set_vertical_state(verticalState.HANG)

func update_vertical_state_fastfall(delta: float):
	update_free_movement(delta, "fastfall")
	if is_on_floor():
		set_vertical_state(verticalState.GROUND)

func update_horizontal_state_center():
	if direction == 1:
		set_horizontal_state(horizontalState.RIGHT)
	elif direction == -1:
		set_horizontal_state(horizontalState.LEFT)

func update_horizontal_state_left():
	if direction != -1:
		set_horizontal_state(horizontalState.CENTER)

func update_horizontal_state_right():
	if direction != 1:
		set_horizontal_state(horizontalState.CENTER)

func update_horizontal_state():
	match currentHorizontalState:
		horizontalState.CENTER:
			update_horizontal_state_center()
		horizontalState.LEFT:
			update_horizontal_state_left()
		horizontalState.RIGHT:
			update_horizontal_state_right()

func update_attack_state():
	match currentAttackState:
		attackState.NONE:
			if Input.is_action_just_pressed("Attack"):
				match currentSign:
					"Rock":
						set_attack_state(attackState.ROCK)
					"Scissors":
						set_attack_state(attackState.SCISSORS)
					"Paper":
						set_attack_state(attackState.PAPER)
				
	return

func update_animation(delta: float):
	update_change_pose_timer(delta)

func update_state(delta: float) -> void:
	if get_parent().alive:
		move_and_slide()
		update_animation(delta)
		set_direction()
		update_vertical_state(delta)
		update_horizontal_state()
		update_attack_state()
		update_timers(delta)
	else:
		update_death(delta)

func update_timers(delta: float):
	update_coyote_timer(delta)
	update_attack_timer(delta)
	update_jump_continue_timer(delta)

func update_coyote_timer(delta: float):
	if coyoteTimer > 0:
		coyoteTimer -= delta

func update_jump_continue_timer(delta: float):
	if jumpContinueTimer > 0:
		jumpContinueTimer -= delta

func update_attack_timer(delta: float):
	if attackTimer > 0:
		attackTimer -= delta

func update_change_pose_timer(delta: float):
	if changePoseTimer > 0:
		changePoseTimer -= delta
		play_trans_anim()
	if changePoseTimer < 0 && changePoseTimer > -1:
		currentStableAnimation = verticalState.keys()[currentVerticalState] + "_" + horizontalState.keys()[currentHorizontalState]
		play_stable_anim()
		changePoseTimer = 0

func update_death(delta: float) -> void:
	$"../HeroAnimation".play("DEATH_" + horizontalState.keys()[currentHorizontalState])
	if !is_on_floor():
		velocity.y += gravAcc * delta
	else:
		velocity.x *= 0.9

func _on_coyote_area_body_entered(_body: Node2D) -> void:
	canAutoJump = true

func _on_coyote_area_body_exited(_body: Node2D) -> void:
	canAutoJump = false
