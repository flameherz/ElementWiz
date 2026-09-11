extends CharacterBody2D

# ==========================================
# Player.gd — ElementWiz core prototype
# เดินได้ด้วย WASD/ลูกศร + ยิงอัตโนมัติใส่ศัตรูที่ใกล้สุด
# ==========================================

@export var move_speed: float = 150.0
@export var attack_range: float = 250.0
@export var attack_cooldown: float = 0.6  # วินาทีระหว่างการยิงแต่ละครั้ง

var attack_timer: float = 0.0
var current_target: Node2D = null

@onready var projectile_scene := preload("res://projectile.tscn")

func _physics_process(delta: float) -> void:
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
