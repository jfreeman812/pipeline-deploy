#!/bin/bash
api_username=${ORCA_USER-root}
api_password=${ORCA_PASS-root}
base_url="http://${api_username}:${api_password}@localhost:1337/api/v1"

#app_id=$(curl -ss "${base_url}/apps" -XPOST -d '{"name": "inventropy", "description": "inventropy"}' | jq ".id")
#endpoint_id=$(curl -ss "${base_url}/apps/${app_id}/endpoints" -XPOST -d '{"name": "blog", "description": "blog", "url": "https://inventropy.us/blog/"}' | jq ".id")
# app_id=$(curl -ss "${base_url}/apps" -XPOST -d '{"name": "badssl", "description": "badssl endpoints"}' | jq ".id")
# endpoint_id=$(curl -ss "${base_url}/apps/${app_id}/endpoints" -XPOST -d '{"name": "expired", "description": "expired badssl", "url": "https://expired.badssl.com"}' | jq ".id")
# app_id=1
# endpoint_id=1
# tc_id=$(curl -ss "${base_url}/apps/${app_id}/tool_configs" -XPOST -d '{"tool_name": "syntribos", "config_name": "prod", "config_path": "syntribos.conf"}' | jq ".id")

app_id=$(curl -ss "${base_url}/apps" -XPOST -d '{"name": "orca2", "description": "orca"}' | jq ".id")
endpoint_id=$(curl -ss "${base_url}/apps/${app_id}/endpoints" -XPOST -d '{"name": "local", "description": "this points to orca itself", "url": "http://orca:1337"}' | jq ".id")
tc_id=$(curl -ss "${base_url}/apps/${app_id}/tool_configs" -XPOST -d '{"tool_name": "syntribos", "config_name": "local", "config_path": "orca.conf"}' | jq ".id")

# scan_id=$(curl -ss "${base_url}/scans" -XPOST -d "{\"application_id\": ${app_id}, \"endpoint_id\": ${endpoint_id}, \"tool_name\": \"baseline\"}" | jq ".id")
scan_id=$(curl -ss "${base_url}/scans" -XPOST -d "{\"application_id\": ${app_id}, \"endpoint_id\": ${endpoint_id}, \"tool_config_id\": ${tc_id}, \"tool_name\": \"syntribos\"}" | jq ".id")

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
