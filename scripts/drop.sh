
# Find the MongoDB user-db pod
echo "Finding MongoDB user-db pod..."
MONGO_POD=$(kubectl get pods | grep "user-db" | grep -v "mysql" | awk '{print $1}' | head -n 1)

if [ -z "$MONGO_POD" ]; then
    echo "ERROR: Could not find MongoDB user-db pod"
    exit 1
fi

echo "Found MongoDB pod: $MONGO_POD"
echo ""

# Drop existing usertable collection before loading
echo "======================================"
echo "Dropping existing usertable collection..."
echo "======================================"
kubectl exec -it "$MONGO_POD" -- mongo users --eval "db.usertable.drop()"
echo ""
echo "Collection dropped successfully"
echo ""
