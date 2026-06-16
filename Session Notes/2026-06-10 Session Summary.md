# Session Summary — 2026-06-10

## สิ่งที่ทำในแชทนี้

### 1. ตั้งค่า Git Repo
- สร้าง `README.md` ระดับ repo ครอบคลุมทั้งสองโครงการ
- สร้าง `srt-ma-exp-healthcheck/srt_ma_exp_healthcheck_context.md` จาก note file ที่มีอยู่

### 2. ตั้งค่า Obsidian Vault
- Vault อยู่ที่ `/Users/phonr/Obsidian/Project_Maintenance`
- Git repo อยู่ที่ `/Users/phonr/Github/Projects_Maintenance`
- สร้างโครงสร้างโน้ตครบทั้งสองโครงการ

### 3. ออกแบบ Architecture & Process
- **Architecture doc** — กำหนดว่าอะไรใช้ร่วมกันได้: กระบวนการ 5 phase + ไฟล์ `lasted_critical_patch` ควรย้ายไป `shared/`
- **New Project Onboarding doc** — framework สำหรับโครงการใหม่ในอนาคต

### 4. Infrastructure Survey — SRT-MA-EXP
รัน survey บน server จริง พบข้อมูลสำคัญ:

| รายการ | ข้อมูล |
| ------ | ------ |
| OS | Oracle Solaris 11.4.19.3.0 (SunOS 5.11) |
| Architecture | SPARC sun4v |
| Hostnames | SRTODB1, SRTODB2 |
| Oracle Clusterware | 19.0.0.0.0 (RAC 2-node) |
| Databases | OLAPCDB, OLTPCDB, SRTDW, TRAINING |
| CDB | ใช่ (พบ PDB: PRODMEDB, APEXDB) |
| ASM | DATA 12.5 TB, RECO 18.9 TB, OCR_VOTE |

---

## สิ่งที่ยังค้างอยู่

### SRT-MA-EXP — ยังขาดข้อมูล

- [ ] รัน `srvctl status database -d` ทีละตัวด้วยชื่อจริง: OLAPCDB, OLTPCDB, SRTDW, TRAINING
- [ ] รัน SQL ดู PDB mapping ว่าแต่ละ CDB มี PDB ชื่ออะไร
- [ ] เก็บ Oracle patch version (Section 4 ใน Survey ยังว่าง)
- [ ] เก็บข้อมูล MSSQL ทั้งหมด (Section 5 ยังว่าง)
- [ ] เก็บข้อมูล Network / วิธี connect (Section 6 ยังว่าง)

```sql
-- รันใน sqlplus ของแต่ละ CDB เพื่อดู PDB mapping
SELECT d.name cdb_name, p.name pdb_name, p.open_mode
FROM   v$database d, v$pdbs p
ORDER  BY p.con_id;
```

```bash
# Solaris — คำสั่งที่ต้องใช้แทน Linux
prtconf | grep Memory          # แทน free -h
cat /var/opt/oracle/oratab     # แทน /etc/oratab
```

### Git Repo — ยังไม่ได้ทำ

- [ ] สร้าง `shared/` folder แล้วย้าย `lasted_oracle_critical_patch_update.docx` ออกจาก `art-amss-dg-healthcheck/`
- [ ] สร้าง `srt-ma-exp-healthcheck/pm_collect_oracle_rac.sh` (Solaris version)
- [ ] สร้าง `srt-ma-exp-healthcheck/pm_collect_rac.sql` (RAC — ไม่มี DG section)
- [ ] สร้าง `srt-ma-exp-healthcheck/pm_collect_mssql.sql`
- [ ] สร้าง `art-amss-dg-healthcheck/config.yaml`

---

## Key Insight จากแชทนี้

**OS คือตัวแปรที่กำหนด effort มากที่สุดเมื่อรับโครงการใหม่**
- Linux → ใช้ collect script จาก ART-AMSS เป็น base ได้เลย
- Solaris / Windows → เขียน collect script ใหม่เกือบทั้งหมด แม้ Oracle SQL จะใช้ซ้ำได้

**SQL แยกตาม HA topology ไม่ใช่ตาม OS**
- DG Primary/Standby → มีแล้ว (ART-AMSS)
- RAC → ต้องสร้างใหม่ 1 ครั้ง (SRT) แล้วใช้กับทุกโปรเจค RAC ต่อไป

---

## โน้ตที่สร้างในแชทนี้

- [[Home]]
- [[Architecture — Multi-Project Report Design]]
- [[New Project Onboarding]]
- [[ART-AMSS/Overview]]
- [[ART-AMSS/Monthly Checklist]]
- [[SRT-MA-EXP/Overview]]
- [[SRT-MA-EXP/Monthly Checklist]]
- [[SRT-MA-EXP/Infrastructure Survey]]
