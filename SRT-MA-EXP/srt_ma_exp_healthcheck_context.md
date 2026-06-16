# SRT MA-EXP Health Check — Project Context

## Project Overview

- **รหัสโครงการ**: I-2026-APW-MA-027
- **ชื่อโครงการ**: จ้างบริการบำรุงรักษาระบบฐานข้อมูลแม่ข่ายและระบบบริการฐานข้อมูลส่วนเพิ่มขยาย (SRT Database Cloud + Expand)
- **Goal**: รายงานผลการบำรุงรักษา + รายงานการเฝ้าระวังภัยคุกคาม ส่งลูกค้าราย 3 เดือน (รายไตรมาส)
- **แพลตฟอร์ม**: Oracle RAC 19c, Microsoft SQL Server 2019, Windows Server 2019 + WSFC
- **ข้อกำหนดสัญญา**: ดู [[TOR]]

---

## หัวข้อตรวจสอบ Oracle RAC 19c (Preventive Checklist)

| หัวข้อ | รายการตรวจสอบ | Views / Commands หลัก |
| ------ | ------------ | --------------------- |
| Clusterware & Instance | Grid Infrastructure status, Node status ทุก node | `crsctl stat res -t`, `srvctl status database` |
| Storage & ASM | ASM Disk Group usage/status | `v$asm_diskgroup`, `v$asm_disk` |
| Alert Log | Critical errors (ORA-) 31 วันล่าสุด | `v$diag_alert_ext` |
| Tablespace | Usage per tablespace (CDB + PDB) | `dba_data_files`, `cdb_data_files`, `v$pdbs` |
| Backup / RMAN | Job history 32 วัน | `v$rman_backup_job_details` |
| Performance | CPU/Memory, Top Wait Events (AWR 31 วัน) | `dba_hist_system_event`, `dba_hist_sqlstat`, `v$pgastat`, `v$sgainfo` |

---

## หัวข้อตรวจสอบ Oracle Enterprise Manager 13c + WebLogic (Preventive Checklist)

| หัวข้อ | รายการตรวจสอบ | Commands / URL หลัก |
| ------ | ------------ | ------------------- |
| EM Console | OMS Service status, Login ได้ปกติ | `emctl status oms` |
| Managed Targets | Database/Listener targets ที่ monitor อยู่ status Up | EM Console → Targets |
| EM Agent | Agent บน server ที่ monitor: status, last upload | `emctl status agent` |
| WebLogic | Admin Server & Managed Server status | `wlst.sh`, EM Console → WebLogic |
| EM Repository | Repository DB health (tablespace, alert log) | EM Console → Repository |

---

## หัวข้อตรวจสอบ Microsoft SQL Server + WSFC (Preventive Checklist)

| หัวข้อ | รายการตรวจสอบ | Commands หลัก |
| ------ | ------------ | ------------- |
| WSFC — Cluster Health | Cluster service status, Node status (Up/Down/Paused) | `Get-ClusterNode`, `Get-Cluster` |
| WSFC — Quorum | Quorum resource status, Disk Witness / Cloud Witness | `Get-ClusterQuorum` |
| WSFC — Cluster Events | Critical events ใน Cluster Event Log | Windows Event Viewer → FailoverClustering |
| Service & Instance | SQL Server Service, SQL Server Agent | `Get-Service MSSQL*`, `EXEC xp_servicecontrol` |
| Database Integrity | DBCC CHECKDB ทุก database | `DBCC CHECKDB` |
| Index Maintenance | Rebuild / Reorganize, Update Statistics | `sys.dm_db_index_physical_stats`, SQL Agent Job history |
| Log Review | SQL Server Error Log, Windows Event Log | `EXEC xp_readerrorlog`, Windows Event Viewer |

---

## Checklist Table Format

คอลัมน์ **สถานะ** แสดง 2 บรรทัดในเซลล์เดียว:

```text
☐  ปกติ
☐  ไม่ปกติ
```

---

## Next Steps

- 🔲 สร้าง `pm_collect_oracle_rac.sh` สำหรับเก็บข้อมูล Oracle RAC
- 🔲 สร้าง `pm_collect_rac.sql` (Primary SQL script สำหรับ RAC — ไม่มี DG)
- 🔲 สร้าง `pm_collect_mssql.sql` หรือ PowerShell script สำหรับ MSSQL + WSFC
- 🔲 สร้าง `generate_report_maintenance.py` — รายงานการบำรุงรักษา (ข้อ 3.7)
- 🔲 สร้าง `generate_report_security.py` — รายงานเฝ้าระวังภัยคุกคาม (ข้อ 3.13)
- 🔲 ออกแบบ template หน้าปก (SRT)
