# Oracle Data Guard Health Check — Project Context

## Project Overview
- **Goal**: รายงานสุขภาพ Oracle Database รายเดือน ส่งลูกค้า (Service Report)
- **วิธีเก็บข้อมูล**: SQL/Shell Script รันด้วยตนเอง ทีละเครื่อง
- **Output**: Text spool → แคปจอ → แนบในรายงาน

---

## Infrastructure

### Servers
| Server | Role |
|---|---|
| dbsystem1 | Primary หรือ Standby (สลับได้) |
| dbsystem2 | Primary หรือ Standby (สลับได้) |

- OS: Linux (UEK) `5.4.17-2136.334.6.1.el7uek.x86_64`
- Oracle Version: **19c** (พบ 19.30 บน dbsystem2, 19.31 บน dbsystem1)
- Authentication: **OS Authentication** (`/ as sysdba`)

### CDB Instances
| ORACLE_SID | PDB | หมายเหตุ |
|---|---|---|
| amsscdb | AMSS, AMSSPDB | CDB #1 |
| fdmccdb | FDMC | CDB #2 |
| fdmscdb | FDMS | CDB #3 |

- แต่ละ CDB มี Primary/Standby สลับกันได้ระหว่าง dbsystem1 และ dbsystem2
- DR (Standby) = **Read-only** (Active Data Guard)
- มี **DG Broker** (`dg_broker_start=TRUE`)

---

## Scope of Work

### 2.1 — Database Enterprise Edition (4 ชุด)
- ตรวจสอบ Instance / Listener Status
- ตรวจสอบ Tablespace, Temp, Undo, Redo Log
- ตรวจสอบ Alert Log / Trace Log
- ตรวจสอบ Performance (AWR, Top SQL, Wait Event)
- ตรวจสอบ Backup Job / RMAN Status
- ตรวจสอบ Parameter ที่สำคัญ (Memory, PGA, SGA)
- ตรวจสอบ License / Patch / PSU Version

### 2.2 — Active Data Guard (4 ชุด)
- ตรวจสอบ Data Guard Configuration และ Sync Status
- ตรวจสอบ Gap / Lag / Archive Apply Delay
- ตรวจสอบ Log Transport และ Apply Service
- ตรวจสอบ Disk Usage และ FRA (Flash Recovery Area)
- ตรวจสอบ Alert Log ทั้ง Primary / Standby
- ตรวจสอบ Backup และ Role Transition Test
- ตรวจสอบ Network Bandwidth ระหว่าง Primary-Standby

---

## Script Architecture

```
pm_collect.sh
├── pm_collect_primary.sql                      # หัวข้อ 2.1 (รันบน PRIMARY)
├── pm_collect_standby.sql                      # หัวข้อ 2.2 (รันบน STANDBY)
├── generate_report.py                       # สร้างรายงาน .docx (python-docx)
├── หน้าปกรายงาน_PM_วิทยุการบินv2.docx      # cover template (ไม่แก้ไข)
└── output/YYYYMM/
    ├── {cdb}_PRIMARY_{host}_{YYYYMM}.txt
    ├── {cdb}_STANDBY_{host}_{YYYYMM}.txt
    ├── inventory_{host}_{YYYYMM}.txt        # รายชื่อ CDB + PDB ทุก instance
    ├── network_test_{host}_{YYYYMM}.txt     # OS-level network test (ping, nc)
    ├── pm_collect_{host}_{YYYYMM}.log
    └── รายงานการบำรุงรักษาระบบฐานข้อมูล_AMSS_{YEAR}_{SEQ}.docx
```

### Flow การรัน (pm_collect.sh)
1. อ่าน `ORACLE_HOME` จาก `/etc/oratab` สำหรับแต่ละ CDB
2. ตรวจสถานะ instance (`v$instance.status`)
3. Query `v$database.database_role` → `PRIMARY` หรือ `PHYSICAL STANDBY`
4. รัน script ตาม role (`cd` ไปที่ SCRIPT_DIR ก่อนเสมอ)
5. Spool output → `output/YYYYMM/{cdb}_{ROLE}_{host}_{YYYYMM}.txt`
6. เก็บ PDB list ลง `inventory_{host}_{YYYYMM}.txt`
7. รัน OS network test → `network_test_{host}_{YYYYMM}.txt`

---

## Script: pm_collect_standby.sql

**File**: `pm_collect_standby.sql`
**Role**: PHYSICAL STANDBY
**Status**: ✅ tested บน amsscdb@dbsystem1 (19.31.0.0.0) — ไม่มี error
**Output**: `output/YYYYMM/{cdb}_STANDBY_{host}_{YYYYMM}.txt` (dynamic จาก `v$database` + `v$instance`)

### Sections

| Section | หัวข้อ 2.2 | Views หลัก |
|---|---|---|
| DB Identity | Header (2 query) | `v$database`, `v$instance` |
| [2.2-1] DG Config & Sync | DG Config, Member Status, Sync Stats | `v$dataguard_config`, `v$dataguard_stats` |
| [2.2-2] Gap / Lag | Archive Gap, MRP/Apply Status, Lag | `v$archive_gap`, `v$managed_standby`, `v$dataguard_stats` |
| [2.2-3] Log Transport & Apply | Dest Status, Redo Apply Rate | `v$archive_dest_status`, `v$recovery_progress` |
| [2.2-4] Disk & FRA | FRA Summary, FRA by Type, Tablespace | `v$recovery_file_dest`, `v$flash_recovery_area_usage`, `dba_data_files` |
| [2.2-5] Alert Log | Last 30 days, filter `%ORA-%` only, linesize 240, col 200 | `v$diag_alert_ext` |
| [2.2-6] Backup / RMAN | RMAN job history 32 วัน (linesize 160, ไม่มี session_key) — มักว่างเปล่าถ้า backup รันจาก Primary เท่านั้น | `v$rman_backup_job_details` |
| [2.1-7] Patch / Version (Standby) | Database Version, Installed Components, Applied Patches — เหมือน primary แต่รันบน Standby | `v$instance`, `dba_registry`, `dba_registry_sqlpatch` |

---

## Script: pm_collect_primary.sql

**File**: `pm_collect_primary.sql`
**Role**: PRIMARY
**Status**: ✅ tested บน amsscdb/fdmccdb/fdmscdb@dbsystem2 (19.30.0.0.0) — ไม่มี error
**Output**: `output/YYYYMM/{cdb}_PRIMARY_{host}_{YYYYMM}.txt` (dynamic จาก `v$database` + `v$instance`)

### Sections

| Section | หัวข้อ 2.1 | Views หลัก |
|---|---|---|
| DB Identity | Header (2 query) | `v$database`, `v$instance` |
| [1.2 - DB Environment] | Global DB Name, SID, DB Location, Archive Dir/Mode, Flashback, Character Set | `global_name`, `v$database`, `v$parameter`, `nls_database_parameters` |
| [2.1-1] Instance Status | Instance status, uptime | `v$instance` |
| [2.1-2] Tablespace / Temp / Undo / Redo | TS usage (CDB+PDB), Temp (GB format เหมือน CDB Root), Undo stats, Redo log, Archive gen, FRA | `dba_segments`, `dba_data_files`, `cdb_segments`, `cdb_data_files`, `v$pdbs`, `dba_temp_free_space`, `dba_temp_files`, `v$undostat`, `v$log`, `v$archived_log`, `v$recovery_file_dest`, `v$flash_recovery_area_usage` |
| [2.1-3] Alert Log | Last 30 days, filter `%ORA-%` only, linesize 240, col 200 | `v$diag_alert_ext` |
| [2.1-4] Performance | AWR summary 31 วัน; Top 10 SQL stats (PDB only, con_id>1, group by **pdb_name+sql_id**, columns: PDB+SQL_ID+stats); Top 10 SQL Full Text (3-col table: PDB+SQL_ID+text, ordered by elapsed); Top 15 Wait Events delta 31 วัน (**dba_hist_system_event**, column=`event_name`, filter by dbid) | `dba_hist_snapshot`, `dba_hist_sqlstat`, `dba_hist_sqltext`, `dba_hist_system_event`, `v$pdbs` |
| [2.1-5] Backup / RMAN | RMAN job history 32 วัน (ไม่มี session_key, status a30, input_type a25, **linesize 160** เพื่อป้องกัน wrap) | `v$rman_backup_job_details` |
| [2.1-6] Parameters | Key params, SGA components, PGA stats | `v$parameter`, `v$sgainfo`, `v$pgastat` |
| [2.1-7] License / Patch | Version, Registry components, Applied patches | `v$instance`, `dba_registry`, `dba_registry_sqlpatch` |

---

## pm_collect.sh — Output Files

| ไฟล์ | เนื้อหา |
|---|---|
| `pm_collect_{host}_{YYYYMM}.log` | run log (status แต่ละ CDB) |
| `inventory_{host}_{YYYYMM}.txt` | CDB+PDB list, role, version |
| `oracle_config_{host}_{YYYYMM}.txt` | Platform, Edition, Oracle Home, Oracle Base, Grid Home |
| `listener_{host}_{YYYYMM}.txt` | ผลลัพธ์ `lsnrctl status` (server-wide) |
| `{cdb}_{ROLE}_{host}_{YYYYMM}.txt` | health check data (spool จาก SQL script) |
| `network_test_{host}_{YYYYMM}.txt` | ping + TCP 1521 test |
| `{YYYYMM}_{host}.zip` | zip ของไฟล์ทั้งหมดข้างต้น (ยกเว้น .docx และ .zip) — สร้างหลัง collection เสร็จ |

## pm_collect.sh

**Status**: ✅ tested บน dbsystem2 — รัน 3 CDB สำเร็จ
**วิธีรัน**: `./pm_collect.sh` (รันเป็น oracle user)

### Variables ที่ต้องตรวจสอบก่อนรัน
```bash
CDB_LIST="amsscdb fdmccdb fdmscdb"   # รายชื่อ CDB
TNSPING_TARGET                        # auto-detect จาก hostname:
                                      # dbsystem1 → AMSSCDB_STBY
                                      # dbsystem2 → AMSSCDB
```

### Network Test (tnsping)
| Test | Tool | วัดอะไร |
|---|---|---|
| tnsping | `$ORACLE_HOME/bin/tnsping` | Oracle Net connectivity + response time (ms) |

- dbsystem1 → `tnsping AMSSCDB_STBY` (ทดสอบการ connect ไปยัง Standby service)
- dbsystem2 → `tnsping AMSSCDB` (ทดสอบการ connect ไปยัง Primary service)

---

## Script: generate_report.py

**File**: `generate_report.py`
**Status**: ✅ tested — สร้าง .docx สำเร็จ
**Output**: `output/YYYYMM/รายงานการบำรุงรักษาระบบฐานข้อมูล_AMSS_{YEAR}_{SEQ}.docx`
**วิธีรัน**: `python3 generate_report.py` (ต้องติดตั้ง `python-docx`)

### Config Variables (แก้ก่อนรันทุกเดือน)
```python
MONTH_TAG  = "202605"   # YYYYMM
YEAR       = "2026"     # ปี CE
DOC_SEQ    = "1"        # ลำดับรายงานในปีนั้น

# Oracle config fallback — อ่านจาก oracle_config_{host}_{YYYYMM}.txt ก่อน ถ้าไม่มีใช้ค่านี้
ORACLE_PLATFORM  = "64-bit Oracle Linux"
ORACLE_EDITION   = "Oracle Database 19c Enterprise Edition"
ORACLE_GRID_HOME = "/u01/app/19.19.0.0/grid"
ORACLE_BASE      = "/u01/app/oracle"
ORACLE_HOME      = "/u01/app/oracle/product/19.0.0.0/dbhome_1"
```

### Cover Template: `หน้าปกรายงาน_วิทยุการบิน_AMSS.docx`
- เปิดไฟล์นี้เป็น base document ทุกครั้ง **(ไม่ overwrite)**
- มี: โลโก้ AEROTHAI, company header, จัดทำโดย/ตรวจสอบโดย, ประวัติเอกสาร, page break, สารบัญ (Word TOC field)
- ถ้าต้องการแก้ปก → แก้ที่ไฟล์นี้ไฟล์เดียว
- ไฟล์ปกอยู่ที่ project root — script ชี้ไปที่นั่นโดยตรง ไม่ต้อง copy

### setup_document() — สิ่งที่ทำกับ heading styles
- ลบ `numPr` ออกจาก Heading 1–4 ทุก level เพื่อป้องกันหัวข้อซ้อน (เลขซ้ำ) เมื่อ template มี list numbering ติดมา
- **ไม่ใส่** `w:updateFields` (หากใส่ Word จะถาม dialog ทุกครั้งที่เปิดไฟล์)
- **Update TOC**: right-click ที่ตาราง สารบัญ → Update Field → Update entire table

### Color Theme (ONPROD Blue — ใช้ตั้งแต่ 2026-05)
| ตัวแปร | Hex | ใช้ที่ |
|---|---|---|
| COLOR_H1–H4 | `#000000` | Headings ทุก level — สีดำ |
| COLOR_CELL_HEADER | `#DAEEF3` | Table header row fill — ฟ้าอ่อน |
| COLOR_HDR_TEXT | `#1F497D` | ข้อความใน header row — navy |
| COLOR_CELL_ODD/EVEN | `#FFFFFF` | Data rows — ขาวทั้งหมด (ไม่สลับสี) |
| COLOR_SECTION_HDR | `#DAEEF3` | Section/subheader merged row |
| COLOR_COVER_LABEL | `#DAEEF3` | Cover + summary label cells |
| COLOR_SQL_BOX | `#EBF3FB` | SQL command display box |
| COLOR_LOG_BOX | `#F2F2F2` | Gray placeholder log box |
| COLOR_FINDINGS_BOX | `#F5F5F5` | รายละเอียดของผลลัพธ์ — editable area |
| Table borders | `#4BACC6` size=8 | ทุกตาราง — teal-blue |

### Document Structure
```
[Cover — จาก หน้าปกรายงาน_วิทยุการบิน_AMSS.docx]
  โลโก้ AEROTHAI
  บริษัท วิทยุการบินแห่งประเทศไทย จำกัด
  จัดทำโดย / ตรวจสอบโดย
  ประวัติการแก้ไขเอกสาร / ตารางอนุมัติ
  ── page break ──
  สารบัญ (Word TOC field — update ด้วย right-click)
  ── page break ──

[Generated content]
Section 1  ข้อมูลระบบ (System Information)
  1.1  DC / Server & OS
    1.1.1  Oracle Database Configuration  ← ONPROD-style table
           (Software / Cluster Software / Database Software)
           อ่านจาก oracle_config_{host}_{YYYYMM}.txt; fallback → placeholder
  1.1.x  dbsystem1/2 – Inventory  (inventory_dbsystem1/2.txt — ไม่แสดง Restricted)
  1.2  CDB / PDB Inventory  (summary table)
    1.2.1  Oracle Database Environment  ← ONPROD-style label|value table (per CDB)
           Storage Mechanism: Global DB Name, SID, DB Location, Archive Dir, Archive Mode, Flashback
           Database Character Set: NLS_CHARACTERSET, NLS_NCHAR_CHARACTERSET
           อ่านจาก [1.2 - DB Environment] ใน PRIMARY log

Section 2  Database Enterprise Edition  [PRIMARY]
  2.1  AMSSCDB (PRIMARY @ dbsystem2)
    2.1.1  Instance Status  (ไม่มี Registered Services)
           รายละเอียดของผลลัพธ์ ←── หลังทุก section
    2.1.2  Tablespace / Temp / Undo / Redo Log
      2.1.2.1  CDB Root  (รายละเอียดของผลลัพธ์)
      2.1.2.2  PDB: AMSS  (รายละเอียดของผลลัพธ์)
      2.1.2.3  PDB: AMSSPDB  (รายละเอียดของผลลัพธ์)
    2.1.3  Alert Log  (รายละเอียดของผลลัพธ์)
    2.1.4  Performance (AWR / Top SQL / Wait Events)
      2.1.4.1  AWR Snapshot Summary (31 วัน)
      2.1.4.2  Top SQL by Elapsed Time (AWR - 31 วัน)  ← dba_hist_sqlstat, con_id>1 (PDB only)
               GROUP BY pdb_name, sql_id (join v$pdbs)
               columns: PDB, SQL_ID, Execs (999,999,999,999), Elapsed(s), CPU(s), Buf Gets (9,999,999,999,999), Disk Reads
      2.1.4.3  Top SQL — Full SQL Text  ← Word table 3-col (PDB | SQL_ID | SQL Text)
               เรียงตาม elapsed desc, con_id>1, render ด้วย add_sql_fulltext_table() (auto-detect 2/3 col)
      2.1.4.4  Top Wait Events (AWR - 31 วัน)  ← dba_hist_system_event delta
               column = `event_name` (ไม่ใช่ `event`), filter by dbid, instance_number
               สูตร: end_value - start_value (snap ล่าสุด - snap เก่าสุด ใน 31 วัน)
      รายละเอียดของผลลัพธ์
    2.1.5  RMAN Backup  (รายละเอียดของผลลัพธ์)
    2.1.6  Parameters (SGA / PGA)  (รายละเอียดของผลลัพธ์)
    2.1.7  Oracle Version  (รายละเอียดของผลลัพธ์)
    2.1.8  รายการตรวจสอบ  ← combined checklist table (ทุกหัวข้อ 2.1.1-2.1.7)
  2.2  FDMCCDB  (same structure)
  2.3  FDMSCDB  (same structure)
  2.4  Listener Status (dbsystem2)  ← lsnrctl status, 1 ตัวต่อ server

Section 3  Active Data Guard  [STANDBY]
  3.1  AMSSCDB (STANDBY @ dbsystem1)
    3.1.1  DG Configuration & Sync Status  (รายละเอียดของผลลัพธ์)
    3.1.2  Gap / Lag / Apply Delay  (รายละเอียดของผลลัพธ์)
    3.1.3  Log Transport & Apply Service  (รายละเอียดของผลลัพธ์)
    3.1.4  Disk Usage & FRA  (รายละเอียดของผลลัพธ์)
    3.1.5  Alert Log (Standby)  (รายละเอียดของผลลัพธ์)
    3.1.6  RMAN on Standby  (รายละเอียดของผลลัพธ์)
    3.1.7  รายการตรวจสอบ  ← combined checklist table (ทุกหัวข้อ 3.1.1-3.1.6)
  3.2  FDMCCDB  (same)
  3.3  FDMSCDB  (same)

Section 4  Patch
  4.1  OPatch Patches  (dbsystem1, dbsystem2 — รายละเอียดของผลลัพธ์ หลังแต่ละ server)
  4.2  Oracle Critical Patch Update (CPU)
       ← เนื้อหาจาก lasted_oracle_critical_patch_update.docx
       - "Latest Patch" heading + URL oracle.com/security-alerts
       - embed image1.png + image2.png จาก docx
       - CPU Releases Table (Word table — ★ latest highlighted)
       - Risk Matrix Table (CVE ID, Component, CVSS Base Score, Remote Exploit, Versions)
       - รายละเอียดของผลลัพธ์ + default finding text

Section 5  Network
  5.1  tnsping Test  (network_test_{host}_{YYYYMM}.txt — tnsping output จาก pm_collect.sh)
       dbsystem1 → tnsping AMSSCDB_STBY
       dbsystem2 → tnsping AMSSCDB
       รายละเอียดของผลลัพธ์
  5.2  Network Bandwidth  (manual — รายละเอียดของผลลัพธ์)

Section 6  สรุปผลการตรวจสอบ (Summary)
  - ตาราง summary: CDB | Section | รายการ | สถานะ | หมายเหตุ
  - ผลโดยรวม
  - ลายเซ็นผู้ตรวจสอบ
```

### Checklist Table
- คอลัมน์ **สถานะ**: แสดง 2 บรรทัดในเซลล์เดียว (`w:br` คั่นกลาง)
  ```
  ☐  ปกติ
  ☐  ไม่ปกติ
  ```

### Log Box Source Files
| Section | Source File |
|---|---|
| 1.1.1 | `oracle_config_{host}_{YYYYMM}.txt` (จาก pm_collect.sh) |
| 1.1.x | `inventory_{host}_{YYYYMM}.txt` |
| 1.2.1 | `{cdb}_PRIMARY_{primary_server}_{YYYYMM}.txt` → section `[1.2 - DB Environment]` |
| 2.x.* | `{cdb}_PRIMARY_{primary_server}_{YYYYMM}.txt` |
| 2.4 Listener | `listener_{primary_server}_{YYYYMM}.txt` (จาก pm_collect.sh — lsnrctl status) |
| 3.x.* | `{cdb}_STANDBY_{standby_server}_{YYYYMM}.txt` |
| 4.1 | `{cdb}_PRIMARY_{host}_{YYYYMM}.txt` → section `[2.1-7]` |
| 4.1 dbsystem1 | `{cdb}_STANDBY_{host}_{YYYYMM}.txt` → section `[2.1-7]` (เพิ่งเพิ่มใน pm_collect_standby.sql) |
| 5.1 tnsping | `network_test_{host}_{YYYYMM}.txt` (tnsping output จาก pm_collect.sh) |
| 5.2 Bandwidth | ผลทดสอบ manual file transfer |

### SQL Command Display
ทุก section ที่แสดงผล query จะมี **"คำสั่ง SQL:" box** (สี `#EBF3FB`) ก่อน result — sourced จาก `pm_collect_primary.sql` / `pm_collect_standby.sql` ผ่าน `SqlScriptReader` class  
- Global instances: `SQL_PRIMARY`, `SQL_STANDBY` (load ตอน import)
- Helper: `add_sql_cmd(doc, sql_text)` — Courier New 8pt, สี navy
- หากไม่พบ label ที่ตรงกัน box จะไม่แสดง (silent skip)

---

## Known Issues & Fixes

| ปัญหา | สาเหตุ | แก้ไข |
|---|---|---|
| `ORA-00904: "V"."VERSION"` | `v$version.version` ถูกเปลี่ยนใน 19c | ใช้ `v$instance.version_full` แทน |
| `Enter value for ...` | `set define on` (default) อ่าน `&` เป็น substitution | `set define off` หลัง spool command |
| Query บน Standby fail | บาง view ไม่มีข้อมูลบน read-only standby | ใช้ `whenever sqlerror continue` |
| `ORA-00904: "FAST_START_FAILOVER"` | `v$dg_broker_config` บน 19.31 ไม่มี column นี้ | ลบออก |
| `ORA-00904: "NAME"` (dg_broker_config) | `v$dg_broker_config` ไม่ accessible บน standby 19.31 | ลบ query ทิ้ง (protection_mode อยู่ใน header แล้ว) |
| `ORA-00904: "ROLE"/"ENABLED"/etc.` (dataguard_config) | `v$dataguard_config` บน 19.31 schema จริง: `DB_UNIQUE_NAME`, `PARENT_DBUN`, `DEST_ROLE`, `CURRENT_SCN`, `CON_ID` เท่านั้น | ใช้ตาม schema จริง |
| `ORA-00904: "TARGET"` (archive_dest_status) | `v$archive_dest_status` บน Standby 19.31 ไม่มี `TARGET` | ใช้ `where status != 'INACTIVE'` แทน |
| `ORA-00904: "TARGET"` (archive_dest) | `v$archive_dest` บน Standby 19c ไม่มี `TARGET` column | ลบ `where target = 'STANDBY'` ออก — ใช้ `where status != 'INACTIVE'` เท่านั้น |
| `ORA-00904: "APPLIED_SCN"` (archive_dest_status) | `v$archive_dest_status` บน 19.31 ไม่มี column นี้ | ลบออก |
| `ORA-00904: "END_TIME"` | `v$recovery_progress` บน 19c ไม่มี `end_time` | ลบออก (มีแค่ `start_time`) |
| `ORA-00904: "REOPEN"` | `v$archive_dest` บน 19c เปลี่ยนชื่อ | ใช้ `reopen_secs` แทน |
| `ORA-00904: "DELAY"` (archive_dest) | `v$archive_dest` บน 19c เปลี่ยนชื่อ | ใช้ `delay_mins` แทน |
| `ORA-00904: "VERSION"` (sqlpatch) | `dba_registry_sqlpatch` บน 19.30 ไม่มี column นี้ | ลบออก |
| `########` ใน Top SQL | format mask เล็กเกินสำหรับ executions/buffer_gets | ใช้ `999,999,999,999` และ `9,999,999,999,999` |
| `ORA-00904: "E"."EVENT"` (dba_hist_system_event) | column ชื่อ `event_name` ไม่ใช่ `event` (ต่างจาก v$system_event) | ใช้ `e.event_name` และ `s.event_name` |
| `ORA-00904: "S"."TIME_WAITED"` (dba_hist_system_event) | column ชื่อ `time_waited_micro` (microseconds) ไม่ใช่ `time_waited` (centiseconds ของ v$system_event) | ใช้ `time_waited_micro` หาร 1,000,000 = วินาที; avg_wait_ms หาร 1,000 |
| RMAN table แสดง `Input(GB) Output(GB)` เป็น data row | linesize 115 แคบเกิน ทำให้ Part2 header wrap เป็น data | ใช้ `set linesize 160` ก่อน RMAN query |
| Top SQL ไม่รู้ว่ามาจาก PDB ไหน | `GROUP BY sql_id` เดียวรวมทุก PDB | เพิ่ม `join v$pdbs` และ `GROUP BY pdb_name, sql_id` |
| Header ตาราง SQLPlus ตกคอลัมน์ (numeric first col) | `_split_subs` ใช้ `.strip()` ลบ leading space ของ numeric column header ทำให้ col bounds เลื่อน 1 ตำแหน่ง | เปลี่ยนเป็น `.strip('\n')` เพื่อรักษา leading space; Instance Status ใช้ hardcoded headers เพิ่มเติม |
| Multi-subsection section แสดง sub-header เป็น data row | `add_sql_section` ดึง raw content ไม่มี marker → parser อ่าน `--- Label -- PROMPT` เป็น data | เปลี่ยนเป็น `add_sql_section_keys` ซึ่งเพิ่ม `--- Label ---` markers ระหว่าง subsections |
| dbsystem1 ไม่มีข้อมูล Patch/Registry ใน Section 4.1 | code ตรวจแค่ `primary_server == host` — dbsystem1 เป็น Standby ไม่มี PRIMARY log | เพิ่ม [2.1-7] ใน pm_collect_standby.sql; generate_report.py fallback ไปอ่าน STANDBY log |

---

## SQLPlus Format Standards

### Spool filename (dynamic)
```sql
-- ดึง CDB name และ hostname จาก Oracle เพื่อสร้างชื่อไฟล์อัตโนมัติ
-- spool ลงใน output/YYYYMM_hostname/ (ตรงกับ pm_collect.sh OUTPUT_DIR)
col spool_dir new_value spool_dir noprint
col spool_fn  new_value spool_fn  noprint
select
    'output/'||to_char(sysdate,'YYYYMM')||'_'||lower(i.host_name)   spool_dir,
    'output/'||to_char(sysdate,'YYYYMM')||'_'||lower(i.host_name)||'/'
        ||lower(d.name)||'_{ROLE}_'||lower(i.host_name)||'_'
        ||to_char(sysdate,'YYYYMM')||'.txt'                          spool_fn
from v$database d, v$instance i;

host mkdir -p &spool_dir
spool &spool_fn
```

### ลำดับ settings ที่สำคัญ
```sql
-- Phase 1: ก่อน spool (define ต้อง ON เพื่อใช้ &variable)
set feedback off
set verify off
set echo off
whenever sqlerror continue
-- << spool setup และ host mkdir อยู่ตรงนี้ >>

-- Phase 2: หลัง spool
set linesize 200
set pagesize 50
set trimspool on
set heading on
set timing off
set define off
```

### Section Separator
```sql
PROMPT
PROMPT ========================================================
PROMPT  [X.X - N] SECTION TITLE
PROMPT ========================================================
PROMPT
```

### Column Format Pattern
```sql
col column_name  for a30              heading 'Display Name'
col number_col   for 999,999,999      heading 'Number'      -- ใช้ comma สำหรับตัวเลขใหญ่
col date_col     for a22              heading 'Date'
-- date ใช้ to_char(...,'DD-MON-YYYY HH24:MI:SS')
```

---

## Key Oracle 19c Notes
- `v$instance.version_full` → full version string (เช่น `19.30.0.0.0`)
- `v$version.version` → **ไม่มีใน 19c** ให้หลีกเลี่ยง
- `fetch first N rows only` → ใช้แทน `where rownum <=` ได้ใน 12c+
- CDB-level views: ใช้ `CDB_*` แทน `DBA_*` พร้อม join `v$pdbs` เพื่อดูแยก PDB
- `dba_registry_sqlpatch` ใน 19.30: ไม่มี column `VERSION`
- `v$dataguard_config` ใน 19.31: มีแค่ `DB_UNIQUE_NAME`, `PARENT_DBUN`, `DEST_ROLE`, `CURRENT_SCN`, `CON_ID`

---

## Next Steps
1. ✅ `pm_collect_standby.sql` — tested, no errors (amsscdb@dbsystem1 19.31)
2. ✅ `pm_collect_primary.sql` — tested, no errors (all CDBs@dbsystem2 19.30)
3. ✅ `pm_collect.sh` — tested บน dbsystem2, รัน 3 CDB สำเร็จ
4. ✅ `generate_report.py` — ใช้ cover template (AEROTHAI logo + สารบัญ), output ชื่อไฟล์ใหม่
5. ✅ Color theme เปลี่ยนเป็น ONPROD Blue (DAEEF3/1F497D/4BACC6) — 2026-05
6. ✅ เพิ่ม SQL command display ก่อน result ทุก section — 2026-05
7. ✅ เพิ่ม Section 1.1.1 Oracle Database Configuration (ลบ Cluster Software แล้ว) — 2026-05
8. ✅ `pm_collect.sh` เพิ่ม oracle_config + lsnrctl status collection — 2026-05
9. ✅ เพิ่ม Section 1.2.1 Oracle Database Environment (per CDB, UNION ALL 2-col format) — 2026-05
10. ✅ เพิ่ม Listener Status ท้าย Section 2 (1 ตัวต่อ server) — 2026-05
11. ✅ Performance — AWR 31 วัน, Top SQL (con_id>1, group by sql_id), Full Text Word table — 2026-05
12. ✅ Wait Events เปลี่ยนจาก v$system_event → dba_hist_system_event delta 31 วัน — 2026-05
13. ✅ ลบ Active User Sessions ออกจากทั้ง SQL และ report — 2026-05
14. ✅ Alert Log ขยาย message_text เป็น 200 chars, linesize 240 — 2026-05
15. ✅ RMAN: ลบ session_key, ขยาย status a30, input_type a25 — 2026-05
16. ✅ Combined checklist ท้าย CDB + `รายละเอียดของผลลัพธ์` (plain text) หลังทุก section — 2026-05
17. ✅ Section 4.2 CPU content จาก `lasted_oracle_critical_patch_update.docx` — 2026-05
18. ✅ แก้ spool path ใน SQL scripts → `output/YYYYMM_HOSTNAME/` (ตรงกับ pm_collect.sh) — 2026-05
19. ✅ `_parse_db_env_old_format()` — fallback parser รองรับ log format เก่า (6-col wrapped) — 2026-05
20. ✅ แก้ `pm_collect_standby.sql` ลบ `target = 'STANDBY'` (ORA-00904) — 2026-05
21. ✅ Alert Log: เพิ่ม `PROMPT --- Alert Log ---` marker ใน primary และ standby — 2026-05
22. ✅ RMAN: เพิ่ม `PROMPT --- RMAN Backup ---` marker + `set linesize 160` — 2026-05
23. ✅ Wait Events: แก้ `e.event` → `e.event_name` (dba_hist_system_event), เพิ่ม dbid/instance_number filter — 2026-05
24. ✅ Top SQL: เพิ่ม PDB column, GROUP BY pdb_name+sql_id, join v$pdbs — 2026-05
25. ✅ Top SQL Full Text: เพิ่ม PDB column, auto-detect 2/3 col ใน add_sql_fulltext_table() — 2026-05
26. ✅ Top SQL format mask: Execs `999,999,999,999`, Buf Gets `9,999,999,999,999` — 2026-05
27. ✅ Section 5 เปลี่ยนจาก ping+nc เป็น tnsping (dbsystem1→AMSSCDB_STBY, dbsystem2→AMSSCDB) — 2026-05
28. ✅ เพิ่ม [2.1-7] Patch/Version ใน pm_collect_standby.sql (dbsystem1 fallback) — 2026-05
29. ✅ แก้ `_split_subs` `.strip()` → `.strip('\n')` + hardcode Instance Status headers — 2026-05
30. ✅ เปลี่ยน multi-subsection sections เป็น `add_sql_section_keys` — 2026-05
31. ✅ Inventory table ใช้ flat structure (1 row per PDB) — 2026-05
32. 🔲 รัน `pm_collect.sh` (version ใหม่) บน dbsystem1 และ dbsystem2 เพื่อ generate log ครบทุกไฟล์
33. 🔲 ผู้ใช้ right-click สารบัญ → Update Field → Update entire table หลังเปิดไฟล์
34. 🔲 เพิ่ม OPatch lsinventory ใน script (ถ้าต้องการ capture แบบอัตโนมัติ)

## Checklist รันรายเดือน
1. Copy scripts ใหม่ (`pm_collect.sh`, `pm_collect_primary.sql`, `pm_collect_standby.sql`) ขึ้น server ทั้งสองเครื่อง
2. รัน `./pm_collect.sh` บน **dbsystem2** (PRIMARY side)
3. รัน `./pm_collect.sh` บน **dbsystem1** (STANDBY side)
4. Copy `YYYYMM_dbsystem1.zip` และ `YYYYMM_dbsystem2.zip` มาไว้ใน `output/`
5. แตก zip ใส่ `output/YYYYMM_dbsystem1/` และ `output/YYYYMM_dbsystem2/`
6. แก้ `MONTH_TAG`, `YEAR`, `DOC_SEQ` ใน `generate_report.py`
7. รัน `python3 generate_report.py`
8. เปิดไฟล์ output → right-click สารบัญ → **Update Field**
9. ตรวจสอบ / กรอก `รายละเอียดของผลลัพธ์` ที่ต้องการแก้ไข + Section 5.2 Bandwidth

> หมายเหตุ: `หน้าปกรายงาน_วิทยุการบิน_AMSS.docx` อยู่ที่ project root — ไม่ต้อง copy ไปไว้ใน output
