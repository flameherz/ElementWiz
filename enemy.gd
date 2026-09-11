extends CharacterBody2D

# ==========================================
# Enemy.gd — ศัตรูพื้นฐาน เดินตรงเข้าใส่ผู้เล่น (Swarmer archetype)
# ==========================================

@export var move_speed: float = 60.0
@export var max_hp: float = 20.0
@export var contact_damage: float = 5.0

var current_hp: float
var player: Node2D = null


func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var direction := (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# เช็คว่าชนผู้เล่นไหมหลังขยับ (CharacterBody2D ไม่มี signal body_entered ให้ใช้
	# เลยเช็คจาก collision ของ move_and_slide แทน)
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(contact_damage)


func take_damage(amount: float) -> void:
	current_hp -= amount
	if current_hp <= 0:
		die()


func die() -> void:
	# TODO: ดรอปธาตุตรงนี้ตอนใส่ elemental system
	queue_free()


# เรียกจาก signal body_entered ของ Area2D (child) เท่านั้น — สำหรับตรวจจับโดนกระสุน
func _on_bullet_area_body_entered(_body: Node2D) -> void:
	pass  # ไม่ต้องทำอะไร เพราะ take_damage() ถูกเรียกตรงจาก projectile.gd อยู่แล้ว
