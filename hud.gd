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
@onready var wave_label: Label = $WaveLabel
@onready var wave_manager: Node = get_node("../WaveManager")
@onready var currency_label: Label = $GameOverPanel/CurrencyLabel
@onready var hp_upgrade_button: Button = $GameOverPanel/HPUpgradeButton
@onready var damage_upgrade_button: Button = $GameOverPanel/DamageUpgradeButton
@onready var levelup_panel: Control = $LevelUpPanel
@onready var choice1_button: Button = $LevelUpPanel/Choice1Button
@onready var choice2_button: Button = $LevelUpPanel/Choice2Button
@onready var choice3_button: Button = $LevelUpPanel/Choice3Button

var current_level_up_choices: Array = []

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

	wave_manager.wave_changed.connect(_on_wave_changed)
	wave_manager.victory.connect(_on_victory)
	_on_wave_changed(wave_manager.current_wave)

	hp_upgrade_button.pressed.connect(_on_hp_upgrade_pressed)
	damage_upgrade_button.pressed.connect(_on_damage_upgrade_pressed)

	levelup_panel.visible = false
	levelup_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	choice1_button.pressed.connect(func(): _on_choice_pressed(0))
	choice2_button.pressed.connect(func(): _on_choice_pressed(1))
	choice3_button.pressed.connect(func(): _on_choice_pressed(2))

	if player:
		player.leveled_up.connect(_on_leveled_up)


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
	var earned: int = wave_manager.current_wave * 5 + int(elapsed_time / 10.0)
	SaveManager.add_currency(earned)
	final_time_label.text = "รอดชีวิตได้: %s\nได้รับ %d เหรียญ" % [format_time(elapsed_time), earned]
	game_over_panel.visible = true
	refresh_shop_ui()


func _on_fusion_triggered(_element_a: Elements.Element, _element_b: Elements.Element, fusion_name: String) -> void:
	fusion_popup.text = "✨ ฟิวชั่น: %s ✨" % fusion_name

	# แฟลชวาบทั้งจอ
	flash_overlay.color.a = 0.6
	var flash_tween := create_tween()
	flash_tween.tween_property(flash_overlay, "color:a", 0.0, 0.3)

	# ข้อความ popup โผล่มาแล้วค้างไว้สักครู่ก่อนจางหาย
	fusion_popup.modulate.a = 1.0
	fusion_popup.scale = Vector2(0.7, 0.7)
	var popup_tween := create_tween()
	popup_tween.tween_property(fusion_popup, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	popup_tween.tween_interval(1.2)
	popup_tween.tween_property(fusion_popup, "modulate:a", 0.0, 0.5)


func _on_wave_changed(wave_number: int) -> void:
	wave_label.text = "เวฟ %d/10" % wave_number


func _on_victory() -> void:
	get_tree().paused = true
	SaveManager.record_boss_defeat()
	var earned: int = 100 + wave_manager.current_wave * 5
	SaveManager.add_currency(earned)
	final_time_label.text = "ชนะแล้ว! เอาชนะบอสสำเร็จ ใช้เวลา %s\nได้รับ %d เหรียญ" % [format_time(elapsed_time), earned]
	game_over_panel.visible = true
	refresh_shop_ui()


func refresh_shop_ui() -> void:
	currency_label.text = "เหรียญสะสม: %d" % SaveManager.currency
	hp_upgrade_button.text = "ซื้อ +%.0f HP ถาวร (%d เหรียญ)" % [SaveManager.HP_PER_LEVEL, SaveManager.get_hp_upgrade_cost()]
	damage_upgrade_button.text = "ซื้อ +%.0f DMG ถาวร (%d เหรียญ)" % [SaveManager.DAMAGE_PER_LEVEL, SaveManager.get_damage_upgrade_cost()]


func _on_hp_upgrade_pressed() -> void:
	SaveManager.buy_hp_upgrade()
	refresh_shop_ui()


func _on_damage_upgrade_pressed() -> void:
	SaveManager.buy_damage_upgrade()
	refresh_shop_ui()


func _on_leveled_up(choices: Array) -> void:
	current_level_up_choices = choices
	get_tree().paused = true

	var buttons: Array[Button] = [choice1_button, choice2_button, choice3_button]
	for i in choices.size():
		var choice: Dictionary = choices[i]
		buttons[i].text = "%s\n%s" % [choice["name"], choice["description"]]
		buttons[i].visible = true

	levelup_panel.visible = true


func _on_choice_pressed(index: int) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and current_level_up_choices.size() > index:
		var choice: Dictionary = current_level_up_choices[index]
		var apply_fn: Callable = choice["apply"]
		apply_fn.call(player)

	levelup_panel.visible = false
	get_tree().paused = false


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
