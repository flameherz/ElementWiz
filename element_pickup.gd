extends Area2D

# ==========================================
# ElementPickup.gd — ไอเทมธาตุที่ดรอปจากศัตรู
# ลอยเข้าหาผู้เล่นเมื่อเข้าใกล้ (magnet effect)
# ==========================================

@export var element_type: Elements.Element = Elements.Element.FIRE
@export var magnet_radius: float = 120.0
@export var magnet_speed: float = 250.0
@export var lifetime: float = 8.0  # หายไปเองถ้าไม่ถูกเก็บภายในเวลานี้

var player: Node2D = null
var time_alive: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if sprite:
		sprite.modulate = Elements.COLOR[element_type]


func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var dist := global_position.distance_to(player.global_position)
	if dist <= magnet_radius:
		var direction := (player.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("collect_element"):
		body.collect_element(element_type)
		queue_free()
