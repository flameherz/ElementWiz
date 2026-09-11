extends Area2D

# ==========================================
# Projectile.gd — กระสุนพุ่งไปยังตำแหน่งเป้าหมาย
# ==========================================

@export var speed: float = 150.0
@export var damage: float = 10.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.ZERO
var time_alive: float = 0.0


func setup(target_position: Vector2) -> void:
	direction = (target_position - global_position).normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	time_alive += delta

	if time_alive >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemies") and parent.has_method("take_damage"):
		parent.take_damage(damage)
		queue_free()
