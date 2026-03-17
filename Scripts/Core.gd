extends Node2D

@onready var HP = {1: $Hero/CanvasLayer/HUD/Bar/HP/HP1/Sprite, 2: $Hero/CanvasLayer/HUD/Bar/HP/HP2/Sprite, 3: $Hero/CanvasLayer/HUD/Bar/HP/HP3/Sprite, 4: $Hero/CanvasLayer/HUD/Bar/HP/HP4/Sprite}
const HPtype = {"Empty": 0, "CommonFull": 1}

@onready var particleGenFollowNode = $Hero.get_child(4)
@onready var particleNode = $Crest/Particles/ForeGround
@onready var particle2Node = $Crest/Particles/BackGround
var sinTimer = 0

func set_camera_position() -> void:
	var body = $Hero/Body
	var camera = $Hero/Camera2D
	var left = camera.limit_left
	var right = camera.limit_right
	var bottom = camera.limit_bottom
	var top = camera.limit_top
	

	var cameraSpeed = (body.position - camera.position)
	
	var viewSize = get_viewport_rect().size
	var halfView = viewSize * 0.5
	
	var targetPoint = camera.position + cameraSpeed
	targetPoint = Vector2(
		clamp(targetPoint.x, left + halfView.x, right - halfView.x),
		clamp(targetPoint.y, top + halfView.y, bottom - halfView.y)
	)

	var distanceCameraToHero = camera.position.distance_to(body.position)
	var smoothSpeed = 0.03
	if distanceCameraToHero > 5:
		camera.position = camera.position.lerp(targetPoint, smoothSpeed)

func particle_follow() -> void:
	particleNode.position = particleGenFollowNode.position + Vector2(-900, -540) + $Hero.position
	particle2Node.position = particleGenFollowNode.position + Vector2(-900, -540) + $Hero.position

func _process(_delta: float) -> void:
	for i in range(GlobalVars.health):
		HP[i + 1].frame = HPtype["CommonFull"]
	for i in range(4 - GlobalVars.health):
		HP[4 - i].frame = HPtype["Empty"]

func _physics_process(delta: float) -> void:
	set_camera_position()
	sinTimer += delta * 2.5
	if sinTimer >= 6.28:
		sinTimer = 0
	particle_follow()
