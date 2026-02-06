extends StaticBody2D
var bodyCountOnPlatform = 0
var settle_timer = 0
var startPos := Vector2(0, 0)
var settlePos := Vector2(0, 0)
@export var upperOffset: float
@export var sideOffset: float
@export var lowerSide: float
@export var mass: int
enum types {FLOATING_STONE, STONE}
enum hitboxTypes {BOX, TRAPECIA, SPECIFIC}
@export var type: types
@export var hitboxType: hitboxTypes
@onready var sprite = $Sprite



@export var texture: Texture2D

func _ready():
	sprite.texture = texture
	startPos = position
	match hitboxType:
		hitboxTypes.BOX:
			create_box_collision()
		hitboxTypes.TRAPECIA:
			create_trapecia_collision()
	match type:
		types.FLOATING_STONE:
			create_settle_area()
	
func clear_collision() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()

func clear_areas() -> void:
	for child in get_children():
		if child is Area2D:
			child.queue_free()

func create_box_collision() -> void:
	clear_collision()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var texture_size = sprite.texture.get_size()
	shape.size = texture_size - Vector2(0, upperOffset)
	collision.shape = shape
	add_child(collision)

func create_trapecia_collision() -> void:
	clear_collision()
	var polygon = CollisionPolygon2D.new()
	var xSize = sprite.texture.get_width() - sideOffset
	var ySize = sprite.texture.get_height() - upperOffset

	polygon.polygon = PackedVector2Array([
		Vector2((xSize - lowerSide)/2, ySize),
		Vector2(0, 0),
		Vector2(xSize, 0),
		Vector2((xSize + lowerSide)/2, ySize)
	])
	polygon.position.x -= xSize/2
	polygon.position.y -= ySize/2
	add_child(polygon)

func create_settle_area() -> void:
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	shape.size.x = texture.get_width() - sideOffset
	shape.size.y = 4
	collision.shape = shape
	collision.position.y = (float(-texture.get_height()) + upperOffset)/2 + 1
	area.add_child(collision)
	area.body_entered.connect(_body_entered)
	area.body_exited.connect(_body_exited)
	add_child(area)
	settlePos = startPos + Vector2(0, 100/float(mass))

func settle() -> void:
	settle_timer += 0.8

func unsettle() -> void:
	settle_timer -= 0.8

func _body_entered(_body: Node2D) -> void:
	if bodyCountOnPlatform == 1:
		settle()
	bodyCountOnPlatform += 1

func _body_exited(_body: Node2D) -> void:
	bodyCountOnPlatform -= 1
	if bodyCountOnPlatform == 1:
		unsettle()

func _physics_process(delta: float) -> void:
	if abs(settle_timer) <= 0.01:
		settle_timer = 0
	if settle_timer > 0:
		settle_timer -= delta
		position = lerp(position, settlePos, 0.05)
	elif settle_timer < 0:
		position = lerp(position, startPos, 0.05)
		settle_timer += delta
