class_name Elements
extends RefCounted

# ==========================================
# Elements.gd — นิยามธาตุกลาง ใช้ร่วมกันทุกสคริปต์
# เรียกใช้จากที่อื่นผ่าน Elements.Element.FIRE เป็นต้น
# ==========================================

enum Element {
	FIRE,
	WATER,
	EARTH,
	WIND,
	LIGHTNING,
	ICE,
	LIGHT,
	DARK,
}

const DISPLAY_NAME := {
	Element.FIRE: "ไฟ",
	Element.WATER: "น้ำ",
	Element.EARTH: "ดิน",
	Element.WIND: "ลม",
	Element.LIGHTNING: "สายฟ้า",
	Element.ICE: "น้ำแข็ง",
	Element.LIGHT: "แสง",
	Element.DARK: "ความมืด",
}

const COLOR := {
	Element.FIRE: Color(1.0, 0.3, 0.1),
	Element.WATER: Color(0.2, 0.5, 1.0),
	Element.EARTH: Color(0.5, 0.35, 0.15),
	Element.WIND: Color(0.7, 1.0, 0.7),
	Element.LIGHTNING: Color(1.0, 0.9, 0.2),
	Element.ICE: Color(0.6, 0.9, 1.0),
	Element.LIGHT: Color(1.0, 1.0, 0.7),
	Element.DARK: Color(0.4, 0.1, 0.5),
}

# คู่ธาตุตรงข้าม — ใช้เช็ค synergy (ผู้เล่นสะสมธาตุตรงข้ามกับศัตรูเยอะสุด = ดรอปโบนัส)
const OPPOSITE := {
	Element.FIRE: Element.WATER,
	Element.WATER: Element.FIRE,
	Element.EARTH: Element.WIND,
	Element.WIND: Element.EARTH,
	Element.LIGHTNING: Element.ICE,
	Element.ICE: Element.LIGHTNING,
	Element.LIGHT: Element.DARK,
	Element.DARK: Element.LIGHT,
}


static func get_opposite(element: Element) -> Element:
	return OPPOSITE[element]

# สูตร fusion — key คือคู่ธาตุ (เรียงตาม enum value น้อยไปมาก), value คือชื่อผลลัพธ์
# ยังไม่ผูก effect จริง แค่นิยามชื่อไว้ก่อนสำหรับ prototype นี้
const FUSION_RECIPES := {
	[Element.FIRE, Element.WATER]: "ไอน้ำ",
	[Element.FIRE, Element.WIND]: "พายุเพลิง",
	[Element.WATER, Element.ICE]: "หิมะ",
	[Element.EARTH, Element.LIGHTNING]: "แม่เหล็ก",
}


static func get_fusion_name(element_a: Element, element_b: Element) -> String:
	var pair := [element_a, element_b] if element_a < element_b else [element_b, element_a]
	if FUSION_RECIPES.has(pair):
		return FUSION_RECIPES[pair]
	return "%s+%s ผสม" % [DISPLAY_NAME[element_a], DISPLAY_NAME[element_b]]


static func get_random_element() -> Element:
	return Element.values()[randi() % Element.size()]
