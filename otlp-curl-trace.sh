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
SPAN_ID=$(openssl rand -hex 8)

START_TIME=$NOW
END_TIME=$((NOW + 1000000000))

cat > traces.json <<JSON
{
  "resourceSpans": [{
    "resource": {
      "attributes": [
        {"key":"service.name","value":{"stringValue":"curl-client"}},
        {"key":"service.host","value":{"stringValue":"mac"}}
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
