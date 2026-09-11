extends Node2D

# ==========================================
# EnemySpawner.gd — spawn ศัตรูรอบขอบจอเป็นจังหวะ
# วาง node นี้ที่ตำแหน่ง (0,0) ของ scene หลัก
# ==========================================

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.5  # วินาทีต่อการ spawn 1 ตัว
@export var spawn_radius: float = 500.0  # ระยะห่างจากผู้เล่นตอน spawn

var spawn_timer: float = 0.0
var player: Node2D = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_enemy()
		spawn_timer = spawn_interval


func spawn_enemy() -> void:
	if not enemy_scene or not is_instance_valid(player):
		return

	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)

	# สุ่มตำแหน่ง spawn รอบๆ ผู้เล่น เป็นวงกลม
	var angle := randf() * TAU
	var offset := Vector2(cos(angle), sin(angle)) * spawn_radius
	enemy.global_position = player.global_position + offset


# เรียกใช้ตอนขึ้น wave ใหม่ เพื่อเร่งความถี่การ spawn (ใช้ตอนต่อ wave system ทีหลัง)
func set_wave_difficulty(wave_number: int) -> void:
	spawn_interval = max(0.3, 1.5 - (wave_number * 0.12))
