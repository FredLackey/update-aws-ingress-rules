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
  local myIp=$(curl -s https://api.ipify.org)

  echo "PROFILE : $profileName"
  echo "NEW IP  : $myIp"

  read -r -a groupIdArray <<<"$groupIds"
  read -r -a fixedIpArray <<<"$fixedIps"

  # Revoke all ingress rules
  for groupId in "${groupIdArray[@]}"; do

    rules=$(aws ec2 describe-security-groups --profile $profileName --group-ids "$groupId" --output json 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo "  GROUP : $groupId (failure)"
      continue
    fi

    echo "  GROUP : $groupId"

    while IFS= read -r rule; do
      ipProtocol=$(jq -r '.IpProtocol' <<<"$rule")
      fromPort=$(jq -r '.FromPort' <<<"$rule")
      ipRanges=$(jq -r '.IpRanges | map(.CidrIp) | join(",")' <<<"$rule")

      if [ "$ipProtocol" = "-1" ]; then
        ipProtocol="tcp"
      fi
      if [ -n "$fromPort" ] || [ ! "$fromPort" ] || [ "$fromPort" = "0" ]; then
        fromPort="all"
      fi

      if [ -n "$ipProtocol" ] && [ -n "$fromPort" ] && [ -n "$ipRanges" ]; then
        aws ec2 revoke-security-group-ingress --profile "$profileName" --group-id "$groupId" --protocol all --port all > /dev/null 2>&1
        echo "    DEL : $ipProtocol | $fromPort | $ipRanges"
      fi

    done <<<"$(jq -c '.SecurityGroups[].IpPermissions[]' <<<"$rules")"

  done

  # Add ingress rules for my IP
  # myIpResult=$(aws ec2 authorize-security-group-ingress --profile=$profileName --protocol all --port all --cidr ${myIp}/32 --group-id $groupId 2>/dev/null)
  # if [ $? -ne 0 ]; then
  #   echo "    ADD : $myIp | ALL | ALL (failure)"
  # else
  #   echo "    ADD : $myIp | ALL | ALL"
  # fi


}

main "$@"
