#!/bin/bash

NOW=$(python - <<'PY'
import time; print(int(time.time_ns()))
PY
)

TRACE_ID=$(python - <<'PY'
import secrets; print(secrets.token_hex(16))
PY
)

SPAN_ID=$(python - <<'PY'
import secrets; print(secrets.token_hex(8))
PY
)

START_TIME=$NOW
END_TIME=$((NOW + 1000000000))

cat > traces.json <<JSON
{
  "resourceSpans": [{
    "resource": {
      "attributes": [
        {"key":"service.name","value":{"stringValue":"curl-client"}}
      ]
    },
    "scopeSpans": [{
      "spans": [{
        "traceId": "$TRACE_ID",
        "spanId": "$SPAN_ID",
        "name": "example-span",
        "kind": 1,
        "startTimeUnixNano": "$START_TIME",
        "endTimeUnixNano": "$END_TIME",
        "attributes": [
          {"key":"http.method","value":{"stringValue":"GET"}},
          {"key":"http.url","value":{"stringValue":"http://example.com"}}
        ],
        "status": {
          "code": 1
        }
      }]
    }]
  }]
}
JSON

curl -sS -X POST http://localhost:4318/v1/traces \
  -H 'Content-Type: application/json' \
  --data-binary @traces.json

echo "Trace sent with ID: $TRACE_ID"
