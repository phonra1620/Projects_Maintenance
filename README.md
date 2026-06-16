# Projects Maintenance — รายงานผลการบำรุงรักษา

คลังสคริปต์และเครื่องมือสำหรับสร้างรายงานผลการบำรุงรักษาระบบฐานข้อมูล Oracle รายเดือน ส่งมอบให้ลูกค้าในรูปแบบไฟล์ `.docx`

---

## โครงการที่ดูแล

| Site | รหัสโครงการ | ชื่อย่อ | Directory |
|------|-------------|---------|-----------|
| ART | I-2025-APW-MA-029 | art-amss | `art-amss-dg-healthcheck/` |
| SRT | I-2026-APW-MA-027 | srt-ma-exp | `srt-ma-exp-healthcheck/` |

รายละเอียดโครงการทั้งหมดอยู่ที่ [รายงานการบำรุงรักษา.md](รายงานการบำรุงรักษา.md)

---

## โครงสร้าง Repository

```
Projects_Maintenance/
├── รายงานการบำรุงรักษา.md          # ทะเบียนโครงการทั้งหมด
│
├── art-amss-dg-healthcheck/         # โครงการ ART-AMSS (Oracle 19c + Active Data Guard)
│   ├── pm_collect.sh                # Shell script เก็บข้อมูลจาก Oracle servers
│   ├── pm_collect_primary.sql       # SQL script สำหรับ PRIMARY node
│   ├── pm_collect_standby.sql       # SQL script สำหรับ STANDBY node
│   ├── generate_report.py           # สร้างรายงาน .docx (python-docx)
│   ├── หน้าปกรายงาน_*.docx         # Template หน้าปก (ไม่แก้ไขโดยตรง)
│   ├── lasted_oracle_critical_patch_update.docx  # CPU patch reference
│   ├── oracle_dg_healthcheck_context.md          # เอกสาร context สำหรับโครงการนี้
│   └── output/                      # ผลลัพธ์ (ไม่ถูก commit)
│
└── srt-ma-exp-healthcheck/          # โครงการ SRT (โครงสร้างเดียวกัน)
```

---

## วิธีใช้งาน (รายเดือน)

### 1. เก็บข้อมูลจาก Oracle Servers

รันในฐานะ `oracle` user บนแต่ละ server:

```bash
# บน PRIMARY server (dbsystem2)
./pm_collect.sh

# บน STANDBY server (dbsystem1)
./pm_collect.sh
```

script จะสร้างไฟล์ผลลัพธ์ใน `output/YYYYMM_HOSTNAME/` และบีบอัดเป็น `YYYYMM_HOSTNAME.zip` โดยอัตโนมัติ

### 2. เตรียมข้อมูลบนเครื่อง Local

```bash
# Copy zip จากทั้งสอง server มาไว้ใน output/
unzip YYYYMM_dbsystem2.zip -d output/YYYYMM_dbsystem2/
unzip YYYYMM_dbsystem1.zip -d output/YYYYMM_dbsystem1/
```

### 3. สร้างรายงาน

แก้ค่าตัวแปรใน `generate_report.py` ก่อนรัน:

```python
MONTH_TAG = "202606"   # YYYYMM
YEAR      = "2026"     # ปี CE
DOC_SEQ   = "1"        # ลำดับรายงานในปีนั้น
```

จากนั้นรัน:

```bash
pip install python-docx   # ติดตั้งครั้งแรกเท่านั้น
python3 generate_report.py
```

Output: `output/YYYYMM/รายงานการบำรุงรักษาระบบฐานข้อมูล_AMSS_{YEAR}_{SEQ}.docx`

### 4. ตรวจสอบก่อนส่ง

- เปิดไฟล์ `.docx` → right-click สารบัญ → **Update Field → Update entire table**
- กรอก `รายละเอียดของผลลัพธ์` ที่ต้องการเพิ่มเติม
- ตรวจสอบ Section 5.2 Network Bandwidth (กรอกด้วยตนเอง)

---

## ข้อกำหนด

| รายการ | รายละเอียด |
|--------|-----------|
| Python | 3.x |
| python-docx | `pip install python-docx` |
| Oracle | 19c (tested บน 19.30 และ 19.31) |
| OS บน Server | Linux (Oracle UEK) |

---

## เอกสารอ้างอิง

- [art-amss-dg-healthcheck/oracle_dg_healthcheck_context.md](art-amss-dg-healthcheck/oracle_dg_healthcheck_context.md) — context เต็มของโครงการ ART-AMSS รวม script architecture, known issues, และ SQLPlus format standards
