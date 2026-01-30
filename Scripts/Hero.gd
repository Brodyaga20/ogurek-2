extends Node2D
var signNow := "None"
var signPrevious := ""
var signChangeTimer : float = 0
var velocityX : float = 0
var signAnimationName := ""
var cameraSpeed = Vector2.ZERO
var distanceCameraToHero := 0
const animationLength := 0.25
var collectedSigns = []
var signs = ["Rock", "Paper", "Scissors"]
var signNowNumber = 0
var signNextNumber = 0
var maxHealth = 4
var health = 4
var alive = true
var transDeathAnim := ""
var abilities = {"Health": false}

const HPtype = {"Empty": 0, "CommonFull": 1}


@onready var HP = {1: $Camera2D/HUD/HP/HP1/Sprite, 2: $Camera2D/HUD/HP/HP2/Sprite, 3: $Camera2D/HUD/HP/HP3/Sprite, 4: $Camera2D/HUD/HP/HP4/Sprite}
@onready var HUD = $Camera2D/HUD
@onready var signSprite = $Camera2D/HUD/Sign
@onready var barSprite = $Camera2D/HUD/Bar

func _ready():
	signSprite.texture = null

func collect(type: String):
	if type in signs:
		if collectedSigns.is_empty():
			HUD.position.y += 200
		collectedSigns.append(type)
		change_sign(type)
	else:
		match type:
			"Heart":
				abilities["Health"] = true

func change_sign(newSign: String):
	if signNow != newSign && collectedSigns.has(newSign):
		signPrevious = signNow
		signNow = newSign
		signChangeTimer = animationLength

func playSignChangeAnim():
	signAnimationName = signPrevious + "-" + signNow
	$SignChange.play(signAnimationName)

func take_damage(amount: int, isTrap: bool):
	if amount >= health:
		health = 0
		die()
	elif isTrap:
		$Body.go_to_checkpoint()
		health -= amount
	else:
		health -= amount
	pass

func die() -> void:
	alive = false

func set_camera_position() -> void:
	cameraSpeed = ($Body.position - $Camera2D.position)/55
	distanceCameraToHero = $Camera2D.position.distance_to($Body.position)
	if distanceCameraToHero > 5:
		$Camera2D.position = lerp($Camera2D.position, $Camera2D.position+cameraSpeed, 2)

func _physics_process(_delta: float) -> void:
	set_camera_position()

func _process(delta: float) -> void:
	for i in range(health):
		HP[i + 1].frame = HPtype["CommonFull"]
	for i in range(4 - health):
		HP[4 - i].frame = HPtype["Empty"]
	if Input.is_action_just_pressed("Die"):
		die()
	if Input.is_action_just_pressed("Reborn"):
		alive = true
		health = maxHealth
	transDeathAnim = $Body.currentGlobalMovementState + "_DEATH"
	if signChangeTimer <= 0:
		if ((Input.is_action_just_pressed("Rock_Sign"))):
			change_sign("Rock")
		elif ((Input.is_action_just_pressed("Scissors_Sign"))):
			change_sign("Scissors")
		elif ((Input.is_action_just_pressed("Paper_Sign"))):
			change_sign("Paper")
		if Input.is_action_just_pressed("Next_Sign") && collectedSigns.size() >= 1:
			signNowNumber = collectedSigns.find(signNow) + 1
			signNextNumber = signNowNumber + 1
			if signNextNumber > collectedSigns.size():
				signNextNumber = 1
			change_sign(collectedSigns[signNextNumber - 1])
	
	if signChangeTimer > 0:
		signChangeTimer -= delta
		playSignChangeAnim()
		
	#region Экран
	if (Input.is_action_just_pressed("Full_Screen")):
		if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN || DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED || DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	#endregion
