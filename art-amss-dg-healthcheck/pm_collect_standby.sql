-- ============================================================
-- pm_collect_standby.sql
-- Oracle Active Data Guard Health Check
-- Role    : PHYSICAL STANDBY
-- Version : Oracle 19c
-- Usage   : sqlplus / as sysdba @pm_collect_standby.sql
-- ============================================================

-- Capture YYYYMM for dynamic spool path (define OFF must come after spool)
set feedback off
set verify off
set echo off
whenever sqlerror continue

col spool_dir new_value spool_dir noprint
col spool_fn  new_value spool_fn  noprint
select
    'output/'||to_char(sysdate,'YYYYMM')||'_'||lower(i.host_name)                                                                               spool_dir,
    'output/'||to_char(sysdate,'YYYYMM')||'_'||lower(i.host_name)||'/'||lower(d.name)||'_STANDBY_'||lower(i.host_name)||'_'||to_char(sysdate,'YYYYMM')||'.txt' spool_fn
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
col open_mode       for a25  heading 'Open Mode'
col protection_mode for a25  heading 'Protection Mode'

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
PROMPT  [2.2 - 1] DATA GUARD CONFIGURATION AND SYNC STATUS
PROMPT ========================================================
PROMPT

-- Note: v$dg_broker_config is not accessible on standby in 19.31; protection_mode shown in header
PROMPT (DG Broker config name: see DATABASE IDENTITY section above)
PROMPT

PROMPT
PROMPT --- DG Broker Member Status ---
PROMPT

col db_unique_name  for a25  heading 'DB Unique Name'
col parent_dbun     for a25  heading 'Parent DB'
col dest_role       for a20  heading 'Dest Role'
col current_scn     for 9999999999999 heading 'Current SCN'

select
    db_unique_name,
    parent_dbun,
    dest_role,
    current_scn
from v$dataguard_config;

PROMPT
PROMPT --- Data Guard Sync Statistics ---
PROMPT

col name          for a35  heading 'Metric'
col value         for a25  heading 'Value'
col unit          for a20  heading 'Unit'
col time_computed for a25  heading 'Time Computed'

select
    name,
    value,
    unit,
    time_computed
from v$dataguard_stats
order by name;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.2 - 2] GAP / LAG / ARCHIVE APPLY DELAY
PROMPT ========================================================
PROMPT

PROMPT --- Archive Gap Check ---
PROMPT

col thread#        for 999     heading 'Thread'
col low_sequence#  for 9999999 heading 'Low Seq'
col high_sequence# for 9999999 heading 'High Seq'

select
    thread#,
    low_sequence#,
    high_sequence#
from v$archive_gap;

PROMPT
PROMPT --- MRP / Apply Process Status ---
PROMPT

col process        for a10     heading 'Process'
col status         for a15     heading 'Status'
col sequence#      for 9999999 heading 'Sequence#'
col delay_mins     for 9999    heading 'Delay(min)'
col client_process for a15     heading 'Client Process'
col client_dbid    for a15     heading 'Client DBID'

select
    process,
    status,
    sequence#,
    delay_mins,
    client_process,
    client_dbid
from v$managed_standby
where process in ('MRP0','RFS','ARCH')
order by process;

PROMPT
PROMPT --- Transport / Apply Lag ---
PROMPT

col name          for a35  heading 'Metric'
col value         for a25  heading 'Value'
col unit          for a20  heading 'Unit'
col time_computed for a25  heading 'Time Computed'

select
    name,
    value,
    unit,
    time_computed
from v$dataguard_stats
where name in ('transport lag','apply lag','apply finish time','estimated startup time')
order by name;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.2 - 3] LOG TRANSPORT AND APPLY SERVICE
PROMPT ========================================================
PROMPT

-- Note: v$archive_dest_status on standby 19.31 valid cols: dest_id, dest_name, status, db_unique_name, error
col dest_id        for 999  heading 'Dest'
col dest_name      for a25  heading 'Dest Name'
col status         for a10  heading 'Status'
col db_unique_name for a20  heading 'DB Unique Name'
col error          for a45  heading 'Error'

select
    dest_id,
    dest_name,
    status,
    db_unique_name,
    error
from v$archive_dest_status
where status != 'INACTIVE';

PROMPT
PROMPT --- Redo Apply Rate ---
PROMPT

-- Note: v$recovery_progress on 19c does not have END_TIME column
col item       for a30        heading 'Item'
col sofar      for 9999999999 heading 'So Far'
col total      for 9999999999 heading 'Total'
col units      for a15        heading 'Units'
col start_time for a25        heading 'Start Time'

select
    item,
    sofar,
    total,
    units,
    to_char(start_time,'DD-MON-YYYY HH24:MI:SS') start_time
from v$recovery_progress
where item in ('Active Apply Rate','Average Apply Rate','Redo Applied')
  and rownum <= 10;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.2 - 4] DISK USAGE AND FRA (Flash Recovery Area)
PROMPT ========================================================
PROMPT

PROMPT --- FRA Summary ---
PROMPT

col name                 for a45      heading 'FRA Location'
col space_limit_gb       for 99999.99 heading 'Limit(GB)'
col space_used_gb        for 99999.99 heading 'Used(GB)'
col space_reclaimable_gb for 99999.99 heading 'Reclaimable(GB)'
col pct_used             for 999.99   heading '%Used'
col number_of_files      for 9999     heading 'Files'

select
    name,
    round(space_limit/1024/1024/1024,2)       space_limit_gb,
    round(space_used/1024/1024/1024,2)        space_used_gb,
    round(space_reclaimable/1024/1024/1024,2) space_reclaimable_gb,
    round((space_used - space_reclaimable) / nullif(space_limit,0) * 100, 2) pct_used,
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

PROMPT
PROMPT --- Tablespace Usage ---
PROMPT

col tablespace_name for a30    heading 'Tablespace'
col total_mb        for 999999 heading 'Total(MB)'
col used_mb         for 999999 heading 'Used(MB)'
col free_mb         for 999999 heading 'Free(MB)'
col pct_used        for 999.99 heading '%Used'
col status          for a10    heading 'Status'

select
    df.tablespace_name,
    round(df.totalspace/1024/1024,0)                                                   total_mb,
    round((df.totalspace - nvl(fs.freespace,0))/1024/1024,0)                          used_mb,
    round(nvl(fs.freespace,0)/1024/1024,0)                                             free_mb,
    round(((df.totalspace - nvl(fs.freespace,0)) / nullif(df.totalspace,0)) * 100, 2) pct_used,
    tp.status
from
    (select tablespace_name, sum(bytes) totalspace from dba_data_files group by tablespace_name) df,
    (select tablespace_name, sum(bytes) freespace from dba_free_space  group by tablespace_name) fs,
    dba_tablespaces tp
where df.tablespace_name = fs.tablespace_name(+)
  and df.tablespace_name = tp.tablespace_name
order by pct_used desc;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.2 - 5] ALERT LOG (Standby - Last 31 Days)
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
  and originating_timestamp >= sysdate - 31
order by originating_timestamp desc
fetch first 30 rows only;

set linesize 115


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.2 - 6] BACKUP STATUS (RMAN on Standby)
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
PROMPT  [2.1 - 7] LICENSE / PATCH / PSU VERSION (Standby)
PROMPT ========================================================
PROMPT

PROMPT --- Database Version ---
PROMPT

col instance_number for 99999 heading 'Inst#'
col instance_name   for a12   heading 'Instance'
col host_name       for a20   heading 'Host Name'
col version_full    for a15   heading 'Version'

select instance_number, instance_name, host_name, version_full
from v$instance;

PROMPT
PROMPT --- Installed Components (Registry) ---
PROMPT

col comp_name for a40  heading 'Component'
col version   for a15  heading 'Version'
col status    for a12  heading 'Status'

select comp_name, version, status
from dba_registry
order by comp_name;

PROMPT
PROMPT --- Applied Patches (Last 10) ---
PROMPT

col patch_id     for 99999999    heading 'Patch ID'
col patch_uid    for 99999999999 heading 'Patch UID'
col action       for a12         heading 'Action'
col status       for a12         heading 'Status'
col description  for a40         heading 'Description'
col applied_time for a22         heading 'Applied Time'

select
    patch_id,
    patch_uid,
    action,
    status,
    substr(description,1,40)                          description,
    to_char(action_time,'DD-MON-YYYY HH24:MI:SS')    applied_time
from dba_registry_sqlpatch
order by action_time desc
fetch first 10 rows only;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  [2.2 - 7] NETWORK BANDWIDTH PRIMARY-STANDBY
PROMPT ========================================================
PROMPT

PROMPT --- Archive Dest Network Config ---
PROMPT

-- Note: v$archive_dest on 19.31 valid cols: dest_id, destination, net_timeout, max_failure, reopen_secs
--       DELAY column renamed to DELAY_MINS in 19c
col dest_id     for 999   heading 'Dest'
col destination for a40   heading 'Destination'
col net_timeout for 9999  heading 'Net Timeout(s)'
col delay_mins  for 9999  heading 'Delay(min)'
col max_failure for 9999  heading 'Max Fail'
col reopen_secs for 9999  heading 'Reopen(s)'

select
    dest_id,
    destination,
    net_timeout,
    delay_mins,
    max_failure,
    reopen_secs
from v$archive_dest
where status != 'INACTIVE';

PROMPT
PROMPT --- Transport / Apply Lag Summary ---
PROMPT

col name          for a35  heading 'Metric'
col value         for a25  heading 'Value'
col unit          for a20  heading 'Unit'
col time_computed for a25  heading 'Time Computed'

select
    name,
    value,
    unit,
    time_computed
from v$dataguard_stats
where name in ('transport lag','apply lag','estimated startup time')
order by name;


-- ============================================================
PROMPT
PROMPT ========================================================
PROMPT  END OF REPORT : ACTIVE DATA GUARD HEALTH CHECK
PROMPT ========================================================
PROMPT

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') "Collected At" from dual;

spool off
exit;
