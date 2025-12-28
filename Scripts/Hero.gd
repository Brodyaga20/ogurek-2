extends Node2D
var signNow := "Scissors"
var signPrevious := ""
var signChangeTimer : float = 0
var velocityX : float = 0
var signAnimationName := ""
var cameraSpeed = Vector2.ZERO
const animationLength := 0.25
var signs = {"Rock": false, "Paper": false, "Scissors": false}

func playSignChangeAnim():
	signAnimationName = signPrevious + "-" + signNow
	$SignChange.play(signAnimationName)

func _physics_process(_delta: float) -> void:
	cameraSpeed = ($Body.position - $Camera2D.position)/70
	$Camera2D.position = lerp($Camera2D.position, $Camera2D.position+cameraSpeed, 2)


func _process(delta: float) -> void:
	
			
	if signChangeTimer <= 0:
		if ((Input.is_action_just_pressed("Rock_Sign")) && signNow != "Rock") || (Input.is_action_just_pressed("Next_Sign") && signNow == "Paper"):
			signPrevious = signNow
			signNow = "Rock"
			signChangeTimer = animationLength
		else:
			if ((Input.is_action_just_pressed("Scissors_Sign")) && signNow != "Scissors") || (Input.is_action_just_pressed("Next_Sign") && signNow == "Rock"):
				signPrevious = signNow
				signNow = "Scissors"
				signChangeTimer = animationLength
			else:
				if ((Input.is_action_just_pressed("Paper_Sign")) && signNow != "Paper") || (Input.is_action_just_pressed("Next_Sign") && signNow == "Scissors"):
					signPrevious = signNow
					signNow = "Paper"
					signChangeTimer = animationLength
	
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
