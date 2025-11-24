#!/bin/bash
set -e

echo "========================================================"
echo "Sock Shop RESET & SEED (Auto-Inc Fix)"
echo "Enables NO_AUTO_VALUE_ON_ZERO to allow ID=0"
echo "========================================================"

# ---------------------------------------------------------
# 1. MYSQL SEEDERS (Corrected)
# ---------------------------------------------------------

seed_mysql_socksdb() {
    local container=$1; local db=$2
    echo "    [MySQL] Resetting & Seeding 'socksdb'..."
    
    docker exec -i $container mysql -u root $db <<EOF
-- Fix: Allow inserting ID 0 for YCSB compatibility
SET SESSION sql_mode='NO_AUTO_VALUE_ON_ZERO';
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE sock_tag;
TRUNCATE TABLE sock;
TRUNCATE TABLE tag;

SET FOREIGN_KEY_CHECKS = 1;

DROP PROCEDURE IF EXISTS SeedData;
DELIMITER $$
CREATE PROCEDURE SeedData()
BEGIN
  DECLARE i INT DEFAULT 0;
  
  -- 1. Seed 1,000 Tags (IDs: 0 - 999)
  WHILE i < 1000 DO
    INSERT INTO tag (tag_id, name) VALUES (i, CONCAT('tag-name-', i));
    SET i = i + 1;
  END WHILE;

  -- 2. Seed 10,000 Socks (IDs: user0 - user9999)
  SET i = 0;
  WHILE i < 10000 DO
    INSERT INTO sock (sock_id, name, description, price, count, image_url_1, image_url_2)
    VALUES (
      CONCAT('user', i), 
      CONCAT('Sock ', i), 
      'Benchmark Description Text',
      ROUND(RAND() * 100, 2), 
      1000,
      '/catalogue/images/puma_1.jpeg', 
      '/catalogue/images/puma_2.jpeg'
    );
    SET i = i + 1;
  END WHILE;

  -- 3. Link Socks to Tags
  SET i = 0;
  WHILE i < 10000 DO
    INSERT INTO sock_tag (sock_id, tag_id) 
    VALUES (
        CONCAT('user', i),     
        FLOOR(RAND() * 1000)   
    );
    SET i = i + 1;
  END WHILE;
END$$
DELIMITER ;
CALL SeedData();
EOF
    echo "    ✓ MySQL Reset & Seed finished."
}

# ---------------------------------------------------------
# 2. MONGODB SEEDERS (Unchanged)
# ---------------------------------------------------------

seed_mongo_users() {
    local container=$1; local db=$2
    echo "    [MongoDB] Resetting 'users'..."
    docker exec $container mongo $db --eval '
      db.customers.drop();
      var bulk = db.customers.initializeUnorderedBulkOp();
      for (var i = 0; i < 10000; i++) {
        bulk.insert({
          "_id": "user" + i,
          "username": "user" + i,
          "firstName": "Bench", "lastName": "Mark",
          "email": "user" + i + "@example.com",
          "addresses": [], "cards": []
        });
      }
      bulk.execute();
    ' > /dev/null 2>&1
    echo "    ✓ Done."
}

seed_mongo_orders() {
    local container=$1; local db=$2
    echo "    [MongoDB] Resetting 'orders'..."
    docker exec $container mongo $db --eval '
      db.orders.drop();
      var bulk = db.orders.initializeUnorderedBulkOp();
      for (var i = 0; i < 10000; i++) {
        bulk.insert({
          "_id": "user" + i,
          "customerId": "user" + Math.floor(Math.random() * 1000),
          "date": new Date(),
          "total": Math.random() * 100,
          "items": []
        });
      }
      bulk.execute();
    ' > /dev/null 2>&1
    echo "    ✓ Done."
}

seed_mongo_carts() {
    local container=$1; local db=$2
    echo "    [MongoDB] Resetting 'carts'..."
    docker exec $container mongo $db --eval '
      db.cart.drop();
      var bulk = db.cart.initializeUnorderedBulkOp();
      for (var i = 0; i < 5000; i++) {
        bulk.insert({
          "_id": "user" + i,
          "customerId": "user" + i,
          "items": [{ "itemId": "item1", "quantity": 1, "unitPrice": 18.00 }]
        });
      }
      bulk.execute();
    ' > /dev/null 2>&1
    echo "    ✓ Done."
}

# ---------------------------------------------------------
# 3. DISCOVERY LOGIC
# ---------------------------------------------------------

ALL_DB_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -E 'db|mongo|mysql' || true)

for container in $ALL_DB_CONTAINERS; do
    echo "Checking: $container"
    if docker exec $container mysql --version >/dev/null 2>&1; then
        DBS=$(docker exec $container mysql -u root --skip-column-names --batch -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "information|perform|mysql|sys" || true)
        for db in $DBS; do
            if [[ "$db" == "socksdb" ]]; then seed_mysql_socksdb "$container" "$db"; fi
        done
    fi
    if docker exec $container which mongo >/dev/null 2>&1; then
        MONGO_DBS=$(docker exec $container mongo --quiet --eval "db.adminCommand('listDatabases').databases.map(db => db.name).join('\n')" 2>/dev/null | grep -v -E "admin|local|config" || true)
        if [[ "$container" =~ "orders" ]]; then MONGO_DBS="$MONGO_DBS orders"; fi
        if [[ "$container" =~ "carts" ]];  then MONGO_DBS="$MONGO_DBS carts"; fi
        if [[ "$container" =~ "user" ]];   then MONGO_DBS="$MONGO_DBS users"; fi
        
        MONGO_DBS=$(echo "$MONGO_DBS" | tr ' ' '\n' | sort -u | grep -v "^$")
        for db in $MONGO_DBS; do
            if [[ "$db" == "users" ]] || [[ "$db" == "userdb" ]]; then seed_mongo_users "$container" "$db";
            elif [[ "$db" == "orders" ]]; then seed_mongo_orders "$container" "$db";
            elif [[ "$db" == "carts" ]] || [[ "$db" == "cart" ]]; then seed_mongo_carts "$container" "$db"; fi
        done
    fi
done