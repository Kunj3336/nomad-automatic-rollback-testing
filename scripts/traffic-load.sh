#!/bin/bash
echo "=== Starting Continuous Load Traffic Test ==="
FAIL_COUNT=0
SUCCESS_COUNT=0

while true; do
  PORTS=$(curl -s http://127.0.0.1:8500/v1/health/service/rollback-service?passing=true | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    ports = [str(item["Service"]["Port"]) for item in data if "Service" in item and "Port" in item["Service"]]
    print(" ".join(ports))
except Exception:
    pass
')

  if [ -n "$PORTS" ]; then
    PORT_ARRAY=($PORTS)
    RANDOM_PORT=\({PORT_ARRAY[\)RANDOM % ${#PORT_ARRAY[@]}]}
    
    HTTP_CODE=\((curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "http://127.0.0.1:\){RANDOM_PORT}/")
    TIME=$(date +"%H:%M:%S")

    if [ "$HTTP_CODE" == "200" ]; then
      ((SUCCESS_COUNT++))
      echo "[\(TIME] [Port:\)RANDOM_PORT] -> HTTP 200 OK | Success: \(SUCCESS_COUNT | Dropped:\)FAIL_COUNT"
    else
      ((FAIL_COUNT++))
      echo "[\(TIME] [Port:\)RANDOM_PORT] -> HTTP \(HTTP_CODE (ERROR) | Success:\)SUCCESS_COUNT | Dropped: $FAIL_COUNT"
    fi
  else
    echo "[$(date +'%H:%M:%S')] -> Waiting for healthy backends..."
  fi
  sleep 0.2
done
