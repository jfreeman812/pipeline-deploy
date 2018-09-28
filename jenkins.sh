#!/bin/sh

api_username=${PIPELINE_USER-root}
api_password=${PIPELINE_PASS-root}
app_id=${PIPELINE_APP_ID-1}
endpoint_id=${PIPELINE_ENDPOINT_ID-1}

base_url="https://${api_username}:${api_password}@pipeline.seceng.rackspace.net/api/v1"

scan_id=$(curl -ss "${base_url}/scans" -XPOST -d "{\"application_id\": ${app_id}, \"endpoint_id\": ${endpoint_id}, \"scan_type\": \"baseline\"}" | jq ".ID")

while true; do
    scan_url="${base_url}/scans/${scan_id}"
    scan_status=$(curl -ss "${scan_url}" | jq ".status" | tr -d '"')

    echo "SCAN STATUS: ${scan_status}"
    if [[ "${scan_status}" == "COMPLETE" ]]; then
        report_id=$(curl -ss "${scan_url}" | jq ".report_id")
        curl "${base_url}/reports/${report_id}"
        break
    elif [[ "${scan_status}" == "ERROR" ]]; then
        echo "ERROR SCANNING"
        break
    fi
    sleep 5
done

echo $res
