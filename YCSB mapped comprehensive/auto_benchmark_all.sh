#!/bin/bash
set -e

# Internal Execution Script
# Phase: RUN ONLY (Assumes data seeded)

OPERATION_COUNT=50000
RECORD_COUNT=10000
THREADS=20
RESULTS_DIR="/results"

mkdir -p $RESULTS_DIR

echo "--------------------------------------------------------"
echo "Starting Comprehensive Benchmark"
echo "Ops: $OPERATION_COUNT | Records: $RECORD_COUNT | Threads: $THREADS"
echo "--------------------------------------------------------"

# --- HELPER: Create View ---
setup_mysql_target() {
    local host=$1; local db=$2; local table=$3
    
    # 1. Identify PK and its Type
    # FIX: Removed "WHERE Key='PRI'" and used grep instead to be safe
    local key_info=$(mysql -h "$host" -u root "$db" --skip-column-names --batch -e "SHOW COLUMNS FROM $table;" | grep "PRI" | head -n 1)
    
    local key_col=$(echo "$key_info" | awk '{print $1}')
    local key_type=$(echo "$key_info" | awk '{print $2}')
    
    # Fallback if no PK
    if [ -z "$key_col" ]; then 
        local first_col=$(mysql -h "$host" -u root "$db" --skip-column-names --batch -e "SHOW COLUMNS FROM $table;" | head -n 1)
        key_col=$(echo "$first_col" | awk '{print $1}')
        key_type=$(echo "$first_col" | awk '{print $2}')
    fi
    
    # 2. Select updatable text columns
    local valid_cols=$(mysql -h "$host" -u root "$db" --skip-column-names --batch -e "SHOW COLUMNS FROM $table;" | grep -i -E "char|text|varchar" | awk '{print $1}')
    local field_num=0
    
    # 3. Handle Key Mapping (Integer vs String)
    if [[ "$key_type" =~ "int" ]]; then
        # Smart Map: Map 'user1' (YCSB) -> 1 (DB) by stripping 'user'
        select_fields="CAST(SUBSTRING(YCSB_KEY, 5) AS UNSIGNED) as $key_col"
        # Note: This complex mapping makes the view non-updatable for the PK, 
        # but allows Reads to work. Updates to other fields might still work.
        # However, since we map YCSB_KEY to the PK column in the select list, 
        # we actually need to invert it.
        # Correct approach for View: We select FROM table. 
        # The view column YCSB_KEY must be derived from the table PK.
        select_fields="CONCAT('user', $key_col) as YCSB_KEY"
    else
        select_fields="$key_col as YCSB_KEY"
    fi
    
    local text_col_count=0
    for col in $valid_cols; do
        if [ "$col" != "$key_col" ]; then
            select_fields="$select_fields, $col as field$field_num"
            field_num=$((field_num + 1))
            text_col_count=$((text_col_count + 1))
        fi
    done
    
    if [ "$text_col_count" -eq 0 ]; then echo "0"; return; fi
    
    mysql -h "$host" -u root "$db" -e "CREATE OR REPLACE VIEW ${table}_ycsb AS SELECT $select_fields FROM $table;" 2>/dev/null
    
    echo "$field_num"
}

# --- HELPER: Run Workload ---
run_ycsb() {
    local db_type=$1; local workload=$2; local id=$3; local args=$4
    local out="$RESULTS_DIR/${id}_wl${workload}.txt"
    echo "  -> Workload $workload..."
    
    timeout 600 ./bin/ycsb run $db_type -P workloads/workload$workload \
        -p operationcount=$OPERATION_COUNT \
        -p recordcount=$RECORD_COUNT \
        -p threadcount=$THREADS \
        -p requestdistribution=zipfian \
        -p maxexecutiontime=300 \
        $args > "$out" 2>&1
}

# --- DISCOVERY & RUN ---
TARGETS="catalogue-db orders-db carts-db user-db"

for host in $TARGETS; do
    # 1. Check MySQL
    if nc -z -w 2 $host 3306 2>/dev/null; then
        echo ">> MySQL detected on $host"
        DBS=$(mysql -h "$host" -u root --skip-column-names --batch -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "information|perform|mysql|sys")
        for db in $DBS; do
            TABLES=$(mysql -h "$host" -u root "$db" --skip-column-names --batch -e "SHOW TABLES;")
            for table in $TABLES; do
                [[ "$table" =~ _ycsb$ ]] && continue
                ROWS=$(mysql -h "$host" -u root "$db" --skip-column-names --batch -e "SELECT COUNT(*) FROM $table;" 2>/dev/null)
                
                if [ "$ROWS" -gt 0 ]; then
                    FIELD_COUNT=$(setup_mysql_target "$host" "$db" "$table")
                    
                    if [ "$FIELD_COUNT" -gt 0 ]; then
                        echo "   Benchmarking $db.$table ($ROWS rows)"
                        ARGS="-p db.driver=com.mysql.cj.jdbc.Driver -p db.url=jdbc:mysql://$host:3306/$db?useSSL=false&allowPublicKeyRetrieval=true -p db.user=root -p table=${table}_ycsb -p fieldcount=$FIELD_COUNT"
                        
                        run_ycsb "jdbc" "a" "mysql_${db}_${table}" "$ARGS"
                        run_ycsb "jdbc" "b" "mysql_${db}_${table}" "$ARGS"
                        run_ycsb "jdbc" "e" "mysql_${db}_${table}" "$ARGS"
                    else
                         echo "   Skipping $db.$table (Link table or no text columns)"
                    fi
                fi
            done
        done
        continue
    fi

    # 2. Check MongoDB
    if mongo --host $host --port 27017 --quiet --eval "db.version()" >/dev/null 2>&1; then
        echo ">> MongoDB detected on $host"
        DBS=$(mongo --host $host --port 27017 --quiet --eval "db.adminCommand('listDatabases').databases.map(db => db.name).join('\n')" 2>/dev/null | grep -v -E "admin|local|config")
        [[ -z "$DBS" && "$host" == "orders-db" ]] && DBS="orders"
        [[ -z "$DBS" && "$host" == "carts-db" ]] && DBS="carts"

        for db in $DBS; do
            COLLS=$(mongo --host $host --port 27017 $db --quiet --eval "db.getCollectionNames().join('\n')")
            for col in $COLLS; do
                [[ "$col" == "system.indexes" ]] && continue
                COUNT=$(mongo --host $host --port 27017 $db --quiet --eval "db.$col.count()" 2>/dev/null)
                if [ "$COUNT" -gt 0 ]; then
                    echo "   Benchmarking $db.$col ($COUNT docs)"
                    ARGS="-p mongodb.url=mongodb://$host:27017/$db -p mongodb.database=$db -p table=$col"
                    run_ycsb "mongodb" "a" "mongo_${db}_${col}" "$ARGS"
                    run_ycsb "mongodb" "b" "mongo_${db}_${col}" "$ARGS"
                    run_ycsb "mongodb" "e" "mongo_${db}_${col}" "$ARGS"
                fi
            done
        done
    fi
done

echo "Benchmark execution finished."