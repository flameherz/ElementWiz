extends Node

# ==========================================
# WaveManager.gd — คุมจังหวะเวฟทั้งหมดของเกม
# วางเป็น sibling ของ Player, EnemySpawner, HUD ใต้ Main
# ==========================================

signal wave_changed(wave_number: int)
signal victory

@export var wave_duration: float = 30.0
@export var total_waves: int = 10
@export var elite_wave: int = 5
@export var boss_wave: int = 10

var current_wave: int = 1
var wave_timer: float = 0.0
var boss_wave_active: bool = false

@onready var spawner: Node2D = get_node("../EnemySpawner")


func _ready() -> void:
	wave_timer = wave_duration
	wave_changed.emit(current_wave)
	spawner.boss_spawned.connect(_on_boss_spawned)


func _process(delta: float) -> void:
	if boss_wave_active:
		return  # เวฟบอส ไม่นับเวลาเปลี่ยนเวฟอัตโนมัติ ต้องฆ่าบอสก่อนถึงจะจบ

	wave_timer -= delta
	if wave_timer <= 0.0:
		advance_wave()


func advance_wave() -> void:
	current_wave += 1
	wave_timer = wave_duration
	wave_changed.emit(current_wave)
	spawner.set_wave_difficulty(current_wave)

	if current_wave == elite_wave:
		spawner.spawn_elite()
	elif current_wave == boss_wave:
		start_boss_wave()


func start_boss_wave() -> void:
	boss_wave_active = true
	spawner.spawn_boss()


func _on_boss_spawned(boss: Node) -> void:
	boss.defeated.connect(func(): victory.emit())
