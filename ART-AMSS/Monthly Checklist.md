# ART-AMSS — Monthly Checklist

## เดือน: `YYYY-MM`

---

## ขั้นตอนการทำงาน

### 1. เก็บข้อมูลจาก Server

- [ ] Copy scripts ใหม่ขึ้น dbsystem1 และ dbsystem2
  - `pm_collect.sh`
  - `pm_collect_primary.sql`
  - `pm_collect_standby.sql`
- [ ] รัน `./pm_collect.sh` บน **dbsystem2** (PRIMARY side)
- [ ] รัน `./pm_collect.sh` บน **dbsystem1** (STANDBY side)

### 2. เตรียมข้อมูลบน Local

- [ ] Copy `YYYYMM_dbsystem2.zip` มาไว้ใน `output/`
- [ ] Copy `YYYYMM_dbsystem1.zip` มาไว้ใน `output/`
- [ ] แตก zip → `output/YYYYMM_dbsystem2/`
- [ ] แตก zip → `output/YYYYMM_dbsystem1/`

### 3. สร้างรายงาน

- [ ] แก้ `MONTH_TAG`, `YEAR`, `DOC_SEQ` ใน `generate_report.py`
- [ ] รัน `python3 generate_report.py`
- [ ] ตรวจสอบ output ไฟล์ `.docx`

### 4. ตรวจสอบก่อนส่ง

- [ ] เปิดไฟล์ → right-click สารบัญ → **Update Field → Update entire table**
- [ ] กรอก `รายละเอียดของผลลัพธ์` ทุก section ที่ต้องการ
- [ ] กรอก Section 5.2 Network Bandwidth (manual)
- [ ] ตรวจสอบ Section 4.2 CPU Patch — อัปเดต `lasted_oracle_critical_patch_update.docx` ถ้ามี patch ใหม่

---

## หมายเหตุประจำเดือน

> บันทึกปัญหา / สิ่งผิดปกติ / ข้อสังเกตที่พบในเดือนนี้

---

## ลิงก์

- [[Overview]]
- [[Home]]
