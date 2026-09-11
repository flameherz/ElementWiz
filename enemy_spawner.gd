extends Node2D

# ==========================================
# EnemySpawner.gd — spawn ศัตรูรอบขอบจอเป็นจังหวะ
# วาง node นี้ที่ตำแหน่ง (0,0) ของ scene หลัก
# ==========================================

@export var enemy_scene: PackedScene
@export var boss_scene: PackedScene
@export var spawn_interval: float = 1.5  # วินาทีต่อการ spawn 1 ตัว
@export var spawn_radius: float = 500.0  # ระยะห่างจากผู้เล่นตอน spawn

signal boss_spawned(boss_instance)

var spawn_timer: float = 0.0
var player: Node2D = null
var spawning_enabled: bool = true


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if not spawning_enabled:
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_enemy()
		spawn_timer = spawn_interval


func spawn_enemy() -> void:
	if not enemy_scene or not is_instance_valid(player):
		return

	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)

	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_radius
	enemy.global_position = player.global_position + offset
	enemy.element_type = Elements.get_random_element()
	enemy.apply_element_tint()


func spawn_elite() -> void:
	# Elite = ศัตรูปกติที่ยกสถานะขึ้น ไม่ต้องมี scene แยก
	if not enemy_scene or not is_instance_valid(player):
		return

	var elite = enemy_scene.instantiate()
	get_tree().current_scene.add_child(elite)

	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_radius * 0.6
	elite.global_position = player.global_position + offset
	elite.element_type = Elements.get_random_element()
	elite.apply_element_tint()

	elite.max_hp *= 3.0
	elite.current_hp = elite.max_hp
	elite.contact_damage *= 1.5
	elite.move_speed *= 0.8
	elite.exp_reward *= 4.0
	elite.scale = Vector2(1.6, 1.6)


func spawn_boss() -> void:
	if not boss_scene or not is_instance_valid(player):
		return

	spawning_enabled = false  # หยุด spawn ศัตรูทั่วไป โฟกัสที่บอสอย่างเดียว

	var boss = boss_scene.instantiate()
	get_tree().current_scene.add_child(boss)

	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_radius * 0.6
	boss.global_position = player.global_position + offset

	boss_spawned.emit(boss)


func set_wave_difficulty(wave_number: int) -> void:
	spawn_interval = max(0.6, 1.5 - (wave_number * 0.08))
