extends Node2D

# ==========================================
# TelegraphAttack.gd — วงเตือนก่อนโจมตี (Boss ranged attack)
# ไม่ต้องมี scene แยก — สร้างจากโค้ดล้วนๆ ด้วย set_script()
# วาดวงกลมขยายขึ้นเรื่อยๆ ระหว่าง telegraph_duration แล้วเช็คว่าผู้เล่นยังยืนอยู่ในวงไหมตอนจบ
# ==========================================

@export var radius: float = 60.0
@export var telegraph_duration: float = 1.0
@export var damage: float = 25.0

var time_elapsed: float = 0.0
var target_player: Node2D = null


func _ready() -> void:
	target_player = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	time_elapsed += delta
	queue_redraw()

	if time_elapsed >= telegraph_duration:
		trigger_attack()


func _draw() -> void:
	var progress: float = clamp(time_elapsed / telegraph_duration, 0.0, 1.0)
	var current_radius: float = radius * progress

	# พื้นที่วงกลมค่อยๆ ขยายเต็ม (บอกว่าจะโดนตรงไหน)
	draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.15, 0.1, 0.35))
	# เส้นขอบวงกลมเต็มขนาดจริง (บอกขอบเขตอันตรายตั้งแต่ต้น ให้วางแผนหลบทัน)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.2, 0.1, 0.9), 2.5)


func trigger_attack() -> void:
	if is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		if dist <= radius and target_player.has_method("take_damage"):
			target_player.take_damage(damage)
	queue_free()
