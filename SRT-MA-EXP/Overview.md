# SRT-MA-EXP — Overview

## ข้อมูลโครงการ

| รายการ | ข้อมูล |
| ------ | ------ |
| รหัสโครงการ | I-2026-APW-MA-027 |
| ชื่อโครงการ | จ้างบริการบำรุงรักษาระบบฐานข้อมูลแม่ข่ายและระบบบริการฐานข้อมูลส่วนเพิ่มขยาย (SRT Database Cloud + Expand) |
| Site | SRT |
| แพลตฟอร์ม | Oracle RAC 19c + Microsoft SQL Server |
| Script Path | `/Users/phonr/Github/Projects_Maintenance/srt-ma-exp-healthcheck/` |

---

## รายงานที่ต้องส่ง

| รายงาน | ข้อสัญญา | คาบเวลา |
| ------ | --------- | ------- |
| รายงานการบำรุงรักษา | ข้อ 3.7 | ราย 3 เดือน (รายไตรมาส) |
| รายงานการเฝ้าระวังภัยคุกคามทางสารสนเทศ | ข้อ 3.13 | ราย 3 เดือน (รายไตรมาส) |

---

## Infrastructure (จาก Survey)

### Oracle RAC 19c (Solaris)

| รายการ | ข้อมูล |
| ------ | ------ |
| OS | Oracle Solaris 11.4.19.3.0 (SunOS 5.11) |
| Architecture | SPARC sun4v |
| Hostnames | SRTODB1, SRTODB2 |
| CPU | 80 cores / node |
| Oracle Clusterware | 19.0.0.0.0 |
| Databases | OLAPCDB, OLTPCDB, SRTDW, TRAINING |
| CDB | ใช่ (พบ PDB: PRODMEDB, APEXDB) |
| ASM Disk Groups | DATA (12.5 TB), RECO (18.9 TB), OCR_VOTE |

### Microsoft SQL Server (Windows)

| รายการ | ข้อมูล |
| ------ | ------ |
| OS | Microsoft Windows Server 2019 Standard Edition |
| Cluster | Windows Server Failover Cluster (WSFC) |
| SQL Server | Microsoft SQL Server 2019 Standard Edition |
| Hostnames | — (ยังไม่ยืนยัน) |

---

## รายการซอฟต์แวร์ที่ต้องตรวจสอบ (ตามสัญญา)

| รายการ | ซอฟต์แวร์ | เวอร์ชัน |
| ------ | --------- | -------- |
| 1 | Oracle Database + Cloud Management Pack + Database Lifecycle Management Pack + Real Application Clusters | 19c Enterprise Edition |
| 2 | Microsoft SQL Server | 2019 Standard Edition |
| 3 | Oracle Enterprise Manager (Management Server) + WebLogic Server | EM 13c / WebLogic 12c Enterprise Edition |
| 4 | ซอฟต์แวร์ระบบจัดการฐานข้อมูลส่วนต่อขยาย (Database Management Expansion) | ดูรายละเอียดด้านล่าง |
| 5 | Microsoft Windows Server + Windows Server Failover Cluster (WSFC) | 2019 Standard Edition |

### รายละเอียด Item 4 — Database Management Expansion (License Add-ons)

#### Enterprise Edition Options

| Option | หน้าที่ |
| ------ | ------- |
| Real Application Clusters (RAC) | High Availability — run DB บน multiple nodes |
| Multitenant | CDB/PDB architecture — รัน multiple PDB ใน 1 CDB |

#### Database Enterprise Management Packs

| Pack | หน้าที่ |
| ---- | ------- |
| Lifecycle Management | Patch, Provisioning, Configuration Management ผ่าน EM |
| Cloud Management | Self-service portal, Resource metering ผ่าน EM |
| Diagnostics | AWR, ASH, ADDM — Performance diagnostics |
| Tuning | SQL Tuning Advisor, SQL Access Advisor |

---

## ขอบเขตงาน

### Oracle RAC 19c

- Clusterware & Instance Health (Grid Infrastructure, Node status)
- Storage & ASM (Disk Group usage/status)
- Alert Log (Critical Errors 31 วันล่าสุด)
- Tablespace Usage (CDB + PDB)
- Backup / RMAN Status
- Performance (CPU/Memory, Top Wait Events AWR 31 วัน)

### Microsoft SQL Server + WSFC

- **Windows Server Failover Cluster**: Cluster Node Status, Cluster Service, Quorum
- Service & Instance Status (SQL Server Service, SQL Agent)
- Database Integrity (DBCC CHECKDB)
- Maintenance Jobs (Index Rebuild/Reorganize, Update Statistics)
- Log Review (SQL Server Error Log, Windows Event Log, Cluster Event Log)

### Oracle Enterprise Manager 13c + WebLogic Server 12c

- EM Console Availability & Login
- Managed Targets Status (Databases, Listeners)
- Agent Status (OMS Agent บน server ที่ Monitor)
- WebLogic Server: Admin Server & Managed Server Status
- EM Repository Database Health

### Security (ข้อ 3.11 + 3.13)

- Oracle Critical Patch Update (CPU)
- MSSQL Security Updates / Cumulative Update
- Vulnerability Assessment

---

## Scripts (To Be Created)

| ไฟล์ | หน้าที่ | สถานะ |
| ---- | ------- | ----- |
| `pm_collect_oracle_rac.sh` | เก็บข้อมูล Oracle RAC (Solaris) | 🔲 ยังไม่สร้าง |
| `pm_collect_rac.sql` | SQL script สำหรับ RAC | 🔲 ยังไม่สร้าง |
| `pm_collect_mssql.sql` | Script สำหรับ MSSQL | 🔲 ยังไม่สร้าง |
| `generate_report_maintenance.py` | รายงานบำรุงรักษา (ข้อ 3.7) | 🔲 ยังไม่สร้าง |
| `generate_report_security.py` | รายงานเฝ้าระวัง (ข้อ 3.13) | 🔲 ยังไม่สร้าง |

---

## คำถามที่ยังต้องยืนยัน

- [ ] PDB แต่ละ CDB ครบหรือไม่ (PRODMEDB, APEXDB อยู่ใน CDB ไหน? SRTDW/TRAINING เป็น CDB ด้วยไหม?)
- [ ] Oracle patch version
- [x] MSSQL: Microsoft SQL Server 2019 Standard Edition
- [ ] วิธี connect เข้า server (SSH / Bastion)

---

## ลิงก์

- [[Monthly Checklist]]
- [[Infrastructure Survey]]
- Context เต็ม: `/srt-ma-exp-healthcheck/srt_ma_exp_healthcheck_context.md`
