-- Create the YCSB table
CREATE TABLE IF NOT EXISTS usertable (
    YCSB_KEY VARCHAR(255) PRIMARY KEY,
    FIELD0 TEXT,
    FIELD1 TEXT,
    FIELD2 TEXT,
    FIELD3 TEXT,
    FIELD4 TEXT,
    FIELD5 TEXT,
    FIELD6 TEXT,
    FIELD7 TEXT,
    FIELD8 TEXT,
    FIELD9 TEXT
);

-- Create indexes for better performance
CREATE INDEX idx_ycsb_key ON usertable(YCSB_KEY);

-- Grant privileges
GRANT ALL PRIVILEGES ON sockshop.* TO 'sockshop'@'%';
FLUSH PRIVILEGES;