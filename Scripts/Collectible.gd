extends Node2D

@export var texture: Texture2D
@export var type: String
enum styles {HOVERING, FALLING, NO_GRAVITY}
@export var style: String
@onready var sprite = $Sprite2D

func _ready():
	sprite.texture = texture
	set_collision()

func set_collision() -> void:
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var texture_size = texture.get_size()
	shape.size = texture_size * 0.2
	collision.shape = shape
	area.add_child(collision)
	area.body_entered.connect(body_enter_collect)
	add_child(area)
	pass


func body_enter_collect(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.get_parent().collect(type)
	queue_free()
