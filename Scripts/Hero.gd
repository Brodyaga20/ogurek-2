extends Node2D
var signNow := "None"
var signPrevious := ""
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
var abilities = {"Health": false, "Stance": false}
@onready var save_dict = {
	"pos_x": $Body.position.x,
	"pos_y": $Body.position.y
}

const barPosition = Vector2(-110, 180)
const platePosition = Vector2(5, 205)
const barWithPlatePosition = Vector2(-5, 205)

const HPtype = {"Empty": 0, "CommonFull": 1}

#region onready
@onready var HP = {1: $Camera2D/HUD/Bar/HP/HP1/Sprite, 2: $Camera2D/HUD/Bar/HP/HP2/Sprite, 3: $Camera2D/HUD/Bar/HP/HP3/Sprite, 4: $Camera2D/HUD/Bar/HP/HP4/Sprite}
@onready var HUD = $Camera2D/HUD
@onready var signPlate = $Camera2D/HUD/Sign
@onready var signSprite = $Camera2D/HUD/Sign/Sign
@onready var bar = $Camera2D/HUD/Bar
#endregion

func save_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_dict = { "pos_x": $Body.position.x, "pos_y": $Body.position.y }
	var json_string = JSON.stringify(save_dict)
	save_file.store_line(json_string)

func load_game():
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()
		var json = JSON.new()
		
		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		var node_data = json.data
		$Body.position = Vector2(node_data["pos_x"], node_data["pos_y"])

func _ready():
	signSprite.texture = null

func collect(type: String):
	if type in signs:
		if collectedSigns.is_empty():
			abilities["Stance"] = true
			signPlate.position = platePosition
			bar.position = barWithPlatePosition
		collectedSigns.append(type)
		change_sign(type)
	else:
		match type:
			"Heart":
				abilities["Health"] = true
				bar.position = barPosition

func change_sign(newSign: String):
	if signNow != newSign && collectedSigns.has(newSign):
		signPrevious = signNow
		signNow = newSign
	play_sign_change_anim()

func play_sign_change_anim():
	signAnimationName = signPrevious + "-" + signNow
	$SignAnimation.play(signAnimationName)

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

func _process(_delta: float) -> void:
	for i in range(health):
		HP[i + 1].frame = HPtype["CommonFull"]
	for i in range(4 - health):
		HP[4 - i].frame = HPtype["Empty"]
	if Input.is_action_just_pressed("Restart"):
		$Body.go_to_checkpoint()
		alive = true
		health = maxHealth
	transDeathAnim = $Body.currentGlobalMovementState + "_DEATH"
	if Input.is_action_just_pressed("Quick_Save"):
		save_game()
	if Input.is_action_just_pressed("Quick_Load"):
		load_game()
	
	#region Смена стойки
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
	
	
	#endregion
	
	#region Экран
	if (Input.is_action_just_pressed("Full_Screen")):
		if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN || DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED || DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	#endregion
