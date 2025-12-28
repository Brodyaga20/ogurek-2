extends CharacterBody2D
#region variables
var acceleration := 400
var accelerationAir := 200

const maxSpeed := 650
const maxSpeedAir := 900
const minSpeed := 100

var signNow = ""
const gravAcc := 5000
const dashGravAcc := 3000
const fastFallAcc := 400
const slowFallAcc := 20

const secondJumpSpeed := 1150
const jumpSpeed := 1300

const dashSpeed := 2000

var dashTimer : float = 0
var hangTimer : float = 0

const airFriction := 0.84
const groundFriction := 0.81
const dashFriction := 0.99

var direction := 0
var lastDirection := 0

var canDJump = true
var canDash = true

var currentTransAnimation := ""
var currentStableAnimation := ""

var stopMove := false
var changePoseTimer : float = 0
var stopFallingTimer := 0
enum verticalState {GROUND, WALK, JUMP, FALL, DJUMP, DASH, HANG, FASTFALL}
enum horizontalState {CENTER, RIGHT, LEFT}
var currentVerticalState : verticalState
var currentHorizontalState : horizontalState
var currentGlobalMovementState := ""

#endregion

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
	changePoseTimer = 0.1
	match currentVerticalState:
		verticalState.GROUND:
			canDash = true
			canDJump = true
			pass
		verticalState.DASH:
			canDash = false
			velocity.y = 0
			velocity.x = dashSpeed * lastDirection
			dashTimer = 0.2
			if lastDirection == 1:
				set_horizontal_state(horizontalState.RIGHT)
			elif lastDirection == -1:
				set_horizontal_state(horizontalState.LEFT)
		verticalState.DJUMP:
			canDJump = false
			velocity.y = -secondJumpSpeed
	return

func exit_vertical_state() -> void:
	return

func enter_horizontal_state() -> void:
	$"../HeroAnimation".play(currentTransAnimation)
	changePoseTimer = 0.1
	return

func exit_horizontal_state() -> void:
	return

func start_playing_stable_anim() -> void:
	$"../HeroAnimation".play(currentStableAnimation)

func update_state(delta: float) -> void:
	currentGlobalMovementState = verticalState.keys()[currentVerticalState] + "-" + horizontalState.keys()[currentHorizontalState]
	
	if changePoseTimer > 0:
		changePoseTimer -= delta
	if changePoseTimer < 0:
		currentStableAnimation = verticalState.keys()[currentVerticalState] + "_" + horizontalState.keys()[currentHorizontalState]
		start_playing_stable_anim()
		changePoseTimer = 0
	direction = int(Input.is_action_pressed("Right")) -  int(Input.is_action_pressed("Left"))
	match currentVerticalState:
		verticalState.GROUND:
			velocity.x += direction * acceleration
			velocity.x = clamp(velocity.x, -maxSpeed, maxSpeed)
			velocity.x *= groundFriction
			if Input.is_action_just_pressed("Jump"):
				set_vertical_state(verticalState.JUMP)
				velocity.y = -jumpSpeed
			elif Input.is_action_just_pressed("Dash") && signNow == "Scissors":
				set_vertical_state(verticalState.DASH)
			elif !is_on_floor():
				set_vertical_state(verticalState.FALL)
			elif Input.is_action_just_pressed("Dash") && signNow == "Scissors":
				set_vertical_state(verticalState.DASH)
		verticalState.JUMP:
			velocity.x += direction * accelerationAir
			velocity.x = clamp(velocity.x, -maxSpeedAir, maxSpeedAir)
			velocity.y += gravAcc * delta
			if velocity.y > 0:
				set_vertical_state(verticalState.FALL)
			elif Input.is_action_just_pressed("Jump") && signNow == "Paper" && canDJump:
				set_vertical_state(verticalState.DJUMP)
			elif Input.is_action_just_pressed("Jump") && signNow == "Scissors" && canDash:
				set_vertical_state(verticalState.DASH)
			if !direction:
				velocity.x *= airFriction
			else:
				lastDirection = direction
		verticalState.FALL:
			velocity.x += direction * accelerationAir
			velocity.x = clamp(velocity.x, -maxSpeedAir, maxSpeedAir)
			velocity.y += gravAcc * delta
			if is_on_floor():
				set_vertical_state(verticalState.GROUND)
			elif Input.is_action_just_pressed("Jump") && signNow == "Scissors" && canDash:
				set_vertical_state(verticalState.DASH)
			elif Input.is_action_just_pressed("Jump") && signNow == "Paper" && canDJump:
				set_vertical_state(verticalState.DJUMP)
			if !direction:
				velocity.x *= airFriction
			if direction:
				lastDirection = direction
		verticalState.DASH:
			dashTimer -= delta
			velocity.y += dashGravAcc * delta
			if dashTimer <= 0:
				dashTimer = 0
				set_vertical_state(verticalState.FALL)
		verticalState.HANG:
			hangTimer -= delta
			if hangTimer <= 0:
				hangTimer = 0
				set_vertical_state(verticalState.FASTFALL)
		verticalState.DJUMP:
			canDJump = false
			velocity.x += direction * accelerationAir
			velocity.x = clamp(velocity.x, -maxSpeedAir, maxSpeedAir)
			velocity.y += gravAcc * delta
			if velocity.y > 0:
				set_vertical_state(verticalState.FALL)
			elif Input.is_action_just_pressed("Jump") && signNow == "Scissors" && canDash:
				set_vertical_state(verticalState.DASH)
			if !direction:
				velocity.x *= airFriction
			if direction:
				lastDirection = direction
	match currentHorizontalState:
		horizontalState.CENTER:
			if direction == 1:
				set_horizontal_state(horizontalState.RIGHT)
			elif direction == -1:
				set_horizontal_state(horizontalState.LEFT)
		horizontalState.LEFT:
			if direction != -1:
				set_horizontal_state(horizontalState.CENTER)
		horizontalState.RIGHT:
			if direction != 1:
				set_horizontal_state(horizontalState.CENTER)
	pass

func _physics_process(delta: float) -> void:
	move_and_slide()
	update_state(delta)

func _process(_delta: float) -> void:
	signNow = get_parent().signNow
