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
signal leveled_up(choices: Array)

var element_counts: Dictionary = {}
var level: int = 1
var exp: float = 0.0
var exp_to_next: float = 10.0

const FUSION_THRESHOLD := 3

var UPGRADE_POOL := [
	{"name": "เร่งฝีเท้า", "description": "ความเร็วเดิน +20%", "apply": func(p): p.upgrade_move_speed(1.2)},
	{"name": "พลังทำลายล้าง", "description": "พลังโจมตี +3", "apply": func(p): p.upgrade_damage(3.0)},
	{"name": "จังหวะไว", "description": "ยิงเร็วขึ้น 15%", "apply": func(p): p.upgrade_attack_speed(0.85)},
	{"name": "พลังชีวิตเพิ่มพูน", "description": "พลังชีวิตสูงสุด +20", "apply": func(p): p.upgrade_max_hp(20.0)},
	{"name": "สายตาไกล", "description": "ระยะยิงไกลขึ้น +50", "apply": func(p): p.upgrade_attack_range(50.0)},
]

@export var base_projectile_damage: float = 10.0
var bonus_damage: float = 0.0

@onready var projectile_scene := preload("res://projectile.tscn")

func _ready() -> void:
	max_hp += SaveManager.get_hp_bonus()
	base_projectile_damage += SaveManager.get_damage_bonus()
	current_hp = max_hp
	health_changed.emit(current_hp, max_hp)
	for element in Elements.Element.values():
		element_counts[element] = 0


func collect_element(element_type: Elements.Element) -> void:
	element_counts[element_type] += 1
	element_changed.emit(element_type, element_counts[element_type])
	check_for_fusion(element_type)


func get_dominant_element():
	var best_element = null
	var best_count: int = 0
	for element in Elements.Element.values():
		if element_counts[element] > best_count:
			best_count = element_counts[element]
			best_element = element
	return best_element


func gain_exp(amount: float) -> void:
	exp += amount
	if exp >= exp_to_next:
		level_up()


func level_up() -> void:
	level += 1
	exp -= exp_to_next
	exp_to_next *= 1.3

	var pool: Array = UPGRADE_POOL.duplicate()
	pool.shuffle()
	var choices: Array = pool.slice(0, 3)
	leveled_up.emit(choices)


func upgrade_move_speed(multiplier: float) -> void:
	move_speed *= multiplier


func upgrade_damage(amount: float) -> void:
	base_projectile_damage += amount


func upgrade_attack_speed(multiplier: float) -> void:
	attack_cooldown *= multiplier


func upgrade_max_hp(amount: float) -> void:
	max_hp += amount
	current_hp += amount
	health_changed.emit(current_hp, max_hp)


func upgrade_attack_range(amount: float) -> void:
	attack_range += amount


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
