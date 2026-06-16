# SRT MA-EXP Health Check — Project Context

## Project Overview
- **รหัสโครงการ**: I-2026-APW-MA-027
- **ชื่อโครงการ**: จ้างบริการบำรุงรักษาระบบฐานข้อมูลแม่ข่ายและระบบบริการฐานข้อมูลส่วนเพิ่มขยาย (SRT Database Cloud + Expand)
- **Goal**: รายงานผลการบำรุงรักษา + รายงานการเฝ้าระวังภัยคุกคาม ส่งลูกค้าราย 3 เดือน (รายไตรมาส)
- **แพลตฟอร์ม**: Oracle RAC 19c, Microsoft SQL Server

---

## รายงานที่ต้องส่ง

| รายงาน | ข้อสัญญา | คาบเวลา |
|--------|----------|---------|
| รายงานการบำรุงรักษา | ข้อ 3.7 | ราย 3 เดือน (รายไตรมาส) |
| รายงานการเฝ้าระวังภัยคุกคามทางสารสนเทศ | ข้อ 3.13 | ราย 3 เดือน (รายไตรมาส) |

---

## โครงสร้างรายงาน

### รายงาน 1: รายงานการบำรุงรักษา (ข้อ 3.7)

```
[หน้าปก]
  ชื่อโครงการ
  ชื่อผู้รับจ้าง
  งวดงาน
  คาบเวลาการบำรุงรักษา
  วันที่และเวลาที่ปฏิบัติงาน

[รายชื่อผู้ปฏิบัติงาน]
  รายชื่อผู้ปฏิบัติงานทั้งหมด

Section 1  ข้อมูลระบบ (System Information)
  1.1  บัญชีสรุปรายการอุปกรณ์และซอฟต์แวร์ที่บำรุงรักษา
       - ตาราง: รายการ | เวอร์ชัน | จำนวน | หมายเหตุ

Section 2  Oracle RAC 19c
  2.1  Clusterware & Instance Health
    2.1.1  Grid Infrastructure Status
    2.1.2  Cluster Node Status
    2.1.3  Instance Status (RAC)
  2.2  Storage & ASM
    2.2.1  ASM Disk Group Usage
    2.2.2  ASM Disk Status
  2.3  Database Health
    2.3.1  Alert Log (Critical Errors)
    2.3.2  Tablespace Usage
    2.3.3  Backup / RMAN Status
  2.4  Performance
    2.4.1  CPU & Memory Usage
    2.4.2  Top Wait Events
  2.5  รายการตรวจสอบ (Checklist)

Section 3  Microsoft SQL Server
  3.1  Service & Instance Status
    3.1.1  SQL Server Service Status
    3.1.2  SQL Server Agent Status
  3.2  Database Integrity
    3.2.1  DBCC CHECKDB Results
  3.3  Maintenance Jobs
    3.3.1  Index Rebuild / Reorganize
    3.3.2  Update Statistics
    3.3.3  Job History Summary
  3.4  Log Review
    3.4.1  SQL Server Error Log
    3.4.2  Windows Event Log (Database-related)
  3.5  รายการตรวจสอบ (Checklist)

Section 4  สรุปผลการบำรุงรักษา
  - ตาราง: ระบบ | รายการ | ผลการตรวจสอบ | สถานะ | หมายเหตุ
  - ปัญหาหรือสิ่งผิดปกติที่ตรวจพบ
  - ข้อเสนอแนะและแนวทางแก้ไข

[ลายมือชื่อ]
  ลายมือชื่อผู้ปฏิบัติงาน
  ลายมือชื่อผู้ควบคุมโครงการ
```

---

### รายงาน 2: รายงานการเฝ้าระวังภัยคุกคามทางสารสนเทศ (ข้อ 3.13)

```
[หน้าปก]
  ชื่อโครงการ
  ชื่อผู้รับจ้าง
  งวดงาน
  คาบเวลา
  รายชื่อผู้ปฏิบัติงาน

Section 1  วิธีการตรวจสอบ
  1.1  รายละเอียดวิธีการตรวจสอบและการดำเนินงานแต่ละรายการ

Section 2  บัญชีอุปกรณ์และซอฟต์แวร์ที่เฝ้าระวัง
  - ตาราง: รายการ | ประเภท | วิธีเฝ้าระวัง

Section 3  Security Patch & Updates (อ้างอิง ข้อ 3.11)
  3.1  Oracle Security Patch
       - Critical Patch Update (CPU) ที่ประกาศในงวดนี้
       - สถานะการติดตั้งบนระบบ
  3.2  Microsoft SQL Server Security Updates
       - Service Pack / Cumulative Update ที่ประกาศในงวดนี้
       - สถานะการติดตั้งบนระบบ

Section 4  Vulnerability Assessment
  4.1  สรุปผลการเฝ้าระวังภัยคุกคาม
  4.2  ช่องโหว่ที่ตรวจพบ (ถ้ามี)
  4.3  ข้อสังเกตหรือแนวทางป้องกัน

[ลายมือชื่อ]
  ลายมือชื่อผู้ปฏิบัติงาน
```

---

## หัวข้อตรวจสอบ Oracle RAC 19c (Preventive Checklist)

| หัวข้อ | รายการตรวจสอบ | Views / Commands หลัก |
|--------|--------------|----------------------|
| Clusterware & Instance | Grid Infrastructure status, Node status ทุก node | `crsctl stat res -t`, `srvctl status database` |
| Storage & ASM | ASM Disk Group usage/status | `v$asm_diskgroup`, `v$asm_disk` |
| Alert Log | Critical errors (ORA-) 31 วันล่าสุด | `v$diag_alert_ext` |
| Tablespace | Usage per tablespace (CDB + PDB) | `dba_data_files`, `cdb_data_files`, `v$pdbs` |
| Backup / RMAN | Job history 32 วัน | `v$rman_backup_job_details` |
| Performance | CPU/Memory, Top Wait Events (AWR 31 วัน) | `dba_hist_system_event`, `dba_hist_sqlstat`, `v$pgastat`, `v$sgainfo` |

---

## หัวข้อตรวจสอบ Microsoft SQL Server (Preventive Checklist)

| หัวข้อ | รายการตรวจสอบ | Commands หลัก |
|--------|--------------|--------------|
| Service & Instance | SQL Server Service, SQL Server Agent | `Get-Service MSSQL*`, `EXEC xp_servicecontrol` |
| Database Integrity | DBCC CHECKDB ทุก database | `DBCC CHECKDB` |
| Index Maintenance | Rebuild / Reorganize, Update Statistics | `sys.dm_db_index_physical_stats`, SQL Agent Job history |
| Log Review | SQL Server Error Log, Windows Event Log | `EXEC xp_readerrorlog`, Windows Event Viewer |

---

## Checklist Table Format

คอลัมน์ **สถานะ** แสดง 2 บรรทัดในเซลล์เดียว:

```
☐  ปกติ
☐  ไม่ปกติ
```

---

## Next Steps
- 🔲 สร้าง `pm_collect_oracle_rac.sh` สำหรับเก็บข้อมูล Oracle RAC
- 🔲 สร้าง `pm_collect_rac.sql` (Primary SQL script สำหรับ RAC — ไม่มี DG)
- 🔲 สร้าง `pm_collect_mssql.sql` หรือ PowerShell script สำหรับ MSSQL
- 🔲 สร้าง `generate_report_maintenance.py` — รายงานการบำรุงรักษา (ข้อ 3.7)
- 🔲 สร้าง `generate_report_security.py` — รายงานเฝ้าระวังภัยคุกคาม (ข้อ 3.13)
- 🔲 ออกแบบ template หน้าปก (SRT)
