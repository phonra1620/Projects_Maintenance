# SRT-MA-EXP — Quarterly Checklist

## ไตรมาส: `YYYY-QN` (เช่น 2026-Q2 = เม.ย.–มิ.ย. 2569)

---

## รายงานการบำรุงรักษา (ข้อ 3.7)

### 1. เก็บข้อมูล Oracle RAC

- [ ] รัน `pm_collect_oracle_rac.sh` บน RAC Node 1
- [ ] รัน `pm_collect_oracle_rac.sh` บน RAC Node 2
- [ ] Copy output zip มาไว้บน local

### 2. เก็บข้อมูล MSSQL

- [ ] รัน `pm_collect_mssql.sql` (หรือ PowerShell script) บน MSSQL Server
- [ ] Copy output มาไว้บน local

### 3. สร้างรายงานการบำรุงรักษา

- [ ] แก้ `MONTH_TAG`, `YEAR`, งวดงาน ใน `generate_report_maintenance.py`
- [ ] รัน `python3 generate_report_maintenance.py`
- [ ] ตรวจสอบ output `.docx`
- [ ] กรอกรายละเอียดปัญหา / ข้อสังเกต / ข้อเสนอแนะ
- [ ] ลงลายมือชื่อผู้ปฏิบัติงานและผู้ควบคุมโครงการ

---

## รายงานการเฝ้าระวังภัยคุกคาม (ข้อ 3.13)

### 4. ตรวจสอบ Security Patch

- [ ] ตรวจสอบ Oracle CPU ล่าสุด (oracle.com/security-alerts)
- [ ] ตรวจสอบ MSSQL Cumulative Update ล่าสุด (microsoft.com)
- [ ] อัปเดตสถานะการติดตั้ง patch บนระบบ

### 5. สร้างรายงานเฝ้าระวัง

- [ ] รัน `python3 generate_report_security.py`
- [ ] กรอกผลการเฝ้าระวัง / ช่องโหว่ที่พบ / ข้อแนะนำ
- [ ] ลงลายมือชื่อผู้ปฏิบัติงาน

---

## หมายเหตุประจำไตรมาส

> บันทึกปัญหา / สิ่งผิดปกติ / ข้อสังเกตที่พบในไตรมาสนี้

---

## ลิงก์

- [[Overview]]
- [[Home]]
