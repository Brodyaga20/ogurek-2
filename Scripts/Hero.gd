extends Node2D
var signNow := "None"
var signPrevious := ""
var velocityX : float = 0
var signAnimationName := ""
var cameraSpeed = Vector2.ZERO
var distanceCameraToHero := 0
const animationLength := 0.25
var signs = ["Rock", "Paper", "Scissors"]
var signNowNumber = 0
var signNextNumber = 0
var maxHealth = 4
var alive = true
var transDeathAnim := ""

@onready var save_dict = {
	"pos_x": $Body.position.x,
	"pos_y": $Body.position.y
}

const barPosition = Vector2(-110, 180)
const platePosition = Vector2(5, 205)
const barWithPlatePosition = Vector2(-5, 205)



#region onready
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
	pass
	#signSprite.texture = null

func collect(type: String):
	if type in signs:
		if GlobalVars.collectedSigns.is_empty():
			GlobalVars.abilities["Stance"] = true
		GlobalVars.collectedSigns.append(type)
		change_sign(type)


func change_sign(newSign: String):
	if signNow != newSign && GlobalVars.collectedSigns.has(newSign):
		signPrevious = signNow
		signNow = newSign
	play_sign_change_anim()

func play_sign_change_anim():
	signAnimationName = signPrevious + "-" + signNow
	$SignAnimation.play(signAnimationName)

func take_damage(amount: int, isTrap: bool):
	if amount >= GlobalVars.health:
		GlobalVars.health = 0
		die()
	elif isTrap:
		$Body.go_to_checkpoint()
		GlobalVars.health -= amount
	else:
		GlobalVars.health -= amount
	pass

func die() -> void:
	alive = false



func _physics_process(_delta: float) -> void:
	pass

func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("Restart"):
		$Body.go_to_checkpoint()
		alive = true
		GlobalVars.health = maxHealth
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
	if Input.is_action_just_pressed("Next_Sign") && GlobalVars.collectedSigns.size() >= 1:
		signNowNumber = GlobalVars.collectedSigns.find(signNow) + 1
		signNextNumber = signNowNumber + 1
		if signNextNumber > GlobalVars.collectedSigns.size():
			signNextNumber = 1
		change_sign(GlobalVars.collectedSigns[signNextNumber - 1])
	
	
	#endregion
	
	#region Экран
	if (Input.is_action_just_pressed("Full_Screen")):
		if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN || DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED || DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MAXIMIZED):
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	#endregion
