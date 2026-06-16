# New Project Onboarding

เมื่อรับโครงการใหม่ ทำตาม 4 ขั้นตอนนี้ตามลำดับ

---

## ขั้นตอนที่ 1 — เก็บข้อมูล (Discovery)

รัน [[Infrastructure Survey]] template บน server แล้วตอบคำถาม Tier 1 ก่อน
ถ้าตอบ Tier 1 ได้ครบจะรู้ทันทีว่าต้องสร้างอะไรบ้าง

### Tier 1 — ตัดสินใจ script และ report structure

- [ ] OS type คืออะไร?
- [ ] Database platform คืออะไร?
- [ ] HA type คืออะไร?
- [ ] ต้องส่งรายงานกี่ฉบับ? อิงข้อสัญญาไหน?
- [ ] Cadence: รายเดือน / รายไตรมาส / อื่น?

### Tier 2 — ต้องรู้ก่อนเขียน script

- [ ] Hostname ของ server ทุกเครื่อง
- [ ] ชื่อ database / ORACLE_SID ทุกตัว
- [ ] CDB หรือ non-CDB? ถ้า CDB มี PDB ชื่ออะไรบ้าง?
- [ ] Path ของ oratab (Linux: `/etc/oratab` / Solaris: `/var/opt/oracle/oratab`)
- [ ] Authentication method (OS Auth / Password)
- [ ] User ที่ใช้รัน script (oracle user / grid user)

### Tier 3 — ต้องรู้ก่อนสร้างรายงาน

- [ ] ชื่อลูกค้าเต็ม
- [ ] มี cover template หน้าปกแล้วหรือยัง?
- [ ] ต้อง track Oracle CPU patch ไหม?
- [ ] ต้อง track MSSQL CU ไหม?
- [ ] ลายเซ็นกี่คน?

---

## ขั้นตอนที่ 2 — เลือก Building Blocks

จาก Tier 1 ให้ดู matrix นี้ว่า script ไหนใช้ซ้ำได้ ไหนต้องสร้างใหม่

### Collect Script (Shell)

| OS | สถานะ | หมายเหตุ |
| -- | ------ | -------- |
| Linux (bash) | ✅ ใช้ซ้ำ | ปรับ CDB_LIST + server name ใน config เท่านั้น |
| Solaris (sh/ksh) | 🔲 สร้างใหม่ | command ต่างกัน: oratab path, memory query, zip syntax |
| Windows | 🔲 สร้างใหม่ | PowerShell หรือ .bat |
| AIX / HP-UX | 🔲 สร้างใหม่ | ประเมินใหม่เมื่อเจอ |

### SQL Script (Oracle)

SQL ทำงานได้บนทุก OS — **ใช้ซ้ำได้เสมอ** ต่างกันแค่ HA type:

| HA Type | Script | สถานะ |
| ------- | ------ | ------ |
| Data Guard PRIMARY | `pm_collect_primary.sql` | ✅ มีแล้ว (ART-AMSS) |
| Data Guard STANDBY | `pm_collect_standby.sql` | ✅ มีแล้ว (ART-AMSS) |
| RAC (ไม่มี DG) | `pm_collect_rac.sql` | 🔲 สร้างสำหรับ SRT |
| Standalone | ใช้ `pm_collect_primary.sql` ตัดส่วน DG ออก | 🔲 ดัดแปลงเมื่อเจอ |

### Collect Script (MSSQL)

| Platform | Script | สถานะ |
| -------- | ------ | ------ |
| MSSQL บน Windows | `pm_collect_mssql.sql` + PowerShell | 🔲 สร้างสำหรับ SRT |
| MSSQL บน Linux | `pm_collect_mssql.sql` + bash sqlcmd | 🔲 สร้างเมื่อเจอ |

### Python Report Generator

| สถานะ | หมายเหตุ |
| ------ | -------- |
| ✅ core logic ใช้ซ้ำได้ | LogReader, SqlScriptReader, doc_builder |
| 🔲 section order ต้องกำหนดต่อโปรเจค | ขึ้นกับ scope ของสัญญา |
| 🔲 config.yaml ต้องสร้างใหม่ทุกโปรเจค | infra + run variables |

---

## ขั้นตอนที่ 3 — สร้าง/ปรับ Script

เรียงตาม dependency:

```
1. สร้าง config.yaml       ← ใส่ infra ที่ได้จาก Tier 2
2. เขียน collect script    ← เลือกจาก matrix ด้านบน
3. เขียน SQL script        ← เลือกหรือดัดแปลงจากที่มีอยู่
4. ทดสอบ collect บน server ← รัน 1 database ก่อน ตรวจ output
5. สร้าง generate_report.py ← กำหนด section ตาม scope สัญญา
6. ทดสอบ generate           ← ตรวจ .docx output
```

---

## ขั้นตอนที่ 4 — ตั้งค่า Obsidian

สร้างโน้ตใน vault ตามโครงสร้างนี้:

```
{PROJECT}/
├── Overview.md          ← Tier 1-3 answers + infra summary
├── Monthly Checklist.md ← หรือ Quarterly ตาม cadence
└── Infrastructure Survey.md  ← ผลลัพธ์จาก server
```

---

## ตารางเปรียบเทียบโครงการ (อัปเดตเมื่อมีโครงการใหม่)

| รายการ | ART-AMSS | SRT-MA-EXP | โครงการถัดไป |
| ------ | -------- | ---------- | ------------ |
| OS | Linux x86_64 | Solaris SPARC | |
| Oracle HA | Data Guard | RAC | |
| มี MSSQL | ไม่มี | มี | |
| จำนวน DB | 3 CDB | 4 DB | |
| Cadence | รายเดือน | รายไตรมาส | |
| รายงาน | 1 ฉบับ | 2 ฉบับ | |
| Collect script | Linux bash | Solaris sh (🔲) | |
| SQL PRIMARY | ✅ มีแล้ว | ✅ ใช้ซ้ำ | |
| SQL STANDBY | ✅ มีแล้ว | ไม่ใช้ | |
| SQL RAC | ไม่ใช้ | 🔲 สร้างใหม่ | |
| SQL MSSQL | ไม่ใช้ | 🔲 สร้างใหม่ | |

---

## Pattern ที่เห็นจาก 2 โครงการแรก

**ข้อสังเกต:**

1. **OS เป็นตัวแปรที่ส่งผลมากที่สุด** — Linux กับ Solaris ทำให้ collect script เขียนซ้ำเกือบทั้งหมด แม้ SQL จะใช้ซ้ำได้
2. **SQL script ยืดหยุ่นกว่า shell** — Oracle SQL เหมือนกันทุก OS, ต่างกันแค่ HA topology (DG vs RAC)
3. **Report section ขึ้นกับสัญญา** — ไม่ขึ้นกับ platform ควรกำหนดจาก TOR ก่อนเขียน code
4. **MSSQL เพิ่ม scope อีกชั้น** — ถ้าโครงการมีทั้ง Oracle + MSSQL ต้องมี collect script แยก 2 ชุด

**สิ่งที่ควรทำก่อนรับโครงการใหม่:**
- ถามว่า OS คืออะไร → ถ้าไม่ใช่ Linux ต้องเผื่อเวลาเขียน collect script ใหม่
- ถามว่า platform มีอะไรบ้าง → ถ้ามี MSSQL ด้วยต้องเผื่อ effort เพิ่ม

---

## ลิงก์

- [[Architecture — Multi-Project Report Design]]
- [[ART-AMSS/Overview]]
- [[SRT-MA-EXP/Overview]]
- [[Home]]
