# Game Design Document
## ElementWiz

---

## 1. ภาพรวมโปรเจกต์

| หัวข้อ | รายละเอียด |
|---|---|
| Genre | Roguelite — Auto-battler / Survivor (แบบ Vampire Survivors, Brotato) |
| Platform | Mobile |
| Art Style | Pixel Art 2D |
| Engine | Godot |
| ทีม | Solo dev — เน้น visual + music/audio เป็นหลัก |
| Session Length | 10 เวฟ x 30 วินาที (~5 นาที/รัน) |
| Theme | นักเวทย์ผสมธาตุเวทมนตร์ (Elemental Fusion Wizard) |

**Core Concept:** ผู้เล่นควบคุมนักเวทย์ที่เก็บธาตุเวทมนตร์ระหว่างต่อสู้กับคลื่นศัตรู เมื่อธาตุชนิดเดียวกันครบ 3 ชิ้น จะเกิดการ "ฟิวชั่น" อัตโนมัติกลายเป็นเวทย์ขั้นสูงที่ทรงพลังและมี visual effect โดดเด่น

---

## 2. Core Loop

1. **เริ่มรอบ** — เลือกตัวละคร (จาก 6 ตัวที่ปลดล็อกแล้ว)
2. **แต่ละเวฟ (30 วิ)** — ศัตรูไล่ตะกละมากขึ้นเรื่อยๆ ผู้เล่นขยับหลบด้วย virtual joystick + โจมตีอัตโนมัติ
3. **เก็บธาตุ** — ศัตรูดรอปธาตุ, สะสมครบ 3 ชิ้นของธาตุเดียวกัน → auto-fusion
4. **Level-up popup** — เลือก 1 ใน 3 ตัวเลือก (skill/ธาตุ/passive)
5. **เวฟ 5** — เจอ Elite (mini-boss ธาตุสุ่ม, 1 phase)
6. **เวฟ 10** — เจอ Boss เต็ม (ธาตุอื่นจาก elite, 2 phase) → จบรัน
7. **ตาย/จบรัน** — ได้ currency + reward ถาวร กลับไปอัพเกรดแบบ meta-progression

---

## 3. ระบบธาตุ (Elemental System)

### 3.1 ธาตุพื้นฐาน (8 ธาตุ)
🔥 ไฟ · 💧 น้ำ · 🌍 ดิน · 🌪️ ลม · ⚡ สายฟ้า · 🧊 น้ำแข็ง · ☀️ แสง · 🌑 ความมืด

### 3.2 กลไก Fusion
- **Threshold:** สะสมธาตุชนิดเดียวกันครบ **3 ชิ้น** → พร้อมฟิวชั่น
- **Trigger:** **Auto-fusion** — เมื่อมี 2 ธาตุพร้อมฟิวชั่นพร้อมกัน จะรวมกันทันทีอัตโนมัติ
- **Presentation:** freeze frame สั้นๆ (~0.5 วิ) + flash effect เพื่อสร้างความรู้สึก "ปัง"

### 3.3 ตัวอย่างสูตร Fusion
| ธาตุ A | ธาตุ B | ผลลัพธ์ |
|---|---|---|
| ไฟ | น้ำ | ไอน้ำ (DoT + บังการมองเห็นศัตรู) |
| ไฟ | ลม | พายุเพลิง (AOE กว้างขึ้น) |
| น้ำ | น้ำแข็ง | หิมะ (freeze + slow) |
| ดิน | สายฟ้า | แม่เหล็ก (ดึงศัตรูเข้ากลุ่ม) |

### 3.4 Passive Skill
ระบบแยกจากธาตุ เป็น skill ติดตัว (เช่น +HP, +move speed, +pickup range) — ผูกกับตัวละครแต่ละตัวเป็นจุดเด่นเฉพาะตัว

---

## 4. ตัวละคร (Characters)

Matrix: เพศ (หญิง/ชาย) x ช่วงวัย (เด็ก/วัยรุ่น/ผู้ใหญ่) = 6 ตัวละคร

| ตัวละคร | ธาตุถนัด | Passive เด่น |
|---|---|---|
| เด็กหญิง | น้ำแข็ง/น้ำ | Pickup range ไกลขึ้น |
| เด็กชาย | ดิน/ลม | HP regen เร็ว |
| วัยรุ่นหญิง | สายฟ้า | Attack speed สูง |
| วัยรุ่นชาย | ไฟ | Movement speed สูง |
| ผู้ใหญ่หญิง | แสง | AOE radius ใหญ่ขึ้น |
| ผู้ใหญ่ชาย | ความมืด | Damage สูงสุด, speed ต่ำ |

**แนวคิดต่อยอด (ยังไม่ตัดสินใจ):** ระบบ "คอมโบคู่" — จับคู่ตัวละครที่ธาตุเสริมกันเพื่อปลดล็อก synergy พิเศษ (รองรับทั้งแบบ single-player build variety หรือ multiplayer ในอนาคต)

---

## 5. Enemy Design

### 5.1 Archetype พื้นฐาน
Swarmer (เยอะ, HP ต่ำ) · Tank (HP สูง, ช้า) · Ranged (ยิงไกล) · Charger (พุ่งใส่) · Splitter (แตกตัวตอนตาย) · Elite/Mini-boss

### 5.2 ศัตรูตามธาตุ (8 ธาตุ)

| ธาตุ | Archetype | ท่าโจมตี |
|---|---|---|
| ไฟ | Charger | สะสมพลัง 0.5 วิ แล้วพุ่งเป็นเส้นตรง ทิ้ง trail ไฟ |
| น้ำ | Ranged | ยิงกระสุนโค้งเล็งล่วงหน้า |
| ดิน | Tank | เดินช้า HP สูง ชนแล้ว knockback |
| ลม | Swarmer | เดินเร็วมาก จำนวนเยอะ |
| สายฟ้า | Charger (เร็ว) | วาร์ปสั้นเข้าใกล้แบบไม่มีสัญญาณเตือน |
| น้ำแข็ง | Ranged/Support | ยิง projectile debuff slow |
| แสง | Elite | ลำแสงกวาดพื้นที่ (มี telegraph) |
| ความมืด | Splitter | ตายแล้วแตกเป็นเงาเล็ก 2-3 ตัว |

### 5.3 Wave Progression
- เวฟ 1-3: Swarmer เท่านั้น
- เวฟ 4-6: เพิ่ม Tank/Ranged
- เวฟ 7-9: ผสมทุก archetype + ความหนาแน่นสูงขึ้น
- เวฟ 10: Boss

---

## 6. Boss Design

### 6.1 โครงสร้าง
- **เวฟ 5** — Elite (ธาตุสุ่ม, 1 phase, HP น้อยกว่า boss เต็ม)
- **เวฟ 10** — Boss เต็ม (ธาตุอื่นจาก elite เพื่อไม่ซ้ำ, 2 phase)
- Boss สุ่มจาก pool 8 ธาตุทุกรัน เพื่อ replayability

### 6.2 Boss Roster

| Boss | ธาตุ | Phase 1 | Phase 2 |
|---|---|---|---|
| Inferno Colossus | ไฟ | เดินเข้าใส่ + วงแหวนไฟ | แตกเป็นเปลวไฟกระจาย 4 ทิศ |
| Tide Sovereign | น้ำ | ยิง projectile โค้งหลายทิศ | คลื่นดัน knockback จากศูนย์กลาง |
| Titan of Roots | ดิน | กระทืบพื้น shockwave วงกลม | เรียกหินเล็กพุ่งจากขอบจอ |
| Gale Wraith | ลม | วนรอบจอ ดูดผู้เล่นเข้าหา | เร่งความเร็ว + พายุย่อยตามทาง |
| Storm Herald | สายฟ้า | วาร์ปสุ่ม + ยิงเส้นฟ้าตรง | วาร์ปถี่ขึ้น เส้นฟ้าหลายเส้น |
| Glacial Empress | น้ำแข็ง | ยิง spike น้ำแข็ง + slow field | แช่แข็งพื้นบางส่วน (ลื่น) |
| Radiant Seraph | แสง | ลำแสงกวาดพื้นที่ (telegraph ชัด) | แสงสาดจากขอบจอหลายจุด |
| Void Herald | ความมืด | ดูดแสงรอบตัว (จอมืดเฉพาะจุด) | แตกร่างเป็นเงาย่อยชั่วคราว |

**หลักออกแบบร่วม:** ทุก boss มี telegraph ชัดเจนก่อนโจมตี, phase 2 = เร่งจังหวะเดิม ไม่ใช่ mechanic ใหม่ (ลดภาระ AI สำหรับ solo dev)

---

## 7. Reward System

### 7.1 In-run (ใช้ต่อในรันนั้น)
- **หลัง Elite (เวฟ 5):** ธาตุ guaranteed 2-3 ชิ้นตรงธาตุ boss + choice popup พิเศษ (rarity สูงกว่าปกติ)
- **หลัง Boss (เวฟ 10):** Fusion shard พิเศษ (fusion จากธาตุปกติไม่ได้) + currency คูณ x2-3

### 7.2 Meta-progression (ข้ามรัน)
| ระบบ | รายละเอียด |
|---|---|
| Boss Codex | บันทึกว่าเคยชนะ boss ธาตุไหนแล้วบ้าง |
| Character unlock | ชนะ boss ธาตุที่ตรงกับตัวละครที่ยังไม่ปลดล็อก = ปลดล็อก |
| Permanent stat upgrade | ใช้ currency ซื้อ upgrade ถาวร (+HP เริ่มต้น, +ช่อง element tracker) |
| Cosmetic | สี trail/effect พิเศษตามธาตุ boss ที่เคยชนะ |

### 7.3 First-time Kill Bonus
- ครั้งแรกที่ชนะ boss ธาตุนั้น → fusion shard + character unlock แบบ guaranteed
- ครั้งต่อไป → currency/ธาตุปกติ, fusion shard เปลี่ยนเป็นสุ่ม (โอกาสต่ำลง)

---

## 8. UI/UX

### 8.1 หลักการ
"ดูจอเดียวรู้เรื่องหมด" — จอเล็ก ผู้เล่นต้องโฟกัสหลบศัตรู ไม่มีเวลาเปิดเมนู

### 8.2 In-game HUD
- มุมบนซ้าย: HP bar
- มุมบนขวา: wave counter + timer
- กลางจอ: gameplay area (ตัวละคร + ศัตรู)
- เหนือปุ่มควบคุม: element tracker (progress ต่อธาตุ) + level badge
- มุมล่างซ้าย: virtual joystick (ควบคุมการเคลื่อนที่, attack auto)

### 8.3 Level-up Popup
- Pause เกม + dim background
- การ์ด 3 ใบ ขนาดใหญ่กดง่ายด้วยนิ้ว (ไอคอน + ชื่อ + คำอธิบายสั้น)
- Badge เน้นตัวเลือกที่ใกล้ fusion

### 8.4 หน้าจอ Meta (นอกเกม)
- Character select — grid 6 ช่อง
- Upgrade/Shop — permanent upgrade ด้วย currency
- Stats/Collection — โชว์ fusion และ boss codex ที่ปลดล็อกแล้ว

---

## 9. Monetization (แนวทาง — ยังไม่ตัดสินใจขั้นสุดท้าย)

โมเดลที่พิจารณา: **Hybrid (Ads + IAP)** — นิยมที่สุดสำหรับ roguelike มือถือ
- Ads: ดูเพื่อ revive / รับ currency พิเศษ
- IAP: ซื้อ cosmetic, skin ตัวละคร, ads-free

---

## 10. สถานะโปรเจกต์ / สิ่งที่ยังต้องตัดสินใจ

- [ ] จำนวน/ชื่อธาตุ 8 ธาตุ (ยืนยันสุดท้าย)
- [ ] ระบบคอมโบคู่ตัวละคร (single-player เท่านั้น หรือรองรับ multiplayer)
- [ ] Monetization โมเดลสุดท้าย
- [ ] Art reference / mood board ฉบับเต็ม
