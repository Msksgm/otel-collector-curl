NOW=$(python - <<'PY'
import time; print(int(time.time_ns()))
PY
)

cat > logs.json <<JSON
{
  "resourceLogs": [{
    "resource": {
      "attributes": [
        {"key":"service.name","value":{"stringValue":"curl-client"}}
      ]
    },
    "scopeLogs": [{
      "logRecords": [{
        "timeUnixNano": "$NOW",
        "severityNumber": 9,
        "severityText": "INFO",
        "body": {"stringValue":"hello from curl (otlp/http json)"}
      }]
    }]
  }]
}
JSON

curl -sS -X POST http://localhost:4318/v1/logs \
  -H 'Content-Type: application/json' \
  --data-binary @logs.json
