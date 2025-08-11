#!/bin/bash

# ナノ秒単位の現在時刻を取得
# macOSの場合はgdate、Linuxの場合はdateコマンドを使用
if command -v gdate &> /dev/null; then
    NOW=$(gdate +%s%N)
else
    NOW=$(date +%s%N)
fi

# 32文字の16進数文字列を生成 (16バイト)
TRACE_ID=$(openssl rand -hex 16)

# 16文字の16進数文字列を生成 (8バイト)
PARENT_SPAN_ID=$(openssl rand -hex 8)

# 16文字の16進数文字列を生成 (8バイト)
CHILD_SPAN_ID=$(openssl rand -hex 8)

# 16文字の16進数文字列を生成 (8バイト)
CHILD_SPAN_ID_2=$(openssl rand -hex 8)

PARENT_START_TIME=$NOW
PARENT_END_TIME=$((NOW + 2000000000))

CHILD_START_TIME=$((NOW + 100000000))
CHILD_END_TIME=$((NOW + 1500000000))

CHILD_START_TIME_2=$((NOW + 200000000))
CHILD_END_TIME_2=$((NOW + 1800000000))

curl -sS -X POST http://localhost:4318/v1/traces \
  -H 'Content-Type: application/json' \
  --data-binary @- <<JSON
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

echo "Trace sent with:"
echo "  Trace ID: $TRACE_ID"
echo "  Parent Span ID: $PARENT_SPAN_ID"
echo "  Child Span ID 1: $CHILD_SPAN_ID"
echo "  Child Span ID 2: $CHILD_SPAN_ID_2"
