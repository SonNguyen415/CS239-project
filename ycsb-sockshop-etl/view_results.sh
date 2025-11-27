#!/bin/bash
# Helper script to view results

echo "Recent Results:"
echo "=============="
ls -lht data/results_*.json 2>/dev/null | head -5 || echo "No results found"

echo ""
echo "Latest Result:"
echo "============="
LATEST=$(ls -t data/results_*.json 2>/dev/null | head -1)
if [ -f "$LATEST" ]; then
    cat "$LATEST" | python -m json.tool
else
    echo "No results available yet"
fi
