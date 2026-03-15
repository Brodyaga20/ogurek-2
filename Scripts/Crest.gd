extends Node2D

@onready var particleGenFollowNode = $Hero.get_child(4)
@onready var particleNode = $Particles/ForeGround
@onready var particle2Node = $Particles/BackGround
var sinTimer = 0

func set_camera_position() -> void:
	var body = $Hero.get_child(3)
	var camera = $Hero/Camera2D
	var cameraSpeed = (body.position - camera.position)/55
	print(cameraSpeed)
	var distanceCameraToHero = camera.position.distance_to(body.position)
	if distanceCameraToHero > 5:
		camera.position = lerp(camera.position, camera.position+cameraSpeed, 2)

func particle_follow() -> void:
	particleNode.position = particleGenFollowNode.position + Vector2(-900, -540) + $Hero.position
	particle2Node.position = particleGenFollowNode.position + Vector2(-900, -540) + $Hero.position

func _physics_process(delta: float) -> void:
	set_camera_position()
	sinTimer += delta * 2.5
	if sinTimer >= 6.28:
		sinTimer = 0
	particle_follow()
