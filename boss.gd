extends CharacterBody2D

# ==========================================
# Boss.gd — บอสเวฟ 10 (จบรัน)
# Phase 2 = เร่งจังหวะเดิม ไม่ใช่ mechanic ใหม่ (ตามหลักการที่วางไว้ใน GDD)
# ==========================================

signal defeated

@export var max_hp: float = 150.0
@export var move_speed: float = 35.0
@export var contact_damage: float = 15.0
@export var phase2_hp_threshold: float = 0.5  # เปลี่ยนเป็น phase 2 เมื่อ HP ต่ำกว่า 50%

var current_hp: float
var player: Node2D = null
var is_phase2: bool = false


func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var direction := (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(contact_damage)


func take_damage(amount: float) -> void:
	current_hp -= amount

	if not is_phase2 and current_hp <= max_hp * phase2_hp_threshold:
		enter_phase2()

	if current_hp <= 0:
		die()


func enter_phase2() -> void:
	is_phase2 = true
	move_speed *= 1.6
	contact_damage *= 1.3
	modulate = Color(1.3, 0.6, 0.6)  # เปลี่ยนสีให้เห็นชัดว่าเข้า phase 2 แล้ว


func die() -> void:
	defeated.emit()
	queue_free()
