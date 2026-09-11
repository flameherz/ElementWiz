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
@export var exp_reward: float = 50.0

@export_group("Ranged Attack")
@export var attack_interval: float = 3.5  # วินาทีระหว่างการโจมตีระยะไกลแต่ละครั้ง
@export var attack_damage: float = 25.0
@export var attack_radius: float = 70.0
@export var telegraph_duration: float = 1.0  # เวลาที่วงเตือนขึ้นก่อนโจมตีจริง

var current_hp: float
var player: Node2D = null
var is_phase2: bool = false
var attack_timer: float = 0.0

const TelegraphScript := preload("res://telegraph_attack.gd")


func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")
	attack_timer = attack_interval

	# ทำให้ Boss เด่นชัดเจน แยกออกจากศัตรูทั่วไปทันที
	scale = Vector2(2.2, 2.2)
	modulate = Color(0.6, 0.3, 1.0)  # โทนม่วงเข้ม ต่างจาก golem สีส้มปกติ


func _physics_process(delta: float) -> void:
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

	attack_timer -= delta
	if attack_timer <= 0.0:
		perform_ranged_attack()
		attack_timer = attack_interval


func perform_ranged_attack() -> void:
	if not is_instance_valid(player):
		return

	var telegraph := Node2D.new()
	telegraph.set_script(TelegraphScript)
	get_tree().current_scene.add_child(telegraph)

	# โจมตีตำแหน่งผู้เล่น ณ ตอนเตือน ให้เวลาหลบก่อนโดนจริง
	telegraph.global_position = player.global_position
	telegraph.damage = attack_damage
	telegraph.radius = attack_radius
	telegraph.telegraph_duration = telegraph_duration


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
	attack_interval *= 0.6  # โจมตีระยะไกลถี่ขึ้น — เร่งจังหวะเดิม ไม่ใช่ท่าใหม่
	modulate = Color(1.3, 0.6, 0.6)  # เปลี่ยนสีให้เห็นชัดว่าเข้า phase 2 แล้ว


func die() -> void:
	if is_instance_valid(player) and player.has_method("gain_exp"):
		player.gain_exp(exp_reward)
	defeated.emit()
	queue_free()
