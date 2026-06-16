# SRT-MA-EXP — Infrastructure Survey

> รันคำสั่งบน server แล้ววางผลลัพธ์ใต้แต่ละข้อ

---

## 1. OS & Server

รันทุก node:

```bash
hostname
cat /etc/os-release | grep -E "^(NAME|VERSION)="
uname -r
nproc
free -h | grep Mem
```

### ผลลัพธ์ Node 1

```
oracle@SRTODB1:~$ hostname

SRTODB1

oracle@SRTODB1:~$ uname -a

SunOS SRTODB1 5.11 11.4.19.3.0 sun4v sparc sun4v

oracle@SRTODB1:~$ 

oracle@SRTODB1:~$ nproc

80
```

### ผลลัพธ์ Node 2

```
oracle@SRTODB2:~$ hostname

SRTODB2

oracle@SRTODB2:~$ uname -a

SunOS SRTODB2 5.11 11.4.19.3.0 sun4v sparc sun4v

oracle@SRTODB2:~$ nproc

80
```

---

## 2. Oracle RAC — Cluster

รันในฐานะ grid user หรือ root:

```bash
olsnodes -n
crsctl query crs activeversion
crsctl stat res -t
srvctl config database
```

### ผลลัพธ์

```
grid@SRTODB1:~$ olsnodes -n

srtodb1 1

srtodb2 2

grid@SRTODB1:~$ crsctl query crs activeversion

Oracle Clusterware active version on the cluster is [19.0.0.0.0]

grid@SRTODB1:~$ srvctl config database

OLAPCDB

OLTPCDB

SRTDW

TRAINING

grid@SRTODB1:~$ crsctl stat res -t

--------------------------------------------------------------------------------

Name           Target  State        Server                   State details       

--------------------------------------------------------------------------------

Local Resources

--------------------------------------------------------------------------------

ora.LISTENER.lsnr

               ONLINE  ONLINE       srtodb1                  STABLE

               ONLINE  ONLINE       srtodb2                  STABLE

ora.net1.network

               ONLINE  ONLINE       srtodb1                  STABLE

               ONLINE  ONLINE       srtodb2                  STABLE

ora.ons

               ONLINE  ONLINE       srtodb1                  STABLE

               ONLINE  ONLINE       srtodb2                  STABLE

ora.proxy_advm

               OFFLINE OFFLINE      srtodb1                  STABLE

               OFFLINE OFFLINE      srtodb2                  STABLE
```

---

## 3. Oracle RAC — Database & Instance

รันในฐานะ oracle user:

```bash
cat /etc/oratab
srvctl status database -d <db_name>
asmcmd lsdg
```

```sql
-- sqlplus / as sysdba
SELECT instance_number, instance_name, host_name,
       version_full, status
FROM   v$instance;

SELECT name, db_unique_name, database_role,
       cdb, open_mode, log_mode
FROM   v$database;

-- ถ้าเป็น CDB
SELECT con_id, name, open_mode FROM v$pdbs ORDER BY con_id;
```

### ผลลัพธ์

```
oracle@SRTODB1:~$ cat /etc/oratab

cat: cannot open /etc/oratab: No such file or directory

oracle@SRTODB1:~$ srvctl status database -d <db_name>

-bash: syntax error near unexpected token `newline'

oracle@SRTODB1:~$ asmcmd lsdg

State    Type    Rebal  Sector  Logical_Sector  Block       AU  Total_MB   Free_MB  Req_mir_free_MB  Usable_file_MB  Offline_disks  Voting_files  Name

MOUNTED  EXTERN  N         512             512   4096  4194304  12581280  11626904                0        11626904              0             N  DATA/

MOUNTED  HIGH    N         512             512   4096  4194304     25540     24144            10216            4642              0             Y  OCR_VOTE/

MOUNTED  EXTERN  N         512             512   4096  4194304  18871920  17451112                0        17451112              0             N  RECO/

CON_ID NAME                           OPEN_MODE

---------- ------------------------------ ----------

         2 PDB$SEED                       READ ONLY

         3 PRODMEDB                       READ WRITE

         4 APEXDB                         READ WRITE
```

---

## 4. Oracle — Patch Version

```sql
-- sqlplus / as sysdba
SELECT patch_id, version, action, status,
       TO_CHAR(action_time,'YYYY-MM-DD') action_date,
       description
FROM   dba_registry_sqlpatch
ORDER  BY action_time DESC
FETCH  FIRST 5 ROWS ONLY;
```

### ผลลัพธ์

```

```

---

## 5. Microsoft SQL Server

```sql
-- SSMS หรือ sqlcmd
SELECT @@SERVERNAME, @@VERSION;

SELECT name, state_desc, recovery_model_desc,
       compatibility_level
FROM   sys.databases
ORDER  BY name;

-- Always On
SELECT * FROM sys.dm_hadr_availability_group_states;

-- Mirroring
SELECT * FROM sys.database_mirroring
WHERE  mirroring_state IS NOT NULL;
```

```powershell
# Windows Server
Get-Service | Where-Object { $_.Name -like "MSSQL*" -or $_.Name -like "SQLAgent*" } |
  Select-Object Name, DisplayName, Status
```

### ผลลัพธ์

```

```

---

## 6. Network & Connectivity

```bash
hostname -I
lsnrctl status
tnsping <service_name>
```

### ผลลัพธ์

```

```

---

## 7. สรุป

| รายการ | ค่าที่ได้ |
| ------ | --------- |
| OS | Oracle Solaris 11.4.19.3.0 (SunOS 5.11) |
| Architecture | SPARC sun4v |
| CPU per node | 80 cores |
| Hostnames | SRTODB1, SRTODB2 |
| Oracle Clusterware | 19.0.0.0.0 |
| จำนวน RAC Node | 2 (srtodb1, srtodb2) |
| Databases ใน cluster | OLAPCDB, OLTPCDB, SRTDW, TRAINING |
| CDB หรือ non-CDB | CDB (พบ PDB: PRODMEDB, APEXDB — ยังไม่รู้ว่าอยู่ใน CDB ไหน) |
| ASM Disk Groups | DATA (12.5 TB), RECO (18.9 TB), OCR_VOTE (25 GB / HIGH mirror) |
| Oracle Patch Version | ยังไม่ได้เก็บ |
| MSSQL | ยังไม่ได้เก็บ |
| วิธี connect | ยังไม่ได้เก็บ |

### ข้อสังเกตสำคัญ

- `/etc/oratab` ไม่มีบน Solaris → ใช้ `/var/opt/oracle/oratab` แทน
- `free -h` ไม่มีบน Solaris → ใช้ `prtconf | grep Memory` แทน
- `cat /etc/os-release` ไม่มีบน Solaris → ใช้ `uname -a` + `cat /etc/release`
- Shell script ต้องเขียนแยกสำหรับ Solaris (bash path, command syntax ต่างกัน)
- `srvctl status database -d <db_name>` ต้องรันแยกทีละ database: OLAPCDB, OLTPCDB, SRTDW, TRAINING

### คำสั่งเพิ่มเติมที่ยังต้องเก็บ

```bash
# Solaris — memory
prtconf | grep Memory

# Solaris — oratab path จริง
cat /var/opt/oracle/oratab

# สถานะแต่ละ database
srvctl status database -d OLAPCDB
srvctl status database -d OLTPCDB
srvctl status database -d SRTDW
srvctl status database -d TRAINING
```

```sql
-- รัน sqlplus ทีละ CDB เพื่อดูว่า PDB อยู่ใน CDB ไหน
-- แทน <SID> ด้วย OLAPCDB / OLTPCDB ทีละตัว
SELECT d.name cdb_name, p.name pdb_name, p.open_mode
FROM   v$database d, v$pdbs p
ORDER  BY p.con_id;
```

---

## ลิงก์

- [[Overview]]
- [[Monthly Checklist]]
- [[Home]]
