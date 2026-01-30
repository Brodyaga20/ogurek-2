extends Node2D

@onready var particleGenFollowNode = $Hero.get_child(4)
@onready var particleNode = $Particles
@onready var particle2Node = $Particles2
var sinTimer = 0

func particle_follow() -> void:
	particleNode.position = particleGenFollowNode.position + Vector2(-900, -540) + $Hero.position
	particle2Node.position = particleGenFollowNode.position + Vector2(-900, -540) + $Hero.position

func _physics_process(delta: float) -> void:
	sinTimer += delta * 2.5
	if sinTimer >= 6.28:
		sinTimer = 0
	particle_follow()
