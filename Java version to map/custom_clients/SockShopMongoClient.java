package com.sockshop.ycsb;

import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.UpdateOptions;
import org.bson.Document;

import site.ycsb.ByteIterator;
import site.ycsb.DB;
import site.ycsb.DBException;
import site.ycsb.Status;
import site.ycsb.StringByteIterator;

import java.util.*;

/**
 * Custom YCSB Binding for Sock Shop MongoDB (Orders Service).
 * Maps generic YCSB keys to specific nested fields in the 'orders' document.
 */
public class SockShopMongoClient extends DB {
    private MongoClient mongoClient;
    private MongoCollection<Document> collection;

    @Override
    public void init() throws DBException {
        Properties props = getProperties();
        String url = props.getProperty("mongodb.url", "mongodb://orders-db:27017/orders");
        String dbName = props.getProperty("mongodb.database", "orders");
        String collName = props.getProperty("mongodb.collection", "orders");

        try {
            mongoClient = new MongoClient(new MongoClientURI(url));
            MongoDatabase db = mongoClient.getDatabase(dbName);
            collection = db.getCollection(collName);
        } catch (Exception e) {
            throw new DBException("Failed to connect to MongoDB", e);
        }
    }

    @Override
    public void cleanup() {
        if (mongoClient != null) {
            mongoClient.close();
        }
    }

    /**
     * Map YCSB fields to specific nested JSON paths.
     * field0 -> customerId
     * field1 -> total
     * field2 -> address.city
     * field3 -> items[0].itemId
     */
    private void mapDocToYCSB(Document doc, Set<String> fields, Map<String, ByteIterator> result) {
        if (fields == null) fields = new HashSet<>(Arrays.asList("field0", "field1", "field2", "field3"));

        for (String field : fields) {
            String val = null;
            if (field.equals("field0")) val = doc.getString("customerId");
            else if (field.equals("field1")) val = String.valueOf(doc.get("total"));
            else if (field.equals("field2")) {
                Document addr = (Document) doc.get("address");
                if (addr != null) val = addr.getString("city");
            }
            // Add more mappings as needed
            
            if (val != null) {
                result.put(field, new StringByteIterator(val));
            }
        }
    }

    @Override
    public Status read(String table, String key, Set<String> fields, Map<String, ByteIterator> result) {
        try {
            // Sock Shop orders use 'userN' or UUID as _id
            Document doc = collection.find(new Document("_id", key)).first();
            if (doc == null) return Status.NOT_FOUND;

            mapDocToYCSB(doc, fields, result);
            return Status.OK;
        } catch (Exception e) {
            e.printStackTrace();
            return Status.ERROR;
        }
    }

    @Override
    public Status insert(String table, String key, Map<String, ByteIterator> values) {
        try {
            // Construct a realistic Order document from YCSB data
            Document doc = new Document("_id", key);
            
            // Map generic YCSB values to specific schema fields if present
            if (values.containsKey("field0")) doc.append("customerId", values.get("field0").toString());
            else doc.append("customerId", "user_placeholder");

            if (values.containsKey("field1")) {
                 try {
                     doc.append("total", Double.parseDouble(values.get("field1").toString()));
                 } catch (Exception e) { doc.append("total", 0.0); }
            } else {
                doc.append("total", 99.99);
            }

            // Create fake nested structure to satisfy Sock Shop app requirements
            doc.append("address", new Document("city", values.containsKey("field2") ? values.get("field2").toString() : "New York")
                                       .append("country", "USA"));
            
            doc.append("items", Arrays.asList(
                new Document("itemId", "sock_item_1").append("quantity", 1).append("unitPrice", 10.0)
            ));

            doc.append("date", new Date());

            collection.insertOne(doc);
            return Status.OK;
        } catch (Exception e) {
            e.printStackTrace();
            return Status.ERROR;
        }
    }

    @Override
    public Status update(String table, String key, Map<String, ByteIterator> values) {
        try {
            Document updates = new Document();
            
            if (values.containsKey("field0")) updates.append("customerId", values.get("field0").toString());
            if (values.containsKey("field1")) updates.append("total", values.get("field1").toString());
            if (values.containsKey("field2")) updates.append("address.city", values.get("field2").toString());

            if (updates.isEmpty()) return Status.OK;

            collection.updateOne(new Document("_id", key), new Document("$set", updates));
            return Status.OK;
        } catch (Exception e) {
            e.printStackTrace();
            return Status.ERROR;
        }
    }

    @Override
    public Status delete(String table, String key) {
        try {
            collection.deleteOne(new Document("_id", key));
            return Status.OK;
        } catch (Exception e) {
            return Status.ERROR;
        }
    }

    @Override
    public Status scan(String table, String startkey, int recordcount, Set<String> fields, Vector<HashMap<String, ByteIterator>> result) {
        try {
            // Mongo driver doesn't support easy "startAt(key)" for string keys without sorting logic
            // This is a simplified scan
            for (Document doc : collection.find(new Document("_id", new Document("$gte", startkey))).limit(recordcount)) {
                HashMap<String, ByteIterator> map = new HashMap<>();
                mapDocToYCSB(doc, fields, map);
                result.add(map);
            }
            return Status.OK;
        } catch (Exception e) {
            return Status.ERROR;
        }
    }
}