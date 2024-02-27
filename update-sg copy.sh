#!/bin/bash

main() {

    if [ "$#" -lt 3 ]; then
        echo "Usage: $0 profileName groupIds fixedIps [port]"
        exit 1
    fi

    local profileName=$1
    local groupIds=$2
    local fixedIps=$3
    local port=${4:-22} # Set default port to 22 if not provided
    local newIp=$(curl -s https://api.ipify.org);

    echo "PROFILE: $profileName"
    echo "NEW IP : $newIp"

    read -r -a groupIdArray <<< "$groupIds"
    read -r -a fixedIpArray <<< "$fixedIps"

    for groupId in "${groupIdArray[@]}"; do

      # Remove the old IPs
      existingIps=$(aws ec2 --profile=$profileName describe-security-groups --filters Name=ip-permission.to-port,Values=$port Name=ip-permission.from-port,Values=$port Name=ip-permission.protocol,Values=tcp --group-ids $groupId --output text --query 'SecurityGroups[*].{IP:IpPermissions[?ToPort==`'$port'`].IpRanges}' | sed 's/IP	//g');
      for existingIp in $existingIps; do
        # if [ -n "$fixedIp" ]; then
          echo "REMOVE   : $groupId | $existingIp"
          echo "aws ec2 revoke-security-group-ingress --profile=$profileName --group-id $groupId --protocol tcp --port $port --cidr $existingIp"
        # fi
      done

      # Add my IP just in case it has changed
      echo "ADD MY IP: $groupId | $fixedIp"
      echo "aws ec2 authorize-security-group-ingress --profile=$profileName --protocol tcp --port $port --cidr ${myIp}/32 --group-id $groupId"

      # Loop through fixed IPs
      for fixedIp in $fixedIps; do
        if [ -n "$fixedIp" ]; then
          echo "ADD FIXED: $groupId | $fixedIp"
          echo "aws ec2 authorize-security-group-ingress --profile=$profileName --protocol tcp --port $port --cidr ${fixedIp} --group-id $groupId"
        fi
      done

    done
}

main "$@"
