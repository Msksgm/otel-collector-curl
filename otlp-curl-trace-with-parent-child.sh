#!/bin/bash

NOW=$(python - <<'PY'
import time; print(int(time.time_ns()))
PY
)

TRACE_ID=$(python - <<'PY'
import secrets; print(secrets.token_hex(16))
PY
)

PARENT_SPAN_ID=$(python - <<'PY'
import secrets; print(secrets.token_hex(8))
PY
)

CHILD_SPAN_ID=$(python - <<'PY'
import secrets; print(secrets.token_hex(8))
PY
)

CHILD_SPAN_ID_2=$(python - <<'PY'
import secrets; print(secrets.token_hex(8))
PY
)

PARENT_START_TIME=$NOW
PARENT_END_TIME=$((NOW + 2000000000))

CHILD_START_TIME=$((NOW + 100000000))
CHILD_END_TIME=$((NOW + 1500000000))

CHILD_START_TIME_2=$((NOW + 200000000))
CHILD_END_TIME_2=$((NOW + 1800000000))

cat > traces-parent-child.json <<JSON
{
  "resourceSpans": [{
    "resource": {
      "attributes": [
        {"key":"service.name","value":{"stringValue":"parent-child-service"}},
        {"key":"service.version","value":{"stringValue":"1.0.0"}},
        {"key":"service.host","value":{"stringValue":"mac"}}
      ]
    },
    "scopeSpans": [{
      "spans": [
        {
          "traceId": "$TRACE_ID",
          "spanId": "$PARENT_SPAN_ID",
          "name": "parent-operation",
          "kind": 2,
          "startTimeUnixNano": "$PARENT_START_TIME",
          "endTimeUnixNano": "$PARENT_END_TIME",
          "attributes": [
            {"key":"http.method","value":{"stringValue":"POST"}},
            {"key":"http.url","value":{"stringValue":"http://api.example.com/process"}},
            {"key":"http.status_code","value":{"intValue":"200"}},
            {"key":"operation.type","value":{"stringValue":"parent"}}
          ],
          "status": {
            "code": 1,
            "message": "Success"
          }
        },
        {
          "traceId": "$TRACE_ID",
          "spanId": "$CHILD_SPAN_ID",
          "parentSpanId": "$PARENT_SPAN_ID",
          "name": "child-operation-database-query",
          "kind": 3,
          "startTimeUnixNano": "$CHILD_START_TIME",
          "endTimeUnixNano": "$CHILD_END_TIME",
          "attributes": [
            {"key":"db.type","value":{"stringValue":"postgresql"}},
            {"key":"db.statement","value":{"stringValue":"SELECT * FROM users WHERE id = ?"}},
            {"key":"db.operation","value":{"stringValue":"SELECT"}},
            {"key":"operation.type","value":{"stringValue":"child"}}
          ],
          "status": {
            "code": 1,
            "message": "Success"
          }
        },
        {
          "traceId": "$TRACE_ID",
          "spanId": "$CHILD_SPAN_ID_2",
          "parentSpanId": "$PARENT_SPAN_ID",
          "name": "child-operation-cache-lookup",
          "kind": 3,
          "startTimeUnixNano": "$CHILD_START_TIME_2",
          "endTimeUnixNano": "$CHILD_END_TIME_2",
          "attributes": [
            {"key":"cache.type","value":{"stringValue":"redis"}},
            {"key":"cache.operation","value":{"stringValue":"GET"}},
            {"key":"cache.key","value":{"stringValue":"user:session:12345"}},
            {"key":"cache.hit","value":{"boolValue":true}},
            {"key":"operation.type","value":{"stringValue":"child"}}
          ],
          "status": {
            "code": 1,
            "message": "Cache hit"
          }
        }
      ]
    }]
  }]
}
JSON

curl -sS -X POST http://localhost:4318/v1/traces \
  -H 'Content-Type: application/json' \
  --data-binary @traces-parent-child.json

echo "Trace sent with:"
echo "  Trace ID: $TRACE_ID"
echo "  Parent Span ID: $PARENT_SPAN_ID"
echo "  Child Span ID 1: $CHILD_SPAN_ID"
echo "  Child Span ID 2: $CHILD_SPAN_ID_2"
