#!/bin/bash
api_username=${ORCA_USER-root}
api_password=${ORCA_PASS-root}
base_url="https://${api_username}:${api_password}@pipeline.qesecurity.rackspace.net/api/v1"

app_id=$(curl -ss "${base_url}/apps" -XPOST -d '{"name": "badssl", "description": "badssl endpoints"}' | jq ".id")
endpoint_id=$(curl -ss "${base_url}/apps/${app_id}/endpoints" -XPOST -d '{"name": "expired", "description": "expired badssl", "url": "https://expired.badssl.com"}' | jq ".id")
# app_id=1
# endpoint_id=1
scan_id=$(curl -ss "${base_url}/scans" -XPOST -d "{\"application_id\": ${app_id}, \"endpoint_id\": ${endpoint_id}, \"scan_type\": \"baseline\"}" | jq ".id")

if [[ "${scan_id}" == "" ]] || [[ "${scan_id}" == "null" ]]; then
	echo "NO SCAN ID RETURNED"
    exit 1
fi

while true; do
    scan_url="${base_url}/scans/${scan_id}"
    scan_status=$(curl -ss "${scan_url}" | jq ".status" | tr -d '"')

    echo "SCAN STATUS: ${scan_status}"
    if [[ "${scan_status}" == "COMPLETE" ]]; then
        report_id=$(curl -ss "${scan_url}" | jq ".report_id")
        curl -ss "${base_url}/reports/${report_id}"
        break
    elif [[ "${scan_status}" == "ERROR" ]]; then
        echo "ERROR SCANNING"
        exit 1
    fi
    sleep 5
done
