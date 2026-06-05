#!/bin/bash
# ==============================================================
# pm_collect.sh
# Oracle Database Health Check — Main Collector
# วิธีใช้: ./pm_collect.sh
#
# Flow:
#   สำหรับแต่ละ CDB ใน CDB_LIST
#     1. อ่าน ORACLE_HOME จาก /etc/oratab
#     2. ตรวจสถานะ instance
#     3. ตรวจ role -> รัน pm_collect_primary.sql หรือ pm_collect_standby.sql
#     4. เก็บรายชื่อ CDB + PDB ลง inventory file
# ==============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
YYYYMM=$(date +%Y%m)
HOSTNAME=$(hostname -s)
OUTPUT_DIR="${SCRIPT_DIR}/output/${YYYYMM}_${HOSTNAME}"
LOG_FILE="${OUTPUT_DIR}/pm_collect_${HOSTNAME}_${YYYYMM}.log"
INVENTORY_FILE="${OUTPUT_DIR}/inventory_${HOSTNAME}_${YYYYMM}.txt"

# รายชื่อ CDB ทั้งหมดที่ต้องเก็บข้อมูล
CDB_LIST="amsscdb fdmccdb fdmscdb"

# Peer host สำหรับ network test (auto-detect จาก hostname)
# หรือ uncomment บรรทัดล่างเพื่อ hardcode
# PEER_HOST="dbsystem2"
case "${HOSTNAME}" in
    dbsystem1) PEER_HOST="dbsystem2" ;;
    dbsystem2) PEER_HOST="dbsystem1" ;;
    *)         PEER_HOST="" ;;
esac

# ==============================================================
# Functions
# ==============================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

# รัน SQL query สั้น ๆ แล้วคืนผลเป็น plain text (1 บรรทัด)
sqlplus_get() {
    sqlplus -s / as sysdba 2>/dev/null <<EOF
set heading off feedback off pagesize 0 trimout on linesize 200 verify off
whenever sqlerror continue
$1
exit;
EOF
}

# ==============================================================
# Prepare output directory
# ==============================================================

mkdir -p "${OUTPUT_DIR}"

log "========================================================"
log " Oracle Health Check Collection"
log " Server  : $(hostname)"
log " Started : $(date '+%Y-%m-%d %H:%M:%S')"
log " Output  : ${OUTPUT_DIR}"
log "========================================================"

# Init inventory file
cat > "${INVENTORY_FILE}" << HEADER
========================================================
  CDB / PDB Inventory
  Server   : $(hostname)
  Collected: $(date '+%Y-%m-%d %H:%M:%S')
========================================================
HEADER

# ==============================================================
# Main loop
# ==============================================================

for CDB in ${CDB_LIST}; do

    log ""
    log ">>> CDB: ${CDB}"

    # --- ตั้งค่า Oracle environment จาก /etc/oratab ---
    ORACLE_HOME=$(awk -F: "/^${CDB}:/{print \$2}" /etc/oratab 2>/dev/null | head -1)
    if [[ -z "${ORACLE_HOME}" ]]; then
        log "  SKIP : ${CDB} ไม่พบใน /etc/oratab"
        echo "" >> "${INVENTORY_FILE}"
        echo "CDB: ${CDB}  ->  NOT IN ORATAB" >> "${INVENTORY_FILE}"
        continue
    fi
    export ORACLE_HOME ORACLE_SID="${CDB}"
    export PATH="${ORACLE_HOME}/bin:${PATH}"

    # --- ตรวจสถานะ instance ---
    INST_STATUS=$(sqlplus_get "select status from v\$instance;" | tr -d ' \n')
    if [[ "${INST_STATUS}" != "OPEN" && "${INST_STATUS}" != "MOUNTED" ]]; then
        log "  SKIP : Instance ไม่พร้อม (status='${INST_STATUS}')"
        echo "" >> "${INVENTORY_FILE}"
        printf "CDB: %-15s  ->  INSTANCE DOWN  (status=%s)\n" \
            "${CDB}" "${INST_STATUS}" >> "${INVENTORY_FILE}"
        continue
    fi

    # --- ตรวจ role ---
    DB_ROLE=$(sqlplus_get "select database_role from v\$database;" | tr -d ' \n')
    DB_VERSION=$(sqlplus_get "select version_full from v\$instance;" | tr -d ' \n')
    log "  Status : ${INST_STATUS}"
    log "  Role   : ${DB_ROLE}"
    log "  Version: ${DB_VERSION}"

    # --- รัน collect script ตาม role ---
    cd "${SCRIPT_DIR}"
    if [[ "${DB_ROLE}" == "PRIMARY" ]]; then
        log "  Script : pm_collect_primary.sql"
        sqlplus / as sysdba @pm_collect_primary.sql
        RC=$?
    elif echo "${DB_ROLE}" | grep -q "STANDBY"; then
        log "  Script : pm_collect_standby.sql"
        sqlplus / as sysdba @pm_collect_standby.sql
        RC=$?
    else
        log "  WARN   : Role '${DB_ROLE}' ไม่รู้จัก, ข้าม"
        RC=1
    fi

    [[ ${RC} -eq 0 ]] \
        && log "  Collect: สำเร็จ" \
        || log "  Collect: เสร็จ (ตรวจสอบ output หาก error)"

    # --- เก็บ inventory: CDB + PDB list ---
    {
        echo ""
        printf "CDB  : %-15s  Role: %-20s  Version: %-15s  Host: %s\n" \
            "${CDB}" "${DB_ROLE}" "${DB_VERSION}" "$(hostname)"
        echo "  PDBs:"
        sqlplus -s / as sysdba 2>/dev/null <<EOF
set heading off feedback off pagesize 0 trimout on linesize 200 verify off
select '    ' || rpad(name,25)
            || 'open_mode='   || rpad(open_mode,22)
            || 'restricted='  || restricted
from v\$pdbs
where name != 'PDB\$SEED'
order by name;
exit;
EOF
    } >> "${INVENTORY_FILE}"

done

# ==============================================================
# Oracle Software Configuration (Section 1.1.1)
# เก็บ platform, edition, oracle_home, oracle_base, grid_home
# ==============================================================

ORACLE_CONFIG_FILE="${OUTPUT_DIR}/oracle_config_${HOSTNAME}_${YYYYMM}.txt"

# ใช้ ORACLE_HOME จาก CDB แรกที่ active (ทุก CDB บนเครื่องเดียวกันใช้ home เดียวกัน)
ACTIVE_ORACLE_HOME=""
for CDB in ${CDB_LIST}; do
    _OH=$(awk -F: "/^${CDB}:/{print \$2}" /etc/oratab 2>/dev/null | head -1)
    if [[ -n "${_OH}" && -d "${_OH}" ]]; then
        ACTIVE_ORACLE_HOME="${_OH}"
        ACTIVE_CDB="${CDB}"
        break
    fi
done

if [[ -n "${ACTIVE_ORACLE_HOME}" ]]; then
    export ORACLE_HOME="${ACTIVE_ORACLE_HOME}"
    export ORACLE_SID="${ACTIVE_CDB}"
    export PATH="${ORACLE_HOME}/bin:${PATH}"

    # Platform — จาก OS release file
    if   [[ -f /etc/oracle-release ]]; then
        OS_PLATFORM="$(cat /etc/oracle-release | tr -d '\n') ($(uname -m))"
    elif [[ -f /etc/redhat-release ]]; then
        OS_PLATFORM="$(cat /etc/redhat-release | tr -d '\n') ($(uname -m))"
    else
        OS_PLATFORM="$(uname -s) $(uname -r) ($(uname -m))"
    fi

    # Oracle Edition — จาก v$version
    ORACLE_EDITION=$(sqlplus -s / as sysdba 2>/dev/null <<'EOF'
set heading off feedback off pagesize 0 trimout on linesize 200 verify off
whenever sqlerror continue
select banner from v$version where rownum=1;
exit;
EOF
)
    ORACLE_EDITION=$(echo "${ORACLE_EDITION}" | head -1 | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

    # Oracle Base — จาก oraenv หรือ derive จาก ORACLE_HOME
    if [[ -n "${ORACLE_BASE}" ]]; then
        ORA_BASE="${ORACLE_BASE}"
    else
        # derive: ORACLE_HOME=/u01/app/oracle/product/19.0.0.0/dbhome_1 → /u01/app/oracle
        ORA_BASE=$(echo "${ACTIVE_ORACLE_HOME}" | sed 's|/product/.*||')
    fi

    # Grid Home — ค้นหาจาก /etc/oracle/olr.olr หรือ /etc/oratab (entry +ASM หรือ grid)
    GRID_HOME=""
    if [[ -f /etc/oracle/olr.olr ]]; then
        GRID_HOME=$(grep -i "^ORA_CRS_HOME" /etc/oracle/olr.olr 2>/dev/null | cut -d= -f2 | tr -d ' \n')
    fi
    if [[ -z "${GRID_HOME}" ]]; then
        GRID_HOME=$(awk -F: '/^\+ASM/{print $2}' /etc/oratab 2>/dev/null | head -1)
    fi
    if [[ -z "${GRID_HOME}" ]]; then
        GRID_HOME=$(awk -F: '/^grid:/{print $2}' /etc/oratab 2>/dev/null | head -1)
    fi
    [[ -z "${GRID_HOME}" ]] && GRID_HOME="(not found)"

    cat > "${ORACLE_CONFIG_FILE}" << CFGEOF
========================================================
  Oracle Database Configuration
  Server   : $(hostname)
  Collected: $(date '+%Y-%m-%d %H:%M:%S')
========================================================
Platform        : ${OS_PLATFORM}
Oracle Edition  : ${ORACLE_EDITION}
Oracle Home     : ${ACTIVE_ORACLE_HOME}
Oracle Base     : ${ORA_BASE}
Grid Home       : ${GRID_HOME}
CFGEOF

    log ""
    log ">>> Oracle Config: เก็บข้อมูลสำเร็จ → $(basename ${ORACLE_CONFIG_FILE})"
    cat "${ORACLE_CONFIG_FILE}"
else
    log ""
    log ">>> Oracle Config: ข้าม (ไม่พบ ORACLE_HOME)"
fi

# ==============================================================
# Listener Status (lsnrctl status)
# ==============================================================

LISTENER_FILE="${OUTPUT_DIR}/listener_${HOSTNAME}_${YYYYMM}.txt"

if [[ -n "${ACTIVE_ORACLE_HOME}" ]]; then
    log ""
    log ">>> Listener Status"
    {
        echo "========================================================"
        echo "  Listener Status"
        echo "  Server   : $(hostname)"
        echo "  Collected: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================================"
        echo ""
        "${ACTIVE_ORACLE_HOME}/bin/lsnrctl" status 2>&1
    } | tee "${LISTENER_FILE}"
    log "  Output : ${LISTENER_FILE}"
else
    log ""
    log ">>> Listener Status: ข้าม (ไม่พบ ORACLE_HOME)"
fi

# ==============================================================
# Network Test (OS Level) : Primary <-> Standby
# ==============================================================

NET_FILE="${OUTPUT_DIR}/network_test_${HOSTNAME}_${YYYYMM}.txt"

# กำหนด tnsping target: ทดสอบว่าเครื่องนี้ต่อหา CDB ของเครื่องตรงข้ามได้ไหม
case "${HOSTNAME}" in
    dbsystem1) TNSPING_TARGET="AMSSCDB_STBY" ;;
    dbsystem2) TNSPING_TARGET="AMSSCDB" ;;
    *)         TNSPING_TARGET="" ;;
esac

if [[ -z "${ACTIVE_ORACLE_HOME}" ]]; then
    log ""
    log ">>> Network Test (tnsping): ข้าม (ไม่พบ ORACLE_HOME)"
elif [[ -z "${TNSPING_TARGET}" ]]; then
    log ""
    log ">>> Network Test (tnsping): ข้าม (ไม่รู้ tnsping target สำหรับ hostname '${HOSTNAME}')"
else
    log ""
    log ">>> Network Test (tnsping): ${HOSTNAME} → ${TNSPING_TARGET}"

    {
        echo "========================================================"
        echo "  Network Test (tnsping): ${HOSTNAME}"
        echo "  Target  : ${TNSPING_TARGET}"
        echo "  Time    : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================================"
        echo ""
        "${ACTIVE_ORACLE_HOME}/bin/tnsping" "${TNSPING_TARGET}" 2>&1

    } | tee "${NET_FILE}"

    log "  Output : ${NET_FILE}"
fi

# ==============================================================
# Summary
# ==============================================================

log ""
log "========================================================"
log " Collection Complete"
log "========================================================"

echo "" | tee -a "${LOG_FILE}"
echo "Files generated in ${OUTPUT_DIR}:" | tee -a "${LOG_FILE}"
ls -lh "${OUTPUT_DIR}/" | tee -a "${LOG_FILE}"

echo ""
echo "========================================================"
echo " Inventory"
echo "========================================================"
cat "${INVENTORY_FILE}"

# ==============================================================
# Zip log files (ยกเว้น .docx และ zip ที่มีอยู่แล้ว)
# ==============================================================

ZIP_FILE="${SCRIPT_DIR}/output/${YYYYMM}_${HOSTNAME}.zip"

log ""
log ">>> Creating zip archive: $(basename ${ZIP_FILE})"

# รวม files ทั้งหมดใน OUTPUT_DIR ยกเว้น .docx (รายงาน) และ .zip
# ใช้ find + xargs -0 เพื่อรองรับ filename ที่มีช่องว่างหรืออักขระพิเศษ
find "${OUTPUT_DIR}" -maxdepth 1 -type f \
    ! -name '*.docx' ! -name '*.zip' \
    -print0 \
| xargs -0 zip -j "${ZIP_FILE}" >> "${LOG_FILE}" 2>&1

if [[ $? -eq 0 ]]; then
    ZIP_SIZE=$(du -sh "${ZIP_FILE}" 2>/dev/null | cut -f1)
    log "  Done : ${ZIP_FILE} (${ZIP_SIZE})"
else
    log "  WARN : zip อาจไม่สมบูรณ์ — ตรวจสอบ log"
fi

cd "${SCRIPT_DIR}"
