# TOR — ขอบเขตของงาน (Terms of Reference)

โครงการ: จ้างบริการบำรุงรักษาระบบฐานข้อมูลแม่ข่ายและระบบบริการฐานข้อมูลส่วนเพิ่มขยาย (SRT Database Cloud + Expand)
รหัสโครงการ: I-2026-APW-MA-027

---

## รายงานที่ต้องส่ง

| รายงาน | ข้อสัญญา | คาบเวลา |
| ------ | --------- | ------- |
| รายงานการบำรุงรักษา | ข้อ 3.7 | ราย 3 เดือน (รายไตรมาส) |
| รายงานการเฝ้าระวังภัยคุกคามทางสารสนเทศ | ข้อ 3.13 | ราย 3 เดือน (รายไตรมาส) |
| รายงานการประเมินความเสี่ยงด้านการรักษาความมั่นคงปลอดภัยไซเบอร์ | ข้อ 3.14 | อย่างน้อย 1 ครั้ง (งวดงานที่ 1) |

---

## รายการซอฟต์แวร์ที่ต้องตรวจสอบ (ตามสัญญา)

| รายการ | ซอฟต์แวร์ | เวอร์ชัน |
| ------ | --------- | -------- |
| 1 | Oracle Database + Cloud Management Pack + Database Lifecycle Management Pack + Real Application Clusters | 19c Enterprise Edition |
| 2 | Microsoft SQL Server | 2019 Standard Edition |
| 3 | Oracle Enterprise Manager (Management Server) + WebLogic Server | EM 13c / WebLogic 12c Enterprise Edition |
| 4 | ซอฟต์แวร์ระบบจัดการฐานข้อมูลส่วนต่อขยาย (Database Management Expansion) | ดูรายละเอียดด้านล่าง |
| 5 | Microsoft Windows Server + Windows Server Failover Cluster (WSFC) | 2019 Standard Edition |

### รายละเอียด Item 1 — Oracle License (CSI# 23023146)

| Product | Qty | License Metric | License Type |
| ------- | --- | -------------- | ------------ |
| Oracle Database Enterprise Edition | 8 | Processor Perpetual | FULL USE |
| Oracle Cloud Management Pack for Oracle Database | 8 | Processor Perpetual | FULL USE |
| Oracle Database Lifecycle Management Pack | 8 | Processor Perpetual | FULL USE |
| Oracle Real Application Clusters | 8 | Processor Perpetual | FULL USE |
| Oracle WebLogic Server Enterprise Edition | 4 | Processor Perpetual | FULL USE |

| Support Type | ช่วงเวลา |
| ------------ | -------- |
| Reinstatement Fee | 1-Nov-2025 ถึง 31-Mar-2026 |
| Software Update License & Support | 1-Apr-2026 ถึง 30-Apr-2027 |

> WebLogic Server EE อยู่ใน CSI# เดียวกัน (23023146) แต่ Qty 4 processors (ไม่ใช่ 8)

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

#### รายละเอียด Item 4 — Oracle License (CSI# 27500566)

| Product | Qty | License Metric | License Type |
| ------- | --- | -------------- | ------------ |
| Oracle Database Enterprise Edition | 4 | Processor Perpetual | FULL USE |
| Oracle Cloud Management Pack for Oracle Database | 4 | Processor Perpetual | FULL USE |
| Oracle Database Lifecycle Management Pack | 4 | Processor Perpetual | FULL USE |
| Oracle Real Application Clusters | 4 | Processor Perpetual | FULL USE |
| Oracle Diagnostics Pack | 12 | Processor Perpetual | FULL USE |
| Oracle Multitenant | 12 | Processor Perpetual | FULL USE |
| Oracle Tuning Pack | 12 | Processor Perpetual | FULL USE |

| Support Type | ช่วงเวลา |
| ------------ | -------- |
| Reinstatement Fee | 25-Feb-2026 ถึง 31-Mar-2026 |
| Software Update License & Support | 1-Apr-2026 ถึง 30-Apr-2027 |

---

## ข้อกำหนดการเข้าปฏิบัติงาน

### ข้อ 3.4 — ความถี่และเวลา

- บำรุงรักษาอย่างน้อยงวดละ 1 ครั้ง
- ต้องดำเนินการในเวลาราชการ
- การดำเนินการต้องกระทบต่อผู้ใช้งานให้น้อยที่สุด

### ข้อ 3.5 — การแจ้งล่วงหน้า

| กรณี | ระยะเวลาแจ้งล่วงหน้า |
| ---- | ------------------- |
| ปกติ (เวลาราชการ) | อย่างน้อย 3 วันทำการ |
| นอกเวลาราชการ | อย่างน้อย 5 วันทำการ |

- หากต้องปิดระบบชั่วคราว: อนุญาตเฉพาะ **12:00–13:00 น.** เท่านั้น มิฉะนั้นต้องดำเนินการนอกเวลาราชการ
- ต้องแจ้งรายละเอียดให้ชัดเจน ผู้ควบคุมโครงการอาจปฏิเสธการเข้าปฏิบัติงานหากแจ้งไม่ครบ

### ข้อ 3.6 — การพบความผิดปกติระหว่างบำรุงรักษา

- หากพบความผิดปกติ / ชำรุดเสียหาย / เสื่อมสภาพ → **ลงบันทึกในรายงานบำรุงรักษา** + **แจ้งผู้ควบคุมโครงการทันที**
- ดำเนินการซ่อมแซมแก้ไขต่อตามข้อ 3.8

---

## ข้อกำหนดการเฝ้าระวังภัยคุกคามทางสารสนเทศ

### ข้อ 3.11 — กิจกรรมที่ต้องดำเนินการอย่างน้อยงวดละ 1 ครั้ง

- Service Pack Update
- Security Update
- Patch Update
- Signature Update
- Version Upgrade
- Virus Signature Update

(ให้เป็นไปตามสิทธิที่ รฟท. ได้รับ — หาก รฟท. ตรวจพบภัยคุกคามต้องแก้ไขทันทีที่ได้รับแจ้ง)

### ข้อ 3.12 — การแจ้งรายชื่อผู้ปฏิบัติงาน

- ต้องแจ้งรายชื่อผู้ปฏิบัติงานที่มีหน้าที่เฝ้าระวังภัยคุกคามให้ รฟท. ทราบเมื่อเริ่มสัญญา
- หากมีการเปลี่ยนแปลงบุคคล ต้องแจ้ง รฟท. ทุกครั้งก่อนดำเนินการทันที

---

## โครงสร้างรายงาน

### รายงาน 1: รายงานการบำรุงรักษา (ข้อ 3.7)

```text
[หน้าปก]  ← (ก) ตามข้อ 3.7
  ชื่อโครงการ
  ชื่อผู้รับจ้าง
  งวดงานที่
  คาบเวลาการบำรุงรักษา
  วันที่และเวลาเข้าปฏิบัติงาน
  วันที่และเวลาที่ปฏิบัติงานแล้วเสร็จ
  รายชื่อผู้ปฏิบัติงานทั้งหมด

Section 1  บัญชีสรุปรายการอุปกรณ์และซอฟต์แวร์ที่บำรุงรักษา  ← (ข) ตามข้อ 3.7
  - ตาราง: รายการ | เวอร์ชัน | สรุปผลการบำรุงรักษา

Section 2  Oracle RAC 19c  ← (ค) ตามข้อ 3.7
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

Section 3  Microsoft SQL Server + WSFC
  3.1  Windows Server Failover Cluster
    3.1.1  Cluster Node Status
    3.1.2  Quorum Status
    3.1.3  Cluster Event Log
  3.2  Service & Instance Status
    3.2.1  SQL Server Service Status
    3.2.2  SQL Server Agent Status
  3.3  Database Integrity
    3.3.1  DBCC CHECKDB Results
  3.4  Maintenance Jobs
    3.4.1  Index Rebuild / Reorganize
    3.4.2  Update Statistics
    3.4.3  Job History Summary
  3.5  Log Review
    3.5.1  SQL Server Error Log
    3.5.2  Windows Event Log (Database-related)
  3.6  รายการตรวจสอบ (Checklist)

Section 4  Oracle Enterprise Manager 13c + WebLogic Server 12c
  4.1  EM Console & OMS Status
  4.2  Managed Targets Status
  4.3  WebLogic Admin/Managed Server Status
  4.4  รายการตรวจสอบ (Checklist)

Section 5  สรุปผลการบำรุงรักษา
  - ตาราง: ระบบ | รายการ | ผลการตรวจสอบ | สถานะ | หมายเหตุ
  - ปัญหาหรือสิ่งผิดปกติที่ตรวจพบระหว่างปฏิบัติงาน
  - ข้อเสนอแนะและแนวทางในการดำเนินการซ่อมแซมและแก้ไข

[ลายมือชื่อ]
  ลายมือชื่อผู้ปฏิบัติงาน
  ลายมือชื่อผู้ควบคุมโครงการหรือผู้ควบคุมการปฏิบัติงาน
```

---

### รายงาน 2: รายงานการเฝ้าระวังภัยคุกคามทางสารสนเทศ (ข้อ 3.13)

```text
[หน้าปก]  ← (ก) ตามข้อ 3.13
  ชื่อโครงการ
  ชื่อผู้รับจ้าง
  งวดงานที่
  คาบเวลาการบำรุงรักษา
  รายชื่อผู้ปฏิบัติงานทั้งหมด

Section 1  รายละเอียดวิธีการตรวจสอบและการดำเนินการ  ← (ข) ตามข้อ 3.13
  1.1  Service Pack Update
  1.2  Security Update
  1.3  Patch Update
  1.4  Signature Update
  1.5  Version Upgrade
  1.6  Virus Signature Update
  (แต่ละรายการ: รายละเอียดวิธีการดำเนินการ + ลายมือชื่อผู้ปฏิบัติงาน)

Section 2  บัญชีสรุปรายการอุปกรณ์และซอฟต์แวร์ที่เฝ้าระวัง  ← (ค) ตามข้อ 3.13
  - ตาราง: รายการ | ประเภท | ผลการเฝ้าระวัง | ข้อสังเกต / แนวทางป้องกัน / การแก้ไข (ถ้ามี)

[ลายมือชื่อ]
  ลายมือชื่อผู้ปฏิบัติงาน
```

---

### รายงาน 3: รายงานการประเมินความเสี่ยงด้านการรักษาความมั่นคงปลอดภัยไซเบอร์ (ข้อ 3.14)

> **กรอบมาตรฐาน**: ประมวลแนวทางปฏิบัติและกรอบมาตรฐานด้านการรักษาความมั่นคงปลอดภัยไซเบอร์
> สำหรับหน่วยงานของรัฐและหน่วยงานโครงสร้างพื้นฐานสำคัญทางสารสนเทศ พ.ศ. 2564 (NCSA)

```text
[หน้าปก]  ← (ก) ตามข้อ 3.14
  ชื่อโครงการ
  ชื่อผู้รับจ้าง
  งวดงานที่
  คาบเวลาการบำรุงรักษา

Section 1  ข้อมูลทั่วไป
  - ชื่อโครงการ ชื่อผู้รับจ้าง งวดงานที่ และคาบเวลาการบำรุงรักษา

Section 2  ผลการประเมินความเสี่ยง  ← (ข) ตามข้อ 3.14
  - ขอบเขตการประเมิน (ระบบ SRT Database Cloud)
  - กรอบมาตรฐานที่ใช้: ประมวลแนวทางปฏิบัติฯ NCSA พ.ศ. 2564
  - ตาราง: ความเสี่ยง | ระดับ | ผลกระทบ | โอกาสเกิด

Section 3  ผลการจัดการความเสี่ยง  ← (ข) ตามข้อ 3.14
  - มาตรการที่ดำเนินการแล้ว
  - ตาราง: ความเสี่ยง | มาตรการ | สถานะ

Section 4  ข้อเสนอแนะในการจัดการความเสี่ยง  ← (ข) ตามข้อ 3.14
  - แนวทางลด/รับ/โอน/ยอมรับความเสี่ยง

[ลายมือชื่อ]  ← (ค) ตามข้อ 3.14
  ผู้ประเมินความเสี่ยงลงลายมือชื่อรับรองรายงาน
```
