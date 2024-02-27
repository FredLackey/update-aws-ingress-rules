#!/bin/bash

main() {

    if [ "$#" -lt 2 ]; then
        echo "Usage: $0 profileName groupIds [fixedIps] [port]"
        exit 1
    fi

    local profileName=$1
    local groupIds=$2
    local fixedIps=$3
    local port=$4 # Allow port to be passed in
    local newIp=$(curl -s https://api.ipify.org);

    echo "PROFILE: $profileName"
    echo "NEW IP : $newIp"

    read -r -a groupIdArray <<< "$groupIds"
    read -r -a fixedIpArray <<< "$fixedIps"

    for groupId in "${groupIdArray[@]}"; do

      echo "REMOVE ALL: $groupId"

      format_json() {
        # Use jq to format the multi-line JSON into a single valid JSON blob
        jq -s add <<< "$1"
      }

      rules=$(aws ec2 describe-security-groups --profile $profileName --group-ids "$groupId" --output json 2>/dev/null)
      if [ $? -ne 0 ]; then
        echo "Failed to describe security group: $groupId"
        continue
      fi

      # Extract required fields using jq
      while IFS= read -r rule; do
          ipProtocol=$(jq -r '.IpProtocol' <<< "$rule")
          fromPort=$(jq -r '.FromPort' <<< "$rule")
          # Extract IpRanges array and convert it into a string
          ipRanges=$(jq -r '.IpRanges | map(.CidrIp) | join(",")' <<< "$rule")

          # Print or store the values as desired
          echo "IP Protocol: $ipProtocol, From Port: $fromPort, IP Ranges: $ipRanges"
          # You can store them in variables if needed
          # local ipProtocol=$ipProtocol
          # local fromPort=$fromPort
          # local ipRanges=$ipRanges
      done <<< "$(jq -c '.SecurityGroups[].IpPermissions[]' <<< "$rules")"

    done
}

main "$@"
