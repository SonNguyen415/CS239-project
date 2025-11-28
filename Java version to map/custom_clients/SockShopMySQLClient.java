package com.sockshop.ycsb;

import com.yahoo.ycsb.ByteIterator;
import com.yahoo.ycsb.DB;
import com.yahoo.ycsb.DBException;
import com.yahoo.ycsb.Status;
import com.yahoo.ycsb.StringByteIterator;

import java.sql.*;
import java.util.*;

/**
 * Custom YCSB Binding for Sock Shop MySQL (Catalogue Service).
 * Maps YCSB "field0", "field1" etc. to real columns "name", "description", etc.
 */
public class SockShopMySQLClient extends DB {
    private Connection connection;
    
    // Mapping YCSB fields to Real Schema
    private static final Map<String, String> FIELD_MAP = new HashMap<>();
    static {
        FIELD_MAP.put("field0", "name");
        FIELD_MAP.put("field1", "description");
        FIELD_MAP.put("field2", "price");
        FIELD_MAP.put("field3", "count");
        FIELD_MAP.put("field4", "image_url_1");
        FIELD_MAP.put("field5", "image_url_2");
    }

    @Override
    public void init() throws DBException {
        Properties props = getProperties();
        String url = props.getProperty("db.url", "jdbc:mysql://catalogue-db:3306/socksdb");
        String user = props.getProperty("db.user", "root");
        String pass = props.getProperty("db.passwd", "");

        try {
            // Load driver and connect
            Class.forName("com.mysql.cj.jdbc.Driver"); 
            connection = DriverManager.getConnection(url + "?useSSL=false&allowPublicKeyRetrieval=true", user, pass);
        } catch (Exception e) {
            throw new DBException("Failed to connect to MySQL", e);
        }
    }

    @Override
    public void cleanup() throws DBException {
        try {
            if (connection != null) connection.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    @Override
    public Status read(String table, String key, Set<String> fields, HashMap<String, ByteIterator> result) {
        // Force table to 'sock' regardless of YCSB config
        String realTable = "sock";
        String keyCol = "sock_id";
        
        try {
            String query = "SELECT * FROM " + realTable + " WHERE " + keyCol + " = ?";
            try (PreparedStatement stmt = connection.prepareStatement(query)) {
                stmt.setString(1, key);
                
                try (ResultSet rs = stmt.executeQuery()) {
                    if (!rs.next()) return Status.NOT_FOUND;

                    // If YCSB didn't ask for specific fields, get them all
                    if (fields == null || fields.isEmpty()) {
                        fields = FIELD_MAP.keySet();
                    }

                    for (String ycsbField : fields) {
                        String realCol = FIELD_MAP.get(ycsbField);
                        if (realCol != null) {
                            String val = rs.getString(realCol);
                            result.put(ycsbField, new StringByteIterator(val != null ? val : ""));
                        }
                    }
                    return Status.OK;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return Status.ERROR;
        }
    }

    @Override
    public Status insert(String table, String key, HashMap<String, ByteIterator> values) {
        String realTable = "sock";
        
        try {
            // Build dynamic INSERT
            StringBuilder cols = new StringBuilder("sock_id");
            StringBuilder vals = new StringBuilder("?");
            List<String> params = new ArrayList<>();
            params.add(key);

            for (Map.Entry<String, ByteIterator> entry : values.entrySet()) {
                String realCol = FIELD_MAP.get(entry.getKey());
                if (realCol != null) {
                    cols.append(", ").append(realCol);
                    vals.append(", ?");
                    params.add(entry.getValue().toString());
                }
            }

            // Fallback defaults for required Sock Shop columns if not provided by YCSB
            if (!params.contains("count")) { cols.append(", count"); vals.append(", 100"); }
            if (!params.contains("price")) { cols.append(", price"); vals.append(", 9.99"); }

            String sql = "INSERT INTO " + realTable + " (" + cols + ") VALUES (" + vals + ") " +
                         "ON DUPLICATE KEY UPDATE count = count + 1"; // Upsert logic

            try (PreparedStatement stmt = connection.prepareStatement(sql)) {
                for (int i = 0; i < params.size(); i++) {
                    stmt.setString(i + 1, params.get(i));
                }
                stmt.executeUpdate();
                return Status.OK;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return Status.ERROR;
        }
    }

    @Override
    public Status update(String table, String key, HashMap<String, ByteIterator> values) {
        try {
            StringBuilder setClause = new StringBuilder();
            List<String> params = new ArrayList<>();

            for (Map.Entry<String, ByteIterator> entry : values.entrySet()) {
                String realCol = FIELD_MAP.get(entry.getKey());
                if (realCol != null) {
                    if (setClause.length() > 0) setClause.append(", ");
                    setClause.append(realCol).append(" = ?");
                    params.add(entry.getValue().toString());
                }
            }

            if (params.isEmpty()) return Status.OK;

            String sql = "UPDATE sock SET " + setClause + " WHERE sock_id = ?";
            try (PreparedStatement stmt = connection.prepareStatement(sql)) {
                for (int i = 0; i < params.size(); i++) {
                    stmt.setString(i + 1, params.get(i));
                }
                stmt.setString(params.size() + 1, key);
                
                int rows = stmt.executeUpdate();
                return rows > 0 ? Status.OK : Status.NOT_FOUND;
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return Status.ERROR;
        }
    }

    @Override
    public Status delete(String table, String key) {
        try (PreparedStatement stmt = connection.prepareStatement("DELETE FROM sock WHERE sock_id = ?")) {
            stmt.setString(1, key);
            stmt.executeUpdate();
            return Status.OK;
        } catch (SQLException e) {
            e.printStackTrace();
            return Status.ERROR;
        }
    }

    @Override
    public Status scan(String table, String startkey, int recordcount, Set<String> fields, Vector<HashMap<String, ByteIterator>> result) {
        // Basic scan implementation
        try {
            String sql = "SELECT * FROM sock WHERE sock_id >= ? ORDER BY sock_id LIMIT ?";
            try (PreparedStatement stmt = connection.prepareStatement(sql)) {
                stmt.setString(1, startkey);
                stmt.setInt(2, recordcount);
                try (ResultSet rs = stmt.executeQuery()) {
                    while (rs.next()) {
                        HashMap<String, ByteIterator> row = new HashMap<>();
                        if (fields == null || fields.isEmpty()) fields = FIELD_MAP.keySet();
                        
                        for (String ycsbField : fields) {
                            String realCol = FIELD_MAP.get(ycsbField);
                            if (realCol != null) {
                                row.put(ycsbField, new StringByteIterator(rs.getString(realCol)));
                            }
                        }
                        result.add(row);
                    }
                }
            }
            return Status.OK;
        } catch (SQLException e) {
            e.printStackTrace();
            return Status.ERROR;
        }
    }
}