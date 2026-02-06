extends Node2D

@export var size: Vector2

func _ready() -> void:
	create_area()

func create_area():
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
		
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(_body_entered)
	add_child(area)


func _body_entered(body: Node2D):
	if body.is_in_group("Player"):
		#print(str(position - body.position) + str(body.get_parent().position))
		body.set_checkpoint(body.position)
