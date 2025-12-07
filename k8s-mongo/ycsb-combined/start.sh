#!/bin/bash

# Start the YCSB exporter in the background
python3 /usr/local/bin/exporter.py &

# Create the named pipe
if [ ! -p /tmp/ycsb_pipe ]; then
  mkfifo /tmp/ycsb_pipe
fi

# Keep the pipe open with a background process that feeds it nothing
# This prevents the pipe from closing
tail -f /dev/null > /tmp/ycsb_pipe &

# Start the live exporter reading from the pipe
python3 /usr/local/bin/live-exporter.py < /tmp/ycsb_pipe &

# Wait a moment for exporters to start
sleep 2

echo "YCSB exporters started."

# Keep container running with interactive bash
exec /bin/bash