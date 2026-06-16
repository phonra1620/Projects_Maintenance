# Architecture — Multi-Project Report Design

## แนวคิดหลัก

แต่ละโปรเจคมีหน้าปกและ section ของตัวเอง  
สิ่งที่ **ใช้ร่วมกันจริงๆ** มีสองระดับ:

1. **ไฟล์ร่วม** — `lasted_critical_patch_update.docx` อัปเดตครั้งเดียว ทุกโปรเจค Oracle หยิบไปใช้
2. **กระบวนการร่วม** — ขั้นตอนที่ทำเหมือนกันทุกโปรเจค ต่างกันแค่รายละเอียด

---

## ไฟล์ร่วม (Shared Assets)

ย้ายออกจาก project folder มาไว้ที่ `shared/` ระดับ repo:

```
Projects_Maintenance/
├── shared/
│   ├── lasted_oracle_critical_patch_update.docx   ← ทุกโปรเจค Oracle ใช้
│   └── lasted_mssql_security_patch.docx           ← โปรเจคที่มี MSSQL ใช้
├── art-amss-dg-healthcheck/
└── srt-ma-exp-healthcheck/
```

**วิธีใช้**: `generate_report.py` แต่ละโปรเจคชี้ไปที่ `../shared/lasted_oracle_critical_patch_update.docx`  
**อัปเดต**: แก้ไฟล์ใน `shared/` ที่เดียว ทุกโปรเจคได้ของใหม่อัตโนมัติรอบถัดไป

---

## กระบวนการร่วม (Shared Process)

ทุกโปรเจคเดิน **5 Phase** เดียวกัน ต่างกันแค่รายละเอียดในแต่ละ phase:

```
Phase 1: เก็บข้อมูล (Collect)
    └─ รัน collect script บน server → download zip

Phase 2: เตรียม Local (Prepare)
    └─ แตก zip → จัดวาง output folder

Phase 3: อัปเดต Patch Reference (Update Shared)
    └─ ตรวจ Oracle CPU / MSSQL CU ล่าสุด
    └─ แก้ shared/lasted_*_patch_update.docx (ถ้ามีของใหม่)

Phase 4: สร้างรายงาน (Generate)
    └─ แก้ run variables ใน config
    └─ รัน generate_report.py → .docx
    └─ Update TOC ใน Word

Phase 5: ตรวจสอบและส่ง (Review & Deliver)
    └─ กรอก findings / ข้อสังเกต
    └─ ลงลายเซ็น
    └─ ส่งลูกค้า
```

---

## สิ่งที่ต่างกันในแต่ละโปรเจค

| Phase | ART-AMSS | SRT-MA-EXP |
| ----- | -------- | ---------- |
| **1. Collect** | Oracle DG (Primary + Standby) | Oracle RAC + MSSQL |
| **2. Prepare** | 2 server folders | RAC nodes + MSSQL folder |
| **3. Patch Ref** | Oracle CPU เท่านั้น | Oracle CPU + MSSQL CU |
| **4. Generate** | 1 รายงาน (รายเดือน) | 2 รายงาน (3.7 + 3.13) รายไตรมาส |
| **5. Deliver** | AEROTHAI | SRT |

---

## Checklist Template ที่ใช้ร่วมกัน

Phase 3 (อัปเดต Patch Reference) ทำก่อนรายงานทุกโปรเจคในรอบนั้น  
ไม่ต้องทำซ้ำถ้ารายงานหลายโปรเจคออกในรอบเดียวกัน

```
รอบการออกรายงาน:
  [ ] ตรวจ Oracle CPU ล่าสุด → แก้ shared/lasted_oracle_critical_patch_update.docx
  [ ] ตรวจ MSSQL CU ล่าสุด  → แก้ shared/lasted_mssql_security_patch.docx  (ถ้ามีโปรเจค MSSQL)

จากนั้นรันแต่ละโปรเจค:
  [ ] ART-AMSS  (รายเดือน)
  [ ] SRT-MA-EXP (รายไตรมาส — เฉพาะเดือนที่ครบงวด)
```

---

## ลิงก์

- [[ART-AMSS/Monthly Checklist]]
- [[SRT-MA-EXP/Monthly Checklist]]
- [[Home]]
