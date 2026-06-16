# ART-AMSS — Overview

## ข้อมูลโครงการ

| รายการ | ข้อมูล |
|--------|--------|
| รหัสโครงการ | I-2025-APW-MA-029 |
| Site | ART |
| แพลตฟอร์ม | Oracle Database 19c + Active Data Guard |
| Script Path | `/Users/phonr/Github/Projects_Maintenance/art-amss-dg-healthcheck/` |

---

## Infrastructure

| Server | Role | Oracle Version |
|--------|------|---------------|
| dbsystem1 | Primary / Standby (สลับได้) | 19.31.0.0.0 |
| dbsystem2 | Primary / Standby (สลับได้) | 19.30.0.0.0 |

**Authentication**: OS Authentication (`/ as sysdba`)

### CDB Instances

| ORACLE_SID | PDB | หมายเหตุ |
|------------|-----|---------|
| amsscdb | AMSS, AMSSPDB | CDB #1 |
| fdmccdb | FDMC | CDB #2 |
| fdmscdb | FDMS | CDB #3 |

---

## ขอบเขตงาน

### 2.1 Database Enterprise Edition (4 ชุด)
- Instance / Listener Status
- Tablespace, Temp, Undo, Redo Log
- Alert Log / Trace Log
- Performance (AWR, Top SQL, Wait Events)
- Backup / RMAN Status
- Parameters (Memory, PGA, SGA)
- License / Patch / PSU Version

### 2.2 Active Data Guard (4 ชุด)
- Data Guard Configuration และ Sync Status
- Gap / Lag / Archive Apply Delay
- Log Transport และ Apply Service
- Disk Usage และ FRA
- Alert Log ทั้ง Primary / Standby
- Backup และ Role Transition Test
- Network Bandwidth ระหว่าง Primary-Standby

---

## Scripts

| ไฟล์ | หน้าที่ |
|------|--------|
| `pm_collect.sh` | เก็บข้อมูลจาก Oracle server (รันเป็น oracle user) |
| `pm_collect_primary.sql` | SQL สำหรับ PRIMARY node (หัวข้อ 2.1) |
| `pm_collect_standby.sql` | SQL สำหรับ STANDBY node (หัวข้อ 2.2) |
| `generate_report.py` | สร้างรายงาน `.docx` |
| `หน้าปกรายงาน_วิทยุการบิน_AMSS.docx` | Template หน้าปก (ห้ามแก้ไข) |

---

## Variables ที่แก้ทุกเดือน (generate_report.py)

```python
MONTH_TAG = "YYYYMM"
YEAR      = "YYYY"
DOC_SEQ   = "1"
```

---

## ลิงก์

- [[Monthly Checklist]]
- Context เต็ม: `/art-amss-dg-healthcheck/oracle_dg_healthcheck_context.md`
