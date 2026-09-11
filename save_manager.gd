extends Node

# ==========================================
# SaveManager.gd — จัดการข้อมูลถาวรข้ามรัน (currency, upgrade, boss codex)
# ต้องตั้งเป็น Autoload ชื่อ "SaveManager" ใน Project Settings
# ==========================================

const SAVE_PATH := "user://save_data.json"

const HP_UPGRADE_COST_BASE := 20
const DAMAGE_UPGRADE_COST_BASE := 25
const HP_PER_LEVEL := 10.0
const DAMAGE_PER_LEVEL := 2.0

var currency: int = 0
var hp_upgrade_level: int = 0
var damage_upgrade_level: int = 0
var bosses_defeated: int = 0


func _ready() -> void:
	load_data()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if data:
		currency = data.get("currency", 0)
		hp_upgrade_level = data.get("hp_upgrade_level", 0)
		damage_upgrade_level = data.get("damage_upgrade_level", 0)
		bosses_defeated = data.get("bosses_defeated", 0)


func save_data() -> void:
	var data := {
		"currency": currency,
		"hp_upgrade_level": hp_upgrade_level,
		"damage_upgrade_level": damage_upgrade_level,
		"bosses_defeated": bosses_defeated,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func add_currency(amount: int) -> void:
	currency += amount
	save_data()


func get_hp_bonus() -> float:
	return hp_upgrade_level * HP_PER_LEVEL


func get_damage_bonus() -> float:
	return damage_upgrade_level * DAMAGE_PER_LEVEL


func get_hp_upgrade_cost() -> int:
	return HP_UPGRADE_COST_BASE + (hp_upgrade_level * 10)


func get_damage_upgrade_cost() -> int:
	return DAMAGE_UPGRADE_COST_BASE + (damage_upgrade_level * 15)


func buy_hp_upgrade() -> bool:
	var cost := get_hp_upgrade_cost()
	if currency >= cost:
		currency -= cost
		hp_upgrade_level += 1
		save_data()
		return true
	return false


func buy_damage_upgrade() -> bool:
	var cost := get_damage_upgrade_cost()
	if currency >= cost:
		currency -= cost
		damage_upgrade_level += 1
		save_data()
		return true
	return false


func record_boss_defeat() -> void:
	bosses_defeated += 1
	save_data()
