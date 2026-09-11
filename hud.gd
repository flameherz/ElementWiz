extends CanvasLayer

# ==========================================
# HUD.gd — HP bar + survival timer + Game Over screen
# แนบสคริปต์นี้ไว้ที่ CanvasLayer node ใน Main scene
#
# ต้องมี child nodes:
#   HPBar (ProgressBar)
#   TimerLabel (Label)
#   GameOverPanel (Control) — ซ่อนไว้ตอนเริ่มเกม (Visible = off)
#     ├── FinalTimeLabel (Label)
#     └── RestartButton (Button)
# ==========================================

@onready var hp_bar: ProgressBar = $HPBar
@onready var timer_label: Label = $TimerLabel
@onready var game_over_panel: Control = $GameOverPanel
@onready var final_time_label: Label = $GameOverPanel/FinalTimeLabel
@onready var restart_button: Button = $GameOverPanel/RestartButton
@onready var element_tracker: HBoxContainer = $ElementTracker
@onready var fusion_popup: Label = $FusionPopup
@onready var flash_overlay: ColorRect = $FlashOverlay

var elapsed_time: float = 0.0
var element_labels: Dictionary = {}
const FUSION_READY_COUNT := 3


func _ready() -> void:
	game_over_panel.visible = false

	# ทำให้ HUD กับปุ่ม restart ยังทำงานได้แม้เกม pause อยู่
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	restart_button.pressed.connect(_on_restart_pressed)

	build_element_tracker()

	fusion_popup.modulate.a = 0.0
	flash_overlay.color.a = 0.0

	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.died.connect(_on_player_died)
		player.element_changed.connect(_on_element_changed)
		player.fusion_triggered.connect(_on_fusion_triggered)
		_on_player_health_changed(player.current_hp, player.max_hp)


func build_element_tracker() -> void:
	# สร้าง entry ธาตุทั้ง 8 ชนิดใน element_tracker แบบ dynamic
	# แต่ละ entry คือ VBoxContainer เล็กๆ: กล่องสี (ColorRect) + ตัวเลข (Label)
	for element in Elements.Element.values():
		var entry := VBoxContainer.new()

		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(24, 24)
		swatch.color = Elements.COLOR[element]
		entry.add_child(swatch)

		var count_label := Label.new()
		count_label.text = "0"
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entry.add_child(count_label)

		element_tracker.add_child(entry)
		element_labels[element] = count_label


func _on_element_changed(element_type: Elements.Element, count: int) -> void:
	if not element_labels.has(element_type):
		return
	var label: Label = element_labels[element_type]
	label.text = str(count)
	# เน้นสีทองตอนใกล้ครบ fusion
	if count >= FUSION_READY_COUNT:
		label.modulate = Color(1.0, 0.85, 0.2)
	else:
		label.modulate = Color(1.0, 1.0, 1.0)


func _process(delta: float) -> void:
	elapsed_time += delta
	timer_label.text = format_time(elapsed_time)


func format_time(time_seconds: float) -> String:
	var minutes := int(time_seconds) / 60
	var seconds := int(time_seconds) % 60
	return "%02d:%02d" % [minutes, seconds]


func _on_player_health_changed(current_hp: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp


func _on_player_died() -> void:
	get_tree().paused = true
	final_time_label.text = "รอดชีวิตได้: %s" % format_time(elapsed_time)
	game_over_panel.visible = true


func _on_fusion_triggered(_element_a: Elements.Element, _element_b: Elements.Element, fusion_name: String) -> void:
	fusion_popup.text = "✨ ฟิวชั่น: %s ✨" % fusion_name

	# แฟลชวาบทั้งจอ
	flash_overlay.color.a = 0.25
	var flash_tween := create_tween()
	flash_tween.tween_property(flash_overlay, "color:a", 0.0, 0.3)

	# ข้อความ popup โผล่มาแล้วค้างไว้สักครู่ก่อนจางหาย
	fusion_popup.modulate.a = 1.0
	fusion_popup.scale = Vector2(0.7, 0.7)
	var popup_tween := create_tween()
	popup_tween.tween_property(fusion_popup, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	popup_tween.tween_interval(1.2)
	popup_tween.tween_property(fusion_popup, "modulate:a", 0.0, 0.5)


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
