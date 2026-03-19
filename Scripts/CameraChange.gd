extends Node2D

@export var topLimit1 : int
@export var bottomLimit1 : int
@export var leftLimit1 : int
@export var rightLimit1 : int

@export var topLimit2 : int
@export var bottomLimit2 : int
@export var leftLimit2 : int
@export var rightLimit2 : int

var newTopLimit 
var newBottomLimit
var newLeftLimit
var newRightLimit

@onready var camera = get_parent().get_parent().get_node("Hero/Camera2D")
var changingTimer : float = 0

func _process(delta: float) -> void:
	update_changing_timer(delta)

func update_changing_timer(delta: float) -> void:
	if changingTimer > 0:
		changingTimer -= delta
		camera.limit_top = lerp(camera.limit_top, newTopLimit, 0.01)
		camera.limit_bottom = lerp(camera.limit_bottom, newBottomLimit, 0.01)
		camera.limit_left = lerp(camera.limit_left, newLeftLimit, 0.01)
		camera.limit_right = lerp(camera.limit_right, newRightLimit, 0.01)


func body_enter_from_right(body: Node2D) -> void:
	if body.is_in_group("Player"):
		changingTimer = 2
		newTopLimit = topLimit1
		newBottomLimit = bottomLimit1
		newLeftLimit = leftLimit1
		newRightLimit = rightLimit1


func body_enter_from_left(body: Node2D) -> void:
	if body.is_in_group("Player"):
		changingTimer = 2
		newTopLimit = topLimit2
		newBottomLimit = bottomLimit2
		newLeftLimit = leftLimit2
		newRightLimit = rightLimit2
