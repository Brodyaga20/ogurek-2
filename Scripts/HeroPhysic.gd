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

const jumpSpeed := 900

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

var signNow = ""
var currentTransAnimation := ""
var currentStableAnimation := ""

#region Переменные состояния
enum verticalState {GROUND, WALK, JUMP, FALL, DASH, HANG, FASTFALL, DEATH}
enum horizontalState {CENTER, RIGHT, LEFT}
var currentVerticalState : verticalState
var currentHorizontalState : horizontalState
var currentGlobalMovementState := ""
#endregion

func _physics_process(delta: float) -> void:
	update_state(delta)

func _process(_delta: float) -> void:
	signNow = get_parent().signNow

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

func enter_vertical_state() -> void:
	$"../HeroAnimation".play(currentTransAnimation)
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
			pass
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
	$"../HeroAnimation".play(currentTransAnimation)
	if currentVerticalState == verticalState.GROUND:
		changePoseTimer = changePoseTimerMax
	else:
		changePoseTimer = -1
	return

func exit_horizontal_state() -> void:
	return
#endregion

func start_playing_stable_anim() -> void:
	$"../HeroAnimation".play(currentStableAnimation)

#region Функции чекпоинтов
func set_checkpoint(newCheckpoint: Vector2):
	checkpoint = newCheckpoint + Vector2(0, -75)

func go_to_checkpoint():
	velocity = Vector2.ZERO
	position = checkpoint
#endregion

func set_current_state():
	currentGlobalMovementState = verticalState.keys()[currentVerticalState] + "_" + horizontalState.keys()[currentHorizontalState]

func set_direction():
	direction = int(Input.is_action_pressed("Right")) -  int(Input.is_action_pressed("Left"))

func horizontal_movement(delta:float, type: String):
	velocity.x += direction * acceleration
	velocity.x = clamp(velocity.x, -maxSpeed, maxSpeed)
	if type == "ground":
		velocity.x *= groundFriction
	elif type == "air":
		velocity.x *= airFriction

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
	horizontal_movement(delta, "ground")
	if Input.is_action_just_pressed("Jump"):
		set_vertical_state(verticalState.JUMP)
		velocity.y = -jumpSpeed
	elif Input.is_action_just_pressed("Dash") && signNow == "Scissors":
		set_vertical_state(verticalState.DASH)
	elif !is_on_floor():
		coyoteTimer = coyoteTimerMax
		set_vertical_state(verticalState.FALL)
	elif Input.is_action_just_pressed("Dash") && signNow == "Scissors":
		set_vertical_state(verticalState.DASH)

func update_vertical_state_jump(delta: float):
	if jumpContinueTimer > 0:
		jumpContinueTimer -= delta
	velocity.x += direction * accelerationAir
	velocity.x = clamp(velocity.x, -maxSpeedAir, maxSpeedAir)
	velocity.y += gravAcc * delta
	if velocity.y > 0:
		set_vertical_state(verticalState.FALL)
	elif Input.is_action_just_released("Jump"):
		canContinueJump = false
	elif jumpContinueTimer > 0 && Input.is_action_pressed("Jump") && canContinueJump:
		velocity.y = -jumpSpeed
	elif Input.is_action_just_pressed("Jump") && signNow == "Paper" && canDJump:
		velocity.y = -jumpSpeed
		canDJump = false
	elif Input.is_action_just_pressed("Jump") && signNow == "Scissors" && canDash:
		set_vertical_state(verticalState.DASH)
	elif Input.is_action_just_pressed("Jump") && signNow == "Rock":
		set_vertical_state(verticalState.HANG)
	if !direction:
		velocity.x *= airFriction
	else:
		lastDirection = direction

func update_vertical_state_fall(delta: float):
	velocity.x += direction * accelerationAir
	velocity.x = clamp(velocity.x, -maxSpeedAir, maxSpeedAir)
	velocity.y += gravAcc * delta
	if is_on_floor():
		set_vertical_state(verticalState.GROUND)
	elif Input.is_action_just_pressed("Jump") && signNow == "Scissors" && canDash:
		set_vertical_state(verticalState.DASH)
	elif Input.is_action_just_pressed("Jump") && ((signNow == "Paper" && canDJump) || (coyoteTimer > 0)):
		velocity.y = -jumpSpeed
		canDJump = false
		set_vertical_state(verticalState.JUMP)
	elif Input.is_action_just_pressed("Jump") && signNow == "Rock":
		set_vertical_state(verticalState.HANG)
	elif Input.is_action_just_pressed("Jump") && canAutoJump:
		autoJump = true
		canAutoJump = false
	if !direction:
		velocity.x *= airFriction
	if direction:
		lastDirection = direction

func update_vertical_state_hang(delta: float):
	velocity.x = 0
	velocity.y = 0
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
	if Input.is_action_just_pressed("Jump") && signNow == "Rock":
		set_vertical_state(verticalState.HANG)

func update_vertical_state_fastfall(delta: float):
	velocity.y += fastFallAcc * delta
	velocity.x = 0
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

func update_horizontal_state(delta: float):
	match currentHorizontalState:
		horizontalState.CENTER:
			update_horizontal_state_center()
		horizontalState.LEFT:
			update_horizontal_state_left()
		horizontalState.RIGHT:
			update_horizontal_state_right()

func update_animation(delta: float):
	if changePoseTimer != 0:
		changePoseTimer -= delta
	if changePoseTimer < 0 && changePoseTimer > -1:
		currentStableAnimation = verticalState.keys()[currentVerticalState] + "_" + horizontalState.keys()[currentHorizontalState]
		start_playing_stable_anim()
		changePoseTimer = 0

func update_state(delta: float) -> void:
	if get_parent().alive:
		move_and_slide()
		set_current_state()
		if coyoteTimer > 0:
			coyoteTimer -= delta
		update_animation(delta)
		set_direction()
		update_vertical_state(delta)
		update_horizontal_state(delta)
	else:
		update_death(delta)

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
