#!/bin/bash
set -e

echo "========================================================"
echo "Sock Shop Intelligent Database Discovery"
echo "========================================================"

# Find all containers that might be databases
CANDIDATES=$(docker ps --format '{{.Names}}' | grep -E 'db|mongo|mysql' || true)

echo ""
echo "MySQL Containers Found:"
echo "------------------------"
for container in $CANDIDATES; do
    # Check for MySQL capability
    if docker exec $container mysql --version >/dev/null 2>&1; then
        echo "  - $container"
        DBS=$(docker exec $container mysql -u root --skip-column-names --batch -e "SHOW DATABASES;" 2>/dev/null | grep -v -E "information_schema|performance|sys|mysql" || true)
        for db in $DBS; do
            TABLES=$(docker exec $container mysql -u root $db --skip-column-names --batch -e "SHOW TABLES;" 2>/dev/null || true)
            COUNT=$(echo "$TABLES" | wc -l)
            echo "    Database: $db ($COUNT tables)"
        done
    fi
done

echo ""
echo "MongoDB Containers Found:"
echo "------------------------"
for container in $CANDIDATES; do
    # Check for MongoDB capability
    if docker exec $container which mongo >/dev/null 2>&1; then
        echo "  - $container"
        DBS=$(docker exec $container mongo --quiet --eval "db.adminCommand('listDatabases').databases.map(db => db.name).join('\n')" 2>/dev/null | grep -v -E "admin|local|config" || true)
        
        # Fallback for orders/carts if listing fails due to auth
        if [[ -z "$DBS" ]]; then
            [[ "$container" =~ "orders" ]] && DBS="orders"
            [[ "$container" =~ "carts" ]] && DBS="carts"
        fi

        for db in $DBS; do
            # Count collections
            COLLS=$(docker exec $container mongo $db --quiet --eval "db.getCollectionNames().length" 2>/dev/null || echo "0")
            echo "    Database: $db ($COLLS collections)"
        done
    fi
done

echo ""
echo "========================================================"
echo "Discovery Complete"
echo "========================================================"