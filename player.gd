extends CharacterBody2D

# ==========================================
# Player.gd — ElementWiz core prototype
# เดินได้ด้วย WASD/ลูกศร + ยิงอัตโนมัติใส่ศัตรูที่ใกล้สุด
# ==========================================

@export var move_speed: float = 150.0
@export var attack_range: float = 400.0
@export var attack_cooldown: float = 0.6  # วินาทีระหว่างการยิงแต่ละครั้ง
@export var max_hp: float = 100.0
@export var invincibility_duration: float = 0.5  # วินาทีที่ป้องกันโดนซ้ำหลังโดนตี

var attack_timer: float = 0.0
var current_target: Node2D = null
var current_hp: float
var invincibility_timer: float = 0.0

signal health_changed(current_hp: float, max_hp: float)
signal died
signal element_changed(element_type: Elements.Element, count: int)
signal fusion_triggered(element_a: Elements.Element, element_b: Elements.Element, fusion_name: String)

var element_counts: Dictionary = {}

const FUSION_THRESHOLD := 3

@export var base_projectile_damage: float = 10.0
var bonus_damage: float = 0.0

@onready var projectile_scene := preload("res://projectile.tscn")

func _ready() -> void:
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
	for element in Elements.Element.values():
		element_counts[element] = 0


func collect_element(element_type: Elements.Element) -> void:
	element_counts[element_type] += 1
	element_changed.emit(element_type, element_counts[element_type])
	check_for_fusion(element_type)


func check_for_fusion(just_collected: Elements.Element) -> void:
	if element_counts[just_collected] < FUSION_THRESHOLD:
		return

	# หาธาตุอื่นที่ครบ 3 เหมือนกัน เพื่อจับคู่ fusion
	for element in Elements.Element.values():
		if element == just_collected:
			continue
		if element_counts[element] >= FUSION_THRESHOLD:
			do_fusion(just_collected, element)
			return


func do_fusion(element_a: Elements.Element, element_b: Elements.Element) -> void:
	element_counts[element_a] -= FUSION_THRESHOLD
	element_counts[element_b] -= FUSION_THRESHOLD
	element_changed.emit(element_a, element_counts[element_a])
	element_changed.emit(element_b, element_counts[element_b])

	var fusion_name := Elements.get_fusion_name(element_a, element_b)
	fusion_triggered.emit(element_a, element_b, fusion_name)
	bonus_damage += 2.0


func take_damage(amount: float) -> void:
	if invincibility_timer > 0.0:
		return  # ยังอยู่ในช่วงป้องกัน ไม่รับดาเมจซ้ำ

	current_hp -= amount
	current_hp = max(current_hp, 0.0)
	health_changed.emit(current_hp, max_hp)
	invincibility_timer = invincibility_duration

	if current_hp <= 0:
		died.emit()


func _physics_process(delta: float) -> void:
	if invincibility_timer > 0.0:
		invincibility_timer -= delta

	handle_movement()
	handle_auto_attack(delta)


func handle_movement() -> void:
	# รองรับทั้งคีย์บอร์ด (ทดสอบใน editor) และ joystick มือถือ (ผ่าน Input actions)
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_up", "move_down")

	velocity = input_dir.normalized() * move_speed
	move_and_slide()


func handle_auto_attack(delta: float) -> void:
	attack_timer -= delta

	# หาเป้าหมายใหม่ถ้ายังไม่มี หรือเป้าเดิมตายไปแล้ว
	if not is_instance_valid(current_target):
		current_target = find_nearest_enemy()

	if current_target and attack_timer <= 0.0:
		fire_projectile(current_target)
		attack_timer = attack_cooldown


func find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist := attack_range

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func fire_projectile(target: Node2D) -> void:
	if not is_instance_valid(target):
		return

	var proj = projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position
	proj.setup(target.global_position)
	proj.damage = base_projectile_damage + bonus_damage
