-- ============================================================
-- pm_collect_primary.sql
-- Oracle Database Health Check
-- Role    : PRIMARY
-- Version : Oracle 19c
-- Usage   : sqlplus / as sysdba @pm_collect_primary.sql
-- ============================================================

-- Spool setup (define ON needed for &variable substitution)
set feedback off
set verify off
set echo off
whenever sqlerror continue

col spool_dir new_value spool_dir noprint
col spool_fn  new_value spool_fn  noprint
select
    'output/'||to_char(sysdate,'YYYYMM')||'_'||lower(i.host_name)                                                                              spool_dir,
    'output/'||to_char(sysdate,'YYYYMM')||'_'||lower(i.host_name)||'/'||lower(d.name)||'_PRIMARY_'||lower(i.host_name)||'_'||to_char(sysdate,'YYYYMM')||'.txt' spool_fn
from v$database d, v$instance i;

host mkdir -p &spool_dir
spool &spool_fn

set linesize 115
set pagesize 50
set trimspool on
set heading on
set timing off
set define off


-- ============================================================
PROMPT ========================================================
PROMPT  DATABASE IDENTITY
PROMPT ========================================================
PROMPT

col db_name        for a15  heading 'DB Name'
col db_unique_name for a20  heading 'DB Unique Name'
col host_name      for a20  heading 'Host Name'
col flashback_on   for a5   heading 'Flash'
col log_mode       for a12  heading 'Log Mode'
col version_full   for a15  heading 'Version'
col startup_time   for a19  heading 'Startup Time'

select
    d.name              db_name,
    d.db_unique_name,
    i.host_name,
    d.flashback_on,
    d.log_mode,
    i.version_full,
    to_char(i.startup_time,'DD-MON-YYYY HH24:MI:SS') startup_time
from v$database d, v$instance i;

col db_name         for a15  heading 'DB Name'
col db_unique_name  for a20  heading 'DB Unique Name'
col host_name       for a15  heading 'Host Name'
col database_role   for a20  heading 'Role'
col open_mode       for a20  heading 'Open Mode'
col protection_mode for a20  heading 'Protection Mode'

select
    d.name              db_name,
    d.db_unique_name,
    i.host_name,
    d.database_role,
    d.open_mode,
    d.protection_mode
from v$database d, v$instance i;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [1.2 - DB Environment]
PROMPT ========================================================
PROMPT

PROMPT --- Storage Mechanism ---
PROMPT

col "Item"   for a30
col "Value"  for a80

select item "Item", value "Value" from (
    select 1 ord, 'Global DB Name'       item,
        (select global_name from global_name)                                                   value
    from dual
    union all
    select 2,     'Oracle DB Name (SID)',
        (select name from v$database)
    from dual
    union all
    select 3,     'DB Location',
        nvl(trim(
            nvl((select max(value) from v$parameter where name='db_create_file_dest'),'')
            || case when (select max(value) from v$parameter where name='db_create_file_dest') is not null
                     and (select max(value) from v$parameter where name='db_recovery_file_dest') is not null
                    then ', ' end
            || nvl((select max(value) from v$parameter where name='db_recovery_file_dest'),'')
        ), '(not configured)')
    from dual
    union all
    select 4,     'Archive Directory',
        nvl(
            -- ถ้า log_archive_dest_1 มีรูปแบบ "LOCATION=<path> ..." ให้ตัดเอาแค่ path
            nvl(
                regexp_substr(
                    (select max(value) from v$parameter where name='log_archive_dest_1'),
                    'LOCATION=(\S+)', 1, 1, 'i', 1
                ),
                nullif(trim((select max(value) from v$parameter where name='log_archive_dest_1')),'')
            ),
            'USE_DB_RECOVERY_FILE_DEST'
        )
    from dual
    union all
    select 5,     'Archive Mode',
        (select log_mode from v$database)
    from dual
    union all
    select 6,     'Oracle Flashback',
        'FLASHBACK_ON is ' || (select flashback_on from v$database)
    from dual
)
order by ord;

PROMPT
PROMPT --- Database Character Set ---
PROMPT

col "Parameter"  for a30
col "Value"      for a30

select parameter "Parameter", value "Value"
from nls_database_parameters
where parameter in ('NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET')
order by parameter desc;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.1 - 1] INSTANCE AND LISTENER STATUS
PROMPT ========================================================
PROMPT

PROMPT --- Instance Status ---
PROMPT

col instance_number for 99999 heading 'Inst#'
col instance_name   for a12   heading 'Instance'
col host_name       for a20   heading 'Host'
col version_full    for a15   heading 'Version'
col status          for a12   heading 'Status'
col database_status for a12   heading 'DB Status'
col uptime_days     for 999   heading 'Days'
col startup_time    for a20   heading 'Startup Time'

select
    instance_number,
    instance_name,
    host_name,
    version_full,
    status,
    database_status,
    trunc(sysdate - startup_time)                       uptime_days,
    to_char(startup_time,'DD-MON-YYYY HH24:MI:SS')     startup_time
from v$instance;

PROMPT
-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.1 - 2] TABLESPACE / TEMP / UNDO / REDO LOG
PROMPT ========================================================
PROMPT

PROMPT --- Tablespace Usage (CDB Root) ---
PROMPT

col "Tablespace_Name" for a30

select s.tablespace_name as "Tablespace_Name",
       round(s.Used,2)                             "Use (GB)",
       round(d.Allocate,2)                         "Allocate (GB)",
       trunc(d.Max,2)                              "Max_Size (GB)",
       trunc((d.Max - s.Used),2)                   "Free (GB)",
       trunc(s.Used*100/(d.Allocate+0.01),2)       "% Allocate",
       trunc(s.Used*100/(d.Max+0.01),2)            "% Used"
from
    (select tablespace_name, sum(bytes/1024/1024/1024) as Used
     from dba_segments group by tablespace_name) s,
    (select tablespace_name, sum(bytes/1024/1024/1024) as Allocate,
            sum(maxbytes/1024/1024/1024) as Max
     from dba_data_files group by tablespace_name) d
where s.tablespace_name = d.tablespace_name
order by 7 desc;

PROMPT
PROMPT --- Tablespace Usage (PDB Level) ---
PROMPT

col "PDB_Name"        for a15
col "Tablespace_Name" for a22

select p.name                                      "PDB_Name",
       s.tablespace_name                           "Tablespace_Name",
       round(s.Used,2)                             "Use (GB)",
       round(d.Allocate,2)                         "Allocate (GB)",
       trunc(d.Max,2)                              "Max_Size (GB)",
       trunc((d.Max - s.Used),2)                   "Free (GB)",
       trunc(s.Used*100/(d.Allocate+0.01),2)       "% Allocate",
       trunc(s.Used*100/(d.Max+0.01),2)            "% Used"
from
    (select con_id, tablespace_name, sum(bytes/1024/1024/1024) as Used
     from cdb_segments group by con_id, tablespace_name) s,
    (select con_id, tablespace_name, sum(bytes/1024/1024/1024) as Allocate,
            sum(maxbytes/1024/1024/1024) as Max
     from cdb_data_files group by con_id, tablespace_name) d,
    v$pdbs p
where s.tablespace_name = d.tablespace_name
  and s.con_id          = d.con_id
  and s.con_id          = p.con_id
  and p.open_mode       = 'READ WRITE'
order by "PDB_Name", 8 desc;

PROMPT
PROMPT --- Temp Tablespace Usage ---
PROMPT

col "Tablespace_Name" for a30

select s.tablespace_name                           "Tablespace_Name",
       round(s.Used,2)                             "Use (GB)",
       round(d.Allocate,2)                         "Allocate (GB)",
       trunc(d.Max,2)                              "Max_Size (GB)",
       trunc((d.Max - s.Used),2)                   "Free (GB)",
       trunc(s.Used*100/(d.Allocate+0.01),2)       "% Allocate",
       trunc(s.Used*100/(d.Max+0.01),2)            "% Used"
from
    (select tablespace_name,
            sum((tablespace_size - free_space)/1024/1024/1024) as Used
     from dba_temp_free_space group by tablespace_name) s,
    (select tablespace_name,
            sum(bytes/1024/1024/1024) as Allocate,
            sum(case when maxbytes > 0 then maxbytes else bytes end/1024/1024/1024) as Max
     from dba_temp_files group by tablespace_name) d
where s.tablespace_name = d.tablespace_name
order by 7 desc;

PROMPT
PROMPT --- Undo Statistics (Last 6 Intervals x 10 min) ---
PROMPT

col begin_time    for a22   heading 'Begin Time'
col undoblks      for 99999 heading 'Undo Blks'
col txncount      for 99999 heading 'Txn Count'
col maxquerylen   for 99999 heading 'Max Query(s)'
col maxconcurrency for 9999 heading 'Max Conc'
col tuned_undoret for 99999 heading 'Tuned Ret(s)'

select
    to_char(begin_time,'DD-MON-YYYY HH24:MI:SS') begin_time,
    undoblks,
    txncount,
    maxquerylen,
    maxconcurrency,
    tuned_undoretention                           tuned_undoret
from v$undostat
order by begin_time desc
fetch first 6 rows only;

PROMPT
PROMPT --- Redo Log Status ---
PROMPT

col group#     for 99      heading 'Grp'
col members    for 9       heading 'Mbr'
col size_mb    for 9999    heading 'Size(MB)'
col status     for a12     heading 'Status'
col archived   for a3      heading 'Arc'
col sequence#  for 9999999 heading 'Sequence#'
col first_time for a22     heading 'First Time'

select
    group#,
    members,
    round(bytes/1024/1024,0)                            size_mb,
    status,
    archived,
    sequence#,
    to_char(first_time,'DD-MON-YYYY HH24:MI:SS')       first_time
from v$log
order by group#;

PROMPT
PROMPT --- Archive Log Generation (Last 7 Days) ---
PROMPT

col log_date for a14    heading 'Date'
col count    for 9999   heading 'Count'
col size_gb  for 999.99 heading 'Size(GB)'

select
    to_char(trunc(completion_time),'DD-MON-YYYY')       log_date,
    count(*)                                            count,
    round(sum(blocks*block_size)/1024/1024/1024,2)      size_gb
from v$archived_log
where dest_id = 1
  and standby_dest = 'NO'
  and completion_time >= sysdate - 7
group by trunc(completion_time)
order by trunc(completion_time);

PROMPT
PROMPT --- FRA (Flash Recovery Area) Summary ---
PROMPT

col name                 for a45      heading 'FRA Location'
col space_limit_gb       for 99999.99 heading 'Limit(GB)'
col space_used_gb        for 99999.99 heading 'Used(GB)'
col space_reclaimable_gb for 99999.99 heading 'Reclaimable(GB)'
col pct_used             for 999.99   heading '%Used'
col number_of_files      for 9999     heading 'Files'

select
    name,
    round(space_limit/1024/1024/1024,2)                                              space_limit_gb,
    round(space_used/1024/1024/1024,2)                                               space_used_gb,
    round(space_reclaimable/1024/1024/1024,2)                                        space_reclaimable_gb,
    round((space_used - space_reclaimable) / nullif(space_limit,0) * 100, 2)         pct_used,
    number_of_files
from v$recovery_file_dest;

PROMPT
PROMPT --- FRA Usage by File Type ---
PROMPT

col file_type                 for a30    heading 'File Type'
col percent_space_used        for 999.99 heading '%Used'
col percent_space_reclaimable for 999.99 heading '%Reclaimable'
col number_of_files           for 9999   heading 'Files'

select
    file_type,
    percent_space_used,
    percent_space_reclaimable,
    number_of_files
from v$flash_recovery_area_usage
order by percent_space_used desc;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.1 - 3] ALERT LOG (Primary - Last 31 Days)
PROMPT ========================================================
PROMPT

set linesize 240

PROMPT --- Alert Log ---
PROMPT

col originating_timestamp for a25  heading 'Timestamp'
col message_level         for 999  heading 'Lvl'
col message_text          for a200 heading 'Message'

select
    to_char(originating_timestamp,'DD-MON-YYYY HH24:MI:SS') originating_timestamp,
    message_level,
    substr(message_text,1,200)                               message_text
from v$diag_alert_ext
where message_text like '%ORA-%'
  and originating_timestamp >= sysdate - 30
order by originating_timestamp desc
fetch first 30 rows only;

set linesize 115


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.1 - 4] PERFORMANCE (AWR / Top SQL / Wait Events)
PROMPT ========================================================
PROMPT
PROMPT  NOTE: ข้อมูล AWR/Top SQL ย้อนหลัง 31 วัน (หรือตาม retention ของ AWR ที่มี)
PROMPT        Wait Events: ยอดสะสมตั้งแต่ Instance เริ่มทำงาน (cumulative since startup)
PROMPT        Active Sessions: สถานะ ณ เวลาที่รัน script
PROMPT

PROMPT --- AWR Snapshots (Last 31 Days) ---
PROMPT

col snap_count for 9999    heading 'Snap Count'
col first_snap for a25     heading 'First Snap'
col last_snap  for a25     heading 'Last Snap'
col min_snap   for 9999999 heading 'Min Snap ID'
col max_snap   for 9999999 heading 'Max Snap ID'

select
    count(*)                                                          snap_count,
    to_char(min(begin_interval_time),'DD-MON-YYYY HH24:MI:SS')      first_snap,
    to_char(max(end_interval_time),  'DD-MON-YYYY HH24:MI:SS')      last_snap,
    min(snap_id)                                                      min_snap,
    max(snap_id)                                                      max_snap
from dba_hist_snapshot
where begin_interval_time >= sysdate - 31;

PROMPT
PROMPT --- Top 10 SQL by Elapsed Time (AWR - Last 31 Days) ---
PROMPT

col pdb_name    for a12              heading 'PDB'
col sql_id      for a13              heading 'SQL ID'
col executions  for 999,999,999,999  heading 'Execs'
col elapsed_sec for 999,999.99       heading 'Elapsed(s)'
col cpu_sec     for 999,999.99       heading 'CPU(s)'
col buffer_gets for 9,999,999,999,999 heading 'Buf Gets'
col disk_reads  for 999,999,999      heading 'Disk Reads'

select
    p.name                                              pdb_name,
    s.sql_id,
    sum(s.executions_delta)                             executions,
    round(sum(s.elapsed_time_delta)/1000000, 2)        elapsed_sec,
    round(sum(s.cpu_time_delta)/1000000, 2)            cpu_sec,
    sum(s.buffer_gets_delta)                            buffer_gets,
    sum(s.disk_reads_delta)                             disk_reads
from dba_hist_sqlstat s
join dba_hist_snapshot sn
    on s.snap_id = sn.snap_id and s.dbid = sn.dbid
join v$pdbs p
    on s.con_id = p.con_id
where sn.begin_interval_time >= sysdate - 31
  and s.executions_delta      > 0
  and s.con_id                > 1
group by p.name, s.sql_id
order by sum(s.elapsed_time_delta) desc
fetch first 10 rows only;

PROMPT
PROMPT --- Top 10 SQL Full Text (AWR - Last 31 Days) ---
PROMPT

set long 8000
set longchunksize 8000
col pdb_name for a12 heading 'PDB'
col sql_id   for a13 heading 'SQL ID'
col sql_text for a83 heading 'SQL Text (Full)'

select
    p.name                                             pdb_name,
    s.sql_id,
    (select t.sql_text
     from dba_hist_sqltext t
     where t.sql_id = s.sql_id
     and rownum = 1)                                   sql_text
from (
    select s2.sql_id,
           s2.con_id,
           sum(s2.elapsed_time_delta)                  elapsed_total
    from dba_hist_sqlstat s2
    join dba_hist_snapshot sn2
        on s2.snap_id = sn2.snap_id and s2.dbid = sn2.dbid
    where sn2.begin_interval_time >= sysdate - 31
      and s2.executions_delta      > 0
      and s2.con_id                > 1
    group by s2.sql_id, s2.con_id
    order by elapsed_total desc
    fetch first 10 rows only
) s
join v$pdbs p on s.con_id = p.con_id
order by s.elapsed_total desc;

set long 80
set longchunksize 80

PROMPT
PROMPT --- Top 15 System Wait Events (AWR - Last 31 Days) ---
PROMPT

col event         for a40        heading 'Event'
col total_waits   for 9,999,999,999 heading 'Total Waits'
col time_waited_s for 999,999.99 heading 'Time Waited(s)'
col avg_wait_ms   for 9,999.99   heading 'Avg Wait(ms)'
col wait_class    for a20        heading 'Wait Class'

with snap_range as (
    select min(snap_id) min_snap, max(snap_id) max_snap
    from dba_hist_snapshot
    where begin_interval_time >= sysdate - 31
      and dbid = (select dbid from v$database)
)
select
    e.event_name                                                                    event,
    greatest(e.total_waits      - nvl(s.total_waits,      0), 0)                   total_waits,
    round(greatest(e.time_waited_micro - nvl(s.time_waited_micro, 0), 0)/1000000, 2) time_waited_s,
    round(greatest(e.time_waited_micro - nvl(s.time_waited_micro, 0), 0)
          / nullif(greatest(e.total_waits - nvl(s.total_waits, 0), 0), 0)
          / 1000, 2)                                                                avg_wait_ms,
    e.wait_class
from dba_hist_system_event e
cross join snap_range sr
left join dba_hist_system_event s
    on  s.event_name      = e.event_name
    and s.snap_id         = sr.min_snap
    and s.dbid            = e.dbid
    and s.instance_number = e.instance_number
where e.snap_id     = sr.max_snap
  and e.dbid        = (select dbid from v$database)
  and e.wait_class != 'Idle'
  and greatest(e.total_waits - nvl(s.total_waits, 0), 0) > 0
order by greatest(e.time_waited_micro - nvl(s.time_waited_micro, 0), 0) desc
fetch first 15 rows only;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.1 - 5] BACKUP STATUS (RMAN)
PROMPT ========================================================
PROMPT

set linesize 160

PROMPT --- RMAN Backup ---
PROMPT

col input_type  for a25      heading 'Input Type'
col status      for a30      heading 'Status'
col start_time  for a22      heading 'Start Time'
col end_time    for a22      heading 'End Time'
col elapsed_min for 9,999    heading 'Elapsed(min)'
col input_gb    for 9,999.99 heading 'Input(GB)'
col output_gb   for 9,999.99 heading 'Output(GB)'

select
    input_type,
    status,
    to_char(start_time,'DD-MON-YYYY HH24:MI:SS') start_time,
    to_char(end_time,'DD-MON-YYYY HH24:MI:SS')   end_time,
    round(elapsed_seconds/60,0)                  elapsed_min,
    round(input_bytes/1024/1024/1024,2)          input_gb,
    round(output_bytes/1024/1024/1024,2)         output_gb
from v$rman_backup_job_details
where start_time >= sysdate - 32
order by start_time desc
fetch first 10 rows only;

set linesize 115

-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.1 - 6] KEY PARAMETERS (Memory / PGA / SGA)
PROMPT ========================================================
PROMPT

PROMPT --- Key Initialization Parameters ---
PROMPT

col name  for a40 heading 'Parameter'
col value for a40 heading 'Value'

select name, value
from v$parameter
where name in (
    'memory_target','memory_max_target',
    'sga_target','sga_max_size',
    'pga_aggregate_target','pga_aggregate_limit',
    'processes','sessions',
    'db_cache_size','shared_pool_size',
    'log_buffer',
    'undo_retention','undo_tablespace',
    'db_block_size',
    'archive_lag_target',
    'log_archive_dest_1','log_archive_dest_2',
    'log_archive_dest_state_1','log_archive_dest_state_2'
)
order by name;

PROMPT
PROMPT --- SGA Components ---
PROMPT

col name       for a35    heading 'Component'
col size_mb    for 999999 heading 'Size(MB)'
col resizeable for a6     heading 'Resize'

select
    name,
    round(bytes/1024/1024,0) size_mb,
    resizeable
from v$sgainfo
order by bytes desc;

PROMPT
PROMPT --- PGA Statistics ---
PROMPT

col name     for a45    heading 'Statistic'
col value_mb for 999999 heading 'Value(MB)'

select
    name,
    round(value/1024/1024,2) value_mb
from v$pgastat
where name in (
    'total PGA inuse',
    'total PGA allocated',
    'maximum PGA allocated',
    'aggregate PGA target parameter',
    'aggregate PGA auto target'
)
order by name;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.1 - 7] LICENSE / PATCH / PSU VERSION
PROMPT ========================================================
PROMPT

PROMPT --- Database Version ---
PROMPT

col instance_name for a15 heading 'Instance'
col host_name     for a35 heading 'Host Name'
col version_full  for a20 heading 'Version'

select instance_name, host_name, version_full
from v$instance;

PROMPT
PROMPT --- Installed Components (Registry) ---
PROMPT

col comp_name for a45 heading 'Component'
col version   for a20 heading 'Version'
col status    for a12 heading 'Status'

select comp_name, version, status
from dba_registry
order by comp_name;

PROMPT
PROMPT --- Applied Patches (Last 10) ---
PROMPT

-- Note: dba_registry_sqlpatch on 19c does not have VERSION column
col patch_id    for 9999999999 heading 'Patch ID'
col patch_uid   for 9999999999 heading 'Patch UID'
col action      for a10        heading 'Action'
col status      for a10        heading 'Status'
col description for a40        heading 'Description'
col action_time for a22        heading 'Applied Time'

select
    patch_id,
    patch_uid,
    action,
    status,
    substr(description,1,40)                             description,
    to_char(action_time,'DD-MON-YYYY HH24:MI:SS')       action_time
from dba_registry_sqlpatch
order by action_time desc
fetch first 10 rows only;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  END OF REPORT : DATABASE HEALTH CHECK (PRIMARY)
PROMPT ========================================================
PROMPT

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Collected At" from dual;

spool off
exit;
